/*global exports, openidm, require */
(function () {
    var _ = require("lib/lodash"),
        base64 = Packages.org.forgerock.util.encode.Base64url,
        authConfig = openidm.read("config/authentication"),
        oidcModule = _.find(authConfig.serverAuthContext.authModules, function (a) {
                        return a.name === "OPENID_CONNECT";
                    }),
        obj = {
            serializeParams: function (params) {
                return _(params)
                        .pairs()
                        .map(function (p) {
                            return p[0] + "=" + encodeURIComponent(p[1]);
                        })
                        .value()
                        .join("&");
            },
            getRequestHeader: function () {
                return oidcModule.properties.openIdConnectHeader;
            },
            getResolvers: function (isExternal) {
                var resolvers = oidcModule.properties.resolvers;

                return  _.map(resolvers, function (r) { 
                            if (isExternal) {
                                return _.omit(r, "client_secret", "well-known");
                            } else {
                                return r;
                            }
                        });
            },
            getToken: function (name, code, redirect_uri) {
                var resolver = _.find(this.getResolvers(false), function (r) {
                        return r.name === name;
                    }),
                    response,
                    claims,
                    user;

                if (!resolver) {
                    throw { "code": 400, "message": "Unable to find provider with name '" + name + "'"};
                }

                try {
                    response = openidm.action("external/rest", "call", {
                        "method": "POST",
                        "url": resolver.token_endpoint,
                        "contentType": "application/x-www-form-urlencoded",
                        "body": this.serializeParams({
                            "grant_type": "authorization_code",
                            "redirect_uri": redirect_uri,
                            "code": code,
                            "client_id": resolver.client_id,
                            "client_secret": resolver.client_secret
                        })
                    });
                } catch (e) {
                    throw {
                        "code" : e.javaException.getCode(), 
                        "message" : e.javaException.getMessage(),
                        "detail" : e.javaException.getDetail()
                    };
                }

                if (!response || !response.id_token) {
                    throw { "code": 400, "message": "Incorrect response from server", "detail": response };
                }

                if (response.id_token.split(".")[1] === null || base64.decode( response.id_token.split(".")[1]) === null) {
                    throw { "code": 400, "message": "Unable to parse the response from server", "detail": response };
                }

                if (new java.lang.String(base64.decode( response.id_token.split(".")[1]) ) === null) {
                    throw { "code": 400, "message": "Unable to build string from decoded response", "detail": response };
                }

                claims = JSON.parse( new java.lang.String(base64.decode( response.id_token.split(".")[1]) ) );

                user = openidm.read("system/fiddles/users/" + claims.iss + ":" + claims.sub);

                // if the user isn't found in our local user cache, create a record for them
                if (user === null) {

                    // "email" is a poor-man's subject, standing in for the real value we might be missing
                    user = openidm.read("system/fiddles/users/" + claims.iss + ":" + claims.email);

                    if (user === null) {
                        openidm.create("system/fiddles/users", null, {
                            "issuer" : claims.iss,
                            "subject" : claims.sub,
                            "email" : claims.email
                        });
                    } else {
                        openidm.update("system/fiddles/users/" + user._id, null, {
                            "issuer" : claims.iss,
                            "subject" : claims.sub,
                            "email" : claims.email
                        });
                    }

                }


                return {
                    "token": response.id_token,
                    "header": this.getRequestHeader()
                }
            }
        };

    exports.process = function (request) {
        if (!oidcModule || !oidcModule.enabled) {
            throw { "code": 500, "message": "OpenID Connect not configured"};
        }

        switch (request.method) {
            case "read":
                return obj.getResolvers(true);
            break;

            case "action":
                switch (request.action) {
                    case "getToken":
                        if (request.additionalParameters.code === undefined ||
                            request.additionalParameters.name === undefined ||
                            request.additionalParameters.redirect_uri === undefined
                            ) {
                            throw { "code": 400, "message": "getToken requires 'redirect_uri', 'code' and 'name' as URL parameters"};
                        }

                        return obj.getToken(request.additionalParameters.name, request.additionalParameters.code, request.additionalParameters.redirect_uri);
                    break;

                    default:
                        throw { "code": 400, "message": "Unsupported action: '" + request.action + "'"};
                }
            break;

            default:
                throw { "code": 400, "message": "Unsupported method: '" + request.method + "'"};
        }
    };

    exports.impl = obj;

}());
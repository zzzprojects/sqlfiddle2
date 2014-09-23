/*global exports, openidm, require */
(function () {
    var _ = require("lib/lodash"),
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
                    response;

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
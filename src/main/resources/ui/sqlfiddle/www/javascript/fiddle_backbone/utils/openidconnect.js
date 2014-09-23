/*global localStorage, JSON */
define(["underscore", "jquery", "fiddle_backbone/models/OpenIDMResource"], function (_, $, idm) {
    return {
        getURLParams: function () {
            return _.chain( window.location.search.replace(/^\?/, '').split("&") )
                .map(function (arg) { 
                    return arg.split("="); 
                })
                .object()
                .value();
        },
        getCode: function () {
            return this.getURLParams().code;
        },
        getRedirectUri: function () {
            return  window.location.protocol + "//" + window.location.host + 
                    window.location.pathname.replace(/(\/index\.html)|(\/$)/, '/oauth.html');
        },
        getMainUri: function () {
            return  window.location.protocol + "//" + window.location.host + 
                    window.location.pathname.replace(/(\/oauth\.html)|(\/$)/, '/index.html');
        },
        getToken: function () {
            var params = this.getURLParams();
            return idm.serviceCall({
                "type": "POST",
                "url": "endpoint/oidc?_action=getToken&code=" + params.code + "&name=" + params.state + "&redirect_uri=" + this.getRedirectUri()
            }).then(function (result) {
                localStorage.setItem("oidcToken", JSON.stringify(result));
                return result;
            });
        },
        getLoggedUserDetails: function () {
            var token = localStorage.getItem("oidcToken"),
                jwt = {};

            if (token) {
                token = JSON.parse(token);
                jwt[token.header] = token.token;

                return idm.serviceCall({
                    "url": "info/login",
                    "headers": jwt
                });
            } else {
                return $.Deferred().reject();
            }
        }
    };
});
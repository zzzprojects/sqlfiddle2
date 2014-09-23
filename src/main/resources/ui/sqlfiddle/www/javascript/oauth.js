requirejs.config({
    paths: {
        jquery: 'libs/jquery/jquery-1.11.1.min',
        underscore: 'libs/lodash.underscore.min',
        utils: 'fiddle_backbone/utils'
    }
});

require(["jquery", "utils/openidconnect"], function ($, oidc) {
    oidc.getToken().always(function () {
        window.location.href = oidc.getMainUri();
    });
});
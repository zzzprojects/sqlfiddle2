define(["./OpenIDMResource", "Backbone"], function (idm, Backbone) {
    return Backbone.Collection.extend({
        fetch: function () {
            var _this = this;
            return idm.serviceCall({
                url: "endpoint/oidc"
            })
            .then(function (data) {
                _this.reset(_.map(data, function (r) {
                    return new Backbone.Model(r);
                }));
                return _this;
            });
        }
    });
});
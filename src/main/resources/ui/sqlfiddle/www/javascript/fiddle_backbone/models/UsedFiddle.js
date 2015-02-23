define(["Backbone"], function (Backbone) {

    var UsedFiddle = Backbone.Model.extend({
        defaults: {
            "fragment": "",
            "full_name": "",
            "ddl": "",
            "sql": "",
            "structure": [],
            "sets": []
        },
        initialize: function () {
            this.set("last_used", new Date());
        }
    });

    return UsedFiddle;

});

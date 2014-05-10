define(["jQuery", "Backbone", "fiddle_backbone/models/DBType"], function ($, Backbone, DBType) {
    
    return Backbone.Collection.extend({
        model: DBType,
        fetch: function () {
            var _this = this;
            return $.ajax({
                url: '/openidm/system/fiddles/db_types?_queryFilter=full_name gt ""',
                headers: {
                    "X-OpenIDM-Username" : "anonymous",
                    "X-OpenIDM-Password" : "anonymous",
                    "X-OpenIDM-NoSession" : "true"
                }
            }).then(function (qry) {
                _this.reset(_.map(qry.result, function (r) {
                    return new DBType(r);
                }));
                return _this;
            });
        },
        getSelectedType: function () {
            return this.find(function (dbType) { 
                return dbType.get("selected");
            });
        },
        setSelectedType: function (db_type_id, silentSelected) {
            this.each(function (dbType) {
                dbType.set({"selected": (dbType.id === db_type_id)}, {silent: true});
            });
            if (! silentSelected) {
                this.trigger("change");
            }
        }
                
    });
    
});
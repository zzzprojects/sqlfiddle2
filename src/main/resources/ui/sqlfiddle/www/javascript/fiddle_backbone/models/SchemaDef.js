define(["jquery", "Backbone"], function ($, Backbone) {

    var SchemaDef = Backbone.Model.extend({

        defaults: {
            "ddl":"",
            "short_code":"",
            "simple_name": "",
            "full_name": "",
            "valid": true,
            "errorMessage": "",
            "loading": false,
            "ready": false,
            "schema_structure": [],
            "statement_separator": ";",
            "browserEngines": {}
        },
        reset: function () {
            this.set(this.defaults);
            this.trigger("reloaded");
        },
        build: function () {
            var selectedDBType = this.get("dbType");
            var thisModel = this;

            $.ajax({
                type: "POST",
                url: "/openidm/endpoint/createSchema?_action=create",
                data: JSON.stringify({
                    statement_separator: this.get('statement_separator'),
                    db_type_id: this.get('dbType').id,
                    ddl: this.get('ddl')
                }),
                headers: {
                    "X-OpenIDM-Username" : "anonymous",
                    "X-OpenIDM-Password" : "anonymous",
                    "X-OpenIDM-NoSession" : "true",
                    "Content-Type": "application/json"
                },
                dataType: "json",
                success: function (data, textStatus, jqXHR) {
                    var short_code;

                    if (data._id) {
                        short_code = data._id.split('_')[1];

                        if (selectedDBType.get("context") === "browser") {
                            thisModel.get("browserEngines")[selectedDBType.get("className")].buildSchema({

                                short_code: short_code,
                                statement_separator: thisModel.get('statement_separator'),
                                ddl: thisModel.get('ddl'),
                                success: function () {
                                    thisModel.set({
                                        "short_code": short_code,
                                        "ready": true,
                                        "valid": true,
                                        "errorMessage": ""
                                    });

                                    thisModel.get("browserEngines")[selectedDBType.get("className")].getSchemaStructure({
                                            callback: function (schemaStruct) {
                                                thisModel.set({
                                                    "schema_structure": schemaStruct
                                                });
                                                thisModel.trigger("built");
                                            }
                                        });

                                },
                                error: function (message) {
                                    thisModel.set({
                                        "short_code": short_code,
                                        "ready": false,
                                        "valid": false,
                                        "errorMessage": message,
                                        "schema_structure": []
                                    });
                                    thisModel.trigger("failed");
                                }

                            });
                        } else {
                            thisModel.set({
                                "short_code": short_code,
                                "ready": true,
                                "valid": true,
                                "errorMessage": ""/*,
                                "schema_structure": data["schema_structure"]*/
                            });

                            thisModel.trigger("built");
                        }

                    }
                    else
                    {
                        thisModel.set({
                            "short_code": "",
                            "ready": false,
                            "valid": false,
                            "errorMessage": data["error"],
                            "schema_structure": []
                        });
                        thisModel.trigger("failed");
                    }
                },
                error: function (jqXHR, textStatus, errorThrown)
                {
                    thisModel.set({
                        "short_code": "",
                        "ready": false,
                        "valid": false,
                        "errorMessage": errorThrown,
                        "schema_structure": []
                    });
                    thisModel.trigger("failed");

                }
            });

        }
    });

    return SchemaDef;

});
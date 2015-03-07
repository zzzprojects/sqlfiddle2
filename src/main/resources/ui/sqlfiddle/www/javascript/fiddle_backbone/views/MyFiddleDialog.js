define ([
        "jquery", "underscore", "Backbone", "Handlebars", 
        "text!../templates/myFiddles.html"
    ],
    function ($,_,Backbone,Handlebars,myFiddlesTemplate) {

    var MyFiddlesDialog = Backbone.View.extend({
        initialize: function (options) {
            this.options = options;
            this.compiledMyFiddlesTemplate = Handlebars.compile(myFiddlesTemplate);
        },
        events: {
            "click .showAll": "showAllFiddlesForSchema",
            "click a.fiddleLink": "showFiddle",
            "click .favoriteLink a": "addFavorite",
            "click button.forgetSchema": "forgetSchema",
            "click button.forgetQuery": "forgetQuery",
            "click button.forgetOtherQueries": "forgetOtherQueries"
        },
        render: function (showDialog) {

                // fiddleHistory is a simple log of all fiddled that have been accessed
            var fiddleHistory = this.collection.toJSON(),

                // groupedHistory cleans up this log so that it is more presentable in the UI
                groupedHistory = _.chain(fiddleHistory)
                                    .groupBy(function (f) {
                                        // extract just the !db/schema portion
                                        return (/^(!\d+\/[^\/]+)/).exec(f.fragment)[0];
                                    })
                                    .pairs()
                                    .map(function (group) {
                                        var sortedFiddles = _.chain(group[1])
                                                                .sortBy(function (f) {
                                                                    // sort the specific entries by the last time they were used, descending
                                                                    return -(new Date(f.last_used)).getTime();
                                                                })
                                                                .map(function (f) {
                                                                    f.dashFragment = f.fragment.replace(/\//g, "-");
                                                                    f.sql = f.sql.substring(0,400);
                                                                    f.last_used = (new Date(f.last_used)).format("mmm d, yyyy HH:MM:ss");
                                                                    return f;
                                                                })
                                                                .value(),

                                            queryFiddles = _.chain(sortedFiddles)
                                                            .filter(function (f) {
                                                                return f.fragment.split("/").length === 3;
                                                            })
                                                            .map(function (f, idx) {
                                                                f.mostRecent = (idx === 0);
                                                                return f;
                                                            })
                                                            .value();

                                        return _.extend(
                                            {
                                                "schemaFragment": group[0],
                                                "schemaGroup": group[0].replace("!", "").replace(/\//g, "-"),
                                                "queries": queryFiddles,
                                                "hasMultipleQueries": (queryFiddles.length > 1)
                                            },
                                            sortedFiddles[0] // the most recently used fiddle for this group will be included at the top level
                                        );
                                    })
                                    // be sure the all of the collections are still sorted with the most recently used on top
                                    .sortBy(function (f) {
                                        return -(new Date(f.last_used)).getTime();
                                    })
                                    .value();


            this.$el.find("#fiddle_history").html(
                this.compiledMyFiddlesTemplate({
                    fiddles: groupedHistory,
                    anonymous: this.isAnonymous
                })
            );

            if (this.isAnonymous) {
                // lame way to disable a bootstrap tab
                this.$el.find("#favorites_tab").addClass('disabled');
                this.$el.find("#favorites_tab a").removeAttr('data-toggle').removeAttr('href');
            } else {
                this.$el.find("#favorites_tab").removeClass('disabled');
                this.$el.find("#favorites_tab a").attr('data-toggle', 'tab').attr('href', '#favorites');

            }

            if (showDialog) {
                this.$el.modal('show');
            }

            $(".preview-schema", this.$el).popover({
                trigger: "hover",
                html: "true",
                placement: "left",
                title: "Schema Structure",
                content: function () {
                    return $(this).closest('td').find('.schemaPreviewWrapper').html();
                }
            });

            $(".preview-ddl", this.$el).popover({
                trigger: "hover",
                html: "true",
                placement: "left",
                title: "Schema DDL",
                content: function () {
                    return $(this).closest('td').find('.schemaPreviewWrapper').html();
                }
            });

            $(".result-sets", this.$el).popover({
                trigger: "hover",
                html: "true",
                placement: "left",
                title: "Query Results",
                content: function(){
                    return $(this).closest('td').find('.resultSetWrapper').html();
                }
            });

            $(".preview-sql", this.$el).popover({
                trigger: "hover",
                html: "true",
                placement: "left",
                title: "SQL Statements",
                content: function () {
                    return $(this).closest('td').find('.resultSetWrapper').html();
                }
            });


            return this;
        },

        showAllFiddlesForSchema: function (e) {
            e.preventDefault();
            this.$el.find("tr.for-schema-" + $(e.target).closest("tr").attr("schemaGroup") ).show("fast");
            //$(this).hide();
        },

        showFiddle: function (e) {
            this.$el.modal('hide');
        },

        forgetSchema: function (e) {
            e.preventDefault();
            var schemaFragment = $(e.target).attr("schemaFragment"),
                fiddleHistory = this.collection.toJSON();

            this.collection.reset(_.reject(fiddleHistory, function (m) {
                return m.fragment.match(new RegExp(schemaFragment + "(/[^/]+)?$"));
            }));
            this.render();
        },

        forgetQuery: function (e) {
            e.preventDefault();
            var fragment = $(e.target).attr("fragment"),
                fiddleHistory = this.collection.toJSON();

            this.collection.reset(_.reject(fiddleHistory, function (m) {
                return m.fragment === fragment;
            }));
            this.render();
        },

        forgetOtherQueries: function (e) {
            e.preventDefault();
            var fragment = $(e.target).attr("fragment"),
                schemaFragment = $(e.target).attr("schemaFragment"),
                fiddleHistory = this.collection.toJSON();

            this.collection.reset(_.reject(fiddleHistory, function (m) {
                return m.fragment.match(new RegExp(schemaFragment + "/[^/]+$")) && m.fragment !== fragment;
            }));
            this.render();
        },
        setAnonymous: function (isAnonymous) {
            this.isAnonymous = isAnonymous;
            this.render();
        },
        addFavorite: function (e) {
            var fragment = $(e.target).attr("fragment");

            e.preventDefault();

        }
/*
            $(".favorite", this).click(function (e) {
                e.preventDefault();
                var thisA = this;
                var containing_row = $(this).closest("tr.queryLog");
                $.post(    "index.cfm/UserFiddles/setFavorite",
                        {
                            schema_def_id: $(this).attr('schema_def_id'),
                            query_id: $(this).attr('query_id'),
                            favorite: $(this).attr('href') == '#addFavorite' ? 1 : 0
                        },
                        function () {
                            if ($(thisA).attr('href') == '#addFavorite')
                            {
                                $(thisA)
                                    .attr('href', '#removeFavorite')
                                    .attr('title', 'Remove from favorites');
                            }
                            else
                            {
                                 $(thisA)
                                    .attr('href', '#addFavorite')
                                    .attr('title', 'Add to favorites');
                            }
                            $("i", thisA).toggleClass("icon-star-empty icon-star");

                            if ($(thisA).closest('.tab-pane').attr("id") == 'favorites') {
                                $(".queryLog[schema_def_id=" + $(thisA).attr('schema_def_id') + "][query_id=" + $(thisA).attr('query_id') + "] a.favorite").replaceWith(thisA);
                            }

                            $("#favorites").load("index.cfm/UserFiddles/getFavorites", {tz: (new Date()).getTimezoneOffset()/60}, setupModal);

                        });
            });

*/

    });

    return MyFiddlesDialog;

});

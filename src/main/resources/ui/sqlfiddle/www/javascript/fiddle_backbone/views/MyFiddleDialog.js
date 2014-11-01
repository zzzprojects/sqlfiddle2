define ([
        "jquery", "underscore", "Backbone", "Handlebars", 
        "text!../templates/myFiddles.html"
    ],
    function ($,_,Backbone,Handlebars,myFiddlesTemplate) {

    var MyFiddlesDialog = Backbone.View.extend({
        initialize: function (options) {
            this.options = options;
            this.compiledTemplate = Handlebars.compile(myFiddlesTemplate);
        },
        events: {
        },
        render: function () {
            this.$el.html(
                this.compiledTemplate({})
            );
            this.$el.modal('show');
            this.$el.find('.modal-body').block({ message: "Loading..."});
            this.collection.fetch();
            return this;
        },
        showFiddles: function () {
            
        }
    });

    return MyFiddlesDialog;

});

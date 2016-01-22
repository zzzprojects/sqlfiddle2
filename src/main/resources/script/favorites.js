(function () {

    if (request.method !== "query" && request.method !== "update") {
        throw {
            "code" : 400
        };
    }


    if (request.method === "query") {

        if (!request.queryId || request.queryId !== "myFavorites") {
            throw {
                "code" : 400,
                "message": "Unsupport query request"
            };
        }

        return openidm.query("system/fiddles/user_fiddles", {
                    "_queryFilter": '/favorite eq true AND /user_id eq "' + context.security.authorization.id + '"'
                });

    } else { // request.method === "update"

    }

}());

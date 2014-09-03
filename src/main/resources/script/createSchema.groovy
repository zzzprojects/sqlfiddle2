
import java.security.MessageDigest

def digest = MessageDigest.getInstance("MD5")
def response = [:]
def content = request.getContent().asMap()

try {

    assert content.db_type_id && content.db_type_id instanceof Integer
    assert content.ddl.size() <= 8000

    def db_type = openidm.read("system/fiddles/db_types/" + content.db_type_id)
    def existing_schema = []
    def schema_def
    def md5hash

    if (content.statement_separator != ";") {
        md5hash = new BigInteger(
                            1, digest.digest( content.ddl.getBytes() )
                        ).toString(16).padLeft(32,"0")
    } else {
        md5hash = new BigInteger(
                            1, digest.digest( (content.statement_separator + content.ddl).getBytes() )
                        ).toString(16).padLeft(32,"0")
    }

    if (!content.statement_separator) {
        content.statement_separator = ";"
    }

    existing_schema = openidm.query("system/fiddles/schema_defs", [
        "_queryFilter": 'md5 eq "'+md5hash+'" and db_type_id eq "'+content.db_type_id+'"'
    ]).result

    assert existing_schema.size() < 2

    if (existing_schema.size() == 1) {
        schema_def = existing_schema[0]
    } else {

        def short_code = md5hash.substring(0,5)
        def checkedUniqueCode = false

        while (!checkedUniqueCode) {
            checkedUniqueCode = 
                openidm.query("system/fiddles/schema_defs", [
                    "_queryFilter": 'short_code eq "'+short_code+'" and db_type_id eq "'+content.db_type_id+'"'
                ])
                .result
                .size() == 0

                if (!checkedUniqueCode) {
                    short_code = md5hash.substring(0,short_code.size()+1)
                }
        }

        // we only need to attempt to create a DB if the context for it is "host"
        if (db_type.context == "host") {

            // if there is an error thrown from here, it will be caught below;
            // It is necessary to build the real db at this stage so that we can fail early if there
            // is a problem (and get a handle on the real error involved in the creation)
            openidm.create("system/hosts/databases", null, [
                "db_type_id": content.db_type_id,
                "schema_name": "db_" + content.db_type_id + "_" + short_code,
                "username": "user_" + content.db_type_id + "_" + short_code,
                "pw": content.db_type_id + "_" + short_code,
                "ddl": content.ddl,
                "statement_separator": content.statement_separator
            ])

        }
        // this schema_def will be linked to the above running db below as part of reconById
        schema_def = openidm.create("system/fiddles/schema_defs", null, [
            "db_type_id": content.db_type_id,
            "short_code": short_code,
            "md5": md5hash,
            "ddl": content.ddl,
            "statement_separator": content.statement_separator
        ])

    }

    assert schema_def != null

    def fragment_parts = schema_def._id.split("_")

    assert fragment_parts.size() == 2

    if (db_type.context == "host") {

        // this ensures that there is a live running db up for the schema_def
        // if this schema was just created for the first time, then it will link to the newly-created DB from above
        response.reconId = openidm.action("recon", "reconById", [:],
            [
                "mapping" : "fiddles_hosts",
                "ids" : schema_def._id,
                "waitForCompletion" : "true"
            ]
        )
    }

    response._id = schema_def._id
    response.short_code = fragment_parts[1]

} catch (e) {
    if (e.cause) {
        response.error = e.cause.message
    } else {
        response.error = e.message
    }
}

response
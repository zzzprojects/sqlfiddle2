def response = [:]

def content = request.getContent().asMap()

assert content.ddl.size() <= 8000

// openidm.create could return either a structure with a new _id value or an existing _id value
def schema_def = openidm.create("system/fiddles/schema_defs", null, [
        "db_type_id": content.db_type_id,
        "ddl": content.ddl,
        "statement_separator": content.statement_separator,
        "md5": "n/a"
    ])

assert schema_def != null

def fragment_parts = schema_def._id.split("_")

assert fragment_parts.size() == 2

schema_def = openidm.read("system/fiddles/schema_defs/" + schema_def._id)

if (schema_def.context == "host") {

    // Use the presence of a link between fiddle and host db to determine if we need to provision a running instance of this db
    def hostLink = openidm.query("repo/link", [
            "_queryId": "links-for-firstId",
            "linkType": "fiddles_hosts",
            "firstId" : schema_def._id
        ]).result[0]

    def auditDetails

    if (hostLink == null) {
        def recon = openidm.action("recon", 
            "reconById", [:],
            [
                "mapping" : "fiddles_hosts",
                "ids" : schema_def._id,
                "waitForCompletion" : "true"
            ]
        )

        auditDetails = openidm.query("audit/recon", [
            "_queryId": "audit-by-recon-id-type",
            "reconId": recon._id, 
            "entryType": ""
        ])

    }

    if (auditDetails.result[0].status == "SUCCESS") {
        response._id = schema_def._id
        response.short_code = fragment_parts[1]
    } else {
        response.error = auditDetails.result[0].messageDetail.message
        openidm.delete("system/fiddles/schema_defs/" + schema_def._id, null)
    }

} else {
    response._id = schema_def._id
    response.short_code = fragment_parts[1]
}

response
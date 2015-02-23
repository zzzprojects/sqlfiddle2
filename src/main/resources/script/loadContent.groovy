import org.forgerock.json.resource.SecurityContext

def securityContext = context.asContext(SecurityContext.class)
def userId = null

if (securityContext.authorizationId.component == "system/fiddles/users") {
    userId = securityContext.authorizationId.id
}

def fragment_parts = request.resourceName.split("_")

assert fragment_parts.size() > 1

def schema_def = openidm.read("system/fiddles/schema_defs/" + fragment_parts[0] + "_" + fragment_parts[1])

assert schema_def != null

def response = [
        "short_code": schema_def.short_code,
        "ddl": schema_def.ddl,
        "schema_statement_separator": schema_def.statement_separator,
        "schema_structure": schema_def.structure,
        "full_name": schema_def.db_type.full_name
    ]

if (fragment_parts.size() > 2) {

    def query = openidm.read("system/fiddles/queries/" + fragment_parts[0] + "_" + fragment_parts[1] + "_" + fragment_parts[2])
    assert query != null

    response["query_statement_separator"] = query.statement_separator
    response["sql"] = query.sql
    response["id"] = query.query_id
    response["sets"] = openidm.action("endpoint/executeQuery", "query", [
            "db_type_id": fragment_parts[0],
            "schema_short_code": fragment_parts[1],
            "sql": query.sql,
            "statement_separator": query.statement_separator
        ]).sets

} else if (userId != null) {

    openidm.update("system/fiddles/users/" + userId, null, [
        "fiddles" : [
            ["schema_def_id": schema_def.schema_def_id]
        ]
    ])

}

response
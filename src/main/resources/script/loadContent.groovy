def fragment_parts = request.resourceName.split("_")

assert fragment_parts.size() > 1

def schema_def = openidm.read("system/fiddles/schema_defs/" + fragment_parts[0] + "_" + fragment_parts[1])

assert schema_def != null

def response = [
        "short_code": schema_def.short_code,
        "ddl": schema_def.ddl,
        "schema_statement_separator": schema_def.statement_separator
    ]

if (fragment_parts.size() > 2) {

    def query = openidm.read("system/fiddles/queries/" + fragment_parts[0] + "_" + fragment_parts[1] + "_" + fragment_parts[2])
    assert query != null

    response["query_statement_separator"] = query.statement_separator
    response["sql"] = query.sql
    response["id"] = query.id

    response["sets"] = openidm.action("endpoint/executeQuery", "query", [:], [
            "db_type_id": fragment_parts[0],
            "schema_short_code": fragment_parts[1],
            "sql": query.sql,
            "statement_separator": query.statement_separator
        ]).sets

}

response
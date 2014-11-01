import org.forgerock.json.resource.SecurityContext
import groovy.json.JsonBuilder
import groovy.transform.InheritConstructors
import groovy.sql.Sql
import groovy.sql.DataSet
import java.security.MessageDigest
import java.util.regex.Pattern

@InheritConstructors
class PostgreSQLException extends Exception {}

def content = request.getContent().asMap()

assert content.sql
assert content.db_type_id
assert content.schema_short_code

assert content.sql.size() <= 8000

def execQueryStatement(connection, statement, rethrow) {

    def set = [ RESULTS: [ COLUMNS: [], DATA: [] ], SUCCEEDED: true, STATEMENT: statement ]
    long startTime = (new Date()).toTimestamp().getTime()

    try {

        connection.eachRow(statement, { row ->
            def meta = row.getMetaData()
            int columnCount = meta.getColumnCount()
            int i = 0
            def data = []

            // this would only be true for the first row in the set
            if (set.RESULTS.COLUMNS.size() == 0) {
                set.EXECUTIONTIME = ((new Date()).toTimestamp().getTime() - startTime)
                for (i = 1; i <= columnCount; i++) {
                    set.RESULTS.COLUMNS.add(meta.getColumnName(i))
                }
            }

            for (i = 0; i < columnCount; i++) {
                switch ( meta.getColumnType((i+1)) ) {
                    case java.sql.Types.TIMESTAMP: 
                        data.add(row.getAt(i).format("MMMM, dd yyyy HH:mm:ss"))
                    break;

                    case java.sql.Types.TIME: 
                        data.add(row.getAt(i).format("MMMM, dd yyyy HH:mm:ss"))
                    break;

                    case java.sql.Types.DATE: 
                        data.add(row.getAt(i).format("MMMM, dd yyyy HH:mm:ss"))
                    break;

                    default: 
                        data.add(row.getAt(i))
                }
            }

            set.RESULTS.DATA.add(data)

        })

    } catch (e) {
        def errorMessage = e.getMessage()
        // terrible, but if you have a better idea please post it here: http://stackoverflow.com/q/22592508/808921
        if ( ((Boolean) errorMessage =~ /No results were returned by the query/)) {
            set.EXECUTIONTIME = ((new Date()).toTimestamp().getTime() - startTime)
        } else if ( ((Boolean) errorMessage =~ /current transaction is aborted, commands ignored until end of transaction block$/) && rethrow) {
            throw new PostgreSQLException(statement)
        } else if ( ((Boolean) errorMessage =~ /insert or update on table "deferred_.*" violates foreign key constraint "deferred_.*_ref"/)) {
            set.ERRORMESSAGE = "Explicit commits are not allowed within the query panel."
            set.SUCCEEDED = false
        } else if ( 
                ((Boolean) errorMessage =~ /Cannot execute statement in a READ ONLY transaction./) ||
                ((Boolean) errorMessage =~ /Can not issue data manipulation statements with executeQuery/) 
            ) {
            set.ERRORMESSAGE = "DDL and DML statements are not allowed in the query panel for MySQL; only SELECT statements are allowed. Put DDL and DML in the schema panel."
            set.SUCCEEDED = false
        } else {
            set.ERRORMESSAGE = errorMessage
            set.SUCCEEDED = false
        }
    }

    return set
}

def schema_def = openidm.read("system/fiddles/schema_defs/" + content.db_type_id + "_" + content.schema_short_code)
assert schema_def != null

def db_type = schema_def.db_type

// Update the timestamp for the schema_def each time this instance is used, so we know if it should stay running longer
schema_def.last_used = (new Date().format("yyyy-MM-dd HH:mm:ss.S"))
openidm.update("system/fiddles/schema_defs/" + schema_def._id, null, schema_def)

// Save a copy of this query (or retrieve the details of one that already exists)
def query = openidm.create("system/fiddles/queries", 
    null, 
    [
        "md5": "n/a",
        "sql": content.sql,
        "statement_separator": content.statement_separator,
        "schema_def_id": schema_def.schema_def_id
    ]
)

def response = [ID: query.query_id]

def securityContext = context.asContext(SecurityContext.class)

if (securityContext.authorizationId.component == "system/fiddles/users") {

    openidm.update("system/fiddles/users/" + securityContext.authorizationId.id, null, [
        "fiddles" : [
            ["schema_def_id": schema_def.schema_def_id, "query_id": query.query_id]
        ]
    ])

}

if (db_type.context == "host") {

    // Use the presence of a link between fiddle and host db to determine if we need to provision a running instance of this db
    def hostLink = openidm.query("repo/link", [
            "_queryId": "links-for-firstId",
            "linkType": "fiddles_hosts",
            "firstId" : schema_def._id
        ]).result[0]

    if (hostLink == null) {
        openidm.action("recon",
            "reconById", [:],
            [
                "mapping" : "fiddles_hosts",
                "ids" : schema_def._id,
                "waitForCompletion" : "true"
            ]
        )

        hostLink = openidm.query("repo/link", [
            "_queryId": "links-for-firstId",
            "linkType": "fiddles_hosts",
            "firstId" : schema_def._id
        ]).result[0]
    }

    // At this point we should have a link between schema definition and running db; otherwise provisioning 
    // went wrong and we won't be able to connect to this db to perform our query
    assert hostLink != null

    // We get the details about how to connect to the running DB by doing a read on it
    def hostDatabase = openidm.read("system/hosts/databases/" + hostLink.secondId)
    def hostConnection = Sql.newInstance(hostDatabase.jdbc_url, hostDatabase.username, hostDatabase.pw, hostDatabase.jdbc_class_name)


    hostConnection.withStatement { it.queryTimeout = 10 }

    // mysql handles transactions poorly; better to just make the whole thing readonly
    if (db_type.simple_name == "MySQL") {
        hostConnection.getConnection().setReadOnly(true)
    }

    def sets = []
    def deferred_table = "DEFERRED_" + content.db_type_id + "_" + content.schema_short_code

    try {

        hostConnection.withTransaction {

            def separator = content.statement_separator ? content.statement_separator : ";"
            char newline = 10
            char carrageReturn = 13
            def statementGroups = Pattern.compile("([\\s\\S]*?)(?=(" + separator + "\\s*)|\$)")

            if (db_type.batch_separator && db_type.batch_separator.size()) {
                content.sql = content.sql.replaceAll(Pattern.compile(newline + db_type.batch_separator + carrageReturn + "?(" + newline + "|\$)", Pattern.CASE_INSENSITIVE), separator)
            }
            if (db_type.simple_name == "Oracle") {
                hostConnection.execute("INSERT INTO system." + deferred_table + " VALUES (2)")
            } else if (db_type.simple_name == "PostgreSQL" ) {
                hostConnection.execute("INSERT INTO " + deferred_table + " VALUES (2)")
            }

            try {

                (statementGroups.matcher(content.sql)).each { statement ->
                    if (statement[1]?.size() && !((Boolean) statement[1] =~ /^\s*$/)) {

                        def executionPlan = null

                        if (db_type.execution_plan_prefix || db_type.execution_plan_suffix) {
                            def executionPlanSQL = (db_type.execution_plan_prefix?:"") + statement[1] + (db_type.execution_plan_suffix?:"")
                            executionPlanSQL = executionPlanSQL.replaceAll("#schema_short_code#", schema_def.short_code)
                            executionPlanSQL = executionPlanSQL.replaceAll("#query_id#", query.query_id.toString())

                            if (db_type.batch_separator && db_type.batch_separator.size()) {
                                executionPlanSQL = executionPlanSQL.replaceAll(Pattern.compile(newline + db_type.batch_separator + carrageReturn + "?(" + newline + "|\$)", Pattern.CASE_INSENSITIVE), separator)
                            }

                            // the savepoint for postgres allows us to fail safely if users provide DDL in their queries;
                            // normally, this would result in an exception that breaks the rest of the transaction. Save points
                            // preserve the transaction.
                            if (db_type.simple_name == "PostgreSQL") {
                                hostConnection.execute("SAVEPOINT sp;")
                            }

                            (statementGroups.matcher(executionPlanSQL)).each { executionPlanStatement ->
                                if (executionPlanStatement[1]?.size()) {
                                    executionPlan = execQueryStatement(hostConnection,executionPlanStatement[1], false)
                                }
                            }
                            
                            if (db_type.simple_name == "PostgreSQL") {
                                hostConnection.execute("ROLLBACK TO sp;")
                            }

                        }

                        sets.add(execQueryStatement(hostConnection, statement[1], true))

                        if (!sets[sets.size()-1]?.SUCCEEDED) {
                            throw new Exception("Ending query execution")
                        } else if (executionPlan?.SUCCEEDED) {
                            sets[sets.size()-1].EXECUTIONPLAN = executionPlan.RESULTS
                            sets[sets.size()-1].EXECUTIONPLANRAW = executionPlan.RESULTS
                        }

                    }

                }
            } catch (PostgreSQLException e) {
                throw e
            } catch (e) {
                // most likely the result of the inner throw "Ending query execution"
            }

            hostConnection.rollback();
        }

    } catch (PostgreSQLException e) {
        sets.add(execQueryStatement(hostConnection, e.getMessage(), false))
    }

    hostConnection.close()

    if (query.query_sets.size() != sets.size()) {
        int i = 0
        query.query_sets = []

        sets.each {
            String columns_list = it.RESULTS?.COLUMNS?.join(",")
            if (columns_list && columns_list.size() > 500) {
                columns_list = columns_list.substring(0,500)
            }

            i++
            query.query_sets.add([
                id : i,
                row_count : it.RESULTS?.DATA?.size() ?: 0,
                execution_time : it.EXECUTIONTIME ?: 0,
                execution_plan : it.EXECUTIONPLANRAW != null ? (new JsonBuilder(it.EXECUTIONPLANRAW).toString()) : "",
                succeeded : it.SUCCEEDED ? 1 : 0,
                error_message : it.ERRORMESSAGE ?: "",
                sql : it.STATEMENT ?: "",
                columns_list : columns_list ?: ""
            ])
        }

        openidm.update("system/fiddles/queries/" + query._id, null, query)
    }

    response.sets = sets

}
response
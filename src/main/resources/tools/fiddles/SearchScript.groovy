/*
 *
 * Copyright (c) 2010 ForgeRock Inc. All Rights Reserved
 *
 * The contents of this file are subject to the terms
 * of the Common Development and Distribution License
 * (the License). You may not use this file except in
 * compliance with the License.
 *
 * You can obtain a copy of the License at
 * http://www.opensource.org/licenses/cddl1.php or
 * OpenIDM/legal/CDDLv1.0.txt
 * See the License for the specific language governing
 * permission and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL
 * Header Notice in each file and include the License file
 * at OpenIDM/legal/CDDLv1.0.txt.
 * If applicable, add the following below the CDDL Header,
 * with the fields enclosed by brackets [] replaced by
 * your own identifying information:
 * "Portions Copyrighted 2010 [name of copyright owner]"
 *
 * $Id$
 */
import groovy.json.JsonSlurper
import groovy.sql.Sql
import groovy.sql.DataSet
import org.identityconnectors.framework.common.objects.AttributeBuilder
import org.identityconnectors.framework.common.objects.filter.Filter
import org.forgerock.openicf.misc.scriptedcommon.MapFilterVisitor

//Need to handle the __UID__ and __NAME__ in queries
def fieldMap = [
    "users": [
        "__NAME__": "u.subject",
        "__UID__": "u.issuer = ? AND u.subject = ?"
    ],
    "db_types": [
        "__NAME__": "d.full_name",
        "__UID__": "d.id"
    ],
    "schema_defs": [
        "__NAME__": "s.md5",
        "__UID__": "s.db_type_id = ? AND s.short_code = ?",
        "schema_def_id": "s.id",
        "minutes_since_last_used": "last_used"
    ],
    "queries": [
        "__NAME__": "q.md5",
        "query_id": "q.id",
        "__UID__": "s.db_type_id = ? AND s.short_code = ? AND q.id = ?"
    ]
]

def whereTemplates = [
    CONTAINS:'$left ${not ? "NOT " : ""}LIKE ?',
    ENDSWITH:'$left ${not ? "NOT " : ""}LIKE ?',
    STARTSWITH:'$left ${not ? "NOT " : ""}LIKE ?',
    EQUALS:'$left ${not ? "<>" : "="} ?',
    GREATERTHAN:'$left ${not ? "<=" : ">"} ?',
    GREATERTHANOREQUAL:'$left ${not ? "<" : ">="} ?',
    LESSTHAN:'$left ${not ? ">=" : "<"} ?',
    LESSTHANOREQUAL:'$left ${not ? ">" : "<="} ?'
]

def whereParams = []
def queryParser

queryParser = { queryObj ->

    if (queryObj.operation == "OR" || queryObj.operation == "AND") {
        return "(" + queryParser(queryObj.right) + " " + queryObj.operation + " " + queryParser(queryObj.left) + ")"
    } else {


        // special cases for concatenated-keys
        if (objectClass.objectClassValue == "users" && queryObj.get("left") == "__UID__") {
            def user_parts = queryObj.get("right").split(":")
            assert user_parts.size() == 2

            whereParams.push(user_parts[0])
            whereParams.push(user_parts[1])

            return fieldMap[objectClass.objectClassValue][queryObj.get("left")]

        } else if (objectClass.objectClassValue == "schema_defs" && queryObj.get("left") == "__UID__") {
            def fragment_parts = queryObj.get("right").split("_")
            assert fragment_parts.size() == 2

            whereParams.push(fragment_parts[0].toInteger())
            whereParams.push(fragment_parts[1])

            return fieldMap[objectClass.objectClassValue][queryObj.get("left")]

        } else if (objectClass.objectClassValue == "queries" && queryObj.get("left") == "__UID__") {
            def fragment_parts = queryObj.get("right").split("_")
            assert fragment_parts.size() == 3

            whereParams.push(fragment_parts[0].toInteger())
            whereParams.push(fragment_parts[1])
            whereParams.push(fragment_parts[2].toInteger())

            return fieldMap[objectClass.objectClassValue][queryObj.get("left")]

        } else if (queryObj.get("left") == "minutes_since_last_used") {

            int rightSide = queryObj.get("right").toInteger()
            return fieldMap[objectClass.objectClassValue][queryObj.get("left")] + " >= (current_timestamp - interval '${rightSide} minutes')"

        } else {

            if (queryObj.get("operation") == "CONTAINS") {

                whereParams.push("%" + queryObj.get("right") + "%")

            } else if (queryObj.get("operation") == "ENDSWITH") {

                whereParams.push("%" + queryObj.get("right"))

            } else if (queryObj.get("operation") == "STARTSWITH") {

                whereParams.push(queryObj.get("right") + "%")

            // integer parameters
            } else if (queryObj.get("left") == "schema_def_id" ||
                       queryObj.get("left") == "db_type_id" ||
                       (objectClass.objectClassValue == "db_types" && queryObj.get("left") == "__UID__")) {

                whereParams.push(queryObj.get("right").toInteger())

            } else {
                whereParams.push(queryObj.get("right"))
            }

            

            if (fieldMap[objectClass.objectClassValue] && fieldMap[objectClass.objectClassValue][queryObj.get("left")]) {
                queryObj.put("left",fieldMap[objectClass.objectClassValue][queryObj.get("left")])
            }

            def engine = new groovy.text.SimpleTemplateEngine()
            def wt = whereTemplates.get(queryObj.get("operation"))
            def binding = [left:queryObj.get("left"),not:queryObj.get("not")]
            def template = engine.createTemplate(wt).make(binding)

            return template.toString()

        }
    }
}

def sql = new Sql(connection)
def filter = filter as Filter

def where = ""

if (filter != null) {

    def query = filter.accept(MapFilterVisitor.INSTANCE, null)

    if (query != null) {
        // We can use Groovy template engine to generate our custom SQL queries
        where = "WHERE " + queryParser(query)
        //println("Search WHERE clause is: ${where} + ${whereParams}")
    }
}

switch ( objectClass.objectClassValue ) {

    case "users":
    sql.eachRow("""
        SELECT
            u.id,
            u.issuer,
            u.subject,
            u.email
        FROM
            users u
        ${where}
    """, whereParams) { row ->
        handler {
            id row.subject
            uid row.issuer + ":" + row.subject as String
            attribute 'issuer', row.issuer
            attribute 'subject', row.subject
            attribute 'email', row.email
        }

    }
    break

    case "schema_defs":

    sql.eachRow("""
        SELECT 
            s.id,
            s.md5,
            s.db_type_id,
            s.short_code,
            to_char(s.last_used, 'YYYY-MM-DD HH24:MI:SS.MS') as last_used,
            floor(EXTRACT(EPOCH FROM age(current_timestamp, last_used))/60) as minutes_since_last_used,
            s.ddl,
            s.statement_separator,
            s.structure_json,
            d.simple_name,
            d.full_name,
            d.context,
            d.batch_separator
        FROM 
            schema_defs s 
                INNER JOIN db_types d ON 
                    s.db_type_id = d.id
        """ + where, whereParams) { row ->

        def structure = row.structure_json != null ? (new JsonSlurper()).parseText(row.structure_json) : null

        handler {
            id row.md5
            uid row.db_type_id + '_' + row.short_code as String
            attribute 'schema_def_id', row.id.toInteger()
            attribute 'db_type_id', row.db_type_id.toInteger()
            attribute 'context', row.context
            attribute 'fragment', row.db_type_id + '_' + row.short_code
            attribute 'ddl', row.ddl
            attribute 'last_used', row.last_used
            attribute 'minutes_since_last_used', (row.minutes_since_last_used != null ? row.minutes_since_last_used.toInteger(): null)
            attribute 'short_code', row.short_code
            attribute 'statement_separator', row.statement_separator
            attribute 'db_type', [
                    id : row.db_type_id.toInteger(),
                    context : row.context,
                    simple_name : row.simple_name,
                    full_name : row.full_name,
                    batch_separator : row.batch_separator
                ]
            attribute 'structure', structure
            
        }

    }
    break

    case "queries":

    def dataCollector = [ uid: "" ]

    def handleCollectedData = {
        if (dataCollector.uid != "") {
            // we must be done with the previous set, so handle it

            handler {
                id dataCollector.id
                uid dataCollector.uid
                attribute 'fragment', dataCollector.uid
                attribute 'md5', dataCollector.id
                attribute 'query_id', dataCollector.query_id
                attribute 'schema_def_id', dataCollector.schema_def_id
                attribute 'sql', dataCollector.sql
                attribute 'statement_separator', dataCollector.statement_separator
                attributes AttributeBuilder.build('query_sets',  dataCollector.query_sets)
            }

        }
    }

    sql.eachRow("""
        SELECT 
            q.schema_def_id,
            q.id,
            s.db_type_id,
            s.short_code,
            q.sql,
            q.statement_separator,
            q.md5,
            qs.id as query_set_id,
            qs.row_count,
            qs.execution_time,
            qs.execution_plan,
            qs.succeeded,
            qs.error_message,
            qs.sql as query_set_sql,
            qs.columns_list
        FROM 
            schema_defs s
                INNER JOIN queries q ON
                    q.schema_def_id = s.id
                LEFT OUTER JOIN query_sets qs ON
                    q.id = qs.query_id AND
                    q.schema_def_id = qs.schema_def_id
        ${where}
        ORDER BY
            q.schema_def_id,
            q.id,
            qs.id
        """, whereParams) { row ->

        if (dataCollector.uid != row.db_type_id + '_' + row.short_code + '_' + row.id) {

            handleCollectedData();

            dataCollector = [
                id : row.md5,
                uid : (row.db_type_id + '_' + row.short_code + '_' + row.id) as String,
                query_id : row.id.toInteger(),
                schema_def_id : row.schema_def_id.toInteger(),
                sql : row.sql,
                statement_separator : row.statement_separator,
                query_sets : [ ]
            ]
        }

        if (row.query_set_id) {
            dataCollector.query_sets.add([
                id : row.query_set_id.toInteger(),
                row_count : row.row_count,
                execution_time : row.execution_time,
                execution_plan : row.execution_plan,
                succeeded : row.succeeded,
                error_message : row.error_message,
                sql : row.query_set_sql,
                columns_list : row.columns_list
            ])
        }
    }

    handleCollectedData();

    break

    case "db_types":
    sql.eachRow("""
        SELECT
            d.id,
            d.context,
            d.full_name,
            d.simple_name,
            d.jdbc_class_name,
            d.sample_fragment,
            d.batch_separator,
            d.execution_plan_prefix,
            d.execution_plan_suffix,
            d.execution_plan_xslt,
            count(h.id) as num_hosts
        FROM
            db_types d
                LEFT OUTER JOIN hosts h ON
                    d.id = h.db_type_id
        ${where}
        GROUP BY
            d.id,
            d.context,
            d.full_name,
            d.simple_name,
            d.jdbc_class_name,
            d.sample_fragment,
            d.batch_separator,
            d.execution_plan_prefix,
            d.execution_plan_suffix,
            d.execution_plan_xslt
        ORDER BY
            d.simple_name,
            d.is_latest_stable desc,
            d.full_name desc
    """, whereParams) { row ->
        handler {
            id row.full_name
            uid row.id as String
            attribute 'context', row.context
            attribute 'simple_name', row.simple_name
            attribute 'className', row.jdbc_class_name
            attribute 'sample_fragment', row.sample_fragment
            attribute 'batch_separator', row.batch_separator
            attribute 'execution_plan_prefix', row.execution_plan_prefix
            attribute 'execution_plan_suffix', row.execution_plan_suffix
            attribute 'execution_plan_xslt', row.execution_plan_xslt
            attribute 'num_hosts', row.num_hosts
        }

    }
    break
}

return new SearchResult()

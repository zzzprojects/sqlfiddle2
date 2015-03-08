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
 
import groovy.sql.Sql
import groovy.sql.DataSet
import java.util.regex.Pattern
import org.identityconnectors.framework.common.objects.AttributesAccessor
import org.identityconnectors.framework.common.exceptions.ConnectorException
import org.identityconnectors.framework.common.objects.Uid


def createAttributes = new AttributesAccessor(attributes as Set<Attribute>)

def sql = new Sql(connection)

def findAvailableHost = { db_type_id ->
    def query = """\
        SELECT
            h.*
        FROM
            Hosts h
        WHERE
            db_type_id = ? AND
            not exists (
                SELECT 
                    1
                FROM
                    Hosts h2
                WHERE   
                    h2.id != h.id AND
                    h2.db_type_id = h.db_type_id AND
                    coalesce((SELECT count(s.id) FROM schema_defs s WHERE s.current_host_id = h2.id), 0) < 
                    coalesce((SELECT count(s.id) FROM schema_defs s WHERE s.current_host_id = h.id), 0)
            )
    """;

    def row = sql.firstRow(query, [db_type_id])

    return row.id
}

switch ( objectClass.objectClassValue ) {
    case "databases":
        String delimiter = (char) 7
        String newline = (char) 10
        String carrageReturn = (char) 13

        def host_id = findAvailableHost(createAttributes.findInteger("db_type_id"))

        sql.eachRow("""\
            SELECT 
                d.setup_script_template, 
                d.drop_script_template, 
                d.batch_separator,
                d.jdbc_class_name,
                h.jdbc_url_template,
                h.default_database,
                h.admin_username,
                h.admin_password
            FROM 
                db_types d
                    INNER JOIN hosts h ON
                        d.id = h.db_type_id
            WHERE 
                h.id = ?
            """, [host_id]) {

            def setup_script = it.setup_script_template
            def drop_script = it.drop_script_template
            def batch_separator = it.batch_separator
            def populatedUrl = it.jdbc_url_template.replace("#databaseName#", it.default_database)

            def adminHostConnection = Sql.newInstance(populatedUrl, it.admin_username, it.admin_password, it.jdbc_class_name)

            // the setup scripts expect "databaseName" placeholders in the form of 2_abcde, 
            // but the id is the form db_2_abcde (the scripts will add the "db_" prefix as needed)
            // This could probably be made neater...
            setup_script = setup_script.replaceAll('#databaseName#', id.replaceFirst("db_", ""))
            drop_script = drop_script.replaceAll('#databaseName#', id.replaceFirst("db_", ""))

            if (batch_separator && batch_separator.size()) {
                setup_script = setup_script.replaceAll(Pattern.compile(newline + batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), delimiter)
                drop_script = drop_script.replaceAll(Pattern.compile(newline + batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), delimiter)
            }

            setup_script.tokenize(delimiter).each {
                adminHostConnection.execute(it)
            }

            populatedUrl = it.jdbc_url_template.replaceAll("#databaseName#", id)
            hostConnection = Sql.newInstance(populatedUrl, createAttributes.findString("username"), createAttributes.findString("pw"), it.jdbc_class_name)

            hostConnection.withStatement { it.queryTimeout = 10 }

            def ddl = ""
            if (createAttributes.findString("ddl")) {
                ddl = createAttributes.findString("ddl")
            }

            def statement_separator = ";"
            if (createAttributes.findString("statement_separator")) {
                statement_separator = createAttributes.findString("statement_separator")
            }

            if (batch_separator && batch_separator.size()) {
                ddl = ddl.replaceAll(Pattern.compile(newline + batch_separator + carrageReturn + "?(" + newline + '|$)', Pattern.CASE_INSENSITIVE), statement_separator)
            }

            try {
                // this monster regexp parses the query block by breaking it up into statements, each with three groups - 
                // 1) Positive lookbehind - this group checks that the preceding characters are either the start or a previous separator
                // 2) The main statement body - this is the one we execute
                // 3) The end of the statement, as indicated by a terminator at the end of the line or the end of the whole DDL
                (Pattern.compile("(?<=(" + statement_separator + ")|^)([\\s\\S]*?)(?=(" + statement_separator + "\\s*\\n+)|(" + statement_separator + "\\s*\$)|\$)").matcher(ddl)).each {
                    if (it[0].size() && ((Boolean) it[0] =~ /\S/) ) {
                        hostConnection.execute(it[0])
                    }
                }
            } catch (e) {
                hostConnection.close()
                drop_script.tokenize(delimiter).each { adminHostConnection.execute(it) }
                throw new ConnectorException(e.getMessage())
            } finally {
                hostConnection.close()
                adminHostConnection.close()
            }



        }


    break
}

return new Uid(id as String)

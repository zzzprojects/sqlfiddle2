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
import java.security.MessageDigest
import org.identityconnectors.framework.common.objects.AttributesAccessor
import org.identityconnectors.framework.common.objects.Uid

def createAttributes = new AttributesAccessor(attributes as Set<Attribute>)

def digest = MessageDigest.getInstance("MD5")
def sql = new Sql(connection)

//Create must return UID. 

switch ( objectClass.objectClassValue ) {

    case "users":

        sql.executeInsert("""
            INSERT INTO 
                users
            (
                issuer,
                subject,
                email
            ) 
            VALUES (?,?,?)
            """,
            [
                createAttributes.findString("issuer"),
                id,
                createAttributes.findString("email")
            ])

        return new Uid(createAttributes.findString("issuer") + ":" + id)

    break

    case "schema_defs":

        sql.executeInsert("""
            INSERT INTO 
                schema_defs 
            (
                db_type_id,
                short_code,
                ddl,
                md5,
                statement_separator,
                last_used
            ) 
            VALUES (?,?,?,?,?,current_timestamp)
            """,
            [
                createAttributes.findInteger("db_type_id"),
                createAttributes.findString("short_code"),
                createAttributes.findString("ddl"),
                id,
                createAttributes.findString("statement_separator")
            ])

        return new Uid(createAttributes.findInteger("db_type_id").toString() + "_" + createAttributes.findString("short_code") as String)


    break

    // queries will return an existing ID if provided with duplicate sql
    case "queries":

        def statement_separator = createAttributes.findString("statement_separator")
        def sql_query = createAttributes.findString("sql")
        def schema_def_id = createAttributes.findInteger("schema_def_id")

        def md5hash

        if (statement_separator != ";") {
            md5hash = new BigInteger(
                                1, digest.digest( sql_query.getBytes() )
                            ).toString(16).padLeft(32,"0")
        } else {
            md5hash = new BigInteger(
                                1, digest.digest( (statement_separator + sql_query).getBytes() )
                            ).toString(16).padLeft(32,"0")
        }

        def existing_query = sql.firstRow("""
            SELECT 
                q.id as queryId,
                s.db_type_id,
                s.short_code
            FROM
                schema_defs s
                    LEFT OUTER JOIN queries q ON
                       s.id = q.schema_def_id AND
                       q.md5 = ?
            WHERE
                s.id = ?
            """, [md5hash, schema_def_id])

        if (!existing_query.queryId) {
            def new_query
            sql.withTransaction {

                sql.execute(
                    """
                    INSERT INTO
                        queries
                    (
                        id,
                        md5,
                        sql,
                        statement_separator,
                        schema_def_id
                    )
                    SELECT  
                        count(*) + 1, ?, ?, ?, ?
                    FROM
                        queries
                    WHERE
                        schema_def_id = ?
                    """, 
                    [
                        md5hash,
                        sql_query,
                        statement_separator,
                        schema_def_id,
                        schema_def_id
                    ]
                )

                new_query = sql.firstRow("""
                    SELECT
                        max(id) as queryId
                    FROM
                        queries
                    WHERE
                        schema_def_id = ?
                    """,
                    [
                        schema_def_id
                    ]
                )
            }
            return new Uid((existing_query.db_type_id + "_" + existing_query.short_code + "_" + new_query.queryId) as String)
        } else {
            return new Uid((existing_query.db_type_id + "_" + existing_query.short_code + "_" + existing_query.queryId) as String)
        }

    break
}

throw new UnsupportedOperationException(operation.name() + " operation of type:" +
                objectClass.objectClassValue + " is not supported.")

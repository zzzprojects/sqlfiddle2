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

import groovy.sql.Sql;
import groovy.sql.DataSet;
import java.security.MessageDigest

def digest = MessageDigest.getInstance("MD5")

// Parameters:
// The connector sends us the following:
// connection : SQL connection
// action: String correponding to the action ("CREATE" here)
// log: a handler to the Log facility
// objectClass: a String describing the Object class (__ACCOUNT__ / __GROUP__ / other)
// id: The entry identifier (OpenICF "Name" atribute. (most often matches the uid)
// attributes: an Attribute Map, containg the <String> attribute name as a key
// and the <List> attribute value(s) as value.
// password: password string, clear text
// options: a handler to the OperationOptions Map

def sql = new Sql(connection);

//Create must return UID. 

switch ( objectClass ) {

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
                attributes.get("db_type_id").get(0).toInteger(),
                attributes.get("short_code").get(0),
                attributes.get("ddl").get(0),
                id,
                attributes.get("statement_separator").get(0)
            ])

        return attributes.get("db_type_id").get(0).toInteger() + "_" + attributes.get("short_code").get(0)


    break

    // queries will return an existing ID if provided with duplicate sql
    case "queries":

        def statement_separator = attributes.get("statement_separator").get(0)
        def sql_query = attributes.get("sql").get(0)
        def schema_def_id = attributes.get("schema_def_id").get(0).toInteger()

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
                (
                    SELECT 
                        q.id
                    FROM 
                        queries q
                    WHERE 
                        q.schema_def_id = s.id AND
                        q.md5 = ?
                ) as queryId,
                s.db_type_id,
                s.short_code
            FROM
                schema_defs s
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
            return existing_query.db_type_id + "_" + existing_query.short_code + "_" + new_query.queryId
        } else {
            return existing_query.db_type_id + "_" + existing_query.short_code + "_" + existing_query.queryId
        }

    break

    default:
    id;
}

return id;

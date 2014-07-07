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

// Parameters:
// The connector sends the following:
// connection: handler to the SQL connection
// objectClass: a String describing the Object class (__ACCOUNT__ / __GROUP__ / other)
// action: a string describing the action ("SYNC" or "GET_LATEST_SYNC_TOKEN" here)
// log: a handler to the Log facility
// options: a handler to the OperationOptions Map (null if action = "GET_LATEST_SYNC_TOKEN")
// token: a handler to an Object representing the sync token (null if action = "GET_LATEST_SYNC_TOKEN")
//
//
// Returns:
// if action = "GET_LATEST_SYNC_TOKEN", it must return an object representing the last known
// sync token for the corresponding ObjectClass
// 
// if action = "SYNC":
// A list of Maps . Each map describing one update:
// Map should look like the following:
//
// [
// "token": <Object> token object (could be Integer, Date, String) , [!! could be null]
// "operation":<String> ("CREATE_OR_UPDATE"|"DELETE"),
// "uid":<String> uid  (uid of the entry) ,
// "previousUid":<String> prevuid (This is for rename ops) ,
// "password":<String> password (optional... allows to pass clear text password if needed),
// "attributes":Map<String,List> of attributes name/values
// ]

log.info("Entering "+action+" Script");
def sql = new Sql(connection);

switch ( objectClass ) {
    case "schema_defs":

        if (action.equalsIgnoreCase("GET_LATEST_SYNC_TOKEN")) {

            row = sql.firstRow("""
                SELECT 
                    to_char(max(last_used), 'YYYY-MM-DD HH24:MI:SS.MS') as latest_used 
                FROM 
                    schema_defs
            """)
            println ("Sync token found: " + row["latest_used"])
            return row["latest_used"]

        } else if (action.equalsIgnoreCase("SYNC")) {
            def result = []

            sql.eachRow("""
                SELECT
                    s.id,
                    s.db_type_id,
                    s.short_code,
                    to_char(s.last_used, 'YYYY-MM-DD HH24:MI:SS.MS') as last_used,
                    floor(EXTRACT(EPOCH FROM age(current_timestamp, last_used))/60) as minutes_since_last_used,
                    s.ddl,
                    s.statement_separator
                FROM 
                    schema_defs s
                WHERE 
                    last_used > ?
                """, [Date.parse("yyyy-MM-dd HH:mm:ss.S", token).toTimestamp()]) {

                println ("Found record: " + it.db_type_id + '_' + it.short_code)

                result.add([
                    operation: "CREATE_OR_UPDATE", 
                    uid: it.db_type_id + '_' + it.short_code, 
                    token: it.last_used, 
                    attributes: [
                        schema_def_id:it.id.toInteger(),
                        db_type_id:it.db_type_id.toInteger(), 
                        fragment: it.db_type_id + '_' + it.short_code,
                        ddl: it.ddl,
                        last_used:it.last_used,
                        minutes_since_last_used:it.minutes_since_last_used != null ? it.minutes_since_last_used.toInteger(): null, 
                        short_code:it.short_code,
                        statement_separator:it.statement_separator
                    ]
                ])
            }
            println result
            return result

        } else { // action not implemented
            log.error("Sync script: action '"+action+"' is not implemented in this script")
            return null;
        }

    break

    default: 
        return null

}
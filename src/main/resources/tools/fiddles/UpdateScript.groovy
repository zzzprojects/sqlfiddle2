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
import org.forgerock.openicf.misc.scriptedcommon.OperationType
import org.identityconnectors.framework.common.exceptions.ConnectorException
import org.identityconnectors.framework.common.objects.AttributesAccessor

def operation = operation as OperationType
def sql = new Sql(connection)
def updateAttributes = new AttributesAccessor(attributes as Set<Attribute>)

switch ( operation ) {
    case OperationType.UPDATE:
    switch ( objectClass.objectClassValue ) {

        case "users":
            def fiddles = updateAttributes.findList("fiddles")
            def user_parts = uid.uidValue.split(":")
            assert fiddles != null
            assert fiddles.size() == 1 && fiddles[0] != null // can only update one fiddle entry at a time
            assert fiddles[0].schema_def_id != null
            assert user_parts.size() == 2

            def queryIdClause
            def whereParams = [
                    user_parts[0],
                    user_parts[1],
                    fiddles[0].schema_def_id
                ]

            if (fiddles[0].query_id == null) {
                queryIdClause = " IS NULL"
            } else {
                whereParams.push(fiddles[0].query_id)
                queryIdClause = " = ?"
            }

            def existingHistory = sql.firstRow("""
                SELECT
                    uf.id
                FROM
                    user_fiddles uf
                        INNER JOIN users u ON
                            uf.user_id = u.id
                WHERE
                    u.issuer = ? AND
                    u.subject = ? AND
                    uf.schema_def_id = ? AND
                    uf.query_id ${queryIdClause}
                """,
                whereParams
                );

            if (existingHistory == null) {
                sql.executeInsert("""
                    INSERT INTO
                        user_fiddles
                    (
                        user_id,
                        schema_def_id,
                        query_id
                    )
                    SELECT
                        u.id,
                        ?,
                        ?
                    FROM
                        users u
                    WHERE
                        u.issuer = ? AND
                        u.subject = ?
                """, [
                    fiddles[0].schema_def_id,
                    fiddles[0].query_id, // can be null
                    user_parts[0],
                    user_parts[1]
                ]);
            } else {
                sql.executeUpdate("""
                    UPDATE
                        user_fiddles
                    SET
                        last_accessed = now(),
                        num_accesses = num_accesses + 1
                    WHERE
                        id = ?
                """, [
                    existingHistory.id
                ]);
            }

        break;

        case "schema_defs":
        def fragment_parts = uid.uidValue.split("_")
        assert fragment_parts.size() == 2
        sql.executeUpdate("""
            UPDATE 
                schema_defs s 
            SET 
                last_used = ? 
            WHERE 
                s.db_type_id  = ? AND
                s.short_code = ?
            """,
            [
                Date.parse("yyyy-MM-dd HH:mm:ss.S", updateAttributes.findString("last_used")).toTimestamp(),
                fragment_parts[0].toInteger(),
                fragment_parts[1]
            ]
        )
        break

        case "queries":
        def fragment_parts = uid.uidValue.split("_")
        assert fragment_parts.size() == 3

        // the only thing a query can update is its "sets", so delete any that already exist (shouldn't happen) and 
        // insert all the new ones that come in
        sql.withTransaction {

            sql.execute("""
                DELETE FROM
                    query_sets
                WHERE
                    query_id = ? AND
                    schema_def_id = ?
            """,[
                updateAttributes.findInteger("query_id"),
                updateAttributes.findInteger("schema_def_id")
            ]);


            int i = 0;

            updateAttributes.findList("query_sets").each {
                i++;
                sql.execute("""
                    INSERT INTO
                        query_sets
                    (
                        id,
                        query_id,
                        schema_def_id,
                        row_count,
                        execution_time,
                        succeeded,
                        sql,
                        execution_plan,
                        error_message,
                        columns_list
                    )
                    VALUES (
                        ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
                    )
                """, [
                    i,
                    updateAttributes.findInteger("query_id"),
                    updateAttributes.findInteger("schema_def_id"),
                    it.row_count,
                    it.execution_time,
                    it.succeeded,
                    it.sql,
                    it.execution_plan,
                    it.error_message,
                    it.columns_list
                ]);
            }

        }

        break
    }
    break

    case OperationType.ADD_ATTRIBUTE_VALUES:
        throw new UnsupportedOperationException(operation.name() + " operation of type:" +
                objectClass.objectClassValue + " is not supported.")
    case OperationType.REMOVE_ATTRIBUTE_VALUES:
        throw new UnsupportedOperationException(operation.name() + " operation of type:" +
                objectClass.objectClassValue + " is not supported.")
    default:
        throw new ConnectorException("UpdateScript can not handle operation:" + operation.name())
}

return uid
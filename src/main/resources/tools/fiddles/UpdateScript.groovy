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
def fragment_parts = uid.uidValue.split("_")
def updateAttributes = new AttributesAccessor(attributes as Set<Attribute>)

assert fragment_parts.size() == 2

switch ( operation ) {
    case OperationType.UPDATE:
    switch ( objectClass.objectClassValue ) {

        case "schema_defs":
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
        );
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
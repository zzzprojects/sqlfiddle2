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

// Parameters:
// The connector sends the following:
// connection: handler to the SQL connection
// log: a handler to the Log facility

def sql = new Sql(connection)
def onePassed = false


sql.eachRow("""
    SELECT 
        hosts.jdbc_url_template,
        hosts.default_database,
        hosts.admin_username,
        hosts.admin_password,
        db_types.jdbc_class_name
    FROM 
        db_types 
            INNER JOIN hosts ON
                db_types.id = hosts.db_type_id
""") {
    try {
        def testUrl = it.jdbc_url_template.replaceAll("#databaseName#", it.default_database)
        def testConnection = Sql.newInstance(testUrl, it.admin_username, it.admin_password, it.jdbc_class_name)
        onePassed = true
    } catch (e) {
        // apparently this host isn't available
    }
}

if (!onePassed) {
    throw "No hosts available"
}





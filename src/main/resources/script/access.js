/**
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
 *
 * Copyright (c) 2011-2012 ForgeRock AS. All rights reserved.
 *
 * The contents of this file are subject to the terms
 * of the Common Development and Distribution License
 * (the License). You may not use this file except in
 * compliance with the License.
 *
 * You can obtain a copy of the License at
 * http://forgerock.org/license/CDDLv1.0.html
 * See the License for the specific language governing
 * permission and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL
 * Header Notice in each file and include the License file
 * at http://forgerock.org/license/CDDLv1.0.html
 * If applicable, add the following below the CDDL Header,
 * with the fields enclosed by brackets [] replaced by
 * your own identifying information:
 * "Portions Copyrighted [year] [name of copyright owner]"
 */


// A configuration for allowed HTTP requests. Each entry in the configuration contains a pattern
// to match against the incoming request ID and, in the event of a match, the associated roles,
// methods, and actions that are allowed for requests on that particular pattern.
//
// pattern:  A pattern to match against an incoming request's resource ID
// roles:  A comma separated list of allowed roles
// methods:  A comma separated list of allowed methods
// actions:  A comma separated list of allowed actions
// customAuthz: A custom function for additional authorization logic/checks (optional)
// excludePatterns: A comma separated list of patterns to exclude from the pattern match (optional)
//
// A single '*' character indicates all possible values.  With patterns ending in "/*", the "*"
// acts as a wild card to indicate the pattern accepts all resource IDs "below" the specified
// pattern (prefix).  For example the pattern "managed/*" would match "managed/user" or anything
// starting with "managed/".  Note: it would not match "managed", which would need to have its
// own entry in the config.

/*jslint vars:true*/

var httpAccessConfig =
{
    "configs" : [
        // Anyone can read from these endpoints
        {
           "pattern"    : "info/login",
           "roles"      : "openidm-authorized",
           "methods"    : "read",
           "actions"    : "*"
        },
        {
           "pattern"    : "endpoint/dbTypes",
           "roles"      : "*",
           "methods"    : "read",
           "actions"    : "*"
        },
        {
           "pattern"    : "endpoint/loadContent/*",
           "roles"      : "*",
           "methods"    : "read",
           "actions"    : "*"
        },
        {
           "pattern"    : "endpoint/createSchema",
           "roles"      : "*",
           "methods"    : "create",
           "actions"    : "*"
        },
        {
           "pattern"    : "endpoint/executeQuery",
           "roles"      : "*",
           "methods"    : "action",
           "actions"    : "query"
        },
        {
           "pattern"    : "endpoint/oidc",
           "roles"      : "*",
           "methods"    : "action,read",
           "actions"    : "getToken"
        },
        // openidm-admin can request nearly anything (some exceptions being a few system endpoints)
        {
            "pattern"   : "*",
            "roles"     : "openidm-admin",
            "methods"   : "*", // default to all methods allowed
            "actions"   : "*", // default to all actions allowed
            "customAuthz" : "disallowQueryExpression()",
            "excludePatterns": "system/*"
        },
        // additional rules for openidm-admin that selectively enable certain parts of system/
        {
            "pattern"   : "system/*",
            "roles"     : "openidm-admin",
            "methods"   : "create,read,update,delete,patch,query", // restrictions on 'action'
            "actions"   : "",
            "customAuthz" : "disallowQueryExpression()"
        },
        // Note that these actions are available directly on system as well
        {
            "pattern"   : "system/*",
            "roles"     : "openidm-admin",
            "methods"   : "action",
            "actions"   : "test,testConfig,createconfiguration,liveSync"
        }
    ]
};

// Additional custom authorization functions go here

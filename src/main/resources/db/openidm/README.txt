To initialize your PostgreSQL 9.3 (or greater) OpenIDM repository, follow these steps:

First, edit "createuser.pgsql" and set a proper password for the openidm user.

After saving the file, execute "createuser.pgsql" script like so:

$ psql -U postgres < createuser.pgsql

Next execute the "openidm.pgsql" script using the openidm user that was just created:

$ psql -U openidm < openidm.pgsql

Your database is now initialized. Edit conf/repo.jdcb.json to set the value for "password" 
to be whatever password you set for the openidm user in the first step.
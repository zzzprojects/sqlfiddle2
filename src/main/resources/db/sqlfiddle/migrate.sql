CREATE TABLE users_old (
    id integer NOT NULL,
    email character varying(1000)
);

CREATE TABLE user_fiddles_old (
    id integer NOT NULL,
    user_id integer NOT NULL,
    schema_def_id integer NOT NULL,
    query_id integer,
    last_accessed timestamp without time zone DEFAULT now(),
    num_accesses integer DEFAULT 1,
    show_in_history smallint DEFAULT 1,
    favorite smallint DEFAULT 0
);

-- these servers are hosted remotely, and only available if the connection to that remote environment is available
COPY hosts (id, db_type_id, jdbc_url_template, default_database, admin_username, admin_password) FROM stdin;
5	1	jdbc:postgresql://POSTGRESQL91_HOST:5432/#databaseName#	postgres	postgres	password
6	2	jdbc:mysql://MYSQL55_HOST:3306/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8	mysql	root	password
7	11	jdbc:postgresql://POSTGRESQL84_HOST:5432/#databaseName#	postgres	postgres	password
8	8	jdbc:mysql://MYSQL51_HOST:3306/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8	mysql	root	password
9	12	jdbc:postgresql://POSTGRESQL92_HOST:5432/#databaseName#	postgres	postgres	password
10	13	jdbc:mysql://MYSQL57_HOST:3306/#databaseName#?allowMultiQueries=true&useLocalTransactionState=true&useUnicode=true&characterEncoding=UTF-8	mysql	root	password
\.

SELECT pg_catalog.setval('hosts_id_seq', 11, true);

-- 1589338 is the same schema / query in both the old and the new versions of the site. Deleting it here so that it won't cause a conflict when imported
DELETE FROM queries WHERE schema_def_id = 1589338;
DELETE FROM schema_defs WHERE id = 1589338;

CREATE EXTENSION dblink;

--pg_dump -U postgres -a -t users -t user_fiddles -t query_sets -t schema_defs -t queries sqlfiddle | ssh -i sqlfiddle2pem.pem ubuntu@10.0.0.16 psql -U postgres sqlfiddle
SELECT dblink_connect('sqlfiddle_old', 'dbname=sqlfiddle hostaddr=10.0.0.113 user=postgres');

INSERT INTO users_old (id,email)
SELECT id,email from dblink('sqlfiddle_old', 'SELECT id,email FROM users WHERE openid_server = ''https://www.google.com/accounts/o8/ud''') AS u(id integer, email character varying(1000));

INSERT INTO user_fiddles_old (id,user_id,schema_def_id,query_id,last_accessed,num_accesses,show_in_history,favorite)
SELECT id,user_id,schema_def_id,query_id,last_accessed,num_accesses,show_in_history,favorite
FROM dblink('sqlfiddle_old', 'SELECT uf.id,uf.user_id,uf.schema_def_id,uf.query_id,uf.last_accessed,uf.num_accesses,uf.show_in_history,uf.favorite FROM user_fiddles uf INNER JOIN users u ON u.id = uf.user_id WHERE u.openid_server = ''https://www.google.com/accounts/o8/ud''') 
AS u(id integer,user_id integer,schema_def_id integer,query_id integer,last_accessed timestamp without time zone,num_accesses integer,show_in_history smallint,favorite smallint);

INSERT INTO schema_defs (id,db_type_id,short_code,last_used,ddl,md5,statement_separator,owner_id,structure_json)
SELECT id,db_type_id,short_code,last_used,ddl,md5,statement_separator,owner_id,structure_json
FROM dblink('sqlfiddle_old', 'SELECT id,db_type_id,short_code,last_used,ddl,md5,statement_separator,owner_id,structure_json FROM schema_defs')
as t(
    id integer,
    db_type_id integer,
    short_code character varying(32),
    last_used timestamp without time zone,
    ddl text,
    md5 character varying(32),
    statement_separator character varying(5),
    owner_id integer,
    structure_json text
);

INSERT INTO queries (schema_def_id,sql,md5,id,statement_separator,author_id)
SELECT schema_def_id,sql,md5,id,statement_separator,author_id
FROM dblink('sqlfiddle_old', 'SELECT schema_def_id,sql,md5,id,statement_separator,author_id FROM queries')
as t(
    schema_def_id integer,
    sql text,
    md5 character varying(32),
    id integer,
    statement_separator character varying(5),
    author_id integer
);

INSERT INTO query_sets (id,query_id,schema_def_id,row_count,execution_time,succeeded,sql,execution_plan,error_message,columns_list)
SELECT id,query_id,schema_def_id,row_count,execution_time,succeeded,sql,execution_plan,error_message,columns_list
FROM dblink('sqlfiddle_old', 'SELECT id,query_id,schema_def_id,row_count,execution_time,succeeded,sql,execution_plan,error_message,columns_list FROM query_sets')
as t(
    id integer,
    query_id integer,
    schema_def_id integer,
    row_count integer,
    execution_time integer,
    succeeded smallint,
    sql text,
    execution_plan text,
    error_message text,
    columns_list character varying(500)
);

SELECT dblink_disconnect('sqlfiddle_old');


insert into users (email, id, issuer)
select email, min(id) as id, 'accounts.google.com' as issuer from users_old
group by email;

insert into user_fiddles (user_id, schema_def_id, query_id, last_accessed, num_accesses, show_in_history, favorite)
select u.id, uf.schema_def_id, uf.query_id, uf.last_accessed, uf.num_accesses, uf.show_in_history, uf.favorite
from users u
  inner join user_fiddles_old uf on
    u.id = uf.user_id
UNION
select u2.id, uf.schema_def_id, uf.query_id, uf.last_accessed, uf.num_accesses, uf.show_in_history, uf.favorite
from users_old u
  inner join user_fiddles_old uf on
    u.id = uf.user_id
  inner join users u2 on
    u.email = u2.email
where not exists (select * from users where users.id = u.id);

drop table users_old;
drop table user_fiddles_old;

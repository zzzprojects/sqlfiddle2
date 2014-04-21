
create user openidm with password 'openidm';

create database openidm encoding 'utf8' owner openidm;

grant all privileges on database openidm to openidm;

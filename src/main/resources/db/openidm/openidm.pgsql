DROP SCHEMA IF EXISTS openidm CASCADE;
CREATE SCHEMA openidm AUTHORIZATION openidm;

-- -----------------------------------------------------
-- Table openidm.objecttpyes
-- -----------------------------------------------------

CREATE TABLE openidm.objecttypes (
  id BIGSERIAL NOT NULL,
  objecttype VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT idx_objecttypes_objecttype UNIQUE (objecttype)
);



-- -----------------------------------------------------
-- Table openidm.genericobjects
-- -----------------------------------------------------

CREATE TABLE openidm.genericobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_genericobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_genericobjects_object UNIQUE (objecttypes_id, objectid)
);



-- -----------------------------------------------------
-- Table openidm.genericobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.genericobjectproperties (
  genericobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_genericobjectproperties_genericobjects FOREIGN KEY (genericobjects_id) REFERENCES openidm.genericobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE INDEX fk_genericobjectproperties_genericobjects ON openidm.genericobjectproperties (genericobjects_id);
CREATE INDEX idx_genericobjectproperties_prop ON openidm.genericobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.managedobjects
-- -----------------------------------------------------

CREATE TABLE openidm.managedobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_managedobjects_objectypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_managedobjects_object ON openidm.managedobjects (objecttypes_id,objectid);
CREATE INDEX fk_managedobjects_objectypes ON openidm.managedobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.managedobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.managedobjectproperties (
  managedobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_managedobjectproperties_managedobjects FOREIGN KEY (managedobjects_id) REFERENCES openidm.managedobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_managedobjectproperties_managedobjects ON openidm.managedobjectproperties (managedobjects_id);
CREATE INDEX idx_managedobjectproperties_prop ON openidm.managedobjectproperties (propkey,propvalue);



-- -----------------------------------------------------
-- Table openidm.configobjects
-- -----------------------------------------------------

CREATE TABLE openidm.configobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_configobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_configobjects_object ON openidm.configobjects (objecttypes_id,objectid);
CREATE INDEX fk_configobjects_objecttypes ON openidm.configobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.configobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.configobjectproperties (
  configobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(255) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_configobjectproperties_configobjects FOREIGN KEY (configobjects_id) REFERENCES openidm.configobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_configobjectproperties_configobjects ON openidm.configobjectproperties (configobjects_id);
CREATE INDEX idx_configobjectproperties_prop ON openidm.configobjectproperties (propkey,propvalue);

-- -----------------------------------------------------
-- Table openidm.relationships
-- -----------------------------------------------------

CREATE TABLE openidm.relationships (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_relationships_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_relationships_object UNIQUE (objecttypes_id, objectid)
);

CREATE INDEX idx_json_relationships_firstId ON openidm.relationships
    ( json_extract_path_text(fullobject, 'firstId') );
CREATE INDEX idx_json_relationships_firstPropertyName ON openidm.relationships
    ( json_extract_path_text(fullobject, 'firstPropertyName') );

CREATE INDEX idx_json_relationships_secondId ON openidm.relationships
    ( json_extract_path_text(fullobject, 'secondId') );
CREATE INDEX idx_json_relationships_secondPropertyName ON openidm.relationships
    ( json_extract_path_text(fullobject, 'secondPropertyName') );

-- -----------------------------------------------------
-- Table openidm.relationshipproperties (not used in postgres)
-- -----------------------------------------------------

CREATE TABLE openidm.relationshipproperties (
  relationships_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_relationshipproperties_relationships FOREIGN KEY (relationships_id) REFERENCES openidm.relationships (id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE INDEX fk_relationshipproperties_relationships ON openidm.relationshipproperties (relationships_id);
CREATE INDEX idx_relationshipproperties_prop ON openidm.relationshipproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.links
-- -----------------------------------------------------

CREATE TABLE openidm.links (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  linktype VARCHAR(510) NOT NULL,
  linkqualifier VARCHAR(255) NOT NULL,
  firstid VARCHAR(255) NOT NULL,
  secondid VARCHAR(255) NOT NULL,
  PRIMARY KEY (objectid)
);

CREATE UNIQUE INDEX idx_links_first ON openidm.links (linktype, linkqualifier, firstid);
CREATE UNIQUE INDEX idx_links_second ON openidm.links (linktype, linkqualifier, secondid);


-- -----------------------------------------------------
-- Table openidm.security
-- -----------------------------------------------------

CREATE TABLE openidm.security (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  storestring TEXT,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.securitykeys
-- -----------------------------------------------------

CREATE TABLE openidm.securitykeys (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  keypair TEXT,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditauthentication
-- -----------------------------------------------------
CREATE TABLE openidm.auditauthentication (
  objectid VARCHAR(56) NOT NULL,
  transactionid VARCHAR(255) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  eventname VARCHAR(50) DEFAULT NULL,
  result VARCHAR(255) DEFAULT NULL,
  principals TEXT,
  context TEXT,
  entries TEXT,
  trackingids TEXT,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditaccess
-- -----------------------------------------------------

CREATE TABLE openidm.auditaccess (
  objectid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(255),
  transactionid VARCHAR(255) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  server_ip VARCHAR(40),
  server_port VARCHAR(5),
  client_ip VARCHAR(40),
  client_port VARCHAR(5),
  request_protocol VARCHAR(255) NULL ,
  request_operation VARCHAR(255) NULL ,
  request_detail TEXT NULL ,
  http_request_secure VARCHAR(255) NULL ,
  http_request_method VARCHAR(255) NULL ,
  http_request_path VARCHAR(255) NULL ,
  http_request_queryparameters TEXT NULL ,
  http_request_headers TEXT NULL ,
  http_request_cookies TEXT NULL ,
  http_response_headers TEXT NULL ,
  response_status VARCHAR(255) NULL ,
  response_statuscode VARCHAR(255) NULL ,
  response_elapsedtime VARCHAR(255) NULL ,
  response_elapsedtimeunits VARCHAR(255) NULL ,
  roles TEXT NULL ,
  PRIMARY KEY (objectid)
);

-- -----------------------------------------------------
-- Table openidm.auditconfig
-- -----------------------------------------------------

CREATE TABLE openidm.auditconfig (
  objectid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(255) DEFAULT NULL,
  transactionid VARCHAR(255) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  runas VARCHAR(255) DEFAULT NULL,
  configobjectid VARCHAR(255) NULL ,
  operation VARCHAR(255) NULL ,
  beforeObject TEXT,
  afterObject TEXT,
  changedfields VARCHAR(255) DEFAULT NULL,
  rev VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (objectid)
);

CREATE INDEX idx_auditconfig_transactionid ON openidm.auditconfig (transactionid);

-- -----------------------------------------------------
-- Table openidm.auditactivity
-- -----------------------------------------------------

CREATE TABLE openidm.auditactivity (
  objectid VARCHAR(56) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(255) DEFAULT NULL,
  transactionid VARCHAR(255) NOT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  runas VARCHAR(255) DEFAULT NULL,
  activityobjectid VARCHAR(255) NULL ,
  operation VARCHAR(255) NULL ,
  subjectbefore TEXT,
  subjectafter TEXT,
  changedfields VARCHAR(255) DEFAULT NULL,
  subjectrev VARCHAR(255) DEFAULT NULL,
  passwordchanged VARCHAR(5) DEFAULT NULL,
  message TEXT,
  status VARCHAR(20),
  PRIMARY KEY (objectid)
);

CREATE INDEX idx_auditactivity_transactionid ON openidm.auditactivity (transactionid);


-- -----------------------------------------------------
-- Table openidm.auditrecon
-- -----------------------------------------------------

CREATE TABLE openidm.auditrecon (
  objectid VARCHAR(56) NOT NULL,
  transactionid VARCHAR(255) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(50) DEFAULT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  activity VARCHAR(24) DEFAULT NULL,
  exceptiondetail TEXT,
  linkqualifier VARCHAR(255) DEFAULT NULL,
  mapping VARCHAR(511) DEFAULT NULL,
  message TEXT,
  messagedetail TEXT,
  situation VARCHAR(24) DEFAULT NULL,
  sourceobjectid VARCHAR(511) DEFAULT NULL,
  status VARCHAR(20) DEFAULT NULL,
  targetobjectid VARCHAR(511) DEFAULT NULL,
  reconciling VARCHAR(12) DEFAULT NULL,
  ambiguoustargetobjectids TEXT,
  reconaction VARCHAR(36) DEFAULT NULL,
  entrytype VARCHAR(7) DEFAULT NULL,
  reconid VARCHAR(56) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.auditsync
-- -----------------------------------------------------

CREATE TABLE openidm.auditsync (
  objectid VARCHAR(56) NOT NULL,
  transactionid VARCHAR(255) NOT NULL,
  activitydate VARCHAR(29) NOT NULL,
  eventname VARCHAR(50) DEFAULT NULL,
  userid VARCHAR(255) DEFAULT NULL,
  trackingids TEXT,
  activity VARCHAR(24) DEFAULT NULL,
  exceptiondetail TEXT,
  linkqualifier VARCHAR(255) DEFAULT NULL,
  mapping VARCHAR(511) DEFAULT NULL,
  message TEXT,
  messagedetail TEXT,
  situation VARCHAR(24) DEFAULT NULL,
  sourceobjectid VARCHAR(511) DEFAULT NULL,
  status VARCHAR(20) DEFAULT NULL,
  targetobjectid VARCHAR(511) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.internaluser
-- -----------------------------------------------------

CREATE TABLE openidm.internaluser (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  pwd VARCHAR(510) DEFAULT NULL,
  roles VARCHAR(1024) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.internalrole
-- -----------------------------------------------------

CREATE TABLE openidm.internalrole (
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  description VARCHAR(510) DEFAULT NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.schedulerobjects
-- -----------------------------------------------------
CREATE TABLE openidm.schedulerobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_schedulerobjects_objectypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_schedulerobjects_object ON openidm.schedulerobjects (objecttypes_id,objectid);
CREATE INDEX fk_schedulerobjects_objectypes ON openidm.schedulerobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.schedulerobjectproperties
-- -----------------------------------------------------
CREATE TABLE openidm.schedulerobjectproperties (
  schedulerobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_schedulerobjectproperties_schedulerobjects FOREIGN KEY (schedulerobjects_id) REFERENCES openidm.schedulerobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_schedulerobjectproperties_schedulerobjects ON openidm.schedulerobjectproperties (schedulerobjects_id);
CREATE INDEX idx_schedulerobjectproperties_prop ON openidm.schedulerobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.uinotification
-- -----------------------------------------------------
CREATE TABLE openidm.uinotification (
  objectid VARCHAR(38) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  notificationType VARCHAR(255) NOT NULL,
  createDate VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  requester VARCHAR(255) NULL,
  receiverId VARCHAR(38) NOT NULL,
  requesterId VARCHAR(38) NULL,
  notificationSubtype VARCHAR(255) NULL,
  PRIMARY KEY (objectid)
);


-- -----------------------------------------------------
-- Table openidm.clusterobjects
-- -----------------------------------------------------
CREATE TABLE openidm.clusterobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_clusterobjects_objectypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE UNIQUE INDEX idx_clusterobjects_object ON openidm.clusterobjects (objecttypes_id,objectid);
CREATE INDEX fk_clusterobjects_objectypes ON openidm.clusterobjects (objecttypes_id);


-- -----------------------------------------------------
-- Table openidm.clusterobjectproperties
-- -----------------------------------------------------
CREATE TABLE openidm.clusterobjectproperties (
  clusterobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_clusterobjectproperties_clusterobjects FOREIGN KEY (clusterobjects_id) REFERENCES openidm.clusterobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);

CREATE INDEX fk_clusterobjectproperties_clusterobjects ON openidm.clusterobjectproperties (clusterobjects_id);
CREATE INDEX idx_clusterobjectproperties_prop ON openidm.clusterobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Table openidm.updateobjects
-- -----------------------------------------------------

CREATE TABLE openidm.updateobjects (
  id BIGSERIAL NOT NULL,
  objecttypes_id BIGINT NOT NULL,
  objectid VARCHAR(255) NOT NULL,
  rev VARCHAR(38) NOT NULL,
  fullobject JSON,
  PRIMARY KEY (id),
  CONSTRAINT fk_updateobjects_objecttypes FOREIGN KEY (objecttypes_id) REFERENCES openidm.objecttypes (id) ON DELETE CASCADE ON UPDATE NO ACTION,
  CONSTRAINT idx_updateobjects_object UNIQUE (objecttypes_id, objectid)
);



-- -----------------------------------------------------
-- Table openidm.updateobjectproperties
-- -----------------------------------------------------

CREATE TABLE openidm.updateobjectproperties (
  updateobjects_id BIGINT NOT NULL,
  propkey VARCHAR(255) NOT NULL,
  proptype VARCHAR(32) DEFAULT NULL,
  propvalue TEXT,
  CONSTRAINT fk_updateobjectproperties_updateobjects FOREIGN KEY (updateobjects_id) REFERENCES openidm.updateobjects (id) ON DELETE CASCADE ON UPDATE NO ACTION
);
CREATE INDEX fk_updateobjectproperties_updateobjects ON openidm.updateobjectproperties (updateobjects_id);
CREATE INDEX idx_updateobjectproperties_prop ON openidm.updateobjectproperties (propkey,propvalue);


-- -----------------------------------------------------
-- Data for table openidm.internaluser
-- -----------------------------------------------------
START TRANSACTION;
INSERT INTO openidm.internaluser (objectid, rev, pwd, roles) VALUES ('openidm-admin', '0', 'openidm-admin', '[ { "_ref" : "repo/internal/role/openidm-admin" }, { "_ref" : "repo/internal/role/openidm-authorized" } ]');
INSERT INTO openidm.internaluser (objectid, rev, pwd, roles) VALUES ('anonymous', '0', 'anonymous', '[ { "_ref" : "repo/internal/role/openidm-reg" } ]');

INSERT INTO openidm.internalrole (objectid, rev, description)
VALUES
('openidm-authorized', '0', 'Basic minimum user'),
('openidm-admin', '0', 'Administrative access'),
('openidm-cert', '0', 'Authenticated via certificate'),
('openidm-tasks-manager', '0', 'Allowed to reassign workflow tasks'),
('openidm-reg', '0', 'Anonymous access');

COMMIT;

CREATE INDEX idx_json_clusterobjects_timestamp ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'timestamp') );
CREATE INDEX idx_json_clusterobjects_state ON openidm.clusterobjects ( json_extract_path_text(fullobject, 'state') );

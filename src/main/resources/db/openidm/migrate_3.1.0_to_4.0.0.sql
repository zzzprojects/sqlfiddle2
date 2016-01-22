
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

ALTER TABLE openidm.links ADD linkqualifier VARCHAR(255) NOT NULL default 'default';

DROP INDEX idx_links_first;
DROP INDEX idx_links_second;

CREATE UNIQUE INDEX idx_links_first ON openidm.links (linktype, linkqualifier, firstid);
CREATE UNIQUE INDEX idx_links_second ON openidm.links (linktype, linkqualifier, secondid);


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
ALTER TABLE openidm.auditaccess RENAME TO auditaccess_31;

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
DROP INDEX idx_auditactivity_rootactionid;
ALTER TABLE openidm.auditactivity RENAME TO auditactivity_31;

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
ALTER TABLE openidm.auditrecon RENAME TO auditrecon_31;

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
ALTER TABLE openidm.auditsync RENAME TO auditsync_31;

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

--ALTER TABLE openidm.internaluser ALTER COLUMN objectid VARCHAR(255) NOT NULL;

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


INSERT INTO openidm.internalrole (objectid, rev, description)
VALUES
('openidm-authorized', '0', 'Basic minimum user'),
('openidm-admin', '0', 'Administrative access'),
('openidm-cert', '0', 'Authenticated via certificate'),
('openidm-tasks-manager', '0', 'Allowed to reassign workflow tasks'),
('openidm-reg', '0', 'Anonymous access');

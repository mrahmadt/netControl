BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "bandwidths" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL,
	"tcrate"	TEXT NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "config" (
	"name"	TEXT NOT NULL,
	"value"	TEXT DEFAULT NULL,
	PRIMARY KEY("name")
);
CREATE TABLE IF NOT EXISTS "temporaryMode" (
	"device_id"	INTEGER NOT NULL,
	"minutes"	INTEGER NOT NULL DEFAULT 15,
	FOREIGN KEY("device_id") REFERENCES "devices"("id") ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY("device_id")
);
CREATE TABLE IF NOT EXISTS "deviceTypes" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "devices" (
	"id"	INTEGER,
	"macaddr"	TEXT NOT NULL UNIQUE,
	"ipaddr"	TEXT DEFAULT NULL,
	"manufacturer"	TEXT DEFAULT NULL,
	"hostname"	TEXT DEFAULT NULL,
	"created_at"	INTEGER NOT NULL,
	"updated_at"	INTEGER NOT NULL,
	"mode"	INTEGER NOT NULL DEFAULT 1,
	"name"	TEXT DEFAULT NULL,
	"icon"	TEXT DEFAULT NULL,
	"bandwidth"	INTEGER DEFAULT NULL,
	"Is_loggedIn"	INTEGER NOT NULL DEFAULT 0,
	"requireLogin"	INTEGER NOT NULL DEFAULT 0,
	"user_id"	INTEGER DEFAULT NULL,
	"stage"	INTEGER NOT NULL DEFAULT 0,
	"availableCredit"	INTEGER NOT NULL DEFAULT 0,
	"modeWhenCreditconsumed"	INTEGER NOT NULL DEFAULT 2,
	"deviceType_id"	INTEGER,
	"MonCredit"	INTEGER NOT NULL DEFAULT 0,
	"TueCredit"	INTEGER NOT NULL DEFAULT 0,
	"WedCredit"	INTEGER NOT NULL DEFAULT 0,
	"ThuCredit"	INTEGER NOT NULL DEFAULT 0,
	"FriCredit"	INTEGER NOT NULL DEFAULT 0,
	"SatCredit"	INTEGER NOT NULL DEFAULT 0,
	"SunCredit"	INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY("user_id") REFERENCES "users"("id") ON UPDATE CASCADE ON DELETE SET NULL,
	FOREIGN KEY("deviceType_id") REFERENCES "deviceTypes"("id") ON UPDATE CASCADE ON DELETE SET NULL,
	FOREIGN KEY("bandwidth") REFERENCES "bandwidths"("id") ON UPDATE CASCADE ON DELETE SET NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "users" (
	"id"	INTEGER,
	"name"	TEXT DEFAULT NULL,
	"password"	TEXT DEFAULT NULL,
	"icon"	TEXT DEFAULT NULL,
	"age"	INTEGER DEFAULT NULL,
	"is_locked"	INTEGER NOT NULL DEFAULT 0,
	"is_admin"	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY("id" AUTOINCREMENT)
);
CREATE TABLE IF NOT EXISTS "schedule" (
	"weekday"	INTEGER NOT NULL DEFAULT NULL,
	"hour"	INTEGER NOT NULL,
	"mode"	INTEGER NOT NULL,
	"device_id"	INTEGER NOT NULL,
	FOREIGN KEY("device_id") REFERENCES "devices"("id") ON UPDATE CASCADE ON DELETE CASCADE,
	UNIQUE("weekday","hour","device_id")
);
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (1,'56kbit','56kbit');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (2,'128kbit','128kbit');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (3,'256kbit','256kbit');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (4,'512kbit','512kbit');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (5,'1mbit','1mbit');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (6,'56kbps','56kbps');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (7,'128kbps','128kbps');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (8,'256kbps','256kbps');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (9,'512kbps','512kbps');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (10,'1mbps','1mbps');
INSERT INTO "bandwidths" ("id","name","tcrate") VALUES (11,'2mbps','2mbps');
INSERT INTO "config" ("name","value") VALUES ('device.new.bandwidth','11');
INSERT INTO "config" ("name","value") VALUES ('wan.interface','enp0s3');
INSERT INTO "config" ("name","value") VALUES ('wan.ipaddr','10.0.2.15');
INSERT INTO "config" ("name","value") VALUES ('lan.interface','enp0s8');
INSERT INTO "config" ("name","value") VALUES ('lan.ipaddr','10.2.2.1');
INSERT INTO "config" ("name","value") VALUES ('device.new.mode','3');
INSERT INTO "config" ("name","value") VALUES ('system.status','0');
INSERT INTO "config" ("name","value") VALUES ('system.portal.ip','10.2.2.1:80');
INSERT INTO "config" ("name","value") VALUES ('lan.dnsserver1','192.168.1.44');
INSERT INTO "deviceTypes" ("id","name") VALUES (1,'PC');
INSERT INTO "deviceTypes" ("id","name") VALUES (2,'Router');
INSERT INTO "deviceTypes" ("id","name") VALUES (3,'Switch');
INSERT INTO "deviceTypes" ("id","name") VALUES (4,'Access Point');
INSERT INTO "deviceTypes" ("id","name") VALUES (5,'Tablet');
INSERT INTO "deviceTypes" ("id","name") VALUES (6,'Phone');
INSERT INTO "deviceTypes" ("id","name") VALUES (7,'Watch');
INSERT INTO "deviceTypes" ("id","name") VALUES (8,'Smart TV');
INSERT INTO "deviceTypes" ("id","name") VALUES (9,'Storage');
INSERT INTO "deviceTypes" ("id","name") VALUES (10,'Speaker');
INSERT INTO "deviceTypes" ("id","name") VALUES (11,'IoT');
INSERT INTO "deviceTypes" ("id","name") VALUES (12,'Server');
INSERT INTO "deviceTypes" ("id","name") VALUES (13,'Other');
INSERT INTO "users" ("id","name","password","icon","age","is_locked","is_admin") VALUES (1,'admin',NULL,NULL,NULL,0,1);
COMMIT;

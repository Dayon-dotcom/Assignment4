DROP DATABASE IF EXISTS space_operations;
CREATE DATABASE space_operations;
USE space_operations;


-- countries 
CREATE TABLE countries (
    countrycode VARCHAR(3),
    countryname VARCHAR(100),
    continent VARCHAR(50),
    PRIMARY KEY (countrycode)
);

-- organizations 
CREATE TABLE organizations (
    orgid INT ,
    orgname VARCHAR(150),
    headquarterscountry VARCHAR(3),
    orgtype VARCHAR(50),
    PRIMARY KEY (orgid),
    CONSTRAINT fk_organizations_countries
        FOREIGN KEY (headquarterscountry) REFERENCES countries (countrycode)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

--  launch_sites 
CREATE TABLE launch_sites (
    siteid INT NOT NULL,
    sitename VARCHAR(150),
    countrycode VARCHAR(3),
    status VARCHAR(50),
    PRIMARY KEY (siteid),
    CONSTRAINT fk_launch_sites_countries
        FOREIGN KEY (countrycode) REFERENCES countries (countrycode)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

--  rockets 
CREATE TABLE rockets (
    rocketid INT ,
    rocketname VARCHAR(100) ,
    orgid INT ,
    payloadcapacitykg INT ,
    operationalstatus VARCHAR(50) ,
    PRIMARY KEY (rocketid),
    CONSTRAINT fk_rockets_organizations
        FOREIGN KEY (orgid) REFERENCES organizations (orgid)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

--  missions 
CREATE TABLE missions (
    missionid INT ,
    missionname VARCHAR(150) ,
    rocketid INT ,
    siteid INT ,
    destination VARCHAR(50) ,
    launchyear INT ,
    outcome VARCHAR(50) ,
    PRIMARY KEY (missionid),
    CONSTRAINT fk_missions_rockets
        FOREIGN KEY (rocketid) REFERENCES rockets (rocketid)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_missions_launch_sites
        FOREIGN KEY (siteid) REFERENCES launch_sites (siteid)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- payloads 
CREATE TABLE payloads (
    payloadid INT ,
    missionid INT ,
    payloadname VARCHAR(150) ,
    payloadtype VARCHAR(50) ,
    masskg DECIMAL(10, 2) ,
    PRIMARY KEY (payloadid),
    CONSTRAINT fk_payloads_missions
        FOREIGN KEY (missionid) REFERENCES missions (missionid)
        ON UPDATE CASCADE ON DELETE CASCADE
);
USE space_operations;

-- Problem 1
SELECT 
    missions.missionname,
    rockets.rocketname,
    organizations.orgname,
    launch_sites.sitename,
    missions.destination,
    missions.launchyear,
    missions.outcome
FROM missions
JOIN rockets 
    ON missions.rocketid = rockets.rocketid
JOIN organizations 
    ON rockets.orgid = organizations.orgid
JOIN launch_sites 
    ON missions.siteid = launch_sites.siteid
ORDER BY 
    missions.launchyear DESC,
    missions.missionname ASC;


-- Problem 2
SELECT 
    missions.missionname,
    rockets.rocketname,
    payloads.payloadname,
    payloads.payloadtype,
    payloads.masskg
FROM payloads
JOIN missions 
    ON payloads.missionid = missions.missionid
JOIN rockets 
    ON missions.rocketid = rockets.rocketid
WHERE missions.launchyear = 2024
ORDER BY payloads.masskg DESC;


-- Problem 3
SELECT 
    launch_sites.sitename,
    missions.missionname,
    rockets.rocketname,
    missions.launchyear
FROM launch_sites
LEFT JOIN missions 
    ON launch_sites.siteid = missions.siteid 
    AND missions.launchyear = 2024
LEFT JOIN rockets 
    ON missions.rocketid = rockets.rocketid
ORDER BY launch_sites.sitename ASC;


-- Problem 4
WITH organization_payload_totals AS (
    SELECT 
        rockets.orgid,
        SUM(payloads.masskg) AS total_payload_mass_kg
    FROM payloads
    JOIN missions 
        ON payloads.missionid = missions.missionid
    JOIN rockets 
        ON missions.rocketid = rockets.rocketid
    GROUP BY rockets.orgid
)
SELECT 
    organizations.orgname,
    organizations.headquarterscountry,
    organizations.orgtype,
    organization_payload_totals.total_payload_mass_kg
FROM organizations
JOIN organization_payload_totals 
    ON organizations.orgid = organization_payload_totals.orgid
ORDER BY organization_payload_totals.total_payload_mass_kg DESC;


-- Problem 5
WITH country_missions AS (
    SELECT 
        launch_sites.countrycode,
        COUNT(missions.missionid) AS total_missions
    FROM launch_sites
    JOIN missions 
        ON launch_sites.siteid = missions.siteid
    GROUP BY launch_sites.countrycode
),
country_payloads AS (
    SELECT 
        launch_sites.countrycode,
        SUM(payloads.masskg) AS total_payload_mass_kg
    FROM launch_sites
    JOIN missions 
        ON launch_sites.siteid = missions.siteid
    JOIN payloads 
        ON missions.missionid = payloads.missionid
    GROUP BY launch_sites.countrycode
)
SELECT 
    countries.countryname,
    COALESCE(country_missions.total_missions, 0) AS total_missions,
    COALESCE(country_payloads.total_payload_mass_kg, 0.00) AS total_payload_mass_kg
FROM countries
LEFT JOIN country_missions 
    ON countries.countrycode = country_missions.countrycode
LEFT JOIN country_payloads 
    ON countries.countrycode = country_payloads.countrycode
ORDER BY total_payload_mass_kg DESC;
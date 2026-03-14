-- Initialise one database per Whispr microservice.
-- Runs automatically when the postgres container is first created.

SELECT 'CREATE DATABASE whispr_auth'         WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'whispr_auth')\gexec
SELECT 'CREATE DATABASE whispr_user'         WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'whispr_user')\gexec
SELECT 'CREATE DATABASE whispr_media'        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'whispr_media')\gexec
SELECT 'CREATE DATABASE whispr_messaging'    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'whispr_messaging')\gexec
SELECT 'CREATE DATABASE whispr_notification' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'whispr_notification')\gexec
SELECT 'CREATE DATABASE whispr_scheduling'   WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'whispr_scheduling')\gexec

-- Create schemas required by each service.
\c whispr_auth
CREATE SCHEMA IF NOT EXISTS auth;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

\c whispr_user
CREATE SCHEMA IF NOT EXISTS users;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

\c whispr_media
CREATE SCHEMA IF NOT EXISTS media;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

\c whispr_messaging
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c whispr_notification
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c whispr_scheduling
CREATE SCHEMA IF NOT EXISTS scheduling;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

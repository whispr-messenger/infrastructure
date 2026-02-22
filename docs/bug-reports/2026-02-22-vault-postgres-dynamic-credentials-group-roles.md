# Bug Report: Vault Postgres Dynamic Credentials Ownership

**Date:** 2026-02-22
**Severity:** High
**Status:** Resolved
**Component:** Vault Config / PostgreSQL / messaging-service
**Cluster:** whispr-messenger

## Summary

Microservices leveraging an ORM (e.g. Ecto for `messaging-service`) were crashing during their database migration phase with a `permission denied for table schema_migrations` error. This happened because Vault generates dynamic credentials that do not inherit the ownership or permissions of tables created by previously generated dynamic users.

## Symptoms

- **Pod Status:** CrashLoopBackOff (1/2 Ready)
- **Application Logs:** 
  ```elixir
  ** (MatchError) no match of right hand side value:
    {:error,
     %Postgrex.Error{
       message: nil,
       postgres: %{
         code: :insufficient_privilege,
         message: "permission denied for table schema_migrations",
         pg_code: "42501"
       }
     }}
    (ecto_sql 3.13.3) lib/ecto/adapters/postgres.ex:326: anonymous fn/3 in Ecto.Adapters.Postgres.do_lock_for_migrations/5
  ```

## Root Cause

Vault uses the `postgresql-database-plugin` to generate dynamic credentials. Every time the lease expires or the pod restarts, Vault creates a new PostgreSQL role with a random name (e.g., `v-root-role-mes-XXXX`).

1. **Initial Migration:** The very first dynamic user successfully connects, creates the `schema_migrations` table, and creates other application tables. Since this user created the tables, PostgreSQL sets this dynamic user as the `OWNER`.
2. **Subsequent Migrations/Restarts:** A new dynamic user is generated. However, it has no inheritance or rights over the tables created by the previous user. When the ORM attempts to read or lock `schema_migrations`, it receives a `permission denied` error.
3. Vault's `creationStatements` only ran `GRANT ALL PRIVILEGES ON DATABASE` which merely grants the ability to connect to the database or create schemas. It does not grant ownership of existing tables inside the `public` schema.

## Debugging Steps

1. **Check the ownership of tables:**
   ```bash
   # Connect to postgres
   psql -h postgresql.postgresql.svc.cluster.local -U postgres -d messaging_service_db -c "\dt"
   ```
   The owner of the tables turned out to be an old `v-root-role-mes-XXXX` user, which was no longer used by the active application pod.
2. **Attempt to manually lock table as the new Vault user:**
   Manually logging in with the pod's currently mounted dynamic credentials and attempting to run `LOCK TABLE schema_migrations IN SHARE UPDATE EXCLUSIVE MODE;` resulted in `permission denied`.

## Resolution

### Fix Applied

Implemented PostgreSQL **Group Roles** to ensure consistent and permanent table ownership across all ephemeral credentials.

1. **`k8s/vault/vault-bootstrap-job.yaml`:**
   Modified the PostgreSQL bootstrap script to create a permanent group role (`role_messaging_service_group` with `NOLOGIN`) for each database. Set this group as the `OWNER` of the database and the `public` schema, and added a retroactive step to alter the owner of all existing tables and sequences to this group.

   ```sql
   DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'role_messaging_service_group') THEN CREATE ROLE role_messaging_service_group NOLOGIN; END IF; END $$;
   ALTER DATABASE "messaging_service_db" OWNER TO role_messaging_service_group;
   ALTER SCHEMA public OWNER TO role_messaging_service_group;
   -- Then ALTER TABLE public.xxx OWNER TO role_messaging_service_group;
   ```

2. **`k8s/vault-config-operator/custom-resources/database-roles.yaml`:**
   Modified the `creationStatements` used by Vault to grant the new permanent group role to the generated dynamic user. We then immediately `ALTER ROLE` so the dynamic user acts as the group role by default.

   ```sql
   CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';
   GRANT role_messaging_service_group TO "{{name}}";
   ALTER ROLE "{{name}}" SET ROLE role_messaging_service_group;
   ```

With this strategy, any table created by *any* dynamic user is inherently owned by the permanent group role. Consequently, the next dynamic user, who is also a member of the group, automatically has full privileges on those tables.

## Affected Files

- `k8s/vault/vault-bootstrap-job.yaml`
- `k8s/vault-config-operator/custom-resources/database-roles.yaml`

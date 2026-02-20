# Database Management Guide

Tools and workflows for DBA work with Oracle, PostgreSQL, and cloud databases.

## Tool Installation

All database-related tools are managed via [mise](https://mise.jdx.dev/). Add to `~/.config/mise/config.toml`:

```toml
[tools]
# PostgreSQL client
postgres = "16"

# MySQL client (uncomment if needed)
# mysql = "latest"

# Cloud CLIs
# oci = "latest"       # Oracle Cloud
# awscli = "latest"    # AWS
# "azure-cli" = "latest"  # Azure
```

```bash
mise install    # Install all defined tools
```

## Credential Management

All database credentials are stored encrypted with fnox. **Never store passwords in plain text.**

### PostgreSQL

```bash
# Store credentials
fnox set PGHOST "db.example.com"
fnox set PGUSER "dba"
fnox set PGPASSWORD "secure-password"
fnox set PGDATABASE "production"

# Connect (PG* env vars are auto-recognized by psql)
fnox exec -- psql

# Or use a connection string
fnox set DATABASE_URL "postgresql://user:pass@host:5432/dbname"
fnox exec -- psql $DATABASE_URL
```

### Oracle Database

Oracle requires the Instant Client, which is not available via mise:

```bash
# 1. Download Oracle Instant Client from oracle.com
# 2. Install and set environment variables

# Add to your local bashrc overrides (~/.bashrc.local):
export ORACLE_HOME=/opt/oracle/instantclient_21_12
export LD_LIBRARY_PATH=$ORACLE_HOME:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME:$PATH

# Store credentials in fnox
fnox set ORACLE_HOST "oracle.example.com"
fnox set ORACLE_PORT "1521"
fnox set ORACLE_SERVICE "ORCL"
fnox set ORACLE_USER "admin"
fnox set ORACLE_PASSWORD "secure-password"

# Connect
fnox exec -- sqlplus $ORACLE_USER/$ORACLE_PASSWORD@$ORACLE_HOST:$ORACLE_PORT/$ORACLE_SERVICE
```

### Oracle Cloud Infrastructure (OCI)

OCI credentials are already stored in the `oci_aysesmenn` fnox profile:

```bash
# OCI credentials stored:
# - OCI_TENANCY_OCID
# - OCI_USER_OCID
# - OCI_REGION
# - OCI_FINGERPRINT
# - OCI_PRIVATE_KEY

# Use OCI CLI with fnox
fnox --profile oci_aysesmenn exec -- oci db system list --compartment-id <ocid>

# List Autonomous Databases
fnox --profile oci_aysesmenn exec -- oci db autonomous-database list \
    --compartment-id <ocid> --display-name "mydb"
```

## Environment Separation

Use fnox profiles for different environments:

```toml
# In fnox.toml
[profiles.dev.secrets]
PGHOST = { provider = "age", value = "..." }
PGDATABASE = { provider = "age", value = "..." }

[profiles.staging.secrets]
PGHOST = { provider = "age", value = "..." }
PGDATABASE = { provider = "age", value = "..." }

[profiles.production.secrets]
PGHOST = { provider = "age", value = "..." }
PGDATABASE = { provider = "age", value = "..." }
```

```bash
# Connect to different environments
fnox --profile dev exec -- psql
fnox --profile staging exec -- psql
fnox --profile production exec -- psql
```

## Shell Aliases for Database Work

Add these to `~/.bashrc.local` for project-specific database shortcuts:

```bash
# Quick connect aliases
alias psql-dev='fnox --profile dev exec -- psql'
alias psql-prod='fnox --profile production exec -- psql'

# Database shell function
dbshell() {
    local profile="${1:-dev}"
    fnox --profile "$profile" exec -- psql
}
# Usage: dbshell prod

# Quick backup
pgdump() {
    local profile="${1:-dev}"
    local output="backup_$(date +%Y%m%d_%H%M%S).sql"
    fnox --profile "$profile" exec -- pg_dump > "$output"
    echo "Backup: $output"
}
```

## Common DBA Tasks

### PostgreSQL Backup & Restore

```bash
# Backup
fnox exec -- pg_dump -Fc $DATABASE_URL > backup.dump

# Restore
fnox exec -- pg_restore -d $DATABASE_URL backup.dump

# Logical backup (SQL)
fnox exec -- pg_dumpall > full_backup.sql
```

### Oracle RMAN (via SSH)

```bash
# Connect to Oracle server and run RMAN
ssh c "rman target /"

# Or use the SSH alias from your config
ssh c "sqlplus / as sysdba"
```

### Database Health Check Script

Create `~/.local/bin/db-health`:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Database Health Check ==="
echo "Date: $(date)"
echo ""

# PostgreSQL
if command -v psql &>/dev/null; then
    echo "--- PostgreSQL ---"
    fnox exec -- psql -c "SELECT version();" 2>/dev/null && \
        echo "✓ PostgreSQL connected" || echo "✗ PostgreSQL failed"
fi

# Oracle (if available)
if command -v sqlplus &>/dev/null; then
    echo "--- Oracle ---"
    echo "SELECT * FROM v\$version WHERE ROWNUM=1;" | \
        fnox exec -- sqlplus -s $ORACLE_USER/$ORACLE_PASSWORD@$ORACLE_HOST:$ORACLE_PORT/$ORACLE_SERVICE 2>/dev/null && \
        echo "✓ Oracle connected" || echo "✗ Oracle failed"
fi
```

## Kubernetes Database Access

For databases running in Kubernetes:

```bash
# Port-forward PostgreSQL
kubectl port-forward svc/postgresql 5432:5432 -n database &

# Connect locally
psql -h localhost -U postgres

# Using k9s for database pod management
k9s -n database
```

## Security Checklist

- [x] All credentials stored in fnox with age encryption
- [x] Age key backed up securely (see [FNOX guide](FNOX.md))
- [ ] Separate credentials per environment (dev/staging/prod)
- [ ] Regular credential rotation (quarterly minimum)
- [ ] SSH tunnels for remote database access
- [ ] Audit logging enabled for production access
- [ ] MFA enabled for cloud console access

## Tool Versions

Check installed database tools:

```bash
command -v psql    && psql --version
command -v mysql   && mysql --version
command -v sqlplus && sqlplus -version
command -v mongosh && mongosh --version
mise list          # All mise-managed tools
```

## Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Oracle Documentation](https://docs.oracle.com/en/database/)
- [OCI CLI Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/)
- [fnox Guide](FNOX.md) — Secret management details

---

**Last Updated:** 2026-02-18

# Database Management Tools

This guide explains how to add database-specific CLI tools to your dotfiles setup.

## Overview

As a DBA managing multiple databases across different cloud providers, you may need to install various database client tools. This document provides guidance on:

1. How to add database tools to mise
2. Best practices for managing database credentials
3. Common database tools and their integration
4. Real-world scenarios and recommendations

## Supported Database Tools

### PostgreSQL

**Installation:**
```bash
# Add to mise.toml
[tools]
postgres = "latest"  # Includes psql client

# Or install globally
mise use -g postgres@latest
```

**Usage:**
```bash
# Connect using fnox-managed secrets
fnox exec -- psql -h $DB_HOST -U $DB_USER -d $DB_NAME

# Or export secrets first
eval "$(fnox export)"
psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

**Connection String with fnox:**
```bash
# Store connection string
fnox set POSTGRES_URL "postgresql://user:password@host:5432/database"

# Use it
fnox exec -- psql $POSTGRES_URL
```

### MySQL/MariaDB

**Installation:**
```bash
# Add to mise.toml
[tools]
mysql = "latest"  # Includes mysql client

# Or install globally
mise use -g mysql@latest
```

**Usage:**
```bash
# Store credentials
fnox set MYSQL_HOST "db.example.com"
fnox set MYSQL_USER "admin"
fnox set MYSQL_PASSWORD "secure-password"
fnox set MYSQL_DATABASE "mydb"

# Connect
fnox exec -- mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE
```

**Create MySQL config template (optional):**
```bash
# Create ~/.my.cnf.tmpl in chezmoi
chezmoi add --template ~/.my.cnf

# Edit template to use fnox variables
chezmoi edit ~/.my.cnf
```

Example `~/.my.cnf.tmpl`:
```ini
[client]
host={{ env "MYSQL_HOST" }}
user={{ env "MYSQL_USER" }}
password={{ env "MYSQL_PASSWORD" }}
```

### Oracle Database

**Installation:**

Oracle SQL*Plus requires manual installation:

1. Download Oracle Instant Client from Oracle website
2. Install according to platform instructions
3. Set environment variables

**Add to your dotfiles:**

Create `dot_bash_oracle` file:
```bash
# Oracle Instant Client configuration
export ORACLE_HOME=/path/to/instantclient
export LD_LIBRARY_PATH=$ORACLE_HOME:$LD_LIBRARY_PATH
export PATH=$ORACLE_HOME:$PATH
```

Source in `.bashrc`:
```bash
# In dot_bashrc
if [ -f "$HOME/.bash_oracle" ]; then
    source "$HOME/.bash_oracle"
fi
```

**Usage with fnox:**
```bash
# Store Oracle connection details
fnox set ORACLE_HOST "oracle.example.com"
fnox set ORACLE_PORT "1521"
fnox set ORACLE_SERVICE "ORCL"
fnox set ORACLE_USER "admin"
fnox set ORACLE_PASSWORD "secure-password"

# Connect
fnox exec -- sqlplus $ORACLE_USER/$ORACLE_PASSWORD@$ORACLE_HOST:$ORACLE_PORT/$ORACLE_SERVICE
```

### MongoDB

**Installation:**
```bash
# Add to mise.toml
[tools]
mongodb = "latest"  # Includes mongosh

# Or install globally
mise use -g mongodb@latest
```

**Usage:**
```bash
# Store MongoDB URI
fnox set MONGODB_URI "mongodb://user:password@host:27017/database"

# Connect
fnox exec -- mongosh $MONGODB_URI
```

### Redis

**Installation:**
```bash
# Add to mise.toml
[tools]
redis = "latest"  # Includes redis-cli

# Or install globally
mise use -g redis@latest
```

**Usage:**
```bash
# Store Redis connection details
fnox set REDIS_HOST "redis.example.com"
fnox set REDIS_PORT "6379"
fnox set REDIS_PASSWORD "secure-password"

# Connect
fnox exec -- redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD
```

## Best Practices

### 1. Secret Management

**DO:**
- Store all database credentials in fnox with encryption
- Use different profiles for dev/staging/prod environments
- Use descriptive secret names (e.g., `PROD_DB_PASSWORD`, not just `PASSWORD`)
- Rotate credentials regularly

**DON'T:**
- Store credentials in plain text config files
- Commit unencrypted credentials to git
- Share credentials through insecure channels
- Use the same credentials across environments

### 2. Connection Patterns

**Option 1: Connection Strings (Recommended)**
```bash
# Best for applications
fnox set DATABASE_URL "postgresql://user:password@host:5432/database"
fnox exec -- ./app
```

**Option 2: Individual Credentials**
```bash
# Best for manual connections
fnox set DB_HOST "db.example.com"
fnox set DB_USER "admin"
fnox set DB_PASSWORD "password"
fnox exec -- psql -h $DB_HOST -U $DB_USER
```

**Option 3: Cloud Secret Manager**
```bash
# Best for production environments
# In fnox.toml:
[profiles.production.providers]
aws = { type = "aws-sm", region = "us-east-1", prefix = "prod/" }

[profiles.production.secrets]
DATABASE_URL = { provider = "aws", value = "database-connection-string" }
```

### 3. Environment-Specific Configuration

Create separate profiles in `fnox.toml`:

```toml
# Development
[profiles.development.secrets]
DB_HOST = { default = "localhost" }
DB_PORT = { default = "5432" }
DB_NAME = { default = "myapp_dev" }

# Staging
[profiles.staging.providers]
aws = { type = "aws-sm", region = "us-east-1", prefix = "staging/" }

[profiles.staging.secrets]
DATABASE_URL = { provider = "aws", value = "database-url" }

# Production
[profiles.production.providers]
aws = { type = "aws-sm", region = "us-east-1", prefix = "prod/" }

[profiles.production.secrets]
DATABASE_URL = { provider = "aws", value = "database-url" }
```

Usage:
```bash
# Development (default)
fnox exec -- psql $DATABASE_URL

# Staging
fnox exec --profile staging -- psql $DATABASE_URL

# Production
fnox exec --profile production -- psql $DATABASE_URL
```

### 4. Shell Aliases for Database Connections

Add to `dot_bash_aliases`:

```bash
# Database connection aliases
alias psql-dev='fnox exec -- psql $DEV_DATABASE_URL'
alias psql-staging='fnox exec --profile staging -- psql $DATABASE_URL'
alias psql-prod='fnox exec --profile production -- psql $DATABASE_URL'

alias mysql-dev='fnox exec -- mysql -h $DEV_MYSQL_HOST -u $DEV_MYSQL_USER -p$DEV_MYSQL_PASSWORD'
alias mongo-dev='fnox exec -- mongosh $DEV_MONGODB_URI'
```

### 5. Database Scripts Management

Store database migration scripts and tools:

```
dotfiles/
├── home/
│   └── dot_local/
│       └── bin/
│           ├── executable_db-backup.sh
│           ├── executable_db-restore.sh
│           └── executable_db-migrate.sh
```

Example `db-backup.sh`:
```bash
#!/usr/bin/env bash
# Database backup script

set -euo pipefail

BACKUP_DIR="$HOME/backups/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Load secrets from fnox
eval "$(fnox export)"

# Backup PostgreSQL
pg_dump $DATABASE_URL > "$BACKUP_DIR/postgres_backup.sql"

# Backup MySQL
mysqldump -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > "$BACKUP_DIR/mysql_backup.sql"

echo "Backups completed: $BACKUP_DIR"
```

## Cloud-Specific Database Tools

### AWS RDS

```bash
# Add AWS CLI to mise.toml
[tools]
awscli = "latest"

# Store AWS credentials in fnox
fnox set AWS_ACCESS_KEY_ID "AKIA..."
fnox set AWS_SECRET_ACCESS_KEY "secret"
fnox set AWS_DEFAULT_REGION "us-east-1"

# Get RDS connection details
fnox exec -- aws rds describe-db-instances

# Connect to RDS PostgreSQL
fnox exec -- psql -h mydb.xxxxx.us-east-1.rds.amazonaws.com -U admin -d mydb
```

### Azure SQL Database

```bash
# Add Azure CLI to mise.toml
[tools]
"azure-cli" = "latest"

# Store Azure credentials in fnox
fnox set AZURE_CLIENT_ID "client-id"
fnox set AZURE_CLIENT_SECRET "secret"
fnox set AZURE_TENANT_ID "tenant-id"

# Login to Azure
fnox exec -- az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID

# Connect to Azure SQL
fnox exec -- sqlcmd -S myserver.database.windows.net -d mydb -U admin -P $AZURE_SQL_PASSWORD
```

### OCI Database (Oracle Cloud)

```bash
# OCI CLI is already in mise.toml
[tools]
oci = "latest"

# Store OCI credentials in fnox
fnox set OCI_USER_OCID "ocid1.user..."
fnox set OCI_FINGERPRINT "aa:bb:cc:..."
fnox set OCI_TENANCY_OCID "ocid1.tenancy..."
fnox set OCI_REGION "us-ashburn-1"
fnox set OCI_PRIVATE_KEY "$(cat ~/.oci/oci_api_key.pem)"

# Create OCI config from template
# In dot_oci/config.tmpl
chezmoi add --template ~/.oci/config
```

## Scenarios and Recommendations

### Scenario 1: Local Development

**Setup:**
- Use local database instances (Docker)
- Store connection details in fnox with default values
- Use `localhost` connections

**Example:**
```bash
# Run local databases with Docker
docker run -d --name postgres -p 5432:5432 -e POSTGRES_PASSWORD=dev postgres
docker run -d --name mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=dev mysql

# Store in fnox with defaults
fnox set DEV_POSTGRES_URL "postgresql://postgres:dev@localhost:5432/postgres"
fnox set DEV_MYSQL_URL "mysql://root:dev@localhost:3306/mysql"
```

### Scenario 2: Multi-Cloud DBA

**Setup:**
- Install all cloud CLIs (AWS, Azure, OCI)
- Use cloud secret managers for production credentials
- Use age encryption for development credentials

**Example mise.toml:**
```toml
[tools]
awscli = "latest"
"azure-cli" = "latest"
oci = "latest"
postgres = "latest"
mysql = "latest"
```

**Example fnox.toml:**
```toml
[profiles.aws-prod.providers]
aws = { type = "aws-sm", region = "us-east-1", prefix = "prod/" }

[profiles.azure-prod.providers]
azure = { type = "azure-sm", vault_url = "https://myvault.vault.azure.net" }

[profiles.oci-prod.providers]
# OCI Vault integration (if available)
# Otherwise use age encryption
age = { type = "age", recipients = ["age1..."] }
```

### Scenario 3: Database Migration Projects

**Setup:**
- Install source and target database clients
- Store both source and target credentials
- Create migration scripts

**Example:**
```bash
# Add tools
mise use -g postgres@latest mysql@latest

# Store credentials
fnox set SOURCE_MYSQL_URL "mysql://user:pass@old-host:3306/db"
fnox set TARGET_POSTGRES_URL "postgresql://user:pass@new-host:5432/db"

# Create migration script
cat > ~/.local/bin/db-migrate << 'EOF'
#!/usr/bin/env bash
eval "$(fnox export)"

# Extract from MySQL
mysqldump $SOURCE_MYSQL_URL > /tmp/dump.sql

# Convert and import to PostgreSQL
# (use appropriate conversion tools)
psql $TARGET_POSTGRES_URL < /tmp/converted.sql
EOF

chmod +x ~/.local/bin/db-migrate
```

### Scenario 4: Database Monitoring and Automation

**Setup:**
- Create monitoring scripts
- Store in dotfiles as executable files
- Schedule with cron or systemd timers

**Example structure:**
```
home/
└── dot_local/
    └── bin/
        ├── executable_db-health-check.sh
        ├── executable_db-backup-all.sh
        └── executable_db-stats.sh
```

## Tips and Tricks

### 1. Tab Completion

Enable bash completion for database tools:
```bash
# Add to dot_bashrc
if command -v psql >/dev/null 2>&1; then
    complete -C psql psql
fi
```

### 2. Connection Aliases with Auto-Export

```bash
# Add to dot_bash_aliases
alias db='eval "$(fnox export)" && psql $DATABASE_URL'
```

### 3. Quick Database Shell Access

```bash
# Add to dot_bash_aliases
dbshell() {
    local profile="${1:-development}"
    fnox exec --profile "$profile" -- psql $DATABASE_URL
}

# Usage:
# dbshell              # Connect to dev
# dbshell staging      # Connect to staging
# dbshell production   # Connect to production
```

### 4. Database Version Check Script

```bash
#!/usr/bin/env bash
# Check versions of all database tools

echo "Database Client Versions:"
echo "========================="
command -v psql >/dev/null && echo "PostgreSQL: $(psql --version)"
command -v mysql >/dev/null && echo "MySQL: $(mysql --version)"
command -v mongosh >/dev/null && echo "MongoDB: $(mongosh --version)"
command -v redis-cli >/dev/null && echo "Redis: $(redis-cli --version)"
command -v sqlplus >/dev/null && echo "Oracle: $(sqlplus -version)"
```

## Security Checklist

- [ ] All database credentials stored in fnox
- [ ] Age encryption key backed up securely
- [ ] Production credentials in cloud secret manager
- [ ] No credentials in git history
- [ ] Connection strings don't include passwords in shell history
- [ ] Regular credential rotation policy in place
- [ ] Separate credentials for each environment
- [ ] Audit logging enabled for production access
- [ ] MFA enabled for cloud console access
- [ ] SSH tunnels used for remote database access when needed

## Common Issues and Solutions

### Issue: "Connection refused"
```bash
# Check if database is running
docker ps | grep postgres

# Check network connectivity
telnet db-host 5432
```

### Issue: "Authentication failed"
```bash
# Verify credentials
fnox get DB_PASSWORD

# Check if password contains special characters that need escaping
# Consider using connection strings instead
```

### Issue: "Tool not found after installation"
```bash
# Reload shell
source ~/.bashrc

# Verify mise installation
mise list

# Reinstall tool
mise install postgres
```

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Oracle Documentation](https://docs.oracle.com/en/database/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/documentation)
- [fnox Documentation](https://fnox.jdx.dev/)
- [mise Documentation](https://mise.jdx.dev/)

## Contributing

If you have suggestions for improving database tool integration, please:

1. Fork the dotfiles repository
2. Add your improvements
3. Test thoroughly
4. Submit a pull request

## Support

For issues or questions:
- GitHub Issues: https://github.com/msavdert/dotfiles/issues
- Email: 10913156+msavdert@users.noreply.github.com

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build the fat JAR (shaded, main class: KerberosClient)
mvn clean package

# Run the full stack (KDC + app)
docker-compose up --build

# Restart only the app container (e.g., after keytab changes)
docker-compose restart kerberos-app
```

## First-Time KDC Setup

After `docker-compose up`, create principals and keytabs inside the KDC container:

```bash
docker exec -it kdc-service sh

kadmin.local -q "addprinc -pw password client@EXAMPLE.COM"
kadmin.local -q "ktadd -k /etc/security/keytabs/client.keytab client@EXAMPLE.COM"

kadmin.local -q "addprinc -pw password service/localhost@EXAMPLE.COM"
kadmin.local -q "ktadd -k /etc/security/keytabs/server.keytab service/localhost@EXAMPLE.COM"
```

Keytabs are written to the `./keytabs/` volume shared between KDC and app containers.

## Architecture

The project demonstrates Kerberos/GSSAPI authentication with two roles:

- **KerberosClient** — logs in via JAAS (`Client` entry in `jaas.conf`), acquires a Kerberos TGT from keytab, then initiates a GSSAPI security context toward a service principal. The service principal can be overridden with `-Dservice.principal=<name>`.
- **KerberosServer** — logs in via JAAS (`Server` entry in `jaas.conf`) and sets up a GSSAPI acceptor context. The actual token exchange loop (send/receive over a socket) is stubbed out — the skeleton is in place for extension.

### Configuration files

| File | Purpose |
|---|---|
| `src/main/resources/krb5.conf` | Kerberos realm config; realm is `EXAMPLE.COM`, KDC host is `kdc-service` |
| `src/main/resources/jaas.conf` | JAAS login modules for `Client` and `Server`; both use keytab-based auth |
| `Dockerfile` | Multi-stage build; copies configs to `/etc/kerberos/jaas.conf` and `/etc/krb5.conf`; Kerberos debug enabled via `-Dsun.security.krb5.debug=true` |
| `Dockerfile.kdc` | MIT Kerberos 5 KDC image based on `debian:bookworm-slim` |
| `kdc-entrypoint.sh` | Initializes the KDC database, creates `admin/admin` principal, starts `krb5kdc` and `kadmind` |

### Key JVM flags (set in Dockerfile ENTRYPOINT)

```
-Djava.security.auth.login.config=/etc/kerberos/jaas.conf
-Djava.security.krb5.conf=/etc/krb5.conf
-Dsun.security.krb5.debug=true
```

These must be set when running the JAR outside Docker as well.

## Realm & Principal Reference

| Item | Value |
|---|---|
| Realm | `EXAMPLE.COM` |
| KDC host | `kdc-service` |
| Client principal | `client@EXAMPLE.COM` |
| Service principal | `service/localhost@EXAMPLE.COM` |
| Keytab volume path | `./keytabs/` (host) → `/etc/security/keytabs/` (container) |

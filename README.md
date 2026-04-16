# Kerberos Test Project

This project provides a simple Java application to test and learn about the Kerberos authentication protocol.

## Project Structure

- `src/main/java`: Contains `KerberosClient` and `KerberosServer` samples.
- `src/main/resources`: Contains `jaas.conf` and `krb5.conf`.
- `Dockerfile`: Multi-stage build for the Java application.
- `docker-compose.yml`: Orchestrates the application and a KDC (Key Distribution Center).

## How to Run

1. **Build the project**:
   ```bash
   mvn clean package
   ```

2. **Run with Docker Compose**:
   ```bash
   docker-compose up --build
   ```

3. **Initialize Principals and Keytabs** (First run only):
   After the containers are starting, you need to create the principals and export the keytabs to the shared volume.
   
   Note: The admin principal `admin/admin@EXAMPLE.COM` is created automatically on the first run of the KDC.
   
   ```bash
   # Enter the KDC container
   docker exec -it kdc-service sh

   # Create the client principal
   kadmin.local -q "addprinc -pw password client@EXAMPLE.COM"
   kadmin.local -q "ktadd -k /etc/security/keytabs/client.keytab client@EXAMPLE.COM"

   # Create the service principal
   kadmin.local -q "addprinc -pw password service/localhost@EXAMPLE.COM"
   kadmin.local -q "ktadd -k /etc/security/keytabs/server.keytab service/localhost@EXAMPLE.COM"

   exit
   ```

4. **Restart the app container** to pick up the keytabs:
   ```bash
   docker-compose restart kerberos-app
   ```

## Configuration

- **Realm**: `EXAMPLE.COM`
- **KDC Host**: `kdc-service`
- **Client Principal**: `client@EXAMPLE.COM`
- **Service Principal**: `service/localhost@EXAMPLE.COM`

Make sure to generate the appropriate keytabs and place them in the `./keytabs` directory before running, or ensure the KDC container is configured to generate them on startup.

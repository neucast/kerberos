# Use Maven to build the application
FROM maven:3.8-eclipse-temurin-17 AS build
COPY src /home/app/src
COPY pom.xml /home/app
RUN mvn -f /home/app/pom.xml clean package

# Use Eclipse Temurin for the runtime
FROM eclipse-temurin:17-jre-jammy
COPY --from=build /home/app/target/kerberos-test-app-1.0-SNAPSHOT.jar /usr/local/lib/kerberos-test-app.jar
COPY src/main/resources/jaas.conf /etc/kerberos/jaas.conf
COPY src/main/resources/krb5.conf /etc/krb5.conf

# We will mount keytabs from a volume or shared folder
ENTRYPOINT ["java", \
            "-Djava.security.auth.login.config=/etc/kerberos/jaas.conf", \
            "-Djava.security.krb5.conf=/etc/krb5.conf", \
            "-Dsun.security.krb5.debug=true", \
            "-jar", "/usr/local/lib/kerberos-test-app.jar"]

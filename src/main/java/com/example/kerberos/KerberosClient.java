package com.example.kerberos;

import javax.security.auth.Subject;
import javax.security.auth.login.LoginContext;
import javax.security.auth.login.LoginException;
import java.security.PrivilegedAction;
import org.ietf.jgss.*;

public class KerberosClient {
    public static void main(String[] args) {
        try {
            // "Client" corresponds to the entry in jaas.conf
            LoginContext lc = new LoginContext("Client");
            lc.login();
            System.out.println("Client logged in successfully.");

            Subject.doAs(lc.getSubject(), (PrivilegedAction<Void>) () -> {
                try {
                    GSSManager manager = GSSManager.getInstance();
                    
                    // The principal of the service we want to connect to
                    String servicePrincipal = System.getProperty("service.principal", "service/localhost@EXAMPLE.COM");
                    Oid krb5Mech = new Oid("1.2.840.113554.1.2.2");
                    
                    GSSName serverName = manager.createName(servicePrincipal, GSSName.NT_HOSTBASED_SERVICE);
                    GSSContext context = manager.createContext(serverName, krb5Mech, null, GSSContext.DEFAULT_LIFETIME);
                    
                    context.requestMutualAuth(true);
                    context.requestConf(true);
                    context.requestInteg(true);

                    byte[] token = new byte[0];
                    while (!context.isEstablished()) {
                        token = context.initSecContext(token, 0, token.length);
                        if (token != null) {
                            System.out.println("Sending token to server...");
                            // In a real app, you'd send this token to the server
                            // Here we just simulate or print
                        }
                    }
                    System.out.println("Context established!");
                    context.dispose();
                } catch (GSSException e) {
                    e.printStackTrace();
                }
                return null;
            });
            
            lc.logout();
        } catch (LoginException e) {
            e.printStackTrace();
        }
    }
}

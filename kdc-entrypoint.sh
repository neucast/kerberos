#!/bin/sh
set -e

# Default values if not provided
REALM=${KRB5_REALM:-EXAMPLE.COM}
KDC_NAME=${KRB5_KDC:-localhost}
ADMIN_PASS=${KRB5_PASS:-password}

# Create krb5.conf if it doesn't exist
if [ ! -f /etc/krb5.conf ]; then
cat <<EOF > /etc/krb5.conf
[libdefaults]
    default_realm = $REALM
    dns_lookup_realm = false
    dns_lookup_kdc = false

[realms]
    $REALM = {
        kdc = $KDC_NAME
        admin_server = $KDC_NAME
    }

[domain_realm]
    .$KDC_NAME = $REALM
    $KDC_NAME = $REALM
EOF
fi

# Create kdc.conf if it doesn't exist
mkdir -p /var/lib/krb5kdc
if [ ! -f /var/lib/krb5kdc/kdc.conf ]; then
cat <<EOF > /var/lib/krb5kdc/kdc.conf
[kdcdefaults]
    kdc_ports = 88,750

[realms]
    $REALM = {
        database_name = /var/lib/krb5kdc/principal
        admin_keytab = /var/lib/krb5kdc/kadm5.keytab
        acl_file = /var/lib/krb5kdc/kadm5.acl
        key_stash_file = /var/lib/krb5kdc/stash
        max_life = 10h 0m 0s
        max_renewable_life = 7d 0h 0m 0s
        master_key_type = aes256-cts
        supported_enctypes = aes256-cts:normal aes128-cts:normal
    }
EOF
fi

# Create ACL file if it doesn't exist
if [ ! -f /var/lib/krb5kdc/kadm5.acl ]; then
    echo "*/admin@$REALM *" > /var/lib/krb5kdc/kadm5.acl
fi

# Initialize database if it doesn't exist
if [ ! -f /var/lib/krb5kdc/principal ]; then
    echo "Creating Kerberos database for realm $REALM..."
    kdb5_util create -s -P "$ADMIN_PASS"
    
    # Create an admin principal
    kadmin.local -q "addprinc -pw $ADMIN_PASS admin/admin@$REALM"
fi

# Start KDC and Kadmind
echo "Starting Kerberos services..."
krb5kdc -n &
kadmind -nofork

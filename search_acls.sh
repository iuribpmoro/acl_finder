#!/bin/bash

# Variables (Change these accordingly)
LDAP_SERVER="192.168.56.11"
LDAP_BIND_DN="samwell.tarly@north.sevenkingdoms.local"
LDAP_PASS="Heartsbane"
BASE_DN="dc=north,dc=sevenkingdoms,dc=local"

IMPACKET_PATH="/opt/impacket/examples/dacledit.py"
IMPACKET_USER="north.sevenkingdoms.local/samwell.tarly"

OUTFOLDER="acl_collection"

# Function to run dacledit against a target
function check_acls() {
    local target_dn=$1
    local target_name=$2
    local target_type=$3
    
    if [[ "$target_type" == "computer" ]]; then
        echo "[*] Checking ACLs for target: $target_name"
        python3 "$IMPACKET_PATH" -action read -target "$target_name" -dc-ip "$LDAP_SERVER" "$IMPACKET_USER":"$LDAP_PASS" > "./$OUTFOLDER/$target_name.acl"
    else
        echo "[*] Checking ACLs for target: $target_name"
        python3 "$IMPACKET_PATH" -action read -target-dn "$target_dn" -dc-ip "$LDAP_SERVER" "$IMPACKET_USER":"$LDAP_PASS" > "./$OUTFOLDER/$target_name.acl"
    fi

}

mkdir -p $OUTFOLDER

# Get all users, groups and GPOs from LDAP and use them as target
echo "[*] Enumerating all users, groups and GPOs in LDAP..."
ldapsearch -x -LLL -H "ldap://$LDAP_SERVER" -D "$LDAP_BIND_DN" -w "$LDAP_PASS" -b "$BASE_DN" -o ldif-wrap=no "(|(objectClass=user)(objectClass=group)(objectClass=groupPolicyContainer))" dn | while read -r line; do
    if [[ "$line" == dn:* ]]; then
        target_dn=$(echo "$line" | cut -d' ' -f2-)
        target_name=$(echo "$target_dn" | cut -d ',' -f1 | cut -d '=' -f2)
        
        if [ ! -f "$OUTFOLDER/$target_name.acl" ]; then
            # Run dacledit for the current target
            check_acls "$target_dn" "$target_name" "simple"
        fi    
    fi
done

# Get all computers from LDAP and use them as target
echo "[*] Enumerating all computers in LDAP..."
ldapsearch -x -LLL -H "ldap://$LDAP_SERVER" -D "$LDAP_BIND_DN" -w "$LDAP_PASS" -b "$BASE_DN" -o ldif-wrap=no "(objectClass=computer)" dn | tee computers.out | while read -r line; do
    if [[ "$line" == dn:* ]]; then
        target_dn=$(echo "$line" | cut -d' ' -f2-)
        target_name=$(echo "$target_dn" | cut -d ',' -f1 | cut -d '=' -f2)
        target_name=$target_name$
        
        if [ ! -f "$OUTFOLDER/$target_name.acl" ]; then
            # Run dacledit for the current target
            check_acls "$target_dn" "$target_name" "computer"
        fi    
    fi
done

echo "[*] Enumeration completed."

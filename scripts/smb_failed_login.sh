#!/bin/bash

TARGET="192.168.1.4"
USERNAME="kali-attacker"
PASSWORD="wrongpassword"

echo "[*] Generating failed SMB authentication events..."

for i in {1..5}; do
    echo "[Attempt $i]"
    smbclient -L //$TARGET -U ${USERNAME}%${PASSWORD} >/dev/null 2>&1
    sleep 1
done

echo "[+] Completed."

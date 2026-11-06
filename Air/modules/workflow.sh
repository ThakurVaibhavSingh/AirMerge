#!/bin/bash

pad() {
    local str="$1" width="$2" len spaces
    len=${#str}
    spaces=$(( width - len ))
    (( spaces < 0 )) && spaces=0
    printf '%s%*s' "$str" "$spaces" ''
}

row() {
    printf '%s' "$(pad "$1" 30)$(pad "$2" 31)$(pad "$3" 28)$(pad "$4" 32)$(pad "$5" 39)$(pad "$6" 33)"
}

workflow() {
    buck "$(pad "[WiFi]" 30)$(pad "[Bettercap]" 31)$(pad "[Nmap-NetIP]" 28)$(pad "[Nmap-OtherIP]" 32)$(pad "[Metasploit]" 39)$(pad "[Hashcat]" 33)"
    ask "$(row "├──Monitor Mode" "├──Scan" "├──Scan Host" "├──Host Reachability" "├──Start/Connect" "├──ZIP/RAR/7Z/CAP/OFFICE/KDBX")"
    ask "$(row "├──Managed Mode" "├──Select AP" "├──Ports-&-Service" "└──Ports" "├──Server Open" "├──Wordlist Creation")"
    ask "$(row "└──Scan" "├──DNS+ARP Spoof" "├──Security-&-Firewall" "   ├──Service" "├──Network/Exploit Search" "├──HASHCAT")"
    ask "$(row "   ├├──NMAP Private" "├──MITM" "├──OS Version" "   ├──Security" "├──Active Session" "├──AIRCRACK")"
    ask "$(row "   ├└──NMAP Public" "└──NMAP others" "└──View Last Scan" "   └──Active User" "├──Post Exploitation" "├──JOHN")"
    ask "$(row "   ├──Deauth" "" "" "" "└──Payloads" "└──Clear Previous Cache")"
    ask "$(row "   └──Handshake" "" "" "" "" "")"
    printf "\n"
    enter
}

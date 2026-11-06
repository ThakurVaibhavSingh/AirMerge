#!/usr/bin/env python3
import csv
import sys
import re

MAC_RE = re.compile(r"^[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}$")


def detect_format(path):
    """Peek at the file to decide which parser to use."""
    with open(path, encoding="utf-8", errors="ignore") as f:
        head = f.read(4096)

    # Bettercap's wifi.show table uses box-drawing chars and a BSSID/Ch header.
    if "│" in head or ("BSSID" in head and re.search(r"\bCh\b", head)):
        return "bettercap"
    return "airodump"


def parse_airodump(path):
    with open(path, newline="", encoding="utf-8", errors="ignore") as f:
        reader = csv.reader(f)
        rows = list(reader)

    results = []
    # Skip first 2 header lines, same as the original awk logic
    for row in rows[2:]:
        if len(row) < 4:
            continue
        bssid = row[0].strip()
        channel = row[3].strip()

        if not MAC_RE.match(bssid):
            continue
        # Skip rows with no valid channel captured yet
        if "-" in channel or not channel:
            continue

        results.append((bssid, channel))

    return results


def parse_bettercap(path):
    with open(path, encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    in_wifi_table = False
    results = []

    for line in lines:
        # Anchor on the wifi.show header row specifically (has both BSSID and Ch),
        # not the net.show table (IP/MAC/Name/Vendor) which appears first.
        if "BSSID" in line and re.search(r"\bCh\b", line):
            in_wifi_table = True
            continue
        if in_wifi_table and line.strip().startswith(("└", "+")):
            break
        if in_wifi_table and "│" in line:
            cols = [c.strip() for c in line.split("│")]
            # cols: ['', RSSI, BSSID, SSID, Encryption, WPS, Ch, Clients, Sent, Recvd, Seen, '']
            if len(cols) < 8:
                continue
            bssid = cols[2]
            channel = cols[6]
            if not MAC_RE.match(bssid):
                continue
            if not channel:
                # Channel not captured yet for this AP — skip rather than emit a bad value
                continue
            results.append((bssid, channel))

    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: parse_scan.py <scan_file>", file=sys.stderr)
        sys.exit(1)

    path = sys.argv[1]
    fmt = detect_format(path)

    if fmt == "bettercap":
        results = parse_bettercap(path)
    else:
        results = parse_airodump(path)

    for i, (bssid, channel) in enumerate(results, 1):
        print(f"{i}. {bssid}, {channel}")


if __name__ == "__main__":
    main()

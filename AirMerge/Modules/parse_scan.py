#!/usr/bin/env python3
import csv
import sys
import re

def main():
    if len(sys.argv) < 2:
        print("Usage: parse_scan.py <csv_file>", file=sys.stderr)
        sys.exit(1)

    csv_file = sys.argv[1]
    count = 0
    results = []

    with open(csv_file, newline="", encoding="utf-8", errors="ignore") as f:
        reader = csv.reader(f)
        rows = list(reader)

    # Skip first 2 lines (NR>2 equivalent), same as your awk logic
    for row in rows[2:]:
        if len(row) < 4:
            continue
        bssid = row[0].strip()
        power = row[3].strip()

        # $1 ~ /^[0-9A-Fa-f]{2}:/  -> bssid must start like "AA:"
        if not re.match(r"^[0-9A-Fa-f]{2}:", bssid):
            continue
        # $4 !~ /-/  -> skip if power field contains "-"
        if "-" in power:
            continue

        count += 1
        results.append((count, bssid, power))

    for num, bssid, power in results:
        print(f"{num}. {bssid}, {power}")

if __name__ == "__main__":
    main()

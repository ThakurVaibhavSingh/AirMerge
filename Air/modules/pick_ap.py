#!/usr/bin/env python3
import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: pick_ap.py <results_file> <pick_number>", file=sys.stderr)
        sys.exit(1)

    results_file = sys.argv[1]
    pick = int(sys.argv[2])

    with open(results_file, encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()

    if pick < 1 or pick > len(lines):
        print("", "")
        sys.exit(1)

    line = lines[pick - 1].strip()
    # line looks like: "3. AA:BB:CC:DD:EE:FF, -45"
    after_dot = line.split(".", 1)[1].strip()      # "AA:BB:CC:DD:EE:FF, -45"
    bssid, power = after_dot.split(",", 1)
    print(f"{bssid.strip()},{power.strip()}")

if __name__ == "__main__":
    main()

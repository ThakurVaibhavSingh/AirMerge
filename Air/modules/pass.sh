#!/bin/bash
# save as: create_test_files.sh
# run: chmod +x create_test_files.sh && ./create_test_files.sh

PASS="123"
DIR="$HOME/AirMerge/test_files"
mkdir -p "$DIR"
cd "$DIR"

# Create content file
echo -e "This is a test file for AirMerge cracking.\nPassword is $PASS." > secret.txt

# 1. ZIP
zip -j -P "$PASS" test_3digit.zip secret.txt

# 2. 7Z (install: sudo apt install p7zip-full)
7z a -p"$PASS" -mhe=on test_3digit.7z secret.txt

# 3. RAR (install: sudo apt install rar or download from rarlab)
rar a -p"$PASS" test_3digit.rar secret.txt

# 4. PDF (install: sudo apt install qpdf)
# First create a simple PDF with LibreOffice or text2pdf, then encrypt:
qpdf --encrypt "$PASS" "$PASS" 128 -- input.pdf test_3digit.pdf

# 5. KeePass (install: pip install pykeepass)
python3 -c "
from pykeepass import create_database
kp = create_database('test_3digit.kdbx', password='$PASS')
kp.add_entry(kp.root_group, 'test', 'user', 'pass123')
kp.save()
"

# 6. Office DOCX (encrypted with LibreOffice)
libreoffice --headless --convert-to docx secret.txt
# Then encrypt (manual step in LibreOffice GUI, or use msoffcrypto with Python)

rm secret.txt
echo "Done! Files in: $DIR"
ls -la "$DIR"
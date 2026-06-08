#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_DIR="$(dirname "$SCRIPT_DIR")"
CONTENT_DIR="$SCRIPT_DIR/content"

echo "==> Copie des fichiers du vault..."

FOLDERS=("Œuvres" "Concepts" "Questions" "Références" "Médias" "Prototypes")

for folder in "${FOLDERS[@]}"; do
    src="$VAULT_DIR/$folder"
    dst="$CONTENT_DIR/$folder"
    if [ -d "$src" ]; then
        rm -rf "$dst"
        cp -r "$src" "$dst"
        echo "    ✓ $folder"
    else
        echo "    ✗ $folder manquant dans le vault"
    fi
done

echo "==> Normalisation NFC des noms de fichiers..."

python3 - <<'PYEOF'
import os, unicodedata

renamed = 0
for root, dirs, files in os.walk('content'):
    # Normalize filenames
    for f in files:
        nfc = unicodedata.normalize('NFC', f)
        if f != nfc:
            os.rename(os.path.join(root, f), os.path.join(root, nfc))
            renamed += 1
    # Normalize directory names (bottom-up handled by walking)
    for d in dirs:
        nfc = unicodedata.normalize('NFC', d)
        if d != nfc:
            src = os.path.join(root, d)
            dst = os.path.join(root, nfc)
            if not os.path.exists(dst):
                os.rename(src, dst)
            renamed += 1

print(f"    {renamed} fichier(s) renommé(s) en NFC")
PYEOF

echo ""
read -p "Message de commit : " msg

if [ -z "$msg" ]; then
    msg="Update portfolio content"
fi

echo ""
echo "==> Git..."
git -C "$SCRIPT_DIR" add -A
git -C "$SCRIPT_DIR" commit -m "$msg"
git -C "$SCRIPT_DIR" push

echo ""
echo "✓ Déployé : $msg"

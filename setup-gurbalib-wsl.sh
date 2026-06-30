#!/bin/bash
# Gurbalib + DGD setup script for WSL (Ubuntu/Debian)
set -euo pipefail

INSTALL_DIR="${1:-$HOME/gurbalib}"
GURBALIB_REPO="${GURBALIB_REPO:-https://github.com/sirdude/gurbalib.git}"

echo "==> Installing build dependencies..."
sudo apt-get update -qq
sudo apt-get install -y build-essential g++ bison git perl

echo "==> Cloning gurbalib into $INSTALL_DIR..."
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "    Directory already exists; pulling latest..."
  git -C "$INSTALL_DIR" pull
else
  git clone "$GURBALIB_REPO" "$INSTALL_DIR"
fi
cd "$INSTALL_DIR"

echo "==> Creating data directories..."
printf 'Y\nY\nY\nY\n' | perl scripts/create_data_dirs

echo "==> Building DGD driver..."
if [ ! -d src/dgd/.git ]; then
  git clone https://github.com/dworkin/dgd.git src/dgd
  git -C src/dgd submodule init
  git -C src/dgd submodule update
fi
make -C src/dgd/src CXX=g++
make -C src/dgd/src install CXX=g++ || true  # first install may warn about dgd.old

echo "==> Installing binaries and config..."
cp src/dgd/bin/dgd bin/
cp -n mud.dgd.examp mud.dgd 2>/dev/null || true
cp -n lib/kernel/include/local_config.h.default lib/kernel/include/local_config.h 2>/dev/null || true
cp scripts/startmud bin/startmud
chmod +x bin/startmud

# mud.dgd requires an absolute path
sed -i "s|directory[[:space:]]*=[[:space:]]*\".*\";|directory\t= \"$INSTALL_DIR/lib/\";|" mud.dgd

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Edit lib/kernel/include/local_config.h (MUD_NAME, IMUD_NAME, ADMIN_EMAIL)"
echo "  2. Start the mud:  cd $INSTALL_DIR && ./bin/startmud"
echo "  3. Connect:        telnet localhost 4000   (or use PuTTY / Windows Terminal)"
echo ""
echo "Notes:"
echo "  - First player to log in becomes admin (log out and back in for admin to work)"
echo "  - Logs: $INSTALL_DIR/lib/logs/gurba-driver.log"
echo "  - FTP server runs on port 4001"

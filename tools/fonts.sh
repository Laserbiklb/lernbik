#!/bin/sh
# Downloads the Rajdhani headline font (SIL Open Font License) into assets/fonts.
set -e
cd "$(dirname "$0")/../assets/fonts"
for w in SemiBold Bold; do
  curl -fsSL -o "Rajdhani-$w.ttf" "https://github.com/google/fonts/raw/main/ofl/rajdhani/Rajdhani-$w.ttf"
done
ls -la

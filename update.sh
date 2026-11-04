#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_AGENT="${USER_AGENT:-Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36}"
BASE_URL="http://orteil.dashnet.org/cookieclicker"

rm -rf "$ROOT_DIR/img" "$ROOT_DIR/loc" "$ROOT_DIR/snd"
mkdir -p "$ROOT_DIR/img" "$ROOT_DIR/loc" "$ROOT_DIR/snd"

while IFS= read -r file; do
  [ -n "$file" ] && rm -f "$ROOT_DIR/$file"
done < "$ROOT_DIR/_jslist.txt"

cd "$ROOT_DIR/img"
wget --user-agent="$USER_AGENT" --convert-links -O index.html "$BASE_URL/img/"
grep -v PARENTDIR index.html | grep '\[IMG' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _imglist.txt
wget --user-agent="$USER_AGENT" -N -i _imglist.txt -B "$BASE_URL/img/"

cd "$ROOT_DIR/snd"
wget --user-agent="$USER_AGENT" --convert-links -O index.html "$BASE_URL/snd/"
grep -v PARENTDIR index.html | grep '\[SND' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _sndlist.txt
wget --user-agent="$USER_AGENT" -N -i _sndlist.txt -B "$BASE_URL/snd/"

cd "$ROOT_DIR/loc"
wget --user-agent="$USER_AGENT" --convert-links -O index.html "$BASE_URL/loc/"
grep -v PARENTDIR index.html | grep '\[TXT' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _loclist.txt
wget --user-agent="$USER_AGENT" -i _loclist.txt "$BASE_URL/loc/"

cd "$ROOT_DIR"
wget --user-agent="$USER_AGENT" -O index.html "$BASE_URL/"
wget --user-agent="$USER_AGENT" -O style.css "$BASE_URL/style.css"
wget --user-agent="$USER_AGENT" -i _jslist.txt -B "$BASE_URL/"
wget --user-agent="$USER_AGENT" -O grab.txt http://orteil.dashnet.org/patreon/grab.php

grep -Po 'url\(\K/cf-fonts/[^)]+' index.html > _fontlist.txt
wget --user-agent="$USER_AGENT" -x -nH -N -i _fontlist.txt -B http://orteil.dashnet.org

sed -i 's|url(/cf-fonts/|url(cf-fonts/|g' index.html
sed -i "s|DataDir=window.location.origin+'/data/';|DataDir='https://orteil.dashnet.org/data/';|g" main.js

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_AGENT="${USER_AGENT:-Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36}"
BASE_URL="http://orteil.dashnet.org/cookieclicker"
DOWNLOAD_CONNECTIONS="${DOWNLOAD_CONNECTIONS:-8}"

if ! [[ "$DOWNLOAD_CONNECTIONS" =~ ^[1-9][0-9]*$ ]]; then
  echo "DOWNLOAD_CONNECTIONS must be a positive integer" >&2
  exit 1
fi

download_list() {
  local list="$1"
  local base_url="$2"
  shift 2

  xargs -r -P "$DOWNLOAD_CONNECTIONS" -n 1 \
    wget --user-agent="$USER_AGENT" "$@" -B "$base_url" < "$list"
}

download_html_pages() {
  local origin="${BASE_URL%/cookieclicker}"
  local page_links
  local href
  local url
  local path

  page_links="$(mktemp)"
  trap 'rm -f "$page_links"' RETURN

  while IFS= read -r href; do
    case "$href" in
      \#*|'mailto:'*|'javascript:'*|'data:'*|'')
        continue
        ;;
      //*)
        case "$href" in
            "//orteil.dashnet.org/"*)
              url="http:$href"
              ;;
            *)
              continue
            ;;
        esac
        ;;
      http://orteil.dashnet.org/*|https://orteil.dashnet.org/*)
        url="$href"
        ;;
      http://*|https://*)
        continue
        ;;
      /*)
        url="$origin$href"
        ;;
      ../*|..)
        continue
        ;;
      *)
        url="$BASE_URL/${href#./}"
        ;;
    esac

    path="${url%%[\?#]*}"
    case "$path" in
      *.css|*.gif|*.ico|*.jpg|*.jpeg|*.js|*.json|*.mp3|*.ogg|*.png|*.svg|*.ttf|*.wav|*.webm|*.woff|*.woff2)
        continue
        ;;
    esac
    printf '%s\n' "$url"
  done < <(grep -Po "(?i)(?<=href=[\"'])[^\"']+" "$ROOT_DIR/index.html") |
    sort -u > "$page_links"

  {
    printf '%s\n' "$BASE_URL/"
    cat "$page_links"
  } | sort -u > "$page_links.all"

  wget --user-agent="$USER_AGENT" \
    --recursive --level=1 --page-requisites --convert-links --adjust-extension \
    --no-host-directories --cut-dirs=1 --domains=orteil.dashnet.org \
    --directory-prefix="$ROOT_DIR" --input-file="$page_links.all"
  rm -f "$page_links.all"
}

rm -rf "$ROOT_DIR/img" "$ROOT_DIR/loc" "$ROOT_DIR/snd"
mkdir -p "$ROOT_DIR/img" "$ROOT_DIR/loc" "$ROOT_DIR/snd"

while IFS= read -r file; do
  [ -n "$file" ] && rm -f "$ROOT_DIR/$file"
done < "$ROOT_DIR/_jslist.txt"

cd "$ROOT_DIR/img"
wget --user-agent="$USER_AGENT" --convert-links -O index.html "$BASE_URL/img/"
grep -v PARENTDIR index.html | grep '\[IMG' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _imglist.txt
download_list _imglist.txt "$BASE_URL/img/" -N

cd "$ROOT_DIR/snd"
wget --user-agent="$USER_AGENT" --convert-links -O index.html "$BASE_URL/snd/"
grep -v PARENTDIR index.html | grep '\[SND' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _sndlist.txt
download_list _sndlist.txt "$BASE_URL/snd/" -N

cd "$ROOT_DIR/loc"
wget --user-agent="$USER_AGENT" --convert-links -O index.html "$BASE_URL/loc/"
grep -v PARENTDIR index.html | grep '\[TXT' | grep -Po 'a href="\K.*?(?=")' | sed 's/\?.*//' > _loclist.txt
download_list _loclist.txt "$BASE_URL/loc/"

cd "$ROOT_DIR"
wget --user-agent="$USER_AGENT" -O index.html "$BASE_URL/"
download_html_pages
wget --user-agent="$USER_AGENT" -O style.css "$BASE_URL/style.css"
download_list _jslist.txt "$BASE_URL/"
wget --user-agent="$USER_AGENT" -O grab.txt http://orteil.dashnet.org/patreon/grab.php

grep -Po 'url\(\K/cf-fonts/[^)]+' index.html > _fontlist.txt
download_list _fontlist.txt http://orteil.dashnet.org -x -nH -N

sed -i 's|url(/cf-fonts/|url(cf-fonts/|g' index.html
sed -i "s|DataDir=window.location.origin+'/data/';|DataDir='https://orteil.dashnet.org/data/';|g" main.js

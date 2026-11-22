#!/bin/sh
# Buduje gotową stronę do publikacji (folder dist) z pliku index.html.
set -e
mkdir -p dist
{
  printf '<!doctype html>\n<html lang="pl">\n<head>\n<meta charset="utf-8">\n'
  printf '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n'
  printf '<meta name="robots" content="noindex, nofollow">\n'
  printf '<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0;font-size:14px}img{max-width:100%%}[hidden]{display:none!important}</style>\n'
  printf '</head>\n<body>\n'
  cat index.html
  printf '\n<form name="wyslana-ankieta" method="POST" data-netlify="true" netlify-honeypot="bot-field" hidden>\n'
  printf '<input name="Klient"><input name="Wysłano"><input name="Panel"><input name="bot-field">\n</form>\n'
  printf '\n</body>\n</html>\n'
} > dist/index.html

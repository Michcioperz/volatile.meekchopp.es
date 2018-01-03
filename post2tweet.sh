#!/bin/bash
source config.sh
python3 html2txt.py $1
echo
echo "$WEBSITE_ROOT${1%.markdown}.html"

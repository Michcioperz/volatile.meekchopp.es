#!/bin/bash
num=1
while [[ -f "posts/${num}.markdown" ]]; do
  (( num += 1 ))
done
$EDITOR "posts/${num}.markdown"
echo "Remember to commit if you got something done"

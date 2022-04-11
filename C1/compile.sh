#!/bin/zsh

if [[ $# != 2 ]]; then
    echo "Usage: compile.sh <path> <persona_code>"
    exit 1
fi

echo 'creating output file...'
pandoc -o $1/$2.pdf ch1.md
echo 'done'
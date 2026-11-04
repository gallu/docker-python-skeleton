#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p src
if [ -z "$(find src -mindepth 1 -print -quit)" ]; then
    cp examples/plain-wsgi/app.py src/app.py
    echo 'Created src/app.py from the Plain Python sample.'
else
    echo 'src/ is not empty; existing application files were left unchanged.'
fi

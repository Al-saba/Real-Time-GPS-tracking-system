#!/bin/bash
# server.sh - starts the Flask server
# Usage: ./server.sh

set -e

# create virtualenv and install if not exists
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  . .venv/bin/activate
  pip install --upgrade pip
  pip install flask flask-cors
else
  . .venv/bin/activate
fi

echo "Starting server on http://0.0.0.0:5000 ..."
python3 server.py

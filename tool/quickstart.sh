#!/usr/bin/env bash
set -euo pipefail

CONFIG=${1:-config.yaml}

echo "Running codegen with $CONFIG..."
dart run bin/shazam.dart build --config "$CONFIG"

echo "Running analyzer..."
dart analyze

echo "Running tests..."
dart test

echo "Quickstart complete."

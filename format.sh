#!/usr/bin/env sh

echo "Running Prettier..."
prettier --write "**/*.{md,json,yml,yaml}"

echo "Running Stylua..."
stylua ./lua/
stylua ./tests/

echo "✅ Formatting complete"

#!/bin/bash
echo "Generating code files..."
flutter pub run build_runner build --delete-conflicting-outputs
echo ""
echo "Code generation complete!"


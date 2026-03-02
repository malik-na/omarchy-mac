#!/bin/bash
# Migration to set up proper browser managed policy directories for Fedora Asahi Remix

echo "Setting up managed policy directories for browsers (Chromium, Brave, Chrome, Edge)..."

for dir in /etc/chromium/policies/managed /etc/chromium-browser/policies/managed /etc/brave/policies/managed /etc/opt/chrome/policies/managed /etc/opt/edge/policies/managed; do
  sudo mkdir -p "$dir"
  sudo chmod a+rw "$dir"
done

echo "Done setting up browser policy directories."

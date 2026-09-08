#!/bin/bash
# My example bash script
echo "-------- Renaming original Podfile..."
mv podfile podfile.temp
echo "-------- Creating empty Podfile..."
pod init
echo "-------- Removing all pods..."
pod install
echo "-------- Deleting empty Podfile..."
rm podfile
echo "-------- Restoring original Podfile..."
mv podfile.temp podfile
echo "-------- Restoring all pods"
pod install
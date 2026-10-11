#!/bin/bash
set -e

PKG="com.local.moonreader.moon_reader_flutter"
APK="build/app/outputs/flutter-apk/app-release.apk"

echo "[1/4] Checking device connection..."
adb devices -l

echo "[2/4] Phone se purana app completely delete (uninstall) kar rahe hain..."
adb uninstall "$PKG" || true

echo "[3/4] APK ko phone ke storage me push kar rahe hain..."
adb push "$APK" /data/local/tmp/ak_clean.apk

echo "[4/4] Package manager se fresh install kar rahe hain..."
adb shell pm install -g /data/local/tmp/ak_clean.apk
adb shell rm -f /data/local/tmp/ak_clean.apk

echo "[5/5] Fresh AK Reader launch kar rahe hain..."
adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1

echo "[✓] Purana app delete hokar naya release APK successfully install ho gaya!"

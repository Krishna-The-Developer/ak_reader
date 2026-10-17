import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // 1. Android 11+ (API 30 to 36) - All Files Access
      final manageStatus = await Permission.manageExternalStorage.status;
      if (manageStatus.isGranted) return true;

      final res = await Permission.manageExternalStorage.request();
      if (res.isGranted) return true;

      // 2. Fallback check (Android 10 and below)
      final storageStatus = await Permission.storage.status;
      if (storageStatus.isGranted) return true;

      final storageRes = await Permission.storage.request();
      if (storageRes.isGranted) return true;

      // Agar user ne manually grant kiya ho settings me
      if (await Permission.manageExternalStorage.isGranted ||
          await Permission.storage.isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("Permission error: $e");
      // Fallback: Agar exception aaye toh app block na ho
      return true;
    }
  }

  static Future<bool> checkPermissionDirect() async {
    if (!Platform.isAndroid) return true;
    try {
      if (await Permission.manageExternalStorage.isGranted) return true;
      if (await Permission.storage.isGranted) return true;
      return false;
    } catch (_) {
      return true;
    }
  }
}

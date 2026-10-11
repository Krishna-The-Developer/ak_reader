import "dart:io";
import "package:flutter/foundation.dart";
import "package:permission_handler/permission_handler.dart";

class PermissionService {
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        final manageStatus = await Permission.manageExternalStorage.status;
        if (!manageStatus.isGranted) {
          final res = await Permission.manageExternalStorage.request();
          if (res.isGranted) return true;
        }
      }

      return status.isGranted;
    } catch (e) {
      debugPrint("Permission request notice: $e");
      return true;
    }
  }
}

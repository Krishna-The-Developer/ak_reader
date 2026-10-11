import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final hasPermission = await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted;
    if (hasPermission) return true;

    if (!context.mounted) return false;

    final bool? userAgreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildWoodenPermissionDialog(ctx),
    );

    if (userAgreed != true) return false;

    PermissionStatus status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    status = await Permission.storage.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isDenied) {
      if (context.mounted) {
        _showSettingsPromptDialog(context);
      }
      return false;
    }

    return status.isGranted;
  }

  static Widget _buildWoodenPermissionDialog(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E190E),
              Color(0xFF190D06),
            ],
          ),
          border: Border.all(
              color: const Color(0xFFD4A373).withAlpha(140), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x33000000),
                border:
                    Border.all(color: const Color(0xFFD4A373).withAlpha(100)),
              ),
              child: const Icon(
                Icons.folder_shared_outlined,
                color: Color(0xFFFFD59E),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Library Storage Access",
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFE0B2),
                shadows: [
                  Shadow(
                      color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "AK Reader needs access to your device storage to import, render, and annotate your books (PDF, EPUB, TXT, comics).\n\nYour personal files remain private and never leave your phone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFFD7CCC8),
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                    ),
                    child: const Text(
                      "Not Now",
                      style: TextStyle(color: Color(0xFFBCAAA4), fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(
                            color: Color(0xFFD4A373), width: 1),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      "Grant Access",
                      style: TextStyle(
                        color: Color(0xFFFFE0B2),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showSettingsPromptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF22120A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFD4A373), width: 1),
        ),
        title: const Text(
          "Permission Required",
          style: TextStyle(
              color: Color(0xFFFFE0B2), fontFamily: 'serif', fontSize: 16),
        ),
        content: const Text(
          "Storage access is disabled. Please enable it in Android Settings to open books from your device.",
          style: TextStyle(color: Color(0xFFD7CCC8), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel",
                style: TextStyle(color: Color(0xFFBCAAA4))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D6E63)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text("Open Settings",
                style: TextStyle(color: Color(0xFFFFE0B2))),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ProfileAvatarService {
  ProfileAvatarService._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndSaveGalleryAvatar({
    required String userId,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (picked == null) return null;

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory avatarDir =
    Directory(p.join(appDocDir.path, 'profile_avatars'));

    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final String ext = p.extension(picked.path).isNotEmpty
        ? p.extension(picked.path)
        : '.jpg';
    final String fileName =
        'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final String savedPath = p.join(avatarDir.path, fileName);

    final File savedFile = await File(picked.path).copy(savedPath);
    return savedFile.path;
  }

  static ImageProvider resolveAvatarProvider(
      String? avatarPath, {
        required String fallbackUrl,
      }) {
    if (avatarPath == null || avatarPath.trim().isEmpty) {
      return NetworkImage(fallbackUrl);
    }

    final trimmed = avatarPath.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    if (trimmed.startsWith('assets/')) {
      return AssetImage(trimmed);
    }

    final file = File(trimmed);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return NetworkImage(fallbackUrl);
  }
}
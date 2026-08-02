import 'dart:io';

import 'package:crypto/crypto.dart';

class ContentHashService {
  ContentHashService._();
  static final instance = ContentHashService._();

  Future<String> calculateFileHash(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }
}

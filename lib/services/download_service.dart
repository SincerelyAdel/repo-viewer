import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String?> downloadZip(
    String zipUrl,
    String repoName, {
    void Function(int received, int total)? onProgress,
  }) async {
    // Request storage permission on Android
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        final fallback = await Permission.storage.request();
        if (!fallback.isGranted) {
          throw Exception('Storage permission denied');
        }
      }
    }

    Directory saveDir;
    if (Platform.isAndroid) {
      // Save to Downloads folder
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) {
        final ext = await getExternalStorageDirectory();
        saveDir = ext ?? await getApplicationDocumentsDirectory();
      }
    } else {
      saveDir = await getApplicationDocumentsDirectory();
    }

    final fileName = '${repoName}_${DateTime.now().millisecondsSinceEpoch}.zip';
    final savePath = '${saveDir.path}/$fileName';

    await _dio.download(
      zipUrl,
      savePath,
      onReceiveProgress: onProgress,
      options: Options(
        headers: {'Accept': 'application/zip'},
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    return savePath;
  }

  Future<String> getAllCodeAsText(
    String owner,
    String repo,
    Map<String, String> files,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln('Repository: $owner/$repo');
    buffer.writeln('Generated: ${DateTime.now().toUtc()}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    for (final entry in files.entries) {
      buffer.writeln('=== ${entry.key} ===');
      buffer.writeln(entry.value);
      buffer.writeln();
    }
    return buffer.toString();
  }
}

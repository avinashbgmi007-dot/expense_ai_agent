import 'dart:io';
import 'package:file_picker/file_picker.dart';

/// Service to handle file uploads and parsing
class FileUploadService {
  /// Pick and return a file from the device
  Future<File?> pickFile({
    List<String> allowedExtensions = const ['pdf', 'csv', 'xlsx', 'xls'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowCompression: true,
        onFileLoading: (FilePickerStatus status) {
          // Handle loading state if needed
        },
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          return File(file.path!);
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Pick multiple files
  Future<List<File>> pickMultipleFiles({
    List<String> allowedExtensions = const ['pdf', 'csv', 'xlsx', 'xls'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Get file info
  Map<String, String> getFileInfo(File file) {
    final name = file.path.split('/').last;
    final extension = name.split('.').last;
    final size = file.lengthSync();

    return {
      'name': name,
      'extension': extension,
      'size': _formatFileSize(size),
      'path': file.path,
    };
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

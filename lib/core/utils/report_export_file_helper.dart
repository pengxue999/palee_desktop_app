import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../models/report_models.dart';

class ReportExportFileHelper {
  ReportExportFileHelper._();

  static Future<String?> saveExportFile(ExportReportData exportData) async {
    final filename = exportData.filename;
    final extension = _resolveExtension(filename, exportData.contentType);
    final bytes = _resolveBytes(exportData);

    final location = await getSaveLocation(
      suggestedName: filename,
      acceptedTypeGroups: [
        XTypeGroup(
          label: extension == 'xlsx' ? 'Excel Files' : 'CSV Files',
          extensions: [extension],
        ),
      ],
    );

    if (location == null) {
      return null;
    }

    var path = location.path;
    if (!path.toLowerCase().endsWith('.$extension')) {
      path += '.$extension';
    }

    final xFile = XFile.fromData(
      bytes,
      name: filename,
      mimeType: exportData.contentType,
    );
    await xFile.saveTo(path);
    return path;
  }

  static Uint8List _resolveBytes(ExportReportData exportData) {
    final contentType = exportData.contentType.toLowerCase();
    if (contentType.contains('spreadsheetml')) {
      return Uint8List.fromList(base64Decode(exportData.data));
    }

    final csvData = utf8.encode(exportData.data);
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...csvData]);
  }

  static String _resolveExtension(String filename, String contentType) {
    final lowerFileName = filename.toLowerCase();
    if (lowerFileName.endsWith('.xlsx') ||
        contentType.toLowerCase().contains('spreadsheetml')) {
      return 'xlsx';
    }
    return 'csv';
  }
}

import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'pdf_preview_pane_stub.dart'
    if (dart.library.html) 'pdf_preview_pane_web.dart'
    as preview_pane;

Widget buildPdfPreviewPane(Uint8List pdfBytes) {
  return preview_pane.buildPdfPreviewPane(pdfBytes);
}

import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

Widget buildPdfPreviewPane(Uint8List pdfBytes) {
  return _WebPdfPreviewPane(pdfBytes: pdfBytes);
}

class _WebPdfPreviewPane extends StatefulWidget {
  final Uint8List pdfBytes;

  const _WebPdfPreviewPane({required this.pdfBytes});

  @override
  State<_WebPdfPreviewPane> createState() => _WebPdfPreviewPaneState();
}

class _WebPdfPreviewPaneState extends State<_WebPdfPreviewPane> {
  List<Uint8List> _pageImages = const [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPreviewPages());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'ບໍ່ສາມາດສະແດງ preview PDF ໄດ້',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth > 900
            ? 820.0
            : constraints.maxWidth - 40;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: _pageImages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return Center(
              child: Container(
                width: pageWidth.clamp(240.0, 820.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _pageImages[index],
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadPreviewPages() async {
    try {
      final images = <Uint8List>[];

      await for (final page in Printing.raster(widget.pdfBytes, dpi: 144)) {
        images.add(await page.toPng());
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _pageImages = images;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }
}

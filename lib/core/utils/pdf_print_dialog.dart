import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../core/constants/app_colors.dart';
import 'pdf_preview_pane.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';

String _ensurePdfExtension(String path) {
  final trimmed = path.trim();
  if (trimmed.toLowerCase().endsWith('.pdf')) {
    return trimmed;
  }
  return '$trimmed.pdf';
}

typedef WordBytesLoader = Future<Uint8List> Function();

Future<void> showPdfPreviewDialog({
  required BuildContext context,
  required Uint8List pdfBytes,
  required String documentId,
  required String title,
  required String fileNamePrefix,
  WordBytesLoader? onLoadWordBytes,
}) async {
  return showDialog(
    context: context,
    useRootNavigator: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _PrintDialog(
      pdfBytes: pdfBytes,
      documentId: documentId,
      title: title,
      fileNamePrefix: fileNamePrefix,
      onLoadWordBytes: onLoadWordBytes,
    ),
  );
}

class _PrintDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final String documentId;
  final String title;
  final String fileNamePrefix;
  final WordBytesLoader? onLoadWordBytes;

  const _PrintDialog({
    required this.pdfBytes,
    required this.documentId,
    required this.title,
    required this.fileNamePrefix,
    this.onLoadWordBytes,
  });

  @override
  State<_PrintDialog> createState() => _PrintDialogState();
}

class _PrintDialogState extends State<_PrintDialog>
    with SingleTickerProviderStateMixin {
  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  bool _loadingPrinters = true;
  bool _printing = false;
  bool _savingWord = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool get _isWebMode => kIsWeb;

  bool get _showPrinterList => !_isWebMode;

  bool _isVirtualPdfPrinter(Printer printer) {
    final normalized = printer.name.toLowerCase();
    return normalized.contains('print to pdf') ||
        normalized.contains('pdf') ||
        normalized.contains('xps');
  }

  bool _isUsbPrinter(Printer printer) {
    return printer.url.toLowerCase().contains('usb');
  }

  List<Printer> _filterAvailablePrinters(List<Printer> printers) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final physicalPrinters = printers
          .where((printer) => !_isVirtualPdfPrinter(printer))
          .toList();
      final usbPrinters = physicalPrinters
          .where((printer) => _isUsbPrinter(printer) && printer.isAvailable)
          .toList();
      return usbPrinters;
    }

    return printers.where((printer) => printer.isAvailable).toList();
  }

  Printer? _pickDefaultPrinter(List<Printer> printers) {
    if (printers.isEmpty) {
      return null;
    }

    final defaultPrinter = printers.where((printer) => printer.isDefault);
    return defaultPrinter.isNotEmpty ? defaultPrinter.first : printers.first;
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
    _loadPrinters();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrinters() async {
    if (!_showPrinterList) {
      if (mounted) {
        setState(() => _loadingPrinters = false);
      }
      return;
    }

    try {
      final list = await Printing.listPrinters();
      final availablePrinters = _filterAvailablePrinters(list);
      if (mounted) {
        setState(() {
          _printers = availablePrinters;
          _selectedPrinter = _pickDefaultPrinter(availablePrinters);
          _loadingPrinters = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPrinters = false);
    }
  }

  Future<Printer?> _refreshSelectedPrinter() async {
    final list = await Printing.listPrinters();
    final availablePrinters = _filterAvailablePrinters(list);
    final activePrinter = _selectedPrinter;

    Printer? matchedPrinter;
    if (activePrinter != null) {
      for (final printer in availablePrinters) {
        if (printer.url == activePrinter.url ||
            printer.name == activePrinter.name) {
          matchedPrinter = printer;
          break;
        }
      }
    }

    matchedPrinter ??= _pickDefaultPrinter(availablePrinters);

    if (mounted) {
      setState(() {
        _printers = availablePrinters;
        _selectedPrinter = matchedPrinter;
      });
    }

    return matchedPrinter;
  }

  Future<void> _doPrint() async {
    if (_isWebMode) {
      setState(() => _printing = true);
      try {
        final printed = await Printing.layoutPdf(
          onLayout: (_) async => widget.pdfBytes,
          name: '${widget.fileNamePrefix}_${widget.documentId}',
        );

        if (!mounted) return;

        setState(() => _printing = false);

        if (!printed) {
          _showErrorSnackBar('ຍົກເລີກການພິມ.');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _printing = false);
          _showErrorSnackBar('ພິມບໍ່ສຳເລັດ: $e');
        }
      }
      return;
    }

    setState(() => _printing = true);
    try {
      final selectedPrinter = await _refreshSelectedPrinter();

      if (selectedPrinter == null) {
        if (mounted) {
          setState(() => _printing = false);
          _showErrorSnackBar(
            'ບໍ່ພົບ printer ທີ່ພ້ອມໃຊ້ງານ. ກະລຸນາເຊື່ອມຕໍ່ printer ແລ້ວລອງໃໝ່.',
          );
        }
        return;
      }

      final printed = await Printing.directPrintPdf(
        printer: selectedPrinter,
        onLayout: (_) async => widget.pdfBytes,
        name: '${widget.fileNamePrefix}_${widget.documentId}',
      );

      if (!mounted) return;

      setState(() => _printing = false);

      if (!printed) {
        _showErrorSnackBar('ຍົກເລີກການພິມ ຫຼື printer ບໍ່ພ້ອມໃຊ້ງານ.');
        return;
      }

      Navigator.of(context, rootNavigator: false).pop();
      _showSuccessSnackBar('ພິມສຳເລັດ!');
    } catch (e) {
      if (mounted) {
        setState(() => _printing = false);
        _showErrorSnackBar('ພິມບໍ່ສຳເລັດ: $e');
      }
    }
  }

  Future<void> _doSavePdf() async {
    setState(() => _printing = true);
    try {
      final fileName = '${widget.fileNamePrefix}_${widget.documentId}.pdf';

      if (kIsWeb) {
        await XFile.fromData(
          widget.pdfBytes,
          mimeType: 'application/pdf',
          name: fileName,
        ).saveTo(fileName);
      } else {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'PDF', extensions: ['pdf']),
          ],
        );

        if (location == null) {
          if (mounted) {
            setState(() => _printing = false);
          }
          return;
        }

        final savePath = _ensurePdfExtension(location.path);

        await XFile.fromData(
          widget.pdfBytes,
          mimeType: 'application/pdf',
          name: fileName,
        ).saveTo(savePath);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: false).pop();
        _showSuccessSnackBar('PDF ບັນທຶກສຳເລັດ: $fileName');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _printing = false);
        _showErrorSnackBar('ບັນທຶກບໍ່ສຳເລັດ: $e');
      }
    }
  }

  Future<void> _doSaveWord() async {
    final loader = widget.onLoadWordBytes;
    if (loader == null || _savingWord) {
      return;
    }

    setState(() => _savingWord = true);
    try {
      final wordBytes = await loader();
      final fileName = '${widget.fileNamePrefix}_${widget.documentId}.docx';
      const wordMime =
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      if (kIsWeb) {
        await XFile.fromData(
          wordBytes,
          mimeType: wordMime,
          name: fileName,
        ).saveTo(fileName);
      } else {
        final location = await getSaveLocation(
          suggestedName: fileName,
          acceptedTypeGroups: const [
            XTypeGroup(label: 'Word', extensions: ['docx']),
          ],
        );

        if (location == null) {
          if (mounted) {
            setState(() => _savingWord = false);
          }
          return;
        }

        final trimmed = location.path.trim();
        final savePath = trimmed.toLowerCase().endsWith('.docx')
            ? trimmed
            : '$trimmed.docx';

        await XFile.fromData(
          wordBytes,
          mimeType: wordMime,
          name: fileName,
        ).saveTo(savePath);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: false).pop();
        _showSuccessSnackBar('Word ບັນທຶກສຳເລັດ: $fileName');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingWord = false);
        _showErrorSnackBar('ບັນທຶກ Word ບໍ່ສຳເລັດ: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    AppToast.success(context, message);
  }

  void _showErrorSnackBar(String message) {
    AppToast.error(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 24,
          ),
          child: Container(
            width: 980,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.94,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody()),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(
              Icons.print_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _HeaderPill(
                    icon: _isWebMode
                        ? Icons.picture_as_pdf_rounded
                        : Icons.print_outlined,
                    label: _isWebMode ? 'PDF preview' : 'Connected printer',
                  ),
                  const SizedBox(width: 8),
                  _HeaderPill(
                    icon: Icons.description_outlined,
                    label: widget.documentId,
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPreviewSidePanel(),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: const BoxDecoration(
              color: ui.Color.fromARGB(255, 229, 229, 229),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _isWebMode
                      ? buildPdfPreviewPane(widget.pdfBytes)
                      : SfPdfViewer.memory(
                          widget.pdfBytes,
                          canShowPaginationDialog: true,
                          canShowScrollHead: true,
                          pageSpacing: 16,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    String? caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.55,
              color: AppColors.foreground,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 10),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSidePanel() {
    if (_isWebMode) {
      return Container(
        width: 290,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          border: Border(
            right: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              icon: Icons.picture_as_pdf_rounded,
              title: 'PDF Preview',
              description:
                  'ໃນ Web ຈະສະແດງ preview PDF ຢູ່ໃນຫນ້ານີ້ ເພື່ອໃຫ້ກວດເບິ່ງເອກະສານກ່ອນພິມ ຫຼື ບັນທຶກ.',
              caption:
                  'ປຸ່ມພິມຈະເປີດ browser print dialog ແລະ ປຸ່ມບັນທຶກຈະດາວໂຫຼດ PDF.',
            ),
          ],
        ),
      );
    }

    return Container(
      width: 290,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: _loadingPrinters
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _buildInfoCard(
                  icon: Icons.sync_rounded,
                  title: 'ກຳລັງໂຫຼດ printer',
                  description:
                      'ລະບົບກຳລັງກວດຄົ້ນລາຍຊື່ເຄື່ອງປິ້ນເຕີທີ່ເຄື່ອງກຳລັງເຊື່ອມຕໍ່ຢູ່.',
                  caption: 'ກະລຸນາລໍຖ້າສັກຄູ່.',
                ),
              ),
            )
          : _printers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _buildInfoCard(
                  icon: Icons.print_disabled_rounded,
                  title: 'ບໍ່ພົບເຄື່ອງປິ້ນເຕີ USB',
                  description:
                      'ກະລຸນາເຊື່ອມຕໍ່ເຄື່ອງປິ້ນເຕີຜ່ານ USB ກ່ອນ ຈຶ່ງຈະສາມາດເລືອກພິມໄດ້.',
                  caption:
                      'ເມື່ອເຊື່ອມ USB ກັບ printer ແລ້ວ ລາຍການຈະສະແດງຂຶ້ນທັນທີ.',
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _printers.length,
              itemBuilder: (_, i) {
                final printer = _printers[i];
                final selected = _selectedPrinter?.name == printer.name;
                return _PrinterTile(
                  printer: printer,
                  selected: selected,
                  onTap: () => setState(() => _selectedPrinter = printer),
                );
              },
            ),
    );
  }

  Widget _buildFooter() {
    final canPrint = !_printing && (_isWebMode || _selectedPrinter != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                onPressed: () => Navigator.of(context).pop(),
                label: 'ຍົກເລີກ',
                variant: AppButtonVariant.danger,
              ),
              const SizedBox(width: 12),
              AppButton(
                onPressed: _printing ? null : _doSavePdf,
                label: 'ບັນທຶກ PDF',
                icon: Icons.download_rounded,
                variant: AppButtonVariant.success,
              ),
              if (widget.onLoadWordBytes != null) ...[
                const SizedBox(width: 12),
                AppButton(
                  onPressed: (_printing || _savingWord) ? null : _doSaveWord,
                  label: _savingWord ? 'ກຳລັງບັນທຶກ...' : 'ບັນທຶກ Word',
                  icon: Icons.description_rounded,
                  variant: AppButtonVariant.primary,
                  isLoading: _savingWord,
                ),
              ],
              const SizedBox(width: 12),
              AppButton(
                onPressed: canPrint ? _doPrint : null,
                label: _printing ? 'ກຳລັງພິມ...' : 'ພິມ',
                icon: Icons.print_rounded,
                variant: AppButtonVariant.primary,
                isLoading: _printing,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrinterTile extends StatelessWidget {
  final Printer printer;
  final bool selected;
  final VoidCallback onTap;

  const _PrinterTile({
    required this.printer,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF0F172A,
            ).withValues(alpha: selected ? 0.06 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.muted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    printer.isDefault
                        ? Icons.print_rounded
                        : Icons.print_outlined,
                    size: 18,
                    color: selected
                        ? AppColors.primary
                        : AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.foreground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (printer.isDefault) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: selected
                      ? AppColors.primary
                      : AppColors.mutedForeground.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

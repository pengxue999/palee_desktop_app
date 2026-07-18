import 'package:flutter/material.dart';

import '../../services/donation_service.dart';
import '../../widgets/app_toast.dart';
import 'pdf_print_dialog.dart';

final DonationService _donationService = DonationService();

Future<void> showDonationCertificatePrintDialog({
  required BuildContext context,
  required int donationId,
  VoidCallback? onPreviewReady,
}) async {
  try {
    final pdfBytes = await _donationService.getDonationCertificatePdf(
      donationId,
    );

    if (!context.mounted) {
      return;
    }

    onPreviewReady?.call();

    await showPdfPreviewDialog(
      context: context,
      pdfBytes: pdfBytes,
      documentId: donationId.toString(),
      title: 'ພິມໃບກຽດຕິຄຸນ',
      fileNamePrefix: 'donation_certificate',
      onLoadWordBytes: () =>
          _donationService.getDonationCertificateDocx(donationId),
    );
  } catch (e) {
    if (context.mounted) {
      AppToast.error(context, 'ບໍ່ສາມາດດຶງໃບກຽກຕິຄຸນຈາກ API ໄດ້: $e');
    }
  }
}

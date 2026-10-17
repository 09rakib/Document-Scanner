import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import 'scan_failure.dart';
import 'scan_output.dart';

class MlkitScannerGateway implements ScannerGateway {
  static const maxPages = 100;
  static const _availability = MethodChannel(
    'com.example.docscan/scanner_support',
  );

  @override
  Future<ScanOutput?> scan() async {
    DocumentScanner? scanner;
    try {
      final status = await _availability.invokeMethod<String>(
        'checkAvailability',
      );
      if (status == 'unsupported') {
        throw const ScanException(ScanFailure.unsupported);
      }
      if (status != 'available') {
        throw const ScanException(ScanFailure.servicesUnavailable);
      }
      scanner = DocumentScanner(
        options: DocumentScannerOptions(
          documentFormats: {DocumentFormat.jpeg, DocumentFormat.pdf},
          pageLimit: maxPages,
          mode: ScannerMode.full,
          isGalleryImport: true,
        ),
      );
      final result = await scanner.scanDocument();
      final pdf = result.pdf;
      final images = result.images;
      if (pdf == null ||
          images == null ||
          images.isEmpty ||
          pdf.pageCount != images.length) {
        throw const ScanException(ScanFailure.corruptOutput);
      }
      return ScanOutput(
        pdfPath: pdf.uri,
        images: List.unmodifiable(images),
        pageCount: pdf.pageCount,
      );
    } on PlatformException catch (error) {
      if (isCancellation(error)) return null;
      throw ScanException(classifyScannerError(error), cause: error);
    } on MissingPluginException catch (error) {
      throw ScanException(ScanFailure.unsupported, cause: error);
    } on TypeError catch (error) {
      throw ScanException(ScanFailure.corruptOutput, cause: error);
    } finally {
      if (scanner != null) {
        try {
          await scanner.close();
        } catch (_) {
          // Closing the plugin instance must not turn cancellation or a valid
          // scan into a second failure. This plugin does not delete output files.
        }
      }
    }
  }
}

bool isCancellation(PlatformException error) =>
    error.message == 'Operation cancelled' ||
    error.code.toLowerCase() == 'cancelled' ||
    error.code.toLowerCase() == 'canceled';

ScanFailure classifyScannerError(PlatformException error) {
  final text = '${error.code} ${error.message}'.toLowerCase();
  if (text.contains('permission') || text.contains('securityexception')) {
    return ScanFailure.permissionDenied;
  }
  if (text.contains('unsupported')) return ScanFailure.unsupported;
  if (text.contains('play services') ||
      text.contains('service_missing') ||
      text.contains('service_disabled')) {
    return ScanFailure.servicesUnavailable;
  }
  // Plugin 0.6.1 erases native ML Kit failure codes at scanner startup. Never
  // claim a precise cause when it only reports "Failed to start document scanner".
  return ScanFailure.scannerUnavailable;
}

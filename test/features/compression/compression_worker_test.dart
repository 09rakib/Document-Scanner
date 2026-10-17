import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:docscan/features/compression/data/compression_models.dart';
import 'package:docscan/features/compression/data/compression_worker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('docscan_compress_worker_');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  Future<File> noise(
    int width,
    int height,
    String name, {
    int? orientation,
  }) async {
    final random = Random(17);
    final bitmap = image.Image(width: width, height: height);
    for (final pixel in bitmap) {
      pixel.setRgb(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    }
    if (orientation != null) bitmap.exif.imageIfd.orientation = orientation;
    return File('${root.path}/$name.jpg')
        .writeAsBytes(image.encodeJpg(bitmap, quality: 95));
  }

  Future<CompressionResult> run(
    List<String> pages,
    CompressionChoice choice,
    String name,
  ) async {
    final folder = await Directory('${root.path}/$name').create();
    return compute(
      compressDocument,
      CompressionJob(pages: pages, directory: folder.path, choice: choice),
    );
  }

  test('presets reduce dimensions/bytes while preserving page order and orientation', () async {
    final portrait = await noise(800, 1200, 'portrait');
    final rotated = await noise(480, 320, 'rotated', orientation: 6);
    final high = await run(
      [portrait.path, rotated.path],
      CompressionChoice.high,
      'high',
    );
    final medium = await run(
      [portrait.path, rotated.path],
      CompressionChoice.medium,
      'medium',
    );
    final low = await run(
      [portrait.path, rotated.path],
      CompressionChoice.low,
      'low',
    );
    expect(low.fileSizeBytes, lessThan(medium.fileSizeBytes));
    expect(medium.fileSizeBytes, lessThan(high.fileSizeBytes));
    final first = image.JpegDecoder().startDecode(
      await File(low.pages.first).readAsBytes(),
    )!;
    final second = image.JpegDecoder().startDecode(
      await File(low.pages.last).readAsBytes(),
    )!;
    expect((first.width, first.height), (667, 1000));
    expect((second.width, second.height), (320, 480));
    final text = latin1.decode(await File(low.pdfPath).readAsBytes());
    expect(text.startsWith('%PDF-'), true);
    expect(text.contains('%%EOF'), true);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text).length, 2);
    expect(await File(low.pdfPath).length(), low.fileSizeBytes);
    expect(await portrait.exists(), true);
  });
  test(
    'target search reports an unattainable multi-page target honestly',
    () async {
      final source = await noise(64, 64, 'small_noise');
      final result = await run(
        List.filled(100, source.path),
        CompressionChoice.kb100,
        'target',
      );
      expect(result.pageCount, 100);
      expect(result.targetBytes, 100 * 1024);
      expect(result.fileSizeBytes, greaterThan(result.targetBytes!));
      expect(result.targetMet, false);
      // Only the best candidate survives; failed trials do not consume cache forever.
      expect(await Directory('${root.path}/target').list().length, 1);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
  test('a reachable target uses the complete PDF byte count', () async {
    final source = await noise(64, 96, 'reachable');
    final result = await run(
      [source.path],
      CompressionChoice.kb100,
      'reachable_target',
    );
    expect(result.targetMet, true);
    expect(await File(result.pdfPath).length(), lessThanOrEqualTo(100 * 1024));
  });
  test(
    'cancellation and unreadable/missing JPEGs return typed failures',
    () async {
      final source = await noise(32, 48, 'source');
      final folder = await Directory('${root.path}/cancelled').create();
      await File('${folder.path}/cancel').writeAsString('cancel');
      await expectLater(
        compute(
          compressDocument,
          CompressionJob(
            pages: [source.path],
            directory: folder.path,
            choice: CompressionChoice.low,
          ),
        ),
        throwsA(
          isA<CompressionException>().having(
            (e) => e.failure,
            'failure',
            CompressionFailure.cancelled,
          ),
        ),
      );
      await expectLater(
        run(['${root.path}/missing.jpg'], CompressionChoice.medium, 'missing'),
        throwsA(
          isA<CompressionException>().having(
            (e) => e.failure,
            'failure',
            CompressionFailure.missingPages,
          ),
        ),
      );
      final bad = await File('${root.path}/bad.jpg')
          .writeAsString('not a JPEG');
      await expectLater(
        run([bad.path], CompressionChoice.medium, 'bad'),
        throwsA(
          isA<CompressionException>().having(
            (e) => e.failure,
            'failure',
            CompressionFailure.corruptPage,
          ),
        ),
      );
    },
  );
}

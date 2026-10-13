import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ak_reader/services/progressive_document_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressiveDocumentController Tests', () {
    late File tempTxtFile;

    setUp(() async {
      tempTxtFile = File('${Directory.systemTemp.path}/test_sample.txt');
      await tempTxtFile.writeAsString(
        'Chapter 1\n\n'
        '${'This is sample test text for physical book pagination. ' * 50}'
        '\n\nChapter 2\n\n'
        '${'Another chapter with rich paragraph content. ' * 50}',
      );
    });

    tearDown(() async {
      if (await tempTxtFile.exists()) {
        await tempTxtFile.delete();
      }
    });

    test('Stage A: Controller initializes and discovers page count rapidly',
        () async {
      final controller = ProgressiveDocumentController(
        filePath: tempTxtFile.path,
        format: 'txt',
        maxCacheSize: 30,
      );

      await controller.initialize();
      expect(controller.isInitialized, isTrue);
      expect(controller.totalPages, greaterThanOrEqualTo(1));
    });

    test('Stage B: Immediate access returns valid page structure', () async {
      final controller = ProgressiveDocumentController(
        filePath: tempTxtFile.path,
        format: 'txt',
        maxCacheSize: 30,
      );

      await controller.initialize();
      final page = controller.getPage(0);
      expect(page.status, equals(PageStatus.ready));
      expect(page.textContent, isNotEmpty);
    });
  });
}

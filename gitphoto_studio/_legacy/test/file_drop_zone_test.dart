import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitphoto_studio/widgets/file_drop_zone.dart';
import 'dart:io';

void main() {
  group('FileDropZone Widget Tests', () {
    
    testWidgets('FileDropZone renders child correctly', (WidgetTester tester) async {
      final child = Container(color: Colors.red);
      
      await tester.pumpWidget(
        MaterialApp(
          home: FileDropZone(
            child: child,
            onFilesDropped: (_) {},
          ),
        ),
      );
      
      // Vérifie que le child est bien rendu
      expect(find.byWidget(child), findsOneWidget);
    });

    testWidgets('FileDropZone renders with custom colors', (WidgetTester tester) async {
      final child = const Text('Test');
      
      await tester.pumpWidget(
        MaterialApp(
          home: FileDropZone(
            child: child,
            onFilesDropped: (_) {},
            dropZoneColor: Colors.blue,
            dropZoneBorderColor: Colors.red,
            dropZoneBorderWidth: 4.0,
            dropZoneText: 'Custom Text',
          ),
        ),
      );
      
      expect(find.byWidget(child), findsOneWidget);
    });
  });

  group('PlatformFile Model Tests', () {
    
    test('PlatformFile creation with all properties', () {
      final platformFile = PlatformFile(
        path: '/test/path.jpg',
        name: 'test.jpg',
        size: 1024,
      );
      
      expect(platformFile.path, '/test/path.jpg');
      expect(platformFile.name, 'test.jpg');
      expect(platformFile.size, 1024);
    });

    test('PlatformFile creation with null values', () {
      final platformFile = PlatformFile();
      
      expect(platformFile.path, isNull);
      expect(platformFile.name, isNull);
      expect(platformFile.size, isNull);
    });

    test('PlatformFile with partial properties', () {
      final platformFile = PlatformFile(
        path: '/test/path.jpg',
        name: 'test.jpg',
      );
      
      expect(platformFile.path, '/test/path.jpg');
      expect(platformFile.name, 'test.jpg');
      expect(platformFile.size, isNull);
    });

    test('PlatformFile properties are final', () {
      final platformFile = PlatformFile(
        path: '/test/path.jpg',
        name: 'test.jpg',
        size: 1024,
      );
      
      // PlatformFile a des propriétés finales (immutables)
      // On vérifie que les propriétés sont bien définies
      expect(platformFile.path, '/test/path.jpg');
      expect(platformFile.name, 'test.jpg');
      expect(platformFile.size, 1024);
    });
  });

  group('File Filtering Tests', () {
    
    test('Filter valid paths from list', () {
      final paths = ['/test1.jpg', '/test2.jpg', '', null, '/test3.jpg'];
      
      final validFiles = paths
          .where((path) => path != null && path.isNotEmpty)
          .map((path) => File(path!))
          .toList();
      
      expect(validFiles.length, 3);
      expect(validFiles[0].path, '/test1.jpg');
      expect(validFiles[1].path, '/test2.jpg');
      expect(validFiles[2].path, '/test3.jpg');
    });

    test('Handle empty list', () {
      final paths = <String>[];
      final validFiles = paths
          .where((path) => path != null && path.isNotEmpty)
          .map((path) => File(path))
          .toList();
      
      expect(validFiles, isEmpty);
    });

    test('Handle list with only invalid paths', () {
      final paths = ['', null, '   '];
      final validFiles = paths
          .where((path) => path != null && path!.trim().isNotEmpty)
          .map((path) => File(path!.trim()))
          .toList();
      
      expect(validFiles, isEmpty);
    });

    test('Filter valid platform files', () {
      final platformFiles = [
        PlatformFile(path: '/test1.jpg', name: 'test1.jpg', size: 100),
        PlatformFile(path: '/test2.jpg', name: 'test2.jpg', size: 200),
        PlatformFile(path: null, name: 'invalid', size: 0),
        PlatformFile(path: '', name: 'empty', size: 0),
      ];
      
      final validFiles = platformFiles
          .where((pf) => pf.path != null && (pf.path!).isNotEmpty)
          .map((pf) => File(pf.path!))
          .toList();
      
      expect(validFiles.length, 2);
      expect(validFiles[0].path, '/test1.jpg');
      expect(validFiles[1].path, '/test2.jpg');
    });
  });
}

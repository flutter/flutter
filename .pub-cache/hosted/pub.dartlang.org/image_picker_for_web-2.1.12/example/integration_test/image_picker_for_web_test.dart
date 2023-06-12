// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';

const String expectedStringContents = 'Hello, world!';
const String otherStringContents = 'Hello again, world!';
final Uint8List bytes = utf8.encode(expectedStringContents) as Uint8List;
final Uint8List otherBytes = utf8.encode(otherStringContents) as Uint8List;
final Map<String, dynamic> options = <String, dynamic>{
  'type': 'text/plain',
  'lastModified': DateTime.utc(2017, 12, 13).millisecondsSinceEpoch,
};
final html.File textFile = html.File(<Uint8List>[bytes], 'hello.txt', options);
final html.File secondTextFile =
    html.File(<Uint8List>[otherBytes], 'secondFile.txt');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Under test...
  late ImagePickerPlugin plugin;

  setUp(() {
    plugin = ImagePickerPlugin();
  });

  testWidgets('Can select a file (Deprecated)', (WidgetTester tester) async {
    final html.FileUploadInputElement mockInput = html.FileUploadInputElement();

    final ImagePickerPluginTestOverrides overrides =
        ImagePickerPluginTestOverrides()
          ..createInputElement = ((_, __) => mockInput)
          ..getMultipleFilesFromInput = ((_) => <html.File>[textFile]);

    final ImagePickerPlugin plugin = ImagePickerPlugin(overrides: overrides);

    // Init the pick file dialog...
    final Future<PickedFile> file = plugin.pickFile();

    // Mock the browser behavior of selecting a file...
    mockInput.dispatchEvent(html.Event('change'));

    // Now the file should be available
    expect(file, completes);
    // And readable
    expect((await file).readAsBytes(), completion(isNotEmpty));
  });

  testWidgets('Can select a file', (WidgetTester tester) async {
    final html.FileUploadInputElement mockInput = html.FileUploadInputElement();

    final ImagePickerPluginTestOverrides overrides =
        ImagePickerPluginTestOverrides()
          ..createInputElement = ((_, __) => mockInput)
          ..getMultipleFilesFromInput = ((_) => <html.File>[textFile]);

    final ImagePickerPlugin plugin = ImagePickerPlugin(overrides: overrides);

    // Init the pick file dialog...
    final Future<XFile> image = plugin.getImage(source: ImageSource.camera);

    // Mock the browser behavior of selecting a file...
    mockInput.dispatchEvent(html.Event('change'));

    // Now the file should be available
    expect(image, completes);

    // And readable
    final XFile file = await image;
    expect(file.readAsBytes(), completion(isNotEmpty));
    expect(file.name, textFile.name);
    expect(file.length(), completion(textFile.size));
    expect(file.mimeType, textFile.type);
    expect(
        file.lastModified(),
        completion(
          DateTime.fromMillisecondsSinceEpoch(textFile.lastModified!),
        ));
  });

  testWidgets('Can select multiple files', (WidgetTester tester) async {
    final html.FileUploadInputElement mockInput = html.FileUploadInputElement();

    final ImagePickerPluginTestOverrides overrides =
        ImagePickerPluginTestOverrides()
          ..createInputElement = ((_, __) => mockInput)
          ..getMultipleFilesFromInput =
              ((_) => <html.File>[textFile, secondTextFile]);

    final ImagePickerPlugin plugin = ImagePickerPlugin(overrides: overrides);

    // Init the pick file dialog...
    final Future<List<XFile>> files = plugin.getMultiImage();

    // Mock the browser behavior of selecting a file...
    mockInput.dispatchEvent(html.Event('change'));

    // Now the file should be available
    expect(files, completes);

    // And readable
    expect((await files).first.readAsBytes(), completion(isNotEmpty));

    // Peek into the second file...
    final XFile secondFile = (await files).elementAt(1);
    expect(secondFile.readAsBytes(), completion(isNotEmpty));
    expect(secondFile.name, secondTextFile.name);
    expect(secondFile.length(), completion(secondTextFile.size));
  });

  // There's no good way of detecting when the user has "aborted" the selection.

  testWidgets('computeCaptureAttribute', (WidgetTester tester) async {
    expect(
      plugin.computeCaptureAttribute(ImageSource.gallery, CameraDevice.front),
      isNull,
    );
    expect(
      plugin.computeCaptureAttribute(ImageSource.gallery, CameraDevice.rear),
      isNull,
    );
    expect(
      plugin.computeCaptureAttribute(ImageSource.camera, CameraDevice.front),
      'user',
    );
    expect(
      plugin.computeCaptureAttribute(ImageSource.camera, CameraDevice.rear),
      'environment',
    );
  });

  group('createInputElement', () {
    testWidgets('accept: any, capture: null', (WidgetTester tester) async {
      final html.Element input = plugin.createInputElement('any', null);

      expect(input.attributes, containsPair('accept', 'any'));
      expect(input.attributes, isNot(contains('capture')));
      expect(input.attributes, isNot(contains('multiple')));
    });

    testWidgets('accept: any, capture: something', (WidgetTester tester) async {
      final html.Element input = plugin.createInputElement('any', 'something');

      expect(input.attributes, containsPair('accept', 'any'));
      expect(input.attributes, containsPair('capture', 'something'));
      expect(input.attributes, isNot(contains('multiple')));
    });

    testWidgets('accept: any, capture: null, multi: true',
        (WidgetTester tester) async {
      final html.Element input =
          plugin.createInputElement('any', null, multiple: true);

      expect(input.attributes, containsPair('accept', 'any'));
      expect(input.attributes, isNot(contains('capture')));
      expect(input.attributes, contains('multiple'));
    });

    testWidgets('accept: any, capture: something, multi: true',
        (WidgetTester tester) async {
      final html.Element input =
          plugin.createInputElement('any', 'something', multiple: true);

      expect(input.attributes, containsPair('accept', 'any'));
      expect(input.attributes, containsPair('capture', 'something'));
      expect(input.attributes, contains('multiple'));
    });
  });
}

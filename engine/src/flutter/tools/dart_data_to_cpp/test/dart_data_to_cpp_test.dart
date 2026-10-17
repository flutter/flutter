// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dart_data_to_cpp/dart_data_to_cpp.dart';
import 'package:engine_repo_tools/engine_repo_tools.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

const String _preamble = '''
import 'dart:ffi';

extension type const _NativeData._(String symbol) {
  const _NativeData({required this.symbol});
}

extension type const _NativeType<DartT, NativeT extends NativeType>._unconstructable(DartT value) {}

extension type const _NativeBool(bool value) implements _NativeType<bool, Bool> {}

extension type const _NativeInt32(int value) implements _NativeType<int, Int32> {}

extension type const _NativeDouble(double value) implements _NativeType<double, Double> {}

extension type const _NativeHandle<DartT extends Object>(DartT value)
    implements _NativeType<DartT, Handle> {}

extension type const _NativeEnum<T extends Enum>(T value)
    implements _NativeType<T, NativeType> {}
''';

void main() {
  final String flutterRoot = Engine.findWithin().flutterDir.path;

  Future<LibraryElement> resolveSource(String source) async {
    final overlay = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
    final String virtualPath = path.join(
      flutterRoot,
      'tools',
      'dart_data_to_cpp',
      'test',
      '_virtual_input.dart',
    );
    overlay.setOverlay(virtualPath, content: '$_preamble\n$source', modificationStamp: 0);
    final SomeResolvedUnitResult result = await resolveFile(
      path: virtualPath,
      resourceProvider: overlay,
    );
    return (result as ResolvedUnitResult).libraryElement;
  }

  test('parses @_NativeData constructor fields and generates C++ and Dart code', () async {
    final LibraryElement library = await resolveSource('''
enum SampleAlign { left, right, center }

extension type const _NativeColor(int value) implements _NativeType<int, Uint32> {
  int encode() => value;
  static int decode(int raw) => raw;
}

const double _kDefaultSize = 14.0;

class SampleStyle {
  @_NativeData(symbol: 'flutter::SampleStyle')
  SampleStyle._({
    _NativeColor? color = const .new(0xFF00FF00),
    _NativeDouble? fontSize = const .new(_kDefaultSize),
    _NativeEnum<SampleAlign>? textAlign = const .new(SampleAlign.center),
    this._fontFamily,
    this._fontFamilyFallback,
  });

  final _NativeHandle<String>? _fontFamily;
  final _NativeHandle<List<String>>? _fontFamilyFallback;
}
''');

    final List<NativeData> definitions = NativeData.parseLibrary(library);
    expect(definitions, hasLength(1));

    final NativeData definition = definitions.single;
    expect(definition.typeName, 'SampleStyle');
    expect(definition.symbol.qualifiedName, 'flutter::SampleStyle');
    expect(definition.symbol.namespace, 'flutter');
    expect(definition.symbol.name, 'SampleStyle');
    final List<NativeDataField> fields = definition.fields;
    expect(fields, hasLength(5));

    final NativeDataField colorField = fields[0];
    expect(colorField.dartName, 'color');
    expect(colorField.isPacked, isTrue);
    expect(colorField.resolvedType.primitive, FfiPrimitive.uint32);
    expect(colorField.defaultValueCode, 'const .new(0xFF00FF00)');

    final NativeDataField fontSizeField = fields[1];
    expect(fontSizeField.dartName, 'fontSize');
    expect(fontSizeField.isPacked, isTrue);
    expect(fontSizeField.resolvedType.primitive, FfiPrimitive.doublePrecision);
    expect(fontSizeField.defaultValueCode, 'const .new(_kDefaultSize)');

    final NativeDataField alignField = fields[2];
    expect(alignField.dartName, 'textAlign');
    expect(alignField.isPacked, isTrue);
    expect(alignField.resolvedType.primitive, FfiPrimitive.uint8);
    expect(alignField.defaultValueCode, 'const .new(SampleAlign.center)');

    final NativeDataField fontFamilyField = fields[3];
    expect(fontFamilyField.dartName, 'fontFamily');
    expect(fontFamilyField.isPacked, isFalse);
    expect(fontFamilyField.defaultValueCode, isNull);

    final NativeDataField fallbackField = fields[4];
    expect(fallbackField.dartName, 'fontFamilyFallback');
    expect(fallbackField.isPacked, isFalse);
    expect(fallbackField.defaultValueCode, isNull);

    final String cppHeader = await generateCppHeader(
      definitions,
      headerGuard: 'FLUTTER_TEST_SAMPLE_STYLE_G_H_',
    );
    expect(cppHeader, contains('#ifndef FLUTTER_TEST_SAMPLE_STYLE_G_H_'));
    expect(cppHeader, contains('class SampleStyle {'));
    expect(cppHeader, contains('uint32_t color = {};'));
    expect(cppHeader, contains('double font_size = {};'));
    expect(cppHeader, contains('uint8_t text_align = {};'));
    expect(cppHeader, contains('Dart_Handle font_family = {};'));
    expect(cppHeader, contains('Dart_Handle font_family_fallback = {};'));
    expect(
      cppHeader,
      contains('bool has_font_family() const { return (present_mask & (1u << 3)) != 0; }'),
    );

    final String dartCode = await generateDartEncoders(
      definitions,
      partOfFile: '_virtual_input.dart',
    );
    expect(dartCode, contains("part of '_virtual_input.dart';"));
    expect(dartCode, contains('final class _PackedSampleStyle extends Struct {'));
    expect(
      dartCode,
      contains(
        'int? get color => (_presentMask & (1 << 0)) == 0 ? null : _NativeColor.decode(_color);',
      ),
    );
    expect(
      dartCode,
      contains('double? get fontSize => (_presentMask & (1 << 1)) == 0 ? null : _fontSize;'),
    );
    expect(dartCode, contains('SampleAlign.values[_textAlign]'));
    expect(dartCode, contains('bool operator ==(Object other)'));
    expect(dartCode, contains('int get hashCode =>'));
    expect(
      dartCode,
      contains('extension type const _EncodedSampleStyle(List<Object?> _data) implements Object {'),
    );
    expect(dartCode, contains('_EncodedSampleStyle _encodeSampleStyleFfi({'));
    expect(dartCode, contains('color = const .new(0xFF00FF00);'));
    expect(dartCode, contains('fontSize = const .new(_kDefaultSize);'));
    expect(dartCode, contains('textAlign = const .new(SampleAlign.center);'));
  });

  test('validates missing default value on primitive field', () async {
    final LibraryElement library = await resolveSource('''
class InvalidStyle {
  @_NativeData(symbol: 'flutter::InvalidStyle')
  InvalidStyle._({
    _NativeInt32? count,
  });
}
''');
    expect(() => NativeData.parseLibrary(library), throwsA(isA<AssertionError>()));
  });

  test('supports non-nullable parameters without allocating present_mask bits', () async {
    final LibraryElement library = await resolveSource('''
extension type const _NativeColor(int value) implements _NativeType<int, Uint32> {
  int encode() => value;
  static int decode(int raw) => raw;
}

class NonNullableColorStyle {
  @_NativeData(symbol: 'flutter::NonNullableColorStyle')
  NonNullableColorStyle._({
    required _NativeColor color,
    _NativeDouble? fontSize = const .new(12.0),
    required this._fontFamily,
  });

  final _NativeHandle<String> _fontFamily;
}
''');

    final List<NativeData> definitions = NativeData.parseLibrary(library);
    expect(definitions, hasLength(1));

    final NativeData definition = definitions.single;
    final [
      NativeDataField colorField,
      NativeDataField fontSizeField,
      NativeDataField fontFamilyField,
    ] = definition.fields;

    expect(colorField.dartName, 'color');
    expect(colorField.isNullable, isFalse);
    expect(colorField.bitIndex, isNull);
    expect(colorField.defaultValueCode, isNull);

    expect(fontSizeField.dartName, 'fontSize');
    expect(fontSizeField.isNullable, isTrue);
    expect(fontSizeField.bitIndex, 0);

    expect(fontFamilyField.dartName, 'fontFamily');
    expect(fontFamilyField.isNullable, isFalse);
    expect(fontFamilyField.bitIndex, isNull);

    final String cppHeader = await generateCppHeader(
      definitions,
      headerGuard: 'FLUTTER_TEST_NON_NULLABLE_COLOR_STYLE_G_H_',
    );
    expect(cppHeader, isNot(contains('has_color')));
    expect(
      cppHeader,
      contains('bool has_font_size() const { return (present_mask & (1u << 0)) != 0; }'),
    );
    expect(cppHeader, isNot(contains('has_font_family')));
    expect(cppHeader, contains('Dart_ListGetRange(handle, 1, 2, handles);'));
    expect(cppHeader, contains('result.font_family = handles[1];'));

    final String dartCode = await generateDartEncoders(
      definitions,
      partOfFile: '_virtual_input.dart',
    );
    expect(dartCode, contains('required _NativeColor color,'));
    expect(dartCode, contains('  packed._color = color.encode();'));
    expect(dartCode, contains('int get color => _NativeColor.decode(_color);'));
    expect(
      dartCode,
      contains('double? get fontSize => (_presentMask & (1 << 0)) == 0 ? null : _fontSize;'),
    );
  });

  test('validates missing static decode() on primitive encoder', () async {
    final LibraryElement library = await resolveSource('''
extension type const _BadEncoder(int value) implements _NativeType<int, Uint32> {
  int encode() => value;
}

class InvalidStyle {
  @_NativeData(symbol: 'flutter::InvalidStyle')
  InvalidStyle._({
    _BadEncoder? field = const .new(0),
  });
}
''');
    expect(
      () => NativeData.parseLibrary(library),
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.message,
          'message',
          contains(
            "Primitive _BadEncoder's must define a decode() method if and only if it defines an encode method.",
          ),
        ),
      ),
    );
  });

  test('sizes present_mask dynamically based on nullable field count', () async {
    String fieldsSource(int count) =>
        <String>[for (int i = 0; i < count; i++) '    _NativeInt32? f$i = const .new(0),']
            .join('\n');

    final LibraryElement library = await resolveSource('''
class Mask8 {
  @_NativeData(symbol: 'flutter::Mask8')
  Mask8._({
${fieldsSource(8)}
  });
}

class Mask16 {
  @_NativeData(symbol: 'flutter::Mask16')
  Mask16._({
${fieldsSource(9)}
  });
}

class Mask32 {
  @_NativeData(symbol: 'flutter::Mask32')
  Mask32._({
${fieldsSource(17)}
  });
}

class Mask64 {
  @_NativeData(symbol: 'flutter::Mask64')
  Mask64._({
${fieldsSource(33)}
  });
}
''');

    final [NativeData mask8, NativeData mask16, NativeData mask32, NativeData mask64] =
        NativeData.parseLibrary(library);

    expect(
      mask8.packedFields
          .singleWhere((NativeDataField f) => f.dartName == 'presentMask')
          .resolvedType
          .primitive,
      FfiPrimitive.uint8,
    );
    expect(
      mask16.packedFields
          .singleWhere((NativeDataField f) => f.dartName == 'presentMask')
          .resolvedType
          .primitive,
      FfiPrimitive.uint16,
    );
    expect(
      mask32.packedFields
          .singleWhere((NativeDataField f) => f.dartName == 'presentMask')
          .resolvedType
          .primitive,
      FfiPrimitive.uint32,
    );
    expect(
      mask64.packedFields
          .singleWhere((NativeDataField f) => f.dartName == 'presentMask')
          .resolvedType
          .primitive,
      FfiPrimitive.uint64,
    );

    final String cpp64 = await generateCppHeader(<NativeData>[
      mask64,
    ], headerGuard: 'FLUTTER_TEST_MASK64_G_H_');
    expect(cpp64, contains('uint64_t present_mask = {};'));
    expect(cpp64, contains('bool has_f31() const { return (present_mask & (1u << 31)) != 0; }'));
    expect(cpp64, contains('bool has_f32() const { return (present_mask & (1ull << 32)) != 0; }'));
  });

  test(
    'generated text_styles.g.h and text_styles.g.dart are up to date with lib/ui/text.dart',
    () async {
      final String inputPath = path.join(flutterRoot, 'lib', 'ui', 'text.dart');
      final String cppPath = path.join(flutterRoot, 'lib', 'ui', 'text', 'text_styles.g.h');
      final String dartPath = path.join(flutterRoot, 'lib', 'ui', 'text_styles.g.dart');

      final SomeResolvedUnitResult result = await resolveFile(path: inputPath);
      expect(result, isA<ResolvedUnitResult>());
      final LibraryElement library = (result as ResolvedUnitResult).libraryElement;
      final Iterable<NativeData> definitions = NativeData.parseLibrary(library);

      expect(
        await generateCppHeader(definitions, headerGuard: 'FLUTTER_LIB_UI_TEXT_TEXT_STYLES_G_H_'),
        File(cppPath).readAsStringSync(),
      );
      expect(
        await generateDartEncoders(
          definitions,
          partOfFile: library.firstFragment.source.shortName,
          libraryName: library.name,
        ),
        File(dartPath).readAsStringSync(),
      );
    },
  );
}

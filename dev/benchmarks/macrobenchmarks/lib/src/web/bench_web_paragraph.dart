// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:web/web.dart' as web;

import 'recorder.dart';

const List<(String, String)> _kBenchmarkFonts = <(String, String)>[
  (
    'Roboto',
    'assets/packages/flutter_gallery_assets/fonts/google_fonts/RobotoCondensed-Regular.ttf',
  ),
  (
    'Merriweather',
    'assets/packages/flutter_gallery_assets/fonts/google_fonts/Merriweather-Regular.ttf',
  ),
  (
    'RobotoMono',
    'assets/packages/flutter_gallery_assets/fonts/google_fonts/RobotoMono-Regular.ttf',
  ),
  ('Rubik', 'assets/packages/flutter_gallery_assets/fonts/google_fonts/Rubik-Regular.ttf'),
  ('Eczar', 'assets/packages/flutter_gallery_assets/fonts/google_fonts/Eczar-Regular.ttf'),
];

bool _fontsLoaded = false;

Future<void> _ensureBenchmarkFontsLoaded() async {
  if (_fontsLoaded) {
    return;
  }
  for (final (String family, String assetUrl) in _kBenchmarkFonts) {
    final web.Response response = await web.window.fetch(assetUrl.toJS).toDart;
    final JSArrayBuffer buffer = await response.arrayBuffer().toDart;
    final Uint8List bytes = buffer.toDart.asUint8List();
    await ui.loadFontFromList(bytes, fontFamily: family);
  }
  await web.document.fonts.ready.toDart;
  _fontsLoaded = true;
}

bool _browserSupportsTextClusters() {
  return (web.window as JSObject).has('TextCluster');
}

/// Base class for paired `SkParagraph` and `WebParagraph` macrobenchmarks.
abstract class BenchParagraphBase extends ParagraphRecorder {
  BenchParagraphBase({required super.name, required this.useWebParagraph});

  /// Whether this benchmark instance runs with `preferWebParagraph: true`.
  final bool useWebParagraph;

  @override
  Future<void> setUpAll() async {
    await super.setUpAll();
    final urlHasWebParagraph = Uri.base.queryParameters['web_paragraph'] == 'true';
    if (useWebParagraph != urlHasWebParagraph) {
      throw StateError(
        'Benchmark "$name" expected web_paragraph=$useWebParagraph in URL, '
        'but Uri.base was ${Uri.base}.',
      );
    }
    if (useWebParagraph && !_browserSupportsTextClusters()) {
      throw StateError(
        'Benchmark "$name" requires CanvasRenderingContext2D.getTextClusters. '
        'Launch Chrome with --enable-experimental-web-platform-features.',
      );
    }
    await _ensureBenchmarkFontsLoaded();

    // Warm up one layout pass in setUpAll so any one-time font fallback checks
    // complete prior to benchmark measurement and tracing.
    final List<ui.Paragraph> warmUpParagraphs = buildParagraphs(0);
    final constraints = ui.ParagraphConstraints(width: layoutWidth);
    for (final paragraph in warmUpParagraphs) {
      paragraph.layout(constraints);
      paragraph.dispose();
    }
  }
}

/// Short UI labels typical of buttons, tab headers, menu items, pills, and
/// input placeholders. Each is 2–7 characters before the per-iteration badge
/// suffix is appended.
const List<String> _kTinyLabels = <String>[
  'OK',
  'Save',
  'Cancel',
  'Edit',
  'Done',
  'Next',
  'Back',
  'Home',
  'Inbox',
  'Sent',
  'Drafts',
  'More',
  'Help',
  'New',
  'Share',
  'Search',
  'Filter',
  'Sort',
  'All',
  'Active',
  'Beta',
  'Pro',
  'Menu',
  'Files',
  'Photos',
  'Music',
  'Chats',
  'Calls',
  'Pins',
  'Tags',
  'Notes',
  'Login',
];

/// Benchmarks 100 tiny single-line paragraphs (~5–9 chars each) per frame.
///
/// Models the dominant text workload of real app chrome: buttons, input
/// labels and placeholders, tab headers, sidebar links, menu items, and pills.
/// Per-paragraph fixed costs dominate here (paragraph construction, the first
/// `measureText` / `getTextClusters` call, and on `WebParagraph` one 2D canvas
/// rasterization + `getImageData` readback + `SkImage` upload per paragraph on
/// uncached paint, then one distinct `drawImageRect` texture per paragraph on
/// cached paint, versus a shared glyph atlas on `SkParagraph`).
///
/// Each label carries a short numeric badge suffix (e.g. `Inbox 42`) that is
/// unique within a frame and changes every iteration, so `SkParagraph`'s
/// `ParagraphCache` cannot serve repeated text from cache, matching the
/// `[$tag]` convention of the other buckets.
class BenchTextParagraphTiny extends BenchParagraphBase {
  BenchTextParagraphTiny.skParagraph() : super(name: skParagraphName, useWebParagraph: false);

  BenchTextParagraphTiny.webParagraph() : super(name: webParagraphName, useWebParagraph: true);

  static const String skParagraphName = 'text_paragraph_tiny';
  static const String webParagraphName = 'web_paragraph_tiny';

  static const int _paragraphCount = 100;
  static const int _columns = 10;

  @override
  double get layoutWidth => 120.0;

  @override
  double get relayoutWidth => 100.0;

  @override
  ui.Offset paragraphOffset(int index, ui.Offset baseOffset) {
    final int col = index % _columns;
    final int row = index ~/ _columns;
    return ui.Offset(baseOffset.dx + col * 96.0, baseOffset.dy + row * 28.0);
  }

  @override
  List<ui.Paragraph> buildParagraphs(int iteration) {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 13.0, maxLines: 1);
    final textStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13.0,
      color: const ui.Color(0xFF202124),
    );
    final paragraphs = <ui.Paragraph>[];
    for (var i = 0; i < _paragraphCount; i++) {
      final String label = _kTinyLabels[i % _kTinyLabels.length];
      // The badge shifts every iteration and differs between repeats of the
      // same label within a frame, so no two paragraphs in consecutive frames
      // share text.
      final int badge = (iteration + 25 * (i ~/ _kTinyLabels.length)) % 100;
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText('$label $badge');
      paragraphs.add(builder.build());
    }
    return paragraphs;
  }
}

/// Benchmarks 50 short single-line paragraphs (~36 chars each) per frame.
///
/// Exercises per-paragraph construction overhead, single-line layout, and
/// high-frequency draw calls (50 separate 2D canvas rasterizations and
/// `SkImage` uploads on uncached `WebParagraph` vs. 50 cached `drawImageRect`
/// quads on cached `WebParagraph` vs. `SkParagraph` glyph runs).
class BenchTextParagraphSmall extends BenchParagraphBase {
  BenchTextParagraphSmall.skParagraph() : super(name: skParagraphName, useWebParagraph: false);

  BenchTextParagraphSmall.webParagraph() : super(name: webParagraphName, useWebParagraph: true);

  static const String skParagraphName = 'text_paragraph_small';
  static const String webParagraphName = 'web_paragraph_small';

  static const int _paragraphCount = 50;

  @override
  double get layoutWidth => 450.0;

  @override
  double get relayoutWidth => 400.0;

  @override
  ui.Offset paragraphOffset(int index, ui.Offset baseOffset) {
    final int col = index & 1;
    final int row = index ~/ 2;
    return ui.Offset(baseOffset.dx + col * 480.0, baseOffset.dy + row * 34.0);
  }

  @override
  List<ui.Paragraph> buildParagraphs(int iteration) {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 14.0, maxLines: 1);
    final textStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14.0,
      color: const ui.Color(0xFF202124),
    );
    final paragraphs = <ui.Paragraph>[];
    final int tag = iteration % 1000;
    for (var i = 0; i < _paragraphCount; i++) {
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText('Item #${i + 100} [$tag]: Quick brown fox jumps');
      paragraphs.add(builder.build());
    }
    return paragraphs;
  }
}

/// Benchmarks 10 medium multi-line paragraphs (~260 chars each, ~5 lines) per frame.
///
/// Exercises cluster extraction, line breaking (`TextWrapper`), line formatting,
/// and medium-sized paragraph rasterization.
class BenchTextParagraphMedium extends BenchParagraphBase {
  BenchTextParagraphMedium.skParagraph() : super(name: skParagraphName, useWebParagraph: false);

  BenchTextParagraphMedium.webParagraph() : super(name: webParagraphName, useWebParagraph: true);

  static const String skParagraphName = 'text_paragraph_medium';
  static const String webParagraphName = 'web_paragraph_medium';

  static const int _paragraphCount = 10;

  static const String _baseParagraphText =
      'Flutter Web renders rich typography by breaking paragraphs into lines, '
      'measuring glyph clusters, and rasterizing text runs onto the target '
      'surface. Tracking build, layout, and paint timings isolates bottlenecks '
      'across engines.';

  @override
  double get layoutWidth => 450.0;

  @override
  double get relayoutWidth => 380.0;

  @override
  ui.Offset paragraphOffset(int index, ui.Offset baseOffset) {
    final int col = index & 1;
    final int row = index ~/ 2;
    return ui.Offset(baseOffset.dx + col * 480.0, baseOffset.dy + row * 170.0);
  }

  @override
  List<ui.Paragraph> buildParagraphs(int iteration) {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 14.0);
    final textStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14.0,
      color: const ui.Color(0xFF202124),
    );
    final paragraphs = <ui.Paragraph>[];
    final int tag = iteration % 1000;
    for (var i = 0; i < _paragraphCount; i++) {
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText('Section ${i + 1} ($tag): $_baseParagraphText');
      paragraphs.add(builder.build());
    }
    return paragraphs;
  }
}

/// Benchmarks 1 large multi-line paragraph (~2,500 chars, ~22 lines) per frame.
///
/// Models the large-paragraph workload from https://github.com/flutter/flutter/issues/188325,
/// stressing `AllCodeUnitFlags`, large-span `getTextClusters`, multi-line wrapping,
/// and full-paragraph 2D canvas rasterization + `getImageData` + `MakeImage`.
class BenchTextParagraphLarge extends BenchParagraphBase {
  BenchTextParagraphLarge.skParagraph() : super(name: skParagraphName, useWebParagraph: false);

  BenchTextParagraphLarge.webParagraph() : super(name: webParagraphName, useWebParagraph: true);

  static const String skParagraphName = 'text_paragraph_large';
  static const String webParagraphName = 'web_paragraph_large';

  static final String _largeBlock = List<String>.generate(
    10,
    (int index) =>
        'Paragraph segment ${index + 1}: Modern web applications demand low-latency '
        'text layout and rasterization even when rendering dense documentation pages, '
        'code editors, or long-form articles containing thousands of characters in a '
        'single paragraph block without dropping frames.',
  ).join(' ');

  @override
  double get layoutWidth => 900.0;

  @override
  double get relayoutWidth => 780.0;

  @override
  ui.Offset paragraphOffset(int index, ui.Offset baseOffset) => baseOffset;

  @override
  List<ui.Paragraph> buildParagraphs(int iteration) {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 12.0);
    final textStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 12.0,
      color: const ui.Color(0xFF202124),
    );
    final int tag = iteration % 1000;
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText('[$tag] $_largeBlock');
    return <ui.Paragraph>[builder.build()];
  }
}

/// Benchmarks 10 rich-text paragraphs (~250 chars each, 8 styled spans per paragraph).
///
/// Exercises multi-span style resolution, multiple font families (`Roboto`,
/// `Merriweather`, `RobotoMono`), font weights/italics, background fills,
/// text decorations (underline, lineThrough, wavy), letterSpacing, and shadows.
class BenchTextParagraphRich extends BenchParagraphBase {
  BenchTextParagraphRich.skParagraph() : super(name: skParagraphName, useWebParagraph: false);

  BenchTextParagraphRich.webParagraph() : super(name: webParagraphName, useWebParagraph: true);

  static const String skParagraphName = 'text_paragraph_rich';
  static const String webParagraphName = 'web_paragraph_rich';

  static const int _paragraphCount = 10;

  @override
  double get layoutWidth => 450.0;

  @override
  double get relayoutWidth => 380.0;

  @override
  ui.Offset paragraphOffset(int index, ui.Offset baseOffset) {
    final int col = index & 1;
    final int row = index ~/ 2;
    return ui.Offset(baseOffset.dx + col * 480.0, baseOffset.dy + row * 170.0);
  }

  @override
  List<ui.Paragraph> buildParagraphs(int iteration) {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 13.0);
    final boldHeaderStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14.0,
      fontWeight: ui.FontWeight.w700,
      color: const ui.Color(0xFF1A73E8),
    );
    final bodyStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13.0,
      color: const ui.Color(0xFF202124),
    );
    final italicSerifStyle = ui.TextStyle(
      fontFamily: 'Merriweather',
      fontSize: 13.0,
      fontStyle: ui.FontStyle.italic,
      color: const ui.Color(0xFF8C1D40),
    );
    final codeStyle = ui.TextStyle(
      fontFamily: 'RobotoMono',
      fontSize: 12.0,
      color: const ui.Color(0xFF0D652D),
      background: ui.Paint()..color = const ui.Color(0xFFE6F4EA),
    );
    final linkStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13.0,
      color: const ui.Color(0xFF1967D2),
      decoration: ui.TextDecoration.underline,
      decorationStyle: ui.TextDecorationStyle.solid,
      decorationColor: const ui.Color(0xFF1967D2),
      letterSpacing: 0.4,
    );
    final strikeStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13.0,
      color: const ui.Color(0xFF5F6368),
      decoration: ui.TextDecoration.lineThrough,
      decorationColor: const ui.Color(0xFFD93025),
    );
    final wavyStyle = ui.TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13.0,
      color: const ui.Color(0xFFB06000),
      decoration: ui.TextDecoration.underline,
      decorationStyle: ui.TextDecorationStyle.wavy,
      decorationColor: const ui.Color(0xFFEA8600),
      decorationThickness: 1.5,
    );
    final shadowStyle = ui.TextStyle(
      fontFamily: 'Merriweather',
      fontSize: 13.0,
      fontWeight: ui.FontWeight.w700,
      color: const ui.Color(0xFF3C4043),
      shadows: const <ui.Shadow>[
        ui.Shadow(color: ui.Color(0x66000000), offset: ui.Offset(1.0, 1.0), blurRadius: 2.0),
      ],
    );

    final paragraphs = <ui.Paragraph>[];
    final int tag = iteration % 1000;
    for (var i = 0; i < _paragraphCount; i++) {
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(boldHeaderStyle)
        ..addText('Card #${i + 1} [$tag]: ')
        ..pop()
        ..pushStyle(bodyStyle)
        ..addText('Rich text combines ')
        ..pop()
        ..pushStyle(italicSerifStyle)
        ..addText('serif italics, ')
        ..pop()
        ..pushStyle(codeStyle)
        ..addText('inline_code()')
        ..pop()
        ..pushStyle(bodyStyle)
        ..addText(', ')
        ..pop()
        ..pushStyle(linkStyle)
        ..addText('hyperlinks')
        ..pop()
        ..pushStyle(bodyStyle)
        ..addText(', ')
        ..pop()
        ..pushStyle(strikeStyle)
        ..addText('deprecated values')
        ..pop()
        ..pushStyle(bodyStyle)
        ..addText(', ')
        ..pop()
        ..pushStyle(wavyStyle)
        ..addText('diagnostics')
        ..pop()
        ..pushStyle(bodyStyle)
        ..addText(', and ')
        ..pop()
        ..pushStyle(shadowStyle)
        ..addText('drop shadows in a single paragraph.')
        ..pop();
      paragraphs.add(builder.build());
    }
    return paragraphs;
  }
}

/// Benchmarks 10 bidirectional and multi-script international paragraphs per frame.
///
/// Exercises ICU4X/Client-ICU Bidi region extraction (`Bidi.getBidiRegions`),
/// visual run reordering across mixed LTR/RTL segments, grapheme/word/line
/// boundary flags (`AllCodeUnitFlags`), and multi-script shaping across Latin,
/// Hebrew (with niqqud), Devanagari (conjuncts and combining marks), and
/// Cyrillic clusters covered by the bundled `Rubik` and `Eczar` fonts.
class BenchTextParagraphBidi extends BenchParagraphBase {
  BenchTextParagraphBidi.skParagraph() : super(name: skParagraphName, useWebParagraph: false);

  BenchTextParagraphBidi.webParagraph() : super(name: webParagraphName, useWebParagraph: true);

  static const String skParagraphName = 'text_paragraph_bidi';
  static const String webParagraphName = 'web_paragraph_bidi';

  static const int _paragraphCount = 10;

  @override
  double get layoutWidth => 450.0;

  @override
  double get relayoutWidth => 380.0;

  @override
  ui.Offset paragraphOffset(int index, ui.Offset baseOffset) {
    final int col = index & 1;
    final int row = index ~/ 2;
    return ui.Offset(baseOffset.dx + col * 480.0, baseOffset.dy + row * 170.0);
  }

  @override
  List<ui.Paragraph> buildParagraphs(int iteration) {
    final paragraphStyle = ui.ParagraphStyle(
      fontFamily: 'Rubik',
      fontSize: 13.0,
      textDirection: ui.TextDirection.ltr,
    );
    final textStyle = ui.TextStyle(
      fontFamily: 'Rubik',
      fontFamilyFallback: const <String>['Eczar', 'Roboto'],
      fontSize: 13.0,
      color: const ui.Color(0xFF202124),
    );
    final paragraphs = <ui.Paragraph>[];
    final int tag = iteration % 1000;
    for (var i = 0; i < _paragraphCount; i++) {
      final builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(
          'Order #${i + 100} [$tag] — '
          'עברית: שָׁלוֹם עוֹלָם וּבְרוּכִים הַבָּאִים (RTL 123) | '
          'हिन्दी: नमस्ते दुनिया प्रदर्शन परीक्षण | '
          'Русский: Привет мир (LTR 456) | '
          'בְּדִיקַת בִּיצוּעִים דּוּ-כִּיוּוּנִית מְשֻׁלֶּבֶת (789)',
        );
      paragraphs.add(builder.build());
    }
    return paragraphs;
  }
}

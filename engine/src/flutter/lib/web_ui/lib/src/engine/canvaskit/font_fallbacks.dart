// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/src/engine/canvaskit/renderer.dart';

import '../dom.dart';
import '../font_change_util.dart';
import '../initialization.dart';
import '../renderer.dart';
import '../util.dart';
import 'canvaskit_api.dart';
import 'font_fallback_data.dart';
import 'fonts.dart';
import 'interval_tree.dart';
import 'noto_font.dart';

/// Global static font fallback data.
class FontFallbackData {
  static FontFallbackData get instance => _instance;
  static FontFallbackData _instance = FontFallbackData();

  /// Resets the fallback font data.
  ///
  /// After calling this method fallback fonts will be loaded from scratch.
  ///
  /// Used for tests.
  static void debugReset() {
    _instance = FontFallbackData();
    notoDownloadQueue = FallbackFontDownloadQueue();
  }

  /// Code units that no known font has a glyph for.
  final Set<int> codeUnitsWithNoKnownFont = <int>{};

  /// Code units which are known to be covered by at least one fallback font.
  final Set<int> knownCoveredCodeUnits = <int>{};

  /// Index of all font families by code unit range.
  final IntervalTree<NotoFont> notoTree = createNotoFontTree();

  static IntervalTree<NotoFont> createNotoFontTree() {
    final Map<NotoFont, List<CodeunitRange>> ranges =
        <NotoFont, List<CodeunitRange>>{};

    for (final NotoFont font in fallbackFonts) {
      // ignore: prefer_foreach
      for (final CodeunitRange range in font.computeUnicodeRanges()) {
        ranges.putIfAbsent(font, () => <CodeunitRange>[]).add(range);
      }
    }

    return IntervalTree<NotoFont>.createFromRanges(ranges);
  }

  /// Fallback fonts which have been registered and loaded.
  final List<RegisteredFont> registeredFallbackFonts = <RegisteredFont>[];

  final List<String> globalFontFallbacks = <String>['Roboto'];

  /// A list of code units to check against the global fallback fonts.
  final Set<int> _codeUnitsToCheckAgainstFallbackFonts = <int>{};

  /// This is [true] if we have scheduled a check for missing code units.
  ///
  /// We only do this once a frame, since checking if a font supports certain
  /// code units is very expensive.
  bool _scheduledCodeUnitCheck = false;

  /// Determines if the given [text] contains any code points which are not
  /// supported by the current set of fonts.
  void ensureFontsSupportText(String text, List<String> fontFamilies) {
    // TODO(hterkelsen): Make this faster for the common case where the text
    // is supported by the given fonts.
    if (debugDisableFontFallbacks) {
      return;
    }

    // If the text is ASCII, then skip this check.
    bool isAscii = true;
    for (int i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) >= 160) {
        isAscii = false;
        break;
      }
    }
    if (isAscii) {
      return;
    }

    // We have a cache of code units which are known to be covered by at least
    // one of our fallback fonts, and a cache of code units which are known not
    // to be covered by any fallback font. From the given text, construct a set
    // of code units which need to be checked.
    final Set<int> runesToCheck = <int>{};
    for (final int rune in text.runes) {
      // Filter out code units which ASCII, known to be covered, or known not
      // to be covered.
      if (!(rune < 160 ||
          knownCoveredCodeUnits.contains(rune) ||
          codeUnitsWithNoKnownFont.contains(rune))) {
        runesToCheck.add(rune);
      }
    }
    if (runesToCheck.isEmpty) {
      return;
    }

    final List<int> codeUnits = runesToCheck.toList();

    final List<SkFont> fonts = <SkFont>[];
    for (final String font in fontFamilies) {
      final List<SkFont>? typefacesForFamily =
        CanvasKitRenderer.instance.fontCollection.familyToFontMap[font];
      if (typefacesForFamily != null) {
        fonts.addAll(typefacesForFamily);
      }
    }
    final List<bool> codeUnitsSupported =
        List<bool>.filled(codeUnits.length, false);
    final String testString = String.fromCharCodes(codeUnits);
    for (final SkFont font in fonts) {
      final Uint16List glyphs = font.getGlyphIDs(testString);
      assert(glyphs.length == codeUnitsSupported.length);
      for (int i = 0; i < glyphs.length; i++) {
        codeUnitsSupported[i] |= glyphs[i] != 0 || _isControlCode(codeUnits[i]);
      }
    }

    if (codeUnitsSupported.any((bool x) => !x)) {
      final List<int> missingCodeUnits = <int>[];
      for (int i = 0; i < codeUnitsSupported.length; i++) {
        if (!codeUnitsSupported[i]) {
          missingCodeUnits.add(codeUnits[i]);
        }
      }
      _codeUnitsToCheckAgainstFallbackFonts.addAll(missingCodeUnits);
      if (!_scheduledCodeUnitCheck) {
        _scheduledCodeUnitCheck = true;
        CanvasKitRenderer.instance.rasterizer.addPostFrameCallback(_ensureFallbackFonts);
      }
    }
  }

  /// Returns [true] if [codepoint] is a Unicode control code.
  bool _isControlCode(int codepoint) {
    return codepoint < 32 || (codepoint > 127 && codepoint < 160);
  }

  /// Checks the missing code units against the current set of fallback fonts
  /// and starts downloading new fallback fonts if the current set can't cover
  /// the code units.
  void _ensureFallbackFonts() {
    _scheduledCodeUnitCheck = false;
    // We don't know if the remaining code units are covered by our fallback
    // fonts. Check them and update the cache.
    if (_codeUnitsToCheckAgainstFallbackFonts.isEmpty) {
      return;
    }
    final List<int> codeUnits = _codeUnitsToCheckAgainstFallbackFonts.toList();
    _codeUnitsToCheckAgainstFallbackFonts.clear();
    final List<bool> codeUnitsSupported =
        List<bool>.filled(codeUnits.length, false);
    final String testString = String.fromCharCodes(codeUnits);

    for (final String font in globalFontFallbacks) {
      final List<SkFont>? fontsForFamily =
          CanvasKitRenderer.instance.fontCollection.familyToFontMap[font];
      if (fontsForFamily == null) {
        printWarning('A fallback font was registered but we '
            'cannot retrieve the typeface for it.');
        continue;
      }
      for (final SkFont font in fontsForFamily) {
        final Uint16List glyphs = font.getGlyphIDs(testString);
        assert(glyphs.length == codeUnitsSupported.length);
        for (int i = 0; i < glyphs.length; i++) {
          final bool codeUnitSupported = glyphs[i] != 0;
          if (codeUnitSupported) {
            knownCoveredCodeUnits.add(codeUnits[i]);
          }
          codeUnitsSupported[i] |=
              codeUnitSupported || _isControlCode(codeUnits[i]);
        }
      }

      // Once we've checked every typeface for this family, check to see if
      // every code unit has been covered in order to avoid unnecessary checks.
      bool keepGoing = false;
      for (final bool supported in codeUnitsSupported) {
        if (!supported) {
          keepGoing = true;
          break;
        }
      }

      if (!keepGoing) {
        return;
      }
    }

    // If we reached here, then there are some code units which aren't covered
    // by the global fallback fonts. Remove the ones which were covered and
    // try to find fallback fonts which cover them.
    for (int i = codeUnits.length - 1; i >= 0; i--) {
      if (codeUnitsSupported[i]) {
        codeUnits.removeAt(i);
      }
    }
    findFontsForMissingCodeunits(codeUnits);
  }

  void registerFallbackFont(String family, Uint8List bytes) {
    final SkTypeface? typeface =
        canvasKit.Typeface.MakeFreeTypeFaceFromData(bytes.buffer);
    if (typeface == null) {
      printWarning('Failed to parse fallback font $family as a font.');
      return;
    }
    // Insert emoji font before all other fallback fonts so we use the emoji
    // whenever it's available.
    registeredFallbackFonts.add(RegisteredFont(bytes, family, typeface));
    // Insert emoji font before all other fallback fonts so we use the emoji
    // whenever it's available.
    if (family == 'Noto Emoji') {
      if (globalFontFallbacks.first == 'Roboto') {
        globalFontFallbacks.insert(1, family);
      } else {
        globalFontFallbacks.insert(0, family);
      }
    } else {
      globalFontFallbacks.add(family);
    }
  }
}

Future<void> findFontsForMissingCodeunits(List<int> codeUnits) async {
  final FontFallbackData data = FontFallbackData.instance;

  Set<NotoFont> fonts = <NotoFont>{};
  final Set<int> coveredCodeUnits = <int>{};
  final Set<int> missingCodeUnits = <int>{};
  for (final int codeUnit in codeUnits) {
    final List<NotoFont> fontsForUnit = data.notoTree.intersections(codeUnit);
    fonts.addAll(fontsForUnit);
    if (fontsForUnit.isNotEmpty) {
      coveredCodeUnits.add(codeUnit);
    } else {
      missingCodeUnits.add(codeUnit);
    }
  }

  // The call to `findMinimumFontsForCodeUnits` will remove all code units that
  // were matched by `fonts` from `unmatchedCodeUnits`.
  final Set<int> unmatchedCodeUnits = Set<int>.from(coveredCodeUnits);
  fonts = findMinimumFontsForCodeUnits(unmatchedCodeUnits, fonts);

  fonts.forEach(notoDownloadQueue.add);

  // We looked through the Noto font tree and didn't find any font families
  // covering some code units.
  if (missingCodeUnits.isNotEmpty || unmatchedCodeUnits.isNotEmpty) {
    if (!notoDownloadQueue.isPending) {
      printWarning('Could not find a set of Noto fonts to display all missing '
          'characters. Please add a font asset for the missing characters.'
          ' See: https://flutter.dev/docs/cookbook/design/fonts');
      data.codeUnitsWithNoKnownFont.addAll(missingCodeUnits);
    }
  }
}

/// Finds the minimum set of fonts which covers all of the [codeUnits].
///
/// Removes all code units covered by [fonts] from [codeUnits]. The code
/// units remaining in the [codeUnits] set after calling this function do not
/// have a font that covers them and can be omitted next time to avoid
/// searching for fonts unnecessarily.
///
/// Since set cover is NP-complete, we approximate using a greedy algorithm
/// which finds the font which covers the most code units. If multiple CJK
/// fonts match the same number of code units, we choose one based on the user's
/// locale.
Set<NotoFont> findMinimumFontsForCodeUnits(
    Set<int> codeUnits, Set<NotoFont> fonts) {
  assert(fonts.isNotEmpty || codeUnits.isEmpty);
  final Set<NotoFont> minimumFonts = <NotoFont>{};
  final List<NotoFont> bestFonts = <NotoFont>[];

  final String language = domWindow.navigator.language;

  while (codeUnits.isNotEmpty) {
    int maxCodeUnitsCovered = 0;
    bestFonts.clear();
    for (final NotoFont font in fonts) {
      int codeUnitsCovered = 0;
      for (final int codeUnit in codeUnits) {
        if (font.contains(codeUnit)) {
          codeUnitsCovered++;
        }
      }
      if (codeUnitsCovered > maxCodeUnitsCovered) {
        bestFonts.clear();
        bestFonts.add(font);
        maxCodeUnitsCovered = codeUnitsCovered;
      } else if (codeUnitsCovered == maxCodeUnitsCovered) {
        bestFonts.add(font);
      }
    }
    if (maxCodeUnitsCovered == 0) {
      // Fonts cannot cover remaining unmatched characters.
      break;
    }
    // If the list of best fonts are all CJK fonts, choose the best one based
    // on locale. Otherwise just choose the first font.
    NotoFont bestFont = bestFonts.first;
    if (bestFonts.length > 1) {
      if (bestFonts.every((NotoFont font) => _cjkFonts.contains(font))) {
        if (language == 'zh-Hans' ||
            language == 'zh-CN' ||
            language == 'zh-SG' ||
            language == 'zh-MY') {
          if (bestFonts.contains(_notoSansSC)) {
            bestFont = _notoSansSC;
          }
        } else if (language == 'zh-Hant' ||
            language == 'zh-TW' ||
            language == 'zh-MO') {
          if (bestFonts.contains(_notoSansTC)) {
            bestFont = _notoSansTC;
          }
        } else if (language == 'zh-HK') {
          if (bestFonts.contains(_notoSansHK)) {
            bestFont = _notoSansHK;
          }
        } else if (language == 'ja') {
          if (bestFonts.contains(_notoSansJP)) {
            bestFont = _notoSansJP;
          }
        } else if (language == 'ko') {
          if (bestFonts.contains(_notoSansKR)) {
            bestFont = _notoSansKR;
          }
        } else if (bestFonts.contains(_notoSansSC)) {
          bestFont = _notoSansSC;
        }
      } else {
        // To be predictable, if there is a tie for best font, choose a font
        // from this list first, then just choose the first font.
        if (bestFonts.contains(_notoSymbols)) {
          bestFont = _notoSymbols;
        } else if (bestFonts.contains(_notoSansSC)) {
          bestFont = _notoSansSC;
        }
      }
    }
    codeUnits.removeWhere((int codeUnit) {
      return bestFont.contains(codeUnit);
    });
    minimumFonts.add(bestFont);
  }
  return minimumFonts;
}

NotoFont _notoSansSC = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans SC');
NotoFont _notoSansTC = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans TC');
NotoFont _notoSansHK = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans HK');
NotoFont _notoSansJP = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans JP');
NotoFont _notoSansKR = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans KR');
List<NotoFont> _cjkFonts = <NotoFont>[_notoSansSC, _notoSansTC, _notoSansHK, _notoSansJP, _notoSansKR];

NotoFont _notoSymbols = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans Symbols');

class FallbackFontDownloadQueue {
  NotoDownloader downloader = NotoDownloader();

  final Set<NotoFont> downloadedFonts = <NotoFont>{};
  final Map<String, NotoFont> pendingFonts = <String, NotoFont>{};

  bool get isPending => pendingFonts.isNotEmpty || _fontsLoading != null;

  Future<void>? _fontsLoading;
  bool get debugIsLoadingFonts => _fontsLoading != null;

  Future<void> debugWhenIdle() async {
    if (assertionsEnabled) {
      await Future<void>.delayed(Duration.zero);
      while (isPending) {
        if (_fontsLoading != null) {
          await _fontsLoading;
        }
        if (pendingFonts.isNotEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          if (pendingFonts.isEmpty) {
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
        }
      }
    } else {
      throw UnimplementedError();
    }
  }

  void add(NotoFont font) {
    if (downloadedFonts.contains(font) ||
        pendingFonts.containsKey(font.url)) {
      return;
    }
    final bool firstInBatch = pendingFonts.isEmpty;
    pendingFonts[font.url] = font;
    if (firstInBatch) {
      Timer.run(startDownloads);
    }
  }

  Future<void> startDownloads() async {
    final Map<String, Future<void>> downloads = <String, Future<void>>{};
    final Map<String, Uint8List> downloadedData = <String, Uint8List>{};
    for (final NotoFont font in pendingFonts.values) {
      downloads[font.url] = Future<void>(() async {
        ByteBuffer buffer;
        try {
          buffer = await downloader.downloadAsBytes(font.url,
              debugDescription: font.name);
        } catch (e) {
          pendingFonts.remove(font.url);
          printWarning('Failed to load font ${font.name} at ${font.url}');
          printWarning(e.toString());
          return;
        }
        downloadedFonts.add(font);
        downloadedData[font.url] = buffer.asUint8List();
      });
    }

    await Future.wait<void>(downloads.values);

    // Register fallback fonts in a predictable order. Otherwise, the fonts
    // change their precedence depending on the download order causing
    // visual differences between app reloads.
    final List<String> downloadOrder =
        (downloadedData.keys.toList()..sort()).reversed.toList();
    for (final String url in downloadOrder) {
      final NotoFont font = pendingFonts.remove(url)!;
      final Uint8List bytes = downloadedData[url]!;
      FontFallbackData.instance.registerFallbackFont(font.name, bytes);
      if (pendingFonts.isEmpty) {
        renderer.fontCollection.registerDownloadedFonts();
        sendFontChangeMessage();
      }
    }

    if (pendingFonts.isNotEmpty) {
      await startDownloads();
    }
  }
}

class NotoDownloader {
  int get debugActiveDownloadCount => _debugActiveDownloadCount;
  int _debugActiveDownloadCount = 0;

  /// Returns a future that resolves when there are no pending downloads.
  ///
  /// Useful in tests to make sure that fonts are loaded before working with
  /// text.
  Future<void> debugWhenIdle() async {
    if (assertionsEnabled) {
      // Some downloads begin asynchronously in a microtask or in a Timer.run.
      // Let those run before waiting for downloads to finish.
      await Future<void>.delayed(Duration.zero);
      while (_debugActiveDownloadCount > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        // If we started with a non-zero count and hit zero while waiting, wait a
        // little more to make sure another download doesn't get chained after
        // the last one (e.g. font file download after font CSS download).
        if (_debugActiveDownloadCount == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    } else {
      throw UnimplementedError();
    }
  }

  /// Downloads the [url] and returns it as a [ByteBuffer].
  ///
  /// Override this for testing.
  Future<ByteBuffer> downloadAsBytes(String url, {String? debugDescription}) async {
    if (assertionsEnabled) {
      _debugActiveDownloadCount += 1;
    }
    final Future<ByteBuffer> data = httpFetchByteBuffer(url);
    if (assertionsEnabled) {
      unawaited(data.whenComplete(() {
        _debugActiveDownloadCount -= 1;
      }));
    }
    return data;
  }

  /// Downloads the [url] and returns is as a [String].
  ///
  /// Override this for testing.
  Future<String> downloadAsString(String url, {String? debugDescription}) async {
    if (assertionsEnabled) {
      _debugActiveDownloadCount += 1;
    }
    final Future<String> data = httpFetchText(url);
    if (assertionsEnabled) {
      unawaited(data.whenComplete(() {
        _debugActiveDownloadCount -= 1;
      }));
    }
    return data;
  }
}

FallbackFontDownloadQueue notoDownloadQueue = FallbackFontDownloadQueue();

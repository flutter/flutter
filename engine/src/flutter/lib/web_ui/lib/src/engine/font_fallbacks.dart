// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:ui/src/engine.dart';

abstract class FallbackFontRegistry {
  List<int> getMissingCodePoints(List<int> codePoints, List<String> fontFamilies);
  Future<void> loadFallbackFont(String familyName, String string);
  void updateFallbackFontFamilies(List<String> families);
}

/// Global static font fallback data.
class FontFallbackManager {
  factory FontFallbackManager(FallbackFontRegistry registry) =>
    FontFallbackManager._(
      registry,
      getFallbackFontData(configuration.useColorEmoji)
    );

  FontFallbackManager._(this.registry, this.fallbackFonts) :
    _notoSansSC = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans SC'),
    _notoSansTC = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans TC'),
    _notoSansHK = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans HK'),
    _notoSansJP = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans JP'),
    _notoSansKR = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans KR'),
    _notoSymbols = fallbackFonts.singleWhere((NotoFont font) => font.name == 'Noto Sans Symbols'),
    notoTree = createNotoFontTree(fallbackFonts) {
      downloadQueue = FallbackFontDownloadQueue(this);
    }

  final FallbackFontRegistry registry;

  late final FallbackFontDownloadQueue downloadQueue;

  /// Code points that no known font has a glyph for.
  final Set<int> codePointsWithNoKnownFont = <int>{};

  /// Code points which are known to be covered by at least one fallback font.
  final Set<int> knownCoveredCodePoints = <int>{};

  final List<NotoFont> fallbackFonts;

  /// Index of all font families by code point range.
  final IntervalTree<NotoFont> notoTree;

  final NotoFont _notoSansSC;
  final NotoFont _notoSansTC;
  final NotoFont _notoSansHK;
  final NotoFont _notoSansJP;
  final NotoFont _notoSansKR;

  final NotoFont _notoSymbols;

  Future<void> _idleFuture = Future<void>.value();

  static IntervalTree<NotoFont> createNotoFontTree(List<NotoFont> fallbackFonts) {
    final Map<NotoFont, List<CodePointRange>> ranges =
        <NotoFont, List<CodePointRange>>{};

    for (final NotoFont font in fallbackFonts) {
      final List<CodePointRange> fontRanges =
        ranges.putIfAbsent(font, () => <CodePointRange>[]);
      fontRanges.addAll(font.computeUnicodeRanges());
    }

    return IntervalTree<NotoFont>.createFromRanges(ranges);
  }

  final List<String> globalFontFallbacks = <String>['Roboto'];

  /// A list of code points to check against the global fallback fonts.
  final Set<int> _codePointsToCheckAgainstFallbackFonts = <int>{};

  /// This is [true] if we have scheduled a check for missing code points.
  ///
  /// We only do this once a frame, since checking if a font supports certain
  /// code points is very expensive.
  bool _scheduledCodePointCheck = false;

  Future<void> debugWhenIdle() {
    if (assertionsEnabled) {
      return _idleFuture;
    } else {
      throw UnimplementedError();
    }
  }

  /// Determines if the given [text] contains any code points which are not
  /// supported by the current set of fonts.
  void ensureFontsSupportText(String text, List<String> fontFamilies) {
    // TODO(hterkelsen): Make this faster for the common case where the text
    // is supported by the given fonts.
    if (debugDisableFontFallbacks) {
      return;
    }

    // We have a cache of code points which are known to be covered by at least
    // one of our fallback fonts, and a cache of code points which are known not
    // to be covered by any fallback font. From the given text, construct a set
    // of code points which need to be checked.
    final Set<int> runesToCheck = <int>{};
    for (final int rune in text.runes) {
      // Filter out code points that don't need checking.
      if (!(rune < 160 || // ASCII and Unicode control points.
          knownCoveredCodePoints.contains(rune) || // Points we've already covered
          codePointsWithNoKnownFont.contains(rune)) // Points that don't have a fallback font
      ) {
        runesToCheck.add(rune);
      }
    }
    if (runesToCheck.isEmpty) {
      return;
    }

    final List<int> codePoints = runesToCheck.toList();
    final List<int> missingCodePoints =
      registry.getMissingCodePoints(codePoints, fontFamilies);

    if (missingCodePoints.isNotEmpty) {
      addMissingCodePoints(codePoints);
    }
  }

  void addMissingCodePoints(List<int> codePoints) {
    _codePointsToCheckAgainstFallbackFonts.addAll(codePoints);
    if (!_scheduledCodePointCheck) {
      _scheduledCodePointCheck = true;
      _idleFuture = Future<void>.delayed(Duration.zero, () async {
        _ensureFallbackFonts();
        _scheduledCodePointCheck = false;
        await downloadQueue.waitForIdle();
      });
    }
  }

  /// Checks the missing code points against the current set of fallback fonts
  /// and starts downloading new fallback fonts if the current set can't cover
  /// the code points.
  void _ensureFallbackFonts() {
    _scheduledCodePointCheck = false;
    // We don't know if the remaining code points are covered by our fallback
    // fonts. Check them and update the cache.
    if (_codePointsToCheckAgainstFallbackFonts.isEmpty) {
      return;
    }
    final List<int> codePoints = _codePointsToCheckAgainstFallbackFonts.toList();
    _codePointsToCheckAgainstFallbackFonts.clear();
    findFontsForMissingCodePoints(codePoints);
  }

  void registerFallbackFont(String family) {
    // Insert emoji font before all other fallback fonts so we use the emoji
    // whenever it's available.
    if (family == 'Noto Color Emoji' || family == 'Noto Emoji') {
      if (globalFontFallbacks.first == 'Roboto') {
        globalFontFallbacks.insert(1, family);
      } else {
        globalFontFallbacks.insert(0, family);
      }
    } else {
      globalFontFallbacks.add(family);
    }
  }

  void findFontsForMissingCodePoints(List<int> codePoints) {
    Set<NotoFont> fonts = <NotoFont>{};
    final Set<int> coveredCodePoints = <int>{};
    final Set<int> missingCodePoints = <int>{};
    for (final int codePoint in codePoints) {
      final List<NotoFont> fontsForPoint = notoTree.intersections(codePoint);
      fonts.addAll(fontsForPoint);
      if (fontsForPoint.isNotEmpty) {
        coveredCodePoints.add(codePoint);
      } else {
        missingCodePoints.add(codePoint);
      }
    }

    // The call to `findMinimumFontsForCodePoints` will remove all code points that
    // were matched by `fonts` from `unmatchedCodePoints`.
    final Set<int> unmatchedCodePoints = Set<int>.from(coveredCodePoints);
    fonts = findMinimumFontsForCodePoints(unmatchedCodePoints, fonts);

    fonts.forEach(downloadQueue.add);

    // We looked through the Noto font tree and didn't find any font families
    // covering some code points.
    if (missingCodePoints.isNotEmpty || unmatchedCodePoints.isNotEmpty) {
      if (!downloadQueue.isPending) {
        printWarning('Could not find a set of Noto fonts to display all missing '
            'characters. Please add a font asset for the missing characters.'
            ' See: https://flutter.dev/docs/cookbook/design/fonts');
        codePointsWithNoKnownFont.addAll(missingCodePoints);
      }
    }
  }

  /// Finds the minimum set of fonts which covers all of the [codePoints].
  ///
  /// Removes all code points covered by [fonts] from [codePoints]. The code
  /// points remaining in the [codePoints] set after calling this function do not
  /// have a font that covers them and can be omitted next time to avoid
  /// searching for fonts unnecessarily.
  ///
  /// Since set cover is NP-complete, we approximate using a greedy algorithm
  /// which finds the font which covers the most code points. If multiple CJK
  /// fonts match the same number of code points, we choose one based on the user's
  /// locale.
  Set<NotoFont> findMinimumFontsForCodePoints(
      Set<int> codePoints, Set<NotoFont> fonts) {
    assert(fonts.isNotEmpty || codePoints.isEmpty);
    final Set<NotoFont> minimumFonts = <NotoFont>{};
    final List<NotoFont> bestFonts = <NotoFont>[];

    final String language = domWindow.navigator.language;

    while (codePoints.isNotEmpty) {
      int maxCodePointsCovered = 0;
      bestFonts.clear();
      for (final NotoFont font in fonts) {
        int codePointsCovered = 0;
        for (final int codePoint in codePoints) {
          if (font.contains(codePoint)) {
            codePointsCovered++;
          }
        }
        if (codePointsCovered > maxCodePointsCovered) {
          bestFonts.clear();
          bestFonts.add(font);
          maxCodePointsCovered = codePointsCovered;
        } else if (codePointsCovered == maxCodePointsCovered) {
          bestFonts.add(font);
        }
      }
      if (maxCodePointsCovered == 0) {
        // Fonts cannot cover remaining unmatched characters.
        break;
      }
      // If the list of best fonts are all CJK fonts, choose the best one based
      // on locale. Otherwise just choose the first font.
      NotoFont bestFont = bestFonts.first;
      if (bestFonts.length > 1) {
        if (bestFonts.every((NotoFont font) =>
          font == _notoSansSC ||
          font == _notoSansTC ||
          font == _notoSansHK ||
          font == _notoSansJP ||
          font == _notoSansKR
        )) {
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
      codePoints.removeWhere((int codePoint) {
        return bestFont.contains(codePoint);
      });
      minimumFonts.add(bestFont);
    }
    return minimumFonts;
  }
}

class FallbackFontDownloadQueue {
  FallbackFontDownloadQueue(this.fallbackManager);

  final FontFallbackManager fallbackManager;

  static const String _defaultFallbackFontsUrlPrefix = 'https://fonts.gstatic.com/s/';
  String? fallbackFontUrlPrefixOverride;
  String get fallbackFontUrlPrefix => fallbackFontUrlPrefixOverride ?? _defaultFallbackFontsUrlPrefix;

  final Set<NotoFont> downloadedFonts = <NotoFont>{};
  final Map<String, NotoFont> pendingFonts = <String, NotoFont>{};

  bool get isPending => pendingFonts.isNotEmpty;

  void Function(String family)? debugOnLoadFontFamily;

  Completer<void>? _idleCompleter;

  Future<void> waitForIdle() {
    if (_idleCompleter == null) {
      // We're already idle
      return Future<void>.value();
    } else {
      return _idleCompleter!.future;
    }
  }

  void add(NotoFont font) {
    if (downloadedFonts.contains(font) ||
        pendingFonts.containsKey(font.url)) {
      return;
    }
    final bool firstInBatch = pendingFonts.isEmpty;
    pendingFonts[font.url] = font;
    _idleCompleter ??= Completer<void>();
    if (firstInBatch) {
      Timer.run(startDownloads);
    }
  }

  Future<void> startDownloads() async {
    final Map<String, Future<void>> downloads = <String, Future<void>>{};
    final List<String> downloadedFontFamilies = <String>[];
    for (final NotoFont font in pendingFonts.values) {
      downloads[font.url] = Future<void>(() async {
        try {
          final String url = '$fallbackFontUrlPrefix${font.url}';
          debugOnLoadFontFamily?.call(font.name);
          await fallbackManager.registry.loadFallbackFont(font.name, url);
          downloadedFontFamilies.add(font.url);
        } catch (e) {
          pendingFonts.remove(font.url);
          printWarning('Failed to load font ${font.name} at ${font.url}');
          printWarning(e.toString());
          return;
        }
        downloadedFonts.add(font);
      });
    }

    await Future.wait<void>(downloads.values);

    // Register fallback fonts in a predictable order. Otherwise, the fonts
    // change their precedence depending on the download order causing
    // visual differences between app reloads.
    downloadedFontFamilies.sort();
    for (final String url in downloadedFontFamilies) {
      final NotoFont font = pendingFonts.remove(url)!;
      fallbackManager.registerFallbackFont(font.name);
    }

    if (pendingFonts.isEmpty) {
      fallbackManager.registry.updateFallbackFontFamilies(
          fallbackManager.globalFontFallbacks
      );
      sendFontChangeMessage();
      final Completer<void> idleCompleter = _idleCompleter!;
      _idleCompleter = null;
      idleCompleter.complete();
    } else {
      await startDownloads();
    }
  }
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'configuration.dart';
import 'dom.dart';
import 'font_change_util.dart';
import 'font_fallbacks.dart';
import 'noto_font.dart';
import 'renderer.dart';
import 'util.dart';

class FallbackFontService {
  FallbackFontService._();

  static final FallbackFontService instance = FallbackFontService._();

  /// Code points that we have discovered are missing but haven't processed yet.
  final Set<int> _unprocessedCodePoints = <int>{};

  /// Code points that we have already tried to find fonts for and failed.
  final Set<int> _unsupportedCodePoints = <int>{};

  /// Fonts that are currently being downloaded.
  final Set<NotoFont> _pendingFonts = <NotoFont>{};

  /// Fonts that have failed to download or register permanently.
  final Set<NotoFont> _permanentlyUnavailableFonts = <NotoFont>{};

  /// Fonts that have been successfully downloaded and registered.
  final Set<NotoFont> _registeredFonts = <NotoFont>{};

  /// Tracks how many fonts have failed for each component.
  final Map<FallbackFontComponent, int> _failedFontsPerComponent = <FallbackFontComponent, int>{};

  /// The total number of fonts that have failed permanently across all requests.
  int _totalPermanentFailures = 0;

  /// Whether the service has been disabled due to too many global failures.
  bool _isBroken = false;

  /// Timer used for debouncing the processing loop.
  Timer? _processTimer;

  /// Timer used for debouncing the font change notification.
  Timer? _notifyTimer;

  /// Completer for [waitForIdle].
  Completer<void>? _idleCompleter;

  /// The number of retries per font.
  static const int _maxRetries = 3;

  /// The delay between retries.
  static const Duration _retryDelay = Duration(seconds: 1);

  /// The maximum number of global permanent failures allowed before the service
  /// is disabled (if no fonts have been successfully registered).
  static const int _maxGlobalFailuresBeforeBroken = 10;

  /// The maximum number of candidate fonts we will attempt to download for any
  /// single [FallbackFontComponent] before marking it as unsupported.
  static const int _maxFontsPerComponent = 5;

  /// Adds a list of missing code points to be processed.
  void addMissingCodePoints(List<int> codePoints) {
    var added = false;
    final FontFallbackManager manager = renderer.fontCollection.fontFallbackManager!;

    // Caches to avoid redundant binary-search lookups for consecutive
    // characters (common in script blocks like CJK or Arabic).
    FallbackFontComponent? lastComponent;
    bool? lastComponentCovered;

    // Filter out code points that we already know are unsupported or are
    // already in the queue to be processed. For the remaining code points,
    // determine which fallback font component covers them and whether that
    // component is already satisfied by a registered font.
    for (final codePoint in codePoints) {
      // Skip if we already know this character can't be rendered or if it's
      // already scheduled for processing.
      if (!_unsupportedCodePoints.contains(codePoint) &&
          !_unprocessedCodePoints.contains(codePoint)) {
        final FallbackFontComponent component = manager.codePointToComponents.lookup(codePoint);

        bool isCovered;
        if (component == lastComponent) {
          isCovered = lastComponentCovered!;
        } else {
          // Check if any of the fonts belonging to this component's block
          // have already been successfully loaded.
          isCovered = component.fonts.any((NotoFont f) => _registeredFonts.contains(f));
          lastComponent = component;
          lastComponentCovered = isCovered;
        }

        if (!isCovered) {
          _unprocessedCodePoints.add(codePoint);
          added = true;
        }
      }
    }

    if (added) {
      // If we added new requirements, ensure we are tracking the "idle" state
      // and schedule a processing run.
      _idleCompleter ??= Completer<void>();
      _scheduleProcess();
    }
  }

  /// Schedules a processing run in the next microtask.
  ///
  /// Debouncing processing allows multiple calls to [addMissingCodePoints]
  /// in the same turn of the event loop (e.g. from different paragraphs in the
  /// same frame) to be processed together.
  void _scheduleProcess() {
    _processTimer ??= Timer(Duration.zero, _process);
  }

  /// Core processing loop of the service.
  ///
  /// Categorizes all unprocessed code points into:
  /// 1. Resolved (already covered by a registered font)
  /// 2. Pending (currently being downloaded)
  /// 3. Unsupported (all candidate fonts failed permanently)
  /// 4. The Gap (missing characters that need a new font download)
  ///
  /// Once the "Gap" is identified, it runs the greedy selection algorithm and
  /// triggers download tasks for the chosen fonts.
  void _process() {
    _processTimer = null;

    final FontFallbackManager manager = renderer.fontCollection.fontFallbackManager!;

    // The "Gap" represents unique components that we need to find new fonts for.
    // We map Component -> Count of missing codepoints it covers in this batch.
    final gapComponentCounts = <FallbackFontComponent, int>{};

    // Lists to track codepoints that should be removed from the active queue.
    final resolvedCodePoints = <int>[];
    final newlyUnsupported = <int>[];

    // Caches to avoid redundant font-set iterations for codepoints that share a component.
    final coveredCache = <FallbackFontComponent, bool>{};
    final pendingCache = <FallbackFontComponent, bool>{};
    final unavailableCache = <FallbackFontComponent, bool>{};

    // Perform a single pass over all unprocessed codepoints to categorize them.
    for (final int cp in _unprocessedCodePoints) {
      if (_unsupportedCodePoints.contains(cp)) {
        resolvedCodePoints.add(cp);
        continue;
      }

      final FallbackFontComponent component = manager.codePointToComponents.lookup(cp);

      // 1. Prune: Is it already covered by a font we successfully registered?
      // This can happen if a font finished downloading while these characters
      // were still in the unprocessed queue.
      final bool isCovered = coveredCache.putIfAbsent(
        component,
        () => component.fonts.any((NotoFont f) => _registeredFonts.contains(f)),
      );
      if (isCovered) {
        resolvedCodePoints.add(cp);
        continue;
      }

      // 2. Pending: Are we already in the middle of downloading a font for this?
      // We don't want to start multiple concurrent downloads for the same script block.
      final bool isPending = pendingCache.putIfAbsent(
        component,
        () => component.fonts.any((NotoFont f) => _pendingFonts.contains(f)),
      );
      if (isPending) {
        // Keep in _unprocessedCodePoints so we re-evaluate when the download finishes,
        // but don't add to the "Gap" (don't start a duplicate download).
        continue;
      }

      // 3. Permanent Failure: Have all fonts for this component failed already?
      // If all candidate fonts for a character are dead, we stop trying to avoid infinite loops.
      //
      // We also stop if the service has been declared "broken" due to too many
      // global failures, or if this specific component has exhausted its
      // allowed attempt budget.
      final bool isUnavailable = unavailableCache.putIfAbsent(
        component,
        () =>
            _isBroken ||
            component.fonts.every((NotoFont f) => _permanentlyUnavailableFonts.contains(f)) ||
            (_failedFontsPerComponent[component] ?? 0) >= _maxFontsPerComponent,
      );
      if (isUnavailable) {
        newlyUnsupported.add(cp);
        resolvedCodePoints.add(cp);
        continue;
      }

      // 4. The Gap: This component is missing and we aren't fetching it yet.
      // We track the count of codepoints to weight the greedy algorithm later.
      gapComponentCounts[component] = (gapComponentCounts[component] ?? 0) + 1;
    }

    // Efficiently remove resolved/failed codepoints from the processing set.
    _unprocessedCodePoints.removeAll(resolvedCodePoints);

    if (newlyUnsupported.isNotEmpty) {
      printWarning(
        'Could not find a set of Noto fonts to display all missing '
        'characters. Please add a font asset for the missing characters.'
        ' See: https://docs.flutter.dev/cookbook/design/fonts',
      );
      _unsupportedCodePoints.addAll(newlyUnsupported);
    }

    if (gapComponentCounts.isEmpty) {
      _checkIdle();
      return;
    }

    // Resolve the Gap: Run the greedy algorithm on unique components.
    // This finds the smallest set of fonts that will resolve all current "Gaps".
    final List<NotoFont> newFonts = _findFontsForComponents(gapComponentCounts);

    if (newFonts.isEmpty) {
      _checkIdle();
      return;
    }

    // Fire and Forget: Start downloads for the selected fonts.
    newFonts.forEach(_startDownloadTask);
  }

  /// Wraps the download and registration process in a managed task.
  ///
  /// This ensures the [_pendingFonts] set is correctly updated and triggers
  /// a re-evaluation of the queue once the task finishes (either successfully
  /// or with a failure that might allow secondary fonts to be selected).
  Future<void> _startDownloadTask(NotoFont font) async {
    _pendingFonts.add(font);
    try {
      await _downloadAndRegisterFontWithRetries(font);
    } catch (e) {
      printWarning('Unexpected error during fallback font download task for ${font.name}: $e');
    } finally {
      _pendingFonts.remove(font);
      // Only re-schedule if we potentially finished the entire queue or if a failure
      // occurred that requires us to re-evaluate alternative fonts.
      // If a font failed, we need to run _process again to see if there's a
      // secondary fallback font that can cover the now-unmet requirements.
      if (!_registeredFonts.contains(font) || _pendingFonts.isEmpty) {
        _scheduleProcess();
      }
    }
  }

  /// Checks if the service has finished all work and notifies [waitForIdle].
  void _checkIdle() {
    // We are only truly "idle" when nothing is left to process and no downloads are in flight.
    if (_unprocessedCodePoints.isEmpty && _pendingFonts.isEmpty) {
      if (_idleCompleter != null) {
        final Completer<void> completer = _idleCompleter!;
        _idleCompleter = null;
        completer.complete();
      }
    }
  }

  /// Implements a greedy algorithm to find the minimal set of fonts covering
  /// the required components, optimized by operating on component counts.
  List<NotoFont> _findFontsForComponents(Map<FallbackFontComponent, int> componentCoverCounts) {
    if (componentCoverCounts.isEmpty) {
      return <NotoFont>[];
    }

    final List<FallbackFontComponent> requiredComponents = componentCoverCounts.keys.toList();
    final FontFallbackManager manager = renderer.fontCollection.fontFallbackManager!;

    // Initialize coverage state for candidate fonts. We only consider fonts
    // that haven't been marked as permanently unavailable. For each candidate
    // font, we track the total number of missing code points it covers across
    // all components, and maintain a mapping of the font to the components it
    // covers to facilitate efficient updates during the greedy selection process.
    final fontCoverCounts = <NotoFont, int>{};
    final fontToComponents = <NotoFont, List<FallbackFontComponent>>{};
    final candidateFonts = <NotoFont>{};

    for (final component in requiredComponents) {
      final int count = componentCoverCounts[component]!;
      for (final NotoFont font in component.fonts) {
        // Skip fonts that we've already tried and failed to load permanently.
        if (_permanentlyUnavailableFonts.contains(font)) {
          continue;
        }
        if (!fontCoverCounts.containsKey(font)) {
          fontCoverCounts[font] = 0;
          fontToComponents[font] = <FallbackFontComponent>[];
          candidateFonts.add(font);
        }
        // A font's weight is the sum of all codepoints in the blocks it covers.
        fontCoverCounts[font] = fontCoverCounts[font]! + count;
        fontToComponents[font]!.add(component);
      }
    }

    final selectedFonts = <NotoFont>[];
    while (candidateFonts.isNotEmpty) {
      // Pick the "best" font based on coverage and language priority.
      final NotoFont selectedFont = _selectBestFont(
        candidateFonts.toList(),
        fontCoverCounts,
        manager,
      );
      selectedFonts.add(selectedFont);

      // Once a font is selected, we consider all of its covered components
      // "resolved" for this batch.
      final List<FallbackFontComponent> componentsToRemove = fontToComponents[selectedFont]!;
      for (final component in componentsToRemove) {
        final int count = componentCoverCounts[component]!;
        if (count == 0) {
          continue;
        }
        // Update the coverage weights for all OTHER candidate fonts that
        // also covered this now-resolved component.
        for (final NotoFont font in component.fonts) {
          if (candidateFonts.contains(font)) {
            fontCoverCounts[font] = fontCoverCounts[font]! - count;
          }
        }
        componentCoverCounts[component] = 0;
      }

      // Prune fonts that no longer provide unique coverage (weight <= 0).
      candidateFonts.removeWhere((NotoFont f) => fontCoverCounts[f]! <= 0);
    }

    return selectedFonts;
  }

  /// Data-driven mapping of BCP47 language tags to Noto font family prefixes.
  /// The order within each list represents the priority for that specific language.
  static const Map<String, List<String>> _kLanguageFontPreferences = <String, List<String>>{
    'zh-Hant': <String>['Noto Sans TC'],
    'zh-TW': <String>['Noto Sans TC'],
    'zh-MO': <String>['Noto Sans TC'],
    'zh-HK': <String>['Noto Sans HK', 'Noto Sans TC'],
    'ja': <String>['Noto Sans JP'],
    'ko': <String>['Noto Sans KR'],
    'zh': <String>['Noto Sans SC'],
    'zh-Hans': <String>['Noto Sans SC'],
    'zh-CN': <String>['Noto Sans SC', 'Noto Sans TC'],
  };

  /// Global priority list for tie-breaking when multiple fonts offer equal coverage.
  static const List<String> _kGlobalTieBreakers = <String>[
    'Noto Color Emoji',
    'Noto Sans Symbols',
    'Noto Sans SC',
    'Noto Sans TC',
    'Noto Sans HK',
    'Noto Sans JP',
    'Noto Sans KR',
  ];

  /// Selects the optimal font from a list of [fonts] based on a multi-stage
  /// tie-breaking process.
  ///
  /// The selection criteria, in order of priority, are:
  /// 1. **Language Preference**: Choose a font that matches the user's
  ///    preferred language (if specified).
  /// 2. **Maximum Coverage**: Choose the font(s) that cover the greatest number
  ///    of currently missing code points.
  /// 3. **Global Tie-Breakers**: If multiple fonts have equal maximum coverage,
  ///    use a predefined global priority list (e.g., favoring Emojis).
  /// 4. **Deterministic Fallback**: If still tied, pick the font with the
  ///    lowest original index.
  NotoFont _selectBestFont(
    List<NotoFont> fonts,
    Map<NotoFont, int> coverCounts,
    FontFallbackManager manager,
  ) {
    assert(fonts.every((NotoFont f) => coverCounts.containsKey(f)));
    final String language = manager.preferredLanguage;

    // 1. Language-Specific Preference
    final List<String> preferredPrefixes = _getPrefixesForLanguage(language);
    for (final prefix in preferredPrefixes) {
      final NotoFont? match = fonts.firstWhereOrNull((NotoFont f) => f.name.startsWith(prefix));
      if (match != null && coverCounts[match]! > 0) {
        return match;
      }
    }

    // 2. Maximum Coverage Selection
    final List<NotoFont> bestFonts = _findFontsWithMaxCoverage(fonts, coverCounts);
    if (bestFonts.length == 1) {
      return bestFonts.first;
    }

    // 3. Global Tie-Breaking
    for (final String prefix in _kGlobalTieBreakers) {
      final NotoFont? match = bestFonts.firstWhereOrNull((NotoFont f) => f.name.startsWith(prefix));
      if (match != null) {
        return match;
      }
    }

    // 4. Deterministic fallback: pick the one with the smallest original index.
    return bestFonts.first;
  }

  /// Returns the prioritized font prefixes for a given BCP47 [lang] tag.
  List<String> _getPrefixesForLanguage(String lang) {
    // 1. Exact match (e.g., 'zh-HK')
    if (_kLanguageFontPreferences.containsKey(lang)) {
      return _kLanguageFontPreferences[lang]!;
    }

    // 2. Base language match (e.g., 'en-US' -> 'en')
    final int dashIndex = lang.indexOf('-');
    if (dashIndex != -1) {
      final String baseLang = lang.substring(0, dashIndex);
      if (_kLanguageFontPreferences.containsKey(baseLang)) {
        return _kLanguageFontPreferences[baseLang]!;
      }
    }

    return const <String>[];
  }

  /// Finds the subset of [fonts] that provide the maximum possible coverage
  /// of missing code points, as defined by [coverCounts].
  ///
  /// If multiple fonts provide the same maximum coverage, all are returned,
  /// sorted by their original index to ensure deterministic behavior in
  /// subsequent tie-breaking steps.
  List<NotoFont> _findFontsWithMaxCoverage(List<NotoFont> fonts, Map<NotoFont, int> coverCounts) {
    assert(fonts.every((NotoFont f) => coverCounts.containsKey(f)));
    var maxCovered = -1;
    final bestFonts = <NotoFont>[];

    for (final font in fonts) {
      final int count = coverCounts[font]!;
      if (count > maxCovered) {
        // Found a new maximum; start a new list.
        maxCovered = count;
        bestFonts.clear();
        bestFonts.add(font);
      } else if (count == maxCovered) {
        // Another font with the same coverage; add to the tie-break set.
        bestFonts.add(font);
      }
    }

    // Ensure deterministic order for tie-breaking step.
    bestFonts.sort((NotoFont a, NotoFont b) => a.index.compareTo(b.index));
    return bestFonts;
  }

  /// Downloads and registers a single fallback [font], implementing a resilient
  /// retry strategy for network and server errors.
  ///
  /// The process follows these steps:
  /// 1. **HTTP Fetch**: Attempts to download the font file from the configured
  ///    CDN.
  /// 2. **Registration**: Once downloaded, the font is registered with the
  ///    renderer. If registration fails (e.g., due to corrupt font data), it
  ///    is treated as a permanent failure.
  /// 3. **Retry Strategy**:
  ///    - **Transient Failures**: Errors like network timeouts or specific HTTP
  ///      status codes (e.g., 408, 429) trigger a retry after a 1-second delay.
  ///      A font is retried up to 3 times.
  ///    - **Permanent Failures**: Errors like 404 (Not Found) or illegal font
  ///      data cause the font to be marked as "Permanently Unavailable."
  /// 4. **Notification**: On successful registration, the service notifies the
  ///    framework to trigger a UI relayout.
  Future<void> _downloadAndRegisterFontWithRetries(NotoFont font) async {
    if (_isBroken) {
      return;
    }

    var attempts = 0;
    final String baseUrl = configuration.fontFallbackBaseUrl;

    // Resolve the full URL from the configured CDN base.
    final url = Uri.parse(baseUrl).resolve(font.url).toString();

    // Attempt the download multiple times if transient errors occur.
    while (attempts < _maxRetries) {
      try {
        final HttpFetchResponse response = await httpFetch(url);

        if (response.hasPayload) {
          // If we got data, try to register it as a typeface in the browser.
          final Uint8List bytes = await response.asUint8List();
          final bool success = await renderer.fontCollection.fallbackFontRegistry!.loadFallbackFont(
            font.name,
            bytes,
          );

          if (success) {
            _registeredFonts.add(font);
            renderer.fontCollection.fontFallbackManager!.registerFallbackFont(font.name);
            _notifyFontsChanged();
            return;
          } else {
            // Registration failure is usually due to corrupt or invalid font data.
            printWarning(
              'Failed to parse font data for ${font.name} from $url. '
              'Treating as permanent failure.',
            );
            break;
          }
        } else if (_isPermanentStatus(response.status)) {
          // 404s and similar are permanent; other errors might be temporary.
          printWarning(
            'Permanent HTTP failure (status ${response.status}) for '
            '${font.name} at $url.',
          );
          break;
        } else {
          printWarning(
            'Transient HTTP failure (status ${response.status}) for '
            '${font.name} at $url. Retrying (attempt ${attempts + 1})...',
          );
        }
      } catch (e) {
        // Only retry for network-level failures or timeouts.
        if (e is HttpFetchError || e is TimeoutException) {
          printWarning(
            'Transient error (attempt ${attempts + 1}) for ${font.name}: $e. '
            'Retrying...',
          );
        } else {
          printWarning('Unexpected permanent error for ${font.name}: $e');
          break;
        }
      }

      attempts++;
      if (attempts < _maxRetries) {
        // Optional delay between retries to give the network time to recover.
        if (!configuration.debugSkipFontRetryDelay) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    }

    // If all retries failed, stop trying this font forever.
    printWarning('Font ${font.name} at $url is permanently unavailable.');
    _permanentlyUnavailableFonts.add(font);

    // Track failures for the global kill switch and per-component cap.
    _totalPermanentFailures++;
    final FontFallbackManager manager = renderer.fontCollection.fontFallbackManager!;
    // Note: This is slightly inefficient as we repeat the search, but it keeps
    // the download task's signature simple.
    // We check all components to see which one was supposed to be covered by this font.
    for (final FallbackFontComponent component in manager.fontComponents) {
      if (component.fonts.contains(font)) {
        _failedFontsPerComponent[component] = (_failedFontsPerComponent[component] ?? 0) + 1;
      }
    }

    if (_registeredFonts.isEmpty && _totalPermanentFailures >= _maxGlobalFailuresBeforeBroken) {
      printWarning(
        'Font fallback service has reached the maximum number of global failures '
        'without a single success. This may indicate a problem with the '
        'fontFallbackBaseUrl (currently "$baseUrl"). Disabling service for this session.',
      );
      _isBroken = true;
    }
  }

  /// Determines if an HTTP [status] code should be treated as a permanent error.
  bool _isPermanentStatus(int status) {
    // 4xx errors are generally permanent, except 408 (Request Timeout) and
    // 429 (Too Many Requests).
    return (status >= 400 && status < 500) && status != 408 && status != 429;
  }

  /// Notifies the Flutter framework that fonts have changed.
  ///
  /// This is debounced to avoid redundant relayouts when multiple fonts are
  /// registered in the same turn of the event loop.
  void _notifyFontsChanged() {
    // Debounce the notification to the framework. Since font downloads are
    // asynchronous and can finish in batches, we wait for the next microtask
    // to ensure we only send a single "font change" message even if multiple
    // fonts were registered in the same turn of the event loop.
    _notifyTimer ??= Timer(Duration.zero, () {
      _notifyTimer = null;
      final FontFallbackManager manager = renderer.fontCollection.fontFallbackManager!;

      // Update the font family lists used by Skia/CanvasKit.
      manager.updateFallbackFontFamilies();

      // Send the platform message to the Flutter framework to trigger a re-layout.
      sendFontChangeMessage();
    });
  }

  /// Returns a future that completes when the service is idle.
  ///
  /// The service is considered idle when there are no more missing code points
  /// to process and no more fonts being downloaded.
  ///
  /// Note that this idle state is transient; if the framework triggers another
  /// layout immediately after a font is registered, new code points may be
  /// enqueued, making the service no longer idle.
  Future<void> waitForIdle() {
    if (_idleCompleter == null) {
      return Future<void>.value();
    }
    return _idleCompleter!.future;
  }

  @visibleForTesting
  void debugReset() {
    _unprocessedCodePoints.clear();
    _unsupportedCodePoints.clear();
    _pendingFonts.clear();
    _permanentlyUnavailableFonts.clear();
    _registeredFonts.clear();
    _failedFontsPerComponent.clear();
    _totalPermanentFailures = 0;
    _isBroken = false;
    _processTimer?.cancel();
    _processTimer = null;
    _notifyTimer?.cancel();
    _notifyTimer = null;
    _idleCompleter = null;
  }
}

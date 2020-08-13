// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of dart.ui;

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Signature for [Window.onBeginFrame].
typedef FrameCallback = void Function(Duration duration);

/// Signature for [Window.onReportTimings].
///
/// {@template dart.ui.TimingsCallback.list}
/// The callback takes a list of [FrameTiming] because it may not be
/// immediately triggered after each frame. Instead, Flutter tries to batch
/// frames together and send all their timings at once to decrease the
/// overhead (as this is available in the release mode). The list is sorted in
/// ascending order of time (earliest frame first). The timing of any frame
/// will be sent within about 1 second (100ms if in the profile/debug mode)
/// even if there are no later frames to batch. The timing of the first frame
/// will be sent immediately without batching.
/// {@endtemplate}
typedef TimingsCallback = void Function(List<FrameTiming> timings);

/// Signature for [Window.onPointerDataPacket].
typedef PointerDataPacketCallback = void Function(PointerDataPacket packet);

/// Signature for [Window.onSemanticsAction].
typedef SemanticsActionCallback = void Function(int id, SemanticsAction action, ByteData? args);

/// Signature for responses to platform messages.
///
/// Used as a parameter to [Window.sendPlatformMessage] and
/// [Window.onPlatformMessage].
typedef PlatformMessageResponseCallback = void Function(ByteData? data);

/// Signature for [Window.onPlatformMessage].
typedef PlatformMessageCallback = void Function(String name, ByteData? data, PlatformMessageResponseCallback? callback);

// Signature for _setNeedsReportTimings.
typedef _SetNeedsReportTimingsFunc = void Function(bool value);

/// Various important time points in the lifetime of a frame.
///
/// [FrameTiming] records a timestamp of each phase for performance analysis.
enum FramePhase {
  /// The timestamp of the vsync signal given by the operating system.
  ///
  /// See also [FrameTiming.vsyncOverhead].
  vsyncStart,

  /// When the UI thread starts building a frame.
  ///
  /// See also [FrameTiming.buildDuration].
  buildStart,

  /// When the UI thread finishes building a frame.
  ///
  /// See also [FrameTiming.buildDuration].
  buildFinish,

  /// When the raster thread starts rasterizing a frame.
  ///
  /// See also [FrameTiming.rasterDuration].
  rasterStart,

  /// When the raster thread finishes rasterizing a frame.
  ///
  /// See also [FrameTiming.rasterDuration].
  rasterFinish,
}

/// Time-related performance metrics of a frame.
///
/// If you're using the whole Flutter framework, please use
/// [SchedulerBinding.addTimingsCallback] to get this. It's preferred over using
/// [Window.onReportTimings] directly because
/// [SchedulerBinding.addTimingsCallback] allows multiple callbacks. If
/// [SchedulerBinding] is unavailable, then see [Window.onReportTimings] for how
/// to get this.
///
/// The metrics in debug mode (`flutter run` without any flags) may be very
/// different from those in profile and release modes due to the debug overhead.
/// Therefore it's recommended to only monitor and analyze performance metrics
/// in profile and release modes.
class FrameTiming {
  /// Construct [FrameTiming] with raw timestamps in microseconds.
  ///
  /// This constructor is used for unit test only. Real [FrameTiming]s should
  /// be retrieved from [Window.onReportTimings].
  factory FrameTiming({
    required int vsyncStart,
    required int buildStart,
    required int buildFinish,
    required int rasterStart,
    required int rasterFinish,
  }) {
    return FrameTiming._(<int>[
      vsyncStart,
      buildStart,
      buildFinish,
      rasterStart,
      rasterFinish
    ]);
  }

  /// Construct [FrameTiming] with raw timestamps in microseconds.
  ///
  /// List [timestamps] must have the same number of elements as
  /// [FramePhase.values].
  ///
  /// This constructor is usually only called by the Flutter engine, or a test.
  /// To get the [FrameTiming] of your app, see [Window.onReportTimings].
  FrameTiming._(List<int> timestamps)
      : assert(timestamps.length == FramePhase.values.length), _timestamps = timestamps;

  /// This is a raw timestamp in microseconds from some epoch. The epoch in all
  /// [FrameTiming] is the same, but it may not match [DateTime]'s epoch.
  int timestampInMicroseconds(FramePhase phase) => _timestamps[phase.index];

  Duration _rawDuration(FramePhase phase) => Duration(microseconds: _timestamps[phase.index]);

  /// The duration to build the frame on the UI thread.
  ///
  /// The build starts approximately when [Window.onBeginFrame] is called. The
  /// [Duration] in the [Window.onBeginFrame] callback is exactly the
  /// `Duration(microseconds: timestampInMicroseconds(FramePhase.buildStart))`.
  ///
  /// The build finishes when [Window.render] is called.
  ///
  /// {@template dart.ui.FrameTiming.fps_smoothness_milliseconds}
  /// To ensure smooth animations of X fps, this should not exceed 1000/X
  /// milliseconds.
  /// {@endtemplate}
  /// {@template dart.ui.FrameTiming.fps_milliseconds}
  /// That's about 16ms for 60fps, and 8ms for 120fps.
  /// {@endtemplate}
  Duration get buildDuration => _rawDuration(FramePhase.buildFinish) - _rawDuration(FramePhase.buildStart);

  /// The duration to rasterize the frame on the raster thread.
  ///
  /// {@macro dart.ui.FrameTiming.fps_smoothness_milliseconds}
  /// {@macro dart.ui.FrameTiming.fps_milliseconds}
  Duration get rasterDuration => _rawDuration(FramePhase.rasterFinish) - _rawDuration(FramePhase.rasterStart);

  /// The duration between receiving the vsync signal and starting building the
  /// frame.
  Duration get vsyncOverhead => _rawDuration(FramePhase.buildStart) - _rawDuration(FramePhase.vsyncStart);

  /// The timespan between vsync start and raster finish.
  ///
  /// To achieve the lowest latency on an X fps display, this should not exceed
  /// 1000/X milliseconds.
  /// {@macro dart.ui.FrameTiming.fps_milliseconds}
  ///
  /// See also [vsyncOverhead], [buildDuration] and [rasterDuration].
  Duration get totalSpan => _rawDuration(FramePhase.rasterFinish) - _rawDuration(FramePhase.vsyncStart);

  final List<int> _timestamps;  // in microseconds

  String _formatMS(Duration duration) => '${duration.inMicroseconds * 0.001}ms';

  @override
  String toString() {
    return '$runtimeType(buildDuration: ${_formatMS(buildDuration)}, rasterDuration: ${_formatMS(rasterDuration)}, vsyncOverhead: ${_formatMS(vsyncOverhead)}, totalSpan: ${_formatMS(totalSpan)})';
  }
}

/// States that an application can be in.
///
/// The values below describe notifications from the operating system.
/// Applications should not expect to always receive all possible
/// notifications. For example, if the users pulls out the battery from the
/// device, no notification will be sent before the application is suddenly
/// terminated, along with the rest of the operating system.
///
/// See also:
///
///  * [WidgetsBindingObserver], for a mechanism to observe the lifecycle state
///    from the widgets layer.
enum AppLifecycleState {
  /// The application is visible and responding to user input.
  resumed,

  /// The application is in an inactive state and is not receiving user input.
  ///
  /// On iOS, this state corresponds to an app or the Flutter host view running
  /// in the foreground inactive state. Apps transition to this state when in
  /// a phone call, responding to a TouchID request, when entering the app
  /// switcher or the control center, or when the UIViewController hosting the
  /// Flutter app is transitioning.
  ///
  /// On Android, this corresponds to an app or the Flutter host view running
  /// in the foreground inactive state.  Apps transition to this state when
  /// another activity is focused, such as a split-screen app, a phone call,
  /// a picture-in-picture app, a system dialog, or another window.
  ///
  /// Apps in this state should assume that they may be [paused] at any time.
  inactive,

  /// The application is not currently visible to the user, not responding to
  /// user input, and running in the background.
  ///
  /// When the application is in this state, the engine will not call the
  /// [Window.onBeginFrame] and [Window.onDrawFrame] callbacks.
  paused,

  /// The application is still hosted on a flutter engine but is detached from
  /// any host views.
  ///
  /// When the application is in this state, the engine is running without
  /// a view. It can either be in the progress of attaching a view when engine
  /// was first initializes, or after the view being destroyed due to a Navigator
  /// pop.
  detached,
}

/// A representation of distances for each of the four edges of a rectangle,
/// used to encode the view insets and padding that applications should place
/// around their user interface, as exposed by [Window.viewInsets] and
/// [Window.padding]. View insets and padding are preferably read via
/// [MediaQuery.of].
///
/// For a generic class that represents distances around a rectangle, see the
/// [EdgeInsets] class.
///
/// See also:
///
///  * [WidgetsBindingObserver], for a widgets layer mechanism to receive
///    notifications when the padding changes.
///  * [MediaQuery.of], for the preferred mechanism for accessing these values.
///  * [Scaffold], which automatically applies the padding in material design
///    applications.
class WindowPadding {
  const WindowPadding._({ required this.left, required this.top, required this.right, required this.bottom });

  /// The distance from the left edge to the first unpadded pixel, in physical pixels.
  final double left;

  /// The distance from the top edge to the first unpadded pixel, in physical pixels.
  final double top;

  /// The distance from the right edge to the first unpadded pixel, in physical pixels.
  final double right;

  /// The distance from the bottom edge to the first unpadded pixel, in physical pixels.
  final double bottom;

  /// A window padding that has zeros for each edge.
  static const WindowPadding zero = WindowPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);

  @override
  String toString() {
    return 'WindowPadding(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}

/// An identifier used to select a user's language and formatting preferences.
///
/// This represents a [Unicode Language
/// Identifier](https://www.unicode.org/reports/tr35/#Unicode_language_identifier)
/// (i.e. without Locale extensions), except variants are not supported.
///
/// Locales are canonicalized according to the "preferred value" entries in the
/// [IANA Language Subtag
/// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).
/// For example, `const Locale('he')` and `const Locale('iw')` are equal and
/// both have the [languageCode] `he`, because `iw` is a deprecated language
/// subtag that was replaced by the subtag `he`.
///
/// See also:
///
///  * [Window.locale], which specifies the system's currently selected
///    [Locale].
class Locale {
  /// Creates a new Locale object. The first argument is the
  /// primary language subtag, the second is the region (also
  /// referred to as 'country') subtag.
  ///
  /// For example:
  ///
  /// ```dart
  /// const Locale swissFrench = Locale('fr', 'CH');
  /// const Locale canadianFrench = Locale('fr', 'CA');
  /// ```
  ///
  /// The primary language subtag must not be null. The region subtag is
  /// optional. When there is no region/country subtag, the parameter should
  /// be omitted or passed `null` instead of an empty-string.
  ///
  /// The subtag values are _case sensitive_ and must be one of the valid
  /// subtags according to CLDR supplemental data:
  /// [language](http://unicode.org/cldr/latest/common/validity/language.xml),
  /// [region](http://unicode.org/cldr/latest/common/validity/region.xml). The
  /// primary language subtag must be at least two and at most eight lowercase
  /// letters, but not four letters. The region region subtag must be two
  /// uppercase letters or three digits. See the [Unicode Language
  /// Identifier](https://www.unicode.org/reports/tr35/#Unicode_language_identifier)
  /// specification.
  ///
  /// Validity is not checked by default, but some methods may throw away
  /// invalid data.
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which also allows a [scriptCode] to be
  ///    specified.
  const Locale(
    this._languageCode, [
    this._countryCode,
  ]) : assert(_languageCode != null), // ignore: unnecessary_null_comparison
       assert(_languageCode != ''),
       scriptCode = null;

  /// Creates a new Locale object.
  ///
  /// The keyword arguments specify the subtags of the Locale.
  ///
  /// The subtag values are _case sensitive_ and must be valid subtags according
  /// to CLDR supplemental data:
  /// [language](http://unicode.org/cldr/latest/common/validity/language.xml),
  /// [script](http://unicode.org/cldr/latest/common/validity/script.xml) and
  /// [region](http://unicode.org/cldr/latest/common/validity/region.xml) for
  /// each of languageCode, scriptCode and countryCode respectively.
  ///
  /// The [countryCode] subtag is optional. When there is no country subtag,
  /// the parameter should be omitted or passed `null` instead of an empty-string.
  ///
  /// Validity is not checked by default, but some methods may throw away
  /// invalid data.
  const Locale.fromSubtags({
    String languageCode = 'und',
    this.scriptCode,
    String? countryCode,
  }) : assert(languageCode != null), // ignore: unnecessary_null_comparison
       assert(languageCode != ''),
       _languageCode = languageCode,
       assert(scriptCode != ''),
       assert(countryCode != ''),
       _countryCode = countryCode;

  /// The primary language subtag for the locale.
  ///
  /// This must not be null. It may be 'und', representing 'undefined'.
  ///
  /// This is expected to be string registered in the [IANA Language Subtag
  /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
  /// with the type "language". The string specified must match the case of the
  /// string in the registry.
  ///
  /// Language subtags that are deprecated in the registry and have a preferred
  /// code are changed to their preferred code. For example, `const
  /// Locale('he')` and `const Locale('iw')` are equal, and both have the
  /// [languageCode] `he`, because `iw` is a deprecated language subtag that was
  /// replaced by the subtag `he`.
  ///
  /// This must be a valid Unicode Language subtag as listed in [Unicode CLDR
  /// supplemental
  /// data](http://unicode.org/cldr/latest/common/validity/language.xml).
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  String get languageCode => _deprecatedLanguageSubtagMap[_languageCode] ?? _languageCode;
  final String _languageCode;

  // This map is generated by //flutter/tools/gen_locale.dart
  // Mappings generated for language subtag registry as of 2019-02-27.
  static const Map<String, String> _deprecatedLanguageSubtagMap = <String, String>{
    'in': 'id', // Indonesian; deprecated 1989-01-01
    'iw': 'he', // Hebrew; deprecated 1989-01-01
    'ji': 'yi', // Yiddish; deprecated 1989-01-01
    'jw': 'jv', // Javanese; deprecated 2001-08-13
    'mo': 'ro', // Moldavian, Moldovan; deprecated 2008-11-22
    'aam': 'aas', // Aramanik; deprecated 2015-02-12
    'adp': 'dz', // Adap; deprecated 2015-02-12
    'aue': 'ktz', // ǂKxʼauǁʼein; deprecated 2015-02-12
    'ayx': 'nun', // Ayi (China); deprecated 2011-08-16
    'bgm': 'bcg', // Baga Mboteni; deprecated 2016-05-30
    'bjd': 'drl', // Bandjigali; deprecated 2012-08-12
    'ccq': 'rki', // Chaungtha; deprecated 2012-08-12
    'cjr': 'mom', // Chorotega; deprecated 2010-03-11
    'cka': 'cmr', // Khumi Awa Chin; deprecated 2012-08-12
    'cmk': 'xch', // Chimakum; deprecated 2010-03-11
    'coy': 'pij', // Coyaima; deprecated 2016-05-30
    'cqu': 'quh', // Chilean Quechua; deprecated 2016-05-30
    'drh': 'khk', // Darkhat; deprecated 2010-03-11
    'drw': 'prs', // Darwazi; deprecated 2010-03-11
    'gav': 'dev', // Gabutamon; deprecated 2010-03-11
    'gfx': 'vaj', // Mangetti Dune ǃXung; deprecated 2015-02-12
    'ggn': 'gvr', // Eastern Gurung; deprecated 2016-05-30
    'gti': 'nyc', // Gbati-ri; deprecated 2015-02-12
    'guv': 'duz', // Gey; deprecated 2016-05-30
    'hrr': 'jal', // Horuru; deprecated 2012-08-12
    'ibi': 'opa', // Ibilo; deprecated 2012-08-12
    'ilw': 'gal', // Talur; deprecated 2013-09-10
    'jeg': 'oyb', // Jeng; deprecated 2017-02-23
    'kgc': 'tdf', // Kasseng; deprecated 2016-05-30
    'kgh': 'kml', // Upper Tanudan Kalinga; deprecated 2012-08-12
    'koj': 'kwv', // Sara Dunjo; deprecated 2015-02-12
    'krm': 'bmf', // Krim; deprecated 2017-02-23
    'ktr': 'dtp', // Kota Marudu Tinagas; deprecated 2016-05-30
    'kvs': 'gdj', // Kunggara; deprecated 2016-05-30
    'kwq': 'yam', // Kwak; deprecated 2015-02-12
    'kxe': 'tvd', // Kakihum; deprecated 2015-02-12
    'kzj': 'dtp', // Coastal Kadazan; deprecated 2016-05-30
    'kzt': 'dtp', // Tambunan Dusun; deprecated 2016-05-30
    'lii': 'raq', // Lingkhim; deprecated 2015-02-12
    'lmm': 'rmx', // Lamam; deprecated 2014-02-28
    'meg': 'cir', // Mea; deprecated 2013-09-10
    'mst': 'mry', // Cataelano Mandaya; deprecated 2010-03-11
    'mwj': 'vaj', // Maligo; deprecated 2015-02-12
    'myt': 'mry', // Sangab Mandaya; deprecated 2010-03-11
    'nad': 'xny', // Nijadali; deprecated 2016-05-30
    'ncp': 'kdz', // Ndaktup; deprecated 2018-03-08
    'nnx': 'ngv', // Ngong; deprecated 2015-02-12
    'nts': 'pij', // Natagaimas; deprecated 2016-05-30
    'oun': 'vaj', // ǃOǃung; deprecated 2015-02-12
    'pcr': 'adx', // Panang; deprecated 2013-09-10
    'pmc': 'huw', // Palumata; deprecated 2016-05-30
    'pmu': 'phr', // Mirpur Panjabi; deprecated 2015-02-12
    'ppa': 'bfy', // Pao; deprecated 2016-05-30
    'ppr': 'lcq', // Piru; deprecated 2013-09-10
    'pry': 'prt', // Pray 3; deprecated 2016-05-30
    'puz': 'pub', // Purum Naga; deprecated 2014-02-28
    'sca': 'hle', // Sansu; deprecated 2012-08-12
    'skk': 'oyb', // Sok; deprecated 2017-02-23
    'tdu': 'dtp', // Tempasuk Dusun; deprecated 2016-05-30
    'thc': 'tpo', // Tai Hang Tong; deprecated 2016-05-30
    'thx': 'oyb', // The; deprecated 2015-02-12
    'tie': 'ras', // Tingal; deprecated 2011-08-16
    'tkk': 'twm', // Takpa; deprecated 2011-08-16
    'tlw': 'weo', // South Wemale; deprecated 2012-08-12
    'tmp': 'tyj', // Tai Mène; deprecated 2016-05-30
    'tne': 'kak', // Tinoc Kallahan; deprecated 2016-05-30
    'tnf': 'prs', // Tangshewi; deprecated 2010-03-11
    'tsf': 'taj', // Southwestern Tamang; deprecated 2015-02-12
    'uok': 'ema', // Uokha; deprecated 2015-02-12
    'xba': 'cax', // Kamba (Brazil); deprecated 2016-05-30
    'xia': 'acn', // Xiandao; deprecated 2013-09-10
    'xkh': 'waw', // Karahawyana; deprecated 2016-05-30
    'xsj': 'suj', // Subi; deprecated 2015-02-12
    'ybd': 'rki', // Yangbye; deprecated 2012-08-12
    'yma': 'lrr', // Yamphe; deprecated 2012-08-12
    'ymt': 'mtm', // Mator-Taygi-Karagas; deprecated 2015-02-12
    'yos': 'zom', // Yos; deprecated 2013-09-10
    'yuu': 'yug', // Yugh; deprecated 2014-02-28
  };

  /// The script subtag for the locale.
  ///
  /// This may be null, indicating that there is no specified script subtag.
  ///
  /// This must be a valid Unicode Language Identifier script subtag as listed
  /// in [Unicode CLDR supplemental
  /// data](http://unicode.org/cldr/latest/common/validity/script.xml).
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  final String? scriptCode;

  /// The region subtag for the locale.
  ///
  /// This may be null, indicating that there is no specified region subtag.
  ///
  /// This is expected to be string registered in the [IANA Language Subtag
  /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry)
  /// with the type "region". The string specified must match the case of the
  /// string in the registry.
  ///
  /// Region subtags that are deprecated in the registry and have a preferred
  /// code are changed to their preferred code. For example, `const Locale('de',
  /// 'DE')` and `const Locale('de', 'DD')` are equal, and both have the
  /// [countryCode] `DE`, because `DD` is a deprecated language subtag that was
  /// replaced by the subtag `DE`.
  ///
  /// See also:
  ///
  ///  * [Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  String? get countryCode => _deprecatedRegionSubtagMap[_countryCode] ?? _countryCode;
  final String? _countryCode;

  // This map is generated by //flutter/tools/gen_locale.dart
  // Mappings generated for language subtag registry as of 2019-02-27.
  static const Map<String, String> _deprecatedRegionSubtagMap = <String, String>{
    'BU': 'MM', // Burma; deprecated 1989-12-05
    'DD': 'DE', // German Democratic Republic; deprecated 1990-10-30
    'FX': 'FR', // Metropolitan France; deprecated 1997-07-14
    'TP': 'TL', // East Timor; deprecated 2002-05-20
    'YD': 'YE', // Democratic Yemen; deprecated 1990-08-14
    'ZR': 'CD', // Zaire; deprecated 1997-07-14
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other))
      return true;
    if (other is! Locale) {
      return false;
    }
    final String? countryCode = _countryCode;
    final String? otherCountryCode = other.countryCode;
    return other.languageCode == languageCode
        && other.scriptCode == scriptCode // scriptCode cannot be ''
        && (other.countryCode == countryCode // Treat '' as equal to null.
            || otherCountryCode != null && otherCountryCode.isEmpty && countryCode == null
            || countryCode != null && countryCode.isEmpty && other.countryCode == null);
  }

  @override
  int get hashCode => hashValues(languageCode, scriptCode, countryCode == '' ? null : countryCode);

  static Locale? _cachedLocale;
  static String? _cachedLocaleString;

  /// Returns a string representing the locale.
  ///
  /// This identifier happens to be a valid Unicode Locale Identifier using
  /// underscores as separator, however it is intended to be used for debugging
  /// purposes only. For parseable results, use [toLanguageTag] instead.
  @keepToString
  @override
  String toString() {
    if (!identical(_cachedLocale, this)) {
      _cachedLocale = this;
      _cachedLocaleString = _rawToString('_');
    }
    return _cachedLocaleString!;
  }

  /// Returns a syntactically valid Unicode BCP47 Locale Identifier.
  ///
  /// Some examples of such identifiers: "en", "es-419", "hi-Deva-IN" and
  /// "zh-Hans-CN". See http://www.unicode.org/reports/tr35/ for technical
  /// details.
  String toLanguageTag() => _rawToString('-');

  String _rawToString(String separator) {
    final StringBuffer out = StringBuffer(languageCode);
    if (scriptCode != null && scriptCode!.isNotEmpty)
      out.write('$separator$scriptCode');
    if (_countryCode != null && _countryCode!.isNotEmpty)
      out.write('$separator$countryCode');
    return out.toString();
  }
}

/// The most basic interface to the host operating system's user interface.
///
/// It exposes the size of the display, the core scheduler API, the input event
/// callback, the graphics drawing API, and other such core services.
///
/// There is a single Window instance in the system, which you can
/// obtain from `WidgetsBinding.instance.window`.
///
/// There is also a [window] singleton object in `dart:ui` if `WidgetsBinding`
/// is unavailable. But we strongly advise to avoid statically referencing it.
/// See the document of [window] for more details of why it should be avoided.
///
/// ## Insets and Padding
///
/// {@animation 300 300 https://flutter.github.io/assets-for-api-docs/assets/widgets/window_padding.mp4}
///
/// In this diagram, the black areas represent system UI that the app cannot
/// draw over. The red area represents view padding that the application may not
/// be able to detect gestures in and may not want to draw in. The grey area
/// represents the system keyboard, which can cover over the bottom view
/// padding when visible.
///
/// The [Window.viewInsets] are the physical pixels which the operating
/// system reserves for system UI, such as the keyboard, which would fully
/// obscure any content drawn in that area.
///
/// The [Window.viewPadding] are the physical pixels on each side of the display
/// that may be partially obscured by system UI or by physical intrusions into
/// the display, such as an overscan region on a television or a "notch" on a
/// phone. Unlike the insets, these areas may have portions that show the user
/// application painted pixels without being obscured, such as a notch at the
/// top of a phone that covers only a subset of the area. Insets, on the other
/// hand, either partially or fully obscure the window, such as an opaque
/// keyboard or a partially transluscent statusbar, which cover an area without
/// gaps.
///
/// The [Window.padding] property is computed from both [Window.viewInsets] and
/// [Window.viewPadding]. It will allow a view inset to consume view padding
/// where appropriate, such as when a phone's keyboard is covering the bottom
/// view padding and so "absorbs" it.
///
/// Clients that want to position elements relative to the view padding
/// regardless of the view insets should use the [Window.viewPadding] property,
/// e.g. if you wish to draw a widget at the center of the screen with respect
/// to the iPhone "safe area" regardless of whether the keyboard is showing.
///
/// [Window.padding] is useful for clients that want to know how much padding
/// should be accounted for without concern for the current inset(s) state, e.g.
/// determining whether a gesture should be considered for scrolling purposes.
/// This value varies based on the current state of the insets. For example, a
/// visible keyboard will consume all gestures in the bottom part of the
/// [Window.viewPadding] anyway, so there is no need to account for that in the
/// [Window.padding], which is always safe to use for such calculations.
class Window {
  Window._() {
    _setNeedsReportTimings = _nativeSetNeedsReportTimings;
  }

  /// The number of device pixels for each logical pixel. This number might not
  /// be a power of two. Indeed, it might not even be an integer. For example,
  /// the Nexus 6 has a device pixel ratio of 3.5.
  ///
  /// Device pixels are also referred to as physical pixels. Logical pixels are
  /// also referred to as device-independent or resolution-independent pixels.
  ///
  /// By definition, there are roughly 38 logical pixels per centimeter, or
  /// about 96 logical pixels per inch, of the physical display. The value
  /// returned by [devicePixelRatio] is ultimately obtained either from the
  /// hardware itself, the device drivers, or a hard-coded value stored in the
  /// operating system or firmware, and may be inaccurate, sometimes by a
  /// significant margin.
  ///
  /// The Flutter framework operates in logical pixels, so it is rarely
  /// necessary to directly deal with this property.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio = 1.0;

  /// The dimensions of the rectangle into which the application will be drawn,
  /// in physical pixels.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// At startup, the size of the application window may not be known before Dart
  /// code runs. If this value is observed early in the application lifecycle,
  /// it may report [Size.zero].
  ///
  /// This value does not take into account any on-screen keyboards or other
  /// system UI. The [padding] and [viewInsets] properties provide a view into
  /// how much of each side of the application may be obscured by system UI.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Size get physicalSize => _physicalSize;
  Size _physicalSize = Size.zero;

  /// The physical depth is the maximum elevation that the Window allows.
  ///
  /// Physical layers drawn at or above this elevation will have their elevation
  /// clamped to this value. This can happen if the physical layer itself has
  /// an elevation larger than available depth, or if some ancestor of the layer
  /// causes it to have a cumulative elevation that is larger than the available
  /// depth.
  ///
  /// The default value is [double.maxFinite], which is used for platforms that
  /// do not specify a maximum elevation. This property is currently on expected
  /// to be set to a non-default value on Fuchsia.
  double get physicalDepth => _physicalDepth;
  double _physicalDepth = double.maxFinite;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but over which the operating system
  /// will likely place system UI, such as the keyboard, that fully obscures
  /// any content.
  ///
  /// When this property changes, [onMetricsChanged] is called.
  ///
  /// The relationship between this [Window.viewInsets], [Window.viewPadding],
  /// and [Window.padding] are described in more detail in the documentation for
  /// [Window].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the view insets in material
  ///    design applications.
  WindowPadding get viewInsets => _viewInsets;
  WindowPadding _viewInsets = WindowPadding.zero;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but which may be partially obscured by
  /// system UI (such as the system notification area), or or physical
  /// intrusions in the display (e.g. overscan regions on television screens or
  /// phone sensor housings).
  ///
  /// Unlike [Window.padding], this value does not change relative to
  /// [Window.viewInsets]. For example, on an iPhone X, it will not change in
  /// response to the soft keyboard being visible or hidden, whereas
  /// [Window.padding] will.
  ///
  /// When this property changes, [onMetricsChanged] is called.
  ///
  /// The relationship between this [Window.viewInsets], [Window.viewPadding],
  /// and [Window.padding] are described in more detail in the documentation for
  /// [Window].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the padding in material design
  ///    applications.
  WindowPadding get viewPadding => _viewPadding;
  WindowPadding _viewPadding = WindowPadding.zero;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but where the operating system will
  /// consume input gestures for the sake of system navigation.
  ///
  /// For example, an operating system might use the vertical edges of the
  /// screen, where swiping inwards from the edges takes users backward
  /// through the history of screens they previously visited.
  ///
  /// When this property changes, [onMetricsChanged] is called.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  WindowPadding get systemGestureInsets => _systemGestureInsets;
  WindowPadding _systemGestureInsets = WindowPadding.zero;

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but which may be partially obscured by
  /// system UI (such as the system notification area), or or physical
  /// intrusions in the display (e.g. overscan regions on television screens or
  /// phone sensor housings).
  ///
  /// This value is calculated by taking
  /// `max(0.0, Window.viewPadding - Window.viewInsets)`. This will treat a
  /// system IME that increases the bottom inset as consuming that much of the
  /// bottom padding. For example, on an iPhone X, [EdgeInsets.bottom] of
  /// [Window.padding] is the same as [EdgeInsets.bottom] of
  /// [Window.viewPadding] when the soft keyboard is not drawn (to account for
  /// the bottom soft button area), but will be `0.0` when the soft keyboard is
  /// visible.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// The relationship between this [Window.viewInsets], [Window.viewPadding],
  /// and [Window.padding] are described in more detail in the documentation for
  /// [Window].
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  ///  * [Scaffold], which automatically applies the padding in material design
  ///    applications.
  WindowPadding get padding => _padding;
  WindowPadding _padding = WindowPadding.zero;

  /// A callback that is invoked whenever the [devicePixelRatio],
  /// [physicalSize], [padding], [viewInsets], or [systemGestureInsets]
  /// values change, for example when the device is rotated or when the
  /// application is resized (e.g. when showing applications side-by-side
  /// on Android).
  ///
  /// The engine invokes this callback in the same zone in which the callback
  /// was set.
  ///
  /// The framework registers with this callback and updates the layout
  /// appropriately.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    register for notifications when this is called.
  ///  * [MediaQuery.of], a simpler mechanism for the same.
  VoidCallback? get onMetricsChanged => _onMetricsChanged;
  VoidCallback? _onMetricsChanged;
  Zone _onMetricsChangedZone = Zone.root;
  set onMetricsChanged(VoidCallback? callback) {
    _onMetricsChanged = callback;
    _onMetricsChangedZone = Zone.current;
  }

  /// The system-reported default locale of the device.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// This is the first locale selected by the user and is the user's
  /// primary locale (the locale the device UI is displayed in)
  ///
  /// This is equivalent to `locales.first` and will provide an empty non-null locale
  /// if the [locales] list has not been set or is empty.
  Locale? get locale {
    if (_locales != null && _locales!.isNotEmpty) {
      return _locales!.first;
    }
    return null;
  }

  /// The full system-reported supported locales of the device.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// The list is ordered in order of priority, with lower-indexed locales being
  /// preferred over higher-indexed ones. The first element is the primary [locale].
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  List<Locale>? get locales => _locales;
  List<Locale>? _locales;

  /// Performs the platform-native locale resolution.
  ///
  /// Each platform may return different results.
  ///
  /// If the platform fails to resolve a locale, then this will return null.
  ///
  /// This method returns synchronously and is a direct call to
  /// platform specific APIs without invoking method channels.
  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales) {
    final List<String?> supportedLocalesData = <String?>[];
    for (Locale locale in supportedLocales) {
      supportedLocalesData.add(locale.languageCode);
      supportedLocalesData.add(locale.countryCode);
      supportedLocalesData.add(locale.scriptCode);
    }

    final List<String> result = _computePlatformResolvedLocale(supportedLocalesData);

    if (result.isNotEmpty) {
      return Locale.fromSubtags(
        languageCode: result[0],
        countryCode: result[1] == '' ? null : result[1],
        scriptCode: result[2] == '' ? null : result[2]);
    }
    return null;
  }
  List<String> _computePlatformResolvedLocale(List<String?> supportedLocalesData) native 'PlatformConfiguration_computePlatformResolvedLocale';

  /// A callback that is invoked whenever [locale] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onLocaleChanged => _onLocaleChanged;
  VoidCallback? _onLocaleChanged;
  Zone _onLocaleChangedZone = Zone.root;
  set onLocaleChanged(VoidCallback? callback) {
    _onLocaleChanged = callback;
    _onLocaleChangedZone = Zone.current;
  }

  /// The lifecycle state immediately after dart isolate initialization.
  ///
  /// This property will not be updated as the lifecycle changes.
  ///
  /// It is used to initialize [SchedulerBinding.lifecycleState] at startup
  /// with any buffered lifecycle state events.
  String get initialLifecycleState {
    _initialLifecycleStateAccessed = true;
    return _initialLifecycleState;
  }
  late String _initialLifecycleState;
  /// Tracks if the initial state has been accessed. Once accessed, we
  /// will stop updating the [initialLifecycleState], as it is not the
  /// preferred way to access the state.
  bool _initialLifecycleStateAccessed = false;

  /// The system-reported text scale.
  ///
  /// This establishes the text scaling factor to use when rendering text,
  /// according to the user's platform preferences.
  ///
  /// The [onTextScaleFactorChanged] callback is called whenever this value
  /// changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  double get textScaleFactor => _textScaleFactor;
  double _textScaleFactor = 1.0;

  /// The setting indicating whether time should always be shown in the 24-hour
  /// format.
  ///
  /// This option is used by [showTimePicker].
  bool get alwaysUse24HourFormat => _alwaysUse24HourFormat;
  bool _alwaysUse24HourFormat = false;

  /// A callback that is invoked whenever [textScaleFactor] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onTextScaleFactorChanged => _onTextScaleFactorChanged;
  VoidCallback? _onTextScaleFactorChanged;
  Zone _onTextScaleFactorChangedZone = Zone.root;
  set onTextScaleFactorChanged(VoidCallback? callback) {
    _onTextScaleFactorChanged = callback;
    _onTextScaleFactorChangedZone = Zone.current;
  }

  /// The setting indicating the current brightness mode of the host platform.
  /// If the platform has no preference, [platformBrightness] defaults to [Brightness.light].
  Brightness get platformBrightness => _platformBrightness;
  Brightness _platformBrightness = Brightness.light;

  /// A callback that is invoked whenever [platformBrightness] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback? get onPlatformBrightnessChanged => _onPlatformBrightnessChanged;
  VoidCallback? _onPlatformBrightnessChanged;
  Zone _onPlatformBrightnessChangedZone = Zone.root;
  set onPlatformBrightnessChanged(VoidCallback? callback) {
    _onPlatformBrightnessChanged = callback;
    _onPlatformBrightnessChangedZone = Zone.current;
  }

  /// A callback that is invoked to notify the application that it is an
  /// appropriate time to provide a scene using the [SceneBuilder] API and the
  /// [render] method. When possible, this is driven by the hardware VSync
  /// signal. This is only called if [scheduleFrame] has been called since the
  /// last time this callback was invoked.
  ///
  /// The [onDrawFrame] callback is invoked immediately after [onBeginFrame],
  /// after draining any microtasks (e.g. completions of any [Future]s) queued
  /// by the [onBeginFrame] handler.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  FrameCallback? get onBeginFrame => _onBeginFrame;
  FrameCallback? _onBeginFrame;
  Zone _onBeginFrameZone = Zone.root;
  set onBeginFrame(FrameCallback? callback) {
    _onBeginFrame = callback;
    _onBeginFrameZone = Zone.current;
  }

  /// A callback that is invoked for each frame after [onBeginFrame] has
  /// completed and after the microtask queue has been drained. This can be
  /// used to implement a second phase of frame rendering that happens
  /// after any deferred work queued by the [onBeginFrame] phase.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  VoidCallback? get onDrawFrame => _onDrawFrame;
  VoidCallback? _onDrawFrame;
  Zone _onDrawFrameZone = Zone.root;
  set onDrawFrame(VoidCallback? callback) {
    _onDrawFrame = callback;
    _onDrawFrameZone = Zone.current;
  }

  /// A callback that is invoked to report the [FrameTiming] of recently
  /// rasterized frames.
  ///
  /// It's prefered to use [SchedulerBinding.addTimingsCallback] than to use
  /// [Window.onReportTimings] directly because
  /// [SchedulerBinding.addTimingsCallback] allows multiple callbacks.
  ///
  /// This can be used to see if the application has missed frames (through
  /// [FrameTiming.buildDuration] and [FrameTiming.rasterDuration]), or high
  /// latencies (through [FrameTiming.totalSpan]).
  ///
  /// Unlike [Timeline], the timing information here is available in the release
  /// mode (additional to the profile and the debug mode). Hence this can be
  /// used to monitor the application's performance in the wild.
  ///
  /// {@macro dart.ui.TimingsCallback.list}
  ///
  /// If this is null, no additional work will be done. If this is not null,
  /// Flutter spends less than 0.1ms every 1 second to report the timings
  /// (measured on iPhone6S). The 0.1ms is about 0.6% of 16ms (frame budget for
  /// 60fps), or 0.01% CPU usage per second.
  TimingsCallback? get onReportTimings => _onReportTimings;
  TimingsCallback? _onReportTimings;
  Zone _onReportTimingsZone = Zone.root;
  set onReportTimings(TimingsCallback? callback) {
    if ((callback == null) != (_onReportTimings == null)) {
      _setNeedsReportTimings(callback != null);
    }
    _onReportTimings = callback;
    _onReportTimingsZone = Zone.current;
  }

  late _SetNeedsReportTimingsFunc _setNeedsReportTimings;
  void _nativeSetNeedsReportTimings(bool value) native 'PlatformConfiguration_setNeedsReportTimings';

  /// A callback that is invoked when pointer data is available.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  PointerDataPacketCallback? get onPointerDataPacket => _onPointerDataPacket;
  PointerDataPacketCallback? _onPointerDataPacket;
  Zone _onPointerDataPacketZone = Zone.root;
  set onPointerDataPacket(PointerDataPacketCallback? callback) {
    _onPointerDataPacket = callback;
    _onPointerDataPacketZone = Zone.current;
  }

  /// The route or path that the embedder requested when the application was
  /// launched.
  ///
  /// This will be the string "`/`" if no particular route was requested.
  ///
  /// ## Android
  ///
  /// On Android, the initial route can be set on the [initialRoute](/javadoc/io/flutter/embedding/android/FlutterActivity.NewEngineIntentBuilder.html#initialRoute-java.lang.String-)
  /// method of the [FlutterActivity](/javadoc/io/flutter/embedding/android/FlutterActivity.html)'s
  /// intent builder.
  ///
  /// On a standalone engine, see https://flutter.dev/docs/development/add-to-app/android/add-flutter-screen#initial-route-with-a-cached-engine.
  ///
  /// ## iOS
  ///
  /// On iOS, the initial route can be set on the `initialRoute`
  /// parameter of the [FlutterViewController](/objcdoc/Classes/FlutterViewController.html)'s
  /// initializer.
  ///
  /// On a standalone engine, see https://flutter.dev/docs/development/add-to-app/ios/add-flutter-screen#route.
  ///
  /// See also:
  ///
  ///  * [Navigator], a widget that handles routing.
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests from the embedder.
  String get defaultRouteName => _defaultRouteName();
  String _defaultRouteName() native 'PlatformConfiguration_defaultRouteName';

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame]
  /// and [onDrawFrame] callbacks be invoked.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  void scheduleFrame() native 'PlatformConfiguration_scheduleFrame';

  /// Updates the application's rendering on the GPU with the newly provided
  /// [Scene]. This function must be called within the scope of the
  /// [onBeginFrame] or [onDrawFrame] callbacks being invoked. If this function
  /// is called a second time during a single [onBeginFrame]/[onDrawFrame]
  /// callback sequence or called outside the scope of those callbacks, the call
  /// will be ignored.
  ///
  /// To record graphical operations, first create a [PictureRecorder], then
  /// construct a [Canvas], passing that [PictureRecorder] to its constructor.
  /// After issuing all the graphical operations, call the
  /// [PictureRecorder.endRecording] function on the [PictureRecorder] to obtain
  /// the final [Picture] that represents the issued graphical operations.
  ///
  /// Next, create a [SceneBuilder], and add the [Picture] to it using
  /// [SceneBuilder.addPicture]. With the [SceneBuilder.build] method you can
  /// then obtain a [Scene] object, which you can display to the user via this
  /// [render] function.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  ///  * [RendererBinding], the Flutter framework class which manages layout and
  ///    painting.
  void render(Scene scene) native 'PlatformConfiguration_render';

  /// Whether the user has requested that [updateSemantics] be called when
  /// the semantic contents of window changes.
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  bool get semanticsEnabled => _semanticsEnabled;
  bool _semanticsEnabled = false;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onSemanticsEnabledChanged => _onSemanticsEnabledChanged;
  VoidCallback? _onSemanticsEnabledChanged;
  Zone _onSemanticsEnabledChangedZone = Zone.root;
  set onSemanticsEnabledChanged(VoidCallback? callback) {
    _onSemanticsEnabledChanged = callback;
    _onSemanticsEnabledChangedZone = Zone.current;
  }

  /// A callback that is invoked whenever the user requests an action to be
  /// performed.
  ///
  /// This callback is used when the user expresses the action they wish to
  /// perform based on the semantics supplied by [updateSemantics].
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  SemanticsActionCallback? get onSemanticsAction => _onSemanticsAction;
  SemanticsActionCallback? _onSemanticsAction;
  Zone _onSemanticsActionZone = Zone.root;
  set onSemanticsAction(SemanticsActionCallback? callback) {
    _onSemanticsAction = callback;
    _onSemanticsActionZone = Zone.current;
  }

  /// Additional accessibility features that may be enabled by the platform.
  AccessibilityFeatures get accessibilityFeatures => _accessibilityFeatures;
  // The zero value matches the default value in `platform_data.h`.
  AccessibilityFeatures _accessibilityFeatures = const AccessibilityFeatures._(0);

  /// A callback that is invoked when the value of [accessibilityFeatures] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback? get onAccessibilityFeaturesChanged => _onAccessibilityFeaturesChanged;
  VoidCallback? _onAccessibilityFeaturesChanged;
  Zone _onAccessibilityFeaturesChangedZone = Zone.root;
  set onAccessibilityFeaturesChanged(VoidCallback? callback) {
    _onAccessibilityFeaturesChanged = callback;
    _onAccessibilityFeaturesChangedZone = Zone.current;
  }

  /// Change the retained semantics data about this window.
  ///
  /// If [semanticsEnabled] is true, the user has requested that this function
  /// be called whenever the semantic content of this window changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) native 'PlatformConfiguration_updateSemantics';

  /// Set the debug name associated with this window's root isolate.
  ///
  /// Normally debug names are automatically generated from the Dart port, entry
  /// point, and source file. For example: `main.dart$main-1234`.
  ///
  /// This can be combined with flutter tools `--isolate-filter` flag to debug
  /// specific root isolates. For example: `flutter attach --isolate-filter=[name]`.
  /// Note that this does not rename any child isolates of the root.
  void setIsolateDebugName(String name) native 'PlatformConfiguration_setIsolateDebugName';

  /// Sends a message to a platform-specific plugin.
  ///
  /// The `name` parameter determines which plugin receives the message. The
  /// `data` parameter contains the message payload and is typically UTF-8
  /// encoded JSON but can be arbitrary data. If the plugin replies to the
  /// message, `callback` will be called with the response.
  ///
  /// The framework invokes [callback] in the same zone in which this method
  /// was called.
  void sendPlatformMessage(String name,
                           ByteData? data,
                           PlatformMessageResponseCallback? callback) {
    final String? error =
        _sendPlatformMessage(name, _zonedPlatformMessageResponseCallback(callback), data);
    if (error != null)
      throw Exception(error);
  }
  String? _sendPlatformMessage(String name,
                              PlatformMessageResponseCallback? callback,
                              ByteData? data) native 'PlatformConfiguration_sendPlatformMessage';

  /// Called whenever this window receives a message from a platform-specific
  /// plugin.
  ///
  /// The `name` parameter determines which plugin sent the message. The `data`
  /// parameter is the payload and is typically UTF-8 encoded JSON but can be
  /// arbitrary data.
  ///
  /// Message handlers must call the function given in the `callback` parameter.
  /// If the handler does not need to respond, the handler should pass null to
  /// the callback.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  PlatformMessageCallback? get onPlatformMessage => _onPlatformMessage;
  PlatformMessageCallback? _onPlatformMessage;
  Zone _onPlatformMessageZone = Zone.root;
  set onPlatformMessage(PlatformMessageCallback? callback) {
    _onPlatformMessage = callback;
    _onPlatformMessageZone = Zone.current;
  }

  /// Called by [_dispatchPlatformMessage].
  void _respondToPlatformMessage(int responseId, ByteData? data)
      native 'PlatformConfiguration_respondToPlatformMessage';

  /// Wraps the given [callback] in another callback that ensures that the
  /// original callback is called in the zone it was registered in.
  static PlatformMessageResponseCallback? _zonedPlatformMessageResponseCallback(PlatformMessageResponseCallback? callback) {
    if (callback == null)
      return null;

    // Store the zone in which the callback is being registered.
    final Zone registrationZone = Zone.current;

    return (ByteData? data) {
      registrationZone.runUnaryGuarded(callback, data);
    };
  }


  /// The embedder can specify data that the isolate can request synchronously
  /// on launch. This accessor fetches that data.
  ///
  /// This data is persistent for the duration of the Flutter application and is
  /// available even after isolate restarts. Because of this lifecycle, the size
  /// of this data must be kept to a minimum.
  ///
  /// For asynchronous communication between the embedder and isolate, a
  /// platform channel may be used.
  ByteData? getPersistentIsolateData() native 'PlatformConfiguration_getPersistentIsolateData';
}

/// Additional accessibility features that may be enabled by the platform.
///
/// It is not possible to enable these settings from Flutter, instead they are
/// used by the platform to indicate that additional accessibility features are
/// enabled.
//
// When changes are made to this class, the equivalent APIs in each of the
// embedders *must* be updated.
class AccessibilityFeatures {
  const AccessibilityFeatures._(this._index);

  static const int _kAccessibleNavigation = 1 << 0;
  static const int _kInvertColorsIndex = 1 << 1;
  static const int _kDisableAnimationsIndex = 1 << 2;
  static const int _kBoldTextIndex = 1 << 3;
  static const int _kReduceMotionIndex = 1 << 4;
  static const int _kHighContrastIndex = 1 << 5;

  // A bitfield which represents each enabled feature.
  final int _index;

  /// Whether there is a running accessibility service which is changing the
  /// interaction model of the device.
  ///
  /// For example, TalkBack on Android and VoiceOver on iOS enable this flag.
  bool get accessibleNavigation => _kAccessibleNavigation & _index != 0;

  /// The platform is inverting the colors of the application.
  bool get invertColors => _kInvertColorsIndex & _index != 0;

  /// The platform is requesting that animations be disabled or simplified.
  bool get disableAnimations => _kDisableAnimationsIndex & _index != 0;

  /// The platform is requesting that text be rendered at a bold font weight.
  ///
  /// Only supported on iOS.
  bool get boldText => _kBoldTextIndex & _index != 0;

  /// The platform is requesting that certain animations be simplified and
  /// parallax effects removed.
  ///
  /// Only supported on iOS.
  bool get reduceMotion => _kReduceMotionIndex & _index != 0;

  /// The platform is requesting that UI be rendered with darker colors.
  ///
  /// Only supported on iOS.
  bool get highContrast => _kHighContrastIndex & _index != 0;

  @override
  String toString() {
    final List<String> features = <String>[];
    if (accessibleNavigation)
      features.add('accessibleNavigation');
    if (invertColors)
      features.add('invertColors');
    if (disableAnimations)
      features.add('disableAnimations');
    if (boldText)
      features.add('boldText');
    if (reduceMotion)
      features.add('reduceMotion');
    if (highContrast)
      features.add('highContrast');
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is AccessibilityFeatures
        && other._index == _index;
  }

  @override
  int get hashCode => _index.hashCode;
}

/// Describes the contrast of a theme or color palette.
enum Brightness {
  /// The color is dark and will require a light text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be dark grey, requiring white text.
  dark,

  /// The color is light and will require a dark text color to achieve readable
  /// contrast.
  ///
  /// For example, the color might be bright white, requiring black text.
  light,
}

/// The [Window] singleton.
///
/// Please try to avoid statically referencing this and instead use a
/// binding for dependency resolution such as `WidgetsBinding.instance.window`.
///
/// Static access of this "window" object means that Flutter has few, if any
/// options to fake or mock the given object in tests. Even in cases where Dart
/// offers special language constructs to forcefully shadow such properties,
/// those mechanisms would only be reasonable for tests and they would not be
/// reasonable for a future of Flutter where we legitimately want to select an
/// appropriate implementation at runtime.
///
/// The only place that `WidgetsBinding.instance.window` is inappropriate is if
/// a `Window` is required before invoking `runApp()`. In that case, it is
/// acceptable (though unfortunate) to use this object statically.
final Window window = Window._();

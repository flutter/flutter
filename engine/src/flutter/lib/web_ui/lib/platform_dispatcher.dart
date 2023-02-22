// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

typedef VoidCallback = void Function();
typedef FrameCallback = void Function(Duration duration);
typedef TimingsCallback = void Function(List<FrameTiming> timings);
typedef PointerDataPacketCallback = void Function(PointerDataPacket packet);
typedef KeyDataCallback = bool Function(KeyData data);
typedef SemanticsActionCallback = void Function(int nodeId, SemanticsAction action, ByteData? args);
typedef PlatformMessageResponseCallback = void Function(ByteData? data);
typedef PlatformMessageCallback = void Function(
    String name, ByteData? data, PlatformMessageResponseCallback? callback);
typedef PlatformConfigurationChangedCallback = void Function(PlatformConfiguration configuration);
typedef ErrorCallback = bool Function(Object exception, StackTrace stackTrace);

// ignore: avoid_classes_with_only_static_members
/// A token that represents a root isolate.
class RootIsolateToken {
  static RootIsolateToken? get instance {
    throw UnsupportedError('Root isolate not identifiable on web.');
  }
}

abstract class PlatformDispatcher {
  static PlatformDispatcher get instance => engine.EnginePlatformDispatcher.instance;

  PlatformConfiguration get configuration;
  VoidCallback? get onPlatformConfigurationChanged;
  set onPlatformConfigurationChanged(VoidCallback? callback);

  Iterable<FlutterView> get views;

  FlutterView? get implicitView;

  VoidCallback? get onMetricsChanged;
  set onMetricsChanged(VoidCallback? callback);

  FrameCallback? get onBeginFrame;
  set onBeginFrame(FrameCallback? callback);

  VoidCallback? get onDrawFrame;
  set onDrawFrame(VoidCallback? callback);

  PointerDataPacketCallback? get onPointerDataPacket;
  set onPointerDataPacket(PointerDataPacketCallback? callback);

  KeyDataCallback? get onKeyData;
  set onKeyData(KeyDataCallback? callback);

  TimingsCallback? get onReportTimings;
  set onReportTimings(TimingsCallback? callback);

  void sendPlatformMessage(
      String name,
      ByteData? data,
      PlatformMessageResponseCallback? callback,
  );

  void sendPortPlatformMessage(
    String name,
    ByteData? data,
    int identifier,
    Object port);

  void registerBackgroundIsolate(RootIsolateToken token);

  PlatformMessageCallback? get onPlatformMessage;
  set onPlatformMessage(PlatformMessageCallback? callback);

  void setIsolateDebugName(String name) {}

  void requestDartPerformanceMode(DartPerformanceMode mode) {}

  ByteData? getPersistentIsolateData() => null;

  void scheduleFrame();

  void render(Scene scene, [FlutterView view]);

  AccessibilityFeatures get accessibilityFeatures;

  VoidCallback? get onAccessibilityFeaturesChanged;
  set onAccessibilityFeaturesChanged(VoidCallback? callback);

  @Deprecated('''
    In a multi-view world, the platform dispatcher can no longer provide apis
    to update semantics since each view will host its own semantics tree.

    Semantics updates must be passed to an individual [FlutterView]. To update
    semantics, use PlatformDispatcher.instance.views to get a [FlutterView] and
    call `updateSemantics`.
  ''')
  void updateSemantics(SemanticsUpdate update);

  Locale get locale;

  List<Locale> get locales => configuration.locales;

  Locale? computePlatformResolvedLocale(List<Locale> supportedLocales);

  VoidCallback? get onLocaleChanged;
  set onLocaleChanged(VoidCallback? callback);

  String get initialLifecycleState => 'AppLifecycleState.resumed';

  bool get alwaysUse24HourFormat => configuration.alwaysUse24HourFormat;

  double get textScaleFactor => configuration.textScaleFactor;

  bool get nativeSpellCheckServiceDefined => false;

  bool get brieflyShowPassword => true;

  VoidCallback? get onTextScaleFactorChanged;
  set onTextScaleFactorChanged(VoidCallback? callback);

  Brightness get platformBrightness => configuration.platformBrightness;

  VoidCallback? get onPlatformBrightnessChanged;
  set onPlatformBrightnessChanged(VoidCallback? callback);

  String? get systemFontFamily => configuration.systemFontFamily;

  VoidCallback? get onSystemFontFamilyChanged;
  set onSystemFontFamilyChanged(VoidCallback? callback);

  bool get semanticsEnabled => configuration.semanticsEnabled;

  VoidCallback? get onSemanticsEnabledChanged;
  set onSemanticsEnabledChanged(VoidCallback? callback);

  SemanticsActionCallback? get onSemanticsAction;
  set onSemanticsAction(SemanticsActionCallback? callback);

  ErrorCallback? get onError;
  set onError(ErrorCallback? callback);

  String get defaultRouteName;

  FrameData get frameData;

  VoidCallback? get onFrameDataChanged => null;
  set onFrameDataChanged(VoidCallback? callback) {}
}

class PlatformConfiguration {
  const PlatformConfiguration({
    this.accessibilityFeatures = const engine.EngineAccessibilityFeatures(0),
    this.alwaysUse24HourFormat = false,
    this.semanticsEnabled = false,
    this.platformBrightness = Brightness.light,
    this.textScaleFactor = 1.0,
    this.locales = const <Locale>[],
    this.defaultRouteName = '/',
    this.systemFontFamily,
  });

  PlatformConfiguration copyWith({
    AccessibilityFeatures? accessibilityFeatures,
    bool? alwaysUse24HourFormat,
    bool? semanticsEnabled,
    Brightness? platformBrightness,
    double? textScaleFactor,
    List<Locale>? locales,
    String? defaultRouteName,
    String? systemFontFamily,
  }) {
    return PlatformConfiguration(
      accessibilityFeatures: accessibilityFeatures ?? this.accessibilityFeatures,
      alwaysUse24HourFormat: alwaysUse24HourFormat ?? this.alwaysUse24HourFormat,
      semanticsEnabled: semanticsEnabled ?? this.semanticsEnabled,
      platformBrightness: platformBrightness ?? this.platformBrightness,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      locales: locales ?? this.locales,
      defaultRouteName: defaultRouteName ?? this.defaultRouteName,
      systemFontFamily: systemFontFamily ?? this.systemFontFamily,
    );
  }

  final AccessibilityFeatures accessibilityFeatures;
  final bool alwaysUse24HourFormat;
  final bool semanticsEnabled;
  final Brightness platformBrightness;
  final double textScaleFactor;
  final List<Locale> locales;
  final String defaultRouteName;
  final String? systemFontFamily;
}

class ViewConfiguration {
  const ViewConfiguration({
    FlutterView? view,
    @Deprecated('''
      Use the `view` property instead.
      This change is related to adding multi-view support in Flutter.
      This feature was deprecated after 3.7.0-1.2.pre.
    ''')
    FlutterView? window,
    this.devicePixelRatio = 1.0,
    this.geometry = Rect.zero,
    this.visible = false,
    this.viewInsets = ViewPadding.zero,
    this.viewPadding = ViewPadding.zero,
    this.systemGestureInsets = ViewPadding.zero,
    this.padding = ViewPadding.zero,
    this.gestureSettings = const GestureSettings(),
    this.displayFeatures = const <DisplayFeature>[],
  }) : assert(window == null || view == null),
  _view = view ?? window;

  ViewConfiguration copyWith({
    FlutterView? view,
    @Deprecated('''
      Use the `view` property instead.
      This change is related to adding multi-view support in Flutter.
      This feature was deprecated after 3.7.0-1.2.pre.
    ''')
    FlutterView? window,
    double? devicePixelRatio,
    Rect? geometry,
    bool? visible,
    ViewPadding? viewInsets,
    ViewPadding? viewPadding,
    ViewPadding? systemGestureInsets,
    ViewPadding? padding,
    GestureSettings? gestureSettings,
    List<DisplayFeature>? displayFeatures,
  }) {
    assert(view == null || window == null);
    return ViewConfiguration(
      view: view ?? window ?? _view,
      devicePixelRatio: devicePixelRatio ?? this.devicePixelRatio,
      geometry: geometry ?? this.geometry,
      visible: visible ?? this.visible,
      viewInsets: viewInsets ?? this.viewInsets,
      viewPadding: viewPadding ?? this.viewPadding,
      systemGestureInsets: systemGestureInsets ?? this.systemGestureInsets,
      padding: padding ?? this.padding,
      gestureSettings: gestureSettings ?? this.gestureSettings,
      displayFeatures: displayFeatures ?? this.displayFeatures,
    );
  }

  @Deprecated('''
    Use the `view` property instead.
    This change is related to adding multi-view support in Flutter.
    This feature was deprecated after 3.7.0-1.2.pre.
  ''')
  FlutterView? get window => _view;
  FlutterView? get view => _view;
  final FlutterView? _view;
  final double devicePixelRatio;
  final Rect geometry;
  final bool visible;
  final ViewPadding viewInsets;
  final ViewPadding viewPadding;
  final ViewPadding systemGestureInsets;
  final ViewPadding padding;
  final GestureSettings gestureSettings;
  final List<DisplayFeature> displayFeatures;

  @override
  String toString() {
    return '$runtimeType[view: $view, geometry: $geometry]';
  }
}

enum FramePhase {
  vsyncStart,
  buildStart,
  buildFinish,
  rasterStart,
  rasterFinish,
  rasterFinishWallTime,
}

enum _FrameTimingInfo {
  layerCacheCount,
  layerCacheBytes,
  pictureCacheCount,
  pictureCacheBytes,
  frameNumber,
}

class FrameTiming {
  factory FrameTiming({
    required int vsyncStart,
    required int buildStart,
    required int buildFinish,
    required int rasterStart,
    required int rasterFinish,
    required int rasterFinishWallTime,
    int layerCacheCount = 0,
    int layerCacheBytes = 0,
    int pictureCacheCount = 0,
    int pictureCacheBytes = 0,
    int frameNumber = 1,
  }) {
    return FrameTiming._(<int>[
      vsyncStart,
      buildStart,
      buildFinish,
      rasterStart,
      rasterFinish,
      rasterFinishWallTime,
      layerCacheCount,
      layerCacheBytes,
      pictureCacheCount,
      pictureCacheBytes,
      frameNumber,
    ]);
  }

  FrameTiming._(this._data)
      : assert(_data.length == _dataLength);

  static final int _dataLength = FramePhase.values.length + _FrameTimingInfo.values.length;

  int timestampInMicroseconds(FramePhase phase) => _data[phase.index];

  Duration _rawDuration(FramePhase phase) => Duration(microseconds: _data[phase.index]);

  int _rawInfo(_FrameTimingInfo info) => _data[FramePhase.values.length + info.index];

  Duration get buildDuration =>
      _rawDuration(FramePhase.buildFinish) - _rawDuration(FramePhase.buildStart);

  Duration get rasterDuration =>
      _rawDuration(FramePhase.rasterFinish) - _rawDuration(FramePhase.rasterStart);

  Duration get vsyncOverhead => _rawDuration(FramePhase.buildStart) - _rawDuration(FramePhase.vsyncStart);

  Duration get totalSpan =>
      _rawDuration(FramePhase.rasterFinish) - _rawDuration(FramePhase.vsyncStart);

  int get layerCacheCount => _rawInfo(_FrameTimingInfo.layerCacheCount);

  int get layerCacheBytes => _rawInfo(_FrameTimingInfo.layerCacheBytes);

  double get layerCacheMegabytes => layerCacheBytes / 1024.0 / 1024.0;

  int get pictureCacheCount => _rawInfo(_FrameTimingInfo.pictureCacheCount);

  int get pictureCacheBytes => _rawInfo(_FrameTimingInfo.pictureCacheBytes);

  double get pictureCacheMegabytes => pictureCacheBytes / 1024.0 / 1024.0;

  int get frameNumber => _data.last;

  final List<int> _data;  // some elements in microseconds, some in bytes, some are counts

  String _formatMS(Duration duration) => '${duration.inMicroseconds * 0.001}ms';

  @override
  String toString() {
    return '$runtimeType(buildDuration: ${_formatMS(buildDuration)}, '
        'rasterDuration: ${_formatMS(rasterDuration)}, '
        'vsyncOverhead: ${_formatMS(vsyncOverhead)}, '
        'totalSpan: ${_formatMS(totalSpan)}, '
        'layerCacheCount: $layerCacheCount, '
        'layerCacheBytes: $layerCacheBytes, '
        'pictureCacheCount: $pictureCacheCount, '
        'pictureCacheBytes: $pictureCacheBytes, '
        'frameNumber: ${_data.last})';
  }
}

enum AppLifecycleState {
  resumed,
  inactive,
  paused,
  detached,
}

abstract class ViewPadding {
  const factory ViewPadding._(
      {required double left,
      required double top,
      required double right,
      required double bottom}) = engine.ViewPadding;

  double get left;
  double get top;
  double get right;
  double get bottom;

  static const ViewPadding zero = ViewPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);

  @override
  String toString() {
    return 'ViewPadding(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}

@Deprecated(
  'Use ViewPadding instead. '
  'This feature was deprecated after v3.8.0-14.0.pre.',
)
typedef WindowPadding = ViewPadding;

class DisplayFeature {
  const DisplayFeature({
    required this.bounds,
    required this.type,
    required this.state,
  });

  final Rect bounds;
  final DisplayFeatureType type;
  final DisplayFeatureState state;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is DisplayFeature && bounds == other.bounds &&
        type == other.type && state == other.state;
  }

  @override
  int get hashCode => Object.hash(bounds, type, state);

  @override
  String toString() {
    return 'DisplayFeature(rect: $bounds, type: $type, state: $state)';
  }
}

enum DisplayFeatureType {
  unknown,
  fold,
  hinge,
  cutout,
}

enum DisplayFeatureState {
  unknown,
  postureFlat,
  postureHalfOpened,
  postureFlipped,
}

class Locale {
  const Locale(
    this._languageCode, [
    this._countryCode,
  ])  : assert(_languageCode != ''),
        scriptCode = null;

  const Locale.fromSubtags({
    String languageCode = 'und',
    this.scriptCode,
    String? countryCode,
  })  : assert(languageCode != ''),
        _languageCode = languageCode,
        assert(scriptCode != ''),
        assert(countryCode != ''),
        _countryCode = countryCode;

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

  final String? scriptCode;

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
    if (identical(this, other)) {
      return true;
    }
    return other is Locale
        && other.languageCode == languageCode
        && other.scriptCode == scriptCode
        && other.countryCode == countryCode;
  }

  @override
  int get hashCode => Object.hash(languageCode, scriptCode, countryCode);

  @override
  String toString() => _rawToString('_');

  // TODO(yjbanov): implement to match flutter native.
  String toLanguageTag() => _rawToString('-');

  String _rawToString(String separator) {
    final StringBuffer out = StringBuffer(languageCode);
    if (scriptCode != null) {
      out.write('$separator$scriptCode');
    }
    if (_countryCode != null) {
      out.write('$separator$countryCode');
    }
    return out.toString();
  }
}

enum DartPerformanceMode {
  balanced,
  latency,
  throughput,
  memory,
}

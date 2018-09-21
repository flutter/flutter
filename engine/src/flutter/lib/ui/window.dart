// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of dart.ui;

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Signature for [Window.onBeginFrame].
typedef FrameCallback = void Function(Duration duration);

/// Signature for [Window.onPointerDataPacket].
typedef PointerDataPacketCallback = void Function(PointerDataPacket packet);

/// Signature for [Window.onSemanticsAction].
typedef SemanticsActionCallback = void Function(int id, SemanticsAction action, ByteData args);

/// Signature for responses to platform messages.
///
/// Used as a parameter to [Window.sendPlatformMessage] and
/// [Window.onPlatformMessage].
typedef PlatformMessageResponseCallback = void Function(ByteData data);

/// Signature for [Window.onPlatformMessage].
typedef PlatformMessageCallback = void Function(String name, ByteData data, PlatformMessageResponseCallback callback);

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
  ///
  /// Android apps in this state should assume that they may enter the
  /// [suspending] state at any time.
  paused,

  /// The application will be suspended momentarily.
  ///
  /// When the application is in this state, the engine will not call the
  /// [Window.onBeginFrame] and [Window.onDrawFrame] callbacks.
  ///
  /// On iOS, this state is currently unused.
  suspending,
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
  const WindowPadding._({ this.left, this.top, this.right, this.bottom });

  /// The distance from the left edge to the first unpadded pixel, in physical pixels.
  final double left;

  /// The distance from the top edge to the first unpadded pixel, in physical pixels.
  final double top;

  /// The distance from the right edge to the first unpadded pixel, in physical pixels.
  final double right;

  /// The distance from the bottom edge to the first unpadded pixel, in physical pixels.
  final double bottom;

  /// A window padding that has zeros for each edge.
  static const WindowPadding zero = const WindowPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);

  @override
  String toString() {
    return '$runtimeType(left: $left, top: $top, right: $right, bottom: $bottom)';
  }
}

/// An identifier used to select a user's language and formatting preferences,
/// consisting of a language and a country. This is a subset of locale
/// identifiers as defined by BCP 47.
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
  /// primary language subtag, the second is the region subtag.
  ///
  /// For example:
  ///
  /// ```dart
  /// const Locale swissFrench = const Locale('fr', 'CH');
  /// const Locale canadianFrench = const Locale('fr', 'CA');
  /// ```
  ///
  /// The primary language subtag must not be null. The region subtag is
  /// optional.
  ///
  /// The values are _case sensitive_, and should match the case of the relevant
  /// subtags in the [IANA Language Subtag
  /// Registry](https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry).
  /// Typically this means the primary language subtag should be lowercase and
  /// the region subtag should be uppercase.
  const Locale(this._languageCode, [ this._countryCode ]) : assert(_languageCode != null);

  /// The primary language subtag for the locale.
  ///
  /// This must not be null.
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
  String get languageCode => _canonicalizeLanguageCode(_languageCode);
  final String _languageCode;

  static String _canonicalizeLanguageCode(String languageCode) {
    // This switch statement is generated by //flutter/tools/gen_locale.dart
    // Mappings generated for language subtag registry as of 2018-08-08.
    switch (languageCode) {
      case 'in': return 'id'; // Indonesian; deprecated 1989-01-01
      case 'iw': return 'he'; // Hebrew; deprecated 1989-01-01
      case 'ji': return 'yi'; // Yiddish; deprecated 1989-01-01
      case 'jw': return 'jv'; // Javanese; deprecated 2001-08-13
      case 'mo': return 'ro'; // Moldavian, Moldovan; deprecated 2008-11-22
      case 'aam': return 'aas'; // Aramanik; deprecated 2015-02-12
      case 'adp': return 'dz'; // Adap; deprecated 2015-02-12
      case 'aue': return 'ktz'; // =/Kx'au//'ein; deprecated 2015-02-12
      case 'ayx': return 'nun'; // Ayi (China); deprecated 2011-08-16
      case 'bgm': return 'bcg'; // Baga Mboteni; deprecated 2016-05-30
      case 'bjd': return 'drl'; // Bandjigali; deprecated 2012-08-12
      case 'ccq': return 'rki'; // Chaungtha; deprecated 2012-08-12
      case 'cjr': return 'mom'; // Chorotega; deprecated 2010-03-11
      case 'cka': return 'cmr'; // Khumi Awa Chin; deprecated 2012-08-12
      case 'cmk': return 'xch'; // Chimakum; deprecated 2010-03-11
      case 'coy': return 'pij'; // Coyaima; deprecated 2016-05-30
      case 'cqu': return 'quh'; // Chilean Quechua; deprecated 2016-05-30
      case 'drh': return 'khk'; // Darkhat; deprecated 2010-03-11
      case 'drw': return 'prs'; // Darwazi; deprecated 2010-03-11
      case 'gav': return 'dev'; // Gabutamon; deprecated 2010-03-11
      case 'gfx': return 'vaj'; // Mangetti Dune !Xung; deprecated 2015-02-12
      case 'ggn': return 'gvr'; // Eastern Gurung; deprecated 2016-05-30
      case 'gti': return 'nyc'; // Gbati-ri; deprecated 2015-02-12
      case 'guv': return 'duz'; // Gey; deprecated 2016-05-30
      case 'hrr': return 'jal'; // Horuru; deprecated 2012-08-12
      case 'ibi': return 'opa'; // Ibilo; deprecated 2012-08-12
      case 'ilw': return 'gal'; // Talur; deprecated 2013-09-10
      case 'jeg': return 'oyb'; // Jeng; deprecated 2017-02-23
      case 'kgc': return 'tdf'; // Kasseng; deprecated 2016-05-30
      case 'kgh': return 'kml'; // Upper Tanudan Kalinga; deprecated 2012-08-12
      case 'koj': return 'kwv'; // Sara Dunjo; deprecated 2015-02-12
      case 'krm': return 'bmf'; // Krim; deprecated 2017-02-23
      case 'ktr': return 'dtp'; // Kota Marudu Tinagas; deprecated 2016-05-30
      case 'kvs': return 'gdj'; // Kunggara; deprecated 2016-05-30
      case 'kwq': return 'yam'; // Kwak; deprecated 2015-02-12
      case 'kxe': return 'tvd'; // Kakihum; deprecated 2015-02-12
      case 'kzj': return 'dtp'; // Coastal Kadazan; deprecated 2016-05-30
      case 'kzt': return 'dtp'; // Tambunan Dusun; deprecated 2016-05-30
      case 'lii': return 'raq'; // Lingkhim; deprecated 2015-02-12
      case 'lmm': return 'rmx'; // Lamam; deprecated 2014-02-28
      case 'meg': return 'cir'; // Mea; deprecated 2013-09-10
      case 'mst': return 'mry'; // Cataelano Mandaya; deprecated 2010-03-11
      case 'mwj': return 'vaj'; // Maligo; deprecated 2015-02-12
      case 'myt': return 'mry'; // Sangab Mandaya; deprecated 2010-03-11
      case 'nad': return 'xny'; // Nijadali; deprecated 2016-05-30
      case 'ncp': return 'kdz'; // Ndaktup; deprecated 2018-03-08
      case 'nnx': return 'ngv'; // Ngong; deprecated 2015-02-12
      case 'nts': return 'pij'; // Natagaimas; deprecated 2016-05-30
      case 'oun': return 'vaj'; // !O!ung; deprecated 2015-02-12
      case 'pcr': return 'adx'; // Panang; deprecated 2013-09-10
      case 'pmc': return 'huw'; // Palumata; deprecated 2016-05-30
      case 'pmu': return 'phr'; // Mirpur Panjabi; deprecated 2015-02-12
      case 'ppa': return 'bfy'; // Pao; deprecated 2016-05-30
      case 'ppr': return 'lcq'; // Piru; deprecated 2013-09-10
      case 'pry': return 'prt'; // Pray 3; deprecated 2016-05-30
      case 'puz': return 'pub'; // Purum Naga; deprecated 2014-02-28
      case 'sca': return 'hle'; // Sansu; deprecated 2012-08-12
      case 'skk': return 'oyb'; // Sok; deprecated 2017-02-23
      case 'tdu': return 'dtp'; // Tempasuk Dusun; deprecated 2016-05-30
      case 'thc': return 'tpo'; // Tai Hang Tong; deprecated 2016-05-30
      case 'thx': return 'oyb'; // The; deprecated 2015-02-12
      case 'tie': return 'ras'; // Tingal; deprecated 2011-08-16
      case 'tkk': return 'twm'; // Takpa; deprecated 2011-08-16
      case 'tlw': return 'weo'; // South Wemale; deprecated 2012-08-12
      case 'tmp': return 'tyj'; // Tai Mène; deprecated 2016-05-30
      case 'tne': return 'kak'; // Tinoc Kallahan; deprecated 2016-05-30
      case 'tnf': return 'prs'; // Tangshewi; deprecated 2010-03-11
      case 'tsf': return 'taj'; // Southwestern Tamang; deprecated 2015-02-12
      case 'uok': return 'ema'; // Uokha; deprecated 2015-02-12
      case 'xba': return 'cax'; // Kamba (Brazil); deprecated 2016-05-30
      case 'xia': return 'acn'; // Xiandao; deprecated 2013-09-10
      case 'xkh': return 'waw'; // Karahawyana; deprecated 2016-05-30
      case 'xsj': return 'suj'; // Subi; deprecated 2015-02-12
      case 'ybd': return 'rki'; // Yangbye; deprecated 2012-08-12
      case 'yma': return 'lrr'; // Yamphe; deprecated 2012-08-12
      case 'ymt': return 'mtm'; // Mator-Taygi-Karagas; deprecated 2015-02-12
      case 'yos': return 'zom'; // Yos; deprecated 2013-09-10
      case 'yuu': return 'yug'; // Yugh; deprecated 2014-02-28
      default: return languageCode;
    }
  }

  /// The region subtag for the locale.
  ///
  /// This can be null.
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
  String get countryCode => _canonicalizeRegionCode(_countryCode);
  final String _countryCode;

  static String _canonicalizeRegionCode(String regionCode) {
    // This switch statement is generated by //flutter/tools/gen_locale.dart
    // Mappings generated for language subtag registry as of 2018-08-08.
    switch (regionCode) {
      case 'BU': return 'MM'; // Burma; deprecated 1989-12-05
      case 'DD': return 'DE'; // German Democratic Republic; deprecated 1990-10-30
      case 'FX': return 'FR'; // Metropolitan France; deprecated 1997-07-14
      case 'TP': return 'TL'; // East Timor; deprecated 2002-05-20
      case 'YD': return 'YE'; // Democratic Yemen; deprecated 1990-08-14
      case 'ZR': return 'CD'; // Zaire; deprecated 1997-07-14
      default: return regionCode;
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! Locale)
      return false;
    final Locale typedOther = other;
    return languageCode == typedOther.languageCode
        && countryCode == typedOther.countryCode;
  }

  @override
  int get hashCode {
    int result = 373;
    result = 37 * result + languageCode.hashCode;
    if (_countryCode != null)
      result = 37 * result + countryCode.hashCode;
    return result;
  }

  @override
  String toString() {
    if (_countryCode == null)
      return languageCode;
    return '${languageCode}_$countryCode';
  }
}

/// The most basic interface to the host operating system's user interface.
///
/// There is a single Window instance in the system, which you can
/// obtain from the [window] property.
class Window {
  Window._();

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

  /// The number of physical pixels on each side of the display rectangle into
  /// which the application can render, but over which the operating system
  /// will likely place system UI, such as the keyboard, that fully obscures
  /// any content.
  ///
  /// When this changes, [onMetricsChanged] is called.
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
  /// When this changes, [onMetricsChanged] is called.
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
  /// [physicalSize], [padding], or [viewInsets] values change, for example
  /// when the device is rotated or when the application is resized (e.g. when
  /// showing applications side-by-side on Android).
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
  VoidCallback get onMetricsChanged => _onMetricsChanged;
  VoidCallback _onMetricsChanged;
  Zone _onMetricsChangedZone;
  set onMetricsChanged(VoidCallback callback) {
    _onMetricsChanged = callback;
    _onMetricsChangedZone = Zone.current;
  }

  /// The system-reported locale.
  ///
  /// This establishes the language and formatting conventions that application
  /// should, if possible, use to render their user interface.
  ///
  /// The [onLocaleChanged] callback is called whenever this value changes.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Locale get locale => _locale;
  Locale _locale;

  /// A callback that is invoked whenever [locale] changes value.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this callback is invoked.
  VoidCallback get onLocaleChanged => _onLocaleChanged;
  VoidCallback _onLocaleChanged;
  Zone _onLocaleChangedZone;
  set onLocaleChanged(VoidCallback callback) {
    _onLocaleChanged = callback;
    _onLocaleChangedZone = Zone.current;
  }

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
  VoidCallback get onTextScaleFactorChanged => _onTextScaleFactorChanged;
  VoidCallback _onTextScaleFactorChanged;
  Zone _onTextScaleFactorChangedZone;
  set onTextScaleFactorChanged(VoidCallback callback) {
    _onTextScaleFactorChanged = callback;
    _onTextScaleFactorChangedZone = Zone.current;
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
  FrameCallback get onBeginFrame => _onBeginFrame;
  FrameCallback _onBeginFrame;
  Zone _onBeginFrameZone;
  set onBeginFrame(FrameCallback callback) {
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
  VoidCallback get onDrawFrame => _onDrawFrame;
  VoidCallback _onDrawFrame;
  Zone _onDrawFrameZone;
  set onDrawFrame(VoidCallback callback) {
    _onDrawFrame = callback;
    _onDrawFrameZone = Zone.current;
  }

  /// A callback that is invoked when pointer data is available.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  ///
  /// See also:
  ///
  ///  * [GestureBinding], the Flutter framework class which manages pointer
  ///    events.
  PointerDataPacketCallback get onPointerDataPacket => _onPointerDataPacket;
  PointerDataPacketCallback _onPointerDataPacket;
  Zone _onPointerDataPacketZone;
  set onPointerDataPacket(PointerDataPacketCallback callback) {
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
  /// On Android, calling
  /// [`FlutterView.setInitialRoute`](/javadoc/io/flutter/view/FlutterView.html#setInitialRoute-java.lang.String-)
  /// will set this value. The value must be set sufficiently early, i.e. before
  /// the [runApp] call is executed in Dart, for this to have any effect on the
  /// framework. The `createFlutterView` method in your `FlutterActivity`
  /// subclass is a suitable time to set the value. The application's
  /// `AndroidManifest.xml` file must also be updated to have a suitable
  /// [`<intent-filter>`](https://developer.android.com/guide/topics/manifest/intent-filter-element.html).
  ///
  /// ## iOS
  ///
  /// On iOS, calling
  /// [`FlutterViewController.setInitialRoute`](/objcdoc/Classes/FlutterViewController.html#/c:objc%28cs%29FlutterViewController%28im%29setInitialRoute:)
  /// will set this value. The value must be set sufficiently early, i.e. before
  /// the [runApp] call is executed in Dart, for this to have any effect on the
  /// framework. The `application:didFinishLaunchingWithOptions:` method is a
  /// suitable time to set this value.
  ///
  /// See also:
  ///
  ///  * [Navigator], a widget that handles routing.
  ///  * [SystemChannels.navigation], which handles subsequent navigation
  ///    requests from the embedder.
  String get defaultRouteName => _defaultRouteName();
  String _defaultRouteName() native 'Window_defaultRouteName';

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame]
  /// and [onDrawFrame] callbacks be invoked.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  void scheduleFrame() native 'Window_scheduleFrame';

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
  void render(Scene scene) native 'Window_render';

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
  VoidCallback get onSemanticsEnabledChanged => _onSemanticsEnabledChanged;
  VoidCallback _onSemanticsEnabledChanged;
  Zone _onSemanticsEnabledChangedZone;
  set onSemanticsEnabledChanged(VoidCallback callback) {
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
  SemanticsActionCallback get onSemanticsAction => _onSemanticsAction;
  SemanticsActionCallback _onSemanticsAction;
  Zone _onSemanticsActionZone;
  set onSemanticsAction(SemanticsActionCallback callback) {
    _onSemanticsAction = callback;
    _onSemanticsActionZone = Zone.current;
  }

  /// Additional accessibility features that may be enabled by the platform.
  AccessibilityFeatures get accessibilityFeatures => _accessibilityFeatures;
  AccessibilityFeatures _accessibilityFeatures;

  /// A callback that is invoked when the value of [accessibilityFlags] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback get onAccessibilityFeaturesChanged => _onAccessibilityFeaturesChanged;
  VoidCallback _onAccessibilityFeaturesChanged;
  Zone _onAccessibilityFlagsChangedZone;
  set onAccessibilityFeaturesChanged(VoidCallback callback) {
    _onAccessibilityFeaturesChanged = callback;
    _onAccessibilityFlagsChangedZone = Zone.current;
  }

  /// Change the retained semantics data about this window.
  ///
  /// If [semanticsEnabled] is true, the user has requested that this funciton
  /// be called whenever the semantic content of this window changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) native 'Window_updateSemantics';

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
                           ByteData data,
                           PlatformMessageResponseCallback callback) {
    final String error =
        _sendPlatformMessage(name, _zonedPlatformMessageResponseCallback(callback), data);
    if (error != null)
      throw new Exception(error);
  }
  String _sendPlatformMessage(String name,
                              PlatformMessageResponseCallback callback,
                              ByteData data) native 'Window_sendPlatformMessage';

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
  PlatformMessageCallback get onPlatformMessage => _onPlatformMessage;
  PlatformMessageCallback _onPlatformMessage;
  Zone _onPlatformMessageZone;
  set onPlatformMessage(PlatformMessageCallback callback) {
    _onPlatformMessage = callback;
    _onPlatformMessageZone = Zone.current;
  }

  /// Called by [_dispatchPlatformMessage].
  void _respondToPlatformMessage(int responseId, ByteData data)
      native 'Window_respondToPlatformMessage';

  /// Wraps the given [callback] in another callback that ensures that the
  /// original callback is called in the zone it was registered in.
  static PlatformMessageResponseCallback _zonedPlatformMessageResponseCallback(PlatformMessageResponseCallback callback) {
    if (callback == null)
      return null;

    // Store the zone in which the callback is being registered.
    final Zone registrationZone = Zone.current;

    return (ByteData data) {
      registrationZone.runUnaryGuarded(callback, data);
    };
  }
}

/// Additional accessibility features that may be enabled by the platform.
///
/// It is not possible to enable these settings from Flutter, instead they are
/// used by the platform to indicate that additional accessibility features are
/// enabled.
class AccessibilityFeatures {
  const AccessibilityFeatures._(this._index);

  static const int _kAccessibleNavigation = 1 << 0;
  static const int _kInvertColorsIndex = 1 << 1;
  static const int _kDisableAnimationsIndex = 1 << 2;
  static const int _kBoldTextIndex = 1 << 3;
  static const int _kReduceMotionIndex = 1 << 4;

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
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final AccessibilityFeatures typedOther = other;
    return _index == typedOther._index;
  }

  @override
  int get hashCode => _index.hashCode;
}

/// The [Window] singleton. This object exposes the size of the display, the
/// core scheduler API, the input event callback, the graphics drawing API, and
/// other such core services.
final Window window = new Window._();

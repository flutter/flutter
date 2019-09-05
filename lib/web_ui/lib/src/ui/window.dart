// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Synced 2019-05-30T14:20:57.841444.

part of ui;

/// Signature of callbacks that have no arguments and return no data.
typedef VoidCallback = void Function();

/// Signature for frame-related callbacks from the scheduler.
///
/// The `timeStamp` is the number of milliseconds since the beginning of the
/// scheduler's epoch. Use timeStamp to determine how far to advance animation
/// timelines so that all the animations in the system are synchronized to a
/// common time base.
typedef FrameCallback = void Function(Duration duration);

/// Signature for [Window.onReportTimings].
typedef TimingsCallback = void Function(List<FrameTiming> timings);

/// Signature for [Window.onPointerDataPacket].
typedef PointerDataPacketCallback = void Function(PointerDataPacket packet);

/// Signature for [Window.onSemanticsAction].
typedef SemanticsActionCallback = void Function(
    int id, SemanticsAction action, ByteData args);

/// Signature for responses to platform messages.
///
/// Used as a parameter to [Window.sendPlatformMessage] and
/// [Window.onPlatformMessage].
typedef PlatformMessageResponseCallback = void Function(ByteData data);

/// Signature for [Window.onPlatformMessage].
typedef PlatformMessageCallback = void Function(
    String name, ByteData data, PlatformMessageResponseCallback callback);

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
  const WindowPadding._({this.left, this.top, this.right, this.bottom});

  /// The distance from the left edge to the first unpadded pixel, in physical
  /// pixels.
  final double left;

  /// The distance from the top edge to the first unpadded pixel, in physical
  /// pixels.
  final double top;

  /// The distance from the right edge to the first unpadded pixel, in physical
  /// pixels.
  final double right;

  /// The distance from the bottom edge to the first unpadded pixel, in physical
  /// pixels.
  final double bottom;

  /// A window padding that has zeros for each edge.
  static const WindowPadding zero =
      WindowPadding._(left: 0.0, top: 0.0, right: 0.0, bottom: 0.0);

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
  /// const Locale swissFrench = const Locale('fr', 'CH');
  /// const Locale canadianFrench = const Locale('fr', 'CA');
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
  ///  * [new Locale.fromSubtags], which also allows a [scriptCode] to be
  ///    specified.
  const Locale(
    this._languageCode, [
    this._countryCode,
  ])  : assert(_languageCode != null),
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
    String countryCode,
  })  : assert(languageCode != null),
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
  ///  * [new Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  String get languageCode => _replaceDeprecatedLanguageSubtag(_languageCode);
  final String _languageCode;

  static String _replaceDeprecatedLanguageSubtag(String languageCode) {
    // This switch statement is generated by //flutter/tools/gen_locale.dart
    // Mappings generated for language subtag registry as of 2018-08-08.
    switch (languageCode) {
      case 'in':
        return 'id'; // Indonesian; deprecated 1989-01-01
      case 'iw':
        return 'he'; // Hebrew; deprecated 1989-01-01
      case 'ji':
        return 'yi'; // Yiddish; deprecated 1989-01-01
      case 'jw':
        return 'jv'; // Javanese; deprecated 2001-08-13
      case 'mo':
        return 'ro'; // Moldavian, Moldovan; deprecated 2008-11-22
      case 'aam':
        return 'aas'; // Aramanik; deprecated 2015-02-12
      case 'adp':
        return 'dz'; // Adap; deprecated 2015-02-12
      case 'aue':
        return 'ktz'; // =/Kx'au//'ein; deprecated 2015-02-12
      case 'ayx':
        return 'nun'; // Ayi (China); deprecated 2011-08-16
      case 'bgm':
        return 'bcg'; // Baga Mboteni; deprecated 2016-05-30
      case 'bjd':
        return 'drl'; // Bandjigali; deprecated 2012-08-12
      case 'ccq':
        return 'rki'; // Chaungtha; deprecated 2012-08-12
      case 'cjr':
        return 'mom'; // Chorotega; deprecated 2010-03-11
      case 'cka':
        return 'cmr'; // Khumi Awa Chin; deprecated 2012-08-12
      case 'cmk':
        return 'xch'; // Chimakum; deprecated 2010-03-11
      case 'coy':
        return 'pij'; // Coyaima; deprecated 2016-05-30
      case 'cqu':
        return 'quh'; // Chilean Quechua; deprecated 2016-05-30
      case 'drh':
        return 'khk'; // Darkhat; deprecated 2010-03-11
      case 'drw':
        return 'prs'; // Darwazi; deprecated 2010-03-11
      case 'gav':
        return 'dev'; // Gabutamon; deprecated 2010-03-11
      case 'gfx':
        return 'vaj'; // Mangetti Dune !Xung; deprecated 2015-02-12
      case 'ggn':
        return 'gvr'; // Eastern Gurung; deprecated 2016-05-30
      case 'gti':
        return 'nyc'; // Gbati-ri; deprecated 2015-02-12
      case 'guv':
        return 'duz'; // Gey; deprecated 2016-05-30
      case 'hrr':
        return 'jal'; // Horuru; deprecated 2012-08-12
      case 'ibi':
        return 'opa'; // Ibilo; deprecated 2012-08-12
      case 'ilw':
        return 'gal'; // Talur; deprecated 2013-09-10
      case 'jeg':
        return 'oyb'; // Jeng; deprecated 2017-02-23
      case 'kgc':
        return 'tdf'; // Kasseng; deprecated 2016-05-30
      case 'kgh':
        return 'kml'; // Upper Tanudan Kalinga; deprecated 2012-08-12
      case 'koj':
        return 'kwv'; // Sara Dunjo; deprecated 2015-02-12
      case 'krm':
        return 'bmf'; // Krim; deprecated 2017-02-23
      case 'ktr':
        return 'dtp'; // Kota Marudu Tinagas; deprecated 2016-05-30
      case 'kvs':
        return 'gdj'; // Kunggara; deprecated 2016-05-30
      case 'kwq':
        return 'yam'; // Kwak; deprecated 2015-02-12
      case 'kxe':
        return 'tvd'; // Kakihum; deprecated 2015-02-12
      case 'kzj':
        return 'dtp'; // Coastal Kadazan; deprecated 2016-05-30
      case 'kzt':
        return 'dtp'; // Tambunan Dusun; deprecated 2016-05-30
      case 'lii':
        return 'raq'; // Lingkhim; deprecated 2015-02-12
      case 'lmm':
        return 'rmx'; // Lamam; deprecated 2014-02-28
      case 'meg':
        return 'cir'; // Mea; deprecated 2013-09-10
      case 'mst':
        return 'mry'; // Cataelano Mandaya; deprecated 2010-03-11
      case 'mwj':
        return 'vaj'; // Maligo; deprecated 2015-02-12
      case 'myt':
        return 'mry'; // Sangab Mandaya; deprecated 2010-03-11
      case 'nad':
        return 'xny'; // Nijadali; deprecated 2016-05-30
      case 'ncp':
        return 'kdz'; // Ndaktup; deprecated 2018-03-08
      case 'nnx':
        return 'ngv'; // Ngong; deprecated 2015-02-12
      case 'nts':
        return 'pij'; // Natagaimas; deprecated 2016-05-30
      case 'oun':
        return 'vaj'; // !O!ung; deprecated 2015-02-12
      case 'pcr':
        return 'adx'; // Panang; deprecated 2013-09-10
      case 'pmc':
        return 'huw'; // Palumata; deprecated 2016-05-30
      case 'pmu':
        return 'phr'; // Mirpur Panjabi; deprecated 2015-02-12
      case 'ppa':
        return 'bfy'; // Pao; deprecated 2016-05-30
      case 'ppr':
        return 'lcq'; // Piru; deprecated 2013-09-10
      case 'pry':
        return 'prt'; // Pray 3; deprecated 2016-05-30
      case 'puz':
        return 'pub'; // Purum Naga; deprecated 2014-02-28
      case 'sca':
        return 'hle'; // Sansu; deprecated 2012-08-12
      case 'skk':
        return 'oyb'; // Sok; deprecated 2017-02-23
      case 'tdu':
        return 'dtp'; // Tempasuk Dusun; deprecated 2016-05-30
      case 'thc':
        return 'tpo'; // Tai Hang Tong; deprecated 2016-05-30
      case 'thx':
        return 'oyb'; // The; deprecated 2015-02-12
      case 'tie':
        return 'ras'; // Tingal; deprecated 2011-08-16
      case 'tkk':
        return 'twm'; // Takpa; deprecated 2011-08-16
      case 'tlw':
        return 'weo'; // South Wemale; deprecated 2012-08-12
      case 'tmp':
        return 'tyj'; // Tai Mène; deprecated 2016-05-30
      case 'tne':
        return 'kak'; // Tinoc Kallahan; deprecated 2016-05-30
      case 'tnf':
        return 'prs'; // Tangshewi; deprecated 2010-03-11
      case 'tsf':
        return 'taj'; // Southwestern Tamang; deprecated 2015-02-12
      case 'uok':
        return 'ema'; // Uokha; deprecated 2015-02-12
      case 'xba':
        return 'cax'; // Kamba (Brazil); deprecated 2016-05-30
      case 'xia':
        return 'acn'; // Xiandao; deprecated 2013-09-10
      case 'xkh':
        return 'waw'; // Karahawyana; deprecated 2016-05-30
      case 'xsj':
        return 'suj'; // Subi; deprecated 2015-02-12
      case 'ybd':
        return 'rki'; // Yangbye; deprecated 2012-08-12
      case 'yma':
        return 'lrr'; // Yamphe; deprecated 2012-08-12
      case 'ymt':
        return 'mtm'; // Mator-Taygi-Karagas; deprecated 2015-02-12
      case 'yos':
        return 'zom'; // Yos; deprecated 2013-09-10
      case 'yuu':
        return 'yug'; // Yugh; deprecated 2014-02-28
      default:
        return languageCode;
    }
  }

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
  ///  * [new Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  final String scriptCode;

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
  ///  * [new Locale.fromSubtags], which describes the conventions for creating
  ///    [Locale] objects.
  String get countryCode => _replaceDeprecatedRegionSubtag(_countryCode);
  final String _countryCode;

  static String _replaceDeprecatedRegionSubtag(String regionCode) {
    // This switch statement is generated by //flutter/tools/gen_locale.dart
    // Mappings generated for language subtag registry as of 2018-08-08.
    switch (regionCode) {
      case 'BU':
        return 'MM'; // Burma; deprecated 1989-12-05
      case 'DD':
        return 'DE'; // German Democratic Republic; deprecated 1990-10-30
      case 'FX':
        return 'FR'; // Metropolitan France; deprecated 1997-07-14
      case 'TP':
        return 'TL'; // East Timor; deprecated 2002-05-20
      case 'YD':
        return 'YE'; // Democratic Yemen; deprecated 1990-08-14
      case 'ZR':
        return 'CD'; // Zaire; deprecated 1997-07-14
      default:
        return regionCode;
    }
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Locale) {
      return false;
    }
    final Locale typedOther = other;
    return languageCode == typedOther.languageCode &&
        scriptCode == typedOther.scriptCode &&
        countryCode == typedOther.countryCode;
  }

  @override
  int get hashCode => hashValues(languageCode, scriptCode, countryCode);

  @override
  String toString() {
    final StringBuffer out = StringBuffer(languageCode);
    if (scriptCode != null) {
      out.write('_$scriptCode');
    }
    if (_countryCode != null) {
      out.write('_$countryCode');
    }
    return out.toString();
  }

  // TODO(yjbanov): implement to match flutter native.
  String toLanguageTag() => '_';
}

/// The most basic interface to the host operating system's user interface.
///
/// There is a single Window instance in the system, which you can
/// obtain from the [window] property.
abstract class Window {
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
  double get devicePixelRatio;

  /// The dimensions of the rectangle into which the application will be drawn,
  /// in physical pixels.
  ///
  /// When this changes, [onMetricsChanged] is called.
  ///
  /// At startup, the size of the application window may not be known before
  /// Dart code runs. If this value is observed early in the application
  /// lifecycle, it may report [Size.zero].
  ///
  /// This value does not take into account any on-screen keyboards or other
  /// system UI. The [padding] and [viewInsets] properties provide a view into
  /// how much of each side of the application may be obscured by system UI.
  ///
  /// See also:
  ///
  ///  * [WidgetsBindingObserver], for a mechanism at the widgets layer to
  ///    observe when this value changes.
  Size get physicalSize;

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
  double get physicalDepth;

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
  WindowPadding get viewInsets => WindowPadding.zero;

  WindowPadding get viewPadding => WindowPadding.zero;

  WindowPadding get systemGestureInsets => WindowPadding.zero;

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
  WindowPadding get padding => WindowPadding.zero;

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
  set onTextScaleFactorChanged(VoidCallback callback) {
    _onTextScaleFactorChanged = callback;
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
  VoidCallback get onPlatformBrightnessChanged => _onPlatformBrightnessChanged;
  VoidCallback _onPlatformBrightnessChanged;
  set onPlatformBrightnessChanged(VoidCallback callback) {
    _onPlatformBrightnessChanged = callback;
  }

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
  set onMetricsChanged(VoidCallback callback) {
    _onMetricsChanged = callback;
  }

  static const _enUS = const Locale('en', 'US');

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
  Locale get locale {
    if (_locales != null && _locales.isNotEmpty) {
      return _locales.first;
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
  List<Locale> get locales => _locales;
  // TODO(flutter_web): Get the real locale from the browser.
  List<Locale> _locales = const [_enUS];

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
  set onLocaleChanged(VoidCallback callback) {
    _onLocaleChanged = callback;
  }

  /// Requests that, at the next appropriate opportunity, the [onBeginFrame]
  /// and [onDrawFrame] callbacks be invoked.
  ///
  /// See also:
  ///
  ///  * [SchedulerBinding], the Flutter framework class which manages the
  ///    scheduling of frames.
  void scheduleFrame() {
    if (webOnlyScheduleFrameCallback == null) {
      throw new Exception(
          'webOnlyScheduleFrameCallback must be initialized first.');
    }
    webOnlyScheduleFrameCallback();
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
  set onBeginFrame(FrameCallback callback) {
    _onBeginFrame = callback;
  }

  /// A callback that is invoked to report the [FrameTiming] of recently
  /// rasterized frames.
  ///
  /// This can be used to see if the application has missed frames (through
  /// [FrameTiming.buildDuration] and [FrameTiming.rasterDuration]), or high
  /// latencies (through [FrameTiming.totalSpan]).
  ///
  /// Unlike [Timeline], the timing information here is available in the release
  /// mode (additional to the profile and the debug mode). Hence this can be
  /// used to monitor the application's performance in the wild.
  ///
  /// The callback may not be immediately triggered after each frame. Instead,
  /// it tries to batch frames together and send all their timings at once to
  /// decrease the overhead (as this is available in the release mode). The
  /// timing of any frame will be sent within about 1 second even if there are
  /// no later frames to batch.
  TimingsCallback get onReportTimings => _onReportTimings;
  TimingsCallback _onReportTimings;
  Zone _onReportTimingsZone;
  set onReportTimings(TimingsCallback callback) {
    _onReportTimings = callback;
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
  set onDrawFrame(VoidCallback callback) {
    _onDrawFrame = callback;
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
  set onPointerDataPacket(PointerDataPacketCallback callback) {
    _onPointerDataPacket = callback;
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
  String get defaultRouteName;

  /// Whether the user has requested that [updateSemantics] be called when
  /// the semantic contents of window changes.
  ///
  /// The [onSemanticsEnabledChanged] callback is called whenever this value
  /// changes.
  ///
  /// This defaults to `true` on the Web because we may never receive a signal
  /// that an assistive technology is turned on.
  bool get semanticsEnabled =>
      engine.EngineSemanticsOwner.instance.semanticsEnabled;

  /// A callback that is invoked when the value of [semanticsEnabled] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback get onSemanticsEnabledChanged => _onSemanticsEnabledChanged;
  VoidCallback _onSemanticsEnabledChanged;
  set onSemanticsEnabledChanged(VoidCallback callback) {
    _onSemanticsEnabledChanged = callback;
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
  set onSemanticsAction(SemanticsActionCallback callback) {
    _onSemanticsAction = callback;
  }

  /// A callback that is invoked when the value of [accessibilityFlags] changes.
  ///
  /// The framework invokes this callback in the same zone in which the
  /// callback was set.
  VoidCallback get onAccessibilityFeaturesChanged =>
      _onAccessibilityFeaturesChanged;
  VoidCallback _onAccessibilityFeaturesChanged;
  set onAccessibilityFeaturesChanged(VoidCallback callback) {
    _onAccessibilityFeaturesChanged = callback;
  }

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
  set onPlatformMessage(PlatformMessageCallback callback) {
    _onPlatformMessage = callback;
  }

  /// Change the retained semantics data about this window.
  ///
  /// If [semanticsEnabled] is true, the user has requested that this funciton
  /// be called whenever the semantic content of this window changes.
  ///
  /// In either case, this function disposes the given update, which means the
  /// semantics update cannot be used further.
  void updateSemantics(SemanticsUpdate update) {
    engine.EngineSemanticsOwner.instance.updateSemantics(update);
  }

  /// Sends a message to a platform-specific plugin.
  ///
  /// The `name` parameter determines which plugin receives the message. The
  /// `data` parameter contains the message payload and is typically UTF-8
  /// encoded JSON but can be arbitrary data. If the plugin replies to the
  /// message, `callback` will be called with the response.
  ///
  /// The framework invokes [callback] in the same zone in which this method
  /// was called.
  void sendPlatformMessage(
    String name,
    ByteData data,
    PlatformMessageResponseCallback callback,
  );

  /// Additional accessibility features that may be enabled by the platform.
  AccessibilityFeatures get accessibilityFeatures => _accessibilityFeatures;
  AccessibilityFeatures _accessibilityFeatures = AccessibilityFeatures._(0);

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
  void render(Scene scene) {
    if (engine.experimentalUseSkia) {
      final engine.LayerScene layerScene = scene;
      _rasterizer.draw(layerScene.layerTree);
    } else {
      engine.domRenderer.renderScene(scene.webOnlyRootElement);
    }
  }

  final engine.Rasterizer _rasterizer = engine.experimentalUseSkia
      ? engine.Rasterizer(engine.Surface((engine.SkCanvas canvas) {
          engine.domRenderer.renderScene(canvas.htmlCanvas);
          canvas.skSurface.callMethod('flush');
        }))
      : null;

  String get initialLifecycleState => _initialLifecycleState;

  String _initialLifecycleState;

  void setIsolateDebugName(String name) {}
}

VoidCallback webOnlyScheduleFrameCallback;

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
    if (accessibleNavigation) {
      features.add('accessibleNavigation');
    }
    if (invertColors) {
      features.add('invertColors');
    }
    if (disableAnimations) {
      features.add('disableAnimations');
    }
    if (boldText) {
      features.add('boldText');
    }
    if (reduceMotion) {
      features.add('reduceMotion');
    }
    return 'AccessibilityFeatures$features';
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    final AccessibilityFeatures typedOther = other;
    return _index == typedOther._index;
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

// Unimplemented classes.
// TODO(flutter_web): see https://github.com/flutter/flutter/issues/33614.
class CallbackHandle {
  CallbackHandle.fromRawHandle(this._handle);

  final int _handle;

  int toRawHandle() => _handle;

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => super.hashCode;
}

// TODO(flutter_web): see https://github.com/flutter/flutter/issues/33615.
class PluginUtilities {
  static CallbackHandle getCallbackHandle(Function callback) {
    throw UnimplementedError();
  }

  static Function getCallbackFromHandle(CallbackHandle handle) {
    throw UnimplementedError();
  }
}

// TODO(flutter_web): see https://github.com/flutter/flutter/issues/33616.
class ImageShader {
  ImageShader(Image image, TileMode tmx, TileMode tmy, Float64List matrix4);
}

// TODO(flutter_web): probably dont implement this one.
class IsolateNameServer {
  static dynamic lookupPortByName(String name) {
    assert(name != null, "'name' cannot be null.");
    throw UnimplementedError();
  }

  static bool registerPortWithName(dynamic port, String name) {
    assert(port != null, "'port' cannot be null.");
    assert(name != null, "'name' cannot be null.");
    throw UnimplementedError();
  }

  static bool removePortNameMapping(String name) {
    assert(name != null, "'name' cannot be null.");
    throw UnimplementedError();
  }
}

/// Various important time points in the lifetime of a frame.
///
/// [FrameTiming] records a timestamp of each phase for performance analysis.
enum FramePhase {
  /// When the UI thread starts building a frame.
  ///
  /// See also [FrameTiming.buildDuration].
  buildStart,

  /// When the UI thread finishes building a frame.
  ///
  /// See also [FrameTiming.buildDuration].
  buildFinish,

  /// When the GPU thread starts rasterizing a frame.
  ///
  /// See also [FrameTiming.rasterDuration].
  rasterStart,

  /// When the GPU thread finishes rasterizing a frame.
  ///
  /// See also [FrameTiming.rasterDuration].
  rasterFinish,
}

/// Time-related performance metrics of a frame.
///
/// See [Window.onReportTimings] for how to get this.
///
/// The metrics in debug mode (`flutter run` without any flags) may be very
/// different from those in profile and release modes due to the debug overhead.
/// Therefore it's recommended to only monitor and analyze performance metrics
/// in profile and release modes.
class FrameTiming {
  /// Construct [FrameTiming] with raw timestamps in microseconds.
  ///
  /// List [timestamps] must have the same number of elements as
  /// [FramePhase.values].
  ///
  /// This constructor is usually only called by the Flutter engine, or a test.
  /// To get the [FrameTiming] of your app, see [Window.onReportTimings].
  FrameTiming(List<int> timestamps)
      : assert(timestamps.length == FramePhase.values.length),
        _timestamps = timestamps;

  /// This is a raw timestamp in microseconds from some epoch. The epoch in all
  /// [FrameTiming] is the same, but it may not match [DateTime]'s epoch.
  int timestampInMicroseconds(FramePhase phase) => _timestamps[phase.index];

  Duration _rawDuration(FramePhase phase) =>
      Duration(microseconds: _timestamps[phase.index]);

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
  Duration get buildDuration =>
      _rawDuration(FramePhase.buildFinish) -
      _rawDuration(FramePhase.buildStart);

  /// The duration to rasterize the frame on the GPU thread.
  ///
  /// {@macro dart.ui.FrameTiming.fps_smoothness_milliseconds}
  /// {@macro dart.ui.FrameTiming.fps_milliseconds}
  Duration get rasterDuration =>
      _rawDuration(FramePhase.rasterFinish) -
      _rawDuration(FramePhase.rasterStart);

  /// The timespan between build start and raster finish.
  ///
  /// To achieve the lowest latency on an X fps display, this should not exceed
  /// 1000/X milliseconds.
  /// {@macro dart.ui.FrameTiming.fps_milliseconds}
  ///
  /// See also [buildDuration] and [rasterDuration].
  Duration get totalSpan =>
      _rawDuration(FramePhase.rasterFinish) -
      _rawDuration(FramePhase.buildStart);

  final List<int> _timestamps; // in microseconds

  String _formatMS(Duration duration) => '${duration.inMicroseconds * 0.001}ms';

  @override
  String toString() {
    return '$runtimeType(buildDuration: ${_formatMS(buildDuration)}, rasterDuration: ${_formatMS(rasterDuration)}, totalSpan: ${_formatMS(totalSpan)})';
  }
}

/// The [Window] singleton. This object exposes the size of the display, the
/// core scheduler API, the input event callback, the graphics drawing API, and
/// other such core services.
Window get window => engine.window;

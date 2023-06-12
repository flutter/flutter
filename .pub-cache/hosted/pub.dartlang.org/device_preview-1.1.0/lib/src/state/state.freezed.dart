// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$DevicePreviewState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function() initializing,
    required TResult Function(List<DeviceInfo> devices,
            List<NamedLocale> locales, DevicePreviewData data)
        initialized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NotInitializedDevicePreviewState value)
        notInitialized,
    required TResult Function(_InitializingDevicePreviewState value)
        initializing,
    required TResult Function(_InitializedDevicePreviewState value) initialized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevicePreviewStateCopyWith<$Res> {
  factory $DevicePreviewStateCopyWith(
          DevicePreviewState value, $Res Function(DevicePreviewState) then) =
      _$DevicePreviewStateCopyWithImpl<$Res>;
}

/// @nodoc
class _$DevicePreviewStateCopyWithImpl<$Res>
    implements $DevicePreviewStateCopyWith<$Res> {
  _$DevicePreviewStateCopyWithImpl(this._value, this._then);

  final DevicePreviewState _value;
  // ignore: unused_field
  final $Res Function(DevicePreviewState) _then;
}

/// @nodoc
abstract class _$$_NotInitializedDevicePreviewStateCopyWith<$Res> {
  factory _$$_NotInitializedDevicePreviewStateCopyWith(
          _$_NotInitializedDevicePreviewState value,
          $Res Function(_$_NotInitializedDevicePreviewState) then) =
      __$$_NotInitializedDevicePreviewStateCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_NotInitializedDevicePreviewStateCopyWithImpl<$Res>
    extends _$DevicePreviewStateCopyWithImpl<$Res>
    implements _$$_NotInitializedDevicePreviewStateCopyWith<$Res> {
  __$$_NotInitializedDevicePreviewStateCopyWithImpl(
      _$_NotInitializedDevicePreviewState _value,
      $Res Function(_$_NotInitializedDevicePreviewState) _then)
      : super(_value, (v) => _then(v as _$_NotInitializedDevicePreviewState));

  @override
  _$_NotInitializedDevicePreviewState get _value =>
      super._value as _$_NotInitializedDevicePreviewState;
}

/// @nodoc

class _$_NotInitializedDevicePreviewState
    with DiagnosticableTreeMixin
    implements _NotInitializedDevicePreviewState {
  const _$_NotInitializedDevicePreviewState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DevicePreviewState.notInitialized()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty('type', 'DevicePreviewState.notInitialized'));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_NotInitializedDevicePreviewState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function() initializing,
    required TResult Function(List<DeviceInfo> devices,
            List<NamedLocale> locales, DevicePreviewData data)
        initialized,
  }) {
    return notInitialized();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
  }) {
    return notInitialized?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
    required TResult orElse(),
  }) {
    if (notInitialized != null) {
      return notInitialized();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NotInitializedDevicePreviewState value)
        notInitialized,
    required TResult Function(_InitializingDevicePreviewState value)
        initializing,
    required TResult Function(_InitializedDevicePreviewState value) initialized,
  }) {
    return notInitialized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
  }) {
    return notInitialized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
    required TResult orElse(),
  }) {
    if (notInitialized != null) {
      return notInitialized(this);
    }
    return orElse();
  }
}

abstract class _NotInitializedDevicePreviewState implements DevicePreviewState {
  const factory _NotInitializedDevicePreviewState() =
      _$_NotInitializedDevicePreviewState;
}

/// @nodoc
abstract class _$$_InitializingDevicePreviewStateCopyWith<$Res> {
  factory _$$_InitializingDevicePreviewStateCopyWith(
          _$_InitializingDevicePreviewState value,
          $Res Function(_$_InitializingDevicePreviewState) then) =
      __$$_InitializingDevicePreviewStateCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_InitializingDevicePreviewStateCopyWithImpl<$Res>
    extends _$DevicePreviewStateCopyWithImpl<$Res>
    implements _$$_InitializingDevicePreviewStateCopyWith<$Res> {
  __$$_InitializingDevicePreviewStateCopyWithImpl(
      _$_InitializingDevicePreviewState _value,
      $Res Function(_$_InitializingDevicePreviewState) _then)
      : super(_value, (v) => _then(v as _$_InitializingDevicePreviewState));

  @override
  _$_InitializingDevicePreviewState get _value =>
      super._value as _$_InitializingDevicePreviewState;
}

/// @nodoc

class _$_InitializingDevicePreviewState
    with DiagnosticableTreeMixin
    implements _InitializingDevicePreviewState {
  const _$_InitializingDevicePreviewState();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DevicePreviewState.initializing()';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty('type', 'DevicePreviewState.initializing'));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_InitializingDevicePreviewState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function() initializing,
    required TResult Function(List<DeviceInfo> devices,
            List<NamedLocale> locales, DevicePreviewData data)
        initialized,
  }) {
    return initializing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
  }) {
    return initializing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NotInitializedDevicePreviewState value)
        notInitialized,
    required TResult Function(_InitializingDevicePreviewState value)
        initializing,
    required TResult Function(_InitializedDevicePreviewState value) initialized,
  }) {
    return initializing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
  }) {
    return initializing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
    required TResult orElse(),
  }) {
    if (initializing != null) {
      return initializing(this);
    }
    return orElse();
  }
}

abstract class _InitializingDevicePreviewState implements DevicePreviewState {
  const factory _InitializingDevicePreviewState() =
      _$_InitializingDevicePreviewState;
}

/// @nodoc
abstract class _$$_InitializedDevicePreviewStateCopyWith<$Res> {
  factory _$$_InitializedDevicePreviewStateCopyWith(
          _$_InitializedDevicePreviewState value,
          $Res Function(_$_InitializedDevicePreviewState) then) =
      __$$_InitializedDevicePreviewStateCopyWithImpl<$Res>;
  $Res call(
      {List<DeviceInfo> devices,
      List<NamedLocale> locales,
      DevicePreviewData data});

  $DevicePreviewDataCopyWith<$Res> get data;
}

/// @nodoc
class __$$_InitializedDevicePreviewStateCopyWithImpl<$Res>
    extends _$DevicePreviewStateCopyWithImpl<$Res>
    implements _$$_InitializedDevicePreviewStateCopyWith<$Res> {
  __$$_InitializedDevicePreviewStateCopyWithImpl(
      _$_InitializedDevicePreviewState _value,
      $Res Function(_$_InitializedDevicePreviewState) _then)
      : super(_value, (v) => _then(v as _$_InitializedDevicePreviewState));

  @override
  _$_InitializedDevicePreviewState get _value =>
      super._value as _$_InitializedDevicePreviewState;

  @override
  $Res call({
    Object? devices = freezed,
    Object? locales = freezed,
    Object? data = freezed,
  }) {
    return _then(_$_InitializedDevicePreviewState(
      devices: devices == freezed
          ? _value._devices
          : devices // ignore: cast_nullable_to_non_nullable
              as List<DeviceInfo>,
      locales: locales == freezed
          ? _value._locales
          : locales // ignore: cast_nullable_to_non_nullable
              as List<NamedLocale>,
      data: data == freezed
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as DevicePreviewData,
    ));
  }

  @override
  $DevicePreviewDataCopyWith<$Res> get data {
    return $DevicePreviewDataCopyWith<$Res>(_value.data, (value) {
      return _then(_value.copyWith(data: value));
    });
  }
}

/// @nodoc

class _$_InitializedDevicePreviewState
    with DiagnosticableTreeMixin
    implements _InitializedDevicePreviewState {
  const _$_InitializedDevicePreviewState(
      {required final List<DeviceInfo> devices,
      required final List<NamedLocale> locales,
      required this.data})
      : _devices = devices,
        _locales = locales;

  /// The list of all available devices.
  final List<DeviceInfo> _devices;

  /// The list of all available devices.
  @override
  List<DeviceInfo> get devices {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_devices);
  }

  /// The list of all available locales.
  final List<NamedLocale> _locales;

  /// The list of all available locales.
  @override
  List<NamedLocale> get locales {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_locales);
  }

  /// The user settings of the preview.
  @override
  final DevicePreviewData data;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DevicePreviewState.initialized(devices: $devices, locales: $locales, data: $data)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DevicePreviewState.initialized'))
      ..add(DiagnosticsProperty('devices', devices))
      ..add(DiagnosticsProperty('locales', locales))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_InitializedDevicePreviewState &&
            const DeepCollectionEquality().equals(other._devices, _devices) &&
            const DeepCollectionEquality().equals(other._locales, _locales) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_devices),
      const DeepCollectionEquality().hash(_locales),
      const DeepCollectionEquality().hash(data));

  @JsonKey(ignore: true)
  @override
  _$$_InitializedDevicePreviewStateCopyWith<_$_InitializedDevicePreviewState>
      get copyWith => __$$_InitializedDevicePreviewStateCopyWithImpl<
          _$_InitializedDevicePreviewState>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() notInitialized,
    required TResult Function() initializing,
    required TResult Function(List<DeviceInfo> devices,
            List<NamedLocale> locales, DevicePreviewData data)
        initialized,
  }) {
    return initialized(devices, locales, data);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
  }) {
    return initialized?.call(devices, locales, data);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? notInitialized,
    TResult Function()? initializing,
    TResult Function(List<DeviceInfo> devices, List<NamedLocale> locales,
            DevicePreviewData data)?
        initialized,
    required TResult orElse(),
  }) {
    if (initialized != null) {
      return initialized(devices, locales, data);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NotInitializedDevicePreviewState value)
        notInitialized,
    required TResult Function(_InitializingDevicePreviewState value)
        initializing,
    required TResult Function(_InitializedDevicePreviewState value) initialized,
  }) {
    return initialized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
  }) {
    return initialized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NotInitializedDevicePreviewState value)? notInitialized,
    TResult Function(_InitializingDevicePreviewState value)? initializing,
    TResult Function(_InitializedDevicePreviewState value)? initialized,
    required TResult orElse(),
  }) {
    if (initialized != null) {
      return initialized(this);
    }
    return orElse();
  }
}

abstract class _InitializedDevicePreviewState implements DevicePreviewState {
  const factory _InitializedDevicePreviewState(
          {required final List<DeviceInfo> devices,
          required final List<NamedLocale> locales,
          required final DevicePreviewData data}) =
      _$_InitializedDevicePreviewState;

  /// The list of all available devices.
  List<DeviceInfo> get devices => throw _privateConstructorUsedError;

  /// The list of all available locales.
  List<NamedLocale> get locales => throw _privateConstructorUsedError;

  /// The user settings of the preview.
  DevicePreviewData get data => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  _$$_InitializedDevicePreviewStateCopyWith<_$_InitializedDevicePreviewState>
      get copyWith => throw _privateConstructorUsedError;
}

DevicePreviewData _$DevicePreviewDataFromJson(Map<String, dynamic> json) {
  return _DevicePreviewData.fromJson(json);
}

/// @nodoc
mixin _$DevicePreviewData {
  /// Indicate whether the toolbar is visible.
  bool get isToolbarVisible => throw _privateConstructorUsedError;

  /// Indicate whether the device simulation is enabled.
  bool get isEnabled => throw _privateConstructorUsedError;

  /// The current orientation of the device
  Orientation get orientation => throw _privateConstructorUsedError;

  /// The currently selected device.
  String? get deviceIdentifier => throw _privateConstructorUsedError;

  /// The currently selected device locale.
  String get locale => throw _privateConstructorUsedError;

  /// Indicate whether the frame is currently visible.
  bool get isFrameVisible => throw _privateConstructorUsedError;

  /// Indicate whether the mode is currently dark.
  bool get isDarkMode => throw _privateConstructorUsedError;

  /// Indicate whether texts are forced to bold.
  bool get boldText => throw _privateConstructorUsedError;

  /// Indicate whether the virtual keyboard is visible.
  bool get isVirtualKeyboardVisible => throw _privateConstructorUsedError;

  /// Indicate whether animations are disabled.
  bool get disableAnimations => throw _privateConstructorUsedError;

  /// Indicate whether the highcontrast mode is activated.
  bool get highContrast => throw _privateConstructorUsedError;

  /// Indicate whether the navigation is in accessible mode.
  bool get accessibleNavigation => throw _privateConstructorUsedError;

  /// Indicate whether image colors are inverted.
  bool get invertColors => throw _privateConstructorUsedError;

  /// Indicate whether image colors are inverted.
  Map<String, Map<String, dynamic>> get pluginData =>
      throw _privateConstructorUsedError;

  /// The current text scaling factor.
  double get textScaleFactor => throw _privateConstructorUsedError;
  DevicePreviewSettingsData? get settings => throw _privateConstructorUsedError;

  /// The custom device configuration
  CustomDeviceInfoData? get customDevice => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DevicePreviewDataCopyWith<DevicePreviewData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevicePreviewDataCopyWith<$Res> {
  factory $DevicePreviewDataCopyWith(
          DevicePreviewData value, $Res Function(DevicePreviewData) then) =
      _$DevicePreviewDataCopyWithImpl<$Res>;
  $Res call(
      {bool isToolbarVisible,
      bool isEnabled,
      Orientation orientation,
      String? deviceIdentifier,
      String locale,
      bool isFrameVisible,
      bool isDarkMode,
      bool boldText,
      bool isVirtualKeyboardVisible,
      bool disableAnimations,
      bool highContrast,
      bool accessibleNavigation,
      bool invertColors,
      Map<String, Map<String, dynamic>> pluginData,
      double textScaleFactor,
      DevicePreviewSettingsData? settings,
      CustomDeviceInfoData? customDevice});

  $DevicePreviewSettingsDataCopyWith<$Res>? get settings;
  $CustomDeviceInfoDataCopyWith<$Res>? get customDevice;
}

/// @nodoc
class _$DevicePreviewDataCopyWithImpl<$Res>
    implements $DevicePreviewDataCopyWith<$Res> {
  _$DevicePreviewDataCopyWithImpl(this._value, this._then);

  final DevicePreviewData _value;
  // ignore: unused_field
  final $Res Function(DevicePreviewData) _then;

  @override
  $Res call({
    Object? isToolbarVisible = freezed,
    Object? isEnabled = freezed,
    Object? orientation = freezed,
    Object? deviceIdentifier = freezed,
    Object? locale = freezed,
    Object? isFrameVisible = freezed,
    Object? isDarkMode = freezed,
    Object? boldText = freezed,
    Object? isVirtualKeyboardVisible = freezed,
    Object? disableAnimations = freezed,
    Object? highContrast = freezed,
    Object? accessibleNavigation = freezed,
    Object? invertColors = freezed,
    Object? pluginData = freezed,
    Object? textScaleFactor = freezed,
    Object? settings = freezed,
    Object? customDevice = freezed,
  }) {
    return _then(_value.copyWith(
      isToolbarVisible: isToolbarVisible == freezed
          ? _value.isToolbarVisible
          : isToolbarVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isEnabled: isEnabled == freezed
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      orientation: orientation == freezed
          ? _value.orientation
          : orientation // ignore: cast_nullable_to_non_nullable
              as Orientation,
      deviceIdentifier: deviceIdentifier == freezed
          ? _value.deviceIdentifier
          : deviceIdentifier // ignore: cast_nullable_to_non_nullable
              as String?,
      locale: locale == freezed
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as String,
      isFrameVisible: isFrameVisible == freezed
          ? _value.isFrameVisible
          : isFrameVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isDarkMode: isDarkMode == freezed
          ? _value.isDarkMode
          : isDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      boldText: boldText == freezed
          ? _value.boldText
          : boldText // ignore: cast_nullable_to_non_nullable
              as bool,
      isVirtualKeyboardVisible: isVirtualKeyboardVisible == freezed
          ? _value.isVirtualKeyboardVisible
          : isVirtualKeyboardVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      disableAnimations: disableAnimations == freezed
          ? _value.disableAnimations
          : disableAnimations // ignore: cast_nullable_to_non_nullable
              as bool,
      highContrast: highContrast == freezed
          ? _value.highContrast
          : highContrast // ignore: cast_nullable_to_non_nullable
              as bool,
      accessibleNavigation: accessibleNavigation == freezed
          ? _value.accessibleNavigation
          : accessibleNavigation // ignore: cast_nullable_to_non_nullable
              as bool,
      invertColors: invertColors == freezed
          ? _value.invertColors
          : invertColors // ignore: cast_nullable_to_non_nullable
              as bool,
      pluginData: pluginData == freezed
          ? _value.pluginData
          : pluginData // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, dynamic>>,
      textScaleFactor: textScaleFactor == freezed
          ? _value.textScaleFactor
          : textScaleFactor // ignore: cast_nullable_to_non_nullable
              as double,
      settings: settings == freezed
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as DevicePreviewSettingsData?,
      customDevice: customDevice == freezed
          ? _value.customDevice
          : customDevice // ignore: cast_nullable_to_non_nullable
              as CustomDeviceInfoData?,
    ));
  }

  @override
  $DevicePreviewSettingsDataCopyWith<$Res>? get settings {
    if (_value.settings == null) {
      return null;
    }

    return $DevicePreviewSettingsDataCopyWith<$Res>(_value.settings!, (value) {
      return _then(_value.copyWith(settings: value));
    });
  }

  @override
  $CustomDeviceInfoDataCopyWith<$Res>? get customDevice {
    if (_value.customDevice == null) {
      return null;
    }

    return $CustomDeviceInfoDataCopyWith<$Res>(_value.customDevice!, (value) {
      return _then(_value.copyWith(customDevice: value));
    });
  }
}

/// @nodoc
abstract class _$$_DevicePreviewDataCopyWith<$Res>
    implements $DevicePreviewDataCopyWith<$Res> {
  factory _$$_DevicePreviewDataCopyWith(_$_DevicePreviewData value,
          $Res Function(_$_DevicePreviewData) then) =
      __$$_DevicePreviewDataCopyWithImpl<$Res>;
  @override
  $Res call(
      {bool isToolbarVisible,
      bool isEnabled,
      Orientation orientation,
      String? deviceIdentifier,
      String locale,
      bool isFrameVisible,
      bool isDarkMode,
      bool boldText,
      bool isVirtualKeyboardVisible,
      bool disableAnimations,
      bool highContrast,
      bool accessibleNavigation,
      bool invertColors,
      Map<String, Map<String, dynamic>> pluginData,
      double textScaleFactor,
      DevicePreviewSettingsData? settings,
      CustomDeviceInfoData? customDevice});

  @override
  $DevicePreviewSettingsDataCopyWith<$Res>? get settings;
  @override
  $CustomDeviceInfoDataCopyWith<$Res>? get customDevice;
}

/// @nodoc
class __$$_DevicePreviewDataCopyWithImpl<$Res>
    extends _$DevicePreviewDataCopyWithImpl<$Res>
    implements _$$_DevicePreviewDataCopyWith<$Res> {
  __$$_DevicePreviewDataCopyWithImpl(
      _$_DevicePreviewData _value, $Res Function(_$_DevicePreviewData) _then)
      : super(_value, (v) => _then(v as _$_DevicePreviewData));

  @override
  _$_DevicePreviewData get _value => super._value as _$_DevicePreviewData;

  @override
  $Res call({
    Object? isToolbarVisible = freezed,
    Object? isEnabled = freezed,
    Object? orientation = freezed,
    Object? deviceIdentifier = freezed,
    Object? locale = freezed,
    Object? isFrameVisible = freezed,
    Object? isDarkMode = freezed,
    Object? boldText = freezed,
    Object? isVirtualKeyboardVisible = freezed,
    Object? disableAnimations = freezed,
    Object? highContrast = freezed,
    Object? accessibleNavigation = freezed,
    Object? invertColors = freezed,
    Object? pluginData = freezed,
    Object? textScaleFactor = freezed,
    Object? settings = freezed,
    Object? customDevice = freezed,
  }) {
    return _then(_$_DevicePreviewData(
      isToolbarVisible: isToolbarVisible == freezed
          ? _value.isToolbarVisible
          : isToolbarVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isEnabled: isEnabled == freezed
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      orientation: orientation == freezed
          ? _value.orientation
          : orientation // ignore: cast_nullable_to_non_nullable
              as Orientation,
      deviceIdentifier: deviceIdentifier == freezed
          ? _value.deviceIdentifier
          : deviceIdentifier // ignore: cast_nullable_to_non_nullable
              as String?,
      locale: locale == freezed
          ? _value.locale
          : locale // ignore: cast_nullable_to_non_nullable
              as String,
      isFrameVisible: isFrameVisible == freezed
          ? _value.isFrameVisible
          : isFrameVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isDarkMode: isDarkMode == freezed
          ? _value.isDarkMode
          : isDarkMode // ignore: cast_nullable_to_non_nullable
              as bool,
      boldText: boldText == freezed
          ? _value.boldText
          : boldText // ignore: cast_nullable_to_non_nullable
              as bool,
      isVirtualKeyboardVisible: isVirtualKeyboardVisible == freezed
          ? _value.isVirtualKeyboardVisible
          : isVirtualKeyboardVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      disableAnimations: disableAnimations == freezed
          ? _value.disableAnimations
          : disableAnimations // ignore: cast_nullable_to_non_nullable
              as bool,
      highContrast: highContrast == freezed
          ? _value.highContrast
          : highContrast // ignore: cast_nullable_to_non_nullable
              as bool,
      accessibleNavigation: accessibleNavigation == freezed
          ? _value.accessibleNavigation
          : accessibleNavigation // ignore: cast_nullable_to_non_nullable
              as bool,
      invertColors: invertColors == freezed
          ? _value.invertColors
          : invertColors // ignore: cast_nullable_to_non_nullable
              as bool,
      pluginData: pluginData == freezed
          ? _value._pluginData
          : pluginData // ignore: cast_nullable_to_non_nullable
              as Map<String, Map<String, dynamic>>,
      textScaleFactor: textScaleFactor == freezed
          ? _value.textScaleFactor
          : textScaleFactor // ignore: cast_nullable_to_non_nullable
              as double,
      settings: settings == freezed
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as DevicePreviewSettingsData?,
      customDevice: customDevice == freezed
          ? _value.customDevice
          : customDevice // ignore: cast_nullable_to_non_nullable
              as CustomDeviceInfoData?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_DevicePreviewData
    with DiagnosticableTreeMixin
    implements _DevicePreviewData {
  const _$_DevicePreviewData(
      {this.isToolbarVisible = true,
      this.isEnabled = true,
      this.orientation = Orientation.portrait,
      this.deviceIdentifier,
      this.locale = 'en-US',
      this.isFrameVisible = true,
      this.isDarkMode = false,
      this.boldText = false,
      this.isVirtualKeyboardVisible = false,
      this.disableAnimations = false,
      this.highContrast = false,
      this.accessibleNavigation = false,
      this.invertColors = false,
      final Map<String, Map<String, dynamic>> pluginData =
          const <String, Map<String, dynamic>>{},
      this.textScaleFactor = 1.0,
      this.settings,
      this.customDevice = null})
      : _pluginData = pluginData;

  factory _$_DevicePreviewData.fromJson(Map<String, dynamic> json) =>
      _$$_DevicePreviewDataFromJson(json);

  /// Indicate whether the toolbar is visible.
  @override
  @JsonKey()
  final bool isToolbarVisible;

  /// Indicate whether the device simulation is enabled.
  @override
  @JsonKey()
  final bool isEnabled;

  /// The current orientation of the device
  @override
  @JsonKey()
  final Orientation orientation;

  /// The currently selected device.
  @override
  final String? deviceIdentifier;

  /// The currently selected device locale.
  @override
  @JsonKey()
  final String locale;

  /// Indicate whether the frame is currently visible.
  @override
  @JsonKey()
  final bool isFrameVisible;

  /// Indicate whether the mode is currently dark.
  @override
  @JsonKey()
  final bool isDarkMode;

  /// Indicate whether texts are forced to bold.
  @override
  @JsonKey()
  final bool boldText;

  /// Indicate whether the virtual keyboard is visible.
  @override
  @JsonKey()
  final bool isVirtualKeyboardVisible;

  /// Indicate whether animations are disabled.
  @override
  @JsonKey()
  final bool disableAnimations;

  /// Indicate whether the highcontrast mode is activated.
  @override
  @JsonKey()
  final bool highContrast;

  /// Indicate whether the navigation is in accessible mode.
  @override
  @JsonKey()
  final bool accessibleNavigation;

  /// Indicate whether image colors are inverted.
  @override
  @JsonKey()
  final bool invertColors;

  /// Indicate whether image colors are inverted.
  final Map<String, Map<String, dynamic>> _pluginData;

  /// Indicate whether image colors are inverted.
  @override
  @JsonKey()
  Map<String, Map<String, dynamic>> get pluginData {
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_pluginData);
  }

  /// The current text scaling factor.
  @override
  @JsonKey()
  final double textScaleFactor;
  @override
  final DevicePreviewSettingsData? settings;

  /// The custom device configuration
  @override
  @JsonKey()
  final CustomDeviceInfoData? customDevice;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DevicePreviewData(isToolbarVisible: $isToolbarVisible, isEnabled: $isEnabled, orientation: $orientation, deviceIdentifier: $deviceIdentifier, locale: $locale, isFrameVisible: $isFrameVisible, isDarkMode: $isDarkMode, boldText: $boldText, isVirtualKeyboardVisible: $isVirtualKeyboardVisible, disableAnimations: $disableAnimations, highContrast: $highContrast, accessibleNavigation: $accessibleNavigation, invertColors: $invertColors, pluginData: $pluginData, textScaleFactor: $textScaleFactor, settings: $settings, customDevice: $customDevice)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DevicePreviewData'))
      ..add(DiagnosticsProperty('isToolbarVisible', isToolbarVisible))
      ..add(DiagnosticsProperty('isEnabled', isEnabled))
      ..add(DiagnosticsProperty('orientation', orientation))
      ..add(DiagnosticsProperty('deviceIdentifier', deviceIdentifier))
      ..add(DiagnosticsProperty('locale', locale))
      ..add(DiagnosticsProperty('isFrameVisible', isFrameVisible))
      ..add(DiagnosticsProperty('isDarkMode', isDarkMode))
      ..add(DiagnosticsProperty('boldText', boldText))
      ..add(DiagnosticsProperty(
          'isVirtualKeyboardVisible', isVirtualKeyboardVisible))
      ..add(DiagnosticsProperty('disableAnimations', disableAnimations))
      ..add(DiagnosticsProperty('highContrast', highContrast))
      ..add(DiagnosticsProperty('accessibleNavigation', accessibleNavigation))
      ..add(DiagnosticsProperty('invertColors', invertColors))
      ..add(DiagnosticsProperty('pluginData', pluginData))
      ..add(DiagnosticsProperty('textScaleFactor', textScaleFactor))
      ..add(DiagnosticsProperty('settings', settings))
      ..add(DiagnosticsProperty('customDevice', customDevice));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DevicePreviewData &&
            const DeepCollectionEquality()
                .equals(other.isToolbarVisible, isToolbarVisible) &&
            const DeepCollectionEquality().equals(other.isEnabled, isEnabled) &&
            const DeepCollectionEquality()
                .equals(other.orientation, orientation) &&
            const DeepCollectionEquality()
                .equals(other.deviceIdentifier, deviceIdentifier) &&
            const DeepCollectionEquality().equals(other.locale, locale) &&
            const DeepCollectionEquality()
                .equals(other.isFrameVisible, isFrameVisible) &&
            const DeepCollectionEquality()
                .equals(other.isDarkMode, isDarkMode) &&
            const DeepCollectionEquality().equals(other.boldText, boldText) &&
            const DeepCollectionEquality().equals(
                other.isVirtualKeyboardVisible, isVirtualKeyboardVisible) &&
            const DeepCollectionEquality()
                .equals(other.disableAnimations, disableAnimations) &&
            const DeepCollectionEquality()
                .equals(other.highContrast, highContrast) &&
            const DeepCollectionEquality()
                .equals(other.accessibleNavigation, accessibleNavigation) &&
            const DeepCollectionEquality()
                .equals(other.invertColors, invertColors) &&
            const DeepCollectionEquality()
                .equals(other._pluginData, _pluginData) &&
            const DeepCollectionEquality()
                .equals(other.textScaleFactor, textScaleFactor) &&
            const DeepCollectionEquality().equals(other.settings, settings) &&
            const DeepCollectionEquality()
                .equals(other.customDevice, customDevice));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(isToolbarVisible),
      const DeepCollectionEquality().hash(isEnabled),
      const DeepCollectionEquality().hash(orientation),
      const DeepCollectionEquality().hash(deviceIdentifier),
      const DeepCollectionEquality().hash(locale),
      const DeepCollectionEquality().hash(isFrameVisible),
      const DeepCollectionEquality().hash(isDarkMode),
      const DeepCollectionEquality().hash(boldText),
      const DeepCollectionEquality().hash(isVirtualKeyboardVisible),
      const DeepCollectionEquality().hash(disableAnimations),
      const DeepCollectionEquality().hash(highContrast),
      const DeepCollectionEquality().hash(accessibleNavigation),
      const DeepCollectionEquality().hash(invertColors),
      const DeepCollectionEquality().hash(_pluginData),
      const DeepCollectionEquality().hash(textScaleFactor),
      const DeepCollectionEquality().hash(settings),
      const DeepCollectionEquality().hash(customDevice));

  @JsonKey(ignore: true)
  @override
  _$$_DevicePreviewDataCopyWith<_$_DevicePreviewData> get copyWith =>
      __$$_DevicePreviewDataCopyWithImpl<_$_DevicePreviewData>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DevicePreviewDataToJson(this);
  }
}

abstract class _DevicePreviewData implements DevicePreviewData {
  const factory _DevicePreviewData(
      {final bool isToolbarVisible,
      final bool isEnabled,
      final Orientation orientation,
      final String? deviceIdentifier,
      final String locale,
      final bool isFrameVisible,
      final bool isDarkMode,
      final bool boldText,
      final bool isVirtualKeyboardVisible,
      final bool disableAnimations,
      final bool highContrast,
      final bool accessibleNavigation,
      final bool invertColors,
      final Map<String, Map<String, dynamic>> pluginData,
      final double textScaleFactor,
      final DevicePreviewSettingsData? settings,
      final CustomDeviceInfoData? customDevice}) = _$_DevicePreviewData;

  factory _DevicePreviewData.fromJson(Map<String, dynamic> json) =
      _$_DevicePreviewData.fromJson;

  @override

  /// Indicate whether the toolbar is visible.
  bool get isToolbarVisible => throw _privateConstructorUsedError;
  @override

  /// Indicate whether the device simulation is enabled.
  bool get isEnabled => throw _privateConstructorUsedError;
  @override

  /// The current orientation of the device
  Orientation get orientation => throw _privateConstructorUsedError;
  @override

  /// The currently selected device.
  String? get deviceIdentifier => throw _privateConstructorUsedError;
  @override

  /// The currently selected device locale.
  String get locale => throw _privateConstructorUsedError;
  @override

  /// Indicate whether the frame is currently visible.
  bool get isFrameVisible => throw _privateConstructorUsedError;
  @override

  /// Indicate whether the mode is currently dark.
  bool get isDarkMode => throw _privateConstructorUsedError;
  @override

  /// Indicate whether texts are forced to bold.
  bool get boldText => throw _privateConstructorUsedError;
  @override

  /// Indicate whether the virtual keyboard is visible.
  bool get isVirtualKeyboardVisible => throw _privateConstructorUsedError;
  @override

  /// Indicate whether animations are disabled.
  bool get disableAnimations => throw _privateConstructorUsedError;
  @override

  /// Indicate whether the highcontrast mode is activated.
  bool get highContrast => throw _privateConstructorUsedError;
  @override

  /// Indicate whether the navigation is in accessible mode.
  bool get accessibleNavigation => throw _privateConstructorUsedError;
  @override

  /// Indicate whether image colors are inverted.
  bool get invertColors => throw _privateConstructorUsedError;
  @override

  /// Indicate whether image colors are inverted.
  Map<String, Map<String, dynamic>> get pluginData =>
      throw _privateConstructorUsedError;
  @override

  /// The current text scaling factor.
  double get textScaleFactor => throw _privateConstructorUsedError;
  @override
  DevicePreviewSettingsData? get settings => throw _privateConstructorUsedError;
  @override

  /// The custom device configuration
  CustomDeviceInfoData? get customDevice => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_DevicePreviewDataCopyWith<_$_DevicePreviewData> get copyWith =>
      throw _privateConstructorUsedError;
}

CustomDeviceInfoData _$CustomDeviceInfoDataFromJson(Map<String, dynamic> json) {
  return _CustomDeviceInfoData.fromJson(json);
}

/// @nodoc
mixin _$CustomDeviceInfoData {
  /// Identifier of the device.
  String get id => throw _privateConstructorUsedError;

  /// The device type.
  DeviceType get type => throw _privateConstructorUsedError;

  /// The device operating system.
  TargetPlatform get platform => throw _privateConstructorUsedError;

  /// The display name of the device.
  String get name => throw _privateConstructorUsedError;

  /// The safe areas when the device is in landscape orientation.
  @NullableEdgeInsetsJsonConverter()
  EdgeInsets? get rotatedSafeAreas => throw _privateConstructorUsedError;

  /// The safe areas when the device is in portrait orientation.
  @EdgeInsetsJsonConverter()
  EdgeInsets get safeAreas => throw _privateConstructorUsedError;

  /// The screen pixel density of the device.
  double get pixelRatio => throw _privateConstructorUsedError;

  /// The size in points of the screen content.
  @SizeJsonConverter()
  Size get screenSize => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CustomDeviceInfoDataCopyWith<CustomDeviceInfoData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CustomDeviceInfoDataCopyWith<$Res> {
  factory $CustomDeviceInfoDataCopyWith(CustomDeviceInfoData value,
          $Res Function(CustomDeviceInfoData) then) =
      _$CustomDeviceInfoDataCopyWithImpl<$Res>;
  $Res call(
      {String id,
      DeviceType type,
      TargetPlatform platform,
      String name,
      @NullableEdgeInsetsJsonConverter() EdgeInsets? rotatedSafeAreas,
      @EdgeInsetsJsonConverter() EdgeInsets safeAreas,
      double pixelRatio,
      @SizeJsonConverter() Size screenSize});
}

/// @nodoc
class _$CustomDeviceInfoDataCopyWithImpl<$Res>
    implements $CustomDeviceInfoDataCopyWith<$Res> {
  _$CustomDeviceInfoDataCopyWithImpl(this._value, this._then);

  final CustomDeviceInfoData _value;
  // ignore: unused_field
  final $Res Function(CustomDeviceInfoData) _then;

  @override
  $Res call({
    Object? id = freezed,
    Object? type = freezed,
    Object? platform = freezed,
    Object? name = freezed,
    Object? rotatedSafeAreas = freezed,
    Object? safeAreas = freezed,
    Object? pixelRatio = freezed,
    Object? screenSize = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: type == freezed
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DeviceType,
      platform: platform == freezed
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as TargetPlatform,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rotatedSafeAreas: rotatedSafeAreas == freezed
          ? _value.rotatedSafeAreas
          : rotatedSafeAreas // ignore: cast_nullable_to_non_nullable
              as EdgeInsets?,
      safeAreas: safeAreas == freezed
          ? _value.safeAreas
          : safeAreas // ignore: cast_nullable_to_non_nullable
              as EdgeInsets,
      pixelRatio: pixelRatio == freezed
          ? _value.pixelRatio
          : pixelRatio // ignore: cast_nullable_to_non_nullable
              as double,
      screenSize: screenSize == freezed
          ? _value.screenSize
          : screenSize // ignore: cast_nullable_to_non_nullable
              as Size,
    ));
  }
}

/// @nodoc
abstract class _$$_CustomDeviceInfoDataCopyWith<$Res>
    implements $CustomDeviceInfoDataCopyWith<$Res> {
  factory _$$_CustomDeviceInfoDataCopyWith(_$_CustomDeviceInfoData value,
          $Res Function(_$_CustomDeviceInfoData) then) =
      __$$_CustomDeviceInfoDataCopyWithImpl<$Res>;
  @override
  $Res call(
      {String id,
      DeviceType type,
      TargetPlatform platform,
      String name,
      @NullableEdgeInsetsJsonConverter() EdgeInsets? rotatedSafeAreas,
      @EdgeInsetsJsonConverter() EdgeInsets safeAreas,
      double pixelRatio,
      @SizeJsonConverter() Size screenSize});
}

/// @nodoc
class __$$_CustomDeviceInfoDataCopyWithImpl<$Res>
    extends _$CustomDeviceInfoDataCopyWithImpl<$Res>
    implements _$$_CustomDeviceInfoDataCopyWith<$Res> {
  __$$_CustomDeviceInfoDataCopyWithImpl(_$_CustomDeviceInfoData _value,
      $Res Function(_$_CustomDeviceInfoData) _then)
      : super(_value, (v) => _then(v as _$_CustomDeviceInfoData));

  @override
  _$_CustomDeviceInfoData get _value => super._value as _$_CustomDeviceInfoData;

  @override
  $Res call({
    Object? id = freezed,
    Object? type = freezed,
    Object? platform = freezed,
    Object? name = freezed,
    Object? rotatedSafeAreas = freezed,
    Object? safeAreas = freezed,
    Object? pixelRatio = freezed,
    Object? screenSize = freezed,
  }) {
    return _then(_$_CustomDeviceInfoData(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: type == freezed
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DeviceType,
      platform: platform == freezed
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as TargetPlatform,
      name: name == freezed
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rotatedSafeAreas: rotatedSafeAreas == freezed
          ? _value.rotatedSafeAreas
          : rotatedSafeAreas // ignore: cast_nullable_to_non_nullable
              as EdgeInsets?,
      safeAreas: safeAreas == freezed
          ? _value.safeAreas
          : safeAreas // ignore: cast_nullable_to_non_nullable
              as EdgeInsets,
      pixelRatio: pixelRatio == freezed
          ? _value.pixelRatio
          : pixelRatio // ignore: cast_nullable_to_non_nullable
              as double,
      screenSize: screenSize == freezed
          ? _value.screenSize
          : screenSize // ignore: cast_nullable_to_non_nullable
              as Size,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_CustomDeviceInfoData
    with DiagnosticableTreeMixin
    implements _CustomDeviceInfoData {
  const _$_CustomDeviceInfoData(
      {required this.id,
      required this.type,
      required this.platform,
      required this.name,
      @NullableEdgeInsetsJsonConverter() this.rotatedSafeAreas = null,
      @EdgeInsetsJsonConverter() required this.safeAreas,
      required this.pixelRatio,
      @SizeJsonConverter() required this.screenSize});

  factory _$_CustomDeviceInfoData.fromJson(Map<String, dynamic> json) =>
      _$$_CustomDeviceInfoDataFromJson(json);

  /// Identifier of the device.
  @override
  final String id;

  /// The device type.
  @override
  final DeviceType type;

  /// The device operating system.
  @override
  final TargetPlatform platform;

  /// The display name of the device.
  @override
  final String name;

  /// The safe areas when the device is in landscape orientation.
  @override
  @JsonKey()
  @NullableEdgeInsetsJsonConverter()
  final EdgeInsets? rotatedSafeAreas;

  /// The safe areas when the device is in portrait orientation.
  @override
  @EdgeInsetsJsonConverter()
  final EdgeInsets safeAreas;

  /// The screen pixel density of the device.
  @override
  final double pixelRatio;

  /// The size in points of the screen content.
  @override
  @SizeJsonConverter()
  final Size screenSize;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'CustomDeviceInfoData(id: $id, type: $type, platform: $platform, name: $name, rotatedSafeAreas: $rotatedSafeAreas, safeAreas: $safeAreas, pixelRatio: $pixelRatio, screenSize: $screenSize)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'CustomDeviceInfoData'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('platform', platform))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('rotatedSafeAreas', rotatedSafeAreas))
      ..add(DiagnosticsProperty('safeAreas', safeAreas))
      ..add(DiagnosticsProperty('pixelRatio', pixelRatio))
      ..add(DiagnosticsProperty('screenSize', screenSize));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_CustomDeviceInfoData &&
            const DeepCollectionEquality().equals(other.id, id) &&
            const DeepCollectionEquality().equals(other.type, type) &&
            const DeepCollectionEquality().equals(other.platform, platform) &&
            const DeepCollectionEquality().equals(other.name, name) &&
            const DeepCollectionEquality()
                .equals(other.rotatedSafeAreas, rotatedSafeAreas) &&
            const DeepCollectionEquality().equals(other.safeAreas, safeAreas) &&
            const DeepCollectionEquality()
                .equals(other.pixelRatio, pixelRatio) &&
            const DeepCollectionEquality()
                .equals(other.screenSize, screenSize));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(id),
      const DeepCollectionEquality().hash(type),
      const DeepCollectionEquality().hash(platform),
      const DeepCollectionEquality().hash(name),
      const DeepCollectionEquality().hash(rotatedSafeAreas),
      const DeepCollectionEquality().hash(safeAreas),
      const DeepCollectionEquality().hash(pixelRatio),
      const DeepCollectionEquality().hash(screenSize));

  @JsonKey(ignore: true)
  @override
  _$$_CustomDeviceInfoDataCopyWith<_$_CustomDeviceInfoData> get copyWith =>
      __$$_CustomDeviceInfoDataCopyWithImpl<_$_CustomDeviceInfoData>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_CustomDeviceInfoDataToJson(this);
  }
}

abstract class _CustomDeviceInfoData implements CustomDeviceInfoData {
  const factory _CustomDeviceInfoData(
          {required final String id,
          required final DeviceType type,
          required final TargetPlatform platform,
          required final String name,
          @NullableEdgeInsetsJsonConverter() final EdgeInsets? rotatedSafeAreas,
          @EdgeInsetsJsonConverter() required final EdgeInsets safeAreas,
          required final double pixelRatio,
          @SizeJsonConverter() required final Size screenSize}) =
      _$_CustomDeviceInfoData;

  factory _CustomDeviceInfoData.fromJson(Map<String, dynamic> json) =
      _$_CustomDeviceInfoData.fromJson;

  @override

  /// Identifier of the device.
  String get id => throw _privateConstructorUsedError;
  @override

  /// The device type.
  DeviceType get type => throw _privateConstructorUsedError;
  @override

  /// The device operating system.
  TargetPlatform get platform => throw _privateConstructorUsedError;
  @override

  /// The display name of the device.
  String get name => throw _privateConstructorUsedError;
  @override

  /// The safe areas when the device is in landscape orientation.
  @NullableEdgeInsetsJsonConverter()
  EdgeInsets? get rotatedSafeAreas => throw _privateConstructorUsedError;
  @override

  /// The safe areas when the device is in portrait orientation.
  @EdgeInsetsJsonConverter()
  EdgeInsets get safeAreas => throw _privateConstructorUsedError;
  @override

  /// The screen pixel density of the device.
  double get pixelRatio => throw _privateConstructorUsedError;
  @override

  /// The size in points of the screen content.
  @SizeJsonConverter()
  Size get screenSize => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_CustomDeviceInfoDataCopyWith<_$_CustomDeviceInfoData> get copyWith =>
      throw _privateConstructorUsedError;
}

DevicePreviewSettingsData _$DevicePreviewSettingsDataFromJson(
    Map<String, dynamic> json) {
  return _DevicePreviewSettingsData.fromJson(json);
}

/// @nodoc
mixin _$DevicePreviewSettingsData {
  /// The toolbar position.
  DevicePreviewToolBarPositionData get toolbarPosition =>
      throw _privateConstructorUsedError;

  /// The theme of the toolbar.
  DevicePreviewToolBarThemeData get toolbarTheme =>
      throw _privateConstructorUsedError;

  /// The theme of the background.
  DevicePreviewBackgroundThemeData get backgroundTheme =>
      throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DevicePreviewSettingsDataCopyWith<DevicePreviewSettingsData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DevicePreviewSettingsDataCopyWith<$Res> {
  factory $DevicePreviewSettingsDataCopyWith(DevicePreviewSettingsData value,
          $Res Function(DevicePreviewSettingsData) then) =
      _$DevicePreviewSettingsDataCopyWithImpl<$Res>;
  $Res call(
      {DevicePreviewToolBarPositionData toolbarPosition,
      DevicePreviewToolBarThemeData toolbarTheme,
      DevicePreviewBackgroundThemeData backgroundTheme});
}

/// @nodoc
class _$DevicePreviewSettingsDataCopyWithImpl<$Res>
    implements $DevicePreviewSettingsDataCopyWith<$Res> {
  _$DevicePreviewSettingsDataCopyWithImpl(this._value, this._then);

  final DevicePreviewSettingsData _value;
  // ignore: unused_field
  final $Res Function(DevicePreviewSettingsData) _then;

  @override
  $Res call({
    Object? toolbarPosition = freezed,
    Object? toolbarTheme = freezed,
    Object? backgroundTheme = freezed,
  }) {
    return _then(_value.copyWith(
      toolbarPosition: toolbarPosition == freezed
          ? _value.toolbarPosition
          : toolbarPosition // ignore: cast_nullable_to_non_nullable
              as DevicePreviewToolBarPositionData,
      toolbarTheme: toolbarTheme == freezed
          ? _value.toolbarTheme
          : toolbarTheme // ignore: cast_nullable_to_non_nullable
              as DevicePreviewToolBarThemeData,
      backgroundTheme: backgroundTheme == freezed
          ? _value.backgroundTheme
          : backgroundTheme // ignore: cast_nullable_to_non_nullable
              as DevicePreviewBackgroundThemeData,
    ));
  }
}

/// @nodoc
abstract class _$$_DevicePreviewSettingsDataCopyWith<$Res>
    implements $DevicePreviewSettingsDataCopyWith<$Res> {
  factory _$$_DevicePreviewSettingsDataCopyWith(
          _$_DevicePreviewSettingsData value,
          $Res Function(_$_DevicePreviewSettingsData) then) =
      __$$_DevicePreviewSettingsDataCopyWithImpl<$Res>;
  @override
  $Res call(
      {DevicePreviewToolBarPositionData toolbarPosition,
      DevicePreviewToolBarThemeData toolbarTheme,
      DevicePreviewBackgroundThemeData backgroundTheme});
}

/// @nodoc
class __$$_DevicePreviewSettingsDataCopyWithImpl<$Res>
    extends _$DevicePreviewSettingsDataCopyWithImpl<$Res>
    implements _$$_DevicePreviewSettingsDataCopyWith<$Res> {
  __$$_DevicePreviewSettingsDataCopyWithImpl(
      _$_DevicePreviewSettingsData _value,
      $Res Function(_$_DevicePreviewSettingsData) _then)
      : super(_value, (v) => _then(v as _$_DevicePreviewSettingsData));

  @override
  _$_DevicePreviewSettingsData get _value =>
      super._value as _$_DevicePreviewSettingsData;

  @override
  $Res call({
    Object? toolbarPosition = freezed,
    Object? toolbarTheme = freezed,
    Object? backgroundTheme = freezed,
  }) {
    return _then(_$_DevicePreviewSettingsData(
      toolbarPosition: toolbarPosition == freezed
          ? _value.toolbarPosition
          : toolbarPosition // ignore: cast_nullable_to_non_nullable
              as DevicePreviewToolBarPositionData,
      toolbarTheme: toolbarTheme == freezed
          ? _value.toolbarTheme
          : toolbarTheme // ignore: cast_nullable_to_non_nullable
              as DevicePreviewToolBarThemeData,
      backgroundTheme: backgroundTheme == freezed
          ? _value.backgroundTheme
          : backgroundTheme // ignore: cast_nullable_to_non_nullable
              as DevicePreviewBackgroundThemeData,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$_DevicePreviewSettingsData
    with DiagnosticableTreeMixin
    implements _DevicePreviewSettingsData {
  const _$_DevicePreviewSettingsData(
      {this.toolbarPosition = DevicePreviewToolBarPositionData.bottom,
      this.toolbarTheme = DevicePreviewToolBarThemeData.dark,
      this.backgroundTheme = DevicePreviewBackgroundThemeData.light});

  factory _$_DevicePreviewSettingsData.fromJson(Map<String, dynamic> json) =>
      _$$_DevicePreviewSettingsDataFromJson(json);

  /// The toolbar position.
  @override
  @JsonKey()
  final DevicePreviewToolBarPositionData toolbarPosition;

  /// The theme of the toolbar.
  @override
  @JsonKey()
  final DevicePreviewToolBarThemeData toolbarTheme;

  /// The theme of the background.
  @override
  @JsonKey()
  final DevicePreviewBackgroundThemeData backgroundTheme;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DevicePreviewSettingsData(toolbarPosition: $toolbarPosition, toolbarTheme: $toolbarTheme, backgroundTheme: $backgroundTheme)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DevicePreviewSettingsData'))
      ..add(DiagnosticsProperty('toolbarPosition', toolbarPosition))
      ..add(DiagnosticsProperty('toolbarTheme', toolbarTheme))
      ..add(DiagnosticsProperty('backgroundTheme', backgroundTheme));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DevicePreviewSettingsData &&
            const DeepCollectionEquality()
                .equals(other.toolbarPosition, toolbarPosition) &&
            const DeepCollectionEquality()
                .equals(other.toolbarTheme, toolbarTheme) &&
            const DeepCollectionEquality()
                .equals(other.backgroundTheme, backgroundTheme));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(toolbarPosition),
      const DeepCollectionEquality().hash(toolbarTheme),
      const DeepCollectionEquality().hash(backgroundTheme));

  @JsonKey(ignore: true)
  @override
  _$$_DevicePreviewSettingsDataCopyWith<_$_DevicePreviewSettingsData>
      get copyWith => __$$_DevicePreviewSettingsDataCopyWithImpl<
          _$_DevicePreviewSettingsData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$_DevicePreviewSettingsDataToJson(this);
  }
}

abstract class _DevicePreviewSettingsData implements DevicePreviewSettingsData {
  const factory _DevicePreviewSettingsData(
          {final DevicePreviewToolBarPositionData toolbarPosition,
          final DevicePreviewToolBarThemeData toolbarTheme,
          final DevicePreviewBackgroundThemeData backgroundTheme}) =
      _$_DevicePreviewSettingsData;

  factory _DevicePreviewSettingsData.fromJson(Map<String, dynamic> json) =
      _$_DevicePreviewSettingsData.fromJson;

  @override

  /// The toolbar position.
  DevicePreviewToolBarPositionData get toolbarPosition =>
      throw _privateConstructorUsedError;
  @override

  /// The theme of the toolbar.
  DevicePreviewToolBarThemeData get toolbarTheme =>
      throw _privateConstructorUsedError;
  @override

  /// The theme of the background.
  DevicePreviewBackgroundThemeData get backgroundTheme =>
      throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_DevicePreviewSettingsDataCopyWith<_$_DevicePreviewSettingsData>
      get copyWith => throw _privateConstructorUsedError;
}

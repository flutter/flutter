// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target

part of 'theme.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$DeviceFrameStyle {
  DeviceKeyboardStyle get keyboardStyle => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DeviceFrameStyleCopyWith<DeviceFrameStyle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceFrameStyleCopyWith<$Res> {
  factory $DeviceFrameStyleCopyWith(
          DeviceFrameStyle value, $Res Function(DeviceFrameStyle) then) =
      _$DeviceFrameStyleCopyWithImpl<$Res>;
  $Res call({DeviceKeyboardStyle keyboardStyle});

  $DeviceKeyboardStyleCopyWith<$Res> get keyboardStyle;
}

/// @nodoc
class _$DeviceFrameStyleCopyWithImpl<$Res>
    implements $DeviceFrameStyleCopyWith<$Res> {
  _$DeviceFrameStyleCopyWithImpl(this._value, this._then);

  final DeviceFrameStyle _value;
  // ignore: unused_field
  final $Res Function(DeviceFrameStyle) _then;

  @override
  $Res call({
    Object? keyboardStyle = freezed,
  }) {
    return _then(_value.copyWith(
      keyboardStyle: keyboardStyle == freezed
          ? _value.keyboardStyle
          : keyboardStyle // ignore: cast_nullable_to_non_nullable
              as DeviceKeyboardStyle,
    ));
  }

  @override
  $DeviceKeyboardStyleCopyWith<$Res> get keyboardStyle {
    return $DeviceKeyboardStyleCopyWith<$Res>(_value.keyboardStyle, (value) {
      return _then(_value.copyWith(keyboardStyle: value));
    });
  }
}

/// @nodoc
abstract class _$$_DeviceFrameStyleCopyWith<$Res>
    implements $DeviceFrameStyleCopyWith<$Res> {
  factory _$$_DeviceFrameStyleCopyWith(
          _$_DeviceFrameStyle value, $Res Function(_$_DeviceFrameStyle) then) =
      __$$_DeviceFrameStyleCopyWithImpl<$Res>;
  @override
  $Res call({DeviceKeyboardStyle keyboardStyle});

  @override
  $DeviceKeyboardStyleCopyWith<$Res> get keyboardStyle;
}

/// @nodoc
class __$$_DeviceFrameStyleCopyWithImpl<$Res>
    extends _$DeviceFrameStyleCopyWithImpl<$Res>
    implements _$$_DeviceFrameStyleCopyWith<$Res> {
  __$$_DeviceFrameStyleCopyWithImpl(
      _$_DeviceFrameStyle _value, $Res Function(_$_DeviceFrameStyle) _then)
      : super(_value, (v) => _then(v as _$_DeviceFrameStyle));

  @override
  _$_DeviceFrameStyle get _value => super._value as _$_DeviceFrameStyle;

  @override
  $Res call({
    Object? keyboardStyle = freezed,
  }) {
    return _then(_$_DeviceFrameStyle(
      keyboardStyle: keyboardStyle == freezed
          ? _value.keyboardStyle
          : keyboardStyle // ignore: cast_nullable_to_non_nullable
              as DeviceKeyboardStyle,
    ));
  }
}

/// @nodoc

class _$_DeviceFrameStyle
    with DiagnosticableTreeMixin
    implements _DeviceFrameStyle {
  const _$_DeviceFrameStyle({required this.keyboardStyle});

  @override
  final DeviceKeyboardStyle keyboardStyle;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DeviceFrameStyle(keyboardStyle: $keyboardStyle)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DeviceFrameStyle'))
      ..add(DiagnosticsProperty('keyboardStyle', keyboardStyle));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DeviceFrameStyle &&
            const DeepCollectionEquality()
                .equals(other.keyboardStyle, keyboardStyle));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(keyboardStyle));

  @JsonKey(ignore: true)
  @override
  _$$_DeviceFrameStyleCopyWith<_$_DeviceFrameStyle> get copyWith =>
      __$$_DeviceFrameStyleCopyWithImpl<_$_DeviceFrameStyle>(this, _$identity);
}

abstract class _DeviceFrameStyle implements DeviceFrameStyle {
  const factory _DeviceFrameStyle(
      {required final DeviceKeyboardStyle keyboardStyle}) = _$_DeviceFrameStyle;

  @override
  DeviceKeyboardStyle get keyboardStyle => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_DeviceFrameStyleCopyWith<_$_DeviceFrameStyle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DeviceKeyboardStyle {
  Color get backgroundColor => throw _privateConstructorUsedError;
  Color get button1BackgroundColor => throw _privateConstructorUsedError;
  Color get button1ForegroundColor => throw _privateConstructorUsedError;
  Color get button2BackgroundColor => throw _privateConstructorUsedError;
  Color get button2ForegroundColor => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DeviceKeyboardStyleCopyWith<DeviceKeyboardStyle> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceKeyboardStyleCopyWith<$Res> {
  factory $DeviceKeyboardStyleCopyWith(
          DeviceKeyboardStyle value, $Res Function(DeviceKeyboardStyle) then) =
      _$DeviceKeyboardStyleCopyWithImpl<$Res>;
  $Res call(
      {Color backgroundColor,
      Color button1BackgroundColor,
      Color button1ForegroundColor,
      Color button2BackgroundColor,
      Color button2ForegroundColor});
}

/// @nodoc
class _$DeviceKeyboardStyleCopyWithImpl<$Res>
    implements $DeviceKeyboardStyleCopyWith<$Res> {
  _$DeviceKeyboardStyleCopyWithImpl(this._value, this._then);

  final DeviceKeyboardStyle _value;
  // ignore: unused_field
  final $Res Function(DeviceKeyboardStyle) _then;

  @override
  $Res call({
    Object? backgroundColor = freezed,
    Object? button1BackgroundColor = freezed,
    Object? button1ForegroundColor = freezed,
    Object? button2BackgroundColor = freezed,
    Object? button2ForegroundColor = freezed,
  }) {
    return _then(_value.copyWith(
      backgroundColor: backgroundColor == freezed
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button1BackgroundColor: button1BackgroundColor == freezed
          ? _value.button1BackgroundColor
          : button1BackgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button1ForegroundColor: button1ForegroundColor == freezed
          ? _value.button1ForegroundColor
          : button1ForegroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button2BackgroundColor: button2BackgroundColor == freezed
          ? _value.button2BackgroundColor
          : button2BackgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button2ForegroundColor: button2ForegroundColor == freezed
          ? _value.button2ForegroundColor
          : button2ForegroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
    ));
  }
}

/// @nodoc
abstract class _$$_DeviceKeyboardStyleCopyWith<$Res>
    implements $DeviceKeyboardStyleCopyWith<$Res> {
  factory _$$_DeviceKeyboardStyleCopyWith(_$_DeviceKeyboardStyle value,
          $Res Function(_$_DeviceKeyboardStyle) then) =
      __$$_DeviceKeyboardStyleCopyWithImpl<$Res>;
  @override
  $Res call(
      {Color backgroundColor,
      Color button1BackgroundColor,
      Color button1ForegroundColor,
      Color button2BackgroundColor,
      Color button2ForegroundColor});
}

/// @nodoc
class __$$_DeviceKeyboardStyleCopyWithImpl<$Res>
    extends _$DeviceKeyboardStyleCopyWithImpl<$Res>
    implements _$$_DeviceKeyboardStyleCopyWith<$Res> {
  __$$_DeviceKeyboardStyleCopyWithImpl(_$_DeviceKeyboardStyle _value,
      $Res Function(_$_DeviceKeyboardStyle) _then)
      : super(_value, (v) => _then(v as _$_DeviceKeyboardStyle));

  @override
  _$_DeviceKeyboardStyle get _value => super._value as _$_DeviceKeyboardStyle;

  @override
  $Res call({
    Object? backgroundColor = freezed,
    Object? button1BackgroundColor = freezed,
    Object? button1ForegroundColor = freezed,
    Object? button2BackgroundColor = freezed,
    Object? button2ForegroundColor = freezed,
  }) {
    return _then(_$_DeviceKeyboardStyle(
      backgroundColor: backgroundColor == freezed
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button1BackgroundColor: button1BackgroundColor == freezed
          ? _value.button1BackgroundColor
          : button1BackgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button1ForegroundColor: button1ForegroundColor == freezed
          ? _value.button1ForegroundColor
          : button1ForegroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button2BackgroundColor: button2BackgroundColor == freezed
          ? _value.button2BackgroundColor
          : button2BackgroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
      button2ForegroundColor: button2ForegroundColor == freezed
          ? _value.button2ForegroundColor
          : button2ForegroundColor // ignore: cast_nullable_to_non_nullable
              as Color,
    ));
  }
}

/// @nodoc

class _$_DeviceKeyboardStyle
    with DiagnosticableTreeMixin
    implements _DeviceKeyboardStyle {
  const _$_DeviceKeyboardStyle(
      {required this.backgroundColor,
      required this.button1BackgroundColor,
      required this.button1ForegroundColor,
      required this.button2BackgroundColor,
      required this.button2ForegroundColor});

  @override
  final Color backgroundColor;
  @override
  final Color button1BackgroundColor;
  @override
  final Color button1ForegroundColor;
  @override
  final Color button2BackgroundColor;
  @override
  final Color button2ForegroundColor;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DeviceKeyboardStyle(backgroundColor: $backgroundColor, button1BackgroundColor: $button1BackgroundColor, button1ForegroundColor: $button1ForegroundColor, button2BackgroundColor: $button2BackgroundColor, button2ForegroundColor: $button2ForegroundColor)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DeviceKeyboardStyle'))
      ..add(DiagnosticsProperty('backgroundColor', backgroundColor))
      ..add(
          DiagnosticsProperty('button1BackgroundColor', button1BackgroundColor))
      ..add(
          DiagnosticsProperty('button1ForegroundColor', button1ForegroundColor))
      ..add(
          DiagnosticsProperty('button2BackgroundColor', button2BackgroundColor))
      ..add(DiagnosticsProperty(
          'button2ForegroundColor', button2ForegroundColor));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_DeviceKeyboardStyle &&
            const DeepCollectionEquality()
                .equals(other.backgroundColor, backgroundColor) &&
            const DeepCollectionEquality()
                .equals(other.button1BackgroundColor, button1BackgroundColor) &&
            const DeepCollectionEquality()
                .equals(other.button1ForegroundColor, button1ForegroundColor) &&
            const DeepCollectionEquality()
                .equals(other.button2BackgroundColor, button2BackgroundColor) &&
            const DeepCollectionEquality()
                .equals(other.button2ForegroundColor, button2ForegroundColor));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(backgroundColor),
      const DeepCollectionEquality().hash(button1BackgroundColor),
      const DeepCollectionEquality().hash(button1ForegroundColor),
      const DeepCollectionEquality().hash(button2BackgroundColor),
      const DeepCollectionEquality().hash(button2ForegroundColor));

  @JsonKey(ignore: true)
  @override
  _$$_DeviceKeyboardStyleCopyWith<_$_DeviceKeyboardStyle> get copyWith =>
      __$$_DeviceKeyboardStyleCopyWithImpl<_$_DeviceKeyboardStyle>(
          this, _$identity);
}

abstract class _DeviceKeyboardStyle implements DeviceKeyboardStyle {
  const factory _DeviceKeyboardStyle(
      {required final Color backgroundColor,
      required final Color button1BackgroundColor,
      required final Color button1ForegroundColor,
      required final Color button2BackgroundColor,
      required final Color button2ForegroundColor}) = _$_DeviceKeyboardStyle;

  @override
  Color get backgroundColor => throw _privateConstructorUsedError;
  @override
  Color get button1BackgroundColor => throw _privateConstructorUsedError;
  @override
  Color get button1ForegroundColor => throw _privateConstructorUsedError;
  @override
  Color get button2BackgroundColor => throw _privateConstructorUsedError;
  @override
  Color get button2ForegroundColor => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$$_DeviceKeyboardStyleCopyWith<_$_DeviceKeyboardStyle> get copyWith =>
      throw _privateConstructorUsedError;
}

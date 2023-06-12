/// The base class that all WinRT Enumerations extend or implement.
class WinRTEnum {
  final String? _name;

  final int value;

  const WinRTEnum(this.value, {String? name}) : _name = name;

  @override
  String toString() =>
      _name != null ? '$runtimeType.$_name' : '$runtimeType(value: $value)';
}

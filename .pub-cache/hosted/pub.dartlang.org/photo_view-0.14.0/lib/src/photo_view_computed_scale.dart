/// A class that work as a enum. It overloads the operator `*` saving the double as a multiplier.
///
/// ```
/// PhotoViewComputedScale.contained * 2
/// ```
///
class PhotoViewComputedScale {
  const PhotoViewComputedScale._internal(this._value, [this.multiplier = 1.0]);

  final String _value;
  final double multiplier;

  @override
  String toString() => 'Enum.$_value';

  static const contained = const PhotoViewComputedScale._internal('contained');
  static const covered = const PhotoViewComputedScale._internal('covered');

  PhotoViewComputedScale operator *(double multiplier) {
    return PhotoViewComputedScale._internal(_value, multiplier);
  }

  PhotoViewComputedScale operator /(double divider) {
    return PhotoViewComputedScale._internal(_value, 1 / divider);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoViewComputedScale &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

import 'package:petitparser/petitparser.dart';

/// Optimized parser to read character data.
class XmlCharacterDataParser extends Parser<String> {
  XmlCharacterDataParser(this._stopper, this._minLength)
      : assert(_stopper.length == 1, 'Invalid stopper character: $_stopper'),
        assert(_minLength >= 0, 'Invalid minimum length: $_minLength');

  final String _stopper;
  final int _minLength;

  @override
  Result<String> parseOn(Context context) {
    final buffer = context.buffer;
    final position = context.position;
    final index = position < buffer.length
        ? buffer.indexOf(_stopper, position)
        : buffer.length;
    final end = index == -1 ? buffer.length : index;
    return end - position < _minLength
        ? context.failure('Unable to parse character data.')
        : context.success(buffer.substring(position, end), end);
  }

  @override
  int fastParseOn(String buffer, int position) {
    final index = position < buffer.length
        ? buffer.indexOf(_stopper, position)
        : buffer.length;
    final end = index == -1 ? buffer.length : index;
    return end - position < _minLength ? -1 : end;
  }

  @override
  XmlCharacterDataParser copy() => XmlCharacterDataParser(_stopper, _minLength);

  @override
  bool hasEqualProperties(XmlCharacterDataParser other) =>
      super.hasEqualProperties(other) &&
      _stopper == other._stopper &&
      _minLength == other._minLength;
}

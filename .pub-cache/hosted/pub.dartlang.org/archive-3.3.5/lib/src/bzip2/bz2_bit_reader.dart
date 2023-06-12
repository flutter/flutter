import '../util/input_stream.dart';

class Bz2BitReader {
  InputStreamBase input;

  Bz2BitReader(this.input);

  int readByte() => readBits(8);

  /// Read a number of bits from the input stream.
  int readBits(int numBits) {
    if (numBits == 0) {
      return 0;
    }

    if (_bitPos == 0) {
      _bitPos = 8;
      _bitBuffer = input.readByte();
    }

    var value = 0;

    while (numBits > _bitPos) {
      value = (value << _bitPos) + (_bitBuffer & _bitMask[_bitPos]);
      numBits -= _bitPos;
      _bitPos = 8;
      _bitBuffer = input.readByte();
    }

    if (numBits > 0) {
      if (_bitPos == 0) {
        _bitPos = 8;
        _bitBuffer = input.readByte();
      }

      value = (value << numBits) +
          (_bitBuffer >> (_bitPos - numBits) & _bitMask[numBits]);

      _bitPos -= numBits;
    }

    return value;
  }

  int _bitBuffer = 0;
  int _bitPos = 0;

  static const List<int> _bitMask = [0, 1, 3, 7, 15, 31, 63, 127, 255];
}

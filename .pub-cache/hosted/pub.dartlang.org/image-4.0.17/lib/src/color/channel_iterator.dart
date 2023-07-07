import 'color.dart';

/// An iterator over the channels of a [Color].
class ChannelIterator extends Iterator<num> {
  int index = -1;
  Color color;

  ChannelIterator(this.color);

  @override
  bool moveNext() {
    index++;
    return index < color.length;
  }

  @override
  num get current => color[index];
}

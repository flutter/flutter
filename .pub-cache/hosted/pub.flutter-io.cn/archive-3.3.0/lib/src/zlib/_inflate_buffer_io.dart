import 'dart:io';

List<int>? inflateBuffer_(List<int> data) {
  return ZLibDecoder(raw: true).convert(data);
}

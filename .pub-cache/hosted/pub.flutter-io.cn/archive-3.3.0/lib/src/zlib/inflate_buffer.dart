import '_inflate_buffer_stub.dart'
  if (dart.library.io) '_inflate_buffer_io.dart'
  if (dart.library.js) '_inflate_buffer_html.dart';

List<int>? inflateBuffer(List<int> array) {
  return inflateBuffer_(array);
}

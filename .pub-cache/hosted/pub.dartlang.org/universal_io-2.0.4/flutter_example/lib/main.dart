import 'package:universal_io/io.dart';

void main() {
  try {
    HttpClient().getUrl(Uri.parse('example'));
    File('x').openRead();
    Directory('x').exists();
    Socket.connect('localhost', 12345);
  } catch (e) {
    // ...
  }
}

@TestOn('windows')

import 'package:test/test.dart';
import 'package:win32/src/winrt/foundation/uri.dart' as winrt_uri;
import 'package:win32/winrt.dart';

// Test the WinRT Uri object to make sure overrides, properties and
// methods are working correctly.

void main() {
  if (isWindowsRuntimeAvailable()) {
    setUp(winrtInitialize);

    test('createUri', () {
      final uri = Uri.parse(
          'https://www.example.com:443/path/to/file.html?q1=v1&q2=v2#fragment');
      final winrtUri = winrt_uri.Uri.createUri(uri.toString());
      expect(winrtUri.rawUri, equals(uri.toString()));
      expect(winrtUri.absoluteUri, equals(uri.toString()));
      expect(winrtUri.absoluteCanonicalUri, equals(uri.toString()));
      expect(winrtUri.displayIri, equals(uri.toString()));
      expect(winrtUri.displayUri, equals(uri.toString()));
      expect(winrtUri.toString(), equals(uri.toString()));
      expect(winrtUri.schemeName, equals('https'));
      expect(winrtUri.host, equals('www.example.com'));
      expect(winrtUri.domain, equals('example.com'));
      expect(winrtUri.port, equals(443));
      expect(winrtUri.userName, isEmpty);
      expect(winrtUri.password, isEmpty);
      expect(winrtUri.path, equals('/path/to/file.html'));
      expect(winrtUri.extension, equals('.html'));
      expect(winrtUri.query, equals('?q1=v1&q2=v2'));
      expect(winrtUri.queryParsed.size, equals(2));
      final queryParameters = winrtUri.queryParsed.toList();
      expect(queryParameters.length, equals(2));
      expect(queryParameters.first.name, equals('q1'));
      expect(queryParameters.first.value, equals('v1'));
      expect(queryParameters.last.name, equals('q2'));
      expect(queryParameters.last.value, equals('v2'));
      expect(winrtUri.fragment, equals('#fragment'));
    });

    tearDown(winrtUninitialize);
  }
}

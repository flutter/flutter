/// A script to generate a Dart cache of https://www.iana.org.  This should be
/// run occasionally.  It was created since iana.org was found to be flakey.
///
/// To execute: dart gen_subtag_registry.dart > language_subtag_registry.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String registry = 'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry';

Future<void> main() async {
  final HttpClient client = HttpClient();
  final HttpClientRequest request = await client.getUrl(Uri.parse(registry));
  final HttpClientResponse response = await request.close();
  final String body = (await response.cast<List<int>>().transform<String>(utf8.decoder).toList()).join('');
  print('''/// Cache of $registry.
const String languageSubtagRegistry = \'\'\'$body\'\'\';''');
  client.close(force: true);
}
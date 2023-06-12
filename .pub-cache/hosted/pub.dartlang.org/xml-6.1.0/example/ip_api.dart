/// IP Geolocation API using ip-api.com.
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart' as args;
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

final HttpClient httpClient = HttpClient();

final args.ArgParser argumentParser = args.ArgParser()
  ..addFlag(
    'incremental',
    abbr: 'i',
    defaultsTo: true,
    help: 'Incrementally parses and prints the response',
  )
  ..addMultiOption('fields',
      abbr: 'f',
      defaultsTo: ['status', 'message', 'query', 'country', 'city'],
      allowed: [
        'as',
        'asname',
        'city',
        'continent',
        'continentCode',
        'country',
        'countryCode',
        'currency',
        'district',
        'isp',
        'lat',
        'lon',
        'message',
        'mobile',
        'org',
        'proxy',
        'query',
        'region',
        'regionName',
        'reverse',
        'status',
        'timezone',
        'zip',
      ],
      help: 'Fields to be returned')
  ..addOption(
    'lang',
    abbr: 'l',
    defaultsTo: 'en',
    allowed: ['en', 'de', 'es', 'pt-BR', 'fr', 'ja', 'zh-CN', 'ru'],
    help: 'Localizes city, region and country names',
  )
  ..addFlag(
    'help',
    abbr: 'h',
    defaultsTo: false,
    help: 'Displays the help text',
  );

void printUsage() {
  stdout.writeln('Usage: ip_lookup -s [query]');
  stdout.writeln();
  stdout.writeln(argumentParser.usage);
  exit(1);
}

Future<void> lookupIp(args.ArgResults results, [String query = '']) async {
  final bool incremental = results['incremental'];
  final List<String> fields = results['fields'];
  final String lang = results['lang'];

  // Build the query URL, perform the request, and convert response to UTF-8.
  final url = Uri.parse(
      'http://ip-api.com/xml/$query?fields=${fields.join(',')}&lang=$lang');
  final request = await httpClient.getUrl(url);
  final response = await request.close();
  final stream = response.transform(utf8.decoder);

  // Typically you would only implement one of the following two approaches,
  // but for demonstration sake we show both in this example:
  if (incremental) {
    void textHandler(XmlEvent event, String text) =>
        stdout.writeln('${event.parent?.name}: $text');

    // Decode the input stream, normalize it, attach parent information,
    // select the events we are interested in, then print the information.
    // This approach uses less memory and is emitting results incrementally;
    // thought the implementation is more involved.
    await stream
        .toXmlEvents()
        .normalizeEvents()
        .withParentEvents()
        .selectSubtreeEvents((event) => event.parent?.name == 'query')
        .forEachEvent(
          onText: (event) => textHandler(event, event.text),
          onCDATA: (event) => textHandler(event, event.text),
        );
  } else {
    // Wait until we have the full response body, then parse the input to a
    // XML DOM tree and extract the information to be printed. This approach
    // uses more memory and waits for the complete data to be downloaded
    // and parsed before printing any results; thought the implementation is
    // simpler.
    final input = await stream.join();
    final document = XmlDocument.parse(input);
    for (final element in document.rootElement.childElements) {
      stdout.writeln('${element.name}: ${element.innerText}');
    }
  }
}

Future<void> main(List<String> arguments) async {
  final results = argumentParser.parse(arguments);

  if (results['help']) {
    printUsage();
  }

  if (results.rest.isEmpty) {
    await lookupIp(results);
  } else {
    for (final query in results.rest) {
      await lookupIp(results, query);
      stdout.writeln();
    }
  }
}

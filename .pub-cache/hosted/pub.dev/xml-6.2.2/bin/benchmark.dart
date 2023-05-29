import 'dart:io';

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import '../test/utils/examples.dart';

/// Measures the time it takes to run [function] in microseconds.
///
/// It does so in two steps:
///
///  - the code is warmed up for the duration of [warmup]; and
///  - the code is benchmarked for the duration of [measure].
///
/// The resulting duration is the average time measured to run [function] once.
double benchmark(void Function() function,
    {Duration warmup = const Duration(milliseconds: 200),
    Duration measure = const Duration(seconds: 2)}) {
  _benchmark(function, warmup);
  return _benchmark(function, measure);
}

double _benchmark(void Function() function, Duration duration) {
  final watch = Stopwatch();
  final micros = duration.inMicroseconds;
  var count = 0;
  var elapsed = 0;
  watch.start();
  while (elapsed < micros) {
    function();
    elapsed = watch.elapsedMicroseconds;
    count++;
  }
  return elapsed / count;
}

/// Compare the speedup between [reference] and [comparison] in percentage.
///
/// A result of 0 means that both reference and comparison run at the same
/// speed. A positive number signifies a speedup, a negative one a slowdown.
double percentChange(double reference, double comparison) =>
    100 * (reference - comparison) / reference;

String characterData() {
  const string = '''a&bc<def"gehi'jklm>nopqr''';
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0"');
  builder.element('character', nest: () {
    for (var i = 0; i < 20; i++) {
      builder.text('$string$string$string$string$string$string');
      builder.element('foo', nest: () {
        builder.attribute('key', '$string$string$string$string');
      });
    }
  });
  return builder.buildDocument().toString();
}

final Map<String, String> benchmarks = {
  'atom': atomXml,
  'books': booksXml,
  'bookstore': bookstoreXml,
  'complicated': complicatedXml,
  'shiporder': shiporderXsd,
  'decoding': characterData(),
};

void main(List<String> args) {
  final builder = XmlBuilder();
  addBenchmarks(builder);
  final document = builder.buildDocument();
  if (args.contains('xml')) {
    stdout.writeln(document.toXmlString(pretty: true));
  } else {
    stdout.writeln([
      '',
      ...document
          .findAllElements('benchmark')
          .first
          .findAllElements('measure')
          .map((measure) => measure.getAttribute('name'))
    ].join(';'));
    stdout.write(document
        .findAllElements('benchmark')
        .map((benchmark) => [
              benchmark.getAttribute('name'),
              ...benchmark.findAllElements('time').map((time) => time.innerText)
            ].join(';'))
        .join('\n'));
  }
}

void addBenchmarks(XmlBuilder builder) {
  builder.processing('xml', 'version="1.0"');
  builder.element('benchmarks', nest: () {
    for (final entry in benchmarks.entries) {
      addBenchmark(builder, entry);
    }
  });
}

void addBenchmark(XmlBuilder builder, MapEntry<String, String> entry) {
  builder.element('benchmark', attributes: {'name': entry.key}, nest: () {
    final source = entry.value;
    final document = XmlDocument.parse(source);
    final parser = benchmark(() => XmlDocument.parse(source));
    final streamEvents = benchmark(() => XmlEventDecoder().convert(source));
    final streamNodes = benchmark(
        () => XmlNodeDecoder().convert(XmlEventDecoder().convert(source)));
    final iterator = benchmark(() => parseEvents(source).toList());
    final serialize = benchmark(() => document.toXmlString());
    final serializePretty = benchmark(() => document.toXmlString(pretty: true));
    addMeasure(builder, 'parser', parser);
    addMeasure(builder, 'streamEvents', streamEvents, parser);
    addMeasure(builder, 'streamNodes', streamNodes, parser);
    addMeasure(builder, 'iterator', iterator, parser);
    addMeasure(builder, 'serialize', serialize);
    addMeasure(builder, 'serializePretty', serializePretty, serialize);
  });
}

void addMeasure(XmlBuilder builder, String name, double measure,
    [double? reference]) {
  builder.element('measure', attributes: {'name': name}, nest: () {
    builder.element('time', nest: measure.toStringAsFixed(6));
    if (reference != null) {
      final speedup = percentChange(reference, measure);
      builder.element('speedup', nest: speedup.toStringAsFixed(2));
    }
  });
}

import 'dart:convert' show Converter;

import 'package:meta/meta.dart';

import 'conversion_sink.dart';

abstract class XmlListConverter<S, T> extends Converter<List<S>, List<T>> {
  const XmlListConverter();

  @override
  @nonVirtual
  List<T> convert(List<S> input) {
    final list = <T>[];
    final sink = ConversionSink<List<T>>(list.addAll);
    startChunkedConversion(sink)
      ..add(input)
      ..close();
    return list;
  }
}

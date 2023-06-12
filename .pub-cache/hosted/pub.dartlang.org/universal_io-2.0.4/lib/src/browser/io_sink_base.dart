// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';

import '../io_impl_js.dart';

/// A base class for [IOSink] subclasses.
abstract class IOSinkBase implements IOSink {
  @override
  Encoding encoding = utf8;

  @override
  Future addStream(Stream<List<int>> stream) {
    return stream.listen((data) {
      add(data);
    }, onError: (error, stackTrace) {
      addError(error, stackTrace);
    }).asFuture();
  }

  @override
  Future flush() {
    return Future.value(null);
  }

  @override
  void write(Object? obj) {
    add(const Utf8Encoder().convert('$obj'));
  }

  @override
  void writeAll(Iterable objects, [String separator = '']) {
    var isFirst = true;
    for (var object in objects) {
      if (isFirst) {
        isFirst = false;
      } else {
        write(separator);
      }
      write(object);
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? obj = '']) {
    if (obj != '') {
      write(obj);
    }
    write('\n');
  }
}

// Copyright 2014 Google Inc. All Rights Reserved.
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

library quiver.async.future_stream_test;

import 'dart:async';

import 'package:quiver/src/async/future_stream.dart';
import 'package:test/test.dart';

void main() {
  group('FutureStream', () {
    test('should forward an event', () {
      var completer = Completer<Stream<String>>();
      var controller = StreamController<String>();
      var futureStream = FutureStream(completer.future);

      var done = futureStream.first.then((s) {
        expect(s, 'hello');
      });

      completer.complete(controller.stream);
      controller.add('hello');

      return done;
    });

    test('should close when the wrapped Steam closes', () {
      var completer = Completer<Stream<String>>();
      var controller = StreamController<String>();
      var futureStream = FutureStream(completer.future);

      var testCompleter = Completer();

      futureStream.listen((_) {}, onDone: () {
        // pass
        testCompleter.complete();
      });

      completer.complete(controller.stream);
      controller.close();

      return testCompleter.future;
    });

    test('should forward errors', () {
      var completer = Completer<Stream<String>>();
      var controller = StreamController<String>();
      var futureStream = FutureStream(completer.future);

      var testCompleter = Completer();

      futureStream.listen((_) {}, onError: (e) {
        expect(e, 'error');
        testCompleter.complete();
      });

      completer.complete(controller.stream);
      controller.addError('error');

      return testCompleter.future;
    });

    test('should be broadcast', () {
      var completer = Completer<Stream<String>>();
      var futureStream = FutureStream(completer.future, broadcast: true);
      expect(futureStream.isBroadcast, isTrue);
    });
  });
}

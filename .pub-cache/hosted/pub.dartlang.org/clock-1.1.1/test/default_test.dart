// Copyright 2018 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:clock/clock.dart';

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('the default clock returns the system time', () {
    expect(DateTime.now().difference(clock.now()).inMilliseconds.abs(),
        lessThan(100));
  });

  group('withClock()', () {
    group('overrides the clock', () {
      test('synchronously', () {
        var time = date(1990, 11, 8);
        withClock(Clock(() => time), () {
          expect(clock.now(), equals(time));
          time = date(2016, 6, 26);
          expect(clock.now(), equals(time));
        });
      });

      test('asynchronously', () {
        var time = date(1990, 11, 8);
        withClock(Clock.fixed(time), () {
          expect(Future(() async {
            expect(clock.now(), equals(time));
          }), completes);
        });
      });

      test('within another withClock() call', () {
        var outerTime = date(1990, 11, 8);
        withClock(Clock.fixed(outerTime), () {
          expect(clock.now(), equals(outerTime));

          var innerTime = date(2016, 11, 8);
          withClock(Clock.fixed(innerTime), () {
            expect(clock.now(), equals(innerTime));
            expect(Future(() async {
              expect(clock.now(), equals(innerTime));
            }), completes);
          });

          expect(clock.now(), equals(outerTime));
        });
      });
    });

    test("with isFinal: true doesn't allow nested calls", () {
      var outerTime = date(1990, 11, 8);
      withClock(Clock.fixed(outerTime), () {
        expect(clock.now(), equals(outerTime));

        expect(() => withClock(fixed(2016, 11, 8), neverCalledVoid),
            throwsStateError);

        expect(clock.now(), equals(outerTime));
        // ignore: deprecated_member_use_from_same_package
      }, isFinal: true);
    });
  });
}

/// A wrapper for [neverCalled] that works around sdk#33015.
void Function() get neverCalledVoid {
  var function = neverCalled;
  return () => function();
}

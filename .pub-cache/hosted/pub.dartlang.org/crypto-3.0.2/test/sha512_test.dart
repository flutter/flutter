// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  group('SHA2-384', () {
    group('with a chunked converter', () {
      test('add may not be called after close', () {
        var sink =
            sha384.startChunkedConversion(StreamController<Digest>().sink);
        sink.close();
        expect(() => sink.add([0]), throwsStateError);
      });

      test('close may be called multiple times', () {
        var sink =
            sha384.startChunkedConversion(StreamController<Digest>().sink);
        sink.close();
        sink.close();
        sink.close();
        sink.close();
      });

      test('close closes the underlying sink', () {
        var inner = ChunkedConversionSink<Digest>.withCallback(
            expectAsync1((accumulated) {
          expect(accumulated.length, equals(1));
          expect(
              accumulated.first.toString(),
              equals(
                  '38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b'));
        }));

        var outer = sha384.startChunkedConversion(inner);
        outer.close();
      });
    });
  });

  group('SHA2-512', () {
    group('with a chunked converter', () {
      test('add may not be called after close', () {
        var sink =
            sha512.startChunkedConversion(StreamController<Digest>().sink);
        sink.close();
        expect(() => sink.add([0]), throwsStateError);
      });

      test('close may be called multiple times', () {
        var sink =
            sha512.startChunkedConversion(StreamController<Digest>().sink);
        sink.close();
        sink.close();
        sink.close();
        sink.close();
      });

      test('close closes the underlying sink', () {
        var inner = ChunkedConversionSink<Digest>.withCallback(
            expectAsync1((accumulated) {
          expect(accumulated.length, equals(1));
          expect(
              accumulated.first.toString(),
              equals(
                  'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e'));
        }));

        var outer = sha512.startChunkedConversion(inner);
        outer.close();
      });
    });

    test('128 bit padding', () {
      final salts = [
        'AAAA{3FXhiiyc5gGWlRrVQ2RlJ.6xj.DKvf6l0bJxqh0BzA}'.codeUnits,
        'AAAA{3FXhiiyc5gGWlRrVQ.2RlJ6xj.DKvf6l0bJxqh0BzA}'.codeUnits,
        'AAAA{rFXhiiyc5gGWlVQ.2RlJ6xj.DKvf6lFXhiiyc5gGWl0}'.codeUnits,
      ];

      const results = [
        'nYg7eEsF/P7/l1AO0w8JFNNomS1gC76VE7Eg7Dpet+Dh6XiScDntYEU4tVItXp67evaLFvtMpW2uVJBZVKrBPw==',
        'TXNM4uk1Iwr2cYisWSdFifXdjfNiJTGEmNaMtqYrwJoS3JXpL1rebPKPfKudbFQGpcgJkLLhhpfnLzULBqq8KA==',
        'ckPYMDuPJjc73qHXQZiJgCskNG8mj9cPqFNsqYqxcBbQESgkWChoibAN7ssJrnoMFIpz9HwsBwMtt3z/KDUh9w==',
      ];

      for (var i = 0; i < salts.length; i++) {
        var digest = <int>[];
        for (var run = 0; run < 2000; run++) {
          digest = sha512.convert([...digest, ...salts[i]]).bytes;
        }
        expect(base64.encode(digest), results[i]);
      }
    });
  });
}

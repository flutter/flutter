// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/compiler/request_channel.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:test/test.dart';

main() {
  group('ByteDataSerializer', () {
    group('addAny', () {
      Uint8List write(Object? object) {
        final serializer = ByteDataSerializer();
        serializer.addAny(object);
        return serializer.result;
      }

      Object? read(Uint8List bytes) {
        final deserializer = ByteDataDeserializer(
          new ByteData.sublistView(bytes),
        );
        return deserializer.expectAny();
      }

      void writeRead(Object? object) {
        final bytes = write(object);
        expect(read(bytes), object);
      }

      group('bool', () {
        test('false', () {
          writeRead(false);
        });
        test('true', () {
          writeRead(true);
        });
      });

      test('null', () {
        writeRead(null);
      });

      group('int', () {
        test('negative', () {
          void writeReadInt(int value) {
            expect(value, isNegative);
            writeRead(value);
          }

          writeReadInt(-1);
          writeReadInt(-2);
          writeReadInt(-0x7F);
          writeReadInt(-0xFF);
          writeReadInt(-0xFFFF);
          writeReadInt(-0xFFFFFF);
          writeReadInt(-0xFFFFFFFF);
          writeReadInt(-0xFFFFFFFFFF);
          writeReadInt(-0xFFFFFFFFFFFF);
          writeReadInt(-0xFFFFFFFFFFFFFF);
          writeReadInt(-0x7FFFFFFFFFFFFFFF);
          writeReadInt(0x8000000000000000);
        });

        test('non-negative', () {
          void writeReadInt(int value) {
            expect(value, isNonNegative);
            writeRead(value);
          }

          writeReadInt(0);
          writeReadInt(1);
          writeReadInt(0x6F);
          writeReadInt(0x7F);
          writeReadInt(0xFF);
          writeReadInt(0xFFFF);
          writeReadInt(0xFFFFFF);
          writeReadInt(0xFFFFFFFF);
          writeReadInt(0xFFFFFFFFFF);
          writeReadInt(0xFFFFFFFFFFFF);
          writeReadInt(0xFFFFFFFFFFFFFF);
          writeReadInt(0x7FFFFFFFFFFFFFFF);
        });
      });

      group('String', () {
        test('one-byte', () {
          writeRead('test');
        });
        test('two-byte', () {
          writeRead('проба');
        });
      });

      group('list', () {
        test('empty', () {
          writeRead(<int>[]);
        });
        test('of int', () {
          writeRead([1, 2, 3]);
        });
        test('of string', () {
          writeRead(['a', 'b', 'c']);
        });
        test('mixed', () {
          writeRead([true, 'abc', 0xAB]);
        });
        test('nested', () {
          writeRead([
            [1, 2, 3],
            true,
            ['foo', 'bar'],
            false,
          ]);
        });
      });

      group('map', () {
        test('empty', () {
          writeRead(<String, int>{});
        });
        test('string to int', () {
          writeRead({'a': 0x11, 'b': 0x22});
        });
        test('nested', () {
          writeRead({
            'foo': {0: 1, 2: 3},
            'bar': {4: 5, 6: 7},
          });
        });
      });

      group('Uint8List', () {
        test('empty', () {
          writeRead(Uint8List(0));
        });
        test('5 elements', () {
          writeRead(
            Uint8List.fromList(
              [0x11, 0x22, 0x33, 0x44, 0x55],
            ),
          );
        });
        test('0..4096', () {
          for (int length = 1; length < 4096; length++) {
            Uint8List object = Uint8List(length);
            for (int i = 0; i < object.length; i++) {
              object[i] = i & 0xFF;
            }
            Uint8List bytes = write(object);
            Uint8List readObject = read(bytes) as Uint8List;
            for (int i = 0; i < object.length; i++) {
              if (object[i] != readObject[i]) {
                fail('[length: $length][i: $i]');
              }
            }
          }
        });
        test('nested in Map', () {
          writeRead({
            'answer': 42,
            'result': Uint8List.fromList(
              [0x11, 0x22, 0x33, 0x44, 0x55],
            ),
            'hasErrors': false,
          });
        });
      });

      group('JSON', () {
        test('command', () {
          writeRead({
            'command': 'compile',
            'argument': {
              'uri': 'input.dart',
              'additional': ['a', 'b', 'c'],
            },
          });
        });
      });
    });
  });

  group('RequestChannel', () {
    Future<void> runServerClient({
      required Future<void> Function(RequestChannel channel) server,
      required Future<void> Function(RequestChannel channel) client,
    }) async {
      ServerSocket serverSocket =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      serverSocket.listen((socket) async {
        await serverSocket.close();
        await server(
          RequestChannel(socket),
        );
      });

      var clientSocket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        serverSocket.port,
      );
      try {
        await client(
          RequestChannel(clientSocket),
        );
      } finally {
        clientSocket.destroy();
      }
    }

    test('exception', () async {
      await runServerClient(
        server: (channel) async {
          channel.add('throwIt', (argument) async {
            throw 'Some error';
          });
        },
        client: (channel) async {
          try {
            await channel.sendRequest('throwIt', {});
            fail('Expected to throw RemoteException.');
          } on RemoteException catch (e) {
            expect(e.message, 'Some error');
            expect(e.stackTrace, isNotEmpty);
          }
        },
      );
    });

    test('no handler', () async {
      await runServerClient(
        server: (channel) async {},
        client: (channel) async {
          try {
            await channel.sendRequest('noSuchHandler', {});
            fail('Expected to throw RemoteException.');
          } on RemoteException catch (e) {
            expect(e.message, contains('noSuchHandler'));
            expect(e.stackTrace, isNotEmpty);
          }
        },
      );
    });

    test('two-way communication', () async {
      await runServerClient(
        server: (channel) async {
          channel.add('add', (argument) async {
            if (argument is List<Object?> && argument.length == 2) {
              Object? a = argument[0];
              Object? b = argument[1];
              if (a is int && b is int) {
                int more = await channel.sendRequest<int>('more', null);
                return a + b + more;
              }
            }
            return '<bad>';
          });
        },
        client: (channel) async {
          channel.add('more', (_) async => 4);
          expect(await channel.sendRequest('add', [2, 3]), 9);
        },
      );
    });
  });
}

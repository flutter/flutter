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

part of main_test;

void _testInternetAddress() {
  group('InternetAddress', () {
    test('== / hashCode', () {
      final value = InternetAddress('10.0.0.1');
      final clone = InternetAddress('10.0.0.1');
      final other = InternetAddress('10.0.0.2');
      expect(value, clone);
      expect(value, isNot(other));
      expect(value.hashCode, clone.hashCode);
      expect(value.hashCode, isNot(other.hashCode));
    });

    test('InternetAddress.loopbackIPv4', () {
      expect(InternetAddress.loopbackIPv4.address, '127.0.0.1');
    });

    test('InternetAddress.loopbackIPv6', () {
      expect(InternetAddress.loopbackIPv6.address, '::1');
    });

    group('InternetAddress(...) when IPv4', () {
      test('255.0.254.1', () {
        final address = InternetAddress('255.0.254.1');
        expect(address.address, '255.0.254.1');
        expect(address.host, '255.0.254.1');
        expect(address.rawAddress, [255, 0, 254, 1]);
      });

      test('255.0.254.1, type: InternetAddressType.IPv4', () {
        final address = InternetAddress(
          '255.0.254.1',
          type: InternetAddressType.IPv4,
        );
        expect(address.address, '255.0.254.1');
        expect(address.host, '255.0.254.1');
        expect(address.rawAddress, [255, 0, 254, 1]);
      });

      test('255.0.254.1, type: InternetAddressType.IPv6', () {
        final address = InternetAddress(
          '255.0.254.1',
          type: InternetAddressType.IPv6,
        );
        expect(address.address, '255.0.254.1');
        expect(address.host, '255.0.254.1');
        expect(address.rawAddress, [255, 0, 254, 1]);
      });
    });

    group('InternetAddress(...) when IPv6', () {
      test("'0123:4567:89ab:cdef:0123:4567:89ab:cdef'", () {
        final actual = InternetAddress(
          '0123:4567:89ab:cdef:0123:4567:89ab:cdef',
        ).rawAddress;
        final expected = Uint8List(16);
        expected[0] = 0x01;
        expected[1] = 0x23;
        expected[2] = 0x45;
        expected[3] = 0x67;
        expected[4] = 0x89;
        expected[5] = 0xAB;
        expected[6] = 0xCD;
        expected[7] = 0xEF;
        expected[8] = 0x01;
        expected[9] = 0x23;
        expected[10] = 0x45;
        expected[11] = 0x67;
        expected[12] = 0x89;
        expected[13] = 0xAB;
        expected[14] = 0xCD;
        expected[15] = 0xEF;
        expect(actual, orderedEquals(expected));
      });

      test("'::'", () {
        final actual = InternetAddress('::').rawAddress;
        final expected = Uint8List(16);
        expect(actual, orderedEquals(expected));
      });

      test("'1::'", () {
        final actual = InternetAddress('1::').rawAddress;
        final expected = Uint8List(16);
        expected[1] = 1;
        expect(actual, orderedEquals(expected));
      });

      test("'::1'", () {
        final actual = InternetAddress('::1').rawAddress;
        final expected = Uint8List(16);
        expected[15] = 1;
        expect(actual, orderedEquals(expected));
      });

      test("'abcd:ef01::'", () {
        final actual = InternetAddress('abcd:ef01::').rawAddress;
        final expected = Uint8List(16);
        expected[0] = 0xAB;
        expected[1] = 0xCD;
        expected[2] = 0xEF;
        expected[3] = 0x01;
        expect(actual, orderedEquals(expected));
      });

      test("'::abcd:ef01'", () {
        final actual = InternetAddress('::abcd:ef01').rawAddress;
        final expected = Uint8List(16);
        expected[12] = 0xAB;
        expected[13] = 0xCD;
        expected[14] = 0xEF;
        expected[15] = 0x01;
        expect(actual, orderedEquals(expected));
      });
    });

    test('address (IPv4)', () {
      expect(InternetAddress('0.1.2.9').address, '0.1.2.9');
    });

    group('address (IPv6)', () {
      test("'0123:4567:89ab:cdef:0123:4567:89ab:cdef'", () {
        expect(
          InternetAddress('0123:4567:89ab:cdef:0123:4567:89ab:cdef').address,
          '0123:4567:89ab:cdef:0123:4567:89ab:cdef',
        );
      });

      test("'::'", () {
        expect(InternetAddress('::').address, '::');
      });

      test("'1::'", () {
        expect(InternetAddress('1::').address, '1::');
      });

      test("'::1'", () {
        expect(InternetAddress('::1').address, '::1');
      });

      test("'1::1'", () {
        expect(InternetAddress('1::1').address, '1::1');
      });

      test("'1:0:0:2::3:0:0:4'", () {
        expect(InternetAddress('1:0:2::3:0:4').address, '1:0:2::3:0:4');
      });

      test("'1:2:3:4:5:6:ff00:0'", () {
        expect(InternetAddress('1:2:3:4:5:6:ff00:0').address,
            '1:2:3:4:5:6:ff00:0');
      });

      test("'1:2:3:4:5:ff00:0:0'", () {
        expect(InternetAddress('1:2:3:4:5:ff00:0:0').address,
            '1:2:3:4:5:ff00:0:0');
      });
    });

    test('host', () {
      expect(InternetAddress('0.1.2.9').host, '0.1.2.9');
      expect(InternetAddress('::').host, '::');
      expect(
          InternetAddress('/abc', type: InternetAddressType.unix).host, '/abc');
    });

    test('type', () {
      expect(InternetAddress('0.1.2.9').type, InternetAddressType.IPv4);
      expect(InternetAddress('::').type, InternetAddressType.IPv6);
      expect(InternetAddress('/abc', type: InternetAddressType.unix).type,
          InternetAddressType.unix);
    });

    test('isLoopback', () {
      // False
      expect(InternetAddress('8.8.8.8').isLoopback, isFalse);
      expect(InternetAddress('10.0.0.0').isLoopback, isFalse);
      expect(InternetAddress('::').isLoopback, isFalse);
      expect(InternetAddress('/abc', type: InternetAddressType.unix).isLoopback,
          isFalse);

      // True
      expect(InternetAddress('127.0.0.1').isLoopback, isTrue);
      expect(InternetAddress('::1').isLoopback, isTrue);
    });

    test('rawAddress (IPv4)', () {
      expect(InternetAddress('10.0.0.1').rawAddress, [10, 0, 0, 1]);
    });
  });
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:multicast_dns/src/constants.dart';
import 'package:multicast_dns/src/resource_record.dart';

// Offsets into the header. See https://tools.ietf.org/html/rfc1035.
const int _kIdOffset = 0;
const int _kFlagsOffset = 2;
const int _kQdcountOffset = 4;
const int _kAncountOffset = 6;
const int _kNscountOffset = 8;
const int _kArcountOffset = 10;
const int _kHeaderSize = 12;

/// Processes a DNS query name into a list of parts.
///
/// Will attempt to append 'local' if the name is something like '_http._tcp',
/// and '._tcp.local' if name is something like '_http'.
List<String> processDnsNameParts(String name) {
  final List<String> parts = name.split('.');
  if (parts.length == 1) {
    return <String>[parts[0], '_tcp', 'local'];
  } else if (parts.length == 2 && parts[1].startsWith('_')) {
    return <String>[parts[0], parts[1], 'local'];
  }

  return parts;
}

/// Encode an mDNS query packet.
///
/// The [type] parameter must be a valid [ResourceRecordType] value. The
/// [multicast] parameter must not be null.
///
/// This is a low level API; most consumers should prefer
/// [ResourceRecordQuery.encode], which offers some convenience wrappers around
/// selecting the correct [type] and setting the [name] parameter correctly.
List<int> encodeMDnsQuery(
  String name, {
  int type = ResourceRecordType.addressIPv4,
  bool multicast = true,
}) {
  assert(ResourceRecordType.debugAssertValid(type));

  final List<String> nameParts = processDnsNameParts(name);
  final List<List<int>> rawNameParts =
      nameParts.map<List<int>>((String part) => utf8.encode(part)).toList();

  // Calculate the size of the packet.
  int size = _kHeaderSize;
  for (int i = 0; i < rawNameParts.length; i++) {
    size += 1 + rawNameParts[i].length;
  }

  size += 1; // End with empty part
  size += 4; // Trailer (QTYPE and QCLASS).
  final Uint8List data = Uint8List(size);
  final ByteData packetByteData = ByteData.view(data.buffer);
  // Query identifier - just use 0.
  packetByteData.setUint16(_kIdOffset, 0);
  // Flags - 0 for query.
  packetByteData.setUint16(_kFlagsOffset, 0);
  // Query count.
  packetByteData.setUint16(_kQdcountOffset, 1);
  // Number of answers - 0 for query.
  packetByteData.setUint16(_kAncountOffset, 0);
  // Number of name server records - 0 for query.
  packetByteData.setUint16(_kNscountOffset, 0);
  // Number of resource records - 0 for query.
  packetByteData.setUint16(_kArcountOffset, 0);
  int offset = _kHeaderSize;
  for (int i = 0; i < rawNameParts.length; i++) {
    data[offset++] = rawNameParts[i].length;
    data.setRange(offset, offset + rawNameParts[i].length, rawNameParts[i]);
    offset += rawNameParts[i].length;
  }

  data[offset] = 0; // Empty part.
  offset++;
  packetByteData.setUint16(offset, type); // QTYPE.
  offset += 2;
  packetByteData.setUint16(
      offset,
      ResourceRecordClass.internet |
          (multicast ? QuestionType.multicast : QuestionType.unicast));

  return data;
}

/// Result of reading a Fully Qualified Domain Name (FQDN).
class _FQDNReadResult {
  /// Creates a new FQDN read result.
  _FQDNReadResult(this.fqdnParts, this.bytesRead);

  /// The raw parts of the FQDN.
  final List<String> fqdnParts;

  /// The bytes consumed from the packet for this FQDN.
  final int bytesRead;

  /// Returns the Fully Qualified Domain Name.
  String get fqdn => fqdnParts.join('.');

  @override
  String toString() => fqdn;
}

/// Reads a FQDN from raw packet data.
String readFQDN(List<int> packet, [int offset = 0]) {
  final Uint8List data =
      packet is Uint8List ? packet : Uint8List.fromList(packet);
  final ByteData byteData = ByteData.view(data.buffer);

  return _readFQDN(data, byteData, offset, data.length).fqdn;
}

// Read a FQDN at the given offset. Returns a pair with the FQDN
// parts and the number of bytes consumed.
//
// If decoding fails (e.g. due to an invalid packet) `null` is returned.
_FQDNReadResult _readFQDN(
    Uint8List data, ByteData byteData, int offset, int length) {
  void checkLength(int required) {
    if (length < required) {
      throw MDnsDecodeException(required);
    }
  }

  final List<String> parts = <String>[];
  final int prevOffset = offset;
  while (true) {
    // At least one byte is required.
    checkLength(offset + 1);

    // Check for compressed.
    if (data[offset] & 0xc0 == 0xc0) {
      // At least two bytes are required for a compressed FQDN.
      checkLength(offset + 2);

      // A compressed FQDN has a new offset in the lower 14 bits.
      final _FQDNReadResult result = _readFQDN(
          data, byteData, byteData.getUint16(offset) & ~0xc000, length);
      parts.addAll(result.fqdnParts);
      offset += 2;
      break;
    } else {
      // A normal FQDN part has a length and a UTF-8 encoded name
      // part. If the length is 0 this is the end of the FQDN.
      final int partLength = data[offset];
      offset++;
      if (partLength > 0) {
        checkLength(offset + partLength);
        final Uint8List partBytes =
            Uint8List.view(data.buffer, offset, partLength);
        offset += partLength;
        // According to the RFC, this is supposed to be utf-8 encoded, but
        // we should continue decoding even if it isn't to avoid dropping the
        // rest of the data, which might still be useful.
        parts.add(utf8.decode(partBytes, allowMalformed: true));
      } else {
        break;
      }
    }
  }
  return _FQDNReadResult(parts, offset - prevOffset);
}

/// Decode an mDNS query packet.
///
/// If decoding fails (e.g. due to an invalid packet), `null` is returned.
///
/// See https://tools.ietf.org/html/rfc1035 for format.
ResourceRecordQuery? decodeMDnsQuery(List<int> packet) {
  final int length = packet.length;
  if (length < _kHeaderSize) {
    return null;
  }

  final Uint8List data =
      packet is Uint8List ? packet : Uint8List.fromList(packet);
  final ByteData packetBytes = ByteData.view(data.buffer);

  // Check whether it's a query.
  final int flags = packetBytes.getUint16(_kFlagsOffset);
  if (flags != 0) {
    return null;
  }
  final int questionCount = packetBytes.getUint16(_kQdcountOffset);
  if (questionCount == 0) {
    return null;
  }

  final _FQDNReadResult fqdn =
      _readFQDN(data, packetBytes, _kHeaderSize, data.length);

  int offset = _kHeaderSize + fqdn.bytesRead;
  final int type = packetBytes.getUint16(offset);
  offset += 2;
  final int queryType = packetBytes.getUint16(offset) & 0x8000;
  return ResourceRecordQuery(type, fqdn.fqdn, queryType);
}

/// Decode an mDNS response packet.
///
/// If decoding fails (e.g. due to an invalid packet) `null` is returned.
///
/// See https://tools.ietf.org/html/rfc1035 for the format.
List<ResourceRecord>? decodeMDnsResponse(List<int> packet) {
  final int length = packet.length;
  if (length < _kHeaderSize) {
    return null;
  }

  final Uint8List data =
      packet is Uint8List ? packet : Uint8List.fromList(packet);
  final ByteData packetBytes = ByteData.view(data.buffer);

  final int answerCount = packetBytes.getUint16(_kAncountOffset);
  final int authorityCount = packetBytes.getUint16(_kNscountOffset);
  final int additionalCount = packetBytes.getUint16(_kArcountOffset);
  final int remainingCount = answerCount + authorityCount + additionalCount;

  if (remainingCount == 0) {
    return null;
  }

  final int questionCount = packetBytes.getUint16(_kQdcountOffset);
  int offset = _kHeaderSize;

  void checkLength(int required) {
    if (length < required) {
      throw MDnsDecodeException(required);
    }
  }

  ResourceRecord? readResourceRecord() {
    // First read the FQDN.
    final _FQDNReadResult result = _readFQDN(data, packetBytes, offset, length);
    final String fqdn = result.fqdn;
    offset += result.bytesRead;
    checkLength(offset + 2);
    final int type = packetBytes.getUint16(offset);
    offset += 2;
    // The first bit of the rrclass field is set to indicate that the answer is
    // unique and the querier should flush the cached answer for this name
    // (RFC 6762, Sec. 10.2). We ignore it for now since we don't cache answers.
    checkLength(offset + 2);
    final int resourceRecordClass = packetBytes.getUint16(offset) & 0x7fff;

    if (resourceRecordClass != ResourceRecordClass.internet) {
      // We do not support other classes.
      return null;
    }

    offset += 2;
    checkLength(offset + 4);
    final int ttl = packetBytes.getInt32(offset);
    offset += 4;

    checkLength(offset + 2);
    final int readDataLength = packetBytes.getUint16(offset);
    offset += 2;
    final int validUntil = DateTime.now().millisecondsSinceEpoch + ttl * 1000;
    switch (type) {
      case ResourceRecordType.addressIPv4:
        checkLength(offset + readDataLength);
        final StringBuffer addr = StringBuffer();
        final int stop = offset + readDataLength;
        addr.write(packetBytes.getUint8(offset));
        offset++;
        for (; offset < stop; offset++) {
          addr.write('.');
          addr.write(packetBytes.getUint8(offset));
        }
        return IPAddressResourceRecord(fqdn, validUntil,
            address: InternetAddress(addr.toString()));
      case ResourceRecordType.addressIPv6:
        checkLength(offset + readDataLength);
        final StringBuffer addr = StringBuffer();
        final int stop = offset + readDataLength;
        addr.write(packetBytes.getUint16(offset).toRadixString(16));
        offset += 2;
        for (; offset < stop; offset += 2) {
          addr.write(':');
          addr.write(packetBytes.getUint16(offset).toRadixString(16));
        }
        return IPAddressResourceRecord(
          fqdn,
          validUntil,
          address: InternetAddress(addr.toString()),
        );
      case ResourceRecordType.service:
        checkLength(offset + 2);
        final int priority = packetBytes.getUint16(offset);
        offset += 2;
        checkLength(offset + 2);
        final int weight = packetBytes.getUint16(offset);
        offset += 2;
        checkLength(offset + 2);
        final int port = packetBytes.getUint16(offset);
        offset += 2;
        final _FQDNReadResult result =
            _readFQDN(data, packetBytes, offset, length);
        offset += result.bytesRead;
        return SrvResourceRecord(
          fqdn,
          validUntil,
          target: result.fqdn,
          port: port,
          priority: priority,
          weight: weight,
        );
      case ResourceRecordType.serverPointer:
        checkLength(offset + readDataLength);
        final _FQDNReadResult result =
            _readFQDN(data, packetBytes, offset, length);
        offset += readDataLength;
        return PtrResourceRecord(
          fqdn,
          validUntil,
          domainName: result.fqdn,
        );
      case ResourceRecordType.text:
        checkLength(offset + readDataLength);
        // The first byte of the buffer is the length of the first string of
        // the TXT record. Further length-prefixed strings may follow. We
        // concatenate them with newlines.
        final StringBuffer strings = StringBuffer();
        int index = 0;
        while (index < readDataLength) {
          final int txtLength = data[offset + index];
          index++;
          if (txtLength == 0) {
            continue;
          }
          final String text = utf8.decode(
            Uint8List.view(data.buffer, offset + index, txtLength),
            allowMalformed: true,
          );
          strings.writeln(text);
          index += txtLength;
        }
        offset += readDataLength;
        return TxtResourceRecord(fqdn, validUntil, text: strings.toString());
      default:
        checkLength(offset + readDataLength);
        offset += readDataLength;
        return null;
    }
  }

  // This list can't be fixed length right now because we might get
  // resource record types we don't support, and consumers expect this list
  // to not have null entries.
  final List<ResourceRecord> result = <ResourceRecord>[];

  try {
    for (int i = 0; i < questionCount; i++) {
      final _FQDNReadResult result =
          _readFQDN(data, packetBytes, offset, length);
      offset += result.bytesRead;
      checkLength(offset + 4);
      offset += 4;
    }
    for (int i = 0; i < remainingCount; i++) {
      final ResourceRecord? record = readResourceRecord();
      if (record != null) {
        result.add(record);
      }
    }
  } on MDnsDecodeException {
    // If decoding fails return null.
    return null;
  }
  return result;
}

/// This exception is thrown by the decoder when the packet is invalid.
class MDnsDecodeException implements Exception {
  /// Creates a new MDnsDecodeException, indicating an error in decoding at the
  /// specified [offset].
  ///
  /// The [offset] parameter should not be null.
  const MDnsDecodeException(this.offset);

  /// The offset in the packet at which the exception occurred.
  final int offset;

  @override
  String toString() => 'Decoding error at $offset';
}

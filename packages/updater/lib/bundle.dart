// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const String kBundleMagic = '#!mojo ';

Future<List<int>> _readBytesWithLength(RandomAccessFile file) async {
  ByteData buffer = new ByteData(4);
  await file.readInto(buffer.buffer.asUint8List());
  int length = buffer.getUint32(0, Endianness.LITTLE_ENDIAN);
  return await file.read(length);
}

const int kMaxLineLen = 10*1024;
const int kNewline = 0x0A;
Future<String> _readLine(RandomAccessFile file) async {
  String line = '';
  while (line.length < kMaxLineLen) {
    int byte = await file.readByte();
    if (byte == -1 || byte == kNewline)
      break;
    line += new String.fromCharCode(byte);
  }
  return line;
}

// Represents a parsed .flx Bundle. Contains information from the bundle's
// header, as well as an open File handle positioned where the zip content
// begins.
// The bundle format is:
// #!mojo <any string>\n
// <32-bit length><signature of the manifest data>
// <32-bit length><manifest data>
// <zip content>
//
// The manifest is a JSON string containing the following keys:
// (optional) name: the name of the package.
// version: the package version.
// update-url: the base URL to download a new manifest and bundle.
// key: a BASE-64 encoded DER-encoded ASN.1 representation of the Q point of the
//   ECDSA public key that was used to sign this manifest.
// content-hash: an integer SHA-256 hash value of the <zip content>.
class Bundle {
  Bundle(this.path);

  final String path;
  List<int> signatureBytes;
  List<int> manifestBytes;
  Map<String, dynamic> manifest;
  RandomAccessFile content;

  Future<bool> _readHeader() async {
    content = await new File(path).open();
    String magic = await _readLine(content);
    if (!magic.startsWith(kBundleMagic))
      return false;
    signatureBytes = await _readBytesWithLength(content);
    manifestBytes = await _readBytesWithLength(content);
    String manifestString = UTF8.decode(manifestBytes);
    manifest = JSON.decode(manifestString);
    return true;
  }

  static Future<Bundle> readHeader(String path) async {
    Bundle bundle = new Bundle(path);
    if (!await bundle._readHeader())
      return null;
    return bundle;
  }
}

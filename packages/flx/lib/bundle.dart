// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bignum/bignum.dart';

import 'signing.dart';

// Magic string we put at the top of all bundle files.
const String kBundleMagic = '#!mojo mojo:flutter\n';

// Prefix of the above, used when reading bundle files. This allows us to be
// more flexbile about what we accept.
const String kBundleMagicPrefix = '#!mojo ';

typedef Stream<List<int>> StreamOpener();

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

// Writes a 32-bit length followed by the content of [bytes].
void _writeBytesWithLengthSync(RandomAccessFile outputFile, List<int> bytes) {
  if (bytes == null)
    bytes = new Uint8List(0);
  assert(bytes.length < 0xffffffff);
  ByteData length = new ByteData(4)..setUint32(0, bytes.length, Endianness.LITTLE_ENDIAN);
  outputFile.writeFromSync(length.buffer.asUint8List());
  outputFile.writeFromSync(bytes);
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
  Bundle._fromFile(this.path);
  Bundle.fromContent({
    this.path,
    this.manifest,
    contentBytes,
    AsymmetricKeyPair keyPair: null
  }) : _contentBytes = contentBytes {
    assert(path != null);
    assert(manifest != null);
    assert(_contentBytes != null);
    manifestBytes = serializeManifest(manifest, keyPair?.publicKey, _contentBytes);
    signatureBytes = signManifest(manifestBytes, keyPair?.privateKey);
    _openContentStream = () => new Stream.fromIterable(<List<int>>[_contentBytes]);
  }

  final String path;
  List<int> signatureBytes;
  List<int> manifestBytes;
  Map<String, dynamic> manifest;

  // Callback to open a Stream containing the bundle content data.
  StreamOpener _openContentStream;

  // Zip content bytes. Only valid when created in memory.
  List<int> _contentBytes;

  Future<bool> _readHeader() async {
    RandomAccessFile file = await new File(path).open();
    String magic = await _readLine(file);
    if (!magic.startsWith(kBundleMagicPrefix)) {
      file.close();
      return false;
    }
    signatureBytes = await _readBytesWithLength(file);
    manifestBytes = await _readBytesWithLength(file);
    int contentOffset = await file.position();
    _openContentStream = () => new File(path).openRead(contentOffset);
    file.close();

    String manifestString = UTF8.decode(manifestBytes);
    manifest = JSON.decode(manifestString);
    return true;
  }

  static Future<Bundle> readHeader(String path) async {
    Bundle bundle = new Bundle._fromFile(path);
    if (!await bundle._readHeader())
      return null;
    return bundle;
  }

  // Verifies that the package has a valid signature and content.
  Future<bool> verifyContent() async {
    if (!verifyManifestSignature(manifest, manifestBytes, signatureBytes))
      return false;

    Stream<List<int>> content = _openContentStream();
    BigInteger expectedHash = new BigInteger(manifest['content-hash'], 10);
    if (!await verifyContentHash(expectedHash, content))
      return false;

    return true;
  }

  // Writes the in-memory representation to disk.
  void writeSync() {
    assert(_contentBytes != null);
    RandomAccessFile outputFile = new File(path).openSync(mode: FileMode.WRITE);
    outputFile.writeStringSync(kBundleMagic);
    _writeBytesWithLengthSync(outputFile, signatureBytes);
    _writeBytesWithLengthSync(outputFile, manifestBytes);
    outputFile.writeFromSync(_contentBytes);
    outputFile.close();
  }
}

// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';

import 'package:mojo/core.dart';
// TODO(mpcomplete): Remove this 'hide' when we remove the conflicting
// UpdateService from activity.mojom.
import 'package:flutter/services.dart' hide UpdateServiceProxy;
import 'package:sky_services/updater/update_service.mojom.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;
import 'package:asn1lib/asn1lib.dart';
import 'package:bignum/bignum.dart';
import 'package:cipher/cipher.dart';
import 'package:cipher/impl/client.dart';

import 'bundle.dart';
import 'pipe_to_file.dart';
import 'version.dart';

const String kManifestFile = 'sky.yaml';
const String kBundleFile = 'app.flx';

// Number of bytes to read at a time from a file.
const int kReadBlockSize = 32*1024;

// The ECDSA algorithm parameters we're using. These match the parameters used
// by the signing tool in flutter_tools.
final ECDomainParameters _ecDomain = new ECDomainParameters('prime256v1');
final String kSignerAlgorithm = 'SHA-256/ECDSA';
final String kHashAlgorithm = 'SHA-256';

UpdateServiceProxy _initUpdateService() {
  UpdateServiceProxy updateService = new UpdateServiceProxy.unbound();
  shell.requestService(null, updateService);
  return updateService;
}

final UpdateServiceProxy _updateService = _initUpdateService();

String cachedDataDir = null;
Future<String> getDataDir() async {
  if (cachedDataDir == null)
    cachedDataDir = await getAppDataDir();
  return cachedDataDir;
}

// Parses a DER-encoded ASN.1 ECDSA signature block.
ECSignature _asn1ParseSignature(Uint8List signature) {
  ASN1Parser parser = new ASN1Parser(signature);
  ASN1Object object = parser.nextObject();
  if (object is! ASN1Sequence)
    return null;
  ASN1Sequence sequence = object;
  if (!(sequence.elements.length == 2 &&
        sequence.elements[0] is ASN1Integer &&
        sequence.elements[1] is ASN1Integer))
    return null;
  ASN1Integer r = sequence.elements[0];
  ASN1Integer s = sequence.elements[1];
  return new ECSignature(r.valueAsPositiveBigInteger, s.valueAsPositiveBigInteger);
}

class UpdateFailure extends Error {
  UpdateFailure(this._message);
  String _message;
  String toString() => _message;
}

class UpdateTask {
  UpdateTask();

  Future run() async {
    try {
      await _runImpl();
    } on UpdateFailure catch (e) {
      print('Update failed: $e');
    } catch (e, stackTrace) {
      print('Update failed: $e');
      print('Stack: $stackTrace');
    } finally {
      _updateService.ptr.notifyUpdateCheckComplete();
    }
  }

  Future _runImpl() async {
    _dataDir = await getDataDir();

    await _readLocalManifest();
    yaml.YamlMap remoteManifest = await _fetchManifest();
    if (!_shouldUpdate(remoteManifest)) {
      print('Update skipped. No new version.');
      return;
    }
    await _fetchBundle();
    await _validateBundle();
    await _replaceBundle();
    print('Update success.');
  }

  Map _currentManifest;
  String _dataDir;
  String _tempPath;

  Future _readLocalManifest() async {
    String bundlePath = path.join(_dataDir, kBundleFile);
    Bundle bundle = await Bundle.readHeader(bundlePath);
    _currentManifest = bundle.manifest;
    bundle.content.close();
  }

  Future<yaml.YamlMap> _fetchManifest() async {
    String manifestUrl = _currentManifest['update-url'] + '/' + kManifestFile;
    String manifestData = await fetchString(manifestUrl);
    return yaml.loadYaml(manifestData, sourceUrl: manifestUrl);
  }

  bool _shouldUpdate(yaml.YamlMap remoteManifest) {
    Version currentVersion = new Version(_currentManifest['version']);
    Version remoteVersion = new Version(remoteManifest['version']);
    return (currentVersion < remoteVersion);
  }

  Future _fetchBundle() async {
    // TODO(mpcomplete): Use the cache dir. We need an equivalent of mkstemp().
    _tempPath = path.join(_dataDir, 'tmp.skyx');
    String bundleUrl = _currentManifest['update-url'] + '/' + kBundleFile;
    UrlResponse response = await fetchUrl(bundleUrl);
    MojoResult result = await PipeToFile.copyToFile(response.body, _tempPath);
    if (!result.isOk)
      throw new UpdateFailure('Failure fetching new package: ${response.statusLine}');
  }

  Future _validateBundle() async {
    Bundle bundle = await Bundle.readHeader(_tempPath);

    if (bundle == null)
      throw new UpdateFailure('Remote package not a valid FLX file.');
    if (bundle.manifest['key'] != _currentManifest['key'])
      throw new UpdateFailure('Remote package key does not match.');

    await _verifyManifestSignature(bundle);
    await _verifyContentHash(bundle);

    bundle.content.close();
  }

  Future _verifyManifestSignature(Bundle bundle) async {
    ECSignature ecSignature = _asn1ParseSignature(bundle.signatureBytes);
    if (ecSignature == null)
      throw new UpdateFailure('Corrupt package signature.');

    List keyBytes = BASE64.decode(_currentManifest['key']);
    ECPoint q = _ecDomain.curve.decodePoint(keyBytes);
    ECPublicKey ecPublicKey = new ECPublicKey(q, _ecDomain);

    Signer signer = new Signer(kSignerAlgorithm);
    signer.init(false, new PublicKeyParameter(ecPublicKey));
    if (!signer.verifySignature(bundle.manifestBytes, ecSignature))
      throw new UpdateFailure('Invalid package signature. This package has been tampered with.');
  }

  Future _verifyContentHash(Bundle bundle) async {
    // Hash the bundle contents.
    Digest hasher = new Digest(kHashAlgorithm);
    RandomAccessFile content = bundle.content;
    int remainingLen = await content.length() - await content.position();
    while (remainingLen > 0) {
      List<int> chunk = await content.read(min(remainingLen, kReadBlockSize));
      hasher.update(chunk, 0, chunk.length);
      remainingLen -= chunk.length;
    }
    Uint8List hashBytes = new Uint8List(hasher.digestSize);
    int len = hasher.doFinal(hashBytes, 0);
    hashBytes = hashBytes.sublist(0, len);
    BigInteger actualHash = new BigInteger.fromBytes(1, hashBytes);

    // Compare to our expected hash from the manifest.
    BigInteger expectedHash = new BigInteger(bundle.manifest['content-hash'], 10);
    if (expectedHash != actualHash)
      throw new UpdateFailure('Invalid package content hash. This package has been tampered with.');
  }

  Future _replaceBundle() async {
    String bundlePath = path.join(_dataDir, kBundleFile);
    await new File(_tempPath).rename(bundlePath);
  }
}

void main() {
  initCipher();
  UpdateTask task = new UpdateTask();
  task.run();
}

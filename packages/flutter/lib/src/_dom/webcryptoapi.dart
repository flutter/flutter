// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'webidl.dart';

typedef AlgorithmIdentifier = JSAny;
typedef HashAlgorithmIdentifier = AlgorithmIdentifier;
typedef BigInteger = JSUint8Array;
typedef NamedCurve = String;
typedef KeyType = String;
typedef KeyUsage = String;
typedef KeyFormat = String;

@JS('Crypto')
@staticInterop
class Crypto {}

extension CryptoExtension on Crypto {
  external ArrayBufferView getRandomValues(ArrayBufferView array);
  external String randomUUID();
  external SubtleCrypto get subtle;
}

@JS()
@staticInterop
@anonymous
class Algorithm {
  external factory Algorithm({required String name});
}

extension AlgorithmExtension on Algorithm {
  external set name(String value);
  external String get name;
}

@JS()
@staticInterop
@anonymous
class KeyAlgorithm {
  external factory KeyAlgorithm({required String name});
}

extension KeyAlgorithmExtension on KeyAlgorithm {
  external set name(String value);
  external String get name;
}

@JS('CryptoKey')
@staticInterop
class CryptoKey {}

extension CryptoKeyExtension on CryptoKey {
  external KeyType get type;
  external bool get extractable;
  external JSObject get algorithm;
  external JSObject get usages;
}

@JS('SubtleCrypto')
@staticInterop
class SubtleCrypto {}

extension SubtleCryptoExtension on SubtleCrypto {
  external JSPromise encrypt(
    AlgorithmIdentifier algorithm,
    CryptoKey key,
    BufferSource data,
  );
  external JSPromise decrypt(
    AlgorithmIdentifier algorithm,
    CryptoKey key,
    BufferSource data,
  );
  external JSPromise sign(
    AlgorithmIdentifier algorithm,
    CryptoKey key,
    BufferSource data,
  );
  external JSPromise verify(
    AlgorithmIdentifier algorithm,
    CryptoKey key,
    BufferSource signature,
    BufferSource data,
  );
  external JSPromise digest(
    AlgorithmIdentifier algorithm,
    BufferSource data,
  );
  external JSPromise generateKey(
    AlgorithmIdentifier algorithm,
    bool extractable,
    JSArray keyUsages,
  );
  external JSPromise deriveKey(
    AlgorithmIdentifier algorithm,
    CryptoKey baseKey,
    AlgorithmIdentifier derivedKeyType,
    bool extractable,
    JSArray keyUsages,
  );
  external JSPromise deriveBits(
    AlgorithmIdentifier algorithm,
    CryptoKey baseKey,
    int length,
  );
  external JSPromise importKey(
    KeyFormat format,
    JSObject keyData,
    AlgorithmIdentifier algorithm,
    bool extractable,
    JSArray keyUsages,
  );
  external JSPromise exportKey(
    KeyFormat format,
    CryptoKey key,
  );
  external JSPromise wrapKey(
    KeyFormat format,
    CryptoKey key,
    CryptoKey wrappingKey,
    AlgorithmIdentifier wrapAlgorithm,
  );
  external JSPromise unwrapKey(
    KeyFormat format,
    BufferSource wrappedKey,
    CryptoKey unwrappingKey,
    AlgorithmIdentifier unwrapAlgorithm,
    AlgorithmIdentifier unwrappedKeyAlgorithm,
    bool extractable,
    JSArray keyUsages,
  );
}

@JS()
@staticInterop
@anonymous
class RsaOtherPrimesInfo {
  external factory RsaOtherPrimesInfo({
    String r,
    String d,
    String t,
  });
}

extension RsaOtherPrimesInfoExtension on RsaOtherPrimesInfo {
  external set r(String value);
  external String get r;
  external set d(String value);
  external String get d;
  external set t(String value);
  external String get t;
}

@JS()
@staticInterop
@anonymous
class JsonWebKey {
  external factory JsonWebKey({
    String kty,
    String use,
    JSArray key_ops,
    String alg,
    bool ext,
    String crv,
    String x,
    String y,
    String d,
    String n,
    String e,
    String p,
    String q,
    String dp,
    String dq,
    String qi,
    JSArray oth,
    String k,
  });
}

extension JsonWebKeyExtension on JsonWebKey {
  external set kty(String value);
  external String get kty;
  external set use(String value);
  external String get use;
  external set key_ops(JSArray value);
  external JSArray get key_ops;
  external set alg(String value);
  external String get alg;
  external set ext(bool value);
  external bool get ext;
  external set crv(String value);
  external String get crv;
  external set x(String value);
  external String get x;
  external set y(String value);
  external String get y;
  external set d(String value);
  external String get d;
  external set n(String value);
  external String get n;
  external set e(String value);
  external String get e;
  external set p(String value);
  external String get p;
  external set q(String value);
  external String get q;
  external set dp(String value);
  external String get dp;
  external set dq(String value);
  external String get dq;
  external set qi(String value);
  external String get qi;
  external set oth(JSArray value);
  external JSArray get oth;
  external set k(String value);
  external String get k;
}

@JS()
@staticInterop
@anonymous
class CryptoKeyPair {
  external factory CryptoKeyPair({
    CryptoKey publicKey,
    CryptoKey privateKey,
  });
}

extension CryptoKeyPairExtension on CryptoKeyPair {
  external set publicKey(CryptoKey value);
  external CryptoKey get publicKey;
  external set privateKey(CryptoKey value);
  external CryptoKey get privateKey;
}

@JS()
@staticInterop
@anonymous
class RsaKeyGenParams implements Algorithm {
  external factory RsaKeyGenParams({
    required int modulusLength,
    required BigInteger publicExponent,
  });
}

extension RsaKeyGenParamsExtension on RsaKeyGenParams {
  external set modulusLength(int value);
  external int get modulusLength;
  external set publicExponent(BigInteger value);
  external BigInteger get publicExponent;
}

@JS()
@staticInterop
@anonymous
class RsaHashedKeyGenParams implements RsaKeyGenParams {
  external factory RsaHashedKeyGenParams(
      {required HashAlgorithmIdentifier hash});
}

extension RsaHashedKeyGenParamsExtension on RsaHashedKeyGenParams {
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
}

@JS()
@staticInterop
@anonymous
class RsaKeyAlgorithm implements KeyAlgorithm {
  external factory RsaKeyAlgorithm({
    required int modulusLength,
    required BigInteger publicExponent,
  });
}

extension RsaKeyAlgorithmExtension on RsaKeyAlgorithm {
  external set modulusLength(int value);
  external int get modulusLength;
  external set publicExponent(BigInteger value);
  external BigInteger get publicExponent;
}

@JS()
@staticInterop
@anonymous
class RsaHashedKeyAlgorithm implements RsaKeyAlgorithm {
  external factory RsaHashedKeyAlgorithm({required KeyAlgorithm hash});
}

extension RsaHashedKeyAlgorithmExtension on RsaHashedKeyAlgorithm {
  external set hash(KeyAlgorithm value);
  external KeyAlgorithm get hash;
}

@JS()
@staticInterop
@anonymous
class RsaHashedImportParams implements Algorithm {
  external factory RsaHashedImportParams(
      {required HashAlgorithmIdentifier hash});
}

extension RsaHashedImportParamsExtension on RsaHashedImportParams {
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
}

@JS()
@staticInterop
@anonymous
class RsaPssParams implements Algorithm {
  external factory RsaPssParams({required int saltLength});
}

extension RsaPssParamsExtension on RsaPssParams {
  external set saltLength(int value);
  external int get saltLength;
}

@JS()
@staticInterop
@anonymous
class RsaOaepParams implements Algorithm {
  external factory RsaOaepParams({BufferSource label});
}

extension RsaOaepParamsExtension on RsaOaepParams {
  external set label(BufferSource value);
  external BufferSource get label;
}

@JS()
@staticInterop
@anonymous
class EcdsaParams implements Algorithm {
  external factory EcdsaParams({required HashAlgorithmIdentifier hash});
}

extension EcdsaParamsExtension on EcdsaParams {
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
}

@JS()
@staticInterop
@anonymous
class EcKeyGenParams implements Algorithm {
  external factory EcKeyGenParams({required NamedCurve namedCurve});
}

extension EcKeyGenParamsExtension on EcKeyGenParams {
  external set namedCurve(NamedCurve value);
  external NamedCurve get namedCurve;
}

@JS()
@staticInterop
@anonymous
class EcKeyAlgorithm implements KeyAlgorithm {
  external factory EcKeyAlgorithm({required NamedCurve namedCurve});
}

extension EcKeyAlgorithmExtension on EcKeyAlgorithm {
  external set namedCurve(NamedCurve value);
  external NamedCurve get namedCurve;
}

@JS()
@staticInterop
@anonymous
class EcKeyImportParams implements Algorithm {
  external factory EcKeyImportParams({required NamedCurve namedCurve});
}

extension EcKeyImportParamsExtension on EcKeyImportParams {
  external set namedCurve(NamedCurve value);
  external NamedCurve get namedCurve;
}

@JS()
@staticInterop
@anonymous
class EcdhKeyDeriveParams implements Algorithm {
  external factory EcdhKeyDeriveParams({required CryptoKey public});
}

extension EcdhKeyDeriveParamsExtension on EcdhKeyDeriveParams {
  external set public(CryptoKey value);
  external CryptoKey get public;
}

@JS()
@staticInterop
@anonymous
class AesCtrParams implements Algorithm {
  external factory AesCtrParams({
    required BufferSource counter,
    required int length,
  });
}

extension AesCtrParamsExtension on AesCtrParams {
  external set counter(BufferSource value);
  external BufferSource get counter;
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class AesKeyAlgorithm implements KeyAlgorithm {
  external factory AesKeyAlgorithm({required int length});
}

extension AesKeyAlgorithmExtension on AesKeyAlgorithm {
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class AesKeyGenParams implements Algorithm {
  external factory AesKeyGenParams({required int length});
}

extension AesKeyGenParamsExtension on AesKeyGenParams {
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class AesDerivedKeyParams implements Algorithm {
  external factory AesDerivedKeyParams({required int length});
}

extension AesDerivedKeyParamsExtension on AesDerivedKeyParams {
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class AesCbcParams implements Algorithm {
  external factory AesCbcParams({required BufferSource iv});
}

extension AesCbcParamsExtension on AesCbcParams {
  external set iv(BufferSource value);
  external BufferSource get iv;
}

@JS()
@staticInterop
@anonymous
class AesGcmParams implements Algorithm {
  external factory AesGcmParams({
    required BufferSource iv,
    BufferSource additionalData,
    int tagLength,
  });
}

extension AesGcmParamsExtension on AesGcmParams {
  external set iv(BufferSource value);
  external BufferSource get iv;
  external set additionalData(BufferSource value);
  external BufferSource get additionalData;
  external set tagLength(int value);
  external int get tagLength;
}

@JS()
@staticInterop
@anonymous
class HmacImportParams implements Algorithm {
  external factory HmacImportParams({
    required HashAlgorithmIdentifier hash,
    int length,
  });
}

extension HmacImportParamsExtension on HmacImportParams {
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class HmacKeyAlgorithm implements KeyAlgorithm {
  external factory HmacKeyAlgorithm({
    required KeyAlgorithm hash,
    required int length,
  });
}

extension HmacKeyAlgorithmExtension on HmacKeyAlgorithm {
  external set hash(KeyAlgorithm value);
  external KeyAlgorithm get hash;
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class HmacKeyGenParams implements Algorithm {
  external factory HmacKeyGenParams({
    required HashAlgorithmIdentifier hash,
    int length,
  });
}

extension HmacKeyGenParamsExtension on HmacKeyGenParams {
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
  external set length(int value);
  external int get length;
}

@JS()
@staticInterop
@anonymous
class HkdfParams implements Algorithm {
  external factory HkdfParams({
    required HashAlgorithmIdentifier hash,
    required BufferSource salt,
    required BufferSource info,
  });
}

extension HkdfParamsExtension on HkdfParams {
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
  external set salt(BufferSource value);
  external BufferSource get salt;
  external set info(BufferSource value);
  external BufferSource get info;
}

@JS()
@staticInterop
@anonymous
class Pbkdf2Params implements Algorithm {
  external factory Pbkdf2Params({
    required BufferSource salt,
    required int iterations,
    required HashAlgorithmIdentifier hash,
  });
}

extension Pbkdf2ParamsExtension on Pbkdf2Params {
  external set salt(BufferSource value);
  external BufferSource get salt;
  external set iterations(int value);
  external int get iterations;
  external set hash(HashAlgorithmIdentifier value);
  external HashAlgorithmIdentifier get hash;
}

// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_identity_services_web/id.dart';

import 'jsify_as.dart';

/// A CredentialResponse with null `credential`.
final CredentialResponse nullCredential =
    jsifyAs<CredentialResponse>(<String, Object?>{
  'credential': null,
});

/// A CredentialResponse wrapping a known good JWT Token as its `credential`.
final CredentialResponse goodCredential =
    jsifyAs<CredentialResponse>(<String, Object?>{
  'credential': goodJwtToken,
});

/// A JWT token with predefined values.
///
/// 'email': 'adultman@example.com',
/// 'sub': '123456',
/// 'name': 'Vincent Adultman',
/// 'picture': 'https://thispersondoesnotexist.com/image?x=.jpg',
///
/// Signed with HS256 and the private key: 'symmetric-encryption-is-weak'
const String goodJwtToken =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.$goodPayload.lqzULA_U3YzEl_-fL7YLU-kFXmdD2ttJLTv-UslaNQ4';

/// The payload of a JWT token that contains predefined values.
///
/// 'email': 'adultman@example.com',
/// 'sub': '123456',
/// 'name': 'Vincent Adultman',
/// 'picture': 'https://thispersondoesnotexist.com/image?x=.jpg',
const String goodPayload =
    'eyJlbWFpbCI6ImFkdWx0bWFuQGV4YW1wbGUuY29tIiwic3ViIjoiMTIzNDU2IiwibmFtZSI6IlZpbmNlbnQgQWR1bHRtYW4iLCJwaWN0dXJlIjoiaHR0cHM6Ly90aGlzcGVyc29uZG9lc25vdGV4aXN0LmNvbS9pbWFnZT94PS5qcGcifQ';

// More encrypted JWT Tokens may be created on https://jwt.io.
//
// First, decode the `goodJwtToken` above, modify to your heart's
// content, and add a new credential here.
//
// (New tokens can also be created with `package:jose` and `dart:convert`.)

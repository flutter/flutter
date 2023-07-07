// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Reads and writes credentials

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void write(
    {required String credentialName,
    required String userName,
    required String password}) {
  print('Writing $credentialName ...');
  final examplePassword = utf8.encode(password) as Uint8List;
  final blob = examplePassword.allocatePointer();

  final credential = calloc<CREDENTIAL>()
    ..ref.Type = CRED_TYPE_GENERIC
    ..ref.TargetName = credentialName.toNativeUtf16()
    ..ref.Persist = CRED_PERSIST_LOCAL_MACHINE
    ..ref.UserName = userName.toNativeUtf16()
    ..ref.CredentialBlob = blob
    ..ref.CredentialBlobSize = examplePassword.length;

  final result = CredWrite(credential, 0);

  if (result != TRUE) {
    final errorCode = GetLastError();
    print('Error ($result): $errorCode');
    return;
  }
  print('Success (blob size: ${credential.ref.CredentialBlobSize})');

  free(blob);
  free(credential);
}

void read(String credentialName) {
  print('Reading $credentialName ...');
  final credPointer = calloc<Pointer<CREDENTIAL>>();
  final result = CredRead(
      credentialName.toNativeUtf16(), CRED_TYPE_GENERIC, 0, credPointer);
  if (result != TRUE) {
    final errorCode = GetLastError();
    var errorText = '$errorCode';
    if (errorCode == ERROR_NOT_FOUND) {
      errorText += ' Not found.';
    }
    print('Error ($result): $errorText');
    return;
  }
  final cred = credPointer.value.ref;
  print('Success. Read username ${cred.UserName.toDartString()} '
      'password size: ${cred.CredentialBlobSize}');
  final blob = cred.CredentialBlob.asTypedList(cred.CredentialBlobSize);
  final password = utf8.decode(blob);
  print('read password: $password');
  CredFree(credPointer.value);
  free(credPointer);
}

void delete(String credentialName) {
  print('Deleting $credentialName');
  final result =
      CredDelete(credentialName.toNativeUtf16(), CRED_TYPE_GENERIC, 0);
  if (result != TRUE) {
    final errorCode = GetLastError();
    print('Error ($result): $errorCode');
    return;
  }
  print('Successfully deleted credential.');
}

void main() {
  print('Accessing Credentials.');
  const credentialName = 'exampleCredential';
  write(
    credentialName: credentialName,
    userName: 'MyUserName',
    password: 'MyPassword',
  );
  read(credentialName);
  delete(credentialName);
  print('Reading deleted credential should fail:');
  read(credentialName);
}

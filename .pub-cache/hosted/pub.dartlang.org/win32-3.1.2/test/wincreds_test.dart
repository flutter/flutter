@TestOn('windows')

import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:win32/win32.dart';

void writeCredential(
    {required String credentialName,
    required String userName,
    required String password}) {
  final userNamePtr = TEXT(userName);
  final credNamePtr = TEXT(credentialName);
  final examplePassword = utf8.encode(password) as Uint8List;
  final blob = examplePassword.allocatePointer();

  final credential = calloc<CREDENTIAL>()
    ..ref.Type = CRED_TYPE_GENERIC
    ..ref.TargetName = credNamePtr
    ..ref.Persist = CRED_PERSIST_LOCAL_MACHINE
    ..ref.UserName = userNamePtr
    ..ref.CredentialBlob = blob
    ..ref.CredentialBlobSize = examplePassword.length;

  try {
    if (CredWrite(credential, 0) != TRUE) {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(blob);
    free(credential);
    free(userNamePtr);
    free(credNamePtr);
  }
}

String readCredential(String credentialName) {
  final credPointer = calloc<Pointer<CREDENTIAL>>();
  final credNamePtr = TEXT(credentialName);

  try {
    if (CredRead(credNamePtr, CRED_TYPE_GENERIC, 0, credPointer) != TRUE) {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }

    final cred = credPointer.value.ref;
    final blob = cred.CredentialBlob.asTypedList(cred.CredentialBlobSize);
    final password = utf8.decode(blob);

    return password;
  } finally {
    if (credPointer.value.address != 0) CredFree(credPointer.value);
    free(credPointer);
    free(credNamePtr);
  }
}

void deleteCredential(String credentialName) {
  final credNamePtr = TEXT(credentialName);

  try {
    if (CredDelete(credNamePtr, CRED_TYPE_GENERIC, 0) != TRUE) {
      throw WindowsException(HRESULT_FROM_WIN32(GetLastError()));
    }
  } finally {
    free(credNamePtr);
  }
}

void main() {
  test('Credential write / read succeeds', () {
    const credentialName = 'dart.win32.test.credential';
    const credentialValue = 'secretValue';

    // create credential
    writeCredential(
        credentialName: credentialName,
        userName: 'userName',
        password: credentialValue);

    // read
    expect(readCredential(credentialName), equals(credentialValue));

    // delete
    deleteCredential(credentialName);
  });

  test('Credential can be updated', () {
    const credentialName = 'dart.win32.test.credential';
    const credentialValue = 'secretValue';
    const credentialValue2 = 'anotherSecret';

    // create credential
    writeCredential(
        credentialName: credentialName,
        userName: 'userName',
        password: credentialValue);

    // update credential with a new value
    writeCredential(
        credentialName: credentialName,
        userName: 'userName',
        password: credentialValue2);

    expect(readCredential(credentialName), equals(credentialValue2));

    // delete
    deleteCredential(credentialName);
  });
}

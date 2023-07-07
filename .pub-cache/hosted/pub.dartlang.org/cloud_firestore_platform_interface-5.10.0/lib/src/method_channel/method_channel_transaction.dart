// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_firestore.dart';

/// An implementation of [TransactionPlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
class MethodChannelTransaction extends TransactionPlatform {
  /// [FirebaseApp] name used for this [MethodChannelTransaction]
  final String appName;
  late String _transactionId;
  late FirebaseFirestorePlatform _firestore;

  /// Constructor.
  MethodChannelTransaction(String transactionId, this.appName)
      : _transactionId = transactionId,
        super() {
    _firestore =
        FirebaseFirestorePlatform.instanceFor(app: Firebase.app(appName));
  }

  List<Map<String, dynamic>> _commands = [];

  /// Returns all transaction commands for the current instance.
  @override
  List<Map<String, dynamic>> get commands {
    return _commands;
  }

  /// Reads the document referenced by the provided [documentPath].
  ///
  /// Requires all reads to be executed before all writes, otherwise an [AssertionError] will be thrown
  @override
  Future<DocumentSnapshotPlatform> get(String documentPath) async {
    assert(_commands.isEmpty,
        'Transactions require all reads to be executed before all writes.');

    final Map<String, dynamic>? result = await MethodChannelFirebaseFirestore
        .channel
        .invokeMapMethod<String, dynamic>('Transaction#get', <String, dynamic>{
      'firestore': _firestore,
      'transactionId': _transactionId,
      'reference': _firestore.doc(documentPath),
    });

    return DocumentSnapshotPlatform(
      _firestore,
      documentPath,
      Map<String, dynamic>.from(result!),
    );
  }

  @override
  MethodChannelTransaction delete(String documentPath) {
    _commands.add(<String, String>{
      'type': 'DELETE',
      'path': documentPath,
    });

    return this;
  }

  @override
  MethodChannelTransaction update(
    String documentPath,
    Map<String, dynamic> data,
  ) {
    _commands.add(<String, dynamic>{
      'type': 'UPDATE',
      'path': documentPath,
      'data': data,
    });

    return this;
  }

  @override
  MethodChannelTransaction set(String documentPath, Map<String, dynamic> data,
      [SetOptions? options]) {
    _commands.add(<String, dynamic>{
      'type': 'SET',
      'path': documentPath,
      'data': data,
      'options': {
        'merge': options?.merge,
        'mergeFields': options?.mergeFields,
      },
    });

    return this;
  }
}

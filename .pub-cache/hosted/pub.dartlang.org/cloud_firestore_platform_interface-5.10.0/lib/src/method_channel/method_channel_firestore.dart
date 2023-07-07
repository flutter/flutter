// ignore_for_file: require_trailing_commas
// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
// TODO(Lyokone): remove once we bump Flutter SDK min version to 3.3
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:_flutterfire_internals/_flutterfire_internals.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_load_bundle_task.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_query_snapshot.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/utils/source.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_collection_reference.dart';
import 'method_channel_document_reference.dart';
import 'method_channel_query.dart';
import 'method_channel_transaction.dart';
import 'method_channel_write_batch.dart';
import 'utils/exception.dart';
import 'utils/firestore_message_codec.dart';

/// The entry point for accessing a Firestore.
///
/// You can get an instance by calling [FirebaseFirestore.instance].
class MethodChannelFirebaseFirestore extends FirebaseFirestorePlatform {
  /// Create an instance of [MethodChannelFirebaseFirestore] with optional [FirebaseApp]
  MethodChannelFirebaseFirestore({FirebaseApp? app}) : super(appInstance: app);

  /// The [FirebaseApp] instance to which this [FirebaseDatabase] belongs.
  ///
  /// If null, the default [FirebaseApp] is used.

  /// The [MethodChannel] used to communicate with the native plugin
  static MethodChannel channel = const MethodChannel(
    'plugins.flutter.io/firebase_firestore',
    StandardMethodCodec(FirestoreMessageCodec()),
  );

  /// The [EventChannel] used for query snapshots
  static EventChannel querySnapshotChannel(String id) {
    return EventChannel(
      'plugins.flutter.io/firebase_firestore/query/$id',
      const StandardMethodCodec(FirestoreMessageCodec()),
    );
  }

  /// The [EventChannel] used for document snapshots
  static EventChannel documentSnapshotChannel(String id) {
    return EventChannel(
      'plugins.flutter.io/firebase_firestore/document/$id',
      const StandardMethodCodec(FirestoreMessageCodec()),
    );
  }

  /// The [EventChannel] used for snapshotsInSync
  static EventChannel snapshotsInSyncChannel(String id) {
    return EventChannel(
      'plugins.flutter.io/firebase_firestore/snapshotsInSync/$id',
      const StandardMethodCodec(FirestoreMessageCodec()),
    );
  }

  /// The [EventChannel] used for loadBundle
  static EventChannel loadBundleChannel(String id) {
    return EventChannel(
      'plugins.flutter.io/firebase_firestore/loadBundle/$id',
      const StandardMethodCodec(FirestoreMessageCodec()),
    );
  }

  /// Gets a [FirebaseFirestorePlatform] with specific arguments such as a different
  /// [FirebaseApp].
  @override
  FirebaseFirestorePlatform delegateFor({required FirebaseApp app}) {
    return MethodChannelFirebaseFirestore(app: app);
  }

  @override
  LoadBundleTaskPlatform loadBundle(Uint8List bundle) {
    return MethodChannelLoadBundleTask(
      task: channel.invokeMethod<String>('LoadBundle#snapshots'),
      bundle: bundle,
      firestore: this,
    );
  }

  @override
  Future<QuerySnapshotPlatform> namedQueryGet(
    String name, {
    GetOptions options = const GetOptions(),
  }) async {
    try {
      final Map<String, dynamic>? data = await MethodChannelFirebaseFirestore
          .channel
          .invokeMapMethod<String, dynamic>(
        'Firestore#namedQueryGet',
        <String, dynamic>{
          'name': name,
          'firestore': FirebaseFirestorePlatform.instance,
          'source': getSourceString(options.source),
          'serverTimestampBehavior': getServerTimestampBehaviorString(
            options.serverTimestampBehavior,
          ),
        },
      );

      return MethodChannelQuerySnapshot(
        FirebaseFirestorePlatform.instance,
        data!,
      );
    } catch (e, stack) {
      if (e.toString().contains('Named query has not been found')) {
        Error.throwWithStackTrace(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'non-existent-named-query',
            message: 'Named query has not been found. '
                'Please check it has been loaded properly via loadBundle().',
          ),
          stack,
        );
      }

      convertPlatformException(e, stack);
    }
  }

  @override
  WriteBatchPlatform batch() => MethodChannelWriteBatch(this);

  @override
  Future<void> clearPersistence() async {
    try {
      await channel
          .invokeMethod<void>('Firestore#clearPersistence', <String, dynamic>{
        'firestore': this,
      });
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> enablePersistence(
      [PersistenceSettings? persistenceSettings]) async {
    throw UnimplementedError(
        'enablePersistence() is only available for Web. Use [Settings.persistenceEnabled] for other platforms.');
  }

  @override
  CollectionReferencePlatform collection(String collectionPath) {
    return MethodChannelCollectionReference(this, collectionPath);
  }

  @override
  QueryPlatform collectionGroup(String collectionPath) {
    return MethodChannelQuery(this, collectionPath,
        isCollectionGroupQuery: true);
  }

  @override
  Future<void> disableNetwork() async {
    try {
      await channel
          .invokeMethod<void>('Firestore#disableNetwork', <String, dynamic>{
        'firestore': this,
      });
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  DocumentReferencePlatform doc(String documentPath) {
    return MethodChannelDocumentReference(this, documentPath);
  }

  @override
  Future<void> enableNetwork() async {
    try {
      await channel
          .invokeMethod<void>('Firestore#enableNetwork', <String, dynamic>{
        'firestore': this,
      });
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Stream<void> snapshotsInSync() {
    StreamSubscription<dynamic>? snapshotStreamSubscription;
    late StreamController<void> controller; // ignore: close_sinks

    controller = StreamController<void>.broadcast(
      onListen: () async {
        final observerId = await MethodChannelFirebaseFirestore.channel
            .invokeMethod<String>('SnapshotsInSync#setup');

        snapshotStreamSubscription =
            MethodChannelFirebaseFirestore.snapshotsInSyncChannel(observerId!)
                .receiveGuardedBroadcastStream(
          arguments: <String, dynamic>{'firestore': this},
          onError: convertPlatformException,
        ).listen(
          (event) => controller.add(null),
          onError: controller.addError,
        );
      },
      onCancel: () {
        snapshotStreamSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    assert(timeout.inMilliseconds > 0,
        'Transaction timeout must be more than 0 milliseconds');

    final String? transactionId =
        await MethodChannelFirebaseFirestore.channel.invokeMethod<String>(
      'Transaction#create',
    );

    Completer<T> completer = Completer();

    // Will be set by the `transactionHandler`.
    late T result;

    final eventChannel = EventChannel(
      'plugins.flutter.io/firebase_firestore/transaction/$transactionId',
      const StandardMethodCodec(FirestoreMessageCodec()),
    );

    final snapshotStreamSubscription =
        eventChannel.receiveGuardedBroadcastStream(
      arguments: <String, dynamic>{
        'firestore': this,
        'timeout': timeout.inMilliseconds,
        'maxAttempts': maxAttempts,
      },
      onError: convertPlatformException,
    ).listen(
      (event) async {
        if (event['error'] != null) {
          completer.completeError(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: event['error']['code'],
              message: event['error']['message'],
            ),
          );
          return;
        } else if (event['complete'] == true) {
          completer.complete(result);
          return;
        }

        final TransactionPlatform transaction =
            MethodChannelTransaction(transactionId!, event['appName']);

        // If the transaction fails on Dart side, then forward the error
        // right away and only inform native side of the error.
        try {
          result = await transactionHandler(transaction) as T;
        } catch (error, stack) {
          // Signal native that a user error occurred, and finish the
          // transaction
          await MethodChannelFirebaseFirestore.channel
              .invokeMethod('Transaction#storeResult', <String, dynamic>{
            'transactionId': transactionId,
            'result': {
              'type': 'ERROR',
            }
          });

          // Allow the [runTransaction] method to listen to an error.

          completer.completeError(error, stack);

          return;
        }

        // Send the transaction commands to Dart.
        await MethodChannelFirebaseFirestore.channel
            .invokeMethod('Transaction#storeResult', <String, dynamic>{
          'transactionId': transactionId,
          'result': {
            'type': 'SUCCESS',
            'commands': transaction.commands,
          },
        });
      },
    );

    return completer.future.whenComplete(snapshotStreamSubscription.cancel);
  }

  @override
  Settings settings = const Settings();

  @override
  Future<void> terminate() async {
    try {
      await channel.invokeMethod<void>('Firestore#terminate', <String, dynamic>{
        'firestore': this,
      });
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> waitForPendingWrites() async {
    try {
      await channel.invokeMethod<void>(
          'Firestore#waitForPendingWrites', <String, dynamic>{
        'firestore': this,
      });
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> setIndexConfiguration(String indexConfiguration) async {
    try {
      await channel.invokeMethod<void>(
          'Firestore#setIndexConfiguration', <String, dynamic>{
        'firestore': this,
        'indexConfiguration': indexConfiguration,
      });
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }
}

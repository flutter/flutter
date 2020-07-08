// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'message_codec.dart';
import 'message_codecs.dart';
import 'system_channels.dart';

typedef _BucketVisitor = void Function(RestorationBucket bucket);

/// Manages the restoration data in the framework and synchronizes it with the
/// engine.
///
/// Restoration data can be serialized out and - at a later point in time - be
/// used to restore the application to the previous state described by the
/// serialized data. Mobile operating systems use the concept of state
/// restoration to provide the illusion that apps continue to run in the
/// background forever: After an app has been backgrounded, the user can always
/// return to it and find it in the same state. In practice, the operating
/// system may, however, terminate the app to free resources for other apps
/// running in the foreground. Before that happens, the app gets a chance to
/// serialize out its restoration data. When the user navigates back to the
/// backgrounded app, it is restarted and the serialized restoration data is
/// provided to it again. Ideally, the app will use that data to restore itself
/// to the same state it was in when the user backgrounded the app.
///
/// In Flutter, restoration data is organized in a tree of [RestorationBucket]s
/// which is rooted in the [rootBucket]. All information that the application
/// needs to restore its current state must be stored in a bucket in this
/// hierarchy. To store data in the hierarchy, entities (e.g. [Widget]s) must
/// claim ownership of a child bucket from a parent bucket (which may be the
/// [rootBucket] provided by this [RestorationManager]). The owner of a bucket
/// may store arbitrary values in the bucket as long as they can be serialized
/// with the [StandardMessageCodec]. The values are stored in the bucket under a
/// given [RestorationId] as key. The [RestorationId]s used to store values must
/// be unique within a given bucket. To access the stored value again during
/// state restoration, the same [RestorationId] must be provided again. The
/// owner of the bucket may also make the bucket available to other entities so
/// that they can claim child buckets from it for their own restoration needs.
/// Within a bucket, child buckets are also identified by unique
/// [RestorationId]s. The restoration id must be provided when claiming a child
/// bucket.
///
/// When restoration data is provided to the [RestorationManager] (e.g. after
/// the application relaunched when foregrounded again), the bucket hierarchy
/// with all the data stored in it is restored. Entities can retrieve the data
/// again by using the same restoration ids that they originally used to store
/// the data.
///
/// In addition to providing restoration data when the app is launched,
/// restoration data may also be provided to a running app to restore it to a
/// previous state. When this happens, the current bucket hierarchy is
/// decommissioned and replaced with the hierarchy deserialized from the newly
/// provided restoration data. Buckets in the old hierarchy notify their
/// listeners when they get decommissioned. In response to the notification,
/// listeners must stop using the old buckets. Owners of those buckets must
/// dispose of them and claim a new child as a replacement from a parent in the
/// new bucket hierarchy (that parent may be the updated [rootBucket]).
///
/// Same platforms restrict the size of the restoration data. Therefore, the
/// data stored in the buckets should be as minimal as possible while still
/// allowing the app to restore its current state from it. Data that can be
/// retrieved from other services (e.g. a database or a web server) should not
/// be included in the restoration data. Instead, a small identifier (e.g. an ID
/// or resource locator) should be stored that can be used to retrieve the data
/// again from its original source during state restoration.
///
/// The [RestorationManager] sends a serialized version of the bucket hierarchy
/// over to the engine at the end of a frame in which the data in the hierarchy
/// or its shape has changed. The engine caches the data until the operating
/// system needs it. The application is responsible for keeping the data in the
/// bucket always up-to-date to reflect its current state.
///
/// ## Discussion
///
/// Due to Flutter's threading model and restrictions in the APIs of the
/// platforms Flutter runs on, restoration data must be stored in the buckets
/// proactively as described above. When the operating system asks for the
/// restoration data, it will do so on the platform thread expecting a
/// synchronous response. To avoid the risk of deadlocks, the platform thread
/// cannot block and call into the UI thread (where the dart code is running) to
/// retrieve the restoration data. For this reason, the [RestorationManager]
/// always sends the latest copy of the restoration data from the UI thread over
/// to the platform thread whenever it changes. That way, the restoration data
/// is always ready to go on the platform thread when the operating system needs
/// it.
///
/// See also:
///
///  * [ServicesBinding.restorationManager], which holds the singleton instance
///    of the [RestorationManager] for the currently running application.
///  * [RestorationBucket], which make up the restoration data hierarchy.
///  * [RestorationId], which identifies a value or a child uniquely within a
///    [RestorationBucket].
///  * [RestorationMixin], which uses [RestorationBucket]s behind the scenes
///    to make [State] objects of [StatefulWidget]s restorable.
class RestorationManager {
  /// The root of the [RestorationBucket] hierarchy containing the restoration
  /// data.
  ///
  /// Child buckets can be claimed from this bucket via
  /// [RestorationBucket.claimChild]. If the [RestorationManager] has been asked
  /// to restore the application to a previous state, these buckets will contain
  /// the previously stored data. Otherwise the root bucket (and all children
  /// claimed from it) will be empty.
  ///
  /// Like any [RestorationBucket], the root bucket informs its listeners if it
  /// has been replaced with a new root bucket. This happens when new
  /// restoration data has been provided to the [RestorationManager] to restore
  /// the application to a different state. In response to the notification,
  /// listeners must stop using the old root bucket and obtain the new one via
  /// this getter ([rootBucket] will have been updated to return the new bucket
  /// just before the old root bucket informs its listeners).
  ///
  /// The restoration data describing the current bucket hierarchy is retrieved
  /// asynchronously from the engine the first time the root bucket is accessed
  /// via this getter. After the data has been copied over from the engine, this
  /// getter will return a [SynchronousFuture], that immediately resolves to the
  /// root [RestorationBucket].
  ///
  /// See also:
  ///
  ///  * [RootRestorationScope], which makes the root bucket available in the
  ///    [Widget] tree.
  Future<RestorationBucket> get rootBucket {
    if (!_isListeningForEngineUpdates) {
      SystemChannels.restoration.setMethodCallHandler(_methodHandler);
      _isListeningForEngineUpdates = true;
    }
    if (_rootBucket != null) {
      return SynchronousFuture<RestorationBucket>(_rootBucket);
    }
    if (_pendingRootBucket == null) {
      _pendingRootBucket = Completer<RestorationBucket>();
      _getRootBucketFromEngine();
    }
    return _pendingRootBucket.future;
  }
  RestorationBucket _rootBucket;
  Completer<RestorationBucket> _pendingRootBucket;
  bool _isListeningForEngineUpdates = false;

  Future<void> _getRootBucketFromEngine() async {
    final Map<String, dynamic> data = await retrieveFromEngine();
    if (_pendingRootBucket == null) {
      // The engine was faster in sending us the data via the 'push' method on
      // the SystemChannel.
      return;
    }
    assert(_rootBucket == null);
    _setRootBucket(data);
  }

  void _setRootBucket(Map<String, dynamic> data) {
    _rootBucket = _createRootBucket(data);
    _pendingRootBucket?.complete(_rootBucket);
    _pendingRootBucket = null;
  }

  RestorationBucket _createRootBucket(Map<String, dynamic> data) {
    return RestorationBucket.root(manager: this, rawData: data);
  }

  Future<dynamic> _methodHandler(MethodCall call) {
    switch (call.method) {
      case 'push':
        handleRestorationDataUpdate(call.arguments as Uint8List);
        break;
      default:
        throw UnimplementedError("${call.method} was invoked but isn't implemented by $runtimeType");
    }
    return null;
  }

  /// Called by the [RestorationManager] on itself when the engine has provided
  /// new serialized restoration `data`.
  ///
  /// The method decommissions the current [rootBucket] and replaces it with
  /// the bucket hierarchy obtained by de-serializing the provided `data`.
  @protected
  void handleRestorationDataUpdate(Uint8List data) {
    final RestorationBucket oldRoot = _rootBucket;
    _setRootBucket(decodeRestorationData(data));
    if (oldRoot != null) {
      oldRoot
        ..decommission()
        ..dispose();
    }
  }

  /// Called by the [RestorationManager] on itself to retrieve the restoration
  /// data provided by the operating system from the engine.
  ///
  /// The method can be overridden in tests to inject arbitrary restoration
  /// data. It is invoked the first time the [rootBucket] is accessed.
  ///
  /// The data returned by this method must be either null (to indicate that no
  /// data is available) or a nested map describing the entire bucket hierarchy
  /// that makes up the restoration data:
  ///
  /// ```
  /// {
  ///  'v': {  // key-value pairs
  ///     // * key is the string representation of a [RestorationID]
  ///     // * value is any primitive that can be encoded with [StandardMessageCodec]
  ///    '<restoration-id>: <Object>,
  ///   },
  ///  'c': {  // child buckets
  ///    'restoration-id': <nested map representing a child bucket>
  ///   }
  /// }
  /// ```
  @protected
  Future<Map<String, dynamic>> retrieveFromEngine() async {
    final Uint8List raw = await SystemChannels.restoration.invokeMethod<Uint8List>('get');
    return decodeRestorationData(raw);
  }

  /// Called by the [RestorationManager] on itself to send the provided
  /// `rawData` to the engine.
  ///
  /// The `rawData` describes the entire bucket hierarchy that makes up the
  /// current restoration data. The format of the data is described in
  /// [retrieveFromEngine]. The provided `rawData` can be serialized with the
  /// [StandardMessageCodec].
  ///
  /// This method can be overridden in tests to capture the restoration data
  /// that would have been send to the engine.
  @protected
  Future<void> sendToEngine(Map<String, dynamic> rawData) {
    assert(rawData != null);
    return SystemChannels.restoration.invokeMethod<void>(
      'put',
      encodeRestorationData(rawData),
    );
  }

  /// Called by the [RestorationManager] on itself to deserialize the
  /// restoration `data` obtained from the engine via [retrieveFromEngine].
  ///
  /// See also:
  ///
  ///  * [encodeRestorationData], which is the opposite of this method.
  @protected
  Map<String, dynamic> decodeRestorationData(Uint8List data) {
    if (data == null) {
      return null;
    }
    final ByteData encoded = data.buffer.asByteData(data.offsetInBytes, data.lengthInBytes);
    return castToMap<String, dynamic>(
      const StandardMessageCodec().decodeMessage(encoded),
    );
  }

  /// Called by the [RestorationManager] on itself to serialized the
  /// restoration `data` before sending it to the engine via [sendToEngine].
  ///
  /// See also:
  ///
  ///  * [decodeRestorationData], which is the opposite of this method.
  @protected
  Uint8List encodeRestorationData(Map<String, dynamic> data) {
    final ByteData encoded = const StandardMessageCodec().encodeMessage(data);
    return encoded.buffer.asUint8List(encoded.offsetInBytes, encoded.lengthInBytes);
  }

  bool _debugDoingUpdate = false;
  bool _postFrameScheduled = false;

  final Set<VoidCallback> _finalizers = <VoidCallback>{};

  /// Schedules a post frame callback to serialize the current hierarchy of
  /// restoration buckets and send it over to the engine.
  ///
  /// Called by [RestorationBucket]s whenever the data stored in them has
  /// changed or the shape of the bucket hierarchy has been modified.
  ///
  /// The task will execute at the end of the current frame or - if currently
  /// not producing a frame - at the end of the next frame. Just before the
  /// hierarchy is serialized and send over to the engine, the optionally
  /// provided `finalizer` is called. The callback may be used to check the
  /// integrity of the data in a given bucket. It is illegal to call
  /// [scheduleSerialization] from within the `finalizer` callback.
  void scheduleSerialization({VoidCallback finalizer}) {
    // The concept of `finalizer` callbacks is necessary to properly use
    // restoration buckets in the [Widget] tree because of the way widgets are
    // disposed during the build phase: Flutter delays the disposal of widgets
    // until the very end of the build phase. When during a build widget A is
    // getting replaced by widget B, B will build before A is disposed. This
    // causes a problem if both widgets want to claim a child restoration bucket
    // with ID x. In theory, this should be allowed because since A is getting
    // replaced by B, A will give up the bucket in its dispose method so that B
    // can claim a bucket with the same ID when it builds. However, in reality B
    // will claim the bucket before A has released it, which means for a very
    // short time (until A is actually getting disposed) there will be two child
    // buckets under the same restoration ID, which is illegal. To get around
    // this problem, restoration buckets do actually allow claiming child
    // buckets for restoration IDs that have already been claimed in the hopes
    // that the original owner will give up the bucket before the restoration
    // data is finalized and sent to the engine at the end of the frame. They
    // check whether this hope became reality in a finalizer callback.

    assert(_rootBucket != null);
    assert(!_debugDoingUpdate, 'Calling scheduleUpdate from a finalizer is not allowed.');
    if (finalizer != null) {
      _finalizers.add(finalizer);
    }
    if (!_postFrameScheduled) {
      _postFrameScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration _) => _doProcessing());
    }
  }

  // TODO(goderbauer): Add API to request out-of-band serialization when no frame is scheduled.

  void _doProcessing() {
    assert(() {
      _debugDoingUpdate = true;
      return true;
    }());
    _postFrameScheduled = false;

    for (final VoidCallback finalizer in _finalizers) {
      finalizer();
    }
    _finalizers.clear();
    sendToEngine(_rootBucket._rawData);

    assert(() {
      _debugDoingUpdate = false;
      return true;
    }());
  }
}

/// Identifies a piece of data within or a child of a [RestorationBucket].
///
/// The [value] of a [RestorationId]s must be unique within a given
/// [RestorationBucket]. [RestorationId] objects with the same [value] are
/// considered equal.
@immutable
class RestorationId {
  /// Creates a [RestorationId].
  ///
  /// The provided `value` must not be null.
  const RestorationId(this.value) : assert(value != null);

  /// The value of the [RestorationId].
  ///
  /// Two [RestorationId] objects with the same [value] are considered equal.
  final String value;

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is RestorationId && other.value == value;
  }

  @override
  int get hashCode => hashValues(runtimeType, value);

  @override
  String toString() {
    return '${objectRuntimeType(this, 'RestorationId')}($value)';
  }
}

/// A [RestorationBucket] holds pieces of the restoration data that a part of
/// the application needs to restore its state.
///
/// For a general overview of how state restoration works in Flutter, see the
/// [RestorationManager].
///
/// [RestorationBucket]s are organized in a tree, that is rooted in
/// [RestorationManager.rootBucket] and managed by a [RestorationManager]. The
/// tree is serializable and must contain all the data an application needs to
/// restore its current state at a later point in time.
///
/// A [RestorationBucket] stores restoration data as key-value pairs. The key is
/// a [RestorationId] that identifies a piece of data uniquely within a bucket.
/// The value can be anything that is serializable via the
/// [StandardMessageCodec]. Furthermore, a [RestorationBucket] may have child
/// buckets, which are identified within their parent via a unique
/// [RestorationId] as well.
///
/// During state restoration, the data previously stored in the
/// [RestorationBucket] hierarchy will be made available again to the
/// application to restore it to the state it had when the data was collected.
/// State restoration to a previous state may happen when the app is launched
/// (e.g. after it has been terminated while running in the background) or after
/// the app has already been running for a while.
///
/// ## Lifecycle
///
/// A [RestorationBucket] is rarely instantiated directly via its constructors.
/// Instead, when an entity wants to store data in or retrieve data from a
/// restoration bucket, it typically obtains a child bucket from a parent by
/// calling [claimChild]. If no parent is available,
/// [RestorationManager.rootBucket] may be used as a parent. When claiming a
/// child, the claimer must provide the [RestorationId] of the child it would
/// like to own. A child bucket with a given [RestorationId] can at most have
/// one owner. If another owner tries to claim a bucket with the same ID from
/// the same parent, an exception is thrown (see discussion in [claimChild]).
/// The [RestorationId]s that a given owner uses to claim a child (and to store
/// data in that child, see below) must be stable across app launches to ensure
/// that after the app restarts the owner can retrieve the same data again that
/// it stored during a previous run.
///
/// Per convention, the owner of the bucket has exclusive access to the values
/// stored in the bucket. It can read, add, modify, and remove values via the
/// [get], [put], and [remove] methods. In general, the owner should store all
/// the data in the bucket that it needs to restore its current state. If its
/// current state changes, the data in the bucket must be updated. At the same
/// time, the data in the bucket should be kept as minimal as possible. For
/// example, for data that can be retrieved from other sources (like a database
/// or webservice) only enough information (e.g. an ID or resource locator) to
/// re-obtain that data should be stored in the bucket. In addition to managing
/// the data in a bucket, an owner may also make the bucket available to other
/// entities so they can claim child buckets from it via [claimChild] for their
/// own restoration needs.
///
/// The bucket returned by [claimChild] may either contain state information
/// that the owner had previously (e.g. during a previous run of the
/// application) stored in it or it may be empty. If the bucket contains data,
/// the owner is expected to restore its state with the information previously
/// stored in the bucket. If the bucket is empty, it may initialize itself to
/// default values.
///
/// During the lifetime of a bucket, it may notify its listeners that the bucket
/// has been [decommission]ed. This happens when new restoration data has been
/// provided to e.g. the [RestorationManager] to restore the application to a
/// different state. In response to the notification, owners must dispose their
/// current bucket and replace it with a new bucket claimed from a new parent
/// (which will have been initialized with the new restoration data). For
/// example, if the owner previously claimed its bucket from
/// [RestorationManager.rootBucket], it must claim its new bucket from there
/// again. The root bucket will have been replaced with the new root bucket just
/// before the bucket listeners are informed about the decommission. Once the
/// new bucket is obtained, owners should restore their internal state according
/// to the information in the new bucket.
///
/// When the data stored in a bucket is no longer needed to restore the
/// application to its current state (e.g. because the owner of the bucket is no
/// longer shown on screen), the bucket must be [dispose]d. This will remove all
/// information stored in the bucket from the app's restoration data and that
/// information will not be available again when the application is restored to
/// this state in the future.
class RestorationBucket extends ChangeNotifier {
  /// Creates an empty [RestorationBucket] to be provided to [adoptChild] to add
  /// it to the bucket hierarchy.
  ///
  /// {@template flutter.services.restoration.bucketcreation}
  /// Instantiating a bucket directly is rare, most buckets are created by
  /// claiming a child from a parent via [claimChild]. If no parent bucket is
  /// available, [RestorationManager.rootBucket] may be used as a parent.
  /// {@endtemplate}
  ///
  /// The restoration `id` must not be null.
  RestorationBucket.empty({
    @required RestorationId id,
    @required this.debugOwner,
  }) : assert(id != null),
       _id = id,
       _rawData = <String, dynamic>{};

  /// Creates the root [RestorationBucket] for the provided restoration
  /// `manager`.
  ///
  /// If `rawData` is null, an empty bucket will be created. Otherwise the
  /// bucket hierarchy rooted in the created bucket will be initialized with the
  /// provided data. The `rawData` must have the format described under
  /// [RestorationManager.retrieveFromEngine].
  ///
  /// {@macro flutter.services.restoration.bucketcreation}
  ///
  /// The `manager` argument must not be null.
  RestorationBucket.root({
    @required RestorationManager manager,
    @required Map<String, dynamic> rawData,
  }) : assert(manager != null),
       _manager = manager,
       _rawData = rawData ?? <String, dynamic>{},
       _id = const RestorationId('root'),
       debugOwner = manager;

  /// Creates a child bucket initialized with the data that the provided
  /// `parent` has stored under the provided [id].
  ///
  /// This constructor cannot be used if the `parent` does not have any child
  /// data stored under the given ID. In that case, create an empty bucket (via
  /// [RestorationBucket.empty] and have the parent adopt it via [adoptChild].
  ///
  /// {@macro flutter.services.restoration.bucketcreation}
  ///
  /// The `id` and `parent` argument must not be null.
  RestorationBucket.child({
    @required RestorationId id,
    @required RestorationBucket parent,
    @required this.debugOwner,
  }) : assert(id != null),
       assert(parent != null),
       assert(parent._rawChildren[id.value] != null),
       _manager = parent._manager,
       _parent = parent,
       _rawData = castToMap<String, dynamic>(parent._rawChildren[id.value]),
       _id = id;

  static const String _childrenMapKey = 'c';
  static const String _valuesMapKey = 'v';

  final Map<String, dynamic> _rawData;

  /// The owner of the bucket that was provided when the bucket was claimed via
  /// [claimChild].
  ///
  /// The value is used in error messages.
  final Object debugOwner;

  RestorationManager _manager;
  RestorationBucket _parent;

  /// The [RestorationId] under which the bucket is currently stored in the
  /// parent of this bucket (or wants to be stored if it is currently
  /// parent-less).
  ///
  /// This value is never null.
  RestorationId get id => _id;
  RestorationId _id;

  Map<String, dynamic> get _rawChildren => castToMap<String, dynamic>(_rawData.putIfAbsent(_childrenMapKey, () => <String, dynamic>{}));
  Map<String, dynamic> get _rawValues => castToMap<String, dynamic>(_rawData.putIfAbsent(_valuesMapKey, () => <String, dynamic>{}));

  /// Called to signal that this bucket and all its descendants are no longer
  /// part of the current restoration data and must not be used anymore.
  ///
  /// Calling this method will drop this bucket from its parent and notify all
  /// its listeners as well as all listeners of its descendants. Once a bucket
  /// has notified its listeners, it must not be used anymore. The bucket must
  /// be [dispose]d and replaced with a new bucket.
  ///
  /// As an example, the [RestorationManager] calls this method on its root
  /// bucket when it has been asked to restore a running application to a
  /// different state. At that point, the data stored in the current bucket
  /// hierarchy is invalid and will be replaced with a new hierarchy generated
  /// from the restoration data describing the new state. To replace the current
  /// bucket hierarchy, [decommission] is called on the root bucket to signal to
  /// all owners of buckets in the hierarchy that their bucket has become
  /// invalid. In response to the notification, bucket owners must [dispose]
  /// their buckets and claim a new bucket from the newly created hierarchy. For
  /// example, the owner of a bucket that was originally claimed from the
  /// [RestorationManager.rootBucket] must dispose that bucket and claim a new
  /// bucket from the new [RestorationManager.rootBucket]. Once the new bucket
  /// is claimed, owners should restore their state according to the data stored
  /// in the new bucket.
  ///
  /// A call to [decommission] must always be followed by a call to [dispose].
  void decommission() {
    _parent?._dropChild(this);
    _parent = null;
    _performDecommission();
  }

  void _performDecommission() {
    _manager = null;
    notifyListeners();
    _visitChildren((RestorationBucket bucket) {
      bucket._performDecommission();
    });
  }

  // Get and store values.

  /// Returns the value that is currently stored in the bucket under the
  /// provided `id`.
  ///
  /// Returns null if nothing is stored under that id.
  ///
  /// See also:
  ///
  ///  * [put], which stores a value in the bucket.
  ///  * [remove], which removes a value from the bucket.
  P get<P>(RestorationId id) {
    assert(id != null);
    return _rawValues[id.value] as P;
  }

  /// Stores the provided `value` under the provided `id` in the bucket.
  ///
  /// Any value that has previously been stored under that id is overwritten
  /// with the new value. The provided `value` must be serializable with the
  /// [StandardMessageCodec].
  ///
  /// Null values will be stored in the bucket as-is. To remove a value, use
  /// [remove].
  ///
  /// See also:
  ///
  ///  * [get], which retrieves a stored value from the bucket.
  ///  * [remove], which removes a value from the bucket.
  void put<P>(RestorationId id, P value) {
    assert(id != null);
    assert(debugIsSerializableForRestoration(value));
    if (_rawValues[id.value] != value || !_rawValues.containsKey(id.value)) {
      _rawValues[id.value] = value;
      _manager?.scheduleSerialization();
    }
  }

  /// Deletes the value currently stored under the provided `id` from the
  /// bucket.
  ///
  /// The value removed from the bucket is returned. If no value was stored
  /// under that id, null is returned.
  P remove<P>(RestorationId id) {
    assert(id != null);
    final bool needsUpdate = _rawValues.containsKey(id.value);
    final P result = _rawValues.remove(id.value) as P;
    if (_rawValues.isEmpty) {
      _rawData.remove(_valuesMapKey);
    }
    if (needsUpdate) {
      _manager?.scheduleSerialization();
    }
    return result;
  }

  // Child management.

  // The restoration IDs and associated buckets of children that have been
  // claimed via [claimChild].
  final Map<RestorationId, RestorationBucket> _claimedChildren = <RestorationId, RestorationBucket>{};
  // Newly created child buckets that are scheduled to be added to [_rawChildren] in
  // [_finalize], see comment in [claimChild] for details.
  final Map<RestorationId, Set<RestorationBucket>> _childrenToAdd = <RestorationId, Set<RestorationBucket>>{};

  /// Claims ownership of the child with the provided `id` from this bucket.
  ///
  /// If the application is getting restored to a previous state, the bucket
  /// will contain all the data that was previously stored in the bucket.
  /// Otherwise, an empty bucket is returned.
  ///
  /// The claimer of the bucket is expected to use the data stored in the bucket
  /// to restore itself to its previous state described by the data in the
  /// bucket. If the bucket is empty, it should initialize itself to default
  /// values. Whenever the information, that the claimer needs to restore its
  /// state changes, the data in the bucket should be updated to reflect that.
  ///
  /// A child bucket with a given `id` can only have one owner. If another owner
  /// claims a child bucket with the same `id` an exception will be thrown at
  /// the end of the current frame unless the previous owner has either deleted
  /// its bucket by calling [dispose] or has moved it to a new parent via
  /// [adoptChild].
  ///
  /// When the returned bucket is no longer needed, it must be [dispose]d to
  /// delete the information stored in it from the app's restoration data.
  RestorationBucket claimChild(RestorationId id, {@required Object debugOwner}) {
    assert(id != null);
    // There are three cases to consider:
    // 1. Claiming an id that has already been claimed.
    // 2. Claiming an id that doesn't yet exist in [_rawChildren].
    // 3. Claiming an id that does exist in [_rawChildren] and hasn't been
    //    claimed yet.
    // If an id has already been claimed (case 1) the current owner may give up
    // that id later this frame and it can be re-used. In anticipation of the
    // previous owner's surrender of the id, we return an empty bucket for this
    // new claim and check in [_finalize] that at the end of the frame the old
    // owner actually did surrendered the id.
    // Case 2 also requires the creation of a new empty bucket.
    // In Case 3 we create a new bucket wrapping the existing data in
    // [_rawChildren].

    // Case 1+2: Adopt and return an empty bucket.
    if (_claimedChildren.containsKey(id) || !_rawChildren.containsKey(id.value)) {
      final RestorationBucket child = RestorationBucket.empty(
        debugOwner: debugOwner,
        id: id,
      );
      adoptChild(child);
      return child;
    }

    // Case 3: Return bucket wrapping the existing data.
    assert(_rawChildren[id.value] != null);
    final RestorationBucket child = RestorationBucket.child(
      id: id,
      parent: this,
      debugOwner: debugOwner,
    );
    _claimedChildren[id] = child;
    return child;
  }

  /// Adopts the provided `child` bucket.
  ///
  /// The `child` will be dropped from its old parent, if it had one.
  ///
  /// The `child` is stored under its [id] in this bucket. If this bucket
  /// already contains a child bucket under the same id, the owner of that
  /// existing bucket must give it up (e.g. by moving the child bucket to a
  /// different parent or by disposing it) before the end of the current frame.
  /// Otherwise an exception indicating the illegal use of duplicated
  /// [RestorationId]s will trigger in debug mode.
  ///
  /// No-op if the provided bucket is already a child of this bucket.
  void adoptChild(RestorationBucket child) {
    assert(child != null);
    if (child._parent != this) {
      child._parent?._removeChildData(child);
      child._parent = this;
      _addChildData(child);
      if (child._manager != _manager) {
        _recursivelyUpdateManager(child);
      }
    }
    assert(child._parent == this);
    assert(child._manager == _manager);
  }

  void _dropChild(RestorationBucket child) {
    assert(child != null);
    assert(child._parent == this);
    _removeChildData(child);
    child._parent = null;
    if (child._manager != null) {
      child._manager = null;
      _recursivelyUpdateManager(child);
    }
  }

  void _recursivelyUpdateManager(RestorationBucket bucket) {
    bucket._manager = _manager;
    bucket._visitChildren(_recursivelyUpdateManager);
  }

  void _finalize() {
    _childrenToAdd.forEach((RestorationId id, Set<RestorationBucket> buckets) {
      assert(() {
        final int claimCount = buckets.length + (_claimedChildren.containsKey(id) ? 1 : 0);
        if (claimCount > 1) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary('Multiple owners claimed child RestorationBuckets with the same ID.'),
            ErrorDescription('The following owners claimed child RestorationBuckets with id "$id" from the parent $this:'),
            ...buckets.map((RestorationBucket bucket) => ErrorDescription(
              ' * ${bucket.debugOwner}',
            )),
            if (_claimedChildren.containsKey(id))
              ErrorDescription(' * ${_claimedChildren[id].debugOwner} (current owner)'),
          ]);
        }
        return true;
      }());
      _finalizeAddChildData(buckets.first);
    });
    _childrenToAdd.clear();
  }

  void _removeChildData(RestorationBucket child) {
    assert(child != null);
    assert(child._parent == this);
    if (_claimedChildren.remove(child.id) == child) {
      _rawChildren.remove(child.id.value);
      if (_rawChildren.isEmpty) {
        _rawData.remove(_childrenMapKey);
      }
      _manager?.scheduleSerialization();
      return;
    }
    _childrenToAdd[child.id]?.remove(child);
    if (_childrenToAdd[child.id]?.isEmpty == true) {
      _childrenToAdd.remove(child.id);
    }
  }

  void _addChildData(RestorationBucket child) {
    assert(child != null);
    assert(child._parent == this);
    if (_claimedChildren.containsKey(child.id)) {
      // Delay addition until the end of the frame in the hopes that the current
      // owner of the child with the same id will have given up that child by
      // then.
      _childrenToAdd.putIfAbsent(child.id, () => <RestorationBucket>{}).add(child);
      _manager.scheduleSerialization(finalizer: _finalize);
      return;
    }
    _finalizeAddChildData(child);
    _manager.scheduleSerialization();
  }

  void _finalizeAddChildData(RestorationBucket child) {
    assert(_claimedChildren[child.id] == null);
    assert(_rawChildren[child.id.value] == null);
    _claimedChildren[child.id] = child;
    _rawChildren[child.id.value] = child._rawData;
  }

  void _visitChildren(_BucketVisitor visitor, {bool concurrentModification = false}) {
    Iterable<RestorationBucket> children = _claimedChildren.values
        .followedBy(_childrenToAdd.values.expand((Set<RestorationBucket> set) => set));
    if (concurrentModification) {
      children = children.toList(growable: false);
    }
    children.forEach(visitor);
  }

  // Bucket management

  /// Changes the [RestorationId] under which the bucket is stored in its parent
  /// to `newId`.
  ///
  /// No-op if the bucket is already stored under the provided id.
  void rename(RestorationId newId) {
    assert(newId != null);
    assert(_parent != null);
    if (newId == id) {
      return;
    }
    _parent._removeChildData(this);
    _id = newId;
    _parent._addChildData(this);
  }

  /// Deletes the bucket and all the data stored in it from the bucket
  /// hierarchy.
  ///
  /// After [dispose] has been called, the data stored in this bucket and its
  /// children are no longer part of the app's restoration data. The data
  /// originally stored in the bucket will not be available again when the
  /// application is restored to this state in the future. It is up to the
  /// owners of the children to either move them (via [adoptChild]) to a new
  /// parent that is still part of the bucket hierarchy or to [dispose] of them
  /// as well.
  ///
  /// This method must only be called by the object's owner.
  @override
  void dispose() {
    _parent?._removeChildData(this);
    _parent = null;
    _manager = null;
    _visitChildren(_dropChild, concurrentModification: true);
    _claimedChildren.clear();
    _childrenToAdd.clear();
    super.dispose();
  }

  @override
  String toString() => '${objectRuntimeType(this, 'RestorationBucket')}(id: $id, owner: $debugOwner)';
}

/// Returns true when the provided `object` is serializable for state
/// restoration.
///
/// Should only be called from within asserts.
bool debugIsSerializableForRestoration(Object object) {
  try {
    const StandardMessageCodec().encodeMessage(object);
    return true;
  } catch (_) {
    return false;
  }
}

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:_internal" which contains all the imports
/// used by patches of that library. We plan to change this when we have a
/// shared front end and simply use parts.

import "dart:async" show Timer;
import "dart:core" hide Symbol;
import "dart:ffi" show Pointer, Struct, Union, IntPtr, Handle, Void, Native;
import "dart:isolate" show SendPort;
import "dart:typed_data" show Int32List, Uint8List;

/// These are the additional parts of this patch library:
part "class_id_fasta.dart";
part "print_patch.dart";
part "symbol_patch.dart";

// On the VM, we don't make the entire legacy weak mode check
// const to avoid having a constant in the platform libraries
// which evaluates differently in weak vs strong mode.
@patch
bool typeAcceptsNull<T>() => (const <Null>[]) is List<int> || null is T;

@patch
@pragma("vm:external-name", "Internal_makeListFixedLength")
@pragma("vm:exact-result-type", "dart:core#_List")
external List<T> makeListFixedLength<T>(List<T> growableList);

@patch
@pragma("vm:external-name", "Internal_makeFixedListUnmodifiable")
@pragma("vm:exact-result-type", "dart:core#_ImmutableList")
external List<T> makeFixedListUnmodifiable<T>(List<T> fixedLengthList);

@patch
@pragma("vm:external-name", "Internal_extractTypeArguments")
external Object? extractTypeArguments<T>(T instance, Function extract);

/// The returned string is a [_OneByteString] with uninitialized content.
@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:external-name", "Internal_allocateOneByteString")
@pragma("vm:exact-result-type", "dart:core#_OneByteString")
external String allocateOneByteString(int length);

/// The [string] must be a [_OneByteString]. The [index] must be valid.
@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:external-name", "Internal_writeIntoOneByteString")
external void writeIntoOneByteString(String string, int index, int codePoint);

/// It is assumed that [from] is a native [Uint8List] class and [to] is a
/// [_OneByteString]. The [fromStart] and [toStart] indices together with the
/// [length] must specify ranges within the bounds of the list / string.
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
@pragma("vm:idempotent")
void copyRangeFromUint8ListToOneByteString(
    Uint8List from, String to, int fromStart, int toStart, int length) {
  for (int i = 0; i < length; i++) {
    writeIntoOneByteString(to, toStart + i, from[fromStart + i]);
  }
}

@pragma("vm:prefer-inline")
String createOneByteStringFromCharacters(Uint8List bytes, int start, int end) {
  final len = end - start;
  final s = allocateOneByteString(len);
  copyRangeFromUint8ListToOneByteString(bytes, s, start, 0, len);
  return s;
}

/// The returned string is a [_TwoByteString] with uninitialized content.
@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:external-name", "Internal_allocateTwoByteString")
@pragma("vm:exact-result-type", "dart:core#_TwoByteString")
external String allocateTwoByteString(int length);

/// The [string] must be a [_TwoByteString]. The [index] must be valid.
@pragma("vm:recognized", "asm-intrinsic")
@pragma("vm:external-name", "Internal_writeIntoTwoByteString")
external void writeIntoTwoByteString(String string, int index, int codePoint);

class VMLibraryHooks {
  // Example: "dart:isolate _Timer._factory"
  static Timer Function(int, void Function(Timer), bool)? timerFactory;

  // Example: "dart:io _EventHandler._sendData"
  static late void Function(Object?, SendPort, int) eventHandlerSendData;

  // A nullary closure that answers the current clock value in milliseconds.
  // Example: "dart:io _EventHandler._timerMillisecondClock"
  static late int Function() timerMillisecondClock;

  // Implementation of package root/map provision.
  static String? packageRootString;
  static String? packageConfigString;
  static Uri? Function()? packageConfigUriSync;
  static Uri? Function(Uri)? resolvePackageUriSync;

  static Uri Function()? _computeScriptUri;
  static Uri? _cachedScript;
  static set platformScript(Object? f) {
    _computeScriptUri = f as Uri Function()?;
    _cachedScript = null;
  }

  static Uri? get platformScript {
    return _cachedScript ??= _computeScriptUri?.call();
  }
}

@pragma("vm:recognized", "other")
@pragma('vm:prefer-inline')
external bool get has63BitSmis;

// Utility class now only used by the VM.
class Lists {
  @pragma("vm:prefer-inline")
  static void copy(List src, int srcStart, List dst, int dstStart, int count) {
    if (srcStart < dstStart) {
      for (int i = srcStart + count - 1, j = dstStart + count - 1;
          i >= srcStart;
          i--, j--) {
        dst[j] = src[i];
      }
    } else {
      for (int i = srcStart, j = dstStart; i < srcStart + count; i++, j++) {
        dst[j] = src[i];
      }
    }
  }
}

// Prepend the parent type arguments (maybe null) of length 'parentLen' to the
// function type arguments (may be null). The result is null if both input
// vectors are null or is a newly allocated and canonicalized vector of length
// 'totalLen'.
@pragma("vm:entry-point", "call")
@pragma("vm:external-name", "Internal_prependTypeArguments")
external _prependTypeArguments(
    functionTypeArguments, parentTypeArguments, parentLen, totalLen);

// Check that a set of type arguments satisfy the type parameter bounds on a
// closure.
@pragma("vm:entry-point", "call")
@pragma("vm:external-name", "Internal_boundsCheckForPartialInstantiation")
external _boundsCheckForPartialInstantiation(closure, typeArgs);

@patch
@pragma("vm:external-name", "Internal_unsafeCast")
external T unsafeCast<T>(dynamic v);

// This function can be used to keep an object alive till that point.
@pragma("vm:recognized", "other")
@pragma('vm:prefer-inline')
external void reachabilityFence(Object? object);

// This function can be used to encode native side effects.
//
// The function call and it's argument are removed in flow graph construction.
@pragma("vm:recognized", "other")
@pragma("vm:external-name", "Internal_nativeEffect")
external void _nativeEffect(Object object);

// Collection of functions which should only be used for testing purposes.
abstract class VMInternalsForTesting {
  // This function can be used by tests to enforce garbage collection.
  @pragma("vm:external-name", "Internal_collectAllGarbage")
  external static void collectAllGarbage();

  @pragma("vm:external-name", "Internal_deoptimizeFunctionsOnStack")
  external static void deoptimizeFunctionsOnStack();

  // Used to verify that PC addresses in stubs can be named using DWARF info
  // by returning the start offset into the isolate instructions that
  // corresponds to a known stub.
  @pragma("vm:external-name", "Internal_allocateObjectInstructionsStart")
  external static int allocateObjectInstructionsStart();

  // Used to verify that PC addresses in stubs can be named using DWARF info
  // by returning the end offset into the isolate instructions that corresponds
  // to a known stub.
  @pragma("vm:external-name", "Internal_allocateObjectInstructionsEnd")
  external static int allocateObjectInstructionsEnd();
}

@patch
T createSentinel<T>() => throw UnsupportedError('createSentinel');

@patch
bool isSentinel(dynamic value) => throw UnsupportedError('isSentinel');

@patch
class LateError {
  @pragma("vm:entry-point")
  static _throwFieldAlreadyInitialized(String fieldName) {
    throw new LateError.fieldAI(fieldName);
  }

  @pragma("vm:entry-point")
  static _throwLocalNotInitialized(String localName) {
    throw new LateError.localNI(localName);
  }

  @pragma("vm:entry-point")
  static _throwLocalAlreadyInitialized(String localName) {
    throw new LateError.localAI(localName);
  }

  @pragma("vm:entry-point")
  static _throwLocalAssignedDuringInitialization(String localName) {
    throw new LateError.localADI(localName);
  }
}

void checkValidWeakTarget(object, name) {
  if ((object == null) ||
      (object is bool) ||
      (object is num) ||
      (object is String) ||
      (object is Record) ||
      (object is Pointer) ||
      (object is Struct) ||
      (object is Union)) {
    throw new ArgumentError.value(object, name,
        "Cannot be a string, number, boolean, record, null, Pointer, Struct or Union");
  }
}

@pragma("vm:entry-point")
class FinalizerBase {
  /// The list of finalizers of this isolate.
  ///
  /// Reuses [WeakReference] so that we don't have to implement yet another
  /// mechanism to hold on weakly to things.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external static List<WeakReference<FinalizerBase>>? get _isolateFinalizers;
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external static set _isolateFinalizers(
      List<WeakReference<FinalizerBase>>? value);

  static int _isolateFinalizersPurgeCollectedAt = 1;

  /// Amortizes the cost for purging nulled out entries.
  ///
  /// Similar to how Expandos purge their nulled out entries on a rehash when
  /// resizing.
  static void _isolateFinalizersEnsureCapacity() {
    _isolateFinalizers ??= <WeakReference<FinalizerBase>>[];
    if (_isolateFinalizers!.length < _isolateFinalizersPurgeCollectedAt) {
      return;
    }
    // retainWhere does a single traversal.
    _isolateFinalizers!.retainWhere((weak) => weak.target != null);
    // We might have dropped most finalizers, trigger next resize at 2x.
    _isolateFinalizersPurgeCollectedAt = _isolateFinalizers!.length * 2;
  }

  /// Registers this [FinalizerBase] to the isolate.
  ///
  /// This is used to prevent sending messages from the GC to the isolate after
  /// isolate shutdown.
  void _isolateRegisterFinalizer() {
    _isolateFinalizersEnsureCapacity();
    _isolateFinalizers!.add(WeakReference(this));
  }

  /// The isolate this [FinalizerBase] belongs to.
  ///
  /// This is used to send finalizer messages to `_handleFinalizerMessage`
  /// without a Dart_Port.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external _setIsolate();

  /// All active attachments.
  ///
  /// This keeps the [FinalizerEntry]s belonging to this finalizer alive. If an
  /// entry gets collected, the finalizer is not run when the
  /// [FinalizerEntry.value] is collected.
  ///
  /// TODO(http://dartbug.com/47777): For native finalizers, what data structure
  /// can we use that we can modify in the VM. So that we don't have to send a
  /// message to Dart to clean up entries for which the GC has run.
  ///
  /// Requirements for data structure:
  /// 1. Keeps entries reachable. Entries that are collected will never run
  ///    the GC.
  /// 2. Atomic insert in Dart on `attach`. GC should not run in between.
  /// 3. Atomic remove in Dart on `detach`. multiple GC tasks run in parallel.
  /// 4. Atomic remove in C++ on value being collected. Multiple GC tasks run in
  ///    parallel.
  ///
  /// For Dart finalizers we execute the remove in Dart, much simpler.
  @pragma("vm:recognized", "other")
  @pragma('vm:prefer-inline')
  external Set<FinalizerEntry> get _allEntries;
  @pragma("vm:recognized", "other")
  @pragma('vm:prefer-inline')
  external set _allEntries(Set<FinalizerEntry> entries);

  /// Entries of which the value has been collected.
  ///
  /// This is a linked list, with [FinalizerEntry.next].
  ///
  /// Atomic exchange: The GC cannot run between reading the value and storing
  /// `null`. Atomicity guaranteed by force optimizing the function.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external FinalizerEntry? _exchangeEntriesCollectedWithNull();

  /// A weak map from `detach` keys to [FinalizerEntry]s.
  ///
  /// Using the [FinalizerEntry.detach] keys as keys in an [Expando] ensures
  /// they can be GCed.
  ///
  /// [FinalizerEntry]s do not get GCed themselves when their
  /// [FinalizerEntry.detach] is unreachable, in contrast to `WeakProperty`s
  /// which are GCed themselves when their `key` is no longer reachable.
  /// To prevent [FinalizerEntry]s staying around in [_detachments] forever,
  /// we reuse `WeakProperty`s.
  /// To avoid code duplication, we do not inline the code but use an [Expando]
  /// here instead.
  ///
  /// We cannot eagerly purge entries from the map (in the Expando) when GCed.
  /// The map is indexed on detach, and doesn't enable finding the entries
  /// based on their identity.
  /// Instead we rely on the WeakProperty being nulled out (assuming the
  /// `detach` key gets GCed) and then reused.
  @pragma("vm:recognized", "other")
  @pragma('vm:prefer-inline')
  external Expando<Set<FinalizerEntry>>? get _detachments;
  @pragma("vm:recognized", "other")
  @pragma('vm:prefer-inline')
  external set _detachments(Expando<Set<FinalizerEntry>>? value);

  void detach(Object detach) {
    final entries = detachments[detach];
    if (entries != null) {
      for (final entry in entries) {
        entry.token = entry;
        _allEntries.remove(entry);
      }
      detachments[detach] = null;
    }
  }
}

// Extension so that the members can be accessed from other libs.
extension FinalizerBaseMembers on FinalizerBase {
  /// See documentation on [_allEntries].
  @pragma('vm:prefer-inline')
  Set<FinalizerEntry> get allEntries => _allEntries;
  @pragma('vm:prefer-inline')
  set allEntries(Set<FinalizerEntry> value) => _allEntries = value;

  /// See documentation on [_exchangeEntriesCollectedWithNull].
  FinalizerEntry? exchangeEntriesCollectedWithNull() =>
      _exchangeEntriesCollectedWithNull();

  /// See documentation on [_detachments].
  @pragma('vm:prefer-inline')
  Expando<Set<FinalizerEntry>> get detachments {
    _detachments ??= Expando<Set<FinalizerEntry>>();
    return unsafeCast<Expando<Set<FinalizerEntry>>>(_detachments);
  }

  /// See documentation on [_isolateRegisterFinalizer].
  isolateRegisterFinalizer() => _isolateRegisterFinalizer();

  /// See documentation on [_setIsolate].
  setIsolate() => _setIsolate();
}

/// Contains the information of an active [Finalizer.attach].
///
/// It holds on to the [value], optional [detach], and [token]. In addition, it
/// also keeps a reference the [finalizer] it belongs to and a [next] field for
/// when being used in a linked list.
///
/// This is being kept alive by [FinalizerBase._allEntries] until either (1)
/// [Finalizer.detach] detaches it, or (2) [value] is collected and the
/// `callback` has been invoked.
///
/// Note that the GC itself uses an extra hidden field `next_seen_by_gc` to keep a
/// linked list of pending entries while running the GC.
@pragma("vm:entry-point")
class FinalizerEntry {
  @pragma('vm:never-inline')
  @pragma("vm:recognized", "other")
  @pragma("vm:external-name", "FinalizerEntry_allocate")
  external static FinalizerEntry allocate(
      Object value, Object? token, Object? detach, FinalizerBase finalizer);

  /// The [value] the [FinalizerBase] is attached to.
  ///
  /// Set to `null` by GC when unreachable.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object? get value;

  /// The [detach] object can be passed to [FinalizerBase] to detach
  /// the finalizer.
  ///
  /// Set to `null` by GC when unreachable.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object? get detach;

  /// The [token] is passed to [FinalizerBase] when the finalizer is run.
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object? get token;
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external set token(Object? value);

  /// The [next] entry in a linked list.
  ///
  /// Used in for the linked list starting from
  /// [FinalizerBase._exchangeEntriesCollectedWithNull].
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external FinalizerEntry? get next;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int get externalSize;

  /// Update the external size.
  @Native<Void Function(Handle, IntPtr)>(
      symbol: 'FinalizerEntry_SetExternalSize')
  external void setExternalSize(int externalSize);
}

@pragma("vm:external-name", "StringBase_intern")
external String intern(String str);

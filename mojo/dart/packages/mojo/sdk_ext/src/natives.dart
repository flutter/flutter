// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

// Data associated with an open handle.
class _OpenHandle {
  final StackTrace stack;
  String description;
  _OpenHandle(this.stack, {this.description});
}

class MojoCoreNatives {
  /// Returns the time, in microseconds, since some undefined point in the past.
  ///
  /// The values are only meaningful relative to other values that were obtained
  /// from the same device without an intervening system restart. Such values
  /// are guaranteed to be monotonically non-decreasing with the passage of real
  /// time.
  ///
  /// Although the units are microseconds, the resolution of the clock may vary
  /// and is typically in the range of ~1-15 ms.
  static int getTimeTicksNow() native "Mojo_GetTimeTicksNow";

  /// Returns the time, in milliseconds, since some undefined point in the past.
  ///
  /// This method is equivalent to `getTimeTicksNow() ~/ 1000`.
  static int timerMillisecondClock() => getTimeTicksNow() ~/ 1000;
}

class MojoHandleNatives {
  static HashMap<int, _OpenHandle> _openHandles = new HashMap();

  /// Puts the given [handleToken] with the given [description] into the set of
  /// open handles.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// This method is only used to report open handles (see [reportOpenHandles]).
  static void addOpenHandle(int handleToken, {String description}) {
    var stack;
    // We only remember a stack trace when in checked mode.
    assert((stack = StackTrace.current) != null);
    var openHandle = new _OpenHandle(stack, description: description);
    _openHandles[handleToken] = openHandle;
  }

  /// Removes the given [handleToken] from the set of open handles.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// This method is only used to report open handles (see [reportOpenHandles]).
  ///
  /// Handles are removed from the set when they are closed, but also, when they
  /// are serialized in the mojo encoder [codec.dart].
  static void removeOpenHandle(int handleToken) {
    _openHandles.remove(handleToken);
  }

  static void _reportOpenHandle(int handle, _OpenHandle openHandle) {
    StringBuffer sb = new StringBuffer();
    sb.writeln('HANDLE LEAK: handle: $handle');
    if (openHandle.description != null) {
      sb.writeln('HANDLE LEAK: description: ${openHandle.description}');
    }
    if (openHandle.stack != null) {
      sb.writeln('HANDLE LEAK: creation stack trace:');
      sb.writeln(openHandle.stack);
    } else {
      sb.writeln('HANDLE LEAK: creation stack trace available in strict mode.');
    }
    print(sb.toString());
  }

  /// Prints a list of all open handles.
  ///
  /// Returns `true` if there are no open handles.
  ///
  /// Prints all handles that have been added with [addOpenHandle] but haven't
  /// been removed with [removeOpenHandle].
  ///
  /// Programs should not have open handles when the program terminates.
  static bool reportOpenHandles() {
    if (_openHandles.length == 0) {
      return true;
    }
    _openHandles.forEach(_reportOpenHandle);
    return false;
  }

  /// Updates the description of the given [handleToken] in the set of open
  /// handles.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// Does nothing, if the [handleToken] isn't in the set.
  static bool setDescription(int handleToken, String description) {
    _OpenHandle openHandle = _openHandles[handleToken];
    if (openHandle != null) {
      openHandle.description = description;
    }
    return true;
  }

  /// Registers a finalizer on [eventSubscription] to close the given
  /// [handleToken].
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// When [eventSubscription] (currently an Instance of the
  /// [MojoEventSubscription] class) is garbage-collected, invokes [close] on
  /// the [handleToken].
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  /// Since the token can be an integer, it's not possible to install the
  /// finalizer directly on the token.
  static int registerFinalizer(Object eventSubscription, int handleToken)
      native "MojoHandle_RegisterFinalizer";

  /// Closes the given [handleToken].
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  static int close(int handleToken) native "MojoHandle_Close";

  /// Waits on the given [handleToken] for a signal.
  ///
  /// Returns a list of two elements. The first entry is an integer, encoding
  /// if the operation was a success or not, as specified in the [MojoResult]
  /// class. In particular, a successful operation is signaled by
  /// [MojoResult.kOk]. The second entry is itself a list of 2 elements:
  /// an integer of satisfied signals, and an integer of satisfiable signals.
  /// Both entries are encoded as specified in [MojoHandleSignals].
  ///
  /// A signal is satisfiable, if the signal may become true in the future.
  ///
  /// The [deadline] specifies how long the call should wait (if no signal is
  /// triggered). If the deadline passes, the returned result-integer is
  /// [MojoResult.kDeadlineExceeded]. If the deadline is 0, then the result
  /// is only [MojoResult.kDeadlineExceeded] if no other termination condition
  /// is already satisfied (see below).
  ///
  /// The [signals] integer encodes the signals this method should wait for.
  /// The integer is encoded as specified in [MojoHandleSignals].
  ///
  /// Waits on the given handle until one of the following happens:
  /// - A signal indicated by [signals] is satisfied.
  /// - It becomes known that no signal indicated by [signals] will ever be
  ///   satisfied (for example the handle has been closed on the other side).
  /// - The [deadline] has passed.
  static List wait(int handleToken, int signals, int deadline)
      native "MojoHandle_Wait";

  /// Waits on many handles at the same time.
  ///
  /// Returns a list with exactly 3 elements:
  /// - the result integer, encoded as specified in [MojoResult]. In particular,
  ///   [MojoResult.kOk] signals success.
  /// - the index of the handle that caused the return. May be `null` if the
  ///   operation didn't succeed.
  /// - a list of signal states. May be `null` if the operation didn't succeed.
  ///   Each signal state is represented by a list of 2 elements: an integer of
  ///   satisfied signals, and an integer of satisfiable signals (see [wait]).
  ///
  /// Behaves as if [wait] was called on each of the [handleTokens] separately,
  /// completing when the first would complete.
  static List waitMany(List<int> handleTokens, List<int> signals, int deadline)
      native "MojoHandle_WaitMany";

  // Called from the embedder's unhandled exception callback.
  // Returns the number of successfully closed handles.
  static int _closeOpenHandles() {
    int count = 0;
    _openHandles.forEach((int handle, _) {
      if (MojoHandleNatives.close(handle) == 0) {
        count++;
      }
    });
    _openHandles.clear();
    return count;
  }
}

class _MojoHandleWatcherNatives {
  static int sendControlData(
      int controlHandle,
      int commandCode,
      int handleOrDeadline,
      SendPort port,
      int data) native "MojoHandleWatcher_SendControlData";
}

class MojoMessagePipeNatives {
  /// Creates a message pipe represented by its two endpoints (handles).
  ///
  /// Returns a list with exactly 3 elements:
  /// - the result integer, encoded as specified in [MojoResult]. In particular,
  ///   [MojoResult.kOk] signals a successful creation.
  /// - the two endpoints of the message pipe. These tokens can be used in the
  ///   methods of [MojoHandleNatives].
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoMessagePipe.FLAG_NONE] (equal to 0).
  static List MojoCreateMessagePipe(int flags) native "MojoMessagePipe_Create";

  /// Writes a message into the endpoint [handleToken].
  ///
  /// Returns a result integer, encoded as specified in [MojoResult]. In
  /// particular, [MojoResult.kOk] signals a successful write.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// A message is composed of [numBytes] bytes of [data], and a list of
  /// [handleTokens].
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoMessagePipeEndpoint.WRITE_FLAG_NONE] (equal to 0).
  static int MojoWriteMessage(int handleToken, ByteData data, int numBytes,
      List<int> handles, int flags) native "MojoMessagePipe_Write";

  /// Reads a message from the endpoint [handleToken].
  ///
  /// Returns `null` if the parameters are invalid. Otherwise returns a list of
  /// exactly 3 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  /// particular, [MojoResult.kOk] signals a successful read.
  /// 2. the number of bytes read (or bytes available if the message couldn't
  ///   be read).
  /// 3. the number of handles read (or handles available if the message
  ///   couldn't be read).
  ///
  /// If no message is available, the result-integer is set to
  /// [MojoResult.kShouldWait].
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// Both [data], and [handleTokens] may be null. If [data] is null, then
  /// [numBytes] must be 0.
  ///
  /// A message is always read in its entirety. That is, if a message doesn't
  /// fit into [data] and/or [handleTokens], then the message is left in the
  /// pipe or discarded (see the description of [flags] below).
  ///
  /// If the message wasn't read because [data] or [handleTokens] was too small,
  /// the result integer is set to [MojoResult.kResourceExhausted].
  ///
  /// The returned list *always* contains the size of the message (independent
  /// if it was actually read into [data] and [handleTokens]).
  /// A common pattern thus consists of invoking this method with
  /// [data] and [handleTokens] set to `null` to query the size of the next
  /// message that is in the pipe.
  ///
  /// The parameter [flags] may set to either
  /// [MojoMessagePipeEndpoint.READ_FLAG_NONE] (equal to 0) or
  /// [MojoMessagePipeEndpoint.READ_FLAG_MAY_DISCARD] (equal to 1). In the
  /// latter case messages that couldn't be read (for example, because the
  /// [data] or [handleTokens] wasn't big enough) are discarded.
  static List MojoReadMessage(int handleToken, ByteData data, int numBytes,
      List<int> handleTokens, int flags) native "MojoMessagePipe_Read";

  /// Reads a message from the endpoint [handleToken].
  ///
  /// The result is returned in the provided list [result], which must have
  /// a length of at least 5.
  ///
  /// The elements in [result] are:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful read. This value is
  ///   only used as output.
  /// 2. the [ByteData] data array. This entry is used both as input and output.
  ///   If the array is non-null and big enough it is used to store the
  ///   byte-data of the message. Otherwise a new [ByteData] array of the
  ///   required length is allocated and stored in this slot.
  /// 3. a list, used to store handles. This entry is used both as input and
  ///   output. If the list is big enough it is filled with the read handles.
  ///   Otherwise, a new list of the required length is allocated and used
  ///   instead.
  /// 4. the size of the read byte data. Only used as output.
  /// 5. the number of read handles. Only used as output.
  ///
  /// The [handleToken] is a token that identifies the Mojo handle.
  ///
  /// The parameter [flags] may set to either
  /// [MojoMessagePipeEndpoint.READ_FLAG_NONE] (equal to 0) or
  /// [MojoMessagePipeEndpoint.READ_FLAG_MAY_DISCARD] (equal to 1). In the
  /// latter case messages that couldn't be read are discarded.
  ///
  /// Also see [MojoReadMessage].
  static void MojoQueryAndReadMessage(int handleToken, int flags, List result)
      native "MojoMessagePipe_QueryAndRead";
}

class MojoDataPipeNatives {
  /// Creates a (unidirectional) data pipe represented by its two endpoints
  /// (handles).
  ///
  /// Returns a list with exactly 3 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful creation.
  /// 2. the producer endpoint. A handle token.
  /// 3. the consumer endpoint. A handle token.
  ///
  /// The parameter [elementBytes] specifies the size of an element in bytes.
  /// All transactions and buffers consist of an integral number of elements.
  /// The integer [elementBytes] must be non-zero. The default should be
  /// [MojoDataPipe.DEFAULT_ELEMENT_SIZE] (equal to 1).
  ///
  /// The parameter [capacityBytes] specifies the capacity of the data-pipe, in
  /// bytes. The parameter must be a multiple of [elementBytes]. The data-pipe
  /// will always be able to queue *at least* this much data. If [capacityBytes]
  /// is set to zero, a system-dependent automatically-calculated capacity is
  /// used. The default should be [MojoDataPipe.DEFAULT_CAPACITY] (equal to 0).
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoDataPipe.FLAG_NONE] (equal to 0).
  static List MojoCreateDataPipe(int elementBytes, int capacityBytes, int flags)
      native "MojoDataPipe_Create";

  /// Writes [numBytes] bytes from [data] into the producer handle.
  ///
  /// Returns an integer, encoding the result as specified in the [MojoResult]
  /// class. In particular, a successful operation returns [MojoResult.kOk].
  ///
  /// The argument [handleToken] must be a producer handle created through
  /// [MojoCreateDataPipe].
  ///
  /// The argument [numBytes] should be a multiple of the data pipe's
  /// element size.
  ///
  /// The argument [flags] can be
  /// - [MojoDataPipeProducer.FLAG_NONE] (equal to 0), or
  /// - [MojoDataPipeProducer.FLAG_ALL_OR_NONE] (equal to 1).
  ///
  /// If [flags] is equal to [MojoDataPipeProducer.FLAG_ALL_OR_NONE], then
  /// either all data is written, or none is. If the data can't be written, then
  /// the result integer is set to [MojoResult.kOutOfRange].
  ///
  /// If no data can currently be written to an open consumer (and [flags] is
  /// *not* set to [MojoDataPipeProducer.FLAG_ALL_OR_NONE]), then the
  /// result-integer is set to [MojoResult.kShouldWait].
  static List MojoWriteData(int handle, ByteData data, int numBytes, int flags)
      native "MojoDataPipe_WriteData";

  /// Starts a two-phase write.
  ///
  /// Returns a List of exactly 2 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful operation.
  /// 2. a [ByteData] object (when successful), or `null` (if unsuccessful).
  ///
  /// The argument [handleToken] must be a producer handle created through
  /// [MojoCreateDataPipe].
  ///
  /// A two-phase write consists of requesting a buffer to write to (this
  /// function), followed by a call to [MojoEndWriteData] to signal that the
  /// buffer has been filled with data and is ready to write.
  ///
  /// While the system waits for the [MojoEndWriteData], the underlying
  /// data pipe is set to non-writable.
  ///
  /// A two-phase write is only started if the result integer (the first
  /// argument of the returned list) is equal to [MojoResult.kOk]. Otherwise,
  /// the underlying pipe stays writable (assuming it was before), and does not
  /// expect a call to [MojoEndWriteData].
  ///
  /// The result integer is equal to [MojoResult.kBusy] if the pipe is already
  /// executing a two-phase write.
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoDataPipeProducer.FLAG_NONE] (equal to 0).
  static List MojoBeginWriteData(int handleToken, int flags)
      native "MojoDataPipe_BeginWriteData";

  /// Finishes a two-phase write.
  ///
  /// Returns a result integer, encoded as specified in [MojoResult]. In
  /// particular, [MojoResult.kOk] signals a successful operation.
  ///
  /// The argument [handleToken] must be a producer handle created through
  /// [MojoCreateDataPipe] and must be the same that was given to a previous
  /// call to [MojoBeginWriteData].
  ///
  /// Writes [bytesWritten] bytes of the [ByteData] buffer provided by
  /// [MojoBeginWriteData] into the pipe. The parameter [bytesWritten] must be
  /// less or equal to the size of the [ByteData] buffer and must be a multiple
  /// of the data pipe's element size.
  static int MojoEndWriteData(int handleToken, int bytesWritten)
      native "MojoDataPipe_EndWriteData";

  /// Reads up to [numBytes] from the given consumer [handleToken].
  ///
  /// Returns a list of exactly two elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful operation.
  /// 2. an integer `readBytes` (having different semantics depending on the
  ///   flags. See below for the different cases.
  ///
  /// The argument [handleToken] must be a consumer handle created through
  /// [MojoCreateDataPipe].
  ///
  /// The argument [numBytes] must be a multiple of the data pipe's element
  /// size.
  ///
  /// If [flags] has neither [MojoDataPipeConsumer.FLAG_DISCARD] (equal to 2),
  /// nor [MojoDataPipeConsumer.FLAG_QUERY] (equal to 4) set, tries to read up
  /// to [numBytes] bytes of data into the [data] buffer and set
  /// `readBytes` (the second element of the returned list) to the amount
  /// actually read.
  ///
  /// If [flags] has [MojoDataPipeConsumer.FLAG_ALL_OR_NONE] (equal to 1) set,
  /// either reads exactly [numBytes] bytes of data or none. Additionally, if
  /// [flags] has [MojoDataPipeConsumer.FLAG_PEEK] (equal to 8) set, the data
  /// read remains in the pipe and is available to future reads.
  ///
  /// If [flags] has [MojoDataPipeConsumer.FLAG_DISCARD] (equal to 2) set, it
  /// discards up to [numBytes] (which again must be a multiple of the element
  /// size) bytes of  data, setting `readBytes` to the amount actually
  /// discarded. If [flags] has [MojoDataPipeConsumer.FLAG_ALL_OR_NONE] (equal
  /// to 1), either discards exactly [numBytes] bytes of data or none. In this
  /// case, [MojoDataPipeConsumer.FLAG_QUERY] must not be set, and
  /// the [data] buffer is ignored (and should typically be set to
  /// null).
  ///
  /// If flags has [MojoDataPipeConsumer.FLAG_QUERY] set, queries the amount of
  /// data available, setting `readBytes` to the number of bytes available. In
  /// this case, [MojoDataPipeConsumer.FLAG_DISCARD] must not be set, and
  /// [MojoDataPipeConsumer.FLAG_ALL_OR_NONE] is ignored, as are [data] and
  /// [numBytes].
  static List MojoReadData(int handleToken, ByteData data, int numBytes,
      int flags) native "MojoDataPipe_ReadData";

  /// Starts a two-phase read.
  ///
  /// Returns a List of exactly 2 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful operation.
  /// 2. a [ByteData] object (when successful), or `null` (if unsuccessful).
  ///
  /// The argument [handleToken] must be a consumer handle created through
  /// [MojoCreateDataPipe].
  ///
  /// A two-phase write consists of requesting a buffer to read from (this
  /// function), followed by a call to [MojoEndReadData] to signal that the
  /// buffer has been read.
  ///
  /// While the system waits for the [MojoEndReadData], the underlying
  /// data pipe is set to non-readable.
  ///
  /// A two-phase read is only started if the result integer (the first
  /// argument of the returned list) is equal to [MojoResult.kOk]. Otherwise,
  /// the underlying pipe stays readable (assuming it was before), and does not
  /// expect a call to [MojoEndReadData].
  ///
  /// The result integer is equal to [MojoResult.kBusy] if the pipe is already
  /// executing a two-phase read.
  ///
  /// The result integer is equal to [MojoResult.kShouldWait] if the pipe has
  /// no data available.
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoDataPipeConsumer.FLAG_NONE] (equal to 0).
  static List MojoBeginReadData(int handleToken, int flags)
      native "MojoDataPipe_BeginReadData";

  /// Finishes a two-phase read.
  ///
  /// Returns a result integer, encoded as specified in [MojoResult]. In
  /// particular, [MojoResult.kOk] signals a successful operation.
  ///
  /// The argument [handleToken] must be a consumer handle created through
  /// [MojoCreateDataPipe] and must be the same that was given to a previous
  /// call to [MojoBeginReadData].
  ///
  /// Consumes [bytesRead] bytes of the [ByteData] buffer provided by
  /// [MojoBeginReadData]. The parameter [bytesWritten] must be
  /// less or equal to the size of the [ByteData] buffer and must be a multiple
  /// of the data pipe's element size.
  static int MojoEndReadData(int handleToken, int bytesRead)
      native "MojoDataPipe_EndReadData";
}

class MojoSharedBufferNatives {
  /// Creates a shared buffer of [numBytes] bytes.
  ///
  /// Returns a List of exactly 2 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful operation.
  /// 2. a handle.
  ///
  /// A shared buffer can be shared between applications (by duplicating the
  /// handle -- see [Duplicate] -- and passing it over a message pipe).
  ///
  /// A shared buffer can be accessed through by invoking [Map].
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoSharedBuffer.createFlagNone] (equal to 0).
  static List Create(int numBytes, int flags) native "MojoSharedBuffer_Create";

  /// Duplicates the given [bufferHandleToken] so that it can be shared through
  /// a message pipe.
  ///
  /// Returns a list of exactly 2 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful operation.
  /// 2. the duplicated handle.
  ///
  /// The [bufferHandleToken] must be a handle created by [Create].
  ///
  /// Creates another handle (returned as second element in the returned list)
  /// which can then be sent to another application over a message pipe, while
  /// retaining access to the [bufferHandleToken] (and any mappings that it may
  /// have).
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoSharedBuffer.duplicateFlagNone] (equal to 0).
  static List Duplicate(int bufferHandleToken, int flags)
      native "MojoSharedBuffer_Duplicate";

  /// Maps the given [bufferHandleToken] so that its data can be access through
  /// a [ByteData] buffer.
  ///
  /// Returns a list of exactly 2 elements:
  /// 1. the result integer, encoded as specified in [MojoResult]. In
  ///   particular, [MojoResult.kOk] signals a successful operation.
  /// 2. a [ByteData] buffer that maps to the data in the shared buffer.
  ///
  /// The [bufferHandleToken] must be a handle created by [Create].
  ///
  /// Maps [numBytes] of data, starting at offset [offset] into a [ByteData]
  /// buffer.
  ///
  /// Note: there is no `unmap` call, since this is supposed to happen via
  /// finalizers.
  ///
  /// The parameter [flags] is reserved for future use and should currently be
  /// set to [MojoSharedBuffer.mapFlagNone] (equal to 0).
  static List Map(int bufferHandleToken, int offset, int numBytes, int flags)
      native "MojoSharedBuffer_Map";
}

// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_DISPATCHER_H_

#include <stddef.h>
#include <stdint.h>

#include <memory>
#include <ostream>
#include <vector>

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/system/entrypoint_class.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/handle_signals_state.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/ref_counted.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/c/system/buffer.h"
#include "mojo/public/c/system/data_pipe.h"
#include "mojo/public/c/system/handle.h"
#include "mojo/public/c/system/message_pipe.h"
#include "mojo/public/c/system/result.h"
#include "mojo/public/c/system/wait_set.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace platform {
class PlatformSharedBufferMapping;
}

namespace system {

class Awakable;
class Channel;
class Core;
class Dispatcher;
struct Handle;
class HandleTable;
class HandleTransport;
class LocalMessagePipeEndpoint;
class MessagePipe;
class ProxyMessagePipeEndpoint;
class TransportData;

using DispatcherVector = std::vector<util::RefPtr<Dispatcher>>;

namespace test {

// Test helper. We need to declare it here so we can friend it.
HandleTransport HandleTryStartTransport(const Handle& handle);

}  // namespace test

// A |Dispatcher| implements Mojo primitives that are "attached" to a particular
// handle. This includes most (all?) primitives except for |MojoWait...()|. This
// object is thread-safe, with its state being protected by a single mutex
// |mutex_|, which is also made available to implementation subclasses (via the
// |mutex()| method).
class Dispatcher : public util::RefCountedThreadSafe<Dispatcher> {
 public:
  // Types of dispatchers. Note that these are not necessarily a one-to-one with
  // implementations of |Dispatcher|: multiple implementations may share the
  // same type.
  enum class Type {
    UNKNOWN = 0,
    MESSAGE_PIPE,
    DATA_PIPE_PRODUCER,
    DATA_PIPE_CONSUMER,
    SHARED_BUFFER,
    WAIT_SET,

    // "Private" types (not exposed via the public interface):
    PLATFORM_HANDLE = -1
  };

  // Gets the type of the dispatcher; see |Type| above.
  virtual Type GetType() const = 0;

  // Gets whether the given entrypoint class is supported; see the definition of
  // |EntrypointClass|. This is ONLY called when a rights check has failed, to
  // determine whether |MOJO_RESULT_PERMISSION_DENIED| (if the entrypoint class
  // is supported) or |MOJO_RESULT_INVALID_ARGUMENT| (if not) should be
  // returned. In the case that the rights check passes, |Core| will proceed
  // immediately to call the method (so if the method is not supported, it must
  // still return |MOJO_RESULT_INVALID_ARGUMENT|).
  virtual bool SupportsEntrypointClass(
      EntrypointClass entrypoint_class) const = 0;

  // These methods implement the various primitives named |Mojo...()|. These
  // take |mutex_| and handle races with |Close()|. Then they call out to
  // subclasses' |...ImplNoLock()| methods (still under |mutex_|), which
  // actually implement the primitives.
  // NOTE(vtl): This puts a big lock around each dispatcher (i.e., handle), and
  // prevents the various |...ImplNoLock()|s from releasing the lock as soon as
  // possible. If this becomes an issue, we can rethink this.

  // No |EntrypointClass|:
  // All dispatchers must support this.
  MojoResult Close();
  // This actually supports |MojoDuplicateHandle[WithReducedRights]()|; rights
  // are handled by |Core|.
  MojoResult DuplicateDispatcher(util::RefPtr<Dispatcher>* new_dispatcher);

  // |EntrypointClass::MESSAGE_PIPE|:
  // |transports| may be non-null if and only if there are handles to be
  // written; not that |this| must not be in |transports|. On success, all the
  // dispatchers in |transports| must have been moved to a closed state; on
  // failure, they should remain in their original state.
  MojoResult WriteMessage(UserPointer<const void> bytes,
                          uint32_t num_bytes,
                          std::vector<HandleTransport>* transports,
                          MojoWriteMessageFlags flags);
  // |handles| must be non-null but empty if |num_handles| is non-null and
  // nonzero. On success, it will be set to the handles to be received (and
  // assigned handle values) as part of the message.
  MojoResult ReadMessage(UserPointer<void> bytes,
                         UserPointer<uint32_t> num_bytes,
                         HandleVector* handles,
                         uint32_t* num_handles,
                         MojoReadMessageFlags flags);

  // |EntrypointClass::DATA_PIPE_PRODUCER|:
  MojoResult SetDataPipeProducerOptions(
      UserPointer<const MojoDataPipeProducerOptions> options);
  MojoResult GetDataPipeProducerOptions(
      UserPointer<MojoDataPipeProducerOptions> options,
      uint32_t options_num_bytes);
  MojoResult WriteData(UserPointer<const void> elements,
                       UserPointer<uint32_t> elements_num_bytes,
                       MojoWriteDataFlags flags);
  MojoResult BeginWriteData(UserPointer<void*> buffer,
                            UserPointer<uint32_t> buffer_num_bytes,
                            MojoWriteDataFlags flags);
  MojoResult EndWriteData(uint32_t num_bytes_written);

  // |EntrypointClass::DATA_PIPE_CONSUMER|:
  MojoResult SetDataPipeConsumerOptions(
      UserPointer<const MojoDataPipeConsumerOptions> options);
  MojoResult GetDataPipeConsumerOptions(
      UserPointer<MojoDataPipeConsumerOptions> options,
      uint32_t options_num_bytes);
  MojoResult ReadData(UserPointer<void> elements,
                      UserPointer<uint32_t> num_bytes,
                      MojoReadDataFlags flags);
  MojoResult BeginReadData(UserPointer<const void*> buffer,
                           UserPointer<uint32_t> buffer_num_bytes,
                           MojoReadDataFlags flags);
  MojoResult EndReadData(uint32_t num_bytes_read);

  // |EntrypointClass::BUFFER|:
  // |options| may be null. |new_dispatcher| must not be null, but
  // |*new_dispatcher| should be null (and will contain the dispatcher for the
  // new handle on success).
  MojoResult DuplicateBufferHandle(
      UserPointer<const MojoDuplicateBufferHandleOptions> options,
      util::RefPtr<Dispatcher>* new_dispatcher);
  MojoResult GetBufferInformation(UserPointer<MojoBufferInformation> info,
                                  uint32_t info_num_bytes);
  MojoResult MapBuffer(
      uint64_t offset,
      uint64_t num_bytes,
      MojoMapBufferFlags flags,
      std::unique_ptr<platform::PlatformSharedBufferMapping>* mapping);

  // |EntrypointClass::WAIT_SET|:
  MojoResult WaitSetAdd(UserPointer<const MojoWaitSetAddOptions> options,
                        Handle&& handle,
                        MojoHandleSignals signals,
                        uint64_t cookie);
  MojoResult WaitSetRemove(uint64_t cookie);
  // Note: This will likely block the calling thread (so, e.g., no mutexes
  // should be held when it's called).
  MojoResult WaitSetWait(MojoDeadline deadline,
                         UserPointer<uint32_t> num_results,
                         UserPointer<MojoWaitSetResult> results,
                         UserPointer<uint32_t> max_results);

  // Gets the current handle signals state. (The default implementation simply
  // returns a default-constructed |HandleSignalsState|, i.e., no signals
  // satisfied or satisfiable.) Note: The state is subject to change from other
  // threads.
  HandleSignalsState GetHandleSignalsState() const;

  // Adds an awakable to this dispatcher, which will be woken up when this
  // object changes state to satisfy |signals| with context |context|. It will
  // also be woken up when it becomes impossible for the object to ever satisfy
  // |signals| with a suitable error status.
  //
  // If |signals_state| is non-null, on *failure* |*signals_state| will be set
  // to the current handle signals state (on success, it is left untouched).
  //
  // Returns:
  //  - |MOJO_RESULT_OK| if the awakable was added;
  //  - |MOJO_RESULT_ALREADY_EXISTS| if |signals| is already satisfied (if
  //    |force| is true, the awakable will still be added);
  //  - |MOJO_RESULT_INVALID_ARGUMENT| if the dispatcher has been closed; and
  //  - |MOJO_RESULT_FAILED_PRECONDITION| if it is not (or no longer) possible
  //    that |signals| will ever be satisfied.
  MojoResult AddAwakable(Awakable* awakable,
                         MojoHandleSignals signals,
                         uint64_t context,
                         HandleSignalsState* signals_state);
  // Like |AddAwakable()|, but in the |MOJO_RESULT_ALREADY_EXISTS| case still
  // adds the awakable (|MOJO_RESULT_ALREADY_EXISTS| will still be returned and
  // |*signals_state| will still be set if |signals_state| is non-null).
  MojoResult AddAwakableUnconditional(Awakable* awakable,
                                      MojoHandleSignals signals,
                                      uint64_t context,
                                      HandleSignalsState* signals_state);
  // Removes an awakable from this dispatcher. (It is valid to call this
  // multiple times for the same |awakable| on the same object, so long as
  // |AddAwakable()| was called at most once.) If |signals_state| is non-null,
  // |*signals_state| will be set to the current handle signals state.
  void RemoveAwakable(Awakable* awakable, HandleSignalsState* signals_state);

  // A dispatcher must be put into a special state in order to be sent across a
  // message pipe. Outside of tests, only |HandleTableAccess| is allowed to do
  // this, since there are requirements on the handle table (see below).
  //
  // In this special state, only a restricted set of operations is allowed.
  // These are the ones available as |HandleTransport| methods. Other
  // |Dispatcher| methods must not be called until |HandleTransport::End()| has
  // been called.
  class HandleTableAccess {
   private:
    friend class Core;
    friend class HandleTable;
    // Tests also need this, to avoid needing |Core|.
    friend HandleTransport test::HandleTryStartTransport(const Handle&);

    // This must be called under the handle table lock and only if the handle
    // table entry is not marked busy. The caller must maintain a reference to
    // |dispatcher| until |HandleTransport::End()| is called.
    static HandleTransport TryStartTransport(const Handle& handle);
  };

  // A |TransportData| may serialize dispatchers that are given to it (and which
  // were previously attached to the |MessageInTransit| that is creating it) to
  // a given |Channel| and then (probably in a different process) deserialize.
  // Note that the |MessageInTransit| "owns" (i.e., has the only ref to) these
  // dispatchers, so there are no locking issues. (There's no lock ordering
  // issue, and in fact no need to take dispatcher locks at all.)
  // TODO(vtl): Consider making another wrapper similar to |HandleTransport|
  // (but with an owning, unique reference), and having
  // |CreateEquivalentDispatcherAndCloseImplNoLock()| return that wrapper (and
  // |MessageInTransit|, etc. only holding on to such wrappers).
  class TransportDataAccess {
   private:
    friend class TransportData;

    // Serialization API. These functions may only be called on such
    // dispatchers. (|channel| is the |Channel| to which the dispatcher is to be
    // serialized.) See the |Dispatcher| methods of the same names for more
    // details.
    static void StartSerialize(Dispatcher* dispatcher,
                               Channel* channel,
                               size_t* max_size,
                               size_t* max_platform_handles);
    static bool EndSerializeAndClose(
        Dispatcher* dispatcher,
        Channel* channel,
        void* destination,
        size_t* actual_size,
        std::vector<platform::ScopedPlatformHandle>* platform_handles);

    // Deserialization API.
    // Note: This "clears" (i.e., reset to the invalid handle) any platform
    // handles that it takes ownership of.
    static util::RefPtr<Dispatcher> Deserialize(
        Channel* channel,
        int32_t type,
        const void* source,
        size_t size,
        std::vector<platform::ScopedPlatformHandle>* platform_handles);
  };

 protected:
  Dispatcher();
  virtual ~Dispatcher();

  // These are to be overridden by subclasses (if necessary). They are called
  // exactly once (first |CancelAllStateNoLock()|, then |CloseImplNoLock()|)
  // when the dispatcher is being closed. |CancelAllStateNoLock()| should cancel
  // (or reset) all stateful "operations", including cancelling all awakables.
  virtual void CancelAllStateNoLock() MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual void CloseImplNoLock() MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  //  All dispatcher types whose handles may ever have the
  // |MOJO_HANDLE_RIGHT_DUPLICATE| right must override this.
  virtual MojoResult DuplicateDispatcherImplNoLock(
      util::RefPtr<Dispatcher>* new_dispatcher)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  // This is called by |CreateEquivalentDispatcherAndCloseNoLock()|. It should
  // "close" this dispatcher and return a new one equivalent to it. Note:
  // Probably the first thing an implementation should do is call
  // |CancelAllStateNoLock()| (or equivalent); unlike |CloseNoLock()|,
  // |CreateEquivalentDispatcherAndCloseNoLock()| does not do this
  // automatically.
  //
  // If the new dispatcher will be enqueued on a message pipe, then
  // |message_pipe|/|port| will be provided (since there may be some
  // special-casing necessary due to locking considerations); otherwise,
  // |message_pipe| will be null (and |port| will be meaningless).
  virtual util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* message_pipe,
      unsigned port) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_) = 0;

  // These are to be overridden by subclasses (if necessary). They are never
  // called after the dispatcher has been closed. See the descriptions of the
  // methods without the "ImplNoLock" for more information.
  virtual MojoResult WriteMessageImplNoLock(
      UserPointer<const void> bytes,
      uint32_t num_bytes,
      std::vector<HandleTransport>* transports,
      MojoWriteMessageFlags flags) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult ReadMessageImplNoLock(UserPointer<void> bytes,
                                           UserPointer<uint32_t> num_bytes,
                                           HandleVector* handles,
                                           uint32_t* num_handles,
                                           MojoReadMessageFlags flags)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult SetDataPipeProducerOptionsImplNoLock(
      UserPointer<const MojoDataPipeProducerOptions> options)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult GetDataPipeProducerOptionsImplNoLock(
      UserPointer<MojoDataPipeProducerOptions> options,
      uint32_t options_num_bytes) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult WriteDataImplNoLock(UserPointer<const void> elements,
                                         UserPointer<uint32_t> num_bytes,
                                         MojoWriteDataFlags flags)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult BeginWriteDataImplNoLock(
      UserPointer<void*> buffer,
      UserPointer<uint32_t> buffer_num_bytes,
      MojoWriteDataFlags flags) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult EndWriteDataImplNoLock(uint32_t num_bytes_written)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult SetDataPipeConsumerOptionsImplNoLock(
      UserPointer<const MojoDataPipeConsumerOptions> options)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult GetDataPipeConsumerOptionsImplNoLock(
      UserPointer<MojoDataPipeConsumerOptions> options,
      uint32_t options_num_bytes) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult ReadDataImplNoLock(UserPointer<void> elements,
                                        UserPointer<uint32_t> num_bytes,
                                        MojoReadDataFlags flags)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult BeginReadDataImplNoLock(
      UserPointer<const void*> buffer,
      UserPointer<uint32_t> buffer_num_bytes,
      MojoReadDataFlags flags) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult EndReadDataImplNoLock(uint32_t num_bytes_read)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult DuplicateBufferHandleImplNoLock(
      UserPointer<const MojoDuplicateBufferHandleOptions> options,
      util::RefPtr<Dispatcher>* new_dispatcher)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult GetBufferInformationImplNoLock(
      UserPointer<MojoBufferInformation> info,
      uint32_t info_num_bytes) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual MojoResult MapBufferImplNoLock(
      uint64_t offset,
      uint64_t num_bytes,
      MojoMapBufferFlags flags,
      std::unique_ptr<platform::PlatformSharedBufferMapping>* mapping)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  // WARNING: Unlike the others, the following wait set methods are *not* called
  // under |mutex_| and |is_closed_| is *not* checked. Thus any override must
  // lock |mutex()| and check |is_closed_no_lock()| (returning
  // |MOJO_RESULT_INVALID_ARGUMENT| if it is true).
  virtual MojoResult WaitSetAddImpl(
      UserPointer<const MojoWaitSetAddOptions> options,
      Handle&& handle,
      MojoHandleSignals signals,
      uint64_t cookie);
  virtual MojoResult WaitSetRemoveImpl(uint64_t cookie);
  virtual MojoResult WaitSetWaitImpl(MojoDeadline deadline,
                                     UserPointer<uint32_t> num_results,
                                     UserPointer<MojoWaitSetResult> results,
                                     UserPointer<uint32_t> max_results);
  virtual HandleSignalsState GetHandleSignalsStateImplNoLock() const
      MOJO_SHARED_LOCKS_REQUIRED(mutex_);
  virtual MojoResult AddAwakableImplNoLock(Awakable* awakable,
                                           MojoHandleSignals signals,
                                           bool force,
                                           uint64_t context,
                                           HandleSignalsState* signals_state)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);
  virtual void RemoveAwakableImplNoLock(Awakable* awakable,
                                        HandleSignalsState* signals_state)
      MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  // These implement the API used to serialize dispatchers to a |Channel|
  // (described below). They will only be called on a dispatcher that's attached
  // to and "owned" by a |MessageInTransit|. See the non-"impl" versions for
  // more information.
  //
  // Note: |StartSerializeImplNoLock()| is actually called with |mutex_| NOT
  // held, since the dispatcher should only be accessible to the calling thread.
  // On Debug builds, |EndSerializeAndCloseImplNoLock()| is called with |mutex_|
  // held, to satisfy any |mutex_.AssertHeld()| (e.g., in |CloseImplNoLock()| --
  // and anything it calls); disentangling those assertions is
  // difficult/fragile, and would weaken our general checking of invariants.
  //
  // TODO(vtl): Consider making these pure virtual once most things support
  // being passed over a message pipe.
  virtual void StartSerializeImplNoLock(Channel* channel,
                                        size_t* max_size,
                                        size_t* max_platform_handles)
      MOJO_NOT_THREAD_SAFE;
  virtual bool EndSerializeAndCloseImplNoLock(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      std::vector<platform::ScopedPlatformHandle>* platform_handles)
      MOJO_NOT_THREAD_SAFE;

  util::Mutex& mutex() const MOJO_LOCK_RETURNED(mutex_) { return mutex_; }

  bool is_closed_no_lock() const MOJO_SHARED_LOCKS_REQUIRED(mutex_) {
    return is_closed_;
  }

 private:
  FRIEND_REF_COUNTED_THREAD_SAFE(Dispatcher);
  friend class HandleTransport;

  // Closes the dispatcher. This must be done under lock, and unlike |Close()|,
  // the dispatcher must not be closed already. (This is the "equivalent" of
  // |CreateEquivalentDispatcherAndCloseNoLock()|, for situations where the
  // dispatcher must be disposed of instead of "transferred".)
  void CloseNoLock() MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  // Creates an equivalent dispatcher -- representing the same resource as this
  // dispatcher -- and close (i.e., disable) this dispatcher. I.e., this
  // dispatcher will look as though it was closed, but the resource it
  // represents will be assigned to the new dispatcher. This must be called
  // under the dispatcher's lock. If the resulting dispatcher will be put into a
  // message on a message pipe, then |message_pipe| will be set appropriately
  // (otherwise, it may be null) and |port| will be set to the destination port.
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseNoLock(
      MessagePipe* message_pipe,
      unsigned port) MOJO_EXCLUSIVE_LOCKS_REQUIRED(mutex_);

  // API to serialize dispatchers to a |Channel|, exposed to only
  // |TransportData| (via |TransportData|). They may only be called on a
  // dispatcher attached to a |MessageInTransit| (and in particular not in
  // |CoreImpl|'s handle table).
  //
  // TODO(vtl): The serialization API (and related implementation methods,
  // including |HandleTransport|'s methods) is marked |MOJO_NOT_THREAD_SAFE|.
  // This is because the threading requirements are somewhat complicated (e.g.,
  // |HandleTableAccess::TryStartTransport()| is really a try-lock function,
  // amongst other things). We could/should do a more careful job annotating
  // these methods. https://github.com/domokit/mojo/issues/322
  //
  // Starts the serialization. Returns (via the two "out" parameters) the
  // maximum amount of space that may be needed to serialize this dispatcher to
  // the given |Channel| (no more than
  // |TransportData::kMaxSerializedDispatcherSize|) and the maximum number of
  // |PlatformHandle|s that may need to be attached (no more than
  // |TransportData::kMaxSerializedDispatcherPlatformHandles|). If this
  // dispatcher cannot be serialized to the given |Channel|, |*max_size| and
  // |*max_platform_handles| should be set to zero. A call to this method will
  // ALWAYS be followed by a call to |EndSerializeAndClose()| (even if this
  // dispatcher cannot be serialized to the given |Channel|).
  void StartSerialize(Channel* channel,
                      size_t* max_size,
                      size_t* max_platform_handles) MOJO_NOT_THREAD_SAFE;
  // Completes the serialization of this dispatcher to the given |Channel| and
  // closes it. (This call will always follow an earlier call to
  // |StartSerialize()|, with the same |Channel|.) This does so by writing to
  // |destination| and appending any |PlatformHandle|s needed to
  // |platform_handles| (which may be null if no platform handles were indicated
  // to be required to |StartSerialize()|). This may write no more than the
  // amount indicated by |StartSerialize()|. (WARNING: Beware of races, e.g., if
  // something can be mutated between the two calls!) Returns true on success,
  // in which case |*actual_size| is set to the amount it actually wrote to
  // |destination|. On failure, |*actual_size| should not be modified; however,
  // the dispatcher will still be closed.
  bool EndSerializeAndClose(Channel* channel,
                            void* destination,
                            size_t* actual_size,
                            std::vector<platform::ScopedPlatformHandle>*
                                platform_handles) MOJO_NOT_THREAD_SAFE;

  // This protects the following members as well as any state added by
  // subclasses.
  mutable util::Mutex mutex_;
  bool is_closed_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(Dispatcher);
};

// So logging macros and |DCHECK_EQ()|, etc. work.
inline std::ostream& operator<<(std::ostream& out, Dispatcher::Type type) {
  return out << static_cast<int>(type);
}

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_DISPATCHER_H_

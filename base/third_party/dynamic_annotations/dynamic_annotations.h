/* Copyright (c) 2011, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/* This file defines dynamic annotations for use with dynamic analysis
   tool such as valgrind, PIN, etc.

   Dynamic annotation is a source code annotation that affects
   the generated code (that is, the annotation is not a comment).
   Each such annotation is attached to a particular
   instruction and/or to a particular object (address) in the program.

   The annotations that should be used by users are macros in all upper-case
   (e.g., ANNOTATE_NEW_MEMORY).

   Actual implementation of these macros may differ depending on the
   dynamic analysis tool being used.

   See http://code.google.com/p/data-race-test/  for more information.

   This file supports the following dynamic analysis tools:
   - None (DYNAMIC_ANNOTATIONS_ENABLED is not defined or zero).
      Macros are defined empty.
   - ThreadSanitizer, Helgrind, DRD (DYNAMIC_ANNOTATIONS_ENABLED is 1).
      Macros are defined as calls to non-inlinable empty functions
      that are intercepted by Valgrind. */

#ifndef __DYNAMIC_ANNOTATIONS_H__
#define __DYNAMIC_ANNOTATIONS_H__

#ifndef DYNAMIC_ANNOTATIONS_PREFIX
# define DYNAMIC_ANNOTATIONS_PREFIX
#endif

#ifndef DYNAMIC_ANNOTATIONS_PROVIDE_RUNNING_ON_VALGRIND
# define DYNAMIC_ANNOTATIONS_PROVIDE_RUNNING_ON_VALGRIND 1
#endif

#ifdef DYNAMIC_ANNOTATIONS_WANT_ATTRIBUTE_WEAK
# ifdef __GNUC__
#  define DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK __attribute__((weak))
# else
/* TODO(glider): for Windows support we may want to change this macro in order
   to prepend __declspec(selectany) to the annotations' declarations. */
#  error weak annotations are not supported for your compiler
# endif
#else
# define DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK
#endif

/* The following preprocessor magic prepends the value of
   DYNAMIC_ANNOTATIONS_PREFIX to annotation function names. */
#define DYNAMIC_ANNOTATIONS_GLUE0(A, B) A##B
#define DYNAMIC_ANNOTATIONS_GLUE(A, B) DYNAMIC_ANNOTATIONS_GLUE0(A, B)
#define DYNAMIC_ANNOTATIONS_NAME(name) \
  DYNAMIC_ANNOTATIONS_GLUE(DYNAMIC_ANNOTATIONS_PREFIX, name)

#ifndef DYNAMIC_ANNOTATIONS_ENABLED
# define DYNAMIC_ANNOTATIONS_ENABLED 0
#endif

#if DYNAMIC_ANNOTATIONS_ENABLED != 0

  /* -------------------------------------------------------------
     Annotations useful when implementing condition variables such as CondVar,
     using conditional critical sections (Await/LockWhen) and when constructing
     user-defined synchronization mechanisms.

     The annotations ANNOTATE_HAPPENS_BEFORE() and ANNOTATE_HAPPENS_AFTER() can
     be used to define happens-before arcs in user-defined synchronization
     mechanisms:  the race detector will infer an arc from the former to the
     latter when they share the same argument pointer.

     Example 1 (reference counting):

     void Unref() {
       ANNOTATE_HAPPENS_BEFORE(&refcount_);
       if (AtomicDecrementByOne(&refcount_) == 0) {
         ANNOTATE_HAPPENS_AFTER(&refcount_);
         delete this;
       }
     }

     Example 2 (message queue):

     void MyQueue::Put(Type *e) {
       MutexLock lock(&mu_);
       ANNOTATE_HAPPENS_BEFORE(e);
       PutElementIntoMyQueue(e);
     }

     Type *MyQueue::Get() {
       MutexLock lock(&mu_);
       Type *e = GetElementFromMyQueue();
       ANNOTATE_HAPPENS_AFTER(e);
       return e;
     }

     Note: when possible, please use the existing reference counting and message
     queue implementations instead of inventing new ones. */

  /* Report that wait on the condition variable at address "cv" has succeeded
     and the lock at address "lock" is held. */
  #define ANNOTATE_CONDVAR_LOCK_WAIT(cv, lock) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarWait)(__FILE__, __LINE__, cv, lock)

  /* Report that wait on the condition variable at "cv" has succeeded.  Variant
     w/o lock. */
  #define ANNOTATE_CONDVAR_WAIT(cv) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarWait)(__FILE__, __LINE__, cv, NULL)

  /* Report that we are about to signal on the condition variable at address
     "cv". */
  #define ANNOTATE_CONDVAR_SIGNAL(cv) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarSignal)(__FILE__, __LINE__, cv)

  /* Report that we are about to signal_all on the condition variable at address
     "cv". */
  #define ANNOTATE_CONDVAR_SIGNAL_ALL(cv) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarSignalAll)(__FILE__, __LINE__, cv)

  /* Annotations for user-defined synchronization mechanisms. */
  #define ANNOTATE_HAPPENS_BEFORE(obj) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateHappensBefore)(__FILE__, __LINE__, obj)
  #define ANNOTATE_HAPPENS_AFTER(obj) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateHappensAfter)(__FILE__, __LINE__, obj)

  /* DEPRECATED. Don't use it. */
  #define ANNOTATE_PUBLISH_MEMORY_RANGE(pointer, size) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotatePublishMemoryRange)(__FILE__, __LINE__, \
        pointer, size)

  /* DEPRECATED. Don't use it. */
  #define ANNOTATE_UNPUBLISH_MEMORY_RANGE(pointer, size) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateUnpublishMemoryRange)(__FILE__, __LINE__, \
        pointer, size)

  /* DEPRECATED. Don't use it. */
  #define ANNOTATE_SWAP_MEMORY_RANGE(pointer, size)   \
    do {                                              \
      ANNOTATE_UNPUBLISH_MEMORY_RANGE(pointer, size); \
      ANNOTATE_PUBLISH_MEMORY_RANGE(pointer, size);   \
    } while (0)

  /* Instruct the tool to create a happens-before arc between mu->Unlock() and
     mu->Lock(). This annotation may slow down the race detector and hide real
     races. Normally it is used only when it would be difficult to annotate each
     of the mutex's critical sections individually using the annotations above.
     This annotation makes sense only for hybrid race detectors. For pure
     happens-before detectors this is a no-op. For more details see
     http://code.google.com/p/data-race-test/wiki/PureHappensBeforeVsHybrid . */
  #define ANNOTATE_PURE_HAPPENS_BEFORE_MUTEX(mu) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsUsedAsCondVar)(__FILE__, __LINE__, \
        mu)

  /* Opposite to ANNOTATE_PURE_HAPPENS_BEFORE_MUTEX.
     Instruct the tool to NOT create h-b arcs between Unlock and Lock, even in
     pure happens-before mode. For a hybrid mode this is a no-op. */
  #define ANNOTATE_NOT_HAPPENS_BEFORE_MUTEX(mu) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsNotPHB)(__FILE__, __LINE__, mu)

  /* Deprecated. Use ANNOTATE_PURE_HAPPENS_BEFORE_MUTEX. */
  #define ANNOTATE_MUTEX_IS_USED_AS_CONDVAR(mu) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsUsedAsCondVar)(__FILE__, __LINE__, \
        mu)

  /* -------------------------------------------------------------
     Annotations useful when defining memory allocators, or when memory that
     was protected in one way starts to be protected in another. */

  /* Report that a new memory at "address" of size "size" has been allocated.
     This might be used when the memory has been retrieved from a free list and
     is about to be reused, or when a the locking discipline for a variable
     changes. */
  #define ANNOTATE_NEW_MEMORY(address, size) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateNewMemory)(__FILE__, __LINE__, address, \
        size)

  /* -------------------------------------------------------------
     Annotations useful when defining FIFO queues that transfer data between
     threads. */

  /* Report that the producer-consumer queue (such as ProducerConsumerQueue) at
     address "pcq" has been created.  The ANNOTATE_PCQ_* annotations
     should be used only for FIFO queues.  For non-FIFO queues use
     ANNOTATE_HAPPENS_BEFORE (for put) and ANNOTATE_HAPPENS_AFTER (for get). */
  #define ANNOTATE_PCQ_CREATE(pcq) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQCreate)(__FILE__, __LINE__, pcq)

  /* Report that the queue at address "pcq" is about to be destroyed. */
  #define ANNOTATE_PCQ_DESTROY(pcq) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQDestroy)(__FILE__, __LINE__, pcq)

  /* Report that we are about to put an element into a FIFO queue at address
     "pcq". */
  #define ANNOTATE_PCQ_PUT(pcq) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQPut)(__FILE__, __LINE__, pcq)

  /* Report that we've just got an element from a FIFO queue at address
     "pcq". */
  #define ANNOTATE_PCQ_GET(pcq) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQGet)(__FILE__, __LINE__, pcq)

  /* -------------------------------------------------------------
     Annotations that suppress errors.  It is usually better to express the
     program's synchronization using the other annotations, but these can
     be used when all else fails. */

  /* Report that we may have a benign race at "pointer", with size
     "sizeof(*(pointer))". "pointer" must be a non-void* pointer.  Insert at the
     point where "pointer" has been allocated, preferably close to the point
     where the race happens.  See also ANNOTATE_BENIGN_RACE_STATIC. */
  #define ANNOTATE_BENIGN_RACE(pointer, description) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateBenignRaceSized)(__FILE__, __LINE__, \
        pointer, sizeof(*(pointer)), description)

  /* Same as ANNOTATE_BENIGN_RACE(address, description), but applies to
     the memory range [address, address+size). */
  #define ANNOTATE_BENIGN_RACE_SIZED(address, size, description) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateBenignRaceSized)(__FILE__, __LINE__, \
        address, size, description)

  /* Request the analysis tool to ignore all reads in the current thread
     until ANNOTATE_IGNORE_READS_END is called.
     Useful to ignore intentional racey reads, while still checking
     other reads and all writes.
     See also ANNOTATE_UNPROTECTED_READ. */
  #define ANNOTATE_IGNORE_READS_BEGIN() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreReadsBegin)(__FILE__, __LINE__)

  /* Stop ignoring reads. */
  #define ANNOTATE_IGNORE_READS_END() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreReadsEnd)(__FILE__, __LINE__)

  /* Similar to ANNOTATE_IGNORE_READS_BEGIN, but ignore writes. */
  #define ANNOTATE_IGNORE_WRITES_BEGIN() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreWritesBegin)(__FILE__, __LINE__)

  /* Stop ignoring writes. */
  #define ANNOTATE_IGNORE_WRITES_END() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreWritesEnd)(__FILE__, __LINE__)

  /* Start ignoring all memory accesses (reads and writes). */
  #define ANNOTATE_IGNORE_READS_AND_WRITES_BEGIN() \
    do {\
      ANNOTATE_IGNORE_READS_BEGIN();\
      ANNOTATE_IGNORE_WRITES_BEGIN();\
    }while(0)\

  /* Stop ignoring all memory accesses. */
  #define ANNOTATE_IGNORE_READS_AND_WRITES_END() \
    do {\
      ANNOTATE_IGNORE_WRITES_END();\
      ANNOTATE_IGNORE_READS_END();\
    }while(0)\

  /* Similar to ANNOTATE_IGNORE_READS_BEGIN, but ignore synchronization events:
     RWLOCK* and CONDVAR*. */
  #define ANNOTATE_IGNORE_SYNC_BEGIN() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreSyncBegin)(__FILE__, __LINE__)

  /* Stop ignoring sync events. */
  #define ANNOTATE_IGNORE_SYNC_END() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreSyncEnd)(__FILE__, __LINE__)


  /* Enable (enable!=0) or disable (enable==0) race detection for all threads.
     This annotation could be useful if you want to skip expensive race analysis
     during some period of program execution, e.g. during initialization. */
  #define ANNOTATE_ENABLE_RACE_DETECTION(enable) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateEnableRaceDetection)(__FILE__, __LINE__, \
        enable)

  /* -------------------------------------------------------------
     Annotations useful for debugging. */

  /* Request to trace every access to "address". */
  #define ANNOTATE_TRACE_MEMORY(address) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateTraceMemory)(__FILE__, __LINE__, address)

  /* Report the current thread name to a race detector. */
  #define ANNOTATE_THREAD_NAME(name) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateThreadName)(__FILE__, __LINE__, name)

  /* -------------------------------------------------------------
     Annotations useful when implementing locks.  They are not
     normally needed by modules that merely use locks.
     The "lock" argument is a pointer to the lock object. */

  /* Report that a lock has been created at address "lock". */
  #define ANNOTATE_RWLOCK_CREATE(lock) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockCreate)(__FILE__, __LINE__, lock)

  /* Report that the lock at address "lock" is about to be destroyed. */
  #define ANNOTATE_RWLOCK_DESTROY(lock) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockDestroy)(__FILE__, __LINE__, lock)

  /* Report that the lock at address "lock" has been acquired.
     is_w=1 for writer lock, is_w=0 for reader lock. */
  #define ANNOTATE_RWLOCK_ACQUIRED(lock, is_w) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockAcquired)(__FILE__, __LINE__, lock, \
        is_w)

  /* Report that the lock at address "lock" is about to be released. */
  #define ANNOTATE_RWLOCK_RELEASED(lock, is_w) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockReleased)(__FILE__, __LINE__, lock, \
        is_w)

  /* -------------------------------------------------------------
     Annotations useful when implementing barriers.  They are not
     normally needed by modules that merely use barriers.
     The "barrier" argument is a pointer to the barrier object. */

  /* Report that the "barrier" has been initialized with initial "count".
   If 'reinitialization_allowed' is true, initialization is allowed to happen
   multiple times w/o calling barrier_destroy() */
  #define ANNOTATE_BARRIER_INIT(barrier, count, reinitialization_allowed) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierInit)(__FILE__, __LINE__, barrier, \
        count, reinitialization_allowed)

  /* Report that we are about to enter barrier_wait("barrier"). */
  #define ANNOTATE_BARRIER_WAIT_BEFORE(barrier) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierWaitBefore)(__FILE__, __LINE__, \
        barrier)

  /* Report that we just exited barrier_wait("barrier"). */
  #define ANNOTATE_BARRIER_WAIT_AFTER(barrier) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierWaitAfter)(__FILE__, __LINE__, \
        barrier)

  /* Report that the "barrier" has been destroyed. */
  #define ANNOTATE_BARRIER_DESTROY(barrier) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierDestroy)(__FILE__, __LINE__, \
        barrier)

  /* -------------------------------------------------------------
     Annotations useful for testing race detectors. */

  /* Report that we expect a race on the variable at "address".
     Use only in unit tests for a race detector. */
  #define ANNOTATE_EXPECT_RACE(address, description) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateExpectRace)(__FILE__, __LINE__, address, \
        description)

  #define ANNOTATE_FLUSH_EXPECTED_RACES() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateFlushExpectedRaces)(__FILE__, __LINE__)

  /* A no-op. Insert where you like to test the interceptors. */
  #define ANNOTATE_NO_OP(arg) \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateNoOp)(__FILE__, __LINE__, arg)

  /* Force the race detector to flush its state. The actual effect depends on
   * the implementation of the detector. */
  #define ANNOTATE_FLUSH_STATE() \
    DYNAMIC_ANNOTATIONS_NAME(AnnotateFlushState)(__FILE__, __LINE__)


#else  /* DYNAMIC_ANNOTATIONS_ENABLED == 0 */

  #define ANNOTATE_RWLOCK_CREATE(lock) /* empty */
  #define ANNOTATE_RWLOCK_DESTROY(lock) /* empty */
  #define ANNOTATE_RWLOCK_ACQUIRED(lock, is_w) /* empty */
  #define ANNOTATE_RWLOCK_RELEASED(lock, is_w) /* empty */
  #define ANNOTATE_BARRIER_INIT(barrier, count, reinitialization_allowed) /* */
  #define ANNOTATE_BARRIER_WAIT_BEFORE(barrier) /* empty */
  #define ANNOTATE_BARRIER_WAIT_AFTER(barrier) /* empty */
  #define ANNOTATE_BARRIER_DESTROY(barrier) /* empty */
  #define ANNOTATE_CONDVAR_LOCK_WAIT(cv, lock) /* empty */
  #define ANNOTATE_CONDVAR_WAIT(cv) /* empty */
  #define ANNOTATE_CONDVAR_SIGNAL(cv) /* empty */
  #define ANNOTATE_CONDVAR_SIGNAL_ALL(cv) /* empty */
  #define ANNOTATE_HAPPENS_BEFORE(obj) /* empty */
  #define ANNOTATE_HAPPENS_AFTER(obj) /* empty */
  #define ANNOTATE_PUBLISH_MEMORY_RANGE(address, size) /* empty */
  #define ANNOTATE_UNPUBLISH_MEMORY_RANGE(address, size)  /* empty */
  #define ANNOTATE_SWAP_MEMORY_RANGE(address, size)  /* empty */
  #define ANNOTATE_PCQ_CREATE(pcq) /* empty */
  #define ANNOTATE_PCQ_DESTROY(pcq) /* empty */
  #define ANNOTATE_PCQ_PUT(pcq) /* empty */
  #define ANNOTATE_PCQ_GET(pcq) /* empty */
  #define ANNOTATE_NEW_MEMORY(address, size) /* empty */
  #define ANNOTATE_EXPECT_RACE(address, description) /* empty */
  #define ANNOTATE_FLUSH_EXPECTED_RACES(address, description) /* empty */
  #define ANNOTATE_BENIGN_RACE(address, description) /* empty */
  #define ANNOTATE_BENIGN_RACE_SIZED(address, size, description) /* empty */
  #define ANNOTATE_PURE_HAPPENS_BEFORE_MUTEX(mu) /* empty */
  #define ANNOTATE_MUTEX_IS_USED_AS_CONDVAR(mu) /* empty */
  #define ANNOTATE_TRACE_MEMORY(arg) /* empty */
  #define ANNOTATE_THREAD_NAME(name) /* empty */
  #define ANNOTATE_IGNORE_READS_BEGIN() /* empty */
  #define ANNOTATE_IGNORE_READS_END() /* empty */
  #define ANNOTATE_IGNORE_WRITES_BEGIN() /* empty */
  #define ANNOTATE_IGNORE_WRITES_END() /* empty */
  #define ANNOTATE_IGNORE_READS_AND_WRITES_BEGIN() /* empty */
  #define ANNOTATE_IGNORE_READS_AND_WRITES_END() /* empty */
  #define ANNOTATE_IGNORE_SYNC_BEGIN() /* empty */
  #define ANNOTATE_IGNORE_SYNC_END() /* empty */
  #define ANNOTATE_ENABLE_RACE_DETECTION(enable) /* empty */
  #define ANNOTATE_NO_OP(arg) /* empty */
  #define ANNOTATE_FLUSH_STATE() /* empty */

#endif  /* DYNAMIC_ANNOTATIONS_ENABLED */

/* Use the macros above rather than using these functions directly. */
#ifdef __cplusplus
extern "C" {
#endif


void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockCreate)(
    const char *file, int line,
    const volatile void *lock) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockDestroy)(
    const char *file, int line,
    const volatile void *lock) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockAcquired)(
    const char *file, int line,
    const volatile void *lock, long is_w) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateRWLockReleased)(
    const char *file, int line,
    const volatile void *lock, long is_w) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierInit)(
    const char *file, int line, const volatile void *barrier, long count,
    long reinitialization_allowed) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierWaitBefore)(
    const char *file, int line,
    const volatile void *barrier) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierWaitAfter)(
    const char *file, int line,
    const volatile void *barrier) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateBarrierDestroy)(
    const char *file, int line,
    const volatile void *barrier) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarWait)(
    const char *file, int line, const volatile void *cv,
    const volatile void *lock) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarSignal)(
    const char *file, int line,
    const volatile void *cv) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateCondVarSignalAll)(
    const char *file, int line,
    const volatile void *cv) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateHappensBefore)(
    const char *file, int line,
    const volatile void *obj) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateHappensAfter)(
    const char *file, int line,
    const volatile void *obj) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotatePublishMemoryRange)(
    const char *file, int line,
    const volatile void *address, long size) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateUnpublishMemoryRange)(
    const char *file, int line,
    const volatile void *address, long size) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQCreate)(
    const char *file, int line,
    const volatile void *pcq) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQDestroy)(
    const char *file, int line,
    const volatile void *pcq) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQPut)(
    const char *file, int line,
    const volatile void *pcq) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotatePCQGet)(
    const char *file, int line,
    const volatile void *pcq) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateNewMemory)(
    const char *file, int line,
    const volatile void *mem, long size) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateExpectRace)(
    const char *file, int line, const volatile void *mem,
    const char *description) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateFlushExpectedRaces)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateBenignRace)(
    const char *file, int line, const volatile void *mem,
    const char *description) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateBenignRaceSized)(
    const char *file, int line, const volatile void *mem, long size,
    const char *description) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsUsedAsCondVar)(
    const char *file, int line,
    const volatile void *mu) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateMutexIsNotPHB)(
    const char *file, int line,
    const volatile void *mu) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateTraceMemory)(
    const char *file, int line,
    const volatile void *arg) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateThreadName)(
    const char *file, int line,
    const char *name) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreReadsBegin)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreReadsEnd)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreWritesBegin)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreWritesEnd)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreSyncBegin)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateIgnoreSyncEnd)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateEnableRaceDetection)(
    const char *file, int line, int enable) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateNoOp)(
    const char *file, int line,
    const volatile void *arg) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
void DYNAMIC_ANNOTATIONS_NAME(AnnotateFlushState)(
    const char *file, int line) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;

#if DYNAMIC_ANNOTATIONS_PROVIDE_RUNNING_ON_VALGRIND == 1
/* Return non-zero value if running under valgrind.

  If "valgrind.h" is included into dynamic_annotations.c,
  the regular valgrind mechanism will be used.
  See http://valgrind.org/docs/manual/manual-core-adv.html about
  RUNNING_ON_VALGRIND and other valgrind "client requests".
  The file "valgrind.h" may be obtained by doing
     svn co svn://svn.valgrind.org/valgrind/trunk/include

  If for some reason you can't use "valgrind.h" or want to fake valgrind,
  there are two ways to make this function return non-zero:
    - Use environment variable: export RUNNING_ON_VALGRIND=1
    - Make your tool intercept the function RunningOnValgrind() and
      change its return value.
 */
int RunningOnValgrind(void) DYNAMIC_ANNOTATIONS_ATTRIBUTE_WEAK;
#endif /* DYNAMIC_ANNOTATIONS_PROVIDE_RUNNING_ON_VALGRIND == 1 */

#ifdef __cplusplus
}
#endif

#if DYNAMIC_ANNOTATIONS_ENABLED != 0 && defined(__cplusplus)

  /* ANNOTATE_UNPROTECTED_READ is the preferred way to annotate racey reads.

     Instead of doing
        ANNOTATE_IGNORE_READS_BEGIN();
        ... = x;
        ANNOTATE_IGNORE_READS_END();
     one can use
        ... = ANNOTATE_UNPROTECTED_READ(x); */
  template <class T>
  inline T ANNOTATE_UNPROTECTED_READ(const volatile T &x) {
    ANNOTATE_IGNORE_READS_BEGIN();
    T res = x;
    ANNOTATE_IGNORE_READS_END();
    return res;
  }
  /* Apply ANNOTATE_BENIGN_RACE_SIZED to a static variable. */
  #define ANNOTATE_BENIGN_RACE_STATIC(static_var, description)        \
    namespace {                                                       \
      class static_var ## _annotator {                                \
       public:                                                        \
        static_var ## _annotator() {                                  \
          ANNOTATE_BENIGN_RACE_SIZED(&static_var,                     \
                                      sizeof(static_var),             \
            # static_var ": " description);                           \
        }                                                             \
      };                                                              \
      static static_var ## _annotator the ## static_var ## _annotator;\
    }
#else /* DYNAMIC_ANNOTATIONS_ENABLED == 0 */

  #define ANNOTATE_UNPROTECTED_READ(x) (x)
  #define ANNOTATE_BENIGN_RACE_STATIC(static_var, description)  /* empty */

#endif /* DYNAMIC_ANNOTATIONS_ENABLED */

#endif  /* __DYNAMIC_ANNOTATIONS_H__ */

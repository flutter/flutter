/* Copyright (c) 2008, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
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
 *
 * ---
 * Author: Kostya Serebryany
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

#ifndef BASE_DYNAMIC_ANNOTATIONS_H_
#define BASE_DYNAMIC_ANNOTATIONS_H_

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
    AnnotateCondVarWait(__FILE__, __LINE__, cv, lock)

  /* Report that wait on the condition variable at "cv" has succeeded.  Variant
     w/o lock. */
  #define ANNOTATE_CONDVAR_WAIT(cv) \
    AnnotateCondVarWait(__FILE__, __LINE__, cv, NULL)

  /* Report that we are about to signal on the condition variable at address
     "cv". */
  #define ANNOTATE_CONDVAR_SIGNAL(cv) \
    AnnotateCondVarSignal(__FILE__, __LINE__, cv)

  /* Report that we are about to signal_all on the condition variable at "cv". */
  #define ANNOTATE_CONDVAR_SIGNAL_ALL(cv) \
    AnnotateCondVarSignalAll(__FILE__, __LINE__, cv)

  /* Annotations for user-defined synchronization mechanisms. */
  #define ANNOTATE_HAPPENS_BEFORE(obj) ANNOTATE_CONDVAR_SIGNAL(obj)
  #define ANNOTATE_HAPPENS_AFTER(obj)  ANNOTATE_CONDVAR_WAIT(obj)

  /* Report that the bytes in the range [pointer, pointer+size) are about
     to be published safely. The race checker will create a happens-before
     arc from the call ANNOTATE_PUBLISH_MEMORY_RANGE(pointer, size) to
     subsequent accesses to this memory.
     Note: this annotation may not work properly if the race detector uses
     sampling, i.e. does not observe all memory accesses.
     */
  #define ANNOTATE_PUBLISH_MEMORY_RANGE(pointer, size) \
    AnnotatePublishMemoryRange(__FILE__, __LINE__, pointer, size)

  /* DEPRECATED. Don't use it. */
  #define ANNOTATE_UNPUBLISH_MEMORY_RANGE(pointer, size) \
    AnnotateUnpublishMemoryRange(__FILE__, __LINE__, pointer, size)

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
    AnnotateMutexIsUsedAsCondVar(__FILE__, __LINE__, mu)

  /* Deprecated. Use ANNOTATE_PURE_HAPPENS_BEFORE_MUTEX. */
  #define ANNOTATE_MUTEX_IS_USED_AS_CONDVAR(mu) \
    AnnotateMutexIsUsedAsCondVar(__FILE__, __LINE__, mu)

  /* -------------------------------------------------------------
     Annotations useful when defining memory allocators, or when memory that
     was protected in one way starts to be protected in another. */

  /* Report that a new memory at "address" of size "size" has been allocated.
     This might be used when the memory has been retrieved from a free list and
     is about to be reused, or when a the locking discipline for a variable
     changes. */
  #define ANNOTATE_NEW_MEMORY(address, size) \
    AnnotateNewMemory(__FILE__, __LINE__, address, size)

  /* -------------------------------------------------------------
     Annotations useful when defining FIFO queues that transfer data between
     threads. */

  /* Report that the producer-consumer queue (such as ProducerConsumerQueue) at
     address "pcq" has been created.  The ANNOTATE_PCQ_* annotations
     should be used only for FIFO queues.  For non-FIFO queues use
     ANNOTATE_HAPPENS_BEFORE (for put) and ANNOTATE_HAPPENS_AFTER (for get). */
  #define ANNOTATE_PCQ_CREATE(pcq) \
    AnnotatePCQCreate(__FILE__, __LINE__, pcq)

  /* Report that the queue at address "pcq" is about to be destroyed. */
  #define ANNOTATE_PCQ_DESTROY(pcq) \
    AnnotatePCQDestroy(__FILE__, __LINE__, pcq)

  /* Report that we are about to put an element into a FIFO queue at address
     "pcq". */
  #define ANNOTATE_PCQ_PUT(pcq) \
    AnnotatePCQPut(__FILE__, __LINE__, pcq)

  /* Report that we've just got an element from a FIFO queue at address "pcq". */
  #define ANNOTATE_PCQ_GET(pcq) \
    AnnotatePCQGet(__FILE__, __LINE__, pcq)

  /* -------------------------------------------------------------
     Annotations that suppress errors.  It is usually better to express the
     program's synchronization using the other annotations, but these can
     be used when all else fails. */

  /* Report that we may have a benign race at "pointer", with size
     "sizeof(*(pointer))". "pointer" must be a non-void* pointer.  Insert at the
     point where "pointer" has been allocated, preferably close to the point
     where the race happens.  See also ANNOTATE_BENIGN_RACE_STATIC. */
  #define ANNOTATE_BENIGN_RACE(pointer, description) \
    AnnotateBenignRaceSized(__FILE__, __LINE__, pointer, \
                            sizeof(*(pointer)), description)

  /* Same as ANNOTATE_BENIGN_RACE(address, description), but applies to
     the memory range [address, address+size). */
  #define ANNOTATE_BENIGN_RACE_SIZED(address, size, description) \
    AnnotateBenignRaceSized(__FILE__, __LINE__, address, size, description)

  /* Request the analysis tool to ignore all reads in the current thread
     until ANNOTATE_IGNORE_READS_END is called.
     Useful to ignore intentional racey reads, while still checking
     other reads and all writes.
     See also ANNOTATE_UNPROTECTED_READ. */
  #define ANNOTATE_IGNORE_READS_BEGIN() \
    AnnotateIgnoreReadsBegin(__FILE__, __LINE__)

  /* Stop ignoring reads. */
  #define ANNOTATE_IGNORE_READS_END() \
    AnnotateIgnoreReadsEnd(__FILE__, __LINE__)

  /* Similar to ANNOTATE_IGNORE_READS_BEGIN, but ignore writes. */
  #define ANNOTATE_IGNORE_WRITES_BEGIN() \
    AnnotateIgnoreWritesBegin(__FILE__, __LINE__)

  /* Stop ignoring writes. */
  #define ANNOTATE_IGNORE_WRITES_END() \
    AnnotateIgnoreWritesEnd(__FILE__, __LINE__)

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

  /* Enable (enable!=0) or disable (enable==0) race detection for all threads.
     This annotation could be useful if you want to skip expensive race analysis
     during some period of program execution, e.g. during initialization. */
  #define ANNOTATE_ENABLE_RACE_DETECTION(enable) \
    AnnotateEnableRaceDetection(__FILE__, __LINE__, enable)

  /* -------------------------------------------------------------
     Annotations useful for debugging. */

  /* Request to trace every access to "address". */
  #define ANNOTATE_TRACE_MEMORY(address) \
    AnnotateTraceMemory(__FILE__, __LINE__, address)

  /* Report the current thread name to a race detector. */
  #define ANNOTATE_THREAD_NAME(name) \
    AnnotateThreadName(__FILE__, __LINE__, name)

  /* -------------------------------------------------------------
     Annotations useful when implementing locks.  They are not
     normally needed by modules that merely use locks.
     The "lock" argument is a pointer to the lock object. */

  /* Report that a lock has been created at address "lock". */
  #define ANNOTATE_RWLOCK_CREATE(lock) \
    AnnotateRWLockCreate(__FILE__, __LINE__, lock)

  /* Report that the lock at address "lock" is about to be destroyed. */
  #define ANNOTATE_RWLOCK_DESTROY(lock) \
    AnnotateRWLockDestroy(__FILE__, __LINE__, lock)

  /* Report that the lock at address "lock" has been acquired.
     is_w=1 for writer lock, is_w=0 for reader lock. */
  #define ANNOTATE_RWLOCK_ACQUIRED(lock, is_w) \
    AnnotateRWLockAcquired(__FILE__, __LINE__, lock, is_w)

  /* Report that the lock at address "lock" is about to be released. */
  #define ANNOTATE_RWLOCK_RELEASED(lock, is_w) \
    AnnotateRWLockReleased(__FILE__, __LINE__, lock, is_w)

  /* -------------------------------------------------------------
     Annotations useful when implementing barriers.  They are not
     normally needed by modules that merely use barriers.
     The "barrier" argument is a pointer to the barrier object. */

  /* Report that the "barrier" has been initialized with initial "count".
   If 'reinitialization_allowed' is true, initialization is allowed to happen
   multiple times w/o calling barrier_destroy() */
  #define ANNOTATE_BARRIER_INIT(barrier, count, reinitialization_allowed) \
    AnnotateBarrierInit(__FILE__, __LINE__, barrier, count, \
                        reinitialization_allowed)

  /* Report that we are about to enter barrier_wait("barrier"). */
  #define ANNOTATE_BARRIER_WAIT_BEFORE(barrier) \
    AnnotateBarrierWaitBefore(__FILE__, __LINE__, barrier)

  /* Report that we just exited barrier_wait("barrier"). */
  #define ANNOTATE_BARRIER_WAIT_AFTER(barrier) \
    AnnotateBarrierWaitAfter(__FILE__, __LINE__, barrier)

  /* Report that the "barrier" has been destroyed. */
  #define ANNOTATE_BARRIER_DESTROY(barrier) \
    AnnotateBarrierDestroy(__FILE__, __LINE__, barrier)

  /* -------------------------------------------------------------
     Annotations useful for testing race detectors. */

  /* Report that we expect a race on the variable at "address".
     Use only in unit tests for a race detector. */
  #define ANNOTATE_EXPECT_RACE(address, description) \
    AnnotateExpectRace(__FILE__, __LINE__, address, description)

  /* A no-op. Insert where you like to test the interceptors. */
  #define ANNOTATE_NO_OP(arg) \
    AnnotateNoOp(__FILE__, __LINE__, arg)

  /* Force the race detector to flush its state. The actual effect depends on
   * the implementation of the detector. */
  #define ANNOTATE_FLUSH_STATE() \
    AnnotateFlushState(__FILE__, __LINE__)


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
  #define ANNOTATE_ENABLE_RACE_DETECTION(enable) /* empty */
  #define ANNOTATE_NO_OP(arg) /* empty */
  #define ANNOTATE_FLUSH_STATE() /* empty */

#endif  /* DYNAMIC_ANNOTATIONS_ENABLED */

/* Macro definitions for GCC attributes that allow static thread safety
   analysis to recognize and use some of the dynamic annotations as
   escape hatches.
   TODO(lcwu): remove the check for __SUPPORT_DYN_ANNOTATION__ once the
   default crosstool/GCC supports these GCC attributes.  */

#define ANNOTALYSIS_STATIC_INLINE
#define ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY ;
#define ANNOTALYSIS_IGNORE_READS_BEGIN
#define ANNOTALYSIS_IGNORE_READS_END
#define ANNOTALYSIS_IGNORE_WRITES_BEGIN
#define ANNOTALYSIS_IGNORE_WRITES_END
#define ANNOTALYSIS_UNPROTECTED_READ

#if defined(__GNUC__) && (!defined(SWIG)) && (!defined(__clang__)) && \
    defined(__SUPPORT_TS_ANNOTATION__) && defined(__SUPPORT_DYN_ANNOTATION__)

#if DYNAMIC_ANNOTATIONS_ENABLED == 0
#define ANNOTALYSIS_ONLY 1
#undef ANNOTALYSIS_STATIC_INLINE
#define ANNOTALYSIS_STATIC_INLINE static inline
#undef ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY
#define ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY { (void)file; (void)line; }
#endif

/* Only emit attributes when annotalysis is enabled. */
#if defined(__SUPPORT_TS_ANNOTATION__) && defined(__SUPPORT_DYN_ANNOTATION__)
#undef  ANNOTALYSIS_IGNORE_READS_BEGIN
#define ANNOTALYSIS_IGNORE_READS_BEGIN  __attribute__ ((ignore_reads_begin))
#undef  ANNOTALYSIS_IGNORE_READS_END
#define ANNOTALYSIS_IGNORE_READS_END    __attribute__ ((ignore_reads_end))
#undef  ANNOTALYSIS_IGNORE_WRITES_BEGIN
#define ANNOTALYSIS_IGNORE_WRITES_BEGIN __attribute__ ((ignore_writes_begin))
#undef  ANNOTALYSIS_IGNORE_WRITES_END
#define ANNOTALYSIS_IGNORE_WRITES_END   __attribute__ ((ignore_writes_end))
#undef  ANNOTALYSIS_UNPROTECTED_READ
#define ANNOTALYSIS_UNPROTECTED_READ    __attribute__ ((unprotected_read))
#endif

#endif // defined(__GNUC__) && (!defined(SWIG)) && (!defined(__clang__))

/* Use the macros above rather than using these functions directly. */
#ifdef __cplusplus
extern "C" {
#endif
void AnnotateRWLockCreate(const char *file, int line,
                          const volatile void *lock);
void AnnotateRWLockDestroy(const char *file, int line,
                           const volatile void *lock);
void AnnotateRWLockAcquired(const char *file, int line,
                            const volatile void *lock, long is_w);
void AnnotateRWLockReleased(const char *file, int line,
                            const volatile void *lock, long is_w);
void AnnotateBarrierInit(const char *file, int line,
                         const volatile void *barrier, long count,
                         long reinitialization_allowed);
void AnnotateBarrierWaitBefore(const char *file, int line,
                               const volatile void *barrier);
void AnnotateBarrierWaitAfter(const char *file, int line,
                              const volatile void *barrier);
void AnnotateBarrierDestroy(const char *file, int line,
                            const volatile void *barrier);
void AnnotateCondVarWait(const char *file, int line,
                         const volatile void *cv,
                         const volatile void *lock);
void AnnotateCondVarSignal(const char *file, int line,
                           const volatile void *cv);
void AnnotateCondVarSignalAll(const char *file, int line,
                              const volatile void *cv);
void AnnotatePublishMemoryRange(const char *file, int line,
                                const volatile void *address,
                                long size);
void AnnotateUnpublishMemoryRange(const char *file, int line,
                                  const volatile void *address,
                                  long size);
void AnnotatePCQCreate(const char *file, int line,
                       const volatile void *pcq);
void AnnotatePCQDestroy(const char *file, int line,
                        const volatile void *pcq);
void AnnotatePCQPut(const char *file, int line,
                    const volatile void *pcq);
void AnnotatePCQGet(const char *file, int line,
                    const volatile void *pcq);
void AnnotateNewMemory(const char *file, int line,
                       const volatile void *address,
                       long size);
void AnnotateExpectRace(const char *file, int line,
                        const volatile void *address,
                        const char *description);
void AnnotateBenignRace(const char *file, int line,
                        const volatile void *address,
                        const char *description);
void AnnotateBenignRaceSized(const char *file, int line,
                        const volatile void *address,
                        long size,
                        const char *description);
void AnnotateMutexIsUsedAsCondVar(const char *file, int line,
                                  const volatile void *mu);
void AnnotateTraceMemory(const char *file, int line,
                         const volatile void *arg);
void AnnotateThreadName(const char *file, int line,
                        const char *name);
ANNOTALYSIS_STATIC_INLINE
void AnnotateIgnoreReadsBegin(const char *file, int line)
    ANNOTALYSIS_IGNORE_READS_BEGIN ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY
ANNOTALYSIS_STATIC_INLINE
void AnnotateIgnoreReadsEnd(const char *file, int line)
    ANNOTALYSIS_IGNORE_READS_END ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY
ANNOTALYSIS_STATIC_INLINE
void AnnotateIgnoreWritesBegin(const char *file, int line)
    ANNOTALYSIS_IGNORE_WRITES_BEGIN ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY
ANNOTALYSIS_STATIC_INLINE
void AnnotateIgnoreWritesEnd(const char *file, int line)
    ANNOTALYSIS_IGNORE_WRITES_END ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY
void AnnotateEnableRaceDetection(const char *file, int line, int enable);
void AnnotateNoOp(const char *file, int line,
                  const volatile void *arg);
void AnnotateFlushState(const char *file, int line);

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
int RunningOnValgrind(void);

/* ValgrindSlowdown returns:
    * 1.0, if (RunningOnValgrind() == 0)
    * 50.0, if (RunningOnValgrind() != 0 && getenv("VALGRIND_SLOWDOWN") == NULL)
    * atof(getenv("VALGRIND_SLOWDOWN")) otherwise
   This function can be used to scale timeout values:
   EXAMPLE:
   for (;;) {
     DoExpensiveBackgroundTask();
     SleepForSeconds(5 * ValgrindSlowdown());
   }
 */
double ValgrindSlowdown(void);

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
  inline T ANNOTATE_UNPROTECTED_READ(const volatile T &x)
      ANNOTALYSIS_UNPROTECTED_READ {
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

/* Annotalysis, a GCC based static analyzer, is able to understand and use
   some of the dynamic annotations defined in this file. However, dynamic
   annotations are usually disabled in the opt mode (to avoid additional
   runtime overheads) while Annotalysis only works in the opt mode.
   In order for Annotalysis to use these dynamic annotations when they
   are disabled, we re-define these annotations here. Note that unlike the
   original macro definitions above, these macros are expanded to calls to
   static inline functions so that the compiler will be able to remove the
   calls after the analysis. */

#ifdef ANNOTALYSIS_ONLY

  #undef ANNOTALYSIS_ONLY

  /* Undefine and re-define the macros that the static analyzer understands. */
  #undef ANNOTATE_IGNORE_READS_BEGIN
  #define ANNOTATE_IGNORE_READS_BEGIN()           \
    AnnotateIgnoreReadsBegin(__FILE__, __LINE__)

  #undef ANNOTATE_IGNORE_READS_END
  #define ANNOTATE_IGNORE_READS_END()             \
    AnnotateIgnoreReadsEnd(__FILE__, __LINE__)

  #undef ANNOTATE_IGNORE_WRITES_BEGIN
  #define ANNOTATE_IGNORE_WRITES_BEGIN()          \
    AnnotateIgnoreWritesBegin(__FILE__, __LINE__)

  #undef ANNOTATE_IGNORE_WRITES_END
  #define ANNOTATE_IGNORE_WRITES_END()            \
    AnnotateIgnoreWritesEnd(__FILE__, __LINE__)

  #undef ANNOTATE_IGNORE_READS_AND_WRITES_BEGIN
  #define ANNOTATE_IGNORE_READS_AND_WRITES_BEGIN()       \
    do {                                                 \
      ANNOTATE_IGNORE_READS_BEGIN();                     \
      ANNOTATE_IGNORE_WRITES_BEGIN();                    \
    }while(0)                                            \

  #undef ANNOTATE_IGNORE_READS_AND_WRITES_END
  #define ANNOTATE_IGNORE_READS_AND_WRITES_END()  \
    do {                                          \
      ANNOTATE_IGNORE_WRITES_END();               \
      ANNOTATE_IGNORE_READS_END();                \
    }while(0)                                     \

  #if defined(__cplusplus)
    #undef ANNOTATE_UNPROTECTED_READ
    template <class T>
    inline T ANNOTATE_UNPROTECTED_READ(const volatile T &x)
         ANNOTALYSIS_UNPROTECTED_READ {
      ANNOTATE_IGNORE_READS_BEGIN();
      T res = x;
      ANNOTATE_IGNORE_READS_END();
      return res;
    }
  #endif /* __cplusplus */

#endif /* ANNOTALYSIS_ONLY */

/* Undefine the macros intended only in this file. */
#undef ANNOTALYSIS_STATIC_INLINE
#undef ANNOTALYSIS_SEMICOLON_OR_EMPTY_BODY

#endif  /* BASE_DYNAMIC_ANNOTATIONS_H_ */

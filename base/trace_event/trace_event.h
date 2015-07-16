// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This header file defines the set of trace_event macros without specifying
// how the events actually get collected and stored. If you need to expose trace
// events to some other universe, you can copy-and-paste this file as well as
// trace_event.h, modifying the macros contained there as necessary for the
// target platform. The end result is that multiple libraries can funnel events
// through to a shared trace event collector.

// Trace events are for tracking application performance and resource usage.
// Macros are provided to track:
//    Begin and end of function calls
//    Counters
//
// Events are issued against categories. Whereas LOG's
// categories are statically defined, TRACE categories are created
// implicitly with a string. For example:
//   TRACE_EVENT_INSTANT0("MY_SUBSYSTEM", "SomeImportantEvent",
//                        TRACE_EVENT_SCOPE_THREAD)
//
// It is often the case that one trace may belong in multiple categories at the
// same time. The first argument to the trace can be a comma-separated list of
// categories, forming a category group, like:
//
// TRACE_EVENT_INSTANT0("input,views", "OnMouseOver", TRACE_EVENT_SCOPE_THREAD)
//
// We can enable/disable tracing of OnMouseOver by enabling/disabling either
// category.
//
// Events can be INSTANT, or can be pairs of BEGIN and END in the same scope:
//   TRACE_EVENT_BEGIN0("MY_SUBSYSTEM", "SomethingCostly")
//   doSomethingCostly()
//   TRACE_EVENT_END0("MY_SUBSYSTEM", "SomethingCostly")
// Note: our tools can't always determine the correct BEGIN/END pairs unless
// these are used in the same scope. Use ASYNC_BEGIN/ASYNC_END macros if you
// need them to be in separate scopes.
//
// A common use case is to trace entire function scopes. This
// issues a trace BEGIN and END automatically:
//   void doSomethingCostly() {
//     TRACE_EVENT0("MY_SUBSYSTEM", "doSomethingCostly");
//     ...
//   }
//
// Additional parameters can be associated with an event:
//   void doSomethingCostly2(int howMuch) {
//     TRACE_EVENT1("MY_SUBSYSTEM", "doSomethingCostly",
//         "howMuch", howMuch);
//     ...
//   }
//
// The trace system will automatically add to this information the
// current process id, thread id, and a timestamp in microseconds.
//
// To trace an asynchronous procedure such as an IPC send/receive, use
// ASYNC_BEGIN and ASYNC_END:
//   [single threaded sender code]
//     static int send_count = 0;
//     ++send_count;
//     TRACE_EVENT_ASYNC_BEGIN0("ipc", "message", send_count);
//     Send(new MyMessage(send_count));
//   [receive code]
//     void OnMyMessage(send_count) {
//       TRACE_EVENT_ASYNC_END0("ipc", "message", send_count);
//     }
// The third parameter is a unique ID to match ASYNC_BEGIN/ASYNC_END pairs.
// ASYNC_BEGIN and ASYNC_END can occur on any thread of any traced process.
// Pointers can be used for the ID parameter, and they will be mangled
// internally so that the same pointer on two different processes will not
// match. For example:
//   class MyTracedClass {
//    public:
//     MyTracedClass() {
//       TRACE_EVENT_ASYNC_BEGIN0("category", "MyTracedClass", this);
//     }
//     ~MyTracedClass() {
//       TRACE_EVENT_ASYNC_END0("category", "MyTracedClass", this);
//     }
//   }
//
// Trace event also supports counters, which is a way to track a quantity
// as it varies over time. Counters are created with the following macro:
//   TRACE_COUNTER1("MY_SUBSYSTEM", "myCounter", g_myCounterValue);
//
// Counters are process-specific. The macro itself can be issued from any
// thread, however.
//
// Sometimes, you want to track two counters at once. You can do this with two
// counter macros:
//   TRACE_COUNTER1("MY_SUBSYSTEM", "myCounter0", g_myCounterValue[0]);
//   TRACE_COUNTER1("MY_SUBSYSTEM", "myCounter1", g_myCounterValue[1]);
// Or you can do it with a combined macro:
//   TRACE_COUNTER2("MY_SUBSYSTEM", "myCounter",
//       "bytesPinned", g_myCounterValue[0],
//       "bytesAllocated", g_myCounterValue[1]);
// This indicates to the tracing UI that these counters should be displayed
// in a single graph, as a summed area chart.
//
// Since counters are in a global namespace, you may want to disambiguate with a
// unique ID, by using the TRACE_COUNTER_ID* variations.
//
// By default, trace collection is compiled in, but turned off at runtime.
// Collecting trace data is the responsibility of the embedding
// application. In Chrome's case, navigating to about:tracing will turn on
// tracing and display data collected across all active processes.
//
//
// Memory scoping note:
// Tracing copies the pointers, not the string content, of the strings passed
// in for category_group, name, and arg_names.  Thus, the following code will
// cause problems:
//     char* str = strdup("importantName");
//     TRACE_EVENT_INSTANT0("SUBSYSTEM", str);  // BAD!
//     free(str);                   // Trace system now has dangling pointer
//
// To avoid this issue with the |name| and |arg_name| parameters, use the
// TRACE_EVENT_COPY_XXX overloads of the macros at additional runtime overhead.
// Notes: The category must always be in a long-lived char* (i.e. static const).
//        The |arg_values|, when used, are always deep copied with the _COPY
//        macros.
//
// When are string argument values copied:
// const char* arg_values are only referenced by default:
//     TRACE_EVENT1("category", "name",
//                  "arg1", "literal string is only referenced");
// Use TRACE_STR_COPY to force copying of a const char*:
//     TRACE_EVENT1("category", "name",
//                  "arg1", TRACE_STR_COPY("string will be copied"));
// std::string arg_values are always copied:
//     TRACE_EVENT1("category", "name",
//                  "arg1", std::string("string will be copied"));
//
//
// Convertable notes:
// Converting a large data type to a string can be costly. To help with this,
// the trace framework provides an interface ConvertableToTraceFormat. If you
// inherit from it and implement the AppendAsTraceFormat method the trace
// framework will call back to your object to convert a trace output time. This
// means, if the category for the event is disabled, the conversion will not
// happen.
//
//   class MyData : public base::trace_event::ConvertableToTraceFormat {
//    public:
//     MyData() {}
//     void AppendAsTraceFormat(std::string* out) const override {
//       out->append("{\"foo\":1}");
//     }
//    private:
//     ~MyData() override {}
//     DISALLOW_COPY_AND_ASSIGN(MyData);
//   };
//
//   TRACE_EVENT1("foo", "bar", "data",
//                scoped_refptr<ConvertableToTraceFormat>(new MyData()));
//
// The trace framework will take ownership if the passed pointer and it will
// be free'd when the trace buffer is flushed.
//
// Note, we only do the conversion when the buffer is flushed, so the provided
// data object should not be modified after it's passed to the trace framework.
//
//
// Thread Safety:
// A thread safe singleton and mutex are used for thread safety. Category
// enabled flags are used to limit the performance impact when the system
// is not enabled.
//
// TRACE_EVENT macros first cache a pointer to a category. The categories are
// statically allocated and safe at all times, even after exit. Fetching a
// category is protected by the TraceLog::lock_. Multiple threads initializing
// the static variable is safe, as they will be serialized by the lock and
// multiple calls will return the same pointer to the category.
//
// Then the category_group_enabled flag is checked. This is a unsigned char, and
// not intended to be multithread safe. It optimizes access to AddTraceEvent
// which is threadsafe internally via TraceLog::lock_. The enabled flag may
// cause some threads to incorrectly call or skip calling AddTraceEvent near
// the time of the system being enabled or disabled. This is acceptable as
// we tolerate some data loss while the system is being enabled/disabled and
// because AddTraceEvent is threadsafe internally and checks the enabled state
// again under lock.
//
// Without the use of these static category pointers and enabled flags all
// trace points would carry a significant performance cost of acquiring a lock
// and resolving the category.

#ifndef BASE_TRACE_EVENT_TRACE_EVENT_H_
#define BASE_TRACE_EVENT_TRACE_EVENT_H_

#include <string>

#include "base/atomicops.h"
#include "base/time/time.h"
#include "base/trace_event/trace_event_impl.h"
#include "base/trace_event/trace_event_memory.h"
#include "base/trace_event/trace_event_system_stats_monitor.h"
#include "build/build_config.h"

// By default, const char* argument values are assumed to have long-lived scope
// and will not be copied. Use this macro to force a const char* to be copied.
#define TRACE_STR_COPY(str) \
    trace_event_internal::TraceStringWithCopy(str)

// This will mark the trace event as disabled by default. The user will need
// to explicitly enable the event.
#define TRACE_DISABLED_BY_DEFAULT(name) "disabled-by-default-" name

// By default, uint64 ID argument values are not mangled with the Process ID in
// TRACE_EVENT_ASYNC macros. Use this macro to force Process ID mangling.
#define TRACE_ID_MANGLE(id) \
    trace_event_internal::TraceID::ForceMangle(id)

// By default, pointers are mangled with the Process ID in TRACE_EVENT_ASYNC
// macros. Use this macro to prevent Process ID mangling.
#define TRACE_ID_DONT_MANGLE(id) \
    trace_event_internal::TraceID::DontMangle(id)

// Records a pair of begin and end events called "name" for the current
// scope, with 0, 1 or 2 associated arguments. If the category is not
// enabled, then this does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT0(category_group, name) \
    INTERNAL_TRACE_MEMORY(category_group, name) \
    INTERNAL_TRACE_EVENT_ADD_SCOPED(category_group, name)
#define TRACE_EVENT1(category_group, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_MEMORY(category_group, name) \
    INTERNAL_TRACE_EVENT_ADD_SCOPED(category_group, name, arg1_name, arg1_val)
#define TRACE_EVENT2( \
    category_group, name, arg1_name, arg1_val, arg2_name, arg2_val) \
  INTERNAL_TRACE_MEMORY(category_group, name) \
  INTERNAL_TRACE_EVENT_ADD_SCOPED( \
      category_group, name, arg1_name, arg1_val, arg2_name, arg2_val)

// Records events like TRACE_EVENT2 but uses |memory_tag| for memory tracing.
// Use this where |name| is too generic to accurately aggregate allocations.
#define TRACE_EVENT_WITH_MEMORY_TAG2( \
    category, name, memory_tag, arg1_name, arg1_val, arg2_name, arg2_val) \
  INTERNAL_TRACE_MEMORY(category, memory_tag) \
  INTERNAL_TRACE_EVENT_ADD_SCOPED( \
      category, name, arg1_name, arg1_val, arg2_name, arg2_val)

// UNSHIPPED_TRACE_EVENT* are like TRACE_EVENT* except that they are not
// included in official builds.

#if OFFICIAL_BUILD
#undef TRACING_IS_OFFICIAL_BUILD
#define TRACING_IS_OFFICIAL_BUILD 1
#elif !defined(TRACING_IS_OFFICIAL_BUILD)
#define TRACING_IS_OFFICIAL_BUILD 0
#endif

#if TRACING_IS_OFFICIAL_BUILD
#define UNSHIPPED_TRACE_EVENT0(category_group, name) (void)0
#define UNSHIPPED_TRACE_EVENT1(category_group, name, arg1_name, arg1_val) \
    (void)0
#define UNSHIPPED_TRACE_EVENT2(category_group, name, arg1_name, arg1_val, \
                               arg2_name, arg2_val) (void)0
#define UNSHIPPED_TRACE_EVENT_INSTANT0(category_group, name, scope) (void)0
#define UNSHIPPED_TRACE_EVENT_INSTANT1(category_group, name, scope, \
                                       arg1_name, arg1_val) (void)0
#define UNSHIPPED_TRACE_EVENT_INSTANT2(category_group, name, scope, \
                                       arg1_name, arg1_val, \
                                       arg2_name, arg2_val) (void)0
#else
#define UNSHIPPED_TRACE_EVENT0(category_group, name) \
    TRACE_EVENT0(category_group, name)
#define UNSHIPPED_TRACE_EVENT1(category_group, name, arg1_name, arg1_val) \
    TRACE_EVENT1(category_group, name, arg1_name, arg1_val)
#define UNSHIPPED_TRACE_EVENT2(category_group, name, arg1_name, arg1_val, \
                               arg2_name, arg2_val) \
    TRACE_EVENT2(category_group, name, arg1_name, arg1_val, arg2_name, arg2_val)
#define UNSHIPPED_TRACE_EVENT_INSTANT0(category_group, name, scope) \
    TRACE_EVENT_INSTANT0(category_group, name, scope)
#define UNSHIPPED_TRACE_EVENT_INSTANT1(category_group, name, scope, \
                                       arg1_name, arg1_val) \
    TRACE_EVENT_INSTANT1(category_group, name, scope, arg1_name, arg1_val)
#define UNSHIPPED_TRACE_EVENT_INSTANT2(category_group, name, scope, \
                                       arg1_name, arg1_val, \
                                       arg2_name, arg2_val) \
    TRACE_EVENT_INSTANT2(category_group, name, scope, arg1_name, arg1_val, \
                         arg2_name, arg2_val)
#endif

// Records a single event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT_INSTANT0(category_group, name, scope) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category_group, name, TRACE_EVENT_FLAG_NONE | scope)
#define TRACE_EVENT_INSTANT1(category_group, name, scope, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category_group, name, TRACE_EVENT_FLAG_NONE | scope, \
        arg1_name, arg1_val)
#define TRACE_EVENT_INSTANT2(category_group, name, scope, arg1_name, arg1_val, \
                             arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category_group, name, TRACE_EVENT_FLAG_NONE | scope, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_INSTANT0(category_group, name, scope) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category_group, name, TRACE_EVENT_FLAG_COPY | scope)
#define TRACE_EVENT_COPY_INSTANT1(category_group, name, scope, \
                                  arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category_group, name, TRACE_EVENT_FLAG_COPY | scope, arg1_name, \
        arg1_val)
#define TRACE_EVENT_COPY_INSTANT2(category_group, name, scope, \
                                  arg1_name, arg1_val, \
                                  arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category_group, name, TRACE_EVENT_FLAG_COPY | scope, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Sets the current sample state to the given category and name (both must be
// constant strings). These states are intended for a sampling profiler.
// Implementation note: we store category and name together because we don't
// want the inconsistency/expense of storing two pointers.
// |thread_bucket| is [0..2] and is used to statically isolate samples in one
// thread from others.
#define TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET( \
    bucket_number, category, name)                 \
        trace_event_internal::                     \
        TraceEventSamplingStateScope<bucket_number>::Set(category "\0" name)

// Returns a current sampling state of the given bucket.
#define TRACE_EVENT_GET_SAMPLING_STATE_FOR_BUCKET(bucket_number) \
    trace_event_internal::TraceEventSamplingStateScope<bucket_number>::Current()

// Creates a scope of a sampling state of the given bucket.
//
// {  // The sampling state is set within this scope.
//    TRACE_EVENT_SAMPLING_STATE_SCOPE_FOR_BUCKET(0, "category", "name");
//    ...;
// }
#define TRACE_EVENT_SCOPED_SAMPLING_STATE_FOR_BUCKET(                   \
    bucket_number, category, name)                                      \
    trace_event_internal::TraceEventSamplingStateScope<bucket_number>   \
        traceEventSamplingScope(category "\0" name);

// Syntactic sugars for the sampling tracing in the main thread.
#define TRACE_EVENT_SCOPED_SAMPLING_STATE(category, name) \
    TRACE_EVENT_SCOPED_SAMPLING_STATE_FOR_BUCKET(0, category, name)
#define TRACE_EVENT_GET_SAMPLING_STATE() \
    TRACE_EVENT_GET_SAMPLING_STATE_FOR_BUCKET(0)
#define TRACE_EVENT_SET_SAMPLING_STATE(category, name) \
    TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(0, category, name)


// Records a single BEGIN event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT_BEGIN0(category_group, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category_group, name, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_BEGIN1(category_group, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category_group, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_BEGIN2(category_group, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category_group, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)
#define TRACE_EVENT_COPY_BEGIN0(category_group, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category_group, name, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_BEGIN1(category_group, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category_group, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_BEGIN2(category_group, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category_group, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Similar to TRACE_EVENT_BEGINx but with a custom |at| timestamp provided.
// - |id| is used to match the _BEGIN event with the _END event.
//   Events are considered to match if their category_group, name and id values
//   all match. |id| must either be a pointer or an integer value up to 64 bits.
//   If it's a pointer, the bits will be xored with a hash of the process ID so
//   that the same pointer on two different processes will not collide.
#define TRACE_EVENT_BEGIN_WITH_ID_TID_AND_TIMESTAMP0(category_group, \
        name, id, thread_id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_BEGIN, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_COPY_BEGIN_WITH_ID_TID_AND_TIMESTAMP0( \
        category_group, name, id, thread_id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_BEGIN, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_BEGIN_WITH_ID_TID_AND_TIMESTAMP1( \
        category_group, name, id, thread_id, timestamp, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_BEGIN, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_BEGIN_WITH_ID_TID_AND_TIMESTAMP2( \
        category_group, name, id, thread_id, timestamp, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_BEGIN, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, arg2_name, \
        arg2_val)

// Records a single END event for "name" immediately. If the category
// is not enabled, then this does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT_END0(category_group, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category_group, name, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_END1(category_group, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category_group, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_END2(category_group, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category_group, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)
#define TRACE_EVENT_COPY_END0(category_group, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category_group, name, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_END1(category_group, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category_group, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_END2(category_group, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category_group, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Similar to TRACE_EVENT_ENDx but with a custom |at| timestamp provided.
// - |id| is used to match the _BEGIN event with the _END event.
//   Events are considered to match if their category_group, name and id values
//   all match. |id| must either be a pointer or an integer value up to 64 bits.
//   If it's a pointer, the bits will be xored with a hash of the process ID so
//   that the same pointer on two different processes will not collide.
#define TRACE_EVENT_END_WITH_ID_TID_AND_TIMESTAMP0(category_group, \
        name, id, thread_id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_END, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_COPY_END_WITH_ID_TID_AND_TIMESTAMP0( \
        category_group, name, id, thread_id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_END, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_END_WITH_ID_TID_AND_TIMESTAMP1( \
        category_group, name, id, thread_id, timestamp, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_END, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_END_WITH_ID_TID_AND_TIMESTAMP2( \
        category_group, name, id, thread_id, timestamp, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_END, category_group, name, id, thread_id, \
        timestamp, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, arg2_name, \
        arg2_val)

// Records the value of a counter called "name" immediately. Value
// must be representable as a 32 bit integer.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_COUNTER1(category_group, name, value) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, TRACE_EVENT_FLAG_NONE, \
        "value", static_cast<int>(value))
#define TRACE_COPY_COUNTER1(category_group, name, value) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, TRACE_EVENT_FLAG_COPY, \
        "value", static_cast<int>(value))

// Records the values of a multi-parted counter called "name" immediately.
// The UI will treat value1 and value2 as parts of a whole, displaying their
// values as a stacked-bar chart.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_COUNTER2(category_group, name, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, TRACE_EVENT_FLAG_NONE, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))
#define TRACE_COPY_COUNTER2(category_group, name, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, TRACE_EVENT_FLAG_COPY, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))

// Records the value of a counter called "name" immediately. Value
// must be representable as a 32 bit integer.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
// - |id| is used to disambiguate counters with the same name. It must either
//   be a pointer or an integer value up to 64 bits. If it's a pointer, the bits
//   will be xored with a hash of the process ID so that the same pointer on
//   two different processes will not collide.
#define TRACE_COUNTER_ID1(category_group, name, id, value) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, \
        "value", static_cast<int>(value))
#define TRACE_COPY_COUNTER_ID1(category_group, name, id, value) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        "value", static_cast<int>(value))

// Records the values of a multi-parted counter called "name" immediately.
// The UI will treat value1 and value2 as parts of a whole, displaying their
// values as a stacked-bar chart.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
// - |id| is used to disambiguate counters with the same name. It must either
//   be a pointer or an integer value up to 64 bits. If it's a pointer, the bits
//   will be xored with a hash of the process ID so that the same pointer on
//   two different processes will not collide.
#define TRACE_COUNTER_ID2(category_group, name, id, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))
#define TRACE_COPY_COUNTER_ID2(category_group, name, id, value1_name, \
        value1_val, value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))

// TRACE_EVENT_SAMPLE_* events are injected by the sampling profiler.
#define TRACE_EVENT_SAMPLE_WITH_TID_AND_TIMESTAMP0(category_group, name,       \
                                                   thread_id, timestamp)       \
  INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP(                          \
      TRACE_EVENT_PHASE_SAMPLE, category_group, name, 0, thread_id, timestamp, \
      TRACE_EVENT_FLAG_NONE)

#define TRACE_EVENT_SAMPLE_WITH_TID_AND_TIMESTAMP1(                            \
    category_group, name, thread_id, timestamp, arg1_name, arg1_val)           \
  INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP(                          \
      TRACE_EVENT_PHASE_SAMPLE, category_group, name, 0, thread_id, timestamp, \
      TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)

#define TRACE_EVENT_SAMPLE_WITH_TID_AND_TIMESTAMP2(category_group, name,       \
                                                   thread_id, timestamp,       \
                                                   arg1_name, arg1_val,        \
                                                   arg2_name, arg2_val)        \
  INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP(                          \
      TRACE_EVENT_PHASE_SAMPLE, category_group, name, 0, thread_id, timestamp, \
      TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, arg2_name, arg2_val)

// ASYNC_STEP_* APIs should be only used by legacy code. New code should
// consider using NESTABLE_ASYNC_* APIs to describe substeps within an async
// event.
// Records a single ASYNC_BEGIN event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
// - |id| is used to match the ASYNC_BEGIN event with the ASYNC_END event. ASYNC
//   events are considered to match if their category_group, name and id values
//   all match. |id| must either be a pointer or an integer value up to 64 bits.
//   If it's a pointer, the bits will be xored with a hash of the process ID so
//   that the same pointer on two different processes will not collide.
//
// An asynchronous operation can consist of multiple phases. The first phase is
// defined by the ASYNC_BEGIN calls. Additional phases can be defined using the
// ASYNC_STEP_INTO or ASYNC_STEP_PAST macros. The ASYNC_STEP_INTO macro will
// annotate the block following the call. The ASYNC_STEP_PAST macro will
// annotate the block prior to the call. Note that any particular event must use
// only STEP_INTO or STEP_PAST macros; they can not mix and match. When the
// operation completes, call ASYNC_END.
//
// An ASYNC trace typically occurs on a single thread (if not, they will only be
// drawn on the thread defined in the ASYNC_BEGIN event), but all events in that
// operation must use the same |name| and |id|. Each step can have its own
// args.
#define TRACE_EVENT_ASYNC_BEGIN0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_ASYNC_BEGIN1(category_group, name, id, arg1_name, \
        arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_ASYNC_BEGIN2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_ASYNC_BEGIN0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_ASYNC_BEGIN1(category_group, name, id, arg1_name, \
        arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_ASYNC_BEGIN2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Similar to TRACE_EVENT_ASYNC_BEGINx but with a custom |at| timestamp
// provided.
#define TRACE_EVENT_ASYNC_BEGIN_WITH_TIMESTAMP0(category_group, \
        name, id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_BEGIN, category_group, name, id, \
        static_cast<int>(base::PlatformThread::CurrentId()), \
        timestamp, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_COPY_ASYNC_BEGIN_WITH_TIMESTAMP0(category_group, \
        name, id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_BEGIN, category_group, name, id, \
        static_cast<int>(base::PlatformThread::CurrentId()), \
        timestamp, TRACE_EVENT_FLAG_COPY)

// Records a single ASYNC_STEP_INTO event for |step| immediately. If the
// category is not enabled, then this does nothing. The |name| and |id| must
// match the ASYNC_BEGIN event above. The |step| param identifies this step
// within the async event. This should be called at the beginning of the next
// phase of an asynchronous operation. The ASYNC_BEGIN event must not have any
// ASYNC_STEP_PAST events.
#define TRACE_EVENT_ASYNC_STEP_INTO0(category_group, name, id, step) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_INTO, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step)
#define TRACE_EVENT_ASYNC_STEP_INTO1(category_group, name, id, step, \
                                     arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_INTO, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step, \
        arg1_name, arg1_val)

// Similar to TRACE_EVENT_ASYNC_STEP_INTOx but with a custom |at| timestamp
// provided.
#define TRACE_EVENT_ASYNC_STEP_INTO_WITH_TIMESTAMP0(category_group, name, \
        id, step, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_STEP_INTO, category_group, name, id, \
        static_cast<int>(base::PlatformThread::CurrentId()), \
        timestamp, TRACE_EVENT_FLAG_NONE, "step", step)

// Records a single ASYNC_STEP_PAST event for |step| immediately. If the
// category is not enabled, then this does nothing. The |name| and |id| must
// match the ASYNC_BEGIN event above. The |step| param identifies this step
// within the async event. This should be called at the beginning of the next
// phase of an asynchronous operation. The ASYNC_BEGIN event must not have any
// ASYNC_STEP_INTO events.
#define TRACE_EVENT_ASYNC_STEP_PAST0(category_group, name, id, step) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_PAST, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step)
#define TRACE_EVENT_ASYNC_STEP_PAST1(category_group, name, id, step, \
                                     arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_PAST, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step, \
        arg1_name, arg1_val)

// Records a single ASYNC_END event for "name" immediately. If the category
// is not enabled, then this does nothing.
#define TRACE_EVENT_ASYNC_END0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_ASYNC_END1(category_group, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_ASYNC_END2(category_group, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_ASYNC_END0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_ASYNC_END1(category_group, name, id, arg1_name, \
        arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_ASYNC_END2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Similar to TRACE_EVENT_ASYNC_ENDx but with a custom |at| timestamp provided.
#define TRACE_EVENT_ASYNC_END_WITH_TIMESTAMP0(category_group, \
        name, id, timestamp) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_ASYNC_END, category_group, name, id, \
        static_cast<int>(base::PlatformThread::CurrentId()), \
        timestamp, TRACE_EVENT_FLAG_NONE)

// NESTABLE_ASYNC_* APIs are used to describe an async operation, which can
// be nested within a NESTABLE_ASYNC event and/or have inner NESTABLE_ASYNC
// events.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
// - A pair of NESTABLE_ASYNC_BEGIN event and NESTABLE_ASYNC_END event is
//   considered as a match if their category_group, name and id all match.
// - |id| must either be a pointer or an integer value up to 64 bits.
//   If it's a pointer, the bits will be xored with a hash of the process ID so
//   that the same pointer on two different processes will not collide.
// - |id| is used to match a child NESTABLE_ASYNC event with its parent
//   NESTABLE_ASYNC event. Therefore, events in the same nested event tree must
//   be logged using the same id and category_group.
//
// Unmatched NESTABLE_ASYNC_END event will be parsed as an event that starts
// at the first NESTABLE_ASYNC event of that id, and unmatched
// NESTABLE_ASYNC_BEGIN event will be parsed as an event that ends at the last
// NESTABLE_ASYNC event of that id. Corresponding warning messages for
// unmatched events will be shown in the analysis view.

// Records a single NESTABLE_ASYNC_BEGIN event called "name" immediately, with
// 0, 1 or 2 associated arguments. If the category is not enabled, then this
// does nothing.
#define TRACE_EVENT_NESTABLE_ASYNC_BEGIN0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_NESTABLE_ASYNC_BEGIN1(category_group, name, id, arg1_name, \
        arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_NESTABLE_ASYNC_BEGIN2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)
// Records a single NESTABLE_ASYNC_END event called "name" immediately, with 0
// or 2 associated arguments. If the category is not enabled, then this does
// nothing.
#define TRACE_EVENT_NESTABLE_ASYNC_END0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_NESTABLE_ASYNC_END2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)

#define TRACE_EVENT_COPY_NESTABLE_ASYNC_BEGIN_WITH_TTS2(category_group, name, \
        id, arg1_name, arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, \
        category_group, name, id, \
        TRACE_EVENT_FLAG_ASYNC_TTS | TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_NESTABLE_ASYNC_END_WITH_TTS2(category_group, name, \
        id, arg1_name, arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, \
        category_group, name, id, \
        TRACE_EVENT_FLAG_ASYNC_TTS | TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Similar to TRACE_EVENT_NESTABLE_ASYNC_{BEGIN,END}x but with a custom
// |timestamp| provided.
#define TRACE_EVENT_NESTABLE_ASYNC_BEGIN_WITH_TIMESTAMP0(category_group, name, \
        id, timestamp) \
  INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN, category_group, name, id, \
        static_cast<int>(base::PlatformThread::CurrentId()), timestamp, \
        TRACE_EVENT_FLAG_NONE)

#define TRACE_EVENT_NESTABLE_ASYNC_END_WITH_TIMESTAMP0(category_group, name, \
        id, timestamp) \
  INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP( \
        TRACE_EVENT_PHASE_NESTABLE_ASYNC_END, category_group, name, id, \
        static_cast<int>(base::PlatformThread::CurrentId()), timestamp, \
        TRACE_EVENT_FLAG_NONE)

// Records a single NESTABLE_ASYNC_INSTANT event called "name" immediately,
// with 2 associated arguments. If the category is not enabled, then this
// does nothing.
#define TRACE_EVENT_NESTABLE_ASYNC_INSTANT2(category_group, name, id, \
        arg1_name, arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_NESTABLE_ASYNC_INSTANT, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Records a single FLOW_BEGIN event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
// - |id| is used to match the FLOW_BEGIN event with the FLOW_END event. FLOW
//   events are considered to match if their category_group, name and id values
//   all match. |id| must either be a pointer or an integer value up to 64 bits.
//   If it's a pointer, the bits will be xored with a hash of the process ID so
//   that the same pointer on two different processes will not collide.
// FLOW events are different from ASYNC events in how they are drawn by the
// tracing UI. A FLOW defines asynchronous data flow, such as posting a task
// (FLOW_BEGIN) and later executing that task (FLOW_END). Expect FLOWs to be
// drawn as lines or arrows from FLOW_BEGIN scopes to FLOW_END scopes. Similar
// to ASYNC, a FLOW can consist of multiple phases. The first phase is defined
// by the FLOW_BEGIN calls. Additional phases can be defined using the FLOW_STEP
// macros. When the operation completes, call FLOW_END. An async operation can
// span threads and processes, but all events in that operation must use the
// same |name| and |id|. Each event can have its own args.
#define TRACE_EVENT_FLOW_BEGIN0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_FLOW_BEGIN1(category_group, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_BEGIN2(category_group, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_FLOW_BEGIN0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_FLOW_BEGIN1(category_group, name, id, arg1_name, \
        arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_FLOW_BEGIN2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_BEGIN, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Records a single FLOW_STEP event for |step| immediately. If the category
// is not enabled, then this does nothing. The |name| and |id| must match the
// FLOW_BEGIN event above. The |step| param identifies this step within the
// async event. This should be called at the beginning of the next phase of an
// asynchronous operation.
#define TRACE_EVENT_FLOW_STEP0(category_group, name, id, step) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_STEP, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step)
#define TRACE_EVENT_FLOW_STEP1(category_group, name, id, step, \
        arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_STEP, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_FLOW_STEP0(category_group, name, id, step) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_STEP, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, "step", step)
#define TRACE_EVENT_COPY_FLOW_STEP1(category_group, name, id, step, \
        arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_STEP, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, "step", step, \
        arg1_name, arg1_val)

// Records a single FLOW_END event for "name" immediately. If the category
// is not enabled, then this does nothing.
#define TRACE_EVENT_FLOW_END0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_FLOW_END1(category_group, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_FLOW_END2(category_group, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_FLOW_END0(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_FLOW_END1(category_group, name, id, arg1_name, \
        arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_FLOW_END2(category_group, name, id, arg1_name, \
        arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_FLOW_END, \
        category_group, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Macros to track the life time and value of arbitrary client objects.
// See also TraceTrackableObject.
#define TRACE_EVENT_OBJECT_CREATED_WITH_ID(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_CREATE_OBJECT, \
        category_group, name, TRACE_ID_DONT_MANGLE(id), TRACE_EVENT_FLAG_NONE)

#define TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(category_group, name, id, snapshot) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_SNAPSHOT_OBJECT, \
        category_group, name, TRACE_ID_DONT_MANGLE(id), TRACE_EVENT_FLAG_NONE,\
        "snapshot", snapshot)

#define TRACE_EVENT_OBJECT_DELETED_WITH_ID(category_group, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_DELETE_OBJECT, \
        category_group, name, TRACE_ID_DONT_MANGLE(id), TRACE_EVENT_FLAG_NONE)

#define INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE() \
  UNLIKELY(*INTERNAL_TRACE_EVENT_UID(category_group_enabled) &           \
           (base::trace_event::TraceLog::ENABLED_FOR_RECORDING |         \
            base::trace_event::TraceLog::ENABLED_FOR_EVENT_CALLBACK |    \
            base::trace_event::TraceLog::ENABLED_FOR_ETW_EXPORT))

// Macro to efficiently determine if a given category group is enabled.
#define TRACE_EVENT_CATEGORY_GROUP_ENABLED(category_group, ret) \
    do { \
      INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category_group); \
      if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
        *ret = true; \
      } else { \
        *ret = false; \
      } \
    } while (0)

// Macro to efficiently determine, through polling, if a new trace has begun.
#define TRACE_EVENT_IS_NEW_TRACE(ret) \
    do { \
      static int INTERNAL_TRACE_EVENT_UID(lastRecordingNumber) = 0; \
      int num_traces_recorded = TRACE_EVENT_API_GET_NUM_TRACES_RECORDED(); \
      if (num_traces_recorded != -1 && \
          num_traces_recorded != \
          INTERNAL_TRACE_EVENT_UID(lastRecordingNumber)) { \
        INTERNAL_TRACE_EVENT_UID(lastRecordingNumber) = \
            num_traces_recorded; \
        *ret = true; \
      } else { \
        *ret = false; \
      } \
    } while (0)

////////////////////////////////////////////////////////////////////////////////
// Implementation specific tracing API definitions.

// Get a pointer to the enabled state of the given trace category. Only
// long-lived literal strings should be given as the category group. The
// returned pointer can be held permanently in a local static for example. If
// the unsigned char is non-zero, tracing is enabled. If tracing is enabled,
// TRACE_EVENT_API_ADD_TRACE_EVENT can be called. It's OK if tracing is disabled
// between the load of the tracing state and the call to
// TRACE_EVENT_API_ADD_TRACE_EVENT, because this flag only provides an early out
// for best performance when tracing is disabled.
// const unsigned char*
//     TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED(const char* category_group)
#define TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED \
    base::trace_event::TraceLog::GetCategoryGroupEnabled

// Get the number of times traces have been recorded. This is used to implement
// the TRACE_EVENT_IS_NEW_TRACE facility.
// unsigned int TRACE_EVENT_API_GET_NUM_TRACES_RECORDED()
#define TRACE_EVENT_API_GET_NUM_TRACES_RECORDED \
    base::trace_event::TraceLog::GetInstance()->GetNumTracesRecorded

// Add a trace event to the platform tracing system.
// base::trace_event::TraceEventHandle TRACE_EVENT_API_ADD_TRACE_EVENT(
//                    char phase,
//                    const unsigned char* category_group_enabled,
//                    const char* name,
//                    unsigned long long id,
//                    int num_args,
//                    const char** arg_names,
//                    const unsigned char* arg_types,
//                    const unsigned long long* arg_values,
//                    unsigned char flags)
#define TRACE_EVENT_API_ADD_TRACE_EVENT \
    base::trace_event::TraceLog::GetInstance()->AddTraceEvent

// Add a trace event to the platform tracing system.
// base::trace_event::TraceEventHandle
// TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_TIMESTAMP(
//                    char phase,
//                    const unsigned char* category_group_enabled,
//                    const char* name,
//                    unsigned long long id,
//                    int thread_id,
//                    const TraceTicks& timestamp,
//                    int num_args,
//                    const char** arg_names,
//                    const unsigned char* arg_types,
//                    const unsigned long long* arg_values,
//                    unsigned char flags)
#define TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP \
    base::trace_event::TraceLog::GetInstance() \
      ->AddTraceEventWithThreadIdAndTimestamp

// Set the duration field of a COMPLETE trace event.
// void TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(
//     const unsigned char* category_group_enabled,
//     const char* name,
//     base::trace_event::TraceEventHandle id)
#define TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION \
    base::trace_event::TraceLog::GetInstance()->UpdateTraceEventDuration

// Defines atomic operations used internally by the tracing system.
#define TRACE_EVENT_API_ATOMIC_WORD base::subtle::AtomicWord
#define TRACE_EVENT_API_ATOMIC_LOAD(var) base::subtle::NoBarrier_Load(&(var))
#define TRACE_EVENT_API_ATOMIC_STORE(var, value) \
    base::subtle::NoBarrier_Store(&(var), (value))

// Defines visibility for classes in trace_event.h
#define TRACE_EVENT_API_CLASS_EXPORT BASE_EXPORT

// The thread buckets for the sampling profiler.
TRACE_EVENT_API_CLASS_EXPORT extern \
    TRACE_EVENT_API_ATOMIC_WORD g_trace_state[3];

#define TRACE_EVENT_API_THREAD_BUCKET(thread_bucket)                           \
    g_trace_state[thread_bucket]

////////////////////////////////////////////////////////////////////////////////

// Implementation detail: trace event macros create temporary variables
// to keep instrumentation overhead low. These macros give each temporary
// variable a unique name based on the line number to prevent name collisions.
#define INTERNAL_TRACE_EVENT_UID3(a,b) \
    trace_event_unique_##a##b
#define INTERNAL_TRACE_EVENT_UID2(a,b) \
    INTERNAL_TRACE_EVENT_UID3(a,b)
#define INTERNAL_TRACE_EVENT_UID(name_prefix) \
    INTERNAL_TRACE_EVENT_UID2(name_prefix, __LINE__)

// Implementation detail: internal macro to create static category.
// No barriers are needed, because this code is designed to operate safely
// even when the unsigned char* points to garbage data (which may be the case
// on processors without cache coherency).
#define INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO_CUSTOM_VARIABLES( \
    category_group, atomic, category_group_enabled) \
    category_group_enabled = \
        reinterpret_cast<const unsigned char*>(TRACE_EVENT_API_ATOMIC_LOAD( \
            atomic)); \
    if (UNLIKELY(!category_group_enabled)) { \
      category_group_enabled = \
          TRACE_EVENT_API_GET_CATEGORY_GROUP_ENABLED(category_group); \
      TRACE_EVENT_API_ATOMIC_STORE(atomic, \
          reinterpret_cast<TRACE_EVENT_API_ATOMIC_WORD>( \
              category_group_enabled)); \
    }

#define INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category_group) \
    static TRACE_EVENT_API_ATOMIC_WORD INTERNAL_TRACE_EVENT_UID(atomic) = 0; \
    const unsigned char* INTERNAL_TRACE_EVENT_UID(category_group_enabled); \
    INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO_CUSTOM_VARIABLES(category_group, \
        INTERNAL_TRACE_EVENT_UID(atomic), \
        INTERNAL_TRACE_EVENT_UID(category_group_enabled));

// Implementation detail: internal macro to create static category and add
// event if the category is enabled.
#define INTERNAL_TRACE_EVENT_ADD(phase, category_group, name, flags, ...) \
    do { \
      INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category_group); \
      if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
        trace_event_internal::AddTraceEvent( \
            phase, INTERNAL_TRACE_EVENT_UID(category_group_enabled), name, \
            trace_event_internal::kNoEventId, flags, ##__VA_ARGS__); \
      } \
    } while (0)

// Implementation detail: internal macro to create static category and add begin
// event if the category is enabled. Also adds the end event when the scope
// ends.
#define INTERNAL_TRACE_EVENT_ADD_SCOPED(category_group, name, ...) \
    INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category_group); \
    trace_event_internal::ScopedTracer INTERNAL_TRACE_EVENT_UID(tracer); \
    if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
      base::trace_event::TraceEventHandle h = \
          trace_event_internal::AddTraceEvent( \
              TRACE_EVENT_PHASE_COMPLETE, \
              INTERNAL_TRACE_EVENT_UID(category_group_enabled), name, \
              trace_event_internal::kNoEventId, TRACE_EVENT_FLAG_NONE, \
              ##__VA_ARGS__); \
      INTERNAL_TRACE_EVENT_UID(tracer).Initialize( \
          INTERNAL_TRACE_EVENT_UID(category_group_enabled), name, h); \
    }

// Implementation detail: internal macro to create static category and add
// event if the category is enabled.
#define INTERNAL_TRACE_EVENT_ADD_WITH_ID(phase, category_group, name, id, \
                                         flags, ...) \
    do { \
      INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category_group); \
      if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
        unsigned char trace_event_flags = flags | TRACE_EVENT_FLAG_HAS_ID; \
        trace_event_internal::TraceID trace_event_trace_id( \
            id, &trace_event_flags); \
        trace_event_internal::AddTraceEvent( \
            phase, INTERNAL_TRACE_EVENT_UID(category_group_enabled), \
            name, trace_event_trace_id.data(), trace_event_flags, \
            ##__VA_ARGS__); \
      } \
    } while (0)

// Implementation detail: internal macro to create static category and add
// event if the category is enabled.
#define INTERNAL_TRACE_EVENT_ADD_WITH_ID_TID_AND_TIMESTAMP(phase, \
        category_group, name, id, thread_id, timestamp, flags, ...) \
    do { \
      INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category_group); \
      if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
        unsigned char trace_event_flags = flags | TRACE_EVENT_FLAG_HAS_ID; \
        trace_event_internal::TraceID trace_event_trace_id( \
            id, &trace_event_flags); \
        trace_event_internal::AddTraceEventWithThreadIdAndTimestamp( \
            phase, INTERNAL_TRACE_EVENT_UID(category_group_enabled), \
            name, trace_event_trace_id.data(), \
            thread_id, base::TraceTicks::FromInternalValue(timestamp), \
            trace_event_flags | TRACE_EVENT_FLAG_EXPLICIT_TIMESTAMP, \
            ##__VA_ARGS__); \
      } \
    } while (0)

// Notes regarding the following definitions:
// New values can be added and propagated to third party libraries, but existing
// definitions must never be changed, because third party libraries may use old
// definitions.

// Phase indicates the nature of an event entry. E.g. part of a begin/end pair.
#define TRACE_EVENT_PHASE_BEGIN    ('B')
#define TRACE_EVENT_PHASE_END      ('E')
#define TRACE_EVENT_PHASE_COMPLETE ('X')
#define TRACE_EVENT_PHASE_INSTANT  ('I')
#define TRACE_EVENT_PHASE_ASYNC_BEGIN ('S')
#define TRACE_EVENT_PHASE_ASYNC_STEP_INTO  ('T')
#define TRACE_EVENT_PHASE_ASYNC_STEP_PAST  ('p')
#define TRACE_EVENT_PHASE_ASYNC_END   ('F')
#define TRACE_EVENT_PHASE_NESTABLE_ASYNC_BEGIN ('b')
#define TRACE_EVENT_PHASE_NESTABLE_ASYNC_END ('e')
#define TRACE_EVENT_PHASE_NESTABLE_ASYNC_INSTANT ('n')
#define TRACE_EVENT_PHASE_FLOW_BEGIN ('s')
#define TRACE_EVENT_PHASE_FLOW_STEP  ('t')
#define TRACE_EVENT_PHASE_FLOW_END   ('f')
#define TRACE_EVENT_PHASE_METADATA ('M')
#define TRACE_EVENT_PHASE_COUNTER  ('C')
#define TRACE_EVENT_PHASE_SAMPLE  ('P')
#define TRACE_EVENT_PHASE_CREATE_OBJECT ('N')
#define TRACE_EVENT_PHASE_SNAPSHOT_OBJECT ('O')
#define TRACE_EVENT_PHASE_DELETE_OBJECT ('D')
#define TRACE_EVENT_PHASE_MEMORY_DUMP ('v')

// Flags for changing the behavior of TRACE_EVENT_API_ADD_TRACE_EVENT.
#define TRACE_EVENT_FLAG_NONE         (static_cast<unsigned char>(0))
#define TRACE_EVENT_FLAG_COPY         (static_cast<unsigned char>(1 << 0))
#define TRACE_EVENT_FLAG_HAS_ID       (static_cast<unsigned char>(1 << 1))
#define TRACE_EVENT_FLAG_MANGLE_ID    (static_cast<unsigned char>(1 << 2))
#define TRACE_EVENT_FLAG_SCOPE_OFFSET (static_cast<unsigned char>(1 << 3))
#define TRACE_EVENT_FLAG_SCOPE_EXTRA  (static_cast<unsigned char>(1 << 4))
#define TRACE_EVENT_FLAG_EXPLICIT_TIMESTAMP (static_cast<unsigned char>(1 << 5))
#define TRACE_EVENT_FLAG_ASYNC_TTS    (static_cast<unsigned char>(1 << 6))

#define TRACE_EVENT_FLAG_SCOPE_MASK   (static_cast<unsigned char>( \
    TRACE_EVENT_FLAG_SCOPE_OFFSET | TRACE_EVENT_FLAG_SCOPE_EXTRA))

// Type values for identifying types in the TraceValue union.
#define TRACE_VALUE_TYPE_BOOL         (static_cast<unsigned char>(1))
#define TRACE_VALUE_TYPE_UINT         (static_cast<unsigned char>(2))
#define TRACE_VALUE_TYPE_INT          (static_cast<unsigned char>(3))
#define TRACE_VALUE_TYPE_DOUBLE       (static_cast<unsigned char>(4))
#define TRACE_VALUE_TYPE_POINTER      (static_cast<unsigned char>(5))
#define TRACE_VALUE_TYPE_STRING       (static_cast<unsigned char>(6))
#define TRACE_VALUE_TYPE_COPY_STRING  (static_cast<unsigned char>(7))
#define TRACE_VALUE_TYPE_CONVERTABLE  (static_cast<unsigned char>(8))

// Enum reflecting the scope of an INSTANT event. Must fit within
// TRACE_EVENT_FLAG_SCOPE_MASK.
#define TRACE_EVENT_SCOPE_GLOBAL  (static_cast<unsigned char>(0 << 3))
#define TRACE_EVENT_SCOPE_PROCESS (static_cast<unsigned char>(1 << 3))
#define TRACE_EVENT_SCOPE_THREAD  (static_cast<unsigned char>(2 << 3))

#define TRACE_EVENT_SCOPE_NAME_GLOBAL  ('g')
#define TRACE_EVENT_SCOPE_NAME_PROCESS ('p')
#define TRACE_EVENT_SCOPE_NAME_THREAD  ('t')

namespace trace_event_internal {

// Specify these values when the corresponding argument of AddTraceEvent is not
// used.
const int kZeroNumArgs = 0;
const unsigned long long kNoEventId = 0;

// TraceID encapsulates an ID that can either be an integer or pointer. Pointers
// are by default mangled with the Process ID so that they are unlikely to
// collide when the same pointer is used on different processes.
class TraceID {
 public:
  class DontMangle {
   public:
    explicit DontMangle(const void* id)
        : data_(static_cast<unsigned long long>(
              reinterpret_cast<uintptr_t>(id))) {}
    explicit DontMangle(unsigned long long id) : data_(id) {}
    explicit DontMangle(unsigned long id) : data_(id) {}
    explicit DontMangle(unsigned int id) : data_(id) {}
    explicit DontMangle(unsigned short id) : data_(id) {}
    explicit DontMangle(unsigned char id) : data_(id) {}
    explicit DontMangle(long long id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit DontMangle(long id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit DontMangle(int id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit DontMangle(short id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit DontMangle(signed char id)
        : data_(static_cast<unsigned long long>(id)) {}
    unsigned long long data() const { return data_; }
   private:
    unsigned long long data_;
  };

  class ForceMangle {
   public:
    explicit ForceMangle(unsigned long long id) : data_(id) {}
    explicit ForceMangle(unsigned long id) : data_(id) {}
    explicit ForceMangle(unsigned int id) : data_(id) {}
    explicit ForceMangle(unsigned short id) : data_(id) {}
    explicit ForceMangle(unsigned char id) : data_(id) {}
    explicit ForceMangle(long long id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit ForceMangle(long id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit ForceMangle(int id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit ForceMangle(short id)
        : data_(static_cast<unsigned long long>(id)) {}
    explicit ForceMangle(signed char id)
        : data_(static_cast<unsigned long long>(id)) {}
    unsigned long long data() const { return data_; }
   private:
    unsigned long long data_;
  };
  TraceID(const void* id, unsigned char* flags)
      : data_(static_cast<unsigned long long>(
              reinterpret_cast<uintptr_t>(id))) {
    *flags |= TRACE_EVENT_FLAG_MANGLE_ID;
  }
  TraceID(ForceMangle id, unsigned char* flags) : data_(id.data()) {
    *flags |= TRACE_EVENT_FLAG_MANGLE_ID;
  }
  TraceID(DontMangle id, unsigned char* flags) : data_(id.data()) {
  }
  TraceID(unsigned long long id, unsigned char* flags)
      : data_(id) { (void)flags; }
  TraceID(unsigned long id, unsigned char* flags)
      : data_(id) { (void)flags; }
  TraceID(unsigned int id, unsigned char* flags)
      : data_(id) { (void)flags; }
  TraceID(unsigned short id, unsigned char* flags)
      : data_(id) { (void)flags; }
  TraceID(unsigned char id, unsigned char* flags)
      : data_(id) { (void)flags; }
  TraceID(long long id, unsigned char* flags)
      : data_(static_cast<unsigned long long>(id)) { (void)flags; }
  TraceID(long id, unsigned char* flags)
      : data_(static_cast<unsigned long long>(id)) { (void)flags; }
  TraceID(int id, unsigned char* flags)
      : data_(static_cast<unsigned long long>(id)) { (void)flags; }
  TraceID(short id, unsigned char* flags)
      : data_(static_cast<unsigned long long>(id)) { (void)flags; }
  TraceID(signed char id, unsigned char* flags)
      : data_(static_cast<unsigned long long>(id)) { (void)flags; }

  unsigned long long data() const { return data_; }

 private:
  unsigned long long data_;
};

// Simple union to store various types as unsigned long long.
union TraceValueUnion {
  bool as_bool;
  unsigned long long as_uint;
  long long as_int;
  double as_double;
  const void* as_pointer;
  const char* as_string;
};

// Simple container for const char* that should be copied instead of retained.
class TraceStringWithCopy {
 public:
  explicit TraceStringWithCopy(const char* str) : str_(str) {}
  const char* str() const { return str_; }
 private:
  const char* str_;
};

// Define SetTraceValue for each allowed type. It stores the type and
// value in the return arguments. This allows this API to avoid declaring any
// structures so that it is portable to third_party libraries.
#define INTERNAL_DECLARE_SET_TRACE_VALUE(actual_type, \
                                         arg_expression, \
                                         union_member, \
                                         value_type_id) \
    static inline void SetTraceValue( \
        actual_type arg, \
        unsigned char* type, \
        unsigned long long* value) { \
      TraceValueUnion type_value; \
      type_value.union_member = arg_expression; \
      *type = value_type_id; \
      *value = type_value.as_uint; \
    }
// Simpler form for int types that can be safely casted.
#define INTERNAL_DECLARE_SET_TRACE_VALUE_INT(actual_type, \
                                             value_type_id) \
    static inline void SetTraceValue( \
        actual_type arg, \
        unsigned char* type, \
        unsigned long long* value) { \
      *type = value_type_id; \
      *value = static_cast<unsigned long long>(arg); \
    }

INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned long long, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned long, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned int, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned short, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned char, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(long long, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(long, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(int, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(short, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(signed char, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE(bool, arg, as_bool, TRACE_VALUE_TYPE_BOOL)
INTERNAL_DECLARE_SET_TRACE_VALUE(double, arg, as_double,
                                 TRACE_VALUE_TYPE_DOUBLE)
INTERNAL_DECLARE_SET_TRACE_VALUE(const void*, arg, as_pointer,
                                 TRACE_VALUE_TYPE_POINTER)
INTERNAL_DECLARE_SET_TRACE_VALUE(const char*, arg, as_string,
                                 TRACE_VALUE_TYPE_STRING)
INTERNAL_DECLARE_SET_TRACE_VALUE(const TraceStringWithCopy&, arg.str(),
                                 as_string, TRACE_VALUE_TYPE_COPY_STRING)

#undef INTERNAL_DECLARE_SET_TRACE_VALUE
#undef INTERNAL_DECLARE_SET_TRACE_VALUE_INT

// std::string version of SetTraceValue so that trace arguments can be strings.
static inline void SetTraceValue(const std::string& arg,
                                 unsigned char* type,
                                 unsigned long long* value) {
  TraceValueUnion type_value;
  type_value.as_string = arg.c_str();
  *type = TRACE_VALUE_TYPE_COPY_STRING;
  *value = type_value.as_uint;
}

// base::Time, base::TimeTicks, etc. versions of SetTraceValue to make it easier
// to trace these types.
static inline void SetTraceValue(const base::Time arg,
                                 unsigned char* type,
                                 unsigned long long* value) {
  *type = TRACE_VALUE_TYPE_INT;
  *value = arg.ToInternalValue();
}

static inline void SetTraceValue(const base::TimeTicks arg,
                                 unsigned char* type,
                                 unsigned long long* value) {
  *type = TRACE_VALUE_TYPE_INT;
  *value = arg.ToInternalValue();
}

static inline void SetTraceValue(const base::ThreadTicks arg,
                                 unsigned char* type,
                                 unsigned long long* value) {
  *type = TRACE_VALUE_TYPE_INT;
  *value = arg.ToInternalValue();
}

static inline void SetTraceValue(const base::TraceTicks arg,
                                 unsigned char* type,
                                 unsigned long long* value) {
  *type = TRACE_VALUE_TYPE_INT;
  *value = arg.ToInternalValue();
}

// These AddTraceEvent and AddTraceEventWithThreadIdAndTimestamp template
// functions are defined here instead of in the macro, because the arg_values
// could be temporary objects, such as std::string. In order to store
// pointers to the internal c_str and pass through to the tracing API,
// the arg_values must live throughout these procedures.

static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags,
    const char* arg1_name,
    const scoped_refptr<base::trace_event::ConvertableToTraceFormat>&
        arg1_val) {
  const int num_args = 1;
  unsigned char arg_types[1] = { TRACE_VALUE_TYPE_CONVERTABLE };
  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      num_args, &arg1_name, arg_types, NULL, &arg1_val, flags);
}

template<class ARG1_TYPE>
static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags,
    const char* arg1_name,
    const ARG1_TYPE& arg1_val,
    const char* arg2_name,
    const scoped_refptr<base::trace_event::ConvertableToTraceFormat>&
        arg2_val) {
  const int num_args = 2;
  const char* arg_names[2] = { arg1_name, arg2_name };

  unsigned char arg_types[2];
  unsigned long long arg_values[2];
  SetTraceValue(arg1_val, &arg_types[0], &arg_values[0]);
  arg_types[1] = TRACE_VALUE_TYPE_CONVERTABLE;

  scoped_refptr<base::trace_event::ConvertableToTraceFormat>
      convertable_values[2];
  convertable_values[1] = arg2_val;

  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      num_args, arg_names, arg_types, arg_values, convertable_values, flags);
}

template<class ARG2_TYPE>
static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags,
    const char* arg1_name,
    const scoped_refptr<base::trace_event::ConvertableToTraceFormat>& arg1_val,
    const char* arg2_name,
    const ARG2_TYPE& arg2_val) {
  const int num_args = 2;
  const char* arg_names[2] = { arg1_name, arg2_name };

  unsigned char arg_types[2];
  unsigned long long arg_values[2];
  arg_types[0] = TRACE_VALUE_TYPE_CONVERTABLE;
  arg_values[0] = 0;
  SetTraceValue(arg2_val, &arg_types[1], &arg_values[1]);

  scoped_refptr<base::trace_event::ConvertableToTraceFormat>
      convertable_values[2];
  convertable_values[0] = arg1_val;

  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      num_args, arg_names, arg_types, arg_values, convertable_values, flags);
}

static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags,
    const char* arg1_name,
    const scoped_refptr<base::trace_event::ConvertableToTraceFormat>& arg1_val,
    const char* arg2_name,
    const scoped_refptr<base::trace_event::ConvertableToTraceFormat>&
        arg2_val) {
  const int num_args = 2;
  const char* arg_names[2] = { arg1_name, arg2_name };
  unsigned char arg_types[2] =
      { TRACE_VALUE_TYPE_CONVERTABLE, TRACE_VALUE_TYPE_CONVERTABLE };
  scoped_refptr<base::trace_event::ConvertableToTraceFormat>
      convertable_values[2] = {arg1_val, arg2_val};

  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      num_args, arg_names, arg_types, NULL, convertable_values, flags);
}

static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags) {
  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      kZeroNumArgs, NULL, NULL, NULL, NULL, flags);
}

static inline base::trace_event::TraceEventHandle AddTraceEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    unsigned char flags) {
  const int thread_id = static_cast<int>(base::PlatformThread::CurrentId());
  const base::TraceTicks now = base::TraceTicks::Now();
  return AddTraceEventWithThreadIdAndTimestamp(phase, category_group_enabled,
                                               name, id, thread_id, now, flags);
}

template<class ARG1_TYPE>
static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags,
    const char* arg1_name,
    const ARG1_TYPE& arg1_val) {
  const int num_args = 1;
  unsigned char arg_types[1];
  unsigned long long arg_values[1];
  SetTraceValue(arg1_val, &arg_types[0], &arg_values[0]);
  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      num_args, &arg1_name, arg_types, arg_values, NULL, flags);
}

template<class ARG1_TYPE>
static inline base::trace_event::TraceEventHandle AddTraceEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    unsigned char flags,
    const char* arg1_name,
    const ARG1_TYPE& arg1_val) {
  int thread_id = static_cast<int>(base::PlatformThread::CurrentId());
  base::TraceTicks now = base::TraceTicks::Now();
  return AddTraceEventWithThreadIdAndTimestamp(phase, category_group_enabled,
                                               name, id, thread_id, now, flags,
                                               arg1_name, arg1_val);
}

template<class ARG1_TYPE, class ARG2_TYPE>
static inline base::trace_event::TraceEventHandle
AddTraceEventWithThreadIdAndTimestamp(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    int thread_id,
    const base::TraceTicks& timestamp,
    unsigned char flags,
    const char* arg1_name,
    const ARG1_TYPE& arg1_val,
    const char* arg2_name,
    const ARG2_TYPE& arg2_val) {
  const int num_args = 2;
  const char* arg_names[2] = { arg1_name, arg2_name };
  unsigned char arg_types[2];
  unsigned long long arg_values[2];
  SetTraceValue(arg1_val, &arg_types[0], &arg_values[0]);
  SetTraceValue(arg2_val, &arg_types[1], &arg_values[1]);
  return TRACE_EVENT_API_ADD_TRACE_EVENT_WITH_THREAD_ID_AND_TIMESTAMP(
      phase, category_group_enabled, name, id, thread_id, timestamp,
      num_args, arg_names, arg_types, arg_values, NULL, flags);
}

template<class ARG1_TYPE, class ARG2_TYPE>
static inline base::trace_event::TraceEventHandle AddTraceEvent(
    char phase,
    const unsigned char* category_group_enabled,
    const char* name,
    unsigned long long id,
    unsigned char flags,
    const char* arg1_name,
    const ARG1_TYPE& arg1_val,
    const char* arg2_name,
    const ARG2_TYPE& arg2_val) {
  int thread_id = static_cast<int>(base::PlatformThread::CurrentId());
  base::TraceTicks now = base::TraceTicks::Now();
  return AddTraceEventWithThreadIdAndTimestamp(phase, category_group_enabled,
                                               name, id, thread_id, now, flags,
                                               arg1_name, arg1_val,
                                               arg2_name, arg2_val);
}

// Used by TRACE_EVENTx macros. Do not use directly.
class TRACE_EVENT_API_CLASS_EXPORT ScopedTracer {
 public:
  // Note: members of data_ intentionally left uninitialized. See Initialize.
  ScopedTracer() : p_data_(NULL) {}

  ~ScopedTracer() {
    if (p_data_ && *data_.category_group_enabled)
      TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(
          data_.category_group_enabled, data_.name, data_.event_handle);
  }

  void Initialize(const unsigned char* category_group_enabled,
                  const char* name,
                  base::trace_event::TraceEventHandle event_handle) {
    data_.category_group_enabled = category_group_enabled;
    data_.name = name;
    data_.event_handle = event_handle;
    p_data_ = &data_;
  }

 private:
  // This Data struct workaround is to avoid initializing all the members
  // in Data during construction of this object, since this object is always
  // constructed, even when tracing is disabled. If the members of Data were
  // members of this class instead, compiler warnings occur about potential
  // uninitialized accesses.
  struct Data {
    const unsigned char* category_group_enabled;
    const char* name;
    base::trace_event::TraceEventHandle event_handle;
  };
  Data* p_data_;
  Data data_;
};

// Used by TRACE_EVENT_BINARY_EFFICIENTx macro. Do not use directly.
class TRACE_EVENT_API_CLASS_EXPORT ScopedTraceBinaryEfficient {
 public:
  ScopedTraceBinaryEfficient(const char* category_group, const char* name);
  ~ScopedTraceBinaryEfficient();

 private:
  const unsigned char* category_group_enabled_;
  const char* name_;
  base::trace_event::TraceEventHandle event_handle_;
};

// This macro generates less code then TRACE_EVENT0 but is also
// slower to execute when tracing is off. It should generally only be
// used with code that is seldom executed or conditionally executed
// when debugging.
// For now the category_group must be "gpu".
#define TRACE_EVENT_BINARY_EFFICIENT0(category_group, name) \
    trace_event_internal::ScopedTraceBinaryEfficient \
        INTERNAL_TRACE_EVENT_UID(scoped_trace)(category_group, name);

// TraceEventSamplingStateScope records the current sampling state
// and sets a new sampling state. When the scope exists, it restores
// the sampling state having recorded.
template<size_t BucketNumber>
class TraceEventSamplingStateScope {
 public:
  TraceEventSamplingStateScope(const char* category_and_name) {
    previous_state_ = TraceEventSamplingStateScope<BucketNumber>::Current();
    TraceEventSamplingStateScope<BucketNumber>::Set(category_and_name);
  }

  ~TraceEventSamplingStateScope() {
    TraceEventSamplingStateScope<BucketNumber>::Set(previous_state_);
  }

  static inline const char* Current() {
    return reinterpret_cast<const char*>(TRACE_EVENT_API_ATOMIC_LOAD(
      g_trace_state[BucketNumber]));
  }

  static inline void Set(const char* category_and_name) {
    TRACE_EVENT_API_ATOMIC_STORE(
      g_trace_state[BucketNumber],
      reinterpret_cast<TRACE_EVENT_API_ATOMIC_WORD>(
        const_cast<char*>(category_and_name)));
  }

 private:
  const char* previous_state_;
};

}  // namespace trace_event_internal

namespace base {
namespace trace_event {

template<typename IDType> class TraceScopedTrackableObject {
 public:
  TraceScopedTrackableObject(const char* category_group, const char* name,
      IDType id)
    : category_group_(category_group),
      name_(name),
      id_(id) {
    TRACE_EVENT_OBJECT_CREATED_WITH_ID(category_group_, name_, id_);
  }

  template <typename ArgType> void snapshot(ArgType snapshot) {
    TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(category_group_, name_, id_, snapshot);
  }

  ~TraceScopedTrackableObject() {
    TRACE_EVENT_OBJECT_DELETED_WITH_ID(category_group_, name_, id_);
  }

 private:
  const char* category_group_;
  const char* name_;
  IDType id_;

  DISALLOW_COPY_AND_ASSIGN(TraceScopedTrackableObject);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_TRACE_EVENT_H_

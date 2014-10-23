/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// Trace events are for tracking application performance and resource usage.
// Macros are provided to track:
//    Begin and end of function calls
//    Counters
//
// Events are issued against categories. Whereas LOG's
// categories are statically defined, TRACE categories are created
// implicitly with a string. For example:
//   TRACE_EVENT_INSTANT0("MY_SUBSYSTEM", "SomeImportantEvent")
//
// Events can be INSTANT, or can be pairs of BEGIN and END in the same scope:
//   TRACE_EVENT_BEGIN0("MY_SUBSYSTEM", "SomethingCostly")
//   doSomethingCostly()
//   TRACE_EVENT_END0("MY_SUBSYSTEM", "SomethingCostly")
// Note: our tools can't always determine the correct BEGIN/END pairs unless
// these are used in the same scope. Use ASYNC_BEGIN/ASYNC_END macros if you need them
// to be in separate scopes.
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
// To trace an asynchronous procedure such as an IPC send/receive, use ASYNC_BEGIN and
// ASYNC_END:
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
// ASYNC_BEGIN and ASYNC_END can occur on any thread of any traced process. Pointers can
// be used for the ID parameter, and they will be mangled internally so that
// the same pointer on two different processes will not match. For example:
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
// Since counters are in a global namespace, you may want to disembiguate with a
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
// in for category, name, and arg_names. Thus, the following code will
// cause problems:
//     char* str = strdup("impprtantName");
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
// Then the category_enabled flag is checked. This is a unsigned char, and
// not intended to be multithread safe. It optimizes access to addTraceEvent
// which is threadsafe internally via TraceLog::lock_. The enabled flag may
// cause some threads to incorrectly call or skip calling addTraceEvent near
// the time of the system being enabled or disabled. This is acceptable as
// we tolerate some data loss while the system is being enabled/disabled and
// because addTraceEvent is threadsafe internally and checks the enabled state
// again under lock.
//
// Without the use of these static category pointers and enabled flags all
// trace points would carry a significant performance cost of aquiring a lock
// and resolving the category.

#ifndef TraceEvent_h
#define TraceEvent_h

#include "platform/EventTracer.h"

#include "wtf/DynamicAnnotations.h"
#include "wtf/PassRefPtr.h"
#include "wtf/text/CString.h"

// By default, const char* argument values are assumed to have long-lived scope
// and will not be copied. Use this macro to force a const char* to be copied.
#define TRACE_STR_COPY(str) \
    blink::TraceEvent::TraceStringWithCopy(str)

// By default, uint64 ID argument values are not mangled with the Process ID in
// TRACE_EVENT_ASYNC macros. Use this macro to force Process ID mangling.
#define TRACE_ID_MANGLE(id) \
    blink::TraceEvent::TraceID::ForceMangle(id)

// By default, pointers are mangled with the Process ID in TRACE_EVENT_ASYNC
// macros. Use this macro to prevent Process ID mangling.
#define TRACE_ID_DONT_MANGLE(id) \
    blink::TraceEvent::TraceID::DontMangle(id)

// Records a pair of begin and end events called "name" for the current
// scope, with 0, 1 or 2 associated arguments. If the category is not
// enabled, then this does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT0(category, name) \
    INTERNAL_TRACE_EVENT_ADD_SCOPED(category, name)
#define TRACE_EVENT1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_SCOPED(category, name, arg1_name, arg1_val)
#define TRACE_EVENT2(category, name, arg1_name, arg1_val, arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_SCOPED(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Records a single event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT_INSTANT0(category, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category, name, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_INSTANT1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_INSTANT2(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)
#define TRACE_EVENT_COPY_INSTANT0(category, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category, name, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_INSTANT1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_INSTANT2(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_INSTANT, \
        category, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Records a single BEGIN event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT_BEGIN0(category, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category, name, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_BEGIN1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_BEGIN2(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)
#define TRACE_EVENT_COPY_BEGIN0(category, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category, name, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_BEGIN1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_BEGIN2(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_BEGIN, \
        category, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Records a single END event for "name" immediately. If the category
// is not enabled, then this does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_EVENT_END0(category, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category, name, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_END1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_END2(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category, name, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val, \
        arg2_name, arg2_val)
#define TRACE_EVENT_COPY_END0(category, name) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category, name, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_END1(category, name, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val)
#define TRACE_EVENT_COPY_END2(category, name, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_END, \
        category, name, TRACE_EVENT_FLAG_COPY, arg1_name, arg1_val, \
        arg2_name, arg2_val)

// Records the value of a counter called "name" immediately. Value
// must be representable as a 32 bit integer.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_COUNTER1(category, name, value) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category, name, TRACE_EVENT_FLAG_NONE, \
        "value", static_cast<int>(value))
#define TRACE_COPY_COUNTER1(category, name, value) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category, name, TRACE_EVENT_FLAG_COPY, \
        "value", static_cast<int>(value))

// Records the values of a multi-parted counter called "name" immediately.
// The UI will treat value1 and value2 as parts of a whole, displaying their
// values as a stacked-bar chart.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
#define TRACE_COUNTER2(category, name, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category, name, TRACE_EVENT_FLAG_NONE, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))
#define TRACE_COPY_COUNTER2(category, name, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD(TRACE_EVENT_PHASE_COUNTER, \
        category, name, TRACE_EVENT_FLAG_COPY, \
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
#define TRACE_COUNTER_ID1(category, name, id, value) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category, name, id, TRACE_EVENT_FLAG_NONE, \
        "value", static_cast<int>(value))
#define TRACE_COPY_COUNTER_ID1(category, name, id, value) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category, name, id, TRACE_EVENT_FLAG_COPY, \
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
#define TRACE_COUNTER_ID2(category, name, id, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category, name, id, TRACE_EVENT_FLAG_NONE, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))
#define TRACE_COPY_COUNTER_ID2(category, name, id, value1_name, value1_val, \
        value2_name, value2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_COUNTER, \
        category, name, id, TRACE_EVENT_FLAG_COPY, \
        value1_name, static_cast<int>(value1_val), \
        value2_name, static_cast<int>(value2_val))

// Records a single ASYNC_BEGIN event called "name" immediately, with 0, 1 or 2
// associated arguments. If the category is not enabled, then this
// does nothing.
// - category and name strings must have application lifetime (statics or
//   literals). They may not include " chars.
// - |id| is used to match the ASYNC_BEGIN event with the ASYNC_END event. ASYNC
//   events are considered to match if their category, name and id values all
//   match. |id| must either be a pointer or an integer value up to 64 bits. If
//   it's a pointer, the bits will be xored with a hash of the process ID so
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
#define TRACE_EVENT_ASYNC_BEGIN0(category, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_ASYNC_BEGIN1(category, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_ASYNC_BEGIN2(category, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category, name, id, TRACE_EVENT_FLAG_NONE, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_ASYNC_BEGIN0(category, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category, name, id, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_ASYNC_BEGIN1(category, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_ASYNC_BEGIN2(category, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_BEGIN, \
        category, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Records a single ASYNC_STEP_INTO event for |step| immediately. If the
// category is not enabled, then this does nothing. The |name| and |id| must
// match the ASYNC_BEGIN event above. The |step| param identifies this step
// within the async event. This should be called at the beginning of the next
// phase of an asynchronous operation. The ASYNC_BEGIN event must not have any
// ASYNC_STEP_PAST events.
#define TRACE_EVENT_ASYNC_STEP_INTO0(category, name, id, step) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_INTO, \
        category, name, id, TRACE_EVENT_FLAG_NONE, "step", step)
#define TRACE_EVENT_ASYNC_STEP_INTO1(category, name, id, step, \
        arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_INTO, \
        category, name, id, TRACE_EVENT_FLAG_NONE, "step", step, \
        arg1_name, arg1_val)

// Records a single ASYNC_STEP_PAST event for |step| immediately. If the
// category is not enabled, then this does nothing. The |name| and |id| must
// match the ASYNC_BEGIN event above. The |step| param identifies this step
// within the async event. This should be called at the beginning of the next
// phase of an asynchronous operation. The ASYNC_BEGIN event must not have any
// ASYNC_STEP_INTO events.
#define TRACE_EVENT_ASYNC_STEP_PAST0(category_group, name, id, step) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_PAST, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step)
#define TRACE_EVENT_ASYNC_STEP_PAST1(category_group, name, id, step, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_STEP_PAST, \
        category_group, name, id, TRACE_EVENT_FLAG_NONE, "step", step, \
        arg1_name, arg1_val)

// Records a single ASYNC_END event for "name" immediately. If the category
// is not enabled, then this does nothing.
#define TRACE_EVENT_ASYNC_END0(category, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category, name, id, TRACE_EVENT_FLAG_NONE)
#define TRACE_EVENT_ASYNC_END1(category, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category, name, id, TRACE_EVENT_FLAG_NONE, arg1_name, arg1_val)
#define TRACE_EVENT_ASYNC_END2(category, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category, name, id, TRACE_EVENT_FLAG_NONE, \
        arg1_name, arg1_val, arg2_name, arg2_val)
#define TRACE_EVENT_COPY_ASYNC_END0(category, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category, name, id, TRACE_EVENT_FLAG_COPY)
#define TRACE_EVENT_COPY_ASYNC_END1(category, name, id, arg1_name, arg1_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val)
#define TRACE_EVENT_COPY_ASYNC_END2(category, name, id, arg1_name, arg1_val, \
        arg2_name, arg2_val) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_ASYNC_END, \
        category, name, id, TRACE_EVENT_FLAG_COPY, \
        arg1_name, arg1_val, arg2_name, arg2_val)

// Creates a scope of a sampling state with the given category and name (both must
// be constant strings). These states are intended for a sampling profiler.
// Implementation note: we store category and name together because we don't
// want the inconsistency/expense of storing two pointers.
// |thread_bucket| is [0..2] and is used to statically isolate samples in one
// thread from others.
//
// {  // The sampling state is set within this scope.
//    TRACE_EVENT_SAMPLING_STATE_SCOPE_FOR_BUCKET(0, "category", "name");
//    ...;
// }
#define TRACE_EVENT_SCOPED_SAMPLING_STATE_FOR_BUCKET(bucket_number, category, name) \
    TraceEvent::SamplingStateScope<bucket_number> traceEventSamplingScope(category "\0" name);

// Returns a current sampling state of the given bucket.
// The format of the returned string is "category\0name".
#define TRACE_EVENT_GET_SAMPLING_STATE_FOR_BUCKET(bucket_number) \
    TraceEvent::SamplingStateScope<bucket_number>::current()

// Sets a current sampling state of the given bucket.
// |category| and |name| have to be constant strings.
#define TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(bucket_number, category, name) \
    TraceEvent::SamplingStateScope<bucket_number>::set(category "\0" name)

// Sets a current sampling state of the given bucket.
// |categoryAndName| doesn't need to be a constant string.
// The format of the string is "category\0name".
#define TRACE_EVENT_SET_NONCONST_SAMPLING_STATE_FOR_BUCKET(bucket_number, categoryAndName) \
    TraceEvent::SamplingStateScope<bucket_number>::set(categoryAndName)

// Syntactic sugars for the sampling tracing in the main thread.
#define TRACE_EVENT_SCOPED_SAMPLING_STATE(category, name) \
    TRACE_EVENT_SCOPED_SAMPLING_STATE_FOR_BUCKET(0, category, name)
#define TRACE_EVENT_GET_SAMPLING_STATE() \
    TRACE_EVENT_GET_SAMPLING_STATE_FOR_BUCKET(0)
#define TRACE_EVENT_SET_SAMPLING_STATE(category, name) \
    TRACE_EVENT_SET_SAMPLING_STATE_FOR_BUCKET(0, category, name)
#define TRACE_EVENT_SET_NONCONST_SAMPLING_STATE(categoryAndName) \
    TRACE_EVENT_SET_NONCONST_SAMPLING_STATE_FOR_BUCKET(0, categoryAndName)

// Macros to track the life time and value of arbitrary client objects.
// See also TraceTrackableObject.
#define TRACE_EVENT_OBJECT_CREATED_WITH_ID(categoryGroup, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_CREATE_OBJECT, \
        categoryGroup, name, TRACE_ID_DONT_MANGLE(id), TRACE_EVENT_FLAG_NONE)

#define TRACE_EVENT_OBJECT_SNAPSHOT_WITH_ID(categoryGroup, name, id, snapshot) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_SNAPSHOT_OBJECT, \
        categoryGroup, name, TRACE_ID_DONT_MANGLE(id), TRACE_EVENT_FLAG_NONE, \
        "snapshot", snapshot)

#define TRACE_EVENT_OBJECT_DELETED_WITH_ID(categoryGroup, name, id) \
    INTERNAL_TRACE_EVENT_ADD_WITH_ID(TRACE_EVENT_PHASE_DELETE_OBJECT, \
        categoryGroup, name, TRACE_ID_DONT_MANGLE(id), TRACE_EVENT_FLAG_NONE)

// Macro to efficiently determine if a given category group is enabled.
#define TRACE_EVENT_CATEGORY_GROUP_ENABLED(categoryGroup, ret) \
    do { \
        INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(categoryGroup);  \
        if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
            *ret = true;                                        \
        } else {                                                \
            *ret = false;                                       \
        }                                                       \
    } while (0)

// This will mark the trace event as disabled by default. The user will need
// to explicitly enable the event.
#define TRACE_DISABLED_BY_DEFAULT(name) "disabled-by-default-" name

////////////////////////////////////////////////////////////////////////////////
// Implementation specific tracing API definitions.

// Get a pointer to the enabled state of the given trace category. Only
// long-lived literal strings should be given as the category name. The returned
// pointer can be held permanently in a local static for example. If the
// unsigned char is non-zero, tracing is enabled. If tracing is enabled,
// TRACE_EVENT_API_ADD_TRACE_EVENT can be called. It's OK if tracing is disabled
// between the load of the tracing state and the call to
// TRACE_EVENT_API_ADD_TRACE_EVENT, because this flag only provides an early out
// for best performance when tracing is disabled.
// const unsigned char*
//     TRACE_EVENT_API_GET_CATEGORY_ENABLED(const char* category_name)
#define TRACE_EVENT_API_GET_CATEGORY_ENABLED \
    blink::EventTracer::getTraceCategoryEnabledFlag

// Add a trace event to the platform tracing system.
// blink::TraceEvent::TraceEventHandle TRACE_EVENT_API_ADD_TRACE_EVENT(
//                    char phase,
//                    const unsigned char* category_enabled,
//                    const char* name,
//                    unsigned long long id,
//                    int num_args,
//                    const char** arg_names,
//                    const unsigned char* arg_types,
//                    const unsigned long long* arg_values,
//                    const RefPtr<ConvertableToTraceFormat>* convertableValues
//                    unsigned char flags)
#define TRACE_EVENT_API_ADD_TRACE_EVENT \
    blink::EventTracer::addTraceEvent

// Set the duration field of a COMPLETE trace event.
// void TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(
//     blink::TraceEvent::TraceEventHandle handle)
#define TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION \
    blink::EventTracer::updateTraceEventDuration

////////////////////////////////////////////////////////////////////////////////

// Implementation detail: trace event macros create temporary variables
// to keep instrumentation overhead low. These macros give each temporary
// variable a unique name based on the line number to prevent name collissions.
#define INTERNAL_TRACE_EVENT_UID3(a, b) \
    trace_event_unique_##a##b
#define INTERNAL_TRACE_EVENT_UID2(a, b) \
    INTERNAL_TRACE_EVENT_UID3(a, b)
#define INTERNALTRACEEVENTUID(name_prefix) \
    INTERNAL_TRACE_EVENT_UID2(name_prefix, __LINE__)

// Implementation detail: internal macro to create static category.
// - WTF_ANNOTATE_BENIGN_RACE, see Thread Safety above.

#define INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category) \
    static const unsigned char* INTERNALTRACEEVENTUID(categoryGroupEnabled) = 0; \
    WTF_ANNOTATE_BENIGN_RACE(&INTERNALTRACEEVENTUID(categoryGroupEnabled), \
                             "trace_event category"); \
    if (!INTERNALTRACEEVENTUID(categoryGroupEnabled)) { \
        INTERNALTRACEEVENTUID(categoryGroupEnabled) = \
            TRACE_EVENT_API_GET_CATEGORY_ENABLED(category); \
    }

// Implementation detail: internal macro to create static category and add
// event if the category is enabled.
#define INTERNAL_TRACE_EVENT_ADD(phase, category, name, flags, ...) \
    do { \
        INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category); \
        if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
            blink::TraceEvent::addTraceEvent( \
                phase, INTERNALTRACEEVENTUID(categoryGroupEnabled), name, \
                blink::TraceEvent::noEventId, flags, ##__VA_ARGS__); \
        } \
    } while (0)

// Implementation detail: internal macro to create static category and add begin
// event if the category is enabled. Also adds the end event when the scope
// ends.
#define INTERNAL_TRACE_EVENT_ADD_SCOPED(category, name, ...) \
    INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category); \
    blink::TraceEvent::ScopedTracer INTERNALTRACEEVENTUID(scopedTracer); \
    if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
        blink::TraceEvent::TraceEventHandle h = \
            blink::TraceEvent::addTraceEvent( \
                TRACE_EVENT_PHASE_COMPLETE, \
                INTERNALTRACEEVENTUID(categoryGroupEnabled), \
                name, blink::TraceEvent::noEventId, \
                TRACE_EVENT_FLAG_NONE, ##__VA_ARGS__); \
        INTERNALTRACEEVENTUID(scopedTracer).initialize( \
            INTERNALTRACEEVENTUID(categoryGroupEnabled), name, h); \
    }

// Implementation detail: internal macro to create static category and add
// event if the category is enabled.
#define INTERNAL_TRACE_EVENT_ADD_WITH_ID(phase, category, name, id, flags, \
                                         ...) \
    do { \
        INTERNAL_TRACE_EVENT_GET_CATEGORY_INFO(category); \
        if (INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE()) { \
            unsigned char traceEventFlags = flags | TRACE_EVENT_FLAG_HAS_ID; \
            blink::TraceEvent::TraceID traceEventTraceID( \
                id, &traceEventFlags); \
            blink::TraceEvent::addTraceEvent( \
                phase, INTERNALTRACEEVENTUID(categoryGroupEnabled), \
                name, traceEventTraceID.data(), traceEventFlags, \
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
#define TRACE_EVENT_PHASE_METADATA ('M')
#define TRACE_EVENT_PHASE_COUNTER  ('C')
#define TRACE_EVENT_PHASE_SAMPLE  ('P')
#define TRACE_EVENT_PHASE_CREATE_OBJECT ('N')
#define TRACE_EVENT_PHASE_SNAPSHOT_OBJECT ('O')
#define TRACE_EVENT_PHASE_DELETE_OBJECT ('D')

// Flags for changing the behavior of TRACE_EVENT_API_ADD_TRACE_EVENT.
#define TRACE_EVENT_FLAG_NONE        (static_cast<unsigned char>(0))
#define TRACE_EVENT_FLAG_COPY        (static_cast<unsigned char>(1 << 0))
#define TRACE_EVENT_FLAG_HAS_ID      (static_cast<unsigned char>(1 << 1))
#define TRACE_EVENT_FLAG_MANGLE_ID   (static_cast<unsigned char>(1 << 2))

// Type values for identifying types in the TraceValue union.
#define TRACE_VALUE_TYPE_BOOL         (static_cast<unsigned char>(1))
#define TRACE_VALUE_TYPE_UINT         (static_cast<unsigned char>(2))
#define TRACE_VALUE_TYPE_INT          (static_cast<unsigned char>(3))
#define TRACE_VALUE_TYPE_DOUBLE       (static_cast<unsigned char>(4))
#define TRACE_VALUE_TYPE_POINTER      (static_cast<unsigned char>(5))
#define TRACE_VALUE_TYPE_STRING       (static_cast<unsigned char>(6))
#define TRACE_VALUE_TYPE_COPY_STRING  (static_cast<unsigned char>(7))
#define TRACE_VALUE_TYPE_CONVERTABLE  (static_cast<unsigned char>(8))

// These values must be in sync with base::debug::TraceLog::CategoryGroupEnabledFlags.
#define ENABLED_FOR_RECORDING (1 << 0)
#define ENABLED_FOR_EVENT_CALLBACK (1 << 2)

#define INTERNAL_TRACE_EVENT_CATEGORY_GROUP_ENABLED_FOR_RECORDING_MODE() \
    (*INTERNALTRACEEVENTUID(categoryGroupEnabled) & (ENABLED_FOR_RECORDING | ENABLED_FOR_EVENT_CALLBACK))

namespace blink {

namespace TraceEvent {

// Specify these values when the corresponding argument of addTraceEvent is not
// used.
const int zeroNumArgs = 0;
const unsigned long long noEventId = 0;

// TraceID encapsulates an ID that can either be an integer or pointer. Pointers
// are mangled with the Process ID so that they are unlikely to collide when the
// same pointer is used on different processes.
class TraceID {
public:
    template<bool dummyMangle> class MangleBehavior {
    public:
        template<typename T> explicit MangleBehavior(T id) : m_data(reinterpret_cast<unsigned long long>(id)) { }
        unsigned long long data() const { return m_data; }
    private:
        unsigned long long m_data;
    };
    typedef MangleBehavior<false> DontMangle;
    typedef MangleBehavior<true> ForceMangle;

    TraceID(const void* id, unsigned char* flags) :
        m_data(static_cast<unsigned long long>(reinterpret_cast<unsigned long>(id)))
    {
        *flags |= TRACE_EVENT_FLAG_MANGLE_ID;
    }
    TraceID(ForceMangle id, unsigned char* flags) : m_data(id.data())
    {
        *flags |= TRACE_EVENT_FLAG_MANGLE_ID;
    }
    TraceID(DontMangle id, unsigned char*) : m_data(id.data()) { }
    TraceID(unsigned long long id, unsigned char*) : m_data(id) { }
    TraceID(unsigned long id, unsigned char*) : m_data(id) { }
    TraceID(unsigned id, unsigned char*) : m_data(id) { }
    TraceID(unsigned short id, unsigned char*) : m_data(id) { }
    TraceID(unsigned char id, unsigned char*) : m_data(id) { }
    TraceID(long long id, unsigned char*) :
        m_data(static_cast<unsigned long long>(id)) { }
    TraceID(long id, unsigned char*) :
        m_data(static_cast<unsigned long long>(id)) { }
    TraceID(int id, unsigned char*) :
        m_data(static_cast<unsigned long long>(id)) { }
    TraceID(short id, unsigned char*) :
        m_data(static_cast<unsigned long long>(id)) { }
    TraceID(signed char id, unsigned char*) :
        m_data(static_cast<unsigned long long>(id)) { }

    unsigned long long data() const { return m_data; }

private:
    unsigned long long m_data;
};

// Simple union to store various types as unsigned long long.
union TraceValueUnion {
    bool m_bool;
    unsigned long long m_uint;
    long long m_int;
    double m_double;
    const void* m_pointer;
    const char* m_string;
};

// Simple container for const char* that should be copied instead of retained.
class TraceStringWithCopy {
public:
    explicit TraceStringWithCopy(const char* str) : m_str(str) { }
    const char* str() const { return m_str; }
private:
    const char* m_str;
};

// Define setTraceValue for each allowed type. It stores the type and
// value in the return arguments. This allows this API to avoid declaring any
// structures so that it is portable to third_party libraries.
#define INTERNAL_DECLARE_SET_TRACE_VALUE(actualType, argExpression, unionMember, valueTypeId) \
    static inline void setTraceValue(actualType arg, unsigned char* type, unsigned long long* value) { \
        TraceValueUnion typeValue; \
        typeValue.unionMember = argExpression; \
        *type = valueTypeId; \
        *value = typeValue.m_uint; \
    }
// Simpler form for int types that can be safely casted.
#define INTERNAL_DECLARE_SET_TRACE_VALUE_INT(actualType, valueTypeId) \
    static inline void setTraceValue(actualType arg, \
                                     unsigned char* type, \
                                     unsigned long long* value) { \
        *type = valueTypeId; \
        *value = static_cast<unsigned long long>(arg); \
    }

INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned long long, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned short, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(unsigned char, TRACE_VALUE_TYPE_UINT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(long long, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(int, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(short, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE_INT(signed char, TRACE_VALUE_TYPE_INT)
INTERNAL_DECLARE_SET_TRACE_VALUE(bool, arg, m_bool, TRACE_VALUE_TYPE_BOOL)
INTERNAL_DECLARE_SET_TRACE_VALUE(double, arg, m_double, TRACE_VALUE_TYPE_DOUBLE)
INTERNAL_DECLARE_SET_TRACE_VALUE(const void*, arg, m_pointer, TRACE_VALUE_TYPE_POINTER)
INTERNAL_DECLARE_SET_TRACE_VALUE(const char*, arg, m_string, TRACE_VALUE_TYPE_STRING)
INTERNAL_DECLARE_SET_TRACE_VALUE(const TraceStringWithCopy&, arg.str(), m_string, TRACE_VALUE_TYPE_COPY_STRING)

#undef INTERNAL_DECLARE_SET_TRACE_VALUE
#undef INTERNAL_DECLARE_SET_TRACE_VALUE_INT

// WTF::String version of setTraceValue so that trace arguments can be strings.
static inline void setTraceValue(const WTF::CString& arg, unsigned char* type, unsigned long long* value)
{
    TraceValueUnion typeValue;
    typeValue.m_string = arg.data();
    *type = TRACE_VALUE_TYPE_COPY_STRING;
    *value = typeValue.m_uint;
}

static inline void setTraceValue(ConvertableToTraceFormat*, unsigned char* type, unsigned long long*)
{
    *type = TRACE_VALUE_TYPE_CONVERTABLE;
}

template<typename T> static inline void setTraceValue(const PassRefPtr<T>& ptr, unsigned char* type, unsigned long long* value)
{
    setTraceValue(ptr.get(), type, value);
}

template<typename T> struct ConvertableToTraceFormatTraits {
    static const bool isConvertable = false;
    static void assignIfConvertable(ConvertableToTraceFormat*& left, const T&)
    {
        left = 0;
    }
};

template<typename T> struct ConvertableToTraceFormatTraits<T*> {
    static const bool isConvertable = WTF::IsSubclass<T, TraceEvent::ConvertableToTraceFormat>::value;
    static void assignIfConvertable(ConvertableToTraceFormat*& left, ...)
    {
        left = 0;
    }
    static void assignIfConvertable(ConvertableToTraceFormat*& left, ConvertableToTraceFormat* const& right)
    {
        left = right;
    }
};

template<typename T> struct ConvertableToTraceFormatTraits<PassRefPtr<T> > {
    static const bool isConvertable = WTF::IsSubclass<T, TraceEvent::ConvertableToTraceFormat>::value;
    static void assignIfConvertable(ConvertableToTraceFormat*& left, const PassRefPtr<T>& right)
    {
        ConvertableToTraceFormatTraits<T*>::assignIfConvertable(left, right.get());
    }
};

template<typename T> bool isConvertableToTraceFormat(const T&)
{
    return ConvertableToTraceFormatTraits<T>::isConvertable;
}

template<typename T> void assignIfConvertableToTraceFormat(ConvertableToTraceFormat*& left, const T& right)
{
    ConvertableToTraceFormatTraits<T>::assignIfConvertable(left, right);
}

// These addTraceEvent template functions are defined here instead of in the
// macro, because the arg values could be temporary string objects. In order to
// store pointers to the internal c_str and pass through to the tracing API, the
// arg values must live throughout these procedures.

static inline TraceEventHandle addTraceEvent(
    char phase,
    const unsigned char* categoryEnabled,
    const char* name,
    unsigned long long id,
    unsigned char flags)
{
    return TRACE_EVENT_API_ADD_TRACE_EVENT(
        phase, categoryEnabled, name, id,
        zeroNumArgs, 0, 0, 0,
        flags);
}

template<typename ARG1_TYPE>
static inline TraceEventHandle addTraceEvent(
    char phase,
    const unsigned char* categoryEnabled,
    const char* name,
    unsigned long long id,
    unsigned char flags,
    const char* arg1Name,
    const ARG1_TYPE& arg1Val)
{
    const int numArgs = 1;
    unsigned char argTypes[1];
    unsigned long long argValues[1];
    setTraceValue(arg1Val, &argTypes[0], &argValues[0]);
    if (isConvertableToTraceFormat(arg1Val)) {
        ConvertableToTraceFormat* convertableValues[1];
        assignIfConvertableToTraceFormat(convertableValues[0], arg1Val);
        return TRACE_EVENT_API_ADD_TRACE_EVENT(
            phase, categoryEnabled, name, id,
            numArgs, &arg1Name, argTypes, argValues,
            convertableValues,
            flags);
    }
    return TRACE_EVENT_API_ADD_TRACE_EVENT(
        phase, categoryEnabled, name, id,
        numArgs, &arg1Name, argTypes, argValues,
        flags);
}

template<typename ARG1_TYPE, typename ARG2_TYPE>
static inline TraceEventHandle addTraceEvent(
    char phase,
    const unsigned char* categoryEnabled,
    const char* name,
    unsigned long long id,
    unsigned char flags,
    const char* arg1Name,
    const ARG1_TYPE& arg1Val,
    const char* arg2Name,
    const ARG2_TYPE& arg2Val)
{
    const int numArgs = 2;
    const char* argNames[2] = { arg1Name, arg2Name };
    unsigned char argTypes[2];
    unsigned long long argValues[2];
    setTraceValue(arg1Val, &argTypes[0], &argValues[0]);
    setTraceValue(arg2Val, &argTypes[1], &argValues[1]);
    if (isConvertableToTraceFormat(arg1Val) || isConvertableToTraceFormat(arg2Val)) {
        ConvertableToTraceFormat* convertableValues[2];
        assignIfConvertableToTraceFormat(convertableValues[0], arg1Val);
        assignIfConvertableToTraceFormat(convertableValues[1], arg2Val);
        return TRACE_EVENT_API_ADD_TRACE_EVENT(
            phase, categoryEnabled, name, id,
            numArgs, argNames, argTypes, argValues,
            convertableValues,
            flags);
    }
    return TRACE_EVENT_API_ADD_TRACE_EVENT(
        phase, categoryEnabled, name, id,
        numArgs, argNames, argTypes, argValues,
        flags);
}

// Used by TRACE_EVENTx macro. Do not use directly.
class ScopedTracer {
public:
    // Note: members of m_data intentionally left uninitialized. See initialize.
    ScopedTracer() : m_pdata(0) { }
    ~ScopedTracer()
    {
        if (m_pdata && *m_pdata->categoryGroupEnabled)
            TRACE_EVENT_API_UPDATE_TRACE_EVENT_DURATION(m_data.categoryGroupEnabled, m_data.name, m_data.eventHandle);
    }

    void initialize(const unsigned char* categoryGroupEnabled, const char* name, TraceEventHandle eventHandle)
    {
        m_data.categoryGroupEnabled = categoryGroupEnabled;
        m_data.name = name;
        m_data.eventHandle = eventHandle;
        m_pdata = &m_data;
    }

private:
    // This Data struct workaround is to avoid initializing all the members
    // in Data during construction of this object, since this object is always
    // constructed, even when tracing is disabled. If the members of Data were
    // members of this class instead, compiler warnings occur about potential
    // uninitialized accesses.
    struct Data {
        const unsigned char* categoryGroupEnabled;
        const char* name;
        TraceEventHandle eventHandle;
    };
    Data* m_pdata;
    Data m_data;
};

// TraceEventSamplingStateScope records the current sampling state
// and sets a new sampling state. When the scope exists, it restores
// the sampling state having recorded.
template<size_t BucketNumber>
class SamplingStateScope {
    WTF_MAKE_FAST_ALLOCATED;
public:
    SamplingStateScope(const char* categoryAndName)
    {
        m_previousState = SamplingStateScope<BucketNumber>::current();
        SamplingStateScope<BucketNumber>::set(categoryAndName);
    }

    ~SamplingStateScope()
    {
        SamplingStateScope<BucketNumber>::set(m_previousState);
    }

    // FIXME: Make load/store to traceSamplingState[] thread-safe and atomic.
    static inline const char* current()
    {
        return reinterpret_cast<const char*>(*blink::traceSamplingState[BucketNumber]);
    }
    static inline void set(const char* categoryAndName)
    {
        *blink::traceSamplingState[BucketNumber] = reinterpret_cast<long>(const_cast<char*>(categoryAndName));
    }

private:
    const char* m_previousState;
};

template<typename IDType> class TraceScopedTrackableObject {
    WTF_MAKE_NONCOPYABLE(TraceScopedTrackableObject);
public:
    TraceScopedTrackableObject(const char* categoryGroup, const char* name, IDType id)
        : m_categoryGroup(categoryGroup), m_name(name), m_id(id)
    {
        TRACE_EVENT_OBJECT_CREATED_WITH_ID(m_categoryGroup, m_name, m_id);
    }

    ~TraceScopedTrackableObject()
    {
        TRACE_EVENT_OBJECT_DELETED_WITH_ID(m_categoryGroup, m_name, m_id);
    }

private:
    const char* m_categoryGroup;
    const char* m_name;
    IDType m_id;
};

} // namespace TraceEvent

} // namespace blink

#endif

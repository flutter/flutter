// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_INCLUDE_DART_TOOLS_API_H_
#define RUNTIME_INCLUDE_DART_TOOLS_API_H_

#include "dart_api.h" /* NOLINT */

/** \mainpage Dart Tools Embedding API Reference
 *
 * This reference describes the Dart embedding API for tools. Tools include
 * a debugger, service protocol, and timeline.
 *
 * NOTE: The APIs described in this file are unstable and subject to change.
 *
 * This reference is generated from the header include/dart_tools_api.h.
 */

/*
 * ========
 * Debugger
 * ========
 */

/**
 * ILLEGAL_ISOLATE_ID is a number guaranteed never to be associated with a
 * valid isolate.
 */
#define ILLEGAL_ISOLATE_ID ILLEGAL_PORT

/**
 * ILLEGAL_ISOLATE_GROUP_ID is a number guaranteed never to be associated with a
 * valid isolate group.
 */
#define ILLEGAL_ISOLATE_GROUP_ID 0

/*
 * =======
 * Service
 * =======
 */

/**
 * A service request callback function.
 *
 * These callbacks, registered by the embedder, are called when the VM receives
 * a service request it can't handle and the service request command name
 * matches one of the embedder registered handlers.
 *
 * The return value of the callback indicates whether the response
 * should be used as a regular result or an error result.
 * Specifically, if the callback returns true, a regular JSON-RPC
 * response is built in the following way:
 *
 * {
 *   "jsonrpc": "2.0",
 *   "result": <json_object>,
 *   "id": <some sequence id>,
 * }
 *
 * If the callback returns false, a JSON-RPC error is built like this:
 *
 * {
 *   "jsonrpc": "2.0",
 *   "error": <json_object>,
 *   "id": <some sequence id>,
 * }
 *
 * \param method The rpc method name.
 * \param param_keys Service requests can have key-value pair parameters. The
 *   keys and values are flattened and stored in arrays.
 * \param param_values The values associated with the keys.
 * \param num_params The length of the param_keys and param_values arrays.
 * \param user_data The user_data pointer registered with this handler.
 * \param result A C string containing a valid JSON object. The returned
 *   pointer will be freed by the VM by calling free.
 *
 * \return True if the result is a regular JSON-RPC response, false if the
 *   result is a JSON-RPC error.
 */
typedef bool (*Dart_ServiceRequestCallback)(const char* method,
                                            const char** param_keys,
                                            const char** param_values,
                                            intptr_t num_params,
                                            void* user_data,
                                            const char** json_object);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc on a specific isolate. The callback will
 * be invoked with the current isolate set to the request target.
 *
 * \param method The name of the method that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterIsolateServiceRequestCallback(
    const char* method,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc. The callback will be invoked without a
 * current isolate.
 *
 * \param method The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks with the same name are registered, only
 * the last callback registered will be remembered.
 */
DART_EXPORT void Dart_RegisterRootServiceRequestCallback(
    const char* method,
    Dart_ServiceRequestCallback callback,
    void* user_data);

/**
 * Embedder information which can be requested by the VM for internal or
 * reporting purposes.
 *
 * The pointers in this structure are not going to be cached or freed by the VM.
 */

#define DART_EMBEDDER_INFORMATION_CURRENT_VERSION (0x00000001)

typedef struct {
  int32_t version;
  const char* name;     // [optional] The name of the embedder
  int64_t current_rss;  // [optional] the current RSS of the embedder
  int64_t max_rss;      // [optional] the maximum RSS of the embedder
} Dart_EmbedderInformation;

/**
 * Callback provided by the embedder that is used by the VM to request
 * information.
 *
 * \return Returns a pointer to a Dart_EmbedderInformation structure.
 * The embedder keeps the ownership of the structure and any field in it.
 * The embedder must ensure that the structure will remain valid until the
 * next invocation of the callback.
 */
typedef void (*Dart_EmbedderInformationCallback)(
    Dart_EmbedderInformation* info);

/**
 * Register a Dart_ServiceRequestCallback to be called to handle
 * requests for the named rpc. The callback will be invoked without a
 * current isolate.
 *
 * \param method The name of the command that this callback is responsible for.
 * \param callback The callback to invoke.
 * \param user_data The user data passed to the callback.
 *
 * NOTE: If multiple callbacks are registered, only the last callback registered
 * will be remembered.
 */
DART_EXPORT void Dart_SetEmbedderInformationCallback(
    Dart_EmbedderInformationCallback callback);

/**
 * Invoke a vm-service method and wait for its result.
 *
 * \param request_json The utf8-encoded json-rpc request.
 * \param request_json_length The length of the json-rpc request.
 *
 * \param response_json The returned utf8-encoded json response, must be
 *   free()ed by caller.
 * \param response_json_length The length of the returned json response.
 * \param error An optional error, must be free()ed by caller.
 *
 * \return Whether the call was successfully performed.
 *
 * NOTE: This method does not need a current isolate and must not have the
 * vm-isolate being the current isolate. It must be called after
 * Dart_Initialize() and before Dart_Cleanup().
 */
DART_EXPORT bool Dart_InvokeVMServiceMethod(uint8_t* request_json,
                                            intptr_t request_json_length,
                                            uint8_t** response_json,
                                            intptr_t* response_json_length,
                                            char** error);

/*
 * ========
 * Event Streams
 * ========
 */

/**
 * A callback invoked when the VM service gets a request to listen to
 * some stream.
 *
 * \return Returns true iff the embedder supports the named stream id.
 */
typedef bool (*Dart_ServiceStreamListenCallback)(const char* stream_id);

/**
 * A callback invoked when the VM service gets a request to cancel
 * some stream.
 */
typedef void (*Dart_ServiceStreamCancelCallback)(const char* stream_id);

/**
 * Adds VM service stream callbacks.
 *
 * \param listen_callback A function pointer to a listen callback function.
 *   A listen callback function should not be already set when this function
 *   is called. A NULL value removes the existing listen callback function
 *   if any.
 *
 * \param cancel_callback A function pointer to a cancel callback function.
 *   A cancel callback function should not be already set when this function
 *   is called. A NULL value removes the existing cancel callback function
 *   if any.
 *
 * \return Success if the callbacks were added.  Otherwise, returns an
 *   error handle.
 */
DART_EXPORT char* Dart_SetServiceStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback);

/**
 * Sends a data event to clients of the VM Service.
 *
 * A data event is used to pass an array of bytes to subscribed VM
 * Service clients.  For example, in the standalone embedder, this is
 * function used to provide WriteEvents on the Stdout and Stderr
 * streams.
 *
 * If the embedder passes in a stream id for which no client is
 * subscribed, then the event is ignored.
 *
 * \param stream_id The id of the stream on which to post the event.
 *
 * \param event_kind A string identifying what kind of event this is.
 *   For example, 'WriteEvent'.
 *
 * \param bytes A pointer to an array of bytes.
 *
 * \param bytes_length The length of the byte array.
 *
 * \return NULL if the arguments are well formed.  Otherwise, returns an
 *   error string. The caller is responsible for freeing the error message.
 */
DART_EXPORT char* Dart_ServiceSendDataEvent(const char* stream_id,
                                            const char* event_kind,
                                            const uint8_t* bytes,
                                            intptr_t bytes_length);

/*
 * ========
 * Reload support
 * ========
 *
 * These functions are used to implement reloading in the Dart VM.
 * This is an experimental feature, so embedders should be prepared
 * for these functions to change.
 */

/**
 * A callback which determines whether the file at some url has been
 * modified since some time.  If the file cannot be found, true should
 * be returned.
 */
typedef bool (*Dart_FileModifiedCallback)(const char* url, int64_t since);

DART_EXPORT char* Dart_SetFileModifiedCallback(
    Dart_FileModifiedCallback file_modified_callback);

/**
 * Returns true if isolate is currently reloading.
 */
DART_EXPORT bool Dart_IsReloading();

/*
 * ========
 * Timeline
 * ========
 */

/**
 * Enable tracking of specified timeline category. This is operational
 * only when systrace timeline functionality is turned on.
 *
 * \param categories A comma separated list of categories that need to
 *   be enabled, the categories are
 *   "all" : All categories
 *   "API" - Execution of Dart C API functions
 *   "Compiler" - Execution of Dart JIT compiler
 *   "CompilerVerbose" - More detailed Execution of Dart JIT compiler
 *   "Dart" - Execution of Dart code
 *   "Debugger" - Execution of Dart debugger
 *   "Embedder" - Execution of Dart embedder code
 *   "GC" - Execution of Dart Garbage Collector
 *   "Isolate" - Dart Isolate lifecycle execution
 *   "VM" - Execution in Dart VM runtime code
 *   "" - None
 *
 *  When "all" is specified all the categories are enabled.
 *  When a comma separated list of categories is specified, the categories
 *   that are specified will be enabled and the rest will be disabled.
 *  When "" is specified all the categories are disabled.
 *  The category names are case sensitive.
 *  eg:  Dart_EnableTimelineCategory("all");
 *       Dart_EnableTimelineCategory("GC,API,Isolate");
 *       Dart_EnableTimelineCategory("GC,Debugger,Dart");
 *
 * \return True if the categories were successfully enabled, False otherwise.
 */
DART_EXPORT bool Dart_SetEnabledTimelineCategory(const char* categories);

/**
 * Returns a timestamp in microseconds. This timestamp is suitable for
 * passing into the timeline system, and uses the same monotonic clock
 * as dart:developer's Timeline.now.
 *
 * \return A timestamp that can be passed to the timeline system.
 */
DART_EXPORT int64_t Dart_TimelineGetMicros();

/**
 * Returns a raw timestamp in from the monotonic clock.
 *
 * \return A raw timestamp from the monotonic clock.
 */
DART_EXPORT int64_t Dart_TimelineGetTicks();

/**
 * Returns the frequency of the monotonic clock.
 *
 * \return The frequency of the monotonic clock.
 */
DART_EXPORT int64_t Dart_TimelineGetTicksFrequency();

typedef enum {
  Dart_Timeline_Event_Begin,          // Phase = 'B'.
  Dart_Timeline_Event_End,            // Phase = 'E'.
  Dart_Timeline_Event_Instant,        // Phase = 'i'.
  Dart_Timeline_Event_Duration,       // Phase = 'X'.
  Dart_Timeline_Event_Async_Begin,    // Phase = 'b'.
  Dart_Timeline_Event_Async_End,      // Phase = 'e'.
  Dart_Timeline_Event_Async_Instant,  // Phase = 'n'.
  Dart_Timeline_Event_Counter,        // Phase = 'C'.
  Dart_Timeline_Event_Flow_Begin,     // Phase = 's'.
  Dart_Timeline_Event_Flow_Step,      // Phase = 't'.
  Dart_Timeline_Event_Flow_End,       // Phase = 'f'.
} Dart_Timeline_Event_Type;

/**
 * Add a timeline event to the embedder stream.
 *
 * Note regarding flow events: events must be associated with flow IDs in two
 * different ways to allow flow events to be serialized correctly in both
 * Chrome's JSON trace event format and Perfetto's proto trace format. Events
 * of type |Dart_Timeline_Event_Flow_Begin|, |Dart_Timeline_Event_Flow_Step|,
 * and |Dart_Timeline_Event_Flow_End| must be reported to support serialization
 * in Chrome's trace format. The |flow_ids| argument must be supplied when
 * reporting events of type |Dart_Timeline_Event_Begin|,
 * |Dart_Timeline_Event_Duration|, |Dart_Timeline_Event_Instant|,
 * |Dart_Timeline_Event_Async_Begin|, and |Dart_Timeline_Event_Async_Instant| to
 * support serialization in Perfetto's proto format.
 *
 * The Dart VM can use various underlying recorders depending on configuration
 * and operating system. Many recorders do not support all event types;
 * unsupported event types are siliently dropped. Some recorders do not accept
 * timestamps as input, instead implicitly using the time the event is recorded.
 * For maximum compatibility, record events with the Begin and End types as they
 * occur instead of using the Duration type or buffering.
 *
 * \param label The name of the event. Its lifetime must extend at least until
 *     Dart_Cleanup.
 * \param timestamp0 The first timestamp of the event.
 * \param timestamp1_or_id When reporting an event of type
 *     |Dart_Timeline_Event_Duration|, the second (end) timestamp of the event
 *     should be passed through |timestamp1_or_id|. When reporting an event of
 *     type |Dart_Timeline_Event_Async_Begin|, |Dart_Timeline_Event_Async_End|,
 *     or |Dart_Timeline_Event_Async_Instant|, the async ID associated with the
 *     event should be passed through |timestamp1_or_id|. When reporting an
 *     event of type |Dart_Timeline_Event_Flow_Begin|,
 *     |Dart_Timeline_Event_Flow_Step|, or |Dart_Timeline_Event_Flow_End|, the
 *     flow ID associated with the event should be passed through
 *     |timestamp1_or_id|. When reporting an event of type
 *     |Dart_Timeline_Event_Begin| or |Dart_Timeline_Event_End|, the event ID
 *     associated with the event should be passed through |timestamp1_or_id|.
 *     Note that this event ID will only be used by the MacOS recorder. The
 *     argument to |timestamp1_or_id| will not be used when reporting events of
 *     other types.
 * \param flow_id_count The number of flow IDs associated with this event.
 * \param flow_ids An array of flow IDs associated with this event. The array
 *     may be reclaimed when this call returns.
 * \param argument_count The number of argument names and values.
 * \param argument_names An array of names of the arguments. The lifetime of the
 *     names must extend at least until Dart_Cleanup. The array may be reclaimed
 *     when this call returns.
 * \param argument_values An array of values of the arguments. The values and
 *     the array may be reclaimed when this call returns.
 */
DART_EXPORT void Dart_RecordTimelineEvent(const char* label,
                                          int64_t timestamp0,
                                          int64_t timestamp1_or_id,
                                          intptr_t flow_id_count,
                                          const int64_t* flow_ids,
                                          Dart_Timeline_Event_Type type,
                                          intptr_t argument_count,
                                          const char** argument_names,
                                          const char** argument_values);

/**
 * Associates a name with the current thread. This name will be used to name
 * threads in the timeline. Can only be called after a call to Dart_Initialize.
 *
 * \param name The name of the thread.
 */
DART_EXPORT void Dart_SetThreadName(const char* name);

typedef struct {
  const char* name;
  const char* value;
} Dart_TimelineRecorderEvent_Argument;

#define DART_TIMELINE_RECORDER_CURRENT_VERSION (0x00000002)

typedef struct {
  /* Set to DART_TIMELINE_RECORDER_CURRENT_VERSION */
  int32_t version;

  /* The event's type / phase. */
  Dart_Timeline_Event_Type type;

  /* The event's timestamp according to the same clock as
   * Dart_TimelineGetMicros. For a duration event, this is the beginning time.
   */
  int64_t timestamp0;

  /**
   * For a duration event, this is the end time. For an async event, this is the
   * async ID. For a flow event, this is the flow ID. For a begin or end event,
   * this is the event ID (which is only referenced by the MacOS recorder).
   */
  int64_t timestamp1_or_id;

  /* The current isolate of the event, as if by Dart_GetMainPortId, or
   * ILLEGAL_PORT if the event had no current isolate. */
  Dart_Port isolate;

  /* The current isolate group of the event, as if by
   * Dart_CurrentIsolateGroupId, or ILLEGAL_PORT if the event had no current
   * isolate group. */
  Dart_IsolateGroupId isolate_group;

  /* The callback data associated with the isolate if any. */
  void* isolate_data;

  /* The callback data associated with the isolate group if any. */
  void* isolate_group_data;

  /* The name / label of the event. */
  const char* label;

  /* The stream / category of the event. */
  const char* stream;

  intptr_t argument_count;
  Dart_TimelineRecorderEvent_Argument* arguments;
} Dart_TimelineRecorderEvent;

/**
 * Callback provided by the embedder to handle the completion of timeline
 * events.
 *
 * \param event A timeline event that has just been completed. The VM keeps
 * ownership of the event and any field in it (i.e., the embedder should copy
 * any values it needs after the callback returns).
 */
typedef void (*Dart_TimelineRecorderCallback)(
    Dart_TimelineRecorderEvent* event);

/**
 * Register a `Dart_TimelineRecorderCallback` to be called as timeline events
 * are completed.
 *
 * The callback will be invoked without a current isolate.
 *
 * The callback will be invoked on the thread completing the event. Because
 * `Dart_RecordTimelineEvent` may be called by any thread, the callback may be
 * called on any thread.
 *
 * The callback may be invoked at any time after `Dart_Initialize` is called and
 * before `Dart_Cleanup` returns.
 *
 * If multiple callbacks are registered, only the last callback registered
 * will be remembered. Providing a NULL callback will clear the registration
 * (i.e., a NULL callback produced a no-op instead of a crash).
 *
 * Setting a callback is insufficient to receive events through the callback. The
 * VM flag `timeline_recorder` must also be set to `callback`.
 */
DART_EXPORT void Dart_SetTimelineRecorderCallback(
    Dart_TimelineRecorderCallback callback);

/*
 * =======
 * Metrics
 * =======
 */

/**
 * Return metrics gathered for the VM and individual isolates.
 */
DART_EXPORT int64_t
Dart_IsolateGroupHeapOldUsedMetric(Dart_IsolateGroup group);  // Byte
DART_EXPORT int64_t
Dart_IsolateGroupHeapOldCapacityMetric(Dart_IsolateGroup group);  // Byte
DART_EXPORT int64_t
Dart_IsolateGroupHeapOldExternalMetric(Dart_IsolateGroup group);  // Byte
DART_EXPORT int64_t
Dart_IsolateGroupHeapNewUsedMetric(Dart_IsolateGroup group);  // Byte
DART_EXPORT int64_t
Dart_IsolateGroupHeapNewCapacityMetric(Dart_IsolateGroup group);  // Byte
DART_EXPORT int64_t
Dart_IsolateGroupHeapNewExternalMetric(Dart_IsolateGroup group);  // Byte

/*
 * ========
 * UserTags
 * ========
 */

/*
 * Gets the current isolate's currently set UserTag instance.
 *
 * \return The currently set UserTag instance.
 */
DART_EXPORT Dart_Handle Dart_GetCurrentUserTag();

/*
 * Gets the current isolate's default UserTag instance.
 *
 * \return The default UserTag with label 'Default'
 */
DART_EXPORT Dart_Handle Dart_GetDefaultUserTag();

/*
 * Creates a new UserTag instance.
 *
 * \param label The name of the new UserTag.
 *
 * \return The newly created UserTag instance or an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewUserTag(const char* label);

/*
 * Updates the current isolate's UserTag to a new value.
 *
 * \param user_tag The UserTag to be set as the current UserTag.
 *
 * \return The previously set UserTag instance or an error handle.
 */
DART_EXPORT Dart_Handle Dart_SetCurrentUserTag(Dart_Handle user_tag);

/*
 * Returns the label of a given UserTag instance.
 *
 * \param user_tag The UserTag from which the label will be retrieved.
 *
 * \return The UserTag's label. NULL if the user_tag is invalid. The caller is
 *   responsible for freeing the returned label.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT char* Dart_GetUserTagLabel(
    Dart_Handle user_tag);

/*
 * =======
 * Heap Snapshot
 * =======
 */

/**
 * Callback provided by the caller of `Dart_WriteHeapSnapshot` which is
 * used to write out chunks of the requested heap snapshot.
 *
 * \param context An opaque context which was passed to `Dart_WriteHeapSnapshot`
 *   together with this callback.
 *
 * \param buffer Pointer to the buffer containing a chunk of the snapshot.
 *   The callback owns the buffer and needs to `free` it.
 *
 * \param size Number of bytes in the `buffer` to be written.
 *
 * \param is_last Set to `true` for the last chunk. The callback will not
 *   be invoked again after it was invoked once with `is_last` set to `true`.
 */
typedef void (*Dart_HeapSnapshotWriteChunkCallback)(void* context,
                                                    uint8_t* buffer,
                                                    intptr_t size,
                                                    bool is_last);

/**
 * Generate heap snapshot of the current isolate group and stream it into the
 * given `callback`. VM would produce snapshot in chunks and send these chunks
 * one by one back to the embedder by invoking the provided `callback`.
 *
 * This API enables embedder to stream snapshot into a file or socket without
 * allocating a buffer to hold the whole snapshot in memory.
 *
 * The isolate group will be paused for the duration of this operation.
 *
 * \param write Callback used to write chunks of the heap snapshot.
 *
 * \param context Opaque context which would be passed on each invocation of
 *   `write` callback.
 *
 * \returns `nullptr` if the operation is successful otherwise error message.
 *   Caller owns error message string and needs to `free` it.
 */
DART_EXPORT char* Dart_WriteHeapSnapshot(
    Dart_HeapSnapshotWriteChunkCallback write,
    void* context);

#endif  // RUNTIME_INCLUDE_DART_TOOLS_API_H_

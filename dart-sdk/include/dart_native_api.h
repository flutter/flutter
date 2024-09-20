/*
 * Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef RUNTIME_INCLUDE_DART_NATIVE_API_H_
#define RUNTIME_INCLUDE_DART_NATIVE_API_H_

#include "dart_api.h" /* NOLINT */

/*
 * ==========================================
 * Message sending/receiving from native code
 * ==========================================
 */

/**
 * A Dart_CObject is used for representing Dart objects as native C
 * data outside the Dart heap. These objects are totally detached from
 * the Dart heap. Only a subset of the Dart objects have a
 * representation as a Dart_CObject.
 *
 * The string encoding in the 'value.as_string' is UTF-8.
 *
 * All the different types from dart:typed_data are exposed as type
 * kTypedData. The specific type from dart:typed_data is in the type
 * field of the as_typed_data structure. The length in the
 * as_typed_data structure is always in bytes.
 *
 * The data for kTypedData is copied on message send and ownership remains with
 * the caller. The ownership of data for kExternalTyped is passed to the VM on
 * message send and returned when the VM invokes the
 * Dart_HandleFinalizer callback; a non-NULL callback must be provided.
 *
 * Note that Dart_CObject_kNativePointer is intended for internal use by
 * dart:io implementation and has no connection to dart:ffi Pointer class.
 * It represents a pointer to a native resource of a known type.
 * The receiving side will only see this pointer as an integer and will not
 * see the specified finalizer.
 * The specified finalizer will only be invoked if the message is not delivered.
 */
typedef enum {
  Dart_CObject_kNull = 0,
  Dart_CObject_kBool,
  Dart_CObject_kInt32,
  Dart_CObject_kInt64,
  Dart_CObject_kDouble,
  Dart_CObject_kString,
  Dart_CObject_kArray,
  Dart_CObject_kTypedData,
  Dart_CObject_kExternalTypedData,
  Dart_CObject_kSendPort,
  Dart_CObject_kCapability,
  Dart_CObject_kNativePointer,
  Dart_CObject_kUnsupported,
  Dart_CObject_kUnmodifiableExternalTypedData,
  Dart_CObject_kNumberOfTypes
} Dart_CObject_Type;
// This enum is versioned by DART_API_DL_MAJOR_VERSION, only add at the end
// and bump the DART_API_DL_MINOR_VERSION.

typedef struct _Dart_CObject {
  Dart_CObject_Type type;
  union {
    bool as_bool;
    int32_t as_int32;
    int64_t as_int64;
    double as_double;
    const char* as_string;
    struct {
      Dart_Port id;
      Dart_Port origin_id;
    } as_send_port;
    struct {
      int64_t id;
    } as_capability;
    struct {
      intptr_t length;
      struct _Dart_CObject** values;
    } as_array;
    struct {
      Dart_TypedData_Type type;
      intptr_t length; /* in elements, not bytes */
      const uint8_t* values;
    } as_typed_data;
    struct {
      Dart_TypedData_Type type;
      intptr_t length; /* in elements, not bytes */
      uint8_t* data;
      void* peer;
      Dart_HandleFinalizer callback;
    } as_external_typed_data;
    struct {
      intptr_t ptr;
      intptr_t size;
      Dart_HandleFinalizer callback;
    } as_native_pointer;
  } value;
} Dart_CObject;
// This struct is versioned by DART_API_DL_MAJOR_VERSION, bump the version when
// changing this struct.

/**
 * Posts a message on some port. The message will contain the Dart_CObject
 * object graph rooted in 'message'.
 *
 * While the message is being sent the state of the graph of Dart_CObject
 * structures rooted in 'message' should not be accessed, as the message
 * generation will make temporary modifications to the data. When the message
 * has been sent the graph will be fully restored.
 *
 * If true is returned, the message was enqueued, and finalizers for external
 * typed data will eventually run, even if the receiving isolate shuts down
 * before processing the message. If false is returned, the message was not
 * enqueued and ownership of external typed data in the message remains with the
 * caller.
 *
 * This function may be called on any thread when the VM is running (that is,
 * after Dart_Initialize has returned and before Dart_Cleanup has been called).
 *
 * \param port_id The destination port.
 * \param message The message to send.
 *
 * \return True if the message was posted.
 */
DART_EXPORT bool Dart_PostCObject(Dart_Port port_id, Dart_CObject* message);

/**
 * Posts a message on some port. The message will contain the integer 'message'.
 *
 * \param port_id The destination port.
 * \param message The message to send.
 *
 * \return True if the message was posted.
 */
DART_EXPORT bool Dart_PostInteger(Dart_Port port_id, int64_t message);

/**
 * A native message handler.
 *
 * This handler is associated with a native port by calling
 * Dart_NewNativePort.
 *
 * The message received is decoded into the message structure. The
 * lifetime of the message data is controlled by the caller. All the
 * data references from the message are allocated by the caller and
 * will be reclaimed when returning to it.
 */
typedef void (*Dart_NativeMessageHandler)(Dart_Port dest_port_id,
                                          Dart_CObject* message);

/**
 * Creates a new native port.  When messages are received on this
 * native port, then they will be dispatched to the provided native
 * message handler.
 *
 * \param name The name of this port in debugging messages.
 * \param handler The C handler to run when messages arrive on the port.
 * \param handle_concurrently Is it okay to process requests on this
 *                            native port concurrently?
 *
 * \return If successful, returns the port id for the native port.  In
 *   case of error, returns ILLEGAL_PORT.
 */
DART_EXPORT Dart_Port Dart_NewNativePort(const char* name,
                                         Dart_NativeMessageHandler handler,
                                         bool handle_concurrently);
/* TODO(turnidge): Currently handle_concurrently is ignored. */

/**
 * Closes the native port with the given id.
 *
 * The port must have been allocated by a call to Dart_NewNativePort.
 *
 * \param native_port_id The id of the native port to close.
 *
 * \return Returns true if the port was closed successfully.
 */
DART_EXPORT bool Dart_CloseNativePort(Dart_Port native_port_id);

/*
 * ==================
 * Verification Tools
 * ==================
 */

/**
 * Forces all loaded classes and functions to be compiled eagerly in
 * the current isolate..
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle Dart_CompileAll(void);

/**
 * Finalizes all classes.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle Dart_FinalizeAllClasses(void);

/*  This function is intentionally undocumented.
 *
 *  It should not be used outside internal tests.
 */
DART_EXPORT void* Dart_ExecuteInternalCommand(const char* command, void* arg);

#endif /* INCLUDE_DART_NATIVE_API_H_ */ /* NOLINT */

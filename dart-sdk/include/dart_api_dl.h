/*
 * Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef RUNTIME_INCLUDE_DART_API_DL_H_
#define RUNTIME_INCLUDE_DART_API_DL_H_

#include "dart_api.h"        /* NOLINT */
#include "dart_native_api.h" /* NOLINT */

/** \mainpage Dynamically Linked Dart API
 *
 * This exposes a subset of symbols from dart_api.h and dart_native_api.h
 * available in every Dart embedder through dynamic linking.
 *
 * All symbols are postfixed with _DL to indicate that they are dynamically
 * linked and to prevent conflicts with the original symbol.
 *
 * Link `dart_api_dl.c` file into your library and invoke
 * `Dart_InitializeApiDL` with `NativeApi.initializeApiDLData`.
 *
 * Returns 0 on success.
 */

DART_EXPORT intptr_t Dart_InitializeApiDL(void* data);

// ============================================================================
// IMPORTANT! Never update these signatures without properly updating
// DART_API_DL_MAJOR_VERSION and DART_API_DL_MINOR_VERSION.
//
// Verbatim copy of `dart_native_api.h` and `dart_api.h` symbol names and types
// to trigger compile-time errors if the symbols in those files are updated
// without updating these.
//
// Function return and argument types, and typedefs are carbon copied. Structs
// are typechecked nominally in C/C++, so they are not copied, instead a
// comment is added to their definition.
typedef int64_t Dart_Port_DL;
typedef struct {
  int64_t port_id;
  int64_t origin_id;
} Dart_PortEx_DL;

typedef void (*Dart_NativeMessageHandler_DL)(Dart_Port_DL dest_port_id,
                                             Dart_CObject* message);

// dart_native_api.h symbols can be called on any thread.
#define DART_NATIVE_API_DL_SYMBOLS(F)                                          \
  /***** dart_native_api.h *****/                                              \
  /* Dart_Port */                                                              \
  F(Dart_PostCObject, bool, (Dart_Port_DL port_id, Dart_CObject * message))    \
  F(Dart_PostInteger, bool, (Dart_Port_DL port_id, int64_t message))           \
  F(Dart_NewNativePort, Dart_Port_DL,                                          \
    (const char* name, Dart_NativeMessageHandler_DL handler,                   \
     bool handle_concurrently))                                                \
  F(Dart_CloseNativePort, bool, (Dart_Port_DL native_port_id))

// dart_api.h symbols can only be called on Dart threads.
#define DART_API_DL_SYMBOLS(F)                                                 \
  /***** dart_api.h *****/                                                     \
  /* Errors */                                                                 \
  F(Dart_IsError, bool, (Dart_Handle handle))                                  \
  F(Dart_IsApiError, bool, (Dart_Handle handle))                               \
  F(Dart_IsUnhandledExceptionError, bool, (Dart_Handle handle))                \
  F(Dart_IsCompilationError, bool, (Dart_Handle handle))                       \
  F(Dart_IsFatalError, bool, (Dart_Handle handle))                             \
  F(Dart_GetError, const char*, (Dart_Handle handle))                          \
  F(Dart_ErrorHasException, bool, (Dart_Handle handle))                        \
  F(Dart_ErrorGetException, Dart_Handle, (Dart_Handle handle))                 \
  F(Dart_ErrorGetStackTrace, Dart_Handle, (Dart_Handle handle))                \
  F(Dart_NewApiError, Dart_Handle, (const char* error))                        \
  F(Dart_NewCompilationError, Dart_Handle, (const char* error))                \
  F(Dart_NewUnhandledExceptionError, Dart_Handle, (Dart_Handle exception))     \
  F(Dart_PropagateError, void, (Dart_Handle handle))                           \
  /* Dart_Handle, Dart_PersistentHandle, Dart_WeakPersistentHandle */          \
  F(Dart_HandleFromPersistent, Dart_Handle, (Dart_PersistentHandle object))    \
  F(Dart_HandleFromWeakPersistent, Dart_Handle,                                \
    (Dart_WeakPersistentHandle object))                                        \
  F(Dart_NewPersistentHandle, Dart_PersistentHandle, (Dart_Handle object))     \
  F(Dart_SetPersistentHandle, void,                                            \
    (Dart_PersistentHandle obj1, Dart_Handle obj2))                            \
  F(Dart_DeletePersistentHandle, void, (Dart_PersistentHandle object))         \
  F(Dart_NewWeakPersistentHandle, Dart_WeakPersistentHandle,                   \
    (Dart_Handle object, void* peer, intptr_t external_allocation_size,        \
     Dart_HandleFinalizer callback))                                           \
  F(Dart_DeleteWeakPersistentHandle, void, (Dart_WeakPersistentHandle object)) \
  F(Dart_NewFinalizableHandle, Dart_FinalizableHandle,                         \
    (Dart_Handle object, void* peer, intptr_t external_allocation_size,        \
     Dart_HandleFinalizer callback))                                           \
  F(Dart_DeleteFinalizableHandle, void,                                        \
    (Dart_FinalizableHandle object, Dart_Handle strong_ref_to_object))         \
  /* Isolates */                                                               \
  F(Dart_CurrentIsolate, Dart_Isolate, (void))                                 \
  F(Dart_ExitIsolate, void, (void))                                            \
  F(Dart_EnterIsolate, void, (Dart_Isolate))                                   \
  /* Dart_Port */                                                              \
  F(Dart_Post, bool, (Dart_Port_DL port_id, Dart_Handle object))               \
  F(Dart_NewSendPort, Dart_Handle, (Dart_Port_DL port_id))                     \
  F(Dart_NewSendPortEx, Dart_Handle, (Dart_PortEx_DL portex_id))               \
  F(Dart_SendPortGetId, Dart_Handle,                                           \
    (Dart_Handle port, Dart_Port_DL * port_id))                                \
  F(Dart_SendPortGetIdEx, Dart_Handle,                                         \
    (Dart_Handle port, Dart_PortEx_DL * portex_id))                            \
  /* Scopes */                                                                 \
  F(Dart_EnterScope, void, (void))                                             \
  F(Dart_ExitScope, void, (void))                                              \
  /* Objects */                                                                \
  F(Dart_IsNull, bool, (Dart_Handle))                                          \
  F(Dart_Null, Dart_Handle, (void))

// dart_api.h symbols that have been deprecated but are retained here
// until we can make a breaking change bumping the major version number
// (DART_API_DL_MAJOR_VERSION)
#define DART_API_DEPRECATED_DL_SYMBOLS(F)                                      \
  F(Dart_UpdateExternalSize, void,                                             \
    (Dart_WeakPersistentHandle object, intptr_t external_allocation_size))     \
  F(Dart_UpdateFinalizableExternalSize, void,                                  \
    (Dart_FinalizableHandle object, Dart_Handle strong_ref_to_object,          \
     intptr_t external_allocation_size))

#define DART_API_ALL_DL_SYMBOLS(F)                                             \
  DART_NATIVE_API_DL_SYMBOLS(F)                                                \
  DART_API_DL_SYMBOLS(F)
// IMPORTANT! Never update these signatures without properly updating
// DART_API_DL_MAJOR_VERSION and DART_API_DL_MINOR_VERSION.
//
// End of verbatim copy.
// ============================================================================

// Copy of definition of DART_EXPORT without 'used' attribute.
//
// The 'used' attribute cannot be used with DART_API_ALL_DL_SYMBOLS because
// they are not function declarations, but variable declarations with a
// function pointer type.
//
// The function pointer variables are initialized with the addresses of the
// functions in the VM. If we were to use function declarations instead, we
// would need to forward the call to the VM adding indirection.
#if defined(__CYGWIN__)
#error Tool chain and platform not supported.
#elif defined(_WIN32)
#if defined(DART_SHARED_LIB)
#define DART_EXPORT_DL DART_EXTERN_C __declspec(dllexport)
#else
#define DART_EXPORT_DL DART_EXTERN_C
#endif
#else
#if __GNUC__ >= 4
#if defined(DART_SHARED_LIB)
#define DART_EXPORT_DL DART_EXTERN_C __attribute__((visibility("default")))
#else
#define DART_EXPORT_DL DART_EXTERN_C
#endif
#else
#error Tool chain not supported.
#endif
#endif

#define DART_API_DL_DECLARATIONS(name, R, A)                                   \
  typedef R(*name##_Type) A;                                                   \
  DART_EXPORT_DL name##_Type name##_DL;

DART_API_ALL_DL_SYMBOLS(DART_API_DL_DECLARATIONS)
DART_API_DEPRECATED_DL_SYMBOLS(DART_API_DL_DECLARATIONS)

#undef DART_API_DL_DECLARATIONS

#undef DART_EXPORT_DL

#endif /* RUNTIME_INCLUDE_DART_API_DL_H_ */ /* NOLINT */

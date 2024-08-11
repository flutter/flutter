/*
 * Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

#ifndef RUNTIME_INCLUDE_DART_API_H_
#define RUNTIME_INCLUDE_DART_API_H_

/** \mainpage Dart Embedding API Reference
 *
 * This reference describes the Dart Embedding API, which is used to embed the
 * Dart Virtual Machine within C/C++ applications.
 *
 * This reference is generated from the header include/dart_api.h.
 */

/* __STDC_FORMAT_MACROS has to be defined before including <inttypes.h> to
 * enable platform independent printf format specifiers. */
#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif

#include <assert.h>
#include <inttypes.h>
#include <stdbool.h>

#if defined(__Fuchsia__)
#include <zircon/types.h>
#endif

#ifdef __cplusplus
#define DART_EXTERN_C extern "C"
#else
#define DART_EXTERN_C extern
#endif

#if defined(__CYGWIN__)
#error Tool chain and platform not supported.
#elif defined(_WIN32)
#if defined(DART_SHARED_LIB)
#define DART_EXPORT DART_EXTERN_C __declspec(dllexport)
#else
#define DART_EXPORT DART_EXTERN_C
#endif
#else
#if __GNUC__ >= 4
#if defined(DART_SHARED_LIB)
#define DART_EXPORT                                                            \
  DART_EXTERN_C __attribute__((visibility("default"))) __attribute((used))
#else
#define DART_EXPORT DART_EXTERN_C
#endif
#else
#error Tool chain not supported.
#endif
#endif

#if __GNUC__
#define DART_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#define DART_DEPRECATED(msg) __attribute__((deprecated(msg)))
#elif _MSC_VER
#define DART_WARN_UNUSED_RESULT _Check_return_
#define DART_DEPRECATED(msg) __declspec(deprecated(msg))
#else
#define DART_WARN_UNUSED_RESULT
#define DART_DEPRECATED(msg)
#endif

/*
 * =======
 * Handles
 * =======
 */

/**
 * An isolate is the unit of concurrency in Dart. Each isolate has
 * its own memory and thread of control. No state is shared between
 * isolates. Instead, isolates communicate by message passing.
 *
 * Each thread keeps track of its current isolate, which is the
 * isolate which is ready to execute on the current thread. The
 * current isolate may be NULL, in which case no isolate is ready to
 * execute. Most of the Dart apis require there to be a current
 * isolate in order to function without error. The current isolate is
 * set by any call to Dart_CreateIsolateGroup or Dart_EnterIsolate.
 */
typedef struct _Dart_Isolate* Dart_Isolate;
typedef struct _Dart_IsolateGroup* Dart_IsolateGroup;

/**
 * An object reference managed by the Dart VM garbage collector.
 *
 * Because the garbage collector may move objects, it is unsafe to
 * refer to objects directly. Instead, we refer to objects through
 * handles, which are known to the garbage collector and updated
 * automatically when the object is moved. Handles should be passed
 * by value (except in cases like out-parameters) and should never be
 * allocated on the heap.
 *
 * Most functions in the Dart Embedding API return a handle. When a
 * function completes normally, this will be a valid handle to an
 * object in the Dart VM heap. This handle may represent the result of
 * the operation or it may be a special valid handle used merely to
 * indicate successful completion. Note that a valid handle may in
 * some cases refer to the null object.
 *
 * --- Error handles ---
 *
 * When a function encounters a problem that prevents it from
 * completing normally, it returns an error handle (See Dart_IsError).
 * An error handle has an associated error message that gives more
 * details about the problem (See Dart_GetError).
 *
 * There are four kinds of error handles that can be produced,
 * depending on what goes wrong:
 *
 * - Api error handles are produced when an api function is misused.
 *   This happens when a Dart embedding api function is called with
 *   invalid arguments or in an invalid context.
 *
 * - Unhandled exception error handles are produced when, during the
 *   execution of Dart code, an exception is thrown but not caught.
 *   Prototypically this would occur during a call to Dart_Invoke, but
 *   it can occur in any function which triggers the execution of Dart
 *   code (for example, Dart_ToString).
 *
 *   An unhandled exception error provides access to an exception and
 *   stacktrace via the functions Dart_ErrorGetException and
 *   Dart_ErrorGetStackTrace.
 *
 * - Compilation error handles are produced when, during the execution
 *   of Dart code, a compile-time error occurs.  As above, this can
 *   occur in any function which triggers the execution of Dart code.
 *
 * - Fatal error handles are produced when the system wants to shut
 *   down the current isolate.
 *
 * --- Propagating errors ---
 *
 * When an error handle is returned from the top level invocation of
 * Dart code in a program, the embedder must handle the error as they
 * see fit.  Often, the embedder will print the error message produced
 * by Dart_Error and exit the program.
 *
 * When an error is returned while in the body of a native function,
 * it can be propagated up the call stack by calling
 * Dart_PropagateError, Dart_SetReturnValue, or Dart_ThrowException.
 * Errors should be propagated unless there is a specific reason not
 * to.  If an error is not propagated then it is ignored.  For
 * example, if an unhandled exception error is ignored, that
 * effectively "catches" the unhandled exception.  Fatal errors must
 * always be propagated.
 *
 * When an error is propagated, any current scopes created by
 * Dart_EnterScope will be exited.
 *
 * Using Dart_SetReturnValue to propagate an exception is somewhat
 * more convenient than using Dart_PropagateError, and should be
 * preferred for reasons discussed below.
 *
 * Dart_PropagateError and Dart_ThrowException do not return.  Instead
 * they transfer control non-locally using a setjmp-like mechanism.
 * This can be inconvenient if you have resources that you need to
 * clean up before propagating the error.
 *
 * When relying on Dart_PropagateError, we often return error handles
 * rather than propagating them from helper functions.  Consider the
 * following contrived example:
 *
 * 1    Dart_Handle isLongStringHelper(Dart_Handle arg) {
 * 2      intptr_t* length = 0;
 * 3      result = Dart_StringLength(arg, &length);
 * 4      if (Dart_IsError(result)) {
 * 5        return result;
 * 6      }
 * 7      return Dart_NewBoolean(length > 100);
 * 8    }
 * 9
 * 10   void NativeFunction_isLongString(Dart_NativeArguments args) {
 * 11     Dart_EnterScope();
 * 12     AllocateMyResource();
 * 13     Dart_Handle arg = Dart_GetNativeArgument(args, 0);
 * 14     Dart_Handle result = isLongStringHelper(arg);
 * 15     if (Dart_IsError(result)) {
 * 16       FreeMyResource();
 * 17       Dart_PropagateError(result);
 * 18       abort();  // will not reach here
 * 19     }
 * 20     Dart_SetReturnValue(result);
 * 21     FreeMyResource();
 * 22     Dart_ExitScope();
 * 23   }
 *
 * In this example, we have a native function which calls a helper
 * function to do its work.  On line 5, the helper function could call
 * Dart_PropagateError, but that would not give the native function a
 * chance to call FreeMyResource(), causing a leak.  Instead, the
 * helper function returns the error handle to the caller, giving the
 * caller a chance to clean up before propagating the error handle.
 *
 * When an error is propagated by calling Dart_SetReturnValue, the
 * native function will be allowed to complete normally and then the
 * exception will be propagated only once the native call
 * returns. This can be convenient, as it allows the C code to clean
 * up normally.
 *
 * The example can be written more simply using Dart_SetReturnValue to
 * propagate the error.
 *
 * 1    Dart_Handle isLongStringHelper(Dart_Handle arg) {
 * 2      intptr_t* length = 0;
 * 3      result = Dart_StringLength(arg, &length);
 * 4      if (Dart_IsError(result)) {
 * 5        return result
 * 6      }
 * 7      return Dart_NewBoolean(length > 100);
 * 8    }
 * 9
 * 10   void NativeFunction_isLongString(Dart_NativeArguments args) {
 * 11     Dart_EnterScope();
 * 12     AllocateMyResource();
 * 13     Dart_Handle arg = Dart_GetNativeArgument(args, 0);
 * 14     Dart_SetReturnValue(isLongStringHelper(arg));
 * 15     FreeMyResource();
 * 16     Dart_ExitScope();
 * 17   }
 *
 * In this example, the call to Dart_SetReturnValue on line 14 will
 * either return the normal return value or the error (potentially
 * generated on line 3).  The call to FreeMyResource on line 15 will
 * execute in either case.
 *
 * --- Local and persistent handles ---
 *
 * Local handles are allocated within the current scope (see
 * Dart_EnterScope) and go away when the current scope exits. Unless
 * otherwise indicated, callers should assume that all functions in
 * the Dart embedding api return local handles.
 *
 * Persistent handles are allocated within the current isolate. They
 * can be used to store objects across scopes. Persistent handles have
 * the lifetime of the current isolate unless they are explicitly
 * deallocated (see Dart_DeletePersistentHandle).
 * The type Dart_Handle represents a handle (both local and persistent).
 * The type Dart_PersistentHandle is a Dart_Handle and it is used to
 * document that a persistent handle is expected as a parameter to a call
 * or the return value from a call is a persistent handle.
 *
 * FinalizableHandles are persistent handles which are auto deleted when
 * the object is garbage collected. It is never safe to use these handles
 * unless you know the object is still reachable.
 *
 * WeakPersistentHandles are persistent handles which are automatically set
 * to point Dart_Null when the object is garbage collected. They are not auto
 * deleted, so it is safe to use them after the object has become unreachable.
 */
typedef struct _Dart_Handle* Dart_Handle;
typedef Dart_Handle Dart_PersistentHandle;
typedef struct _Dart_WeakPersistentHandle* Dart_WeakPersistentHandle;
typedef struct _Dart_FinalizableHandle* Dart_FinalizableHandle;
// These structs are versioned by DART_API_DL_MAJOR_VERSION, bump the
// version when changing this struct.

typedef void (*Dart_HandleFinalizer)(void* isolate_callback_data, void* peer);

/**
 * Is this an error handle?
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsError(Dart_Handle handle);

/**
 * Is this an api error handle?
 *
 * Api error handles are produced when an api function is misused.
 * This happens when a Dart embedding api function is called with
 * invalid arguments or in an invalid context.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsApiError(Dart_Handle handle);

/**
 * Is this an unhandled exception error handle?
 *
 * Unhandled exception error handles are produced when, during the
 * execution of Dart code, an exception is thrown but not caught.
 * This can occur in any function which triggers the execution of Dart
 * code.
 *
 * See Dart_ErrorGetException and Dart_ErrorGetStackTrace.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsUnhandledExceptionError(Dart_Handle handle);

/**
 * Is this a compilation error handle?
 *
 * Compilation error handles are produced when, during the execution
 * of Dart code, a compile-time error occurs.  This can occur in any
 * function which triggers the execution of Dart code.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsCompilationError(Dart_Handle handle);

/**
 * Is this a fatal error handle?
 *
 * Fatal error handles are produced when the system wants to shut down
 * the current isolate.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT bool Dart_IsFatalError(Dart_Handle handle);

/**
 * Gets the error message from an error handle.
 *
 * Requires there to be a current isolate.
 *
 * \return A C string containing an error message if the handle is
 *   error. An empty C string ("") if the handle is valid. This C
 *   String is scope allocated and is only valid until the next call
 *   to Dart_ExitScope.
*/
DART_EXPORT const char* Dart_GetError(Dart_Handle handle);

/**
 * Is this an error handle for an unhandled exception?
 */
DART_EXPORT bool Dart_ErrorHasException(Dart_Handle handle);

/**
 * Gets the exception Object from an unhandled exception error handle.
 */
DART_EXPORT Dart_Handle Dart_ErrorGetException(Dart_Handle handle);

/**
 * Gets the stack trace Object from an unhandled exception error handle.
 */
DART_EXPORT Dart_Handle Dart_ErrorGetStackTrace(Dart_Handle handle);

/**
 * Produces an api error handle with the provided error message.
 *
 * Requires there to be a current isolate.
 *
 * \param error the error message.
 */
DART_EXPORT Dart_Handle Dart_NewApiError(const char* error);
DART_EXPORT Dart_Handle Dart_NewCompilationError(const char* error);

/**
 * Produces a new unhandled exception error handle.
 *
 * Requires there to be a current isolate.
 *
 * \param exception An instance of a Dart object to be thrown or
 *        an ApiError or CompilationError handle.
 *        When an ApiError or CompilationError handle is passed in
 *        a string object of the error message is created and it becomes
 *        the Dart object to be thrown.
 */
DART_EXPORT Dart_Handle Dart_NewUnhandledExceptionError(Dart_Handle exception);

/**
 * Propagates an error.
 *
 * If the provided handle is an unhandled exception error, this
 * function will cause the unhandled exception to be rethrown.  This
 * will proceed in the standard way, walking up Dart frames until an
 * appropriate 'catch' block is found, executing 'finally' blocks,
 * etc.
 *
 * If the error is not an unhandled exception error, we will unwind
 * the stack to the next C frame.  Intervening Dart frames will be
 * discarded; specifically, 'finally' blocks will not execute.  This
 * is the standard way that compilation errors (and the like) are
 * handled by the Dart runtime.
 *
 * In either case, when an error is propagated any current scopes
 * created by Dart_EnterScope will be exited.
 *
 * See the additional discussion under "Propagating Errors" at the
 * beginning of this file.
 *
 * \param handle An error handle (See Dart_IsError)
 *
 * On success, this function does not return.  On failure, the
 * process is terminated.
 */
DART_EXPORT void Dart_PropagateError(Dart_Handle handle);

/**
 * Converts an object to a string.
 *
 * May generate an unhandled exception error.
 *
 * \return The converted string if no error occurs during
 *   the conversion. If an error does occur, an error handle is
 *   returned.
 */
DART_EXPORT Dart_Handle Dart_ToString(Dart_Handle object);

/**
 * Checks to see if two handles refer to identically equal objects.
 *
 * If both handles refer to instances, this is equivalent to using the top-level
 * function identical() from dart:core. Otherwise, returns whether the two
 * argument handles refer to the same object.
 *
 * \param obj1 An object to be compared.
 * \param obj2 An object to be compared.
 *
 * \return True if the objects are identically equal.  False otherwise.
 */
DART_EXPORT bool Dart_IdentityEquals(Dart_Handle obj1, Dart_Handle obj2);

/**
 * Allocates a handle in the current scope from a persistent handle.
 */
DART_EXPORT Dart_Handle Dart_HandleFromPersistent(Dart_PersistentHandle object);

/**
 * Allocates a handle in the current scope from a weak persistent handle.
 *
 * This will be a handle to Dart_Null if the object has been garbage collected.
 */
DART_EXPORT Dart_Handle
Dart_HandleFromWeakPersistent(Dart_WeakPersistentHandle object);

/**
 * Allocates a persistent handle for an object.
 *
 * This handle has the lifetime of the current isolate unless it is
 * explicitly deallocated by calling Dart_DeletePersistentHandle.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_PersistentHandle Dart_NewPersistentHandle(Dart_Handle object);

/**
 * Assign value of local handle to a persistent handle.
 *
 * Requires there to be a current isolate.
 *
 * \param obj1 A persistent handle whose value needs to be set.
 * \param obj2 An object whose value needs to be set to the persistent handle.
 */
DART_EXPORT void Dart_SetPersistentHandle(Dart_PersistentHandle obj1,
                                          Dart_Handle obj2);

/**
 * Deallocates a persistent handle.
 *
 * Requires there to be a current isolate group.
 */
DART_EXPORT void Dart_DeletePersistentHandle(Dart_PersistentHandle object);

/**
 * Allocates a weak persistent handle for an object.
 *
 * This handle has the lifetime of the current isolate. The handle can also be
 * explicitly deallocated by calling Dart_DeleteWeakPersistentHandle.
 *
 * If the object becomes unreachable the callback is invoked with the peer as
 * argument. The callback can be executed on any thread, will have a current
 * isolate group, but will not have a current isolate. The callback can only
 * call Dart_DeletePersistentHandle or Dart_DeleteWeakPersistentHandle. This
 * gives the embedder the ability to cleanup data associated with the object.
 * The handle will point to the Dart_Null object after the finalizer has been
 * run. It is illegal to call into the VM with any other Dart_* functions from
 * the callback. If the handle is deleted before the object becomes
 * unreachable, the callback is never invoked.
 *
 * Requires there to be a current isolate.
 *
 * \param object An object with identity.
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param external_allocation_size The number of externally allocated
 *   bytes for peer. Used to inform the garbage collector.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected, unless the handle has been deleted.
 *   A valid callback needs to be specified it cannot be NULL.
 *
 * \return The weak persistent handle or NULL. NULL is returned in case of bad
 *   parameters.
 */
DART_EXPORT Dart_WeakPersistentHandle
Dart_NewWeakPersistentHandle(Dart_Handle object,
                             void* peer,
                             intptr_t external_allocation_size,
                             Dart_HandleFinalizer callback);

/**
 * Deletes the given weak persistent [object] handle.
 *
 * Requires there to be a current isolate group.
 */
DART_EXPORT void Dart_DeleteWeakPersistentHandle(
    Dart_WeakPersistentHandle object);

/**
 * Allocates a finalizable handle for an object.
 *
 * This handle has the lifetime of the current isolate group unless the object
 * pointed to by the handle is garbage collected, in this case the VM
 * automatically deletes the handle after invoking the callback associated
 * with the handle. The handle can also be explicitly deallocated by
 * calling Dart_DeleteFinalizableHandle.
 *
 * If the object becomes unreachable the callback is invoked with the
 * the peer as argument. The callback can be executed on any thread, will have
 * an isolate group, but will not have a current isolate. The callback can only
 * call Dart_DeletePersistentHandle or Dart_DeleteWeakPersistentHandle.
 * This gives the embedder the ability to cleanup data associated with the
 * object and clear out any cached references to the handle. All references to
 * this handle after the callback will be invalid. It is illegal to call into
 * the VM with any other Dart_* functions from the callback. If the handle is
 * deleted before the object becomes unreachable, the callback is never
 * invoked.
 *
 * Requires there to be a current isolate.
 *
 * \param object An object with identity.
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param external_allocation_size The number of externally allocated
 *   bytes for peer. Used to inform the garbage collector.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected, unless the handle has been deleted.
 *   A valid callback needs to be specified it cannot be NULL.
 *
 * \return The finalizable handle or NULL. NULL is returned in case of bad
 *   parameters.
 */
DART_EXPORT Dart_FinalizableHandle
Dart_NewFinalizableHandle(Dart_Handle object,
                          void* peer,
                          intptr_t external_allocation_size,
                          Dart_HandleFinalizer callback);

/**
 * Deletes the given finalizable [object] handle.
 *
 * The caller has to provide the actual Dart object the handle was created from
 * to prove the object (and therefore the finalizable handle) is still alive.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_DeleteFinalizableHandle(Dart_FinalizableHandle object,
                                              Dart_Handle strong_ref_to_object);

/*
 * ==========================
 * Initialization and Globals
 * ==========================
 */

/**
 * Gets the version string for the Dart VM.
 *
 * The version of the Dart VM can be accessed without initializing the VM.
 *
 * \return The version string for the embedded Dart VM.
 */
DART_EXPORT const char* Dart_VersionString(void);

/**
 * Isolate specific flags are set when creating a new isolate using the
 * Dart_IsolateFlags structure.
 *
 * Current version of flags is encoded in a 32-bit integer with 16 bits used
 * for each part.
 */

#define DART_FLAGS_CURRENT_VERSION (0x0000000d)

typedef struct {
  int32_t version;
  bool enable_asserts;
  bool use_field_guards;
  bool use_osr;
  bool obfuscate;
  bool load_vmservice_library;
  bool null_safety;
  bool is_system_isolate;
  bool is_service_isolate;
  bool is_kernel_isolate;
  bool snapshot_is_dontneed_safe;
  bool branch_coverage;
  bool coverage;
} Dart_IsolateFlags;

/**
 * Initialize Dart_IsolateFlags with correct version and default values.
 */
DART_EXPORT void Dart_IsolateFlagsInitialize(Dart_IsolateFlags* flags);

/**
 * An isolate creation and initialization callback function.
 *
 * This callback, provided by the embedder, is called when the VM
 * needs to create an isolate. The callback should create an isolate
 * by calling Dart_CreateIsolateGroup and load any scripts required for
 * execution.
 *
 * This callback may be called on a different thread than the one
 * running the parent isolate.
 *
 * When the function returns NULL, it is the responsibility of this
 * function to ensure that Dart_ShutdownIsolate has been called if
 * required (for example, if the isolate was created successfully by
 * Dart_CreateIsolateGroup() but the root library fails to load
 * successfully, then the function should call Dart_ShutdownIsolate
 * before returning).
 *
 * When the function returns NULL, the function should set *error to
 * a malloc-allocated buffer containing a useful error message.  The
 * caller of this function (the VM) will make sure that the buffer is
 * freed.
 *
 * \param script_uri The uri of the main source file or snapshot to load.
 *   Either the URI of the parent isolate set in Dart_CreateIsolateGroup for
 *   Isolate.spawn, or the argument to Isolate.spawnUri canonicalized by the
 *   library tag handler of the parent isolate.
 *   The callback is responsible for loading the program by a call to
 *   Dart_LoadScriptFromKernel.
 * \param main The name of the main entry point this isolate will
 *   eventually run.  This is provided for advisory purposes only to
 *   improve debugging messages.  The main function is not invoked by
 *   this function.
 * \param package_root Ignored.
 * \param package_config Uri of the package configuration file (either in format
 *   of .packages or .dart_tool/package_config.json) for this isolate
 *   to resolve package imports against. If this parameter is not passed the
 *   package resolution of the parent isolate should be used.
 * \param flags Default flags for this isolate being spawned. Either inherited
 *   from the spawning isolate or passed as parameters when spawning the
 *   isolate from Dart code.
 * \param isolate_data The isolate data which was passed to the
 *   parent isolate when it was created by calling Dart_CreateIsolateGroup().
 * \param error A structure into which the embedder can place a
 *   C string containing an error message in the case of failures.
 *
 * \return The embedder returns NULL if the creation and
 *   initialization was not successful and the isolate if successful.
 */
typedef Dart_Isolate (*Dart_IsolateGroupCreateCallback)(
    const char* script_uri,
    const char* main,
    const char* package_root,
    const char* package_config,
    Dart_IsolateFlags* flags,
    void* isolate_data,
    char** error);

/**
 * An isolate initialization callback function.
 *
 * This callback, provided by the embedder, is called when the VM has created an
 * isolate within an existing isolate group (i.e. from the same source as an
 * existing isolate).
 *
 * The callback should setup native resolvers and might want to set a custom
 * message handler via [Dart_SetMessageNotifyCallback] and mark the isolate as
 * runnable.
 *
 * This callback may be called on a different thread than the one
 * running the parent isolate.
 *
 * When the function returns `false`, it is the responsibility of this
 * function to ensure that `Dart_ShutdownIsolate` has been called.
 *
 * When the function returns `false`, the function should set *error to
 * a malloc-allocated buffer containing a useful error message.  The
 * caller of this function (the VM) will make sure that the buffer is
 * freed.
 *
 * \param child_isolate_data The callback data to associate with the new
 *        child isolate.
 * \param error A structure into which the embedder can place a
 *   C string containing an error message in the case the initialization fails.
 *
 * \return The embedder returns true if the initialization was successful and
 *         false otherwise (in which case the VM will terminate the isolate).
 */
typedef bool (*Dart_InitializeIsolateCallback)(void** child_isolate_data,
                                               char** error);

/**
 * An isolate shutdown callback function.
 *
 * This callback, provided by the embedder, is called before the vm
 * shuts down an isolate.  The isolate being shutdown will be the current
 * isolate. It is safe to run Dart code.
 *
 * This function should be used to dispose of native resources that
 * are allocated to an isolate in order to avoid leaks.
 *
 * \param isolate_group_data The same callback data which was passed to the
 *   isolate group when it was created.
 * \param isolate_data The same callback data which was passed to the isolate
 *   when it was created.
 */
typedef void (*Dart_IsolateShutdownCallback)(void* isolate_group_data,
                                             void* isolate_data);

/**
 * An isolate cleanup callback function.
 *
 * This callback, provided by the embedder, is called after the vm
 * shuts down an isolate. There will be no current isolate and it is *not*
 * safe to run Dart code.
 *
 * This function should be used to dispose of native resources that
 * are allocated to an isolate in order to avoid leaks.
 *
 * \param isolate_group_data The same callback data which was passed to the
 *   isolate group when it was created.
 * \param isolate_data The same callback data which was passed to the isolate
 *   when it was created.
 */
typedef void (*Dart_IsolateCleanupCallback)(void* isolate_group_data,
                                            void* isolate_data);

/**
 * An isolate group cleanup callback function.
 *
 * This callback, provided by the embedder, is called after the vm
 * shuts down an isolate group.
 *
 * This function should be used to dispose of native resources that
 * are allocated to an isolate in order to avoid leaks.
 *
 * \param isolate_group_data The same callback data which was passed to the
 *   isolate group when it was created.
 *
 */
typedef void (*Dart_IsolateGroupCleanupCallback)(void* isolate_group_data);

/**
 * A thread start callback function.
 * This callback, provided by the embedder, is called after a thread in the
 * vm thread pool starts.
 * This function could be used to adjust thread priority or attach native
 * resources to the thread.
 */
typedef void (*Dart_ThreadStartCallback)(void);

/**
 * A thread death callback function.
 * This callback, provided by the embedder, is called before a thread in the
 * vm thread pool exits.
 * This function could be used to dispose of native resources that
 * are associated and attached to the thread, in order to avoid leaks.
 */
typedef void (*Dart_ThreadExitCallback)(void);

/**
 * Opens a file for reading or writing.
 *
 * Callback provided by the embedder for file operations. If the
 * embedder does not allow file operations this callback can be
 * NULL.
 *
 * \param name The name of the file to open.
 * \param write A boolean variable which indicates if the file is to
 *   opened for writing. If there is an existing file it needs to truncated.
 */
typedef void* (*Dart_FileOpenCallback)(const char* name, bool write);

/**
 * Read contents of file.
 *
 * Callback provided by the embedder for file operations. If the
 * embedder does not allow file operations this callback can be
 * NULL.
 *
 * \param data Buffer allocated in the callback into which the contents
 *   of the file are read into. It is the responsibility of the caller to
 *   free this buffer.
 * \param file_length A variable into which the length of the file is returned.
 *   In the case of an error this value would be -1.
 * \param stream Handle to the opened file.
 */
typedef void (*Dart_FileReadCallback)(uint8_t** data,
                                      intptr_t* file_length,
                                      void* stream);

/**
 * Write data into file.
 *
 * Callback provided by the embedder for file operations. If the
 * embedder does not allow file operations this callback can be
 * NULL.
 *
 * \param data Buffer which needs to be written into the file.
 * \param length Length of the buffer.
 * \param stream Handle to the opened file.
 */
typedef void (*Dart_FileWriteCallback)(const void* data,
                                       intptr_t length,
                                       void* stream);

/**
 * Closes the opened file.
 *
 * Callback provided by the embedder for file operations. If the
 * embedder does not allow file operations this callback can be
 * NULL.
 *
 * \param stream Handle to the opened file.
 */
typedef void (*Dart_FileCloseCallback)(void* stream);

typedef bool (*Dart_EntropySource)(uint8_t* buffer, intptr_t length);

/**
 * Callback provided by the embedder that is used by the vmservice isolate
 * to request the asset archive. The asset archive must be an uncompressed tar
 * archive that is stored in a Uint8List.
 *
 * If the embedder has no vmservice isolate assets, the callback can be NULL.
 *
 * \return The embedder must return a handle to a Uint8List containing an
 *   uncompressed tar archive or null.
 */
typedef Dart_Handle (*Dart_GetVMServiceAssetsArchive)(void);

/**
 * The current version of the Dart_InitializeFlags. Should be incremented every
 * time Dart_InitializeFlags changes in a binary incompatible way.
 */
#define DART_INITIALIZE_PARAMS_CURRENT_VERSION (0x00000008)

/** Forward declaration */
struct Dart_CodeObserver;

/**
 * Callback provided by the embedder that is used by the VM to notify on code
 * object creation, *before* it is invoked the first time.
 * This is useful for embedders wanting to e.g. keep track of PCs beyond
 * the lifetime of the garbage collected code objects.
 * Note that an address range may be used by more than one code object over the
 * lifecycle of a process. Clients of this function should record timestamps for
 * these compilation events and when collecting PCs to disambiguate reused
 * address ranges.
 */
typedef void (*Dart_OnNewCodeCallback)(struct Dart_CodeObserver* observer,
                                       const char* name,
                                       uintptr_t base,
                                       uintptr_t size);

typedef struct Dart_CodeObserver {
  void* data;

  Dart_OnNewCodeCallback on_new_code;
} Dart_CodeObserver;

/**
 * Optional callback provided by the embedder that is used by the VM to
 * implement registration of kernel blobs for the subsequent Isolate.spawnUri
 * If no callback is provided, the registration of kernel blobs will throw
 * an error.
 *
 * \param kernel_buffer A buffer which contains a kernel program. Callback
 *                      should copy the contents of `kernel_buffer` as
 *                      it may be freed immediately after registration.
 * \param kernel_buffer_size The size of `kernel_buffer`.
 *
 * \return A C string representing URI which can be later used
 *         to spawn a new isolate. This C String should be scope allocated
 *         or owned by the embedder.
 *         Returns NULL if embedder runs out of memory.
 */
typedef const char* (*Dart_RegisterKernelBlobCallback)(
    const uint8_t* kernel_buffer,
    intptr_t kernel_buffer_size);

/**
 * Optional callback provided by the embedder that is used by the VM to
 * unregister kernel blobs.
 * If no callback is provided, the unregistration of kernel blobs will throw
 * an error.
 *
 * \param kernel_blob_uri URI of the kernel blob to unregister.
 */
typedef void (*Dart_UnregisterKernelBlobCallback)(const char* kernel_blob_uri);

/**
 * Describes how to initialize the VM. Used with Dart_Initialize.
 */
typedef struct {
  /**
   * Identifies the version of the struct used by the client.
   * should be initialized to DART_INITIALIZE_PARAMS_CURRENT_VERSION.
   */
  int32_t version;

  /**
   * A buffer containing snapshot data, or NULL if no snapshot is provided.
   *
   * If provided, the buffer must remain valid until Dart_Cleanup returns.
   */
  const uint8_t* vm_snapshot_data;

  /**
   * A buffer containing a snapshot of precompiled instructions, or NULL if
   * no snapshot is provided.
   *
   * If provided, the buffer must remain valid until Dart_Cleanup returns.
   */
  const uint8_t* vm_snapshot_instructions;

  /**
   * A function to be called during isolate group creation.
   * See Dart_IsolateGroupCreateCallback.
   */
  Dart_IsolateGroupCreateCallback create_group;

  /**
   * A function to be called during isolate
   * initialization inside an existing isolate group.
   * See Dart_InitializeIsolateCallback.
   */
  Dart_InitializeIsolateCallback initialize_isolate;

  /**
   * A function to be called right before an isolate is shutdown.
   * See Dart_IsolateShutdownCallback.
   */
  Dart_IsolateShutdownCallback shutdown_isolate;

  /**
   * A function to be called after an isolate was shutdown.
   * See Dart_IsolateCleanupCallback.
   */
  Dart_IsolateCleanupCallback cleanup_isolate;

  /**
   * A function to be called after an isolate group is
   * shutdown. See Dart_IsolateGroupCleanupCallback.
   */
  Dart_IsolateGroupCleanupCallback cleanup_group;

  Dart_ThreadStartCallback thread_start;
  Dart_ThreadExitCallback thread_exit;
  Dart_FileOpenCallback file_open;
  Dart_FileReadCallback file_read;
  Dart_FileWriteCallback file_write;
  Dart_FileCloseCallback file_close;
  Dart_EntropySource entropy_source;

  /**
   * A function to be called by the service isolate when it requires the
   * vmservice assets archive. See Dart_GetVMServiceAssetsArchive.
   */
  Dart_GetVMServiceAssetsArchive get_service_assets;

  bool start_kernel_isolate;

  /**
   * An external code observer callback function. The observer can be invoked
   * as early as during the Dart_Initialize() call.
   */
  Dart_CodeObserver* code_observer;

  /**
   * Kernel blob registration callback function. See Dart_RegisterKernelBlobCallback.
   */
  Dart_RegisterKernelBlobCallback register_kernel_blob;

  /**
   * Kernel blob unregistration callback function. See Dart_UnregisterKernelBlobCallback.
   */
  Dart_UnregisterKernelBlobCallback unregister_kernel_blob;

#if defined(__Fuchsia__)
  /**
   * The resource needed to use zx_vmo_replace_as_executable. Can be
   * ZX_HANDLE_INVALID if the process has ambient-replace-as-executable or if
   * executable memory is not needed (e.g., this is an AOT runtime).
   */
  zx_handle_t vmex_resource;
#endif
} Dart_InitializeParams;

/**
 * Initializes the VM.
 *
 * \param params A struct containing initialization information. The version
 *   field of the struct must be DART_INITIALIZE_PARAMS_CURRENT_VERSION.
 *
 * \return NULL if initialization is successful. Returns an error message
 *   otherwise. The caller is responsible for freeing the error message.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT char* Dart_Initialize(
    Dart_InitializeParams* params);

/**
 * Cleanup state in the VM before process termination.
 *
 * \return NULL if cleanup is successful. Returns an error message otherwise.
 *   The caller is responsible for freeing the error message.
 *
 * NOTE: This function must not be called on a thread that was created by the VM
 * itself.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT char* Dart_Cleanup(void);

/**
 * Sets command line flags. Should be called before Dart_Initialize.
 *
 * \param argc The length of the arguments array.
 * \param argv An array of arguments.
 *
 * \return NULL if successful. Returns an error message otherwise.
 *  The caller is responsible for freeing the error message.
 *
 * NOTE: This call does not store references to the passed in c-strings.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT char* Dart_SetVMFlags(int argc,
                                                          const char** argv);

/**
 * Returns true if the named VM flag is of boolean type, specified, and set to
 * true.
 *
 * \param flag_name The name of the flag without leading punctuation
 *                  (example: "enable_asserts").
 */
DART_EXPORT bool Dart_IsVMFlagSet(const char* flag_name);

/*
 * ========
 * Isolates
 * ========
 */

/**
 * Creates a new isolate. The new isolate becomes the current isolate.
 *
 * A snapshot can be used to restore the VM quickly to a saved state
 * and is useful for fast startup. If snapshot data is provided, the
 * isolate will be started using that snapshot data. Requires a core snapshot or
 * an app snapshot created by Dart_CreateSnapshot or
 * Dart_CreatePrecompiledSnapshot* from a VM with the same version.
 *
 * Requires there to be no current isolate.
 *
 * \param script_uri The main source file or snapshot this isolate will load.
 *   The VM will provide this URI to the Dart_IsolateGroupCreateCallback when a
 *   child isolate is created by Isolate.spawn. The embedder should use a URI
 *   that allows it to load the same program into such a child isolate.
 * \param name A short name for the isolate to improve debugging messages.
 *   Typically of the format 'foo.dart:main()'.
 * \param isolate_snapshot_data Buffer containing the snapshot data of the
 *   isolate or NULL if no snapshot is provided. If provided, the buffer must
 *   remain valid until the isolate shuts down.
 * \param isolate_snapshot_instructions Buffer containing the snapshot
 *   instructions of the isolate or NULL if no snapshot is provided. If
 *   provided, the buffer must remain valid until the isolate shuts down.
 * \param flags Pointer to VM specific flags or NULL for default flags.
 * \param isolate_group_data Embedder group data. This data can be obtained
 *   by calling Dart_IsolateGroupData and will be passed to the
 *   Dart_IsolateShutdownCallback, Dart_IsolateCleanupCallback, and
 *   Dart_IsolateGroupCleanupCallback.
 * \param isolate_data Embedder data.  This data will be passed to
 *   the Dart_IsolateGroupCreateCallback when new isolates are spawned from
 *   this parent isolate.
 * \param error Returns NULL if creation is successful, an error message
 *   otherwise. The caller is responsible for calling free() on the error
 *   message.
 *
 * \return The new isolate on success, or NULL if isolate creation failed.
 */
DART_EXPORT Dart_Isolate
Dart_CreateIsolateGroup(const char* script_uri,
                        const char* name,
                        const uint8_t* isolate_snapshot_data,
                        const uint8_t* isolate_snapshot_instructions,
                        Dart_IsolateFlags* flags,
                        void* isolate_group_data,
                        void* isolate_data,
                        char** error);
/**
 * Creates a new isolate inside the isolate group of [group_member].
 *
 * Requires there to be no current isolate.
 *
 * \param group_member An isolate from the same group into which the newly created
 *   isolate should be born into. Other threads may not have entered / enter this
 *   member isolate.
 * \param name A short name for the isolate for debugging purposes.
 * \param shutdown_callback A callback to be called when the isolate is being
 *   shutdown (may be NULL).
 * \param cleanup_callback A callback to be called when the isolate is being
 *   cleaned up (may be NULL).
 * \param child_isolate_data The embedder-specific data associated with this isolate.
 * \param error Set to NULL if creation is successful, set to an error
 *   message otherwise. The caller is responsible for calling free() on the
 *   error message.
 *
 * \return The newly created isolate on success, or NULL if isolate creation
 *   failed.
 *
 * If successful, the newly created isolate will become the current isolate.
 */
DART_EXPORT Dart_Isolate
Dart_CreateIsolateInGroup(Dart_Isolate group_member,
                          const char* name,
                          Dart_IsolateShutdownCallback shutdown_callback,
                          Dart_IsolateCleanupCallback cleanup_callback,
                          void* child_isolate_data,
                          char** error);

/* TODO(turnidge): Document behavior when there is already a current
 * isolate. */

/**
 * Creates a new isolate from a Dart Kernel file. The new isolate
 * becomes the current isolate.
 *
 * Requires there to be no current isolate.
 *
 * \param script_uri The main source file or snapshot this isolate will load.
 *   The VM will provide this URI to the Dart_IsolateGroupCreateCallback when a
 * child isolate is created by Isolate.spawn. The embedder should use a URI that
 *   allows it to load the same program into such a child isolate.
 * \param name A short name for the isolate to improve debugging messages.
 *   Typically of the format 'foo.dart:main()'.
 * \param kernel_buffer A buffer which contains a kernel/DIL program. Must
 *   remain valid until isolate shutdown.
 * \param kernel_buffer_size The size of `kernel_buffer`.
 * \param flags Pointer to VM specific flags or NULL for default flags.
 * \param isolate_group_data Embedder group data. This data can be obtained
 *   by calling Dart_IsolateGroupData and will be passed to the
 *   Dart_IsolateShutdownCallback, Dart_IsolateCleanupCallback, and
 *   Dart_IsolateGroupCleanupCallback.
 * \param isolate_data Embedder data.  This data will be passed to
 *   the Dart_IsolateGroupCreateCallback when new isolates are spawned from
 *   this parent isolate.
 * \param error Returns NULL if creation is successful, an error message
 *   otherwise. The caller is responsible for calling free() on the error
 *   message.
 *
 * \return The new isolate on success, or NULL if isolate creation failed.
 */
DART_EXPORT Dart_Isolate
Dart_CreateIsolateGroupFromKernel(const char* script_uri,
                                  const char* name,
                                  const uint8_t* kernel_buffer,
                                  intptr_t kernel_buffer_size,
                                  Dart_IsolateFlags* flags,
                                  void* isolate_group_data,
                                  void* isolate_data,
                                  char** error);
/**
 * Shuts down the current isolate. After this call, the current isolate is NULL.
 * Any current scopes created by Dart_EnterScope will be exited. Invokes the
 * shutdown callback and any callbacks of remaining weak persistent handles.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ShutdownIsolate(void);
/* TODO(turnidge): Document behavior when there is no current isolate. */

/**
 * Returns the current isolate. Will return NULL if there is no
 * current isolate.
 */
DART_EXPORT Dart_Isolate Dart_CurrentIsolate(void);

/**
 * Returns the callback data associated with the current isolate. This
 * data was set when the isolate got created or initialized.
 */
DART_EXPORT void* Dart_CurrentIsolateData(void);

/**
 * Returns the callback data associated with the given isolate. This
 * data was set when the isolate got created or initialized.
 */
DART_EXPORT void* Dart_IsolateData(Dart_Isolate isolate);

/**
 * Returns the current isolate group. Will return NULL if there is no
 * current isolate group.
 */
DART_EXPORT Dart_IsolateGroup Dart_CurrentIsolateGroup(void);

/**
 * Returns the callback data associated with the current isolate group. This
 * data was passed to the isolate group when it was created.
 */
DART_EXPORT void* Dart_CurrentIsolateGroupData(void);

/**
 * Gets an id that uniquely identifies current isolate group.
 *
 * It is the responsibility of the caller to free the returned ID.
 */
typedef int64_t Dart_IsolateGroupId;
DART_EXPORT Dart_IsolateGroupId Dart_CurrentIsolateGroupId(void);

/**
 * Returns the callback data associated with the specified isolate group. This
 * data was passed to the isolate when it was created.
 * The embedder is responsible for ensuring the consistency of this data
 * with respect to the lifecycle of an isolate group.
 */
DART_EXPORT void* Dart_IsolateGroupData(Dart_Isolate isolate);

/**
 * Returns the debugging name for the current isolate.
 *
 * This name is unique to each isolate and should only be used to make
 * debugging messages more comprehensible.
 */
DART_EXPORT Dart_Handle Dart_DebugName(void);

/**
 * Returns the debugging name for the current isolate.
 *
 * This name is unique to each isolate and should only be used to make
 * debugging messages more comprehensible.
 *
 * The returned string is scope allocated and is only valid until the next call
 * to Dart_ExitScope.
 */
DART_EXPORT const char* Dart_DebugNameToCString(void);

/**
 * Returns the ID for an isolate which is used to query the service protocol.
 *
 * It is the responsibility of the caller to free the returned ID.
 */
DART_EXPORT const char* Dart_IsolateServiceId(Dart_Isolate isolate);

/**
 * Enters an isolate. After calling this function,
 * the current isolate will be set to the provided isolate.
 *
 * Requires there to be no current isolate. Multiple threads may not be in
 * the same isolate at once.
 */
DART_EXPORT void Dart_EnterIsolate(Dart_Isolate isolate);

/**
 * Kills the given isolate.
 *
 * This function has the same effect as dart:isolate's
 * Isolate.kill(priority:immediate).
 * It can interrupt ordinary Dart code but not native code. If the isolate is
 * in the middle of a long running native function, the isolate will not be
 * killed until control returns to Dart.
 *
 * Does not require a current isolate. It is safe to kill the current isolate if
 * there is one.
 */
DART_EXPORT void Dart_KillIsolate(Dart_Isolate isolate);

/**
 * Notifies the VM that the embedder expects to be idle until |deadline|. The VM
 * may use this time to perform garbage collection or other tasks to avoid
 * delays during execution of Dart code in the future.
 *
 * |deadline| is measured in microseconds against the system's monotonic time.
 * This clock can be accessed via Dart_TimelineGetMicros().
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_NotifyIdle(int64_t deadline);

typedef void (*Dart_HeapSamplingReportCallback)(void* context, void* data);

typedef void* (*Dart_HeapSamplingCreateCallback)(
    Dart_Isolate isolate,
    Dart_IsolateGroup isolate_group,
    const char* cls_name,
    intptr_t allocation_size);
typedef void (*Dart_HeapSamplingDeleteCallback)(void* data);

/**
 * Starts the heap sampling profiler for each thread in the VM.
 */
DART_EXPORT void Dart_EnableHeapSampling(void);

/*
 * Stops the heap sampling profiler for each thread in the VM.
 */
DART_EXPORT void Dart_DisableHeapSampling(void);

/* Registers callbacks are invoked once per sampled allocation upon object
 * allocation and garbage collection.
 *
 * |create_callback| can be used to associate additional data with the sampled
 * allocation, such as a stack trace. This data pointer will be passed to
 * |delete_callback| to allow for proper disposal when the object associated
 * with the allocation sample is collected.
 *
 * The provided callbacks must not call into the VM and should do as little
 * work as possible to avoid performance penalities during object allocation and
 * garbage collection.
 *
 * NOTE: It is a fatal error to set either callback to null once they have been
 * initialized.
 */
DART_EXPORT void Dart_RegisterHeapSamplingCallback(
    Dart_HeapSamplingCreateCallback create_callback,
    Dart_HeapSamplingDeleteCallback delete_callback);

/*
 * Reports the surviving allocation samples for all live isolate groups in the
 * VM.
 *
 * When the callback is invoked:
 *  - |context| will be the context object provided when invoking
 *    |Dart_ReportSurvivingAllocations|. This can be safely set to null if not
 *    required.
 *  - |heap_size| will be equal to the size of the allocated object associated
 *    with the sample.
 *  - |cls_name| will be a C String representing
 *    the class name of the allocated object. This string is valid for the
 *    duration of the call to Dart_ReportSurvivingAllocations and can be
 *    freed by the VM at any point after the method returns.
 *  - |data| will be set to the data associated with the sample by
 *    |Dart_HeapSamplingCreateCallback|.
 *
 * If |force_gc| is true, a full GC will be performed before reporting the
 * allocations.
 */
DART_EXPORT void Dart_ReportSurvivingAllocations(
    Dart_HeapSamplingReportCallback callback,
    void* context,
    bool force_gc);

/*
 * Sets the average heap sampling rate based on a number of |bytes| for each
 * thread.
 *
 * In other words, approximately every |bytes| allocated will create a sample.
 * Defaults to 512 KiB.
 */
DART_EXPORT void Dart_SetHeapSamplingPeriod(intptr_t bytes);

/**
 * Notifies the VM that the embedder expects the application's working set has
 * recently shrunk significantly and is not expected to rise in the near future.
 * The VM may spend O(heap-size) time performing clean up work.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_NotifyDestroyed(void);

/**
 * Notifies the VM that the system is running low on memory.
 *
 * Does not require a current isolate. Only valid after calling Dart_Initialize.
 */
DART_EXPORT void Dart_NotifyLowMemory(void);

typedef enum {
  /**
   * Balanced
   */
  Dart_PerformanceMode_Default,
  /**
   * Optimize for low latency, at the expense of throughput and memory overhead
   * by performing work in smaller batches (requiring more overhead) or by
   * delaying work (requiring more memory). An embedder should not remain in
   * this mode indefinitely.
   */
  Dart_PerformanceMode_Latency,
  /**
   * Optimize for high throughput, at the expense of latency and memory overhead
   * by performing work in larger batches with more intervening growth.
   */
  Dart_PerformanceMode_Throughput,
  /**
   * Optimize for low memory, at the expensive of throughput and latency by more
   * frequently performing work.
   */
  Dart_PerformanceMode_Memory,
} Dart_PerformanceMode;

/**
 * Set the desired performance trade-off.
 *
 * Requires a current isolate.
 *
 * Returns the previous performance mode.
 */
DART_EXPORT Dart_PerformanceMode
Dart_SetPerformanceMode(Dart_PerformanceMode mode);

/**
 * Starts the CPU sampling profiler.
 */
DART_EXPORT void Dart_StartProfiling(void);

/**
 * Stops the CPU sampling profiler.
 *
 * Note that some profile samples might still be taken after this function
 * returns due to the asynchronous nature of the implementation on some
 * platforms.
 */
DART_EXPORT void Dart_StopProfiling(void);

/**
 * Notifies the VM that the current thread should not be profiled until a
 * matching call to Dart_ThreadEnableProfiling is made.
 *
 * NOTE: By default, if a thread has entered an isolate it will be profiled.
 * This function should be used when an embedder knows a thread is about
 * to make a blocking call and wants to avoid unnecessary interrupts by
 * the profiler.
 */
DART_EXPORT void Dart_ThreadDisableProfiling(void);

/**
 * Notifies the VM that the current thread should be profiled.
 *
 * NOTE: It is only legal to call this function *after* calling
 *   Dart_ThreadDisableProfiling.
 *
 * NOTE: By default, if a thread has entered an isolate it will be profiled.
 */
DART_EXPORT void Dart_ThreadEnableProfiling(void);

/**
 * Register symbol information for the Dart VM's profiler and crash dumps.
 *
 * This consumes the output of //topaz/runtime/dart/profiler_symbols, which
 * should be treated as opaque.
 */
DART_EXPORT void Dart_AddSymbols(const char* dso_name,
                                 void* buffer,
                                 intptr_t buffer_size);

/**
 * Exits an isolate. After this call, Dart_CurrentIsolate will
 * return NULL.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ExitIsolate(void);
/* TODO(turnidge): We don't want users of the api to be able to exit a
 * "pure" dart isolate. Implement and document. */

/**
 * Creates a full snapshot of the current isolate heap.
 *
 * A full snapshot is a compact representation of the dart vm isolate heap
 * and dart isolate heap states. These snapshots are used to initialize
 * the vm isolate on startup and fast initialization of an isolate.
 * A Snapshot of the heap is created before any dart code has executed.
 *
 * Requires there to be a current isolate. Not available in the precompiled
 * runtime (check Dart_IsPrecompiledRuntime).
 *
 * \param vm_snapshot_data_buffer Returns a pointer to a buffer containing the
 *   vm snapshot. This buffer is scope allocated and is only valid
 *   until the next call to Dart_ExitScope.
 * \param vm_snapshot_data_size Returns the size of vm_snapshot_data_buffer.
 * \param isolate_snapshot_data_buffer Returns a pointer to a buffer containing
 *   the isolate snapshot. This buffer is scope allocated and is only valid
 *   until the next call to Dart_ExitScope.
 * \param isolate_snapshot_data_size Returns the size of
 *   isolate_snapshot_data_buffer.
 * \param is_core Create a snapshot containing core libraries.
 *   Such snapshot should be agnostic to null safety mode.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateSnapshot(uint8_t** vm_snapshot_data_buffer,
                    intptr_t* vm_snapshot_data_size,
                    uint8_t** isolate_snapshot_data_buffer,
                    intptr_t* isolate_snapshot_data_size,
                    bool is_core);

/**
 * Returns whether the buffer contains a kernel file.
 *
 * \param buffer Pointer to a buffer that might contain a kernel binary.
 * \param buffer_size Size of the buffer.
 *
 * \return Whether the buffer contains a kernel binary (full or partial).
 */
DART_EXPORT bool Dart_IsKernel(const uint8_t* buffer, intptr_t buffer_size);

/**
 * Make isolate runnable.
 *
 * When isolates are spawned, this function is used to indicate that
 * the creation and initialization (including script loading) of the
 * isolate is complete and the isolate can start.
 * This function expects there to be no current isolate.
 *
 * \param isolate The isolate to be made runnable.
 *
 * \return NULL if successful. Returns an error message otherwise. The caller
 * is responsible for freeing the error message.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT char* Dart_IsolateMakeRunnable(
    Dart_Isolate isolate);

/*
 * ==================
 * Messages and Ports
 * ==================
 */

/**
 * A port is used to send or receive inter-isolate messages
 */
typedef int64_t Dart_Port;
typedef struct {
  int64_t port_id;
  int64_t origin_id;
} Dart_PortEx;

/**
 * ILLEGAL_PORT is a port number guaranteed never to be associated with a valid
 * port.
 */
#define ILLEGAL_PORT ((Dart_Port)0)

/**
 * A message notification callback.
 *
 * This callback allows the embedder to provide a custom wakeup mechanism for
 * the delivery of inter-isolate messages. This function is called once per
 * message on an arbitrary thread. It is the responsibility of the embedder to
 * eventually call Dart_HandleMessage once per callback received with the
 * destination isolate set as the current isolate to process the message.
 */
typedef void (*Dart_MessageNotifyCallback)(Dart_Isolate destination_isolate);

/**
 * Allows embedders to provide a custom wakeup mechanism for the delivery of
 * inter-isolate messages. This setting only applies to the current isolate.
 *
 * This mechanism is optional: if not provided, the isolate will be scheduled on
 * a VM-managed thread pool. An embedder should provide this callback if it
 * wants to run an isolate on a specific thread or to interleave handling of
 * inter-isolate messages with other event sources.
 *
 * Most embedders will only call this function once, before isolate
 * execution begins. If this function is called after isolate
 * execution begins, the embedder is responsible for threading issues.
 */
DART_EXPORT void Dart_SetMessageNotifyCallback(
    Dart_MessageNotifyCallback message_notify_callback);
/* TODO(turnidge): Consider moving this to isolate creation so that it
 * is impossible to mess up. */

/**
 * Query the current message notify callback for the isolate.
 *
 * \return The current message notify callback for the isolate.
 */
DART_EXPORT Dart_MessageNotifyCallback Dart_GetMessageNotifyCallback(void);

/**
 * The VM's default message handler supports pausing an isolate before it
 * processes the first message and right after the it processes the isolate's
 * final message. This can be controlled for all isolates by two VM flags:
 *
 *   `--pause-isolates-on-start`
 *   `--pause-isolates-on-exit`
 *
 * Additionally, Dart_SetShouldPauseOnStart and Dart_SetShouldPauseOnExit can be
 * used to control this behaviour on a per-isolate basis.
 *
 * When an embedder is using a Dart_MessageNotifyCallback the embedder
 * needs to cooperate with the VM so that the service protocol can report
 * accurate information about isolates and so that tools such as debuggers
 * work reliably.
 *
 * The following functions can be used to implement pausing on start and exit.
 */

/**
 * If the VM flag `--pause-isolates-on-start` was passed this will be true.
 *
 * \return A boolean value indicating if pause on start was requested.
 */
DART_EXPORT bool Dart_ShouldPauseOnStart(void);

/**
 * Override the VM flag `--pause-isolates-on-start` for the current isolate.
 *
 * \param should_pause Should the isolate be paused on start?
 *
 * NOTE: This must be called before Dart_IsolateMakeRunnable.
 */
DART_EXPORT void Dart_SetShouldPauseOnStart(bool should_pause);

/**
 * Is the current isolate paused on start?
 *
 * \return A boolean value indicating if the isolate is paused on start.
 */
DART_EXPORT bool Dart_IsPausedOnStart(void);

/**
 * Called when the embedder has paused the current isolate on start and when
 * the embedder has resumed the isolate.
 *
 * \param paused Is the isolate paused on start?
 */
DART_EXPORT void Dart_SetPausedOnStart(bool paused);

/**
 * If the VM flag `--pause-isolates-on-exit` was passed this will be true.
 *
 * \return A boolean value indicating if pause on exit was requested.
 */
DART_EXPORT bool Dart_ShouldPauseOnExit(void);

/**
 * Override the VM flag `--pause-isolates-on-exit` for the current isolate.
 *
 * \param should_pause Should the isolate be paused on exit?
 *
 */
DART_EXPORT void Dart_SetShouldPauseOnExit(bool should_pause);

/**
 * Is the current isolate paused on exit?
 *
 * \return A boolean value indicating if the isolate is paused on exit.
 */
DART_EXPORT bool Dart_IsPausedOnExit(void);

/**
 * Called when the embedder has paused the current isolate on exit and when
 * the embedder has resumed the isolate.
 *
 * \param paused Is the isolate paused on exit?
 */
DART_EXPORT void Dart_SetPausedOnExit(bool paused);

/**
 * Called when the embedder has caught a top level unhandled exception error
 * in the current isolate.
 *
 * NOTE: It is illegal to call this twice on the same isolate without first
 * clearing the sticky error to null.
 *
 * \param error The unhandled exception error.
 */
DART_EXPORT void Dart_SetStickyError(Dart_Handle error);

/**
 * Does the current isolate have a sticky error?
 */
DART_EXPORT bool Dart_HasStickyError(void);

/**
 * Gets the sticky error for the current isolate.
 *
 * \return A handle to the sticky error object or null.
 */
DART_EXPORT Dart_Handle Dart_GetStickyError(void);

/**
 * Handles the next pending message for the current isolate.
 *
 * May generate an unhandled exception error.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle Dart_HandleMessage(void);

/**
 * Handles any pending messages for the vm service for the current
 * isolate.
 *
 * This function may be used by an embedder at a breakpoint to avoid
 * pausing the vm service.
 *
 * This function can indirectly cause the message notify callback to
 * be called.
 *
 * \return true if the vm service requests the program resume
 * execution, false otherwise
 */
DART_EXPORT bool Dart_HandleServiceMessages(void);

/**
 * Does the current isolate have pending service messages?
 *
 * \return true if the isolate has pending service messages, false otherwise.
 */
DART_EXPORT bool Dart_HasServiceMessages(void);

/**
 * Processes any incoming messages for the current isolate.
 *
 * This function may only be used when the embedder has not provided
 * an alternate message delivery mechanism with
 * Dart_SetMessageCallbacks. It is provided for convenience.
 *
 * This function waits for incoming messages for the current
 * isolate. As new messages arrive, they are handled using
 * Dart_HandleMessage. The routine exits when all ports to the
 * current isolate are closed.
 *
 * \return A valid handle if the run loop exited successfully.  If an
 *   exception or other error occurs while processing messages, an
 *   error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle Dart_RunLoop(void);

/**
 * Lets the VM run message processing for the isolate.
 *
 * This function expects there to a current isolate and the current isolate
 * must not have an active api scope. The VM will take care of making the
 * isolate runnable (if not already), handles its message loop and will take
 * care of shutting the isolate down once it's done.
 *
 * \param errors_are_fatal Whether uncaught errors should be fatal.
 * \param on_error_port A port to notify on uncaught errors (or ILLEGAL_PORT).
 * \param on_exit_port A port to notify on exit (or ILLEGAL_PORT).
 * \param error A non-NULL pointer which will hold an error message if the call
 *   fails. The error has to be free()ed by the caller.
 *
 * \return If successful the VM takes ownership of the isolate and takes care
 *   of its message loop. If not successful the caller retains ownership of the
 *   isolate.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT bool Dart_RunLoopAsync(
    bool errors_are_fatal,
    Dart_Port on_error_port,
    Dart_Port on_exit_port,
    char** error);

/* TODO(turnidge): Should this be removed from the public api? */

/**
 * Gets the main port id for the current isolate.
 */
DART_EXPORT Dart_Port Dart_GetMainPortId(void);

/**
 * Does the current isolate have live ReceivePorts?
 *
 * A ReceivePort is live when it has not been closed.
 */
DART_EXPORT bool Dart_HasLivePorts(void);

/**
 * Posts a message for some isolate. The message is a serialized
 * object.
 *
 * Requires there to be a current isolate.
 *
 * For posting messages outside of an isolate see \ref Dart_PostCObject.
 *
 * \param port_id The destination port.
 * \param object An object from the current isolate.
 *
 * \return True if the message was posted.
 */
DART_EXPORT bool Dart_Post(Dart_Port port_id, Dart_Handle object);

/**
 * Returns a new SendPort with the provided port id.
 *
 * If there is a possibility of a port closing since port_id was acquired
 * for a SendPort, one should use Dart_NewSendPortEx and
 * Dart_SendPortGetIdEx.
 *
 * \param port_id The destination port.
 *
 * \return A new SendPort if no errors occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewSendPort(Dart_Port port_id);

/**
 * Returns a new SendPort with the provided port id and origin id.
 *
 * \param portex_id The destination composte port id.
 *
 * \return A new SendPort if no errors occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewSendPortEx(Dart_PortEx portex_id);

/**
 * Gets the SendPort id for the provided SendPort.
 * \param port A SendPort object whose id is desired.
 * \param port_id Returns the id of the SendPort.
 * \return Success if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_SendPortGetId(Dart_Handle port,
                                           Dart_Port* port_id);

/**
 * Gets the SendPort and Origin ids for the provided SendPort.
 * \param port A SendPort object whose id is desired.
 * \param portex_id Returns composite id of the SendPort.
 * \return Success if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_SendPortGetIdEx(Dart_Handle port,
                                             Dart_PortEx* portex_id);
/*
 * ======
 * Scopes
 * ======
 */

/**
 * Enters a new scope.
 *
 * All new local handles will be created in this scope. Additionally,
 * some functions may return "scope allocated" memory which is only
 * valid within this scope.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_EnterScope(void);

/**
 * Exits a scope.
 *
 * The previous scope (if any) becomes the current scope.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT void Dart_ExitScope(void);

/**
 * The Dart VM uses "zone allocation" for temporary structures. Zones
 * support very fast allocation of small chunks of memory. The chunks
 * cannot be deallocated individually, but instead zones support
 * deallocating all chunks in one fast operation.
 *
 * This function makes it possible for the embedder to allocate
 * temporary data in the VMs zone allocator.
 *
 * Zone allocation is possible:
 *   1. when inside a scope where local handles can be allocated
 *   2. when processing a message from a native port in a native port
 *      handler
 *
 * All the memory allocated this way will be reclaimed either on the
 * next call to Dart_ExitScope or when the native port handler exits.
 *
 * \param size Size of the memory to allocate.
 *
 * \return A pointer to the allocated memory. NULL if allocation
 *   failed. Failure might due to is no current VM zone.
 */
DART_EXPORT uint8_t* Dart_ScopeAllocate(intptr_t size);

/*
 * =======
 * Objects
 * =======
 */

/**
 * Returns the null object.
 *
 * \return A handle to the null object.
 */
DART_EXPORT Dart_Handle Dart_Null(void);

/**
 * Is this object null?
 */
DART_EXPORT bool Dart_IsNull(Dart_Handle object);

/**
 * Returns the empty string object.
 *
 * \return A handle to the empty string object.
 */
DART_EXPORT Dart_Handle Dart_EmptyString(void);

/**
 * Returns types that are not classes, and which therefore cannot be looked up
 * as library members by Dart_GetType.
 *
 * \return A handle to the dynamic, void or Never type.
 */
DART_EXPORT Dart_Handle Dart_TypeDynamic(void);
DART_EXPORT Dart_Handle Dart_TypeVoid(void);
DART_EXPORT Dart_Handle Dart_TypeNever(void);

/**
 * Checks if the two objects are equal.
 *
 * The result of the comparison is returned through the 'equal'
 * parameter. The return value itself is used to indicate success or
 * failure, not equality.
 *
 * May generate an unhandled exception error.
 *
 * \param obj1 An object to be compared.
 * \param obj2 An object to be compared.
 * \param equal Returns the result of the equality comparison.
 *
 * \return A valid handle if no error occurs during the comparison.
 */
DART_EXPORT Dart_Handle Dart_ObjectEquals(Dart_Handle obj1,
                                          Dart_Handle obj2,
                                          bool* equal);

/**
 * Is this object an instance of some type?
 *
 * The result of the test is returned through the 'instanceof' parameter.
 * The return value itself is used to indicate success or failure.
 *
 * \param object An object.
 * \param type A type.
 * \param instanceof Return true if 'object' is an instance of type 'type'.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ObjectIsType(Dart_Handle object,
                                          Dart_Handle type,
                                          bool* instanceof);

/**
 * Query object type.
 *
 * \param object Some Object.
 *
 * \return true if Object is of the specified type.
 */
DART_EXPORT bool Dart_IsInstance(Dart_Handle object);
DART_EXPORT bool Dart_IsNumber(Dart_Handle object);
DART_EXPORT bool Dart_IsInteger(Dart_Handle object);
DART_EXPORT bool Dart_IsDouble(Dart_Handle object);
DART_EXPORT bool Dart_IsBoolean(Dart_Handle object);
DART_EXPORT bool Dart_IsString(Dart_Handle object);
DART_EXPORT bool Dart_IsStringLatin1(Dart_Handle object); /* (ISO-8859-1) */
DART_EXPORT bool Dart_IsList(Dart_Handle object);
DART_EXPORT bool Dart_IsMap(Dart_Handle object);
DART_EXPORT bool Dart_IsLibrary(Dart_Handle object);
DART_EXPORT bool Dart_IsType(Dart_Handle handle);
DART_EXPORT bool Dart_IsFunction(Dart_Handle handle);
DART_EXPORT bool Dart_IsVariable(Dart_Handle handle);
DART_EXPORT bool Dart_IsTypeVariable(Dart_Handle handle);
DART_EXPORT bool Dart_IsClosure(Dart_Handle object);
DART_EXPORT bool Dart_IsTypedData(Dart_Handle object);
DART_EXPORT bool Dart_IsByteBuffer(Dart_Handle object);
DART_EXPORT bool Dart_IsFuture(Dart_Handle object);

/*
 * =========
 * Instances
 * =========
 */

/*
 * For the purposes of the embedding api, not all objects returned are
 * Dart language objects.  Within the api, we use the term 'Instance'
 * to indicate handles which refer to true Dart language objects.
 *
 * TODO(turnidge): Reorganize the "Object" section above, pulling down
 * any functions that more properly belong here. */

/**
 * Gets the type of a Dart language object.
 *
 * \param instance Some Dart object.
 *
 * \return If no error occurs, the type is returned. Otherwise an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_InstanceGetType(Dart_Handle instance);

/**
 * Returns the name for the provided class type.
 *
 * \return A valid string handle if no error occurs during the
 *   operation.
 */
DART_EXPORT Dart_Handle Dart_ClassName(Dart_Handle cls_type);

/**
 * Returns the name for the provided function or method.
 *
 * \return A valid string handle if no error occurs during the
 *   operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionName(Dart_Handle function);

/**
 * Returns a handle to the owner of a function.
 *
 * The owner of an instance method or a static method is its defining
 * class. The owner of a top-level function is its defining
 * library. The owner of the function of a non-implicit closure is the
 * function of the method or closure that defines the non-implicit
 * closure.
 *
 * \return A valid handle to the owner of the function, or an error
 *   handle if the argument is not a valid handle to a function.
 */
DART_EXPORT Dart_Handle Dart_FunctionOwner(Dart_Handle function);

/**
 * Determines whether a function handle refers to a static function
 * of method.
 *
 * For the purposes of the embedding API, a top-level function is
 * implicitly declared static.
 *
 * \param function A handle to a function or method declaration.
 * \param is_static Returns whether the function or method is declared static.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_FunctionIsStatic(Dart_Handle function,
                                              bool* is_static);

/**
 * Is this object a closure resulting from a tear-off (closurized method)?
 *
 * Returns true for closures produced when an ordinary method is accessed
 * through a getter call. Returns false otherwise, in particular for closures
 * produced from local function declarations.
 *
 * \param object Some Object.
 *
 * \return true if Object is a tear-off.
 */
DART_EXPORT bool Dart_IsTearOff(Dart_Handle object);

/**
 * Retrieves the function of a closure.
 *
 * \return A handle to the function of the closure, or an error handle if the
 *   argument is not a closure.
 */
DART_EXPORT Dart_Handle Dart_ClosureFunction(Dart_Handle closure);

/**
 * Returns a handle to the library which contains class.
 *
 * \return A valid handle to the library with owns class, null if the class
 *   has no library or an error handle if the argument is not a valid handle
 *   to a class type.
 */
DART_EXPORT Dart_Handle Dart_ClassLibrary(Dart_Handle cls_type);

/*
 * =============================
 * Numbers, Integers and Doubles
 * =============================
 */

/**
 * Does this Integer fit into a 64-bit signed integer?
 *
 * \param integer An integer.
 * \param fits Returns true if the integer fits into a 64-bit signed integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerFitsIntoInt64(Dart_Handle integer,
                                                  bool* fits);

/**
 * Does this Integer fit into a 64-bit unsigned integer?
 *
 * \param integer An integer.
 * \param fits Returns true if the integer fits into a 64-bit unsigned integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerFitsIntoUint64(Dart_Handle integer,
                                                   bool* fits);

/**
 * Returns an Integer with the provided value.
 *
 * \param value The value of the integer.
 *
 * \return The Integer object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewInteger(int64_t value);

/**
 * Returns an Integer with the provided value.
 *
 * \param value The unsigned value of the integer.
 *
 * \return The Integer object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewIntegerFromUint64(uint64_t value);

/**
 * Returns an Integer with the provided value.
 *
 * \param value The value of the integer represented as a C string
 *   containing a hexadecimal number.
 *
 * \return The Integer object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewIntegerFromHexCString(const char* value);

/**
 * Gets the value of an Integer.
 *
 * The integer must fit into a 64-bit signed integer, otherwise an error occurs.
 *
 * \param integer An Integer.
 * \param value Returns the value of the Integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerToInt64(Dart_Handle integer,
                                            int64_t* value);

/**
 * Gets the value of an Integer.
 *
 * The integer must fit into a 64-bit unsigned integer, otherwise an
 * error occurs.
 *
 * \param integer An Integer.
 * \param value Returns the value of the Integer.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerToUint64(Dart_Handle integer,
                                             uint64_t* value);

/**
 * Gets the value of an integer as a hexadecimal C string.
 *
 * \param integer An Integer.
 * \param value Returns the value of the Integer as a hexadecimal C
 *   string. This C string is scope allocated and is only valid until
 *   the next call to Dart_ExitScope.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_IntegerToHexCString(Dart_Handle integer,
                                                 const char** value);

/**
 * Returns a Double with the provided value.
 *
 * \param value A double.
 *
 * \return The Double object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewDouble(double value);

/**
 * Gets the value of a Double
 *
 * \param double_obj A Double
 * \param value Returns the value of the Double.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_DoubleValue(Dart_Handle double_obj, double* value);

/**
 * Returns a closure of static function 'function_name' in the class 'class_name'
 * in the exported namespace of specified 'library'.
 *
 * \param library Library object
 * \param cls_type Type object representing a Class
 * \param function_name Name of the static function in the class
 *
 * \return A valid Dart instance if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_GetStaticMethodClosure(Dart_Handle library,
                                                    Dart_Handle cls_type,
                                                    Dart_Handle function_name);

/*
 * ========
 * Booleans
 * ========
 */

/**
 * Returns the True object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the True object.
 */
DART_EXPORT Dart_Handle Dart_True(void);

/**
 * Returns the False object.
 *
 * Requires there to be a current isolate.
 *
 * \return A handle to the False object.
 */
DART_EXPORT Dart_Handle Dart_False(void);

/**
 * Returns a Boolean with the provided value.
 *
 * \param value true or false.
 *
 * \return The Boolean object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewBoolean(bool value);

/**
 * Gets the value of a Boolean
 *
 * \param boolean_obj A Boolean
 * \param value Returns the value of the Boolean.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_BooleanValue(Dart_Handle boolean_obj, bool* value);

/*
 * =======
 * Strings
 * =======
 */

/**
 * Gets the length of a String.
 *
 * \param str A String.
 * \param length Returns the length of the String.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringLength(Dart_Handle str, intptr_t* length);

/**
 * Gets the length of UTF-8 encoded representation for a string.
 *
 * \param str A String.
 * \param length Returns the length of UTF-8 encoded representation for string.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringUTF8Length(Dart_Handle str,
                                              intptr_t* length);

/**
 * Returns a String built from the provided C string
 * (There is an implicit assumption that the C string passed in contains
 *  UTF-8 encoded characters and '\0' is considered as a termination
 *  character).
 *
 * \param str A C String
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromCString(const char* str);
/* TODO(turnidge): Document what happens when we run out of memory
 * during this call. */

/**
 * Returns a String built from an array of UTF-8 encoded characters.
 *
 * \param utf8_array An array of UTF-8 encoded characters.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromUTF8(const uint8_t* utf8_array,
                                               intptr_t length);

/**
 * Returns a String built from an array of UTF-16 encoded characters.
 *
 * \param utf16_array An array of UTF-16 encoded characters.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromUTF16(const uint16_t* utf16_array,
                                                intptr_t length);

/**
 * Returns a String built from an array of UTF-32 encoded characters.
 *
 * \param utf32_array An array of UTF-32 encoded characters.
 * \param length The length of the codepoints array.
 *
 * \return The String object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewStringFromUTF32(const int32_t* utf32_array,
                                                intptr_t length);

/**
 * Gets the C string representation of a String.
 * (It is a sequence of UTF-8 encoded values with a '\0' termination.)
 *
 * \param str A string.
 * \param cstr Returns the String represented as a C string.
 *   This C string is scope allocated and is only valid until
 *   the next call to Dart_ExitScope.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToCString(Dart_Handle str,
                                             const char** cstr);

/**
 * Gets a UTF-8 encoded representation of a String.
 *
 * Any unpaired surrogate code points in the string will be converted as
 * replacement characters (U+FFFD, 0xEF 0xBF 0xBD in UTF-8). If you need
 * to preserve unpaired surrogates, use the Dart_StringToUTF16 function.
 *
 * \param str A string.
 * \param utf8_array Returns the String represented as UTF-8 code
 *   units.  This UTF-8 array is scope allocated and is only valid
 *   until the next call to Dart_ExitScope.
 * \param length Used to return the length of the array which was
 *   actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToUTF8(Dart_Handle str,
                                          uint8_t** utf8_array,
                                          intptr_t* length);

/**
 * Copies the UTF-8 encoded representation of a String into specified buffer.
 *
 * Any unpaired surrogate code points in the string will be converted as
 * replacement characters (U+FFFD, 0xEF 0xBF 0xBD in UTF-8).
 *
 * \param str A string.
 * \param utf8_array Buffer into which the UTF-8 encoded representation of
 *   the string is copied into.
 *   The buffer is allocated and managed by the caller.
 * \param length Specifies the length of the buffer passed in.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_CopyUTF8EncodingOfString(Dart_Handle str,
                                                      uint8_t* utf8_array,
                                                      intptr_t length);

/**
 * Gets the data corresponding to the string object. This function returns
 * the data only for Latin-1 (ISO-8859-1) string objects. For all other
 * string objects it returns an error.
 *
 * \param str A string.
 * \param latin1_array An array allocated by the caller, used to return
 *   the string data.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToLatin1(Dart_Handle str,
                                            uint8_t* latin1_array,
                                            intptr_t* length);

/**
 * Gets the UTF-16 encoded representation of a string.
 *
 * \param str A string.
 * \param utf16_array An array allocated by the caller, used to return
 *   the array of UTF-16 encoded characters.
 * \param length Used to pass in the length of the provided array.
 *   Used to return the length of the array which was actually used.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringToUTF16(Dart_Handle str,
                                           uint16_t* utf16_array,
                                           intptr_t* length);

/**
 * Gets the storage size in bytes of a String.
 *
 * \param str A String.
 * \param size Returns the storage size in bytes of the String.
 *  This is the size in bytes needed to store the String.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_StringStorageSize(Dart_Handle str, intptr_t* size);

/**
 * Retrieves some properties associated with a String.
 * Properties retrieved are:
 * - character size of the string (one or two byte)
 * - length of the string
 * - peer pointer of string if it is an external string.
 * \param str A String.
 * \param char_size Returns the character size of the String.
 * \param str_len Returns the length of the String.
 * \param peer Returns the peer pointer associated with the String or 0 if
 *   there is no peer pointer for it.
 * \return Success if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_StringGetProperties(Dart_Handle str,
                                                 intptr_t* char_size,
                                                 intptr_t* str_len,
                                                 void** peer);

/*
 * =====
 * Lists
 * =====
 */

/**
 * Returns a List<dynamic> of the desired length.
 *
 * \param length The length of the list.
 *
 * \return The List object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewList(intptr_t length);

/**
 * Returns a List of the desired length with the desired element type.
 *
 * \param element_type Handle to a nullable type object. E.g., from
 * Dart_GetType or Dart_GetNullableType.
 *
 * \param length The length of the list.
 *
 * \return The List object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewListOfType(Dart_Handle element_type,
                                           intptr_t length);

/**
 * Returns a List of the desired length with the desired element type, filled
 * with the provided object.
 *
 * \param element_type Handle to a type object. E.g., from Dart_GetType.
 *
 * \param fill_object Handle to an object of type 'element_type' that will be
 * used to populate the list. This parameter can only be Dart_Null() if the
 * length of the list is 0 or 'element_type' is a nullable type.
 *
 * \param length The length of the list.
 *
 * \return The List object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewListOfTypeFilled(Dart_Handle element_type,
                                                 Dart_Handle fill_object,
                                                 intptr_t length);

/**
 * Gets the length of a List.
 *
 * May generate an unhandled exception error.
 *
 * \param list A List.
 * \param length Returns the length of the List.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ListLength(Dart_Handle list, intptr_t* length);

/**
 * Gets the Object at some index of a List.
 *
 * If the index is out of bounds, an error occurs.
 *
 * May generate an unhandled exception error.
 *
 * \param list A List.
 * \param index A valid index into the List.
 *
 * \return The Object in the List at the specified index if no error
 *   occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_ListGetAt(Dart_Handle list, intptr_t index);

/**
* Gets a range of Objects from a List.
*
* If any of the requested index values are out of bounds, an error occurs.
*
* May generate an unhandled exception error.
*
* \param list A List.
* \param offset The offset of the first item to get.
* \param length The number of items to get.
* \param result A pointer to fill with the objects.
*
* \return Success if no error occurs during the operation.
*/
DART_EXPORT Dart_Handle Dart_ListGetRange(Dart_Handle list,
                                          intptr_t offset,
                                          intptr_t length,
                                          Dart_Handle* result);

/**
 * Sets the Object at some index of a List.
 *
 * If the index is out of bounds, an error occurs.
 *
 * May generate an unhandled exception error.
 *
 * \param list A List.
 * \param index A valid index into the List.
 * \param value The Object to put in the List.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT Dart_Handle Dart_ListSetAt(Dart_Handle list,
                                       intptr_t index,
                                       Dart_Handle value);

/**
 * May generate an unhandled exception error.
 */
DART_EXPORT Dart_Handle Dart_ListGetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            uint8_t* native_array,
                                            intptr_t length);

/**
 * May generate an unhandled exception error.
 */
DART_EXPORT Dart_Handle Dart_ListSetAsBytes(Dart_Handle list,
                                            intptr_t offset,
                                            const uint8_t* native_array,
                                            intptr_t length);

/*
 * ====
 * Maps
 * ====
 */

/**
 * Gets the Object at some key of a Map.
 *
 * May generate an unhandled exception error.
 *
 * \param map A Map.
 * \param key An Object.
 *
 * \return The value in the map at the specified key, null if the map does not
 *   contain the key, or an error handle.
 */
DART_EXPORT Dart_Handle Dart_MapGetAt(Dart_Handle map, Dart_Handle key);

/**
 * Returns whether the Map contains a given key.
 *
 * May generate an unhandled exception error.
 *
 * \param map A Map.
 *
 * \return A handle on a boolean indicating whether map contains the key.
 *   Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_MapContainsKey(Dart_Handle map, Dart_Handle key);

/**
 * Gets the list of keys of a Map.
 *
 * May generate an unhandled exception error.
 *
 * \param map A Map.
 *
 * \return The list of key Objects if no error occurs. Otherwise returns an
 *   error handle.
 */
DART_EXPORT Dart_Handle Dart_MapKeys(Dart_Handle map);

/*
 * ==========
 * Typed Data
 * ==========
 */

typedef enum {
  Dart_TypedData_kByteData = 0,
  Dart_TypedData_kInt8,
  Dart_TypedData_kUint8,
  Dart_TypedData_kUint8Clamped,
  Dart_TypedData_kInt16,
  Dart_TypedData_kUint16,
  Dart_TypedData_kInt32,
  Dart_TypedData_kUint32,
  Dart_TypedData_kInt64,
  Dart_TypedData_kUint64,
  Dart_TypedData_kFloat32,
  Dart_TypedData_kFloat64,
  Dart_TypedData_kInt32x4,
  Dart_TypedData_kFloat32x4,
  Dart_TypedData_kFloat64x2,
  Dart_TypedData_kInvalid
} Dart_TypedData_Type;

/**
 * Return type if this object is a TypedData object.
 *
 * \return kInvalid if the object is not a TypedData object or the appropriate
 *   Dart_TypedData_Type.
 */
DART_EXPORT Dart_TypedData_Type Dart_GetTypeOfTypedData(Dart_Handle object);

/**
 * Return type if this object is an external TypedData object.
 *
 * \return kInvalid if the object is not an external TypedData object or
 *   the appropriate Dart_TypedData_Type.
 */
DART_EXPORT Dart_TypedData_Type
Dart_GetTypeOfExternalTypedData(Dart_Handle object);

/**
 * Returns a TypedData object of the desired length and type.
 *
 * \param type The type of the TypedData object.
 * \param length The length of the TypedData object (length in type units).
 *
 * \return The TypedData object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewTypedData(Dart_TypedData_Type type,
                                          intptr_t length);

/**
 * Returns a TypedData object which references an external data array.
 *
 * \param type The type of the data array.
 * \param data A data array. This array must not move.
 * \param length The length of the data array (length in type units).
 *
 * \return The TypedData object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewExternalTypedData(Dart_TypedData_Type type,
                                                  void* data,
                                                  intptr_t length);

/**
 * Returns a TypedData object which references an external data array.
 *
 * \param type The type of the data array.
 * \param data A data array. This array must not move.
 * \param length The length of the data array (length in type units).
 * \param peer A pointer to a native object or NULL.  This value is
 *   provided to callback when it is invoked.
 * \param external_allocation_size The number of externally allocated
 *   bytes for peer. Used to inform the garbage collector.
 * \param callback A function pointer that will be invoked sometime
 *   after the object is garbage collected, unless the handle has been deleted.
 *   A valid callback needs to be specified it cannot be NULL.
 *
 * \return The TypedData object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle
Dart_NewExternalTypedDataWithFinalizer(Dart_TypedData_Type type,
                                       void* data,
                                       intptr_t length,
                                       void* peer,
                                       intptr_t external_allocation_size,
                                       Dart_HandleFinalizer callback);
DART_EXPORT Dart_Handle Dart_NewUnmodifiableExternalTypedDataWithFinalizer(
    Dart_TypedData_Type type,
    const void* data,
    intptr_t length,
    void* peer,
    intptr_t external_allocation_size,
    Dart_HandleFinalizer callback);

/**
 * Returns a ByteBuffer object for the typed data.
 *
 * \param typed_data The TypedData object.
 *
 * \return The ByteBuffer object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_NewByteBuffer(Dart_Handle typed_data);

/**
 * Acquires access to the internal data address of a TypedData object.
 *
 * \param object The typed data object whose internal data address is to
 *    be accessed.
 * \param type The type of the object is returned here.
 * \param data The internal data address is returned here.
 * \param len Size of the typed array is returned here.
 *
 * Notes:
 *   When the internal address of the object is acquired any calls to a
 *   Dart API function that could potentially allocate an object or run
 *   any Dart code will return an error.
 *
 *   Any Dart API functions for accessing the data should not be called
 *   before the corresponding release. In particular, the object should
 *   not be acquired again before its release. This leads to undefined
 *   behavior.
 *
 * \return Success if the internal data address is acquired successfully.
 *   Otherwise, returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_TypedDataAcquireData(Dart_Handle object,
                                                  Dart_TypedData_Type* type,
                                                  void** data,
                                                  intptr_t* len);

/**
 * Releases access to the internal data address that was acquired earlier using
 * Dart_TypedDataAcquireData.
 *
 * \param object The typed data object whose internal data address is to be
 *   released.
 *
 * \return Success if the internal data address is released successfully.
 *   Otherwise, returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_TypedDataReleaseData(Dart_Handle object);

/**
 * Returns the TypedData object associated with the ByteBuffer object.
 *
 * \param byte_buffer The ByteBuffer object.
 *
 * \return The TypedData object if no error occurs. Otherwise returns
 *   an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetDataFromByteBuffer(Dart_Handle byte_buffer);

/*
 * ============================================================
 * Invoking Constructors, Methods, Closures and Field accessors
 * ============================================================
 */

/**
 * Invokes a constructor, creating a new object.
 *
 * This function allows hidden constructors (constructors with leading
 * underscores) to be called.
 *
 * \param type Type of object to be constructed.
 * \param constructor_name The name of the constructor to invoke.  Use
 *   Dart_Null() or Dart_EmptyString() to invoke the unnamed constructor.
 *   This name should not include the name of the class.
 * \param number_of_arguments Size of the arguments array.
 * \param arguments An array of arguments to the constructor.
 *
 * \return If the constructor is called and completes successfully,
 *   then the new object. If an error occurs during execution, then an
 *   error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_New(Dart_Handle type,
         Dart_Handle constructor_name,
         int number_of_arguments,
         Dart_Handle* arguments);

/**
 * Allocate a new object without invoking a constructor.
 *
 * \param type The type of an object to be allocated.
 *
 * \return The new object. If an error occurs during execution, then an
 *   error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle Dart_Allocate(Dart_Handle type);

/**
 * Allocate a new object without invoking a constructor, and sets specified
 *  native fields.
 *
 * \param type The type of an object to be allocated.
 * \param num_native_fields The number of native fields to set.
 * \param native_fields An array containing the value of native fields.
 *
 * \return The new object. If an error occurs during execution, then an
 *   error handle is returned.
 */
DART_EXPORT Dart_Handle
Dart_AllocateWithNativeFields(Dart_Handle type,
                              intptr_t num_native_fields,
                              const intptr_t* native_fields);

/**
 * Invokes a method or function.
 *
 * The 'target' parameter may be an object, type, or library.  If
 * 'target' is an object, then this function will invoke an instance
 * method.  If 'target' is a type, then this function will invoke a
 * static method.  If 'target' is a library, then this function will
 * invoke a top-level function from that library.
 * NOTE: This API call cannot be used to invoke methods of a type object.
 *
 * This function ignores visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param target An object, type, or library.
 * \param name The name of the function or method to invoke.
 * \param number_of_arguments Size of the arguments array.
 * \param arguments An array of arguments to the function.
 *
 * \return If the function or method is called and completes
 *   successfully, then the return value is returned. If an error
 *   occurs during execution, then an error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_Invoke(Dart_Handle target,
            Dart_Handle name,
            int number_of_arguments,
            Dart_Handle* arguments);
/* TODO(turnidge): Document how to invoke operators. */

/**
 * Invokes a Closure with the given arguments.
 *
 * May generate an unhandled exception error.
 *
 * \return If no error occurs during execution, then the result of
 *   invoking the closure is returned. If an error occurs during
 *   execution, then an error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_InvokeClosure(Dart_Handle closure,
                   int number_of_arguments,
                   Dart_Handle* arguments);

/**
 * Invokes a Generative Constructor on an object that was previously
 * allocated using Dart_Allocate/Dart_AllocateWithNativeFields.
 *
 * The 'object' parameter must be an object.
 *
 * This function ignores visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param object An object.
 * \param name The name of the constructor to invoke.
 *   Use Dart_Null() or Dart_EmptyString() to invoke the unnamed constructor.
 * \param number_of_arguments Size of the arguments array.
 * \param arguments An array of arguments to the function.
 *
 * \return If the constructor is called and completes
 *   successfully, then the object is returned. If an error
 *   occurs during execution, then an error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_InvokeConstructor(Dart_Handle object,
                       Dart_Handle name,
                       int number_of_arguments,
                       Dart_Handle* arguments);

/**
 * Gets the value of a field.
 *
 * The 'container' parameter may be an object, type, or library.  If
 * 'container' is an object, then this function will access an
 * instance field.  If 'container' is a type, then this function will
 * access a static field.  If 'container' is a library, then this
 * function will access a top-level variable.
 * NOTE: This API call cannot be used to access fields of a type object.
 *
 * This function ignores field visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param container An object, type, or library.
 * \param name A field name.
 *
 * \return If no error occurs, then the value of the field is
 *   returned. Otherwise an error handle is returned.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_GetField(Dart_Handle container, Dart_Handle name);

/**
 * Sets the value of a field.
 *
 * The 'container' parameter may actually be an object, type, or
 * library.  If 'container' is an object, then this function will
 * access an instance field.  If 'container' is a type, then this
 * function will access a static field.  If 'container' is a library,
 * then this function will access a top-level variable.
 * NOTE: This API call cannot be used to access fields of a type object.
 *
 * This function ignores field visibility (leading underscores in names).
 *
 * May generate an unhandled exception error.
 *
 * \param container An object, type, or library.
 * \param name A field name.
 * \param value The new field value.
 *
 * \return A valid handle if no error occurs.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_SetField(Dart_Handle container, Dart_Handle name, Dart_Handle value);

/*
 * ==========
 * Exceptions
 * ==========
 */

/*
 * TODO(turnidge): Remove these functions from the api and replace all
 * uses with Dart_NewUnhandledExceptionError. */

/**
 * Throws an exception.
 *
 * This function causes a Dart language exception to be thrown. This
 * will proceed in the standard way, walking up Dart frames until an
 * appropriate 'catch' block is found, executing 'finally' blocks,
 * etc.
 *
 * If an error handle is passed into this function, the error is
 * propagated immediately.  See Dart_PropagateError for a discussion
 * of error propagation.
 *
 * If successful, this function does not return. Note that this means
 * that the destructors of any stack-allocated C++ objects will not be
 * called. If there are no Dart frames on the stack, an error occurs.
 *
 * \return An error handle if the exception was not thrown.
 *   Otherwise the function does not return.
 */
DART_EXPORT Dart_Handle Dart_ThrowException(Dart_Handle exception);

/**
 * Rethrows an exception.
 *
 * Rethrows an exception, unwinding all dart frames on the stack. If
 * successful, this function does not return. Note that this means
 * that the destructors of any stack-allocated C++ objects will not be
 * called. If there are no Dart frames on the stack, an error occurs.
 *
 * \return An error handle if the exception was not thrown.
 *   Otherwise the function does not return.
 */
DART_EXPORT Dart_Handle Dart_ReThrowException(Dart_Handle exception,
                                              Dart_Handle stacktrace);

/*
 * ===========================
 * Native fields and functions
 * ===========================
 */

/**
 * Gets the number of native instance fields in an object.
 */
DART_EXPORT Dart_Handle Dart_GetNativeInstanceFieldCount(Dart_Handle obj,
                                                         int* count);

/**
 * Gets the value of a native field.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_GetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t* value);

/**
 * Sets the value of a native field.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle Dart_SetNativeInstanceField(Dart_Handle obj,
                                                    int index,
                                                    intptr_t value);

/**
 * The arguments to a native function.
 *
 * This object is passed to a native function to represent its
 * arguments and return value. It allows access to the arguments to a
 * native function by index. It also allows the return value of a
 * native function to be set.
 */
typedef struct _Dart_NativeArguments* Dart_NativeArguments;

/**
 * Extracts current isolate group data from the native arguments structure.
 */
DART_EXPORT void* Dart_GetNativeIsolateGroupData(Dart_NativeArguments args);

typedef enum {
  Dart_NativeArgument_kBool = 0,
  Dart_NativeArgument_kInt32,
  Dart_NativeArgument_kUint32,
  Dart_NativeArgument_kInt64,
  Dart_NativeArgument_kUint64,
  Dart_NativeArgument_kDouble,
  Dart_NativeArgument_kString,
  Dart_NativeArgument_kInstance,
  Dart_NativeArgument_kNativeFields,
} Dart_NativeArgument_Type;

typedef struct _Dart_NativeArgument_Descriptor {
  uint8_t type;
  uint8_t index;
} Dart_NativeArgument_Descriptor;

typedef union _Dart_NativeArgument_Value {
  bool as_bool;
  int32_t as_int32;
  uint32_t as_uint32;
  int64_t as_int64;
  uint64_t as_uint64;
  double as_double;
  struct {
    Dart_Handle dart_str;
    void* peer;
  } as_string;
  struct {
    intptr_t num_fields;
    intptr_t* values;
  } as_native_fields;
  Dart_Handle as_instance;
} Dart_NativeArgument_Value;

enum {
  kNativeArgNumberPos = 0,
  kNativeArgNumberSize = 8,
  kNativeArgTypePos = kNativeArgNumberPos + kNativeArgNumberSize,
  kNativeArgTypeSize = 8,
};

#define BITMASK(size) ((1 << size) - 1)
#define DART_NATIVE_ARG_DESCRIPTOR(type, position)                             \
  (((type & BITMASK(kNativeArgTypeSize)) << kNativeArgTypePos) |               \
   (position & BITMASK(kNativeArgNumberSize)))

/**
 * Gets the native arguments based on the types passed in and populates
 * the passed arguments buffer with appropriate native values.
 *
 * \param args the Native arguments block passed into the native call.
 * \param num_arguments length of argument descriptor array and argument
 *   values array passed in.
 * \param arg_descriptors an array that describes the arguments that
 *   need to be retrieved. For each argument to be retrieved the descriptor
 *   contains the argument number (0, 1 etc.) and the argument type
 *   described using Dart_NativeArgument_Type, e.g:
 *   DART_NATIVE_ARG_DESCRIPTOR(Dart_NativeArgument_kBool, 1) indicates
 *   that the first argument is to be retrieved and it should be a boolean.
 * \param arg_values array into which the native arguments need to be
 *   extracted into, the array is allocated by the caller (it could be
 *   stack allocated to avoid the malloc/free performance overhead).
 *
 * \return Success if all the arguments could be extracted correctly,
 *   returns an error handle if there were any errors while extracting the
 *   arguments (mismatched number of arguments, incorrect types, etc.).
 */
DART_EXPORT Dart_Handle
Dart_GetNativeArguments(Dart_NativeArguments args,
                        int num_arguments,
                        const Dart_NativeArgument_Descriptor* arg_descriptors,
                        Dart_NativeArgument_Value* arg_values);

/**
 * Gets the native argument at some index.
 */
DART_EXPORT Dart_Handle Dart_GetNativeArgument(Dart_NativeArguments args,
                                               int index);
/* TODO(turnidge): Specify the behavior of an out-of-bounds access. */

/**
 * Gets the number of native arguments.
 */
DART_EXPORT int Dart_GetNativeArgumentCount(Dart_NativeArguments args);

/**
 * Gets all the native fields of the native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param num_fields size of the intptr_t array 'field_values' passed in.
 * \param field_values intptr_t array in which native field values are returned.
 * \return Success if the native fields where copied in successfully. Otherwise
 *   returns an error handle. On success the native field values are copied
 *   into the 'field_values' array, if the argument at 'arg_index' is a
 *   null object then 0 is copied as the native field values into the
 *   'field_values' array.
 */
DART_EXPORT Dart_Handle
Dart_GetNativeFieldsOfArgument(Dart_NativeArguments args,
                               int arg_index,
                               int num_fields,
                               intptr_t* field_values);

/**
 * Gets the native field of the receiver.
 */
DART_EXPORT Dart_Handle Dart_GetNativeReceiver(Dart_NativeArguments args,
                                               intptr_t* value);

/**
 * Gets a string native argument at some index.
 * \param args Native arguments structure.
 * \param arg_index Index of the desired argument in the structure above.
 * \param peer Returns the peer pointer if the string argument has one.
 * \return Success if the string argument has a peer, if it does not
 *   have a peer then the String object is returned. Otherwise returns
 *   an error handle (argument is not a String object).
 */
DART_EXPORT Dart_Handle Dart_GetNativeStringArgument(Dart_NativeArguments args,
                                                     int arg_index,
                                                     void** peer);

/**
 * Gets an integer native argument at some index.
 * \param args Native arguments structure.
 * \param index Index of the desired argument in the structure above.
 * \param value Returns the integer value if the argument is an Integer.
 * \return Success if no error occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetNativeIntegerArgument(Dart_NativeArguments args,
                                                      int index,
                                                      int64_t* value);

/**
 * Gets a boolean native argument at some index.
 * \param args Native arguments structure.
 * \param index Index of the desired argument in the structure above.
 * \param value Returns the boolean value if the argument is a Boolean.
 * \return Success if no error occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetNativeBooleanArgument(Dart_NativeArguments args,
                                                      int index,
                                                      bool* value);

/**
 * Gets a double native argument at some index.
 * \param args Native arguments structure.
 * \param index Index of the desired argument in the structure above.
 * \param value Returns the double value if the argument is a double.
 * \return Success if no error occurs. Otherwise returns an error handle.
 */
DART_EXPORT Dart_Handle Dart_GetNativeDoubleArgument(Dart_NativeArguments args,
                                                     int index,
                                                     double* value);

/**
 * Sets the return value for a native function.
 *
 * If retval is an Error handle, then error will be propagated once
 * the native functions exits. See Dart_PropagateError for a
 * discussion of how different types of errors are propagated.
 */
DART_EXPORT void Dart_SetReturnValue(Dart_NativeArguments args,
                                     Dart_Handle retval);

DART_EXPORT void Dart_SetWeakHandleReturnValue(Dart_NativeArguments args,
                                               Dart_WeakPersistentHandle rval);

DART_EXPORT void Dart_SetBooleanReturnValue(Dart_NativeArguments args,
                                            bool retval);

DART_EXPORT void Dart_SetIntegerReturnValue(Dart_NativeArguments args,
                                            int64_t retval);

DART_EXPORT void Dart_SetDoubleReturnValue(Dart_NativeArguments args,
                                           double retval);

/**
 * A native function.
 */
typedef void (*Dart_NativeFunction)(Dart_NativeArguments arguments);

/**
 * Native entry resolution callback.
 *
 * For libraries and scripts which have native functions, the embedder
 * can provide a native entry resolver. This callback is used to map a
 * name/arity to a Dart_NativeFunction. If no function is found, the
 * callback should return NULL.
 *
 * The parameters to the native resolver function are:
 * \param name a Dart string which is the name of the native function.
 * \param num_of_arguments is the number of arguments expected by the
 *   native function.
 * \param auto_setup_scope is a boolean flag that can be set by the resolver
 *   to indicate if this function needs a Dart API scope (see Dart_EnterScope/
 *   Dart_ExitScope) to be setup automatically by the VM before calling into
 *   the native function. By default most native functions would require this
 *   to be true but some light weight native functions which do not call back
 *   into the VM through the Dart API may not require a Dart scope to be
 *   setup automatically.
 *
 * \return A valid Dart_NativeFunction which resolves to a native entry point
 *   for the native function.
 *
 * See Dart_SetNativeResolver.
 */
typedef Dart_NativeFunction (*Dart_NativeEntryResolver)(Dart_Handle name,
                                                        int num_of_arguments,
                                                        bool* auto_setup_scope);
/* TODO(turnidge): Consider renaming to NativeFunctionResolver or
 * NativeResolver. */

/**
 * Native entry symbol lookup callback.
 *
 * For libraries and scripts which have native functions, the embedder
 * can provide a callback for mapping a native entry to a symbol. This callback
 * maps a native function entry PC to the native function name. If no native
 * entry symbol can be found, the callback should return NULL.
 *
 * The parameters to the native reverse resolver function are:
 * \param nf A Dart_NativeFunction.
 *
 * \return A const UTF-8 string containing the symbol name or NULL.
 *
 * See Dart_SetNativeResolver.
 */
typedef const uint8_t* (*Dart_NativeEntrySymbol)(Dart_NativeFunction nf);

/**
 * FFI Native C function pointer resolver callback.
 *
 * See Dart_SetFfiNativeResolver.
 */
typedef void* (*Dart_FfiNativeResolver)(const char* name, uintptr_t args_n);

/*
 * ===========
 * Environment
 * ===========
 */

/**
 * An environment lookup callback function.
 *
 * \param name The name of the value to lookup in the environment.
 *
 * \return A valid handle to a string if the name exists in the
 * current environment or Dart_Null() if not.
 */
typedef Dart_Handle (*Dart_EnvironmentCallback)(Dart_Handle name);

/**
 * Sets the environment callback for the current isolate. This
 * callback is used to lookup environment values by name in the
 * current environment. This enables the embedder to supply values for
 * the const constructors bool.fromEnvironment, int.fromEnvironment
 * and String.fromEnvironment.
 */
DART_EXPORT Dart_Handle
Dart_SetEnvironmentCallback(Dart_EnvironmentCallback callback);

/**
 * Sets the callback used to resolve native functions for a library.
 *
 * \param library A library.
 * \param resolver A native entry resolver.
 *
 * \return A valid handle if the native resolver was set successfully.
 */
DART_EXPORT Dart_Handle
Dart_SetNativeResolver(Dart_Handle library,
                       Dart_NativeEntryResolver resolver,
                       Dart_NativeEntrySymbol symbol);
/* TODO(turnidge): Rename to Dart_LibrarySetNativeResolver? */

/**
 * Returns the callback used to resolve native functions for a library.
 *
 * \param library A library.
 * \param resolver a pointer to a Dart_NativeEntryResolver
 *
 * \return A valid handle if the library was found.
 */
DART_EXPORT Dart_Handle
Dart_GetNativeResolver(Dart_Handle library, Dart_NativeEntryResolver* resolver);

/**
 * Returns the callback used to resolve native function symbols for a library.
 *
 * \param library A library.
 * \param resolver a pointer to a Dart_NativeEntrySymbol.
 *
 * \return A valid handle if the library was found.
 */
DART_EXPORT Dart_Handle Dart_GetNativeSymbol(Dart_Handle library,
                                             Dart_NativeEntrySymbol* resolver);

/**
 * Sets the callback used to resolve FFI native functions for a library.
 * The resolved functions are expected to be a C function pointer of the
 * correct signature (as specified in the `@Native<NFT>()` function
 * annotation in Dart code).
 *
 * NOTE: This is an experimental feature and might change in the future.
 *
 * \param library A library.
 * \param resolver A native function resolver.
 *
 * \return A valid handle if the native resolver was set successfully.
 */
DART_EXPORT Dart_Handle
Dart_SetFfiNativeResolver(Dart_Handle library, Dart_FfiNativeResolver resolver);

/**
 * Callback provided by the embedder that is used by the VM to resolve asset
 * paths.
 * If no callback is provided, using `@Native`s with `native_asset.yaml`s will
 * fail.
 *
 * The VM is responsible for looking up the asset path with the asset id in the
 * kernel mapping.
 * The embedder is responsible for providing the asset mapping during kernel
 * compilation and using the asset path to return a library handle in this
 * function.
 *
 * \param path The string in the asset path as passed in native_assets.yaml
 *             during kernel compilation.
 *
 * \param error Returns NULL if creation is successful, an error message
 *   otherwise. The caller is responsible for calling free() on the error
 *   message.
 *
 * \return The library handle. If |error| is not-null, the return value is
 *         undefined.
 */
typedef void* (*Dart_NativeAssetsDlopenCallback)(const char* path,
                                                 char** error);
typedef void* (*Dart_NativeAssetsDlopenCallbackNoPath)(char** error);

/**
 * Callback provided by the embedder that is used by the VM to lookup symbols
 * in native code assets.
 * If no callback is provided, using `@Native`s with `native_asset.yaml`s will
 * fail.
 *
 * \param handle The library handle returned from a
 *               `Dart_NativeAssetsDlopenCallback` or
 *               `Dart_NativeAssetsDlopenCallbackNoPath`.
 *
 * \param symbol The symbol to look up. Is a string.
 *
 * \param error Returns NULL if creation is successful, an error message
 *   otherwise. The caller is responsible for calling free() on the error
 *   message.
 *
 * \return The symbol address. If |error| is not-null, the return value is
 *         undefined.
 */
typedef void* (*Dart_NativeAssetsDlsymCallback)(void* handle,
                                                const char* symbol,
                                                char** error);

typedef struct {
  Dart_NativeAssetsDlopenCallback dlopen_absolute;
  Dart_NativeAssetsDlopenCallback dlopen_relative;
  Dart_NativeAssetsDlopenCallback dlopen_system;
  Dart_NativeAssetsDlopenCallbackNoPath dlopen_process;
  Dart_NativeAssetsDlopenCallbackNoPath dlopen_executable;
  Dart_NativeAssetsDlsymCallback dlsym;
} NativeAssetsApi;

/**
 * Initializes native asset resolution for the current isolate group.
 *
 * The caller is responsible for ensuring this is called right after isolate
 * group creation, and before running any dart code (or spawning isolates).
 *
 * @param native_assets_api The callbacks used by native assets resolution.
 *                          The VM does not take ownership of the parameter,
 *                          it can be freed immediately after the call.
 */
DART_EXPORT void Dart_InitializeNativeAssetsResolver(
    NativeAssetsApi* native_assets_api);

/*
 * =====================
 * Scripts and Libraries
 * =====================
 */

typedef enum {
  Dart_kCanonicalizeUrl = 0,
  Dart_kImportTag,
  Dart_kKernelTag,
} Dart_LibraryTag;

/**
 * The library tag handler is a multi-purpose callback provided by the
 * embedder to the Dart VM. The embedder implements the tag handler to
 * provide the ability to load Dart scripts and imports.
 *
 * -- TAGS --
 *
 * Dart_kCanonicalizeUrl
 *
 * This tag indicates that the embedder should canonicalize 'url' with
 * respect to 'library'.  For most embedders, this is resolving the `url`
 * relative to the `library`s url (see `Dart_LibraryUrl`).
 *
 * Dart_kImportTag
 *
 * This tag is used to load a library from IsolateMirror.loadUri. The embedder
 * should call Dart_LoadLibraryFromKernel to provide the library to the VM. The
 * return value should be an error or library (the result from
 * Dart_LoadLibraryFromKernel).
 *
 * Dart_kKernelTag
 *
 * This tag is used to load the intermediate file (kernel) generated by
 * the Dart front end. This tag is typically used when a 'hot-reload'
 * of an application is needed and the VM is 'use dart front end' mode.
 * The dart front end typically compiles all the scripts, imports and part
 * files into one intermediate file hence we don't use the source/import or
 * script tags. The return value should be an error or a TypedData containing
 * the kernel bytes.
 *
 */
typedef Dart_Handle (*Dart_LibraryTagHandler)(
    Dart_LibraryTag tag,
    Dart_Handle library_or_package_map_url,
    Dart_Handle url);

/**
 * Sets library tag handler for the current isolate. This handler is
 * used to handle the various tags encountered while loading libraries
 * or scripts in the isolate.
 *
 * \param handler Handler code to be used for handling the various tags
 *   encountered while loading libraries or scripts in the isolate.
 *
 * \return If no error occurs, the handler is set for the isolate.
 *   Otherwise an error handle is returned.
 *
 * TODO(turnidge): Document.
 */
DART_EXPORT Dart_Handle
Dart_SetLibraryTagHandler(Dart_LibraryTagHandler handler);

/**
 * Handles deferred loading requests. When this handler is invoked, it should
 * eventually load the deferred loading unit with the given id and call
 * Dart_DeferredLoadComplete or Dart_DeferredLoadCompleteError. It is
 * recommended that the loading occur asynchronously, but it is permitted to
 * call Dart_DeferredLoadComplete or Dart_DeferredLoadCompleteError before the
 * handler returns.
 *
 * If an error is returned, it will be propagated through
 * `prefix.loadLibrary()`. This is useful for synchronous
 * implementations, which must propagate any unwind errors from
 * Dart_DeferredLoadComplete or Dart_DeferredLoadComplete. Otherwise the handler
 * should return a non-error such as `Dart_Null()`.
 */
typedef Dart_Handle (*Dart_DeferredLoadHandler)(intptr_t loading_unit_id);

/**
 * Sets the deferred load handler for the current isolate. This handler is
 * used to handle loading deferred imports in an AppJIT or AppAOT program.
 */
DART_EXPORT Dart_Handle
Dart_SetDeferredLoadHandler(Dart_DeferredLoadHandler handler);

/**
 * Notifies the VM that a deferred load completed successfully. This function
 * will eventually cause the corresponding `prefix.loadLibrary()` futures to
 * complete.
 *
 * Requires the current isolate to be the same current isolate during the
 * invocation of the Dart_DeferredLoadHandler.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_DeferredLoadComplete(intptr_t loading_unit_id,
                          const uint8_t* snapshot_data,
                          const uint8_t* snapshot_instructions);

/**
 * Notifies the VM that a deferred load failed. This function
 * will eventually cause the corresponding `prefix.loadLibrary()` futures to
 * complete with an error.
 *
 * If `transient` is true, future invocations of `prefix.loadLibrary()` will
 * trigger new load requests. If false, futures invocation will complete with
 * the same error.
 *
 * Requires the current isolate to be the same current isolate during the
 * invocation of the Dart_DeferredLoadHandler.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_DeferredLoadCompleteError(intptr_t loading_unit_id,
                               const char* error_message,
                               bool transient);

/**
 * Loads the root library for the current isolate.
 *
 * Requires there to be no current root library.
 *
 * \param kernel_buffer A buffer which contains a kernel binary (see
 *     pkg/kernel/binary.md). Must remain valid until isolate group shutdown.
 * \param kernel_size Length of the passed in buffer.
 *
 * \return A handle to the root library, or an error.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_LoadScriptFromKernel(const uint8_t* kernel_buffer, intptr_t kernel_size);

/**
 * Gets the library for the root script for the current isolate.
 *
 * If the root script has not yet been set for the current isolate,
 * this function returns Dart_Null().  This function never returns an
 * error handle.
 *
 * \return Returns the root Library for the current isolate or Dart_Null().
 */
DART_EXPORT Dart_Handle Dart_RootLibrary(void);

/**
 * Sets the root library for the current isolate.
 *
 * \return Returns an error handle if `library` is not a library handle.
 */
DART_EXPORT Dart_Handle Dart_SetRootLibrary(Dart_Handle library);

/**
 * Lookup or instantiate a legacy type by name and type arguments from a
 * Library.
 *
 * \param library The library containing the class or interface.
 * \param class_name The class name for the type.
 * \param number_of_type_arguments Number of type arguments.
 *   For non parametric types the number of type arguments would be 0.
 * \param type_arguments Pointer to an array of type arguments.
 *   For non parametric types a NULL would be passed in for this argument.
 *
 * \return If no error occurs, the type is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetType(Dart_Handle library,
                                     Dart_Handle class_name,
                                     intptr_t number_of_type_arguments,
                                     Dart_Handle* type_arguments);

/**
 * Lookup or instantiate a nullable type by name and type arguments from
 * Library.
 *
 * \param library The library containing the class or interface.
 * \param class_name The class name for the type.
 * \param number_of_type_arguments Number of type arguments.
 *   For non parametric types the number of type arguments would be 0.
 * \param type_arguments Pointer to an array of type arguments.
 *   For non parametric types a NULL would be passed in for this argument.
 *
 * \return If no error occurs, the type is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetNullableType(Dart_Handle library,
                                             Dart_Handle class_name,
                                             intptr_t number_of_type_arguments,
                                             Dart_Handle* type_arguments);

/**
 * Lookup or instantiate a non-nullable type by name and type arguments from
 * Library.
 *
 * \param library The library containing the class or interface.
 * \param class_name The class name for the type.
 * \param number_of_type_arguments Number of type arguments.
 *   For non parametric types the number of type arguments would be 0.
 * \param type_arguments Pointer to an array of type arguments.
 *   For non parametric types a NULL would be passed in for this argument.
 *
 * \return If no error occurs, the type is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle
Dart_GetNonNullableType(Dart_Handle library,
                        Dart_Handle class_name,
                        intptr_t number_of_type_arguments,
                        Dart_Handle* type_arguments);

/**
 * Creates a nullable version of the provided type.
 *
 * \param type The type to be converted to a nullable type.
 *
 * \return If no error occurs, a nullable type is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_TypeToNullableType(Dart_Handle type);

/**
 * Creates a non-nullable version of the provided type.
 *
 * \param type The type to be converted to a non-nullable type.
 *
 * \return If no error occurs, a non-nullable type is returned.
 *   Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_TypeToNonNullableType(Dart_Handle type);

/**
 * A type's nullability.
 *
 * \param type A Dart type.
 * \param result An out parameter containing the result of the check. True if
 * the type is of the specified nullability, false otherwise.
 *
 * \return Returns an error handle if type is not of type Type.
 */
DART_EXPORT Dart_Handle Dart_IsNullableType(Dart_Handle type, bool* result);
DART_EXPORT Dart_Handle Dart_IsNonNullableType(Dart_Handle type, bool* result);

/**
 * Lookup a class or interface by name from a Library.
 *
 * \param library The library containing the class or interface.
 * \param class_name The name of the class or interface.
 *
 * \return If no error occurs, the class or interface is
 *   returned. Otherwise an error handle is returned.
 */
DART_EXPORT Dart_Handle Dart_GetClass(Dart_Handle library,
                                      Dart_Handle class_name);
/* TODO(asiva): The above method needs to be removed once all uses
 * of it are removed from the embedder code. */

/**
 * Returns an import path to a Library, such as "file:///test.dart" or
 * "dart:core".
 */
DART_EXPORT Dart_Handle Dart_LibraryUrl(Dart_Handle library);

/**
 * Returns a URL from which a Library was loaded.
 */
DART_EXPORT Dart_Handle Dart_LibraryResolvedUrl(Dart_Handle library);

/**
 * \return An array of libraries.
 */
DART_EXPORT Dart_Handle Dart_GetLoadedLibraries(void);

DART_EXPORT Dart_Handle Dart_LookupLibrary(Dart_Handle url);
/* TODO(turnidge): Consider returning Dart_Null() when the library is
 * not found to distinguish that from a true error case. */

/**
 * Report an loading error for the library.
 *
 * \param library The library that failed to load.
 * \param error The Dart error instance containing the load error.
 *
 * \return If the VM handles the error, the return value is
 * a null handle. If it doesn't handle the error, the error
 * object is returned.
 */
DART_EXPORT Dart_Handle Dart_LibraryHandleError(Dart_Handle library,
                                                Dart_Handle error);

/**
 * Called by the embedder to load a partial program. Does not set the root
 * library.
 *
 * \param kernel_buffer A buffer which contains a kernel binary (see
 *     pkg/kernel/binary.md). Must remain valid until isolate shutdown.
 * \param kernel_buffer_size Length of the passed in buffer.
 *
 * \return A handle to the main library of the compilation unit, or an error.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_LoadLibraryFromKernel(const uint8_t* kernel_buffer,
                           intptr_t kernel_buffer_size);
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_LoadLibrary(Dart_Handle kernel_buffer);

/**
 * Indicates that all outstanding load requests have been satisfied.
 * This finalizes all the new classes loaded and optionally completes
 * deferred library futures.
 *
 * Requires there to be a current isolate.
 *
 * \param complete_futures Specify true if all deferred library
 *  futures should be completed, false otherwise.
 *
 * \return Success if all classes have been finalized and deferred library
 *   futures are completed. Otherwise, returns an error.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_FinalizeLoading(bool complete_futures);

/*
 * =====
 * Peers
 * =====
 */

/**
 * The peer field is a lazily allocated field intended for storage of
 * an uncommonly used values.  Most instances types can have a peer
 * field allocated.  The exceptions are subtypes of Null, num, and
 * bool.
 */

/**
 * Returns the value of peer field of 'object' in 'peer'.
 *
 * \param object An object.
 * \param peer An out parameter that returns the value of the peer
 *   field.
 *
 * \return Returns an error if 'object' is a subtype of Null, num, or
 *   bool.
 */
DART_EXPORT Dart_Handle Dart_GetPeer(Dart_Handle object, void** peer);

/**
 * Sets the value of the peer field of 'object' to the value of
 * 'peer'.
 *
 * \param object An object.
 * \param peer A value to store in the peer field.
 *
 * \return Returns an error if 'object' is a subtype of Null, num, or
 *   bool.
 */
DART_EXPORT Dart_Handle Dart_SetPeer(Dart_Handle object, void* peer);

/*
 * ======
 * Kernel
 * ======
 */

/**
 * Experimental support for Dart to Kernel parser isolate.
 *
 * TODO(hausner): Document finalized interface.
 *
 */

// TODO(33433): Remove kernel service from the embedding API.

typedef enum {
  Dart_KernelCompilationStatus_Unknown = -1,
  Dart_KernelCompilationStatus_Ok = 0,
  Dart_KernelCompilationStatus_Error = 1,
  Dart_KernelCompilationStatus_Crash = 2,
  Dart_KernelCompilationStatus_MsgFailed = 3,
} Dart_KernelCompilationStatus;

typedef struct {
  Dart_KernelCompilationStatus status;
  char* error;
  uint8_t* kernel;
  intptr_t kernel_size;
} Dart_KernelCompilationResult;

typedef enum {
  Dart_KernelCompilationVerbosityLevel_Error = 0,
  Dart_KernelCompilationVerbosityLevel_Warning,
  Dart_KernelCompilationVerbosityLevel_Info,
  Dart_KernelCompilationVerbosityLevel_All,
} Dart_KernelCompilationVerbosityLevel;

DART_EXPORT bool Dart_IsKernelIsolate(Dart_Isolate isolate);
DART_EXPORT bool Dart_KernelIsolateIsRunning(void);
DART_EXPORT Dart_Port Dart_KernelPort(void);

/**
 * Compiles the given `script_uri` to a kernel file.
 *
 * \param platform_kernel A buffer containing the kernel of the platform (e.g.
 * `vm_platform_strong.dill`). The VM does not take ownership of this memory.
 *
 * \param platform_kernel_size The length of the platform_kernel buffer.
 *
 * \param snapshot_compile Set to `true` when the compilation is for a snapshot.
 * This is used by the frontend to determine if compilation related information
 * should be printed to console (e.g., null safety mode).
 *
 * \param embed_sources Set to `true` when sources should be embedded in the
 * kernel file.
 *
 * \param verbosity Specifies the logging behavior of the kernel compilation
 * service.
 *
 * \return Returns the result of the compilation.
 *
 * On a successful compilation the returned [Dart_KernelCompilationResult] has
 * a status of [Dart_KernelCompilationStatus_Ok] and the `kernel`/`kernel_size`
 * fields are set. The caller takes ownership of the malloc()ed buffer.
 *
 * On a failed compilation the `error` might be set describing the reason for
 * the failed compilation. The caller takes ownership of the malloc()ed
 * error.
 *
 * Requires there to be a current isolate.
 */
DART_EXPORT Dart_KernelCompilationResult
Dart_CompileToKernel(const char* script_uri,
                     const uint8_t* platform_kernel,
                     const intptr_t platform_kernel_size,
                     bool incremental_compile,
                     bool snapshot_compile,
                     bool embed_sources,
                     const char* package_config,
                     Dart_KernelCompilationVerbosityLevel verbosity);

typedef struct {
  const char* uri;
  const char* source;
} Dart_SourceFile;

DART_EXPORT Dart_KernelCompilationResult Dart_KernelListDependencies(void);

/**
 * Sets the kernel buffer which will be used to load Dart SDK sources
 * dynamically at runtime.
 *
 * \param platform_kernel A buffer containing kernel which has sources for the
 * Dart SDK populated. Note: The VM does not take ownership of this memory.
 *
 * \param platform_kernel_size The length of the platform_kernel buffer.
 */
DART_EXPORT void Dart_SetDartLibrarySourcesKernel(
    const uint8_t* platform_kernel,
    const intptr_t platform_kernel_size);

/**
 * Always return true as the VM only supports strong null safety.
 */
DART_EXPORT bool Dart_DetectNullSafety(const char* script_uri,
                                       const char* package_config,
                                       const char* original_working_directory,
                                       const uint8_t* snapshot_data,
                                       const uint8_t* snapshot_instructions,
                                       const uint8_t* kernel_buffer,
                                       intptr_t kernel_buffer_size);

#define DART_KERNEL_ISOLATE_NAME "kernel-service"

/*
 * =======
 * Service
 * =======
 */

#define DART_VM_SERVICE_ISOLATE_NAME "vm-service"

/**
 * Returns true if isolate is the service isolate.
 *
 * \param isolate An isolate
 *
 * \return Returns true if 'isolate' is the service isolate.
 */
DART_EXPORT bool Dart_IsServiceIsolate(Dart_Isolate isolate);

/**
 * Writes the CPU profile to the timeline as a series of 'instant' events.
 *
 * Note that this is an expensive operation.
 *
 * \param main_port The main port of the Isolate whose profile samples to write.
 * \param error An optional error, must be free()ed by caller.
 *
 * \return Returns true if the profile is successfully written and false
 *         otherwise.
 */
DART_EXPORT bool Dart_WriteProfileToTimeline(Dart_Port main_port, char** error);

/*
 * ==============
 * Precompilation
 * ==============
 */

/**
 * Compiles all functions reachable from entry points and marks
 * the isolate to disallow future compilation.
 *
 * Entry points should be specified using `@pragma("vm:entry-point")`
 * annotation.
 *
 * \return An error handle if a compilation error or runtime error running const
 * constructors was encountered.
 */
DART_EXPORT Dart_Handle Dart_Precompile(void);

typedef void (*Dart_CreateLoadingUnitCallback)(
    void* callback_data,
    intptr_t loading_unit_id,
    void** write_callback_data,
    void** write_debug_callback_data);
typedef void (*Dart_StreamingWriteCallback)(void* callback_data,
                                            const uint8_t* buffer,
                                            intptr_t size);
typedef void (*Dart_StreamingCloseCallback)(void* callback_data);

DART_EXPORT Dart_Handle Dart_LoadingUnitLibraryUris(intptr_t loading_unit_id);

// On Darwin systems, 'dlsym' adds an '_' to the beginning of the symbol name.
// Use the '...CSymbol' definitions for resolving through 'dlsym'. The actual
// symbol names in the objects are given by the '...AsmSymbol' definitions.
#if defined(__APPLE__)
#define kSnapshotBuildIdCSymbol "kDartSnapshotBuildId"
#define kVmSnapshotDataCSymbol "kDartVmSnapshotData"
#define kVmSnapshotInstructionsCSymbol "kDartVmSnapshotInstructions"
#define kVmSnapshotBssCSymbol "kDartVmSnapshotBss"
#define kIsolateSnapshotDataCSymbol "kDartIsolateSnapshotData"
#define kIsolateSnapshotInstructionsCSymbol "kDartIsolateSnapshotInstructions"
#define kIsolateSnapshotBssCSymbol "kDartIsolateSnapshotBss"
#else
#define kSnapshotBuildIdCSymbol "_kDartSnapshotBuildId"
#define kVmSnapshotDataCSymbol "_kDartVmSnapshotData"
#define kVmSnapshotInstructionsCSymbol "_kDartVmSnapshotInstructions"
#define kVmSnapshotBssCSymbol "_kDartVmSnapshotBss"
#define kIsolateSnapshotDataCSymbol "_kDartIsolateSnapshotData"
#define kIsolateSnapshotInstructionsCSymbol "_kDartIsolateSnapshotInstructions"
#define kIsolateSnapshotBssCSymbol "_kDartIsolateSnapshotBss"
#endif

#define kSnapshotBuildIdAsmSymbol "_kDartSnapshotBuildId"
#define kVmSnapshotDataAsmSymbol "_kDartVmSnapshotData"
#define kVmSnapshotInstructionsAsmSymbol "_kDartVmSnapshotInstructions"
#define kVmSnapshotBssAsmSymbol "_kDartVmSnapshotBss"
#define kIsolateSnapshotDataAsmSymbol "_kDartIsolateSnapshotData"
#define kIsolateSnapshotInstructionsAsmSymbol                                  \
  "_kDartIsolateSnapshotInstructions"
#define kIsolateSnapshotBssAsmSymbol "_kDartIsolateSnapshotBss"

/**
 *  Creates a precompiled snapshot.
 *   - A root library must have been loaded.
 *   - Dart_Precompile must have been called.
 *
 *  Outputs an assembly file defining the symbols listed in the definitions
 *  above.
 *
 *  The assembly should be compiled as a static or shared library and linked or
 *  loaded by the embedder. Running this snapshot requires a VM compiled with
 *  DART_PRECOMPILED_SNAPSHOT. The kDartVmSnapshotData and
 *  kDartVmSnapshotInstructions should be passed to Dart_Initialize. The
 *  kDartIsolateSnapshotData and kDartIsolateSnapshotInstructions should be
 *  passed to Dart_CreateIsolateGroup.
 *
 *  The callback will be invoked one or more times to provide the assembly code.
 *
 *  If stripped is true, then the assembly code will not include DWARF
 *  debugging sections.
 *
 *  If debug_callback_data is provided, debug_callback_data will be used with
 *  the callback to provide separate debugging information.
 *
 *  \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateAppAOTSnapshotAsAssembly(Dart_StreamingWriteCallback callback,
                                    void* callback_data,
                                    bool stripped,
                                    void* debug_callback_data);
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateAppAOTSnapshotAsAssemblies(
    Dart_CreateLoadingUnitCallback next_callback,
    void* next_callback_data,
    bool stripped,
    Dart_StreamingWriteCallback write_callback,
    Dart_StreamingCloseCallback close_callback);

/**
 *  Creates a precompiled snapshot.
 *   - A root library must have been loaded.
 *   - Dart_Precompile must have been called.
 *
 *  Outputs an ELF shared library defining the symbols
 *   - _kDartVmSnapshotData
 *   - _kDartVmSnapshotInstructions
 *   - _kDartIsolateSnapshotData
 *   - _kDartIsolateSnapshotInstructions
 *
 *  The shared library should be dynamically loaded by the embedder.
 *  Running this snapshot requires a VM compiled with DART_PRECOMPILED_SNAPSHOT.
 *  The kDartVmSnapshotData and kDartVmSnapshotInstructions should be passed to
 *  Dart_Initialize. The kDartIsolateSnapshotData and
 *  kDartIsolateSnapshotInstructions should be passed to Dart_CreateIsolate.
 *
 *  The callback will be invoked one or more times to provide the binary output.
 *
 *  If stripped is true, then the binary output will not include DWARF
 *  debugging sections.
 *
 *  If debug_callback_data is provided, debug_callback_data will be used with
 *  the callback to provide separate debugging information.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateAppAOTSnapshotAsElf(Dart_StreamingWriteCallback callback,
                               void* callback_data,
                               bool stripped,
                               void* debug_callback_data);
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateAppAOTSnapshotAsElfs(Dart_CreateLoadingUnitCallback next_callback,
                                void* next_callback_data,
                                bool stripped,
                                Dart_StreamingWriteCallback write_callback,
                                Dart_StreamingCloseCallback close_callback);

/**
 *  Like Dart_CreateAppAOTSnapshotAsAssembly, but only includes
 *  kDartVmSnapshotData and kDartVmSnapshotInstructions. It also does
 *  not strip DWARF information from the generated assembly or allow for
 *  separate debug information.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateVMAOTSnapshotAsAssembly(Dart_StreamingWriteCallback callback,
                                   void* callback_data);

/**
 * Sorts the class-ids in depth first traversal order of the inheritance
 * tree. This is a costly operation, but it can make method dispatch
 * more efficient and is done before writing snapshots.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle Dart_SortClasses(void);

/**
 *  Creates a snapshot that caches compiled code and type feedback for faster
 *  startup and quicker warmup in a subsequent process.
 *
 *  Outputs a snapshot in two pieces. The pieces should be passed to
 *  Dart_CreateIsolateGroup in a VM using the same VM snapshot pieces used in the
 *  current VM. The instructions piece must be loaded with read and execute
 *  permissions; the data piece may be loaded as read-only.
 *
 *   - Requires the VM to have not been started with --precompilation.
 *   - Not supported when targeting IA32.
 *   - The VM writing the snapshot and the VM reading the snapshot must be the
 *     same version, must be built in the same DEBUG/RELEASE/PRODUCT mode, must
 *     be targeting the same architecture, and must both be in checked mode or
 *     both in unchecked mode.
 *
 *  The buffers are scope allocated and are only valid until the next call to
 *  Dart_ExitScope.
 *
 * \return A valid handle if no error occurs during the operation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_CreateAppJITSnapshotAsBlobs(uint8_t** isolate_snapshot_data_buffer,
                                 intptr_t* isolate_snapshot_data_size,
                                 uint8_t** isolate_snapshot_instructions_buffer,
                                 intptr_t* isolate_snapshot_instructions_size);

/**
 * Get obfuscation map for precompiled code.
 *
 * Obfuscation map is encoded as a JSON array of pairs (original name,
 * obfuscated name).
 *
 * \return Returns an error handler if the VM was built in a mode that does not
 * support obfuscation.
 */
DART_EXPORT DART_WARN_UNUSED_RESULT Dart_Handle
Dart_GetObfuscationMap(uint8_t** buffer, intptr_t* buffer_length);

/**
 *  Returns whether the VM only supports running from precompiled snapshots and
 *  not from any other kind of snapshot or from source (that is, the VM was
 *  compiled with DART_PRECOMPILED_RUNTIME).
 */
DART_EXPORT bool Dart_IsPrecompiledRuntime(void);

/**
 *  Print a native stack trace. Used for crash handling.
 *
 *  If context is NULL, prints the current stack trace. Otherwise, context
 *  should be a CONTEXT* (Windows) or ucontext_t* (POSIX) from a signal handler
 *  running on the current thread.
 */
DART_EXPORT void Dart_DumpNativeStackTrace(void* context);

/**
 *  Indicate that the process is about to abort, and the Dart VM should not
 *  attempt to cleanup resources.
 */
DART_EXPORT void Dart_PrepareToAbort(void);

/**
 * Callback provided by the embedder that is used by the VM to
 * produce footnotes appended to DWARF stack traces.
 *
 * Whenever VM formats a stack trace as a string it would call this callback
 * passing raw program counters for each frame in the stack trace.
 *
 * Embedder can then return a string which if not-null will be appended to the
 * formatted stack trace.
 *
 * Returned string is expected to be `malloc()` allocated. VM takes ownership
 * of the returned string and will `free()` it.
 *
 * \param addresses raw program counter addresses for each frame
 * \param count number of elements in the addresses array
 */
typedef char* (*Dart_DwarfStackTraceFootnoteCallback)(void* addresses[],
                                                      intptr_t count);

/**
 *  Configure DWARF stack trace footnote callback.
 */
DART_EXPORT void Dart_SetDwarfStackTraceFootnoteCallback(
    Dart_DwarfStackTraceFootnoteCallback callback);

#endif /* INCLUDE_DART_API_H_ */ /* NOLINT */

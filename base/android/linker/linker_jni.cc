// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is the Android-specific Chromium linker, a tiny shared library
// implementing a custom dynamic linker that can be used to load the
// real Chromium libraries (e.g. libcontentshell.so).

// The main point of this linker is to be able to share the RELRO
// section of libcontentshell.so (or equivalent) between the browser and
// renderer process.

// This source code *cannot* depend on anything from base/ or the C++
// STL, to keep the final library small, and avoid ugly dependency issues.

#include <android/log.h>
#include <crazy_linker.h>
#include <fcntl.h>
#include <jni.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>

// Set this to 1 to enable debug traces to the Android log.
// Note that LOG() from "base/logging.h" cannot be used, since it is
// in base/ which hasn't been loaded yet.
#define DEBUG 0

#define TAG "chromium_android_linker"

#if DEBUG
#define LOG_INFO(...) __android_log_print(ANDROID_LOG_INFO, TAG, __VA_ARGS__)
#else
#define LOG_INFO(...) ((void)0)
#endif
#define LOG_ERROR(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

#define UNUSED __attribute__((unused))

namespace {

// A simply scoped UTF String class that can be initialized from
// a Java jstring handle. Modeled like std::string, which cannot
// be used here.
class String {
 public:
  String(JNIEnv* env, jstring str);

  ~String() {
    if (ptr_)
      ::free(ptr_);
  }

  const char* c_str() const { return ptr_ ? ptr_ : ""; }
  size_t size() const { return size_; }

 private:
  char* ptr_;
  size_t size_;
};

String::String(JNIEnv* env, jstring str) {
  size_ = env->GetStringUTFLength(str);
  ptr_ = static_cast<char*>(::malloc(size_ + 1));

  // Note: the result contains Java "modified UTF-8" bytes.
  // Good enough for the linker though.
  const char* bytes = env->GetStringUTFChars(str, NULL);
  ::memcpy(ptr_, bytes, size_);
  ptr_[size_] = '\0';

  env->ReleaseStringUTFChars(str, bytes);
}

// Return true iff |address| is a valid address for the target CPU.
bool IsValidAddress(jlong address) {
  return static_cast<jlong>(static_cast<size_t>(address)) == address;
}

// Find the jclass JNI reference corresponding to a given |class_name|.
// |env| is the current JNI environment handle.
// On success, return true and set |*clazz|.
bool InitClassReference(JNIEnv* env, const char* class_name, jclass* clazz) {
  *clazz = env->FindClass(class_name);
  if (!*clazz) {
    LOG_ERROR("Could not find class for %s", class_name);
    return false;
  }
  return true;
}

// Initialize a jfieldID corresponding to the field of a given |clazz|,
// with name |field_name| and signature |field_sig|.
// |env| is the current JNI environment handle.
// On success, return true and set |*field_id|.
bool InitFieldId(JNIEnv* env,
                 jclass clazz,
                 const char* field_name,
                 const char* field_sig,
                 jfieldID* field_id) {
  *field_id = env->GetFieldID(clazz, field_name, field_sig);
  if (!*field_id) {
    LOG_ERROR("Could not find ID for field '%s'", field_name);
    return false;
  }
  LOG_INFO(
      "%s: Found ID %p for field '%s'", __FUNCTION__, *field_id, field_name);
  return true;
}

// Initialize a jmethodID corresponding to the static method of a given
// |clazz|, with name |method_name| and signature |method_sig|.
// |env| is the current JNI environment handle.
// On success, return true and set |*method_id|.
bool InitStaticMethodId(JNIEnv* env,
                        jclass clazz,
                        const char* method_name,
                        const char* method_sig,
                        jmethodID* method_id) {
  *method_id = env->GetStaticMethodID(clazz, method_name, method_sig);
  if (!*method_id) {
    LOG_ERROR("Could not find ID for static method '%s'", method_name);
    return false;
  }
  LOG_INFO("%s: Found ID %p for static method '%s'",
           __FUNCTION__, *method_id, method_name);
  return true;
}

// Initialize a jfieldID corresponding to the static field of a given |clazz|,
// with name |field_name| and signature |field_sig|.
// |env| is the current JNI environment handle.
// On success, return true and set |*field_id|.
bool InitStaticFieldId(JNIEnv* env,
                       jclass clazz,
                       const char* field_name,
                       const char* field_sig,
                       jfieldID* field_id) {
  *field_id = env->GetStaticFieldID(clazz, field_name, field_sig);
  if (!*field_id) {
    LOG_ERROR("Could not find ID for static field '%s'", field_name);
    return false;
  }
  LOG_INFO(
      "%s: Found ID %p for static field '%s'",
      __FUNCTION__, *field_id, field_name);
  return true;
}

// Initialize a jint corresponding to the static integer field of a class
// with class name |class_name| and field name |field_name|.
// |env| is the current JNI environment handle.
// On success, return true and set |*value|.
bool InitStaticInt(JNIEnv* env,
                   const char* class_name,
                   const char* field_name,
                   jint* value) {
  jclass clazz;
  if (!InitClassReference(env, class_name, &clazz))
    return false;

  jfieldID field_id;
  if (!InitStaticFieldId(env, clazz, field_name, "I", &field_id))
    return false;

  *value = env->GetStaticIntField(clazz, field_id);
  LOG_INFO(
      "%s: Found value %d for class '%s', static field '%s'",
      __FUNCTION__, *value, class_name, field_name);

  return true;
}

// A class used to model the field IDs of the org.chromium.base.Linker
// LibInfo inner class, used to communicate data with the Java side
// of the linker.
struct LibInfo_class {
  jfieldID load_address_id;
  jfieldID load_size_id;
  jfieldID relro_start_id;
  jfieldID relro_size_id;
  jfieldID relro_fd_id;

  // Initialize an instance.
  bool Init(JNIEnv* env) {
    jclass clazz;
    if (!InitClassReference(
             env, "org/chromium/base/library_loader/Linker$LibInfo", &clazz)) {
      return false;
    }

    return InitFieldId(env, clazz, "mLoadAddress", "J", &load_address_id) &&
           InitFieldId(env, clazz, "mLoadSize", "J", &load_size_id) &&
           InitFieldId(env, clazz, "mRelroStart", "J", &relro_start_id) &&
           InitFieldId(env, clazz, "mRelroSize", "J", &relro_size_id) &&
           InitFieldId(env, clazz, "mRelroFd", "I", &relro_fd_id);
  }

  void SetLoadInfo(JNIEnv* env,
                   jobject library_info_obj,
                   size_t load_address,
                   size_t load_size) {
    env->SetLongField(library_info_obj, load_address_id, load_address);
    env->SetLongField(library_info_obj, load_size_id, load_size);
  }

  // Use this instance to convert a RelroInfo reference into
  // a crazy_library_info_t.
  void GetRelroInfo(JNIEnv* env,
                    jobject library_info_obj,
                    size_t* relro_start,
                    size_t* relro_size,
                    int* relro_fd) {
    *relro_start = static_cast<size_t>(
        env->GetLongField(library_info_obj, relro_start_id));

    *relro_size =
        static_cast<size_t>(env->GetLongField(library_info_obj, relro_size_id));

    *relro_fd = env->GetIntField(library_info_obj, relro_fd_id);
  }

  void SetRelroInfo(JNIEnv* env,
                    jobject library_info_obj,
                    size_t relro_start,
                    size_t relro_size,
                    int relro_fd) {
    env->SetLongField(library_info_obj, relro_start_id, relro_start);
    env->SetLongField(library_info_obj, relro_size_id, relro_size);
    env->SetIntField(library_info_obj, relro_fd_id, relro_fd);
  }
};

static LibInfo_class s_lib_info_fields;

// Retrieve the SDK build version and pass it into the crazy linker. This
// needs to be done early in initialization, before any other crazy linker
// code is run.
// |env| is the current JNI environment handle.
// On success, return true.
bool InitSDKVersionInfo(JNIEnv* env) {
  jint value = 0;
  if (!InitStaticInt(env, "android/os/Build$VERSION", "SDK_INT", &value))
    return false;

  crazy_set_sdk_build_version(static_cast<int>(value));
  LOG_INFO("%s: Set SDK build version to %d",
           __FUNCTION__, static_cast<int>(value));

  return true;
}

// The linker uses a single crazy_context_t object created on demand.
// There is no need to protect this against concurrent access, locking
// is already handled on the Java side.
static crazy_context_t* s_crazy_context;

crazy_context_t* GetCrazyContext() {
  if (!s_crazy_context) {
    // Create new context.
    s_crazy_context = crazy_context_create();

    // Ensure libraries located in the same directory as the linker
    // can be loaded before system ones.
    crazy_context_add_search_path_for_address(
        s_crazy_context, reinterpret_cast<void*>(&s_crazy_context));
  }

  return s_crazy_context;
}

// A scoped crazy_library_t that automatically closes the handle
// on scope exit, unless Release() has been called.
class ScopedLibrary {
 public:
  ScopedLibrary() : lib_(NULL) {}

  ~ScopedLibrary() {
    if (lib_)
      crazy_library_close_with_context(lib_, GetCrazyContext());
  }

  crazy_library_t* Get() { return lib_; }

  crazy_library_t** GetPtr() { return &lib_; }

  crazy_library_t* Release() {
    crazy_library_t* ret = lib_;
    lib_ = NULL;
    return ret;
  }

 private:
  crazy_library_t* lib_;
};

namespace {

template <class LibraryOpener>
bool GenericLoadLibrary(
    JNIEnv* env,
    const char* library_name, jlong load_address, jobject lib_info_obj,
    const LibraryOpener& opener) {
  crazy_context_t* context = GetCrazyContext();

  if (!IsValidAddress(load_address)) {
    LOG_ERROR("%s: Invalid address 0x%llx", __FUNCTION__, load_address);
    return false;
  }

  // Set the desired load address (0 means randomize it).
  crazy_context_set_load_address(context, static_cast<size_t>(load_address));

  ScopedLibrary library;
  if (!opener.Open(library.GetPtr(), library_name, context)) {
    return false;
  }

  crazy_library_info_t info;
  if (!crazy_library_get_info(library.Get(), context, &info)) {
    LOG_ERROR("%s: Could not get library information for %s: %s",
              __FUNCTION__,
              library_name,
              crazy_context_get_error(context));
    return false;
  }

  // Release library object to keep it alive after the function returns.
  library.Release();

  s_lib_info_fields.SetLoadInfo(
      env, lib_info_obj, info.load_address, info.load_size);
  LOG_INFO("%s: Success loading library %s", __FUNCTION__, library_name);
  return true;
}

// Used for opening the library in a regular file.
class FileLibraryOpener {
 public:
  bool Open(
      crazy_library_t** library,
      const char* library_name,
      crazy_context_t* context) const;
};

bool FileLibraryOpener::Open(
    crazy_library_t** library,
    const char* library_name,
    crazy_context_t* context) const {
  if (!crazy_library_open(library, library_name, context)) {
    LOG_ERROR("%s: Could not open %s: %s",
              __FUNCTION__,
              library_name,
              crazy_context_get_error(context));
    return false;
  }
  return true;
}

// Used for opening the library in a zip file.
class ZipLibraryOpener {
 public:
  explicit ZipLibraryOpener(const char* zip_file) : zip_file_(zip_file) {}
  bool Open(
      crazy_library_t** library,
      const char* library_name,
      crazy_context_t* context) const;
 private:
  const char* zip_file_;
};

bool ZipLibraryOpener::Open(
    crazy_library_t** library,
    const char* library_name,
    crazy_context_t* context) const {
  if (!crazy_library_open_in_zip_file(
          library, zip_file_, library_name, context)) {
     LOG_ERROR("%s: Could not open %s in zip file %s: %s",
               __FUNCTION__, library_name, zip_file_,
               crazy_context_get_error(context));
     return false;
  }
  return true;
}

}  // unnamed namespace

// Load a library with the chromium linker. This will also call its
// JNI_OnLoad() method, which shall register its methods. Note that
// lazy native method resolution will _not_ work after this, because
// Dalvik uses the system's dlsym() which won't see the new library,
// so explicit registration is mandatory.
// |env| is the current JNI environment handle.
// |clazz| is the static class handle for org.chromium.base.Linker,
// and is ignored here.
// |library_name| is the library name (e.g. libfoo.so).
// |load_address| is an explicit load address.
// |library_info| is a LibInfo handle used to communicate information
// with the Java side.
// Return true on success.
jboolean LoadLibrary(JNIEnv* env,
                     jclass clazz,
                     jstring library_name,
                     jlong load_address,
                     jobject lib_info_obj) {
  String lib_name(env, library_name);
  FileLibraryOpener opener;
  return GenericLoadLibrary(
      env, lib_name.c_str(),
      static_cast<size_t>(load_address), lib_info_obj, opener);
}

// Load a library from a zipfile with the chromium linker. The
// library in the zipfile must be uncompressed and page aligned.
// The basename of the library is given. The library is expected
// to be lib/<abi_tag>/crazy.<basename>. The <abi_tag> used will be the
// same as the abi for this linker. The "crazy." prefix is included
// so that the Android Package Manager doesn't extract the library into
// /data/app-lib.
//
// Loading the library will also call its JNI_OnLoad() method, which
// shall register its methods. Note that lazy native method resolution
// will _not_ work after this, because Dalvik uses the system's dlsym()
// which won't see the new library, so explicit registration is mandatory.
//
// |env| is the current JNI environment handle.
// |clazz| is the static class handle for org.chromium.base.Linker,
// and is ignored here.
// |zipfile_name| is the filename of the zipfile containing the library.
// |library_name| is the library base name (e.g. libfoo.so).
// |load_address| is an explicit load address.
// |library_info| is a LibInfo handle used to communicate information
// with the Java side.
// Returns true on success.
jboolean LoadLibraryInZipFile(JNIEnv* env,
                              jclass clazz,
                              jstring zipfile_name,
                              jstring library_name,
                              jlong load_address,
                              jobject lib_info_obj) {
  String zipfile_name_str(env, zipfile_name);
  String lib_name(env, library_name);
  ZipLibraryOpener opener(zipfile_name_str.c_str());
  return GenericLoadLibrary(
      env, lib_name.c_str(),
      static_cast<size_t>(load_address), lib_info_obj, opener);
}

// Class holding the Java class and method ID for the Java side Linker
// postCallbackOnMainThread method.
struct JavaCallbackBindings_class {
  jclass clazz;
  jmethodID method_id;

  // Initialize an instance.
  bool Init(JNIEnv* env, jclass linker_class) {
    clazz = reinterpret_cast<jclass>(env->NewGlobalRef(linker_class));
    return InitStaticMethodId(env,
                              linker_class,
                              "postCallbackOnMainThread",
                              "(J)V",
                              &method_id);
  }
};

static JavaCallbackBindings_class s_java_callback_bindings;

// Designated receiver function for callbacks from Java. Its name is known
// to the Java side.
// |env| is the current JNI environment handle and is ignored here.
// |clazz| is the static class handle for org.chromium.base.Linker,
// and is ignored here.
// |arg| is a pointer to an allocated crazy_callback_t, deleted after use.
void RunCallbackOnUiThread(JNIEnv* env, jclass clazz, jlong arg) {
  crazy_callback_t* callback = reinterpret_cast<crazy_callback_t*>(arg);

  LOG_INFO("%s: Called back from java with handler %p, opaque %p",
           __FUNCTION__, callback->handler, callback->opaque);

  crazy_callback_run(callback);
  delete callback;
}

// Request a callback from Java. The supplied crazy_callback_t is valid only
// for the duration of this call, so we copy it to a newly allocated
// crazy_callback_t and then call the Java side's postCallbackOnMainThread.
// This will call back to to our RunCallbackOnUiThread some time
// later on the UI thread.
// |callback_request| is a crazy_callback_t.
// |poster_opaque| is unused.
// Returns true if the callback request succeeds.
static bool PostForLaterExecution(crazy_callback_t* callback_request,
                                  void* poster_opaque UNUSED) {
  crazy_context_t* context = GetCrazyContext();

  JavaVM* vm;
  int minimum_jni_version;
  crazy_context_get_java_vm(context,
                            reinterpret_cast<void**>(&vm),
                            &minimum_jni_version);

  // Do not reuse JNIEnv from JNI_OnLoad, but retrieve our own.
  JNIEnv* env;
  if (JNI_OK != vm->GetEnv(
      reinterpret_cast<void**>(&env), minimum_jni_version)) {
    LOG_ERROR("Could not create JNIEnv");
    return false;
  }

  // Copy the callback; the one passed as an argument may be temporary.
  crazy_callback_t* callback = new crazy_callback_t();
  *callback = *callback_request;

  LOG_INFO("%s: Calling back to java with handler %p, opaque %p",
           __FUNCTION__, callback->handler, callback->opaque);

  jlong arg = static_cast<jlong>(reinterpret_cast<uintptr_t>(callback));

  env->CallStaticVoidMethod(
      s_java_callback_bindings.clazz, s_java_callback_bindings.method_id, arg);

  // Back out and return false if we encounter a JNI exception.
  if (env->ExceptionCheck() == JNI_TRUE) {
    env->ExceptionDescribe();
    env->ExceptionClear();
    delete callback;
    return false;
  }

  return true;
}

jboolean CreateSharedRelro(JNIEnv* env,
                           jclass clazz,
                           jstring library_name,
                           jlong load_address,
                           jobject lib_info_obj) {
  String lib_name(env, library_name);

  LOG_INFO("%s: Called for %s", __FUNCTION__, lib_name.c_str());

  if (!IsValidAddress(load_address)) {
    LOG_ERROR("%s: Invalid address 0x%llx", __FUNCTION__, load_address);
    return false;
  }

  ScopedLibrary library;
  if (!crazy_library_find_by_name(lib_name.c_str(), library.GetPtr())) {
    LOG_ERROR("%s: Could not find %s", __FUNCTION__, lib_name.c_str());
    return false;
  }

  crazy_context_t* context = GetCrazyContext();
  size_t relro_start = 0;
  size_t relro_size = 0;
  int relro_fd = -1;

  if (!crazy_library_create_shared_relro(library.Get(),
                                         context,
                                         static_cast<size_t>(load_address),
                                         &relro_start,
                                         &relro_size,
                                         &relro_fd)) {
    LOG_ERROR("%s: Could not create shared RELRO sharing for %s: %s\n",
              __FUNCTION__,
              lib_name.c_str(),
              crazy_context_get_error(context));
    return false;
  }

  s_lib_info_fields.SetRelroInfo(
      env, lib_info_obj, relro_start, relro_size, relro_fd);
  return true;
}

jboolean UseSharedRelro(JNIEnv* env,
                        jclass clazz,
                        jstring library_name,
                        jobject lib_info_obj) {
  String lib_name(env, library_name);

  LOG_INFO("%s: called for %s, lib_info_ref=%p",
           __FUNCTION__,
           lib_name.c_str(),
           lib_info_obj);

  ScopedLibrary library;
  if (!crazy_library_find_by_name(lib_name.c_str(), library.GetPtr())) {
    LOG_ERROR("%s: Could not find %s", __FUNCTION__, lib_name.c_str());
    return false;
  }

  crazy_context_t* context = GetCrazyContext();
  size_t relro_start = 0;
  size_t relro_size = 0;
  int relro_fd = -1;
  s_lib_info_fields.GetRelroInfo(
      env, lib_info_obj, &relro_start, &relro_size, &relro_fd);

  LOG_INFO("%s: library=%s relro start=%p size=%p fd=%d",
           __FUNCTION__,
           lib_name.c_str(),
           (void*)relro_start,
           (void*)relro_size,
           relro_fd);

  if (!crazy_library_use_shared_relro(
           library.Get(), context, relro_start, relro_size, relro_fd)) {
    LOG_ERROR("%s: Could not use shared RELRO for %s: %s",
              __FUNCTION__,
              lib_name.c_str(),
              crazy_context_get_error(context));
    return false;
  }

  LOG_INFO("%s: Library %s using shared RELRO section!",
           __FUNCTION__,
           lib_name.c_str());

  return true;
}

jboolean CanUseSharedRelro(JNIEnv* env, jclass clazz) {
  return crazy_system_can_share_relro();
}

jlong GetRandomBaseLoadAddress(JNIEnv* env, jclass clazz, jlong bytes) {
  void* address =
      mmap(NULL, bytes, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (address == MAP_FAILED) {
    LOG_INFO("%s: Random base load address not determinable\n", __FUNCTION__);
    return 0;
  }
  munmap(address, bytes);
  LOG_INFO("%s: Random base load address is %p\n", __FUNCTION__, address);
  return static_cast<jlong>(reinterpret_cast<uintptr_t>(address));
}

// Get the full path of a library in the zip file
// (lib/<abi>/crazy.<lib_name>).
//
// |env| is the current JNI environment handle.
// |clazz| is the static class handle which is not used here.
// |lib_name| is the library base name.
// Returns the full path (or empty string on failure).
jstring GetLibraryFilePathInZipFile(JNIEnv* env,
                                    jclass clazz,
                                    jstring lib_name) {
  String lib_name_str(env, lib_name);
  const char* lib_name_c_str = lib_name_str.c_str();
  char buffer[kMaxFilePathLengthInZip + 1];
  if (crazy_library_file_path_in_zip_file(
          lib_name_c_str, buffer, sizeof(buffer)) == CRAZY_STATUS_FAILURE) {
    LOG_ERROR("%s: Failed to get full filename for library '%s'",
              __FUNCTION__, lib_name_c_str);
    buffer[0] = '\0';
  }
  return env->NewStringUTF(buffer);
}

// Check whether a library is page aligned and uncompressed in the APK file.
//
// |env| is the current JNI environment handle.
// |clazz| is the static class handle which is not used here.
// |apkfile_name| is the filename of the APK.
// |library_name| is the library base name.
// Returns true if page aligned and uncompressed.
jboolean CheckLibraryIsMappableInApk(JNIEnv* env, jclass clazz,
                                     jstring apkfile_name,
                                     jstring library_name) {
  String apkfile_name_str(env, apkfile_name);
  const char* apkfile_name_c_str = apkfile_name_str.c_str();
  String library_name_str(env, library_name);
  const char* library_name_c_str = library_name_str.c_str();

  LOG_INFO("%s: Checking if %s is page-aligned and uncompressed in %s\n",
           __FUNCTION__, library_name_c_str, apkfile_name_c_str);
  jboolean mappable = crazy_linker_check_library_is_mappable_in_zip_file(
      apkfile_name_c_str, library_name_c_str) == CRAZY_STATUS_SUCCESS;
  LOG_INFO("%s: %s\n", __FUNCTION__, mappable ? "Mappable" : "NOT mappable");

  return mappable;
}

const JNINativeMethod kNativeMethods[] = {
    {"nativeLoadLibrary",
     "("
     "Ljava/lang/String;"
     "J"
     "Lorg/chromium/base/library_loader/Linker$LibInfo;"
     ")"
     "Z",
     reinterpret_cast<void*>(&LoadLibrary)},
    {"nativeLoadLibraryInZipFile",
     "("
     "Ljava/lang/String;"
     "Ljava/lang/String;"
     "J"
     "Lorg/chromium/base/library_loader/Linker$LibInfo;"
     ")"
     "Z",
     reinterpret_cast<void*>(&LoadLibraryInZipFile)},
    {"nativeRunCallbackOnUiThread",
     "("
     "J"
     ")"
     "V",
     reinterpret_cast<void*>(&RunCallbackOnUiThread)},
    {"nativeCreateSharedRelro",
     "("
     "Ljava/lang/String;"
     "J"
     "Lorg/chromium/base/library_loader/Linker$LibInfo;"
     ")"
     "Z",
     reinterpret_cast<void*>(&CreateSharedRelro)},
    {"nativeUseSharedRelro",
     "("
     "Ljava/lang/String;"
     "Lorg/chromium/base/library_loader/Linker$LibInfo;"
     ")"
     "Z",
     reinterpret_cast<void*>(&UseSharedRelro)},
    {"nativeCanUseSharedRelro",
     "("
     ")"
     "Z",
     reinterpret_cast<void*>(&CanUseSharedRelro)},
    {"nativeGetRandomBaseLoadAddress",
     "("
     "J"
     ")"
     "J",
     reinterpret_cast<void*>(&GetRandomBaseLoadAddress)},
    {"nativeGetLibraryFilePathInZipFile",
     "("
     "Ljava/lang/String;"
     ")"
     "Ljava/lang/String;",
     reinterpret_cast<void*>(&GetLibraryFilePathInZipFile)},
    {"nativeCheckLibraryIsMappableInApk",
     "("
     "Ljava/lang/String;"
     "Ljava/lang/String;"
     ")"
     "Z",
     reinterpret_cast<void*>(&CheckLibraryIsMappableInApk)}, };

}  // namespace

// JNI_OnLoad() hook called when the linker library is loaded through
// the regular System.LoadLibrary) API. This shall save the Java VM
// handle and initialize LibInfo fields.
jint JNI_OnLoad(JavaVM* vm, void* reserved) {
  LOG_INFO("%s: Entering", __FUNCTION__);
  // Get new JNIEnv
  JNIEnv* env;
  if (JNI_OK != vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_4)) {
    LOG_ERROR("Could not create JNIEnv");
    return -1;
  }

  // Initialize SDK version info.
  LOG_INFO("%s: Retrieving SDK version info", __FUNCTION__);
  if (!InitSDKVersionInfo(env))
    return -1;

  // Register native methods.
  jclass linker_class;
  if (!InitClassReference(env,
                          "org/chromium/base/library_loader/Linker",
                          &linker_class))
    return -1;

  LOG_INFO("%s: Registering native methods", __FUNCTION__);
  env->RegisterNatives(linker_class,
                       kNativeMethods,
                       sizeof(kNativeMethods) / sizeof(kNativeMethods[0]));

  // Find LibInfo field ids.
  LOG_INFO("%s: Caching field IDs", __FUNCTION__);
  if (!s_lib_info_fields.Init(env)) {
    return -1;
  }

  // Resolve and save the Java side Linker callback class and method.
  LOG_INFO("%s: Resolving callback bindings", __FUNCTION__);
  if (!s_java_callback_bindings.Init(env, linker_class)) {
    return -1;
  }

  // Save JavaVM* handle into context.
  crazy_context_t* context = GetCrazyContext();
  crazy_context_set_java_vm(context, vm, JNI_VERSION_1_4);

  // Register the function that the crazy linker can call to post code
  // for later execution.
  crazy_context_set_callback_poster(context, &PostForLaterExecution, NULL);

  LOG_INFO("%s: Done", __FUNCTION__);
  return JNI_VERSION_1_4;
}

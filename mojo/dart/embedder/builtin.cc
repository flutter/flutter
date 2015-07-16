// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>

#include "base/i18n/icu_util.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/dart/embedder/builtin.h"
#include "mojo/dart/embedder/mojo_io_natives.h"
#include "mojo/dart/embedder/mojo_natives.h"

namespace mojo {
namespace dart {

struct ResourcesEntry {
  const char* path_;
  const char* resource_;
  int length_;
};

extern ResourcesEntry __dart_embedder_patch_resources_[];

// Returns -1 if resource could not be found.
static int FindResource(const char* path, const uint8_t** resource) {
  ResourcesEntry* table = &__dart_embedder_patch_resources_[0];
  for (int i = 0; table[i].path_ != NULL; i++) {
    const ResourcesEntry& entry = table[i];
    if (strcmp(path, entry.path_) == 0) {
      *resource = reinterpret_cast<const uint8_t*>(entry.resource_);
      DCHECK(entry.length_ > 0);
      return entry.length_;
    }
  }
  *resource = NULL;
  return -1;
}

const char* Builtin::mojo_core_patch_resource_names_[] = {
    "/core/natives_patch.dart",
    NULL,
};

const char* Builtin::mojo_io_patch_resource_names_[] = {
  "/io/internet_address_patch.dart",
  "/io/mojo_patch.dart",
  "/io/platform_patch.dart",
  "/io/socket_patch.dart",
  "/io/server_socket_patch.dart",
  NULL,
};

Builtin::builtin_lib_props Builtin::builtin_libraries_[] = {
    /* { url_,
         has_natives_,
         native_symbol_,
         native_resolver_,
         patch_library_url_,
         patch_paths_} */
    {"dart:mojo.builtin",
     true,
     Builtin::NativeSymbol,
     Builtin::NativeLookup,
     nullptr,
     nullptr},
    {"dart:mojo.internal",
     true,
     MojoNativeSymbol,
     MojoNativeLookup,
     "dart:mojo.internal-patch",
     mojo_core_patch_resource_names_},
    {"dart:io",
     true,
     MojoIoNativeSymbol,
     MojoIoNativeLookup,
     "dart:io-patch",
     mojo_io_patch_resource_names_},
};

uint8_t Builtin::snapshot_magic_number[] = {0xf5, 0xf5, 0xdc, 0xdc};

Dart_Handle Builtin::NewError(const char* format, ...) {
  va_list args;
  va_start(args, format);
  intptr_t len = vsnprintf(nullptr, 0, format, args);
  va_end(args);

  char* buffer = reinterpret_cast<char*>(Dart_ScopeAllocate(len + 1));
  va_list args2;
  va_start(args2, format);
  vsnprintf(buffer, (len + 1), format, args2);
  va_end(args2);

  return Dart_NewApiError(buffer);
}

Dart_Handle Builtin::GetStringResource(const char* resource_name) {
  const uint8_t* resource_string;
  int resource_length = FindResource(resource_name, &resource_string);
  if (resource_length > 0) {
    return Dart_NewStringFromUTF8(resource_string, resource_length);
  }
  return NewError("Could not find resource %s", resource_name);
}

// Patch all the specified patch files in the array 'patch_resources' into the
// library specified in 'library'.
void Builtin::LoadPatchFiles(Dart_Handle library,
                             const char* patch_uri,
                             const char** patch_resources) {
  for (intptr_t j = 0; patch_resources[j] != NULL; j++) {
    Dart_Handle patch_src = GetStringResource(patch_resources[j]);
    DART_CHECK_VALID(patch_src);
    // Prepend the patch library URI to form a unique script URI for the patch.
    intptr_t len = snprintf(NULL, 0, "%s%s", patch_uri, patch_resources[j]);
    char* patch_filename = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(patch_filename, len + 1, "%s%s", patch_uri, patch_resources[j]);
    Dart_Handle patch_file_uri = Dart_NewStringFromCString(patch_filename);
    DART_CHECK_VALID(patch_file_uri);
    free(patch_filename);
    DART_CHECK_VALID(Dart_LibraryLoadPatch(library, patch_file_uri, patch_src));
  }
  DART_CHECK_VALID(Dart_FinalizeLoading(false));
}

Dart_Handle Builtin::GetLibrary(BuiltinLibraryId id) {
  static_assert((sizeof(builtin_libraries_) / sizeof(builtin_lib_props)) ==
                kInvalidLibrary, "Unexpected number of builtin libraries");
  DCHECK_GE(id, kBuiltinLibrary);
  DCHECK_LT(id, kInvalidLibrary);
  Dart_Handle url = Dart_NewStringFromCString(builtin_libraries_[id].url_);
  Dart_Handle library = Dart_LookupLibrary(url);
  DART_CHECK_VALID(library);
  return library;
}

void Builtin::PrepareLibrary(BuiltinLibraryId id) {
  Dart_Handle library = GetLibrary(id);
  DCHECK(!Dart_IsError(library));
  if (builtin_libraries_[id].has_natives_) {
    // Setup the native resolver for built in library functions.
    DART_CHECK_VALID(
        Dart_SetNativeResolver(library,
                               builtin_libraries_[id].native_resolver_,
                               builtin_libraries_[id].native_symbol_));
  }
  if (builtin_libraries_[id].patch_url_ != nullptr) {
    DCHECK(builtin_libraries_[id].patch_resources_ != nullptr);
    LoadPatchFiles(library,
                   builtin_libraries_[id].patch_url_,
                   builtin_libraries_[id].patch_resources_);
  }
}

}  // namespace dart
}  // namespace mojo

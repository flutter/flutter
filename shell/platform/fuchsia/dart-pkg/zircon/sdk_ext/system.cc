// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "system.h"

#include <array>

#include <fcntl.h>
#include <lib/fdio/directory.h>
#include <lib/fdio/io.h>
#include <lib/fdio/limits.h>
#include <lib/fdio/namespace.h>
#include <lib/zx/channel.h>
#include <sys/stat.h>
#include <unistd.h>
#include <zircon/process.h>
#include <zircon/processargs.h>

#include "flutter/fml/unique_fd.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_class_library.h"

using tonic::ToDart;

namespace zircon {
namespace dart {

namespace {

constexpr char kGetSizeResult[] = "GetSizeResult";
constexpr char kHandlePairResult[] = "HandlePairResult";
constexpr char kHandleResult[] = "HandleResult";
constexpr char kReadResult[] = "ReadResult";
constexpr char kWriteResult[] = "WriteResult";
constexpr char kFromFileResult[] = "FromFileResult";
constexpr char kMapResult[] = "MapResult";

class ByteDataScope {
 public:
  explicit ByteDataScope(Dart_Handle dart_handle) : dart_handle_(dart_handle) {
    Acquire();
  }

  explicit ByteDataScope(size_t size) {
    dart_handle_ = Dart_NewTypedData(Dart_TypedData_kByteData, size);
    FML_DCHECK(!tonic::LogIfError(dart_handle_));
    Acquire();
    FML_DCHECK(size == size_);
  }

  ~ByteDataScope() {
    if (is_valid_) {
      Release();
    }
  }

  void* data() const { return data_; }
  size_t size() const { return size_; }
  Dart_Handle dart_handle() const { return dart_handle_; }
  bool is_valid() const { return is_valid_; }

  void Release() {
    FML_DCHECK(is_valid_);
    Dart_Handle result = Dart_TypedDataReleaseData(dart_handle_);
    tonic::LogIfError(result);
    is_valid_ = false;
    data_ = nullptr;
    size_ = 0;
  }

 private:
  void Acquire() {
    FML_DCHECK(size_ == 0);
    FML_DCHECK(data_ == nullptr);
    FML_DCHECK(!is_valid_);

    Dart_TypedData_Type type;
    intptr_t size;
    Dart_Handle result =
        Dart_TypedDataAcquireData(dart_handle_, &type, &data_, &size);
    is_valid_ =
        !tonic::LogIfError(result) && type == Dart_TypedData_kByteData && data_;
    if (is_valid_) {
      size_ = size;
    } else {
      size_ = 0;
    }
  }

  Dart_Handle dart_handle_;
  bool is_valid_ = false;
  size_t size_ = 0;
  void* data_ = nullptr;
};

Dart_Handle MakeHandleList(const std::vector<zx_handle_t>& in_handles) {
  tonic::DartClassLibrary& class_library =
      tonic::DartState::Current()->class_library();
  Dart_Handle handle_type = class_library.GetClass("zircon", "Handle");
  Dart_Handle list = Dart_NewListOfTypeFilled(
      handle_type, Handle::CreateInvalid(), in_handles.size());
  if (Dart_IsError(list))
    return list;
  for (size_t i = 0; i < in_handles.size(); i++) {
    Dart_Handle result =
        Dart_ListSetAt(list, i, ToDart(Handle::Create(in_handles[i])));
    if (Dart_IsError(result))
      return result;
  }
  return list;
}

template <class... Args>
Dart_Handle ConstructDartObject(const char* class_name, Args&&... args) {
  tonic::DartClassLibrary& class_library =
      tonic::DartState::Current()->class_library();
  Dart_Handle type =
      Dart_HandleFromPersistent(class_library.GetClass("zircon", class_name));
  FML_DCHECK(!tonic::LogIfError(type));

  const char* cstr;
  Dart_StringToCString(Dart_ToString(type), &cstr);

  std::array<Dart_Handle, sizeof...(Args)> args_array{
      {std::forward<Args>(args)...}};
  Dart_Handle object =
      Dart_New(type, Dart_EmptyString(), sizeof...(Args), args_array.data());
  FML_DCHECK(!tonic::LogIfError(object));
  return object;
}

fdio_ns_t* GetNamespace() {
  // Grab the fdio_ns_t* out of the isolate.
  Dart_Handle zircon_lib = Dart_LookupLibrary(ToDart("dart:zircon"));
  FML_DCHECK(!tonic::LogIfError(zircon_lib));
  Dart_Handle namespace_type =
      Dart_GetType(zircon_lib, ToDart("_Namespace"), 0, nullptr);
  FML_DCHECK(!tonic::LogIfError(namespace_type));
  Dart_Handle namespace_field =
      Dart_GetField(namespace_type, ToDart("_namespace"));
  FML_DCHECK(!tonic::LogIfError(namespace_field));
  uint64_t fdio_ns_ptr;
  Dart_Handle result = Dart_IntegerToUint64(namespace_field, &fdio_ns_ptr);
  FML_DCHECK(!tonic::LogIfError(result));

  return reinterpret_cast<fdio_ns_t*>(fdio_ns_ptr);
}

fml::UniqueFD FdFromPath(std::string path) {
  // Get a VMO for the file.
  fdio_ns_t* ns = reinterpret_cast<fdio_ns_t*>(GetNamespace());
  fml::UniqueFD dirfd(fdio_ns_opendir(ns));
  if (!dirfd.is_valid())
    return fml::UniqueFD();

  const char* c_path = path.c_str();
  if (path.length() > 0 && c_path[0] == '/')
    c_path = &c_path[1];
  return fml::UniqueFD(openat(dirfd.get(), c_path, O_RDONLY));
}

}  // namespace

IMPLEMENT_WRAPPERTYPEINFO(zircon, System);

Dart_Handle System::ChannelCreate(uint32_t options) {
  zx_handle_t out0 = 0, out1 = 0;
  zx_status_t status = zx_channel_create(options, &out0, &out1);
  if (status != ZX_OK) {
    return ConstructDartObject(kHandlePairResult, ToDart(status));
  } else {
    return ConstructDartObject(kHandlePairResult, ToDart(status),
                               ToDart(Handle::Create(out0)),
                               ToDart(Handle::Create(out1)));
  }
}

zx_status_t System::ConnectToService(std::string path,
                                     fml::RefPtr<Handle> channel) {
  return fdio_ns_connect(GetNamespace(), path.c_str(),
                         ZX_FS_RIGHT_READABLE | ZX_FS_RIGHT_WRITABLE,
                         channel->ReleaseHandle());
}

zx::channel System::CloneChannelFromFileDescriptor(int fd) {
  zx::handle handle;
  zx_status_t status = fdio_fd_clone(fd, handle.reset_and_get_address());
  if (status != ZX_OK)
    return zx::channel();

  zx_info_handle_basic_t info = {};
  status =
      handle.get_info(ZX_INFO_HANDLE_BASIC, &info, sizeof(info), NULL, NULL);

  if (status != ZX_OK || info.type != ZX_OBJ_TYPE_CHANNEL)
    return zx::channel();

  return zx::channel(handle.release());
}

Dart_Handle System::ChannelFromFile(std::string path) {
  fml::UniqueFD fd = FdFromPath(path);
  if (!fd.is_valid()) {
    return ConstructDartObject(kHandleResult, ToDart(ZX_ERR_IO));
  }

  // Get channel from fd.
  zx::channel channel = CloneChannelFromFileDescriptor(fd.get());
  if (!channel) {
    return ConstructDartObject(kHandleResult, ToDart(ZX_ERR_IO));
  }

  return ConstructDartObject(kHandleResult, ToDart(ZX_OK),
                             ToDart(Handle::Create(channel.release())));
}

zx_status_t System::ChannelWrite(fml::RefPtr<Handle> channel,
                                 const tonic::DartByteData& data,
                                 std::vector<Handle*> handles) {
  if (!channel || !channel->is_valid()) {
    data.Release();
    return ZX_ERR_BAD_HANDLE;
  }

  std::vector<zx_handle_t> zx_handles;
  for (Handle* handle : handles) {
    zx_handles.push_back(handle->handle());
  }

  zx_status_t status = zx_channel_write(channel->handle(), 0, data.data(),
                                        data.length_in_bytes(),
                                        zx_handles.data(), zx_handles.size());
  // Handles are always consumed.
  for (Handle* handle : handles) {
    handle->ReleaseHandle();
  }

  data.Release();
  return status;
}

Dart_Handle System::ChannelQueryAndRead(fml::RefPtr<Handle> channel) {
  if (!channel || !channel->is_valid()) {
    return ConstructDartObject(kReadResult, ToDart(ZX_ERR_BAD_HANDLE));
  }

  uint32_t actual_bytes = 0;
  uint32_t actual_handles = 0;

  // Query the size of the next message.
  zx_status_t status = zx_channel_read(channel->handle(), 0, nullptr, nullptr,
                                       0, 0, &actual_bytes, &actual_handles);
  if (status != ZX_ERR_BUFFER_TOO_SMALL) {
    // An empty message or an error.
    return ConstructDartObject(kReadResult, ToDart(status));
  }

  // Allocate space for the bytes and handles.
  ByteDataScope bytes(actual_bytes);
  FML_DCHECK(bytes.is_valid());
  std::vector<zx_handle_t> handles(actual_handles);

  // Make the call to actually get the message.
  status = zx_channel_read(channel->handle(), 0, bytes.data(), handles.data(),
                           bytes.size(), handles.size(), &actual_bytes,
                           &actual_handles);
  FML_DCHECK(status != ZX_OK || bytes.size() == actual_bytes);

  bytes.Release();

  if (status == ZX_OK) {
    FML_DCHECK(handles.size() == actual_handles);

    // return a ReadResult object.
    return ConstructDartObject(kReadResult, ToDart(status), bytes.dart_handle(),
                               ToDart(actual_bytes), MakeHandleList(handles));
  } else {
    return ConstructDartObject(kReadResult, ToDart(status));
  }
}

Dart_Handle System::EventpairCreate(uint32_t options) {
  zx_handle_t out0 = 0, out1 = 0;
  zx_status_t status = zx_eventpair_create(0, &out0, &out1);
  if (status != ZX_OK) {
    return ConstructDartObject(kHandlePairResult, ToDart(status));
  } else {
    return ConstructDartObject(kHandlePairResult, ToDart(status),
                               ToDart(Handle::Create(out0)),
                               ToDart(Handle::Create(out1)));
  }
}

Dart_Handle System::SocketCreate(uint32_t options) {
  zx_handle_t out0 = 0, out1 = 0;
  zx_status_t status = zx_socket_create(options, &out0, &out1);
  if (status != ZX_OK) {
    return ConstructDartObject(kHandlePairResult, ToDart(status));
  } else {
    return ConstructDartObject(kHandlePairResult, ToDart(status),
                               ToDart(Handle::Create(out0)),
                               ToDart(Handle::Create(out1)));
  }
}

Dart_Handle System::SocketWrite(fml::RefPtr<Handle> socket,
                                const tonic::DartByteData& data,
                                int options) {
  if (!socket || !socket->is_valid()) {
    data.Release();
    return ConstructDartObject(kWriteResult, ToDart(ZX_ERR_BAD_HANDLE));
  }

  size_t actual;
  zx_status_t status = zx_socket_write(socket->handle(), options, data.data(),
                                       data.length_in_bytes(), &actual);
  data.Release();
  return ConstructDartObject(kWriteResult, ToDart(status), ToDart(actual));
}

Dart_Handle System::SocketRead(fml::RefPtr<Handle> socket, size_t size) {
  if (!socket || !socket->is_valid()) {
    return ConstructDartObject(kReadResult, ToDart(ZX_ERR_BAD_HANDLE));
  }

  ByteDataScope bytes(size);
  size_t actual;
  zx_status_t status =
      zx_socket_read(socket->handle(), 0, bytes.data(), size, &actual);
  bytes.Release();
  if (status == ZX_OK) {
    FML_DCHECK(actual <= size);
    return ConstructDartObject(kReadResult, ToDart(status), bytes.dart_handle(),
                               ToDart(actual));
  }

  return ConstructDartObject(kReadResult, ToDart(status));
}

Dart_Handle System::VmoCreate(uint64_t size, uint32_t options) {
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = zx_vmo_create(size, options, &vmo);
  if (status != ZX_OK) {
    return ConstructDartObject(kHandleResult, ToDart(status));
  } else {
    return ConstructDartObject(kHandleResult, ToDart(status),
                               ToDart(Handle::Create(vmo)));
  }
}

Dart_Handle System::VmoFromFile(std::string path) {
  fml::UniqueFD fd = FdFromPath(path);
  if (!fd.is_valid())
    return ConstructDartObject(kFromFileResult, ToDart(ZX_ERR_IO));

  struct stat stat_struct;
  if (fstat(fd.get(), &stat_struct) == -1)
    return ConstructDartObject(kFromFileResult, ToDart(ZX_ERR_IO));
  zx_handle_t vmo = ZX_HANDLE_INVALID;
  zx_status_t status = fdio_get_vmo_clone(fd.get(), &vmo);
  if (status != ZX_OK)
    return ConstructDartObject(kFromFileResult, ToDart(status));

  return ConstructDartObject(kFromFileResult, ToDart(status),
                             ToDart(Handle::Create(vmo)),
                             ToDart(stat_struct.st_size));
}

Dart_Handle System::VmoGetSize(fml::RefPtr<Handle> vmo) {
  if (!vmo || !vmo->is_valid()) {
    return ConstructDartObject(kGetSizeResult, ToDart(ZX_ERR_BAD_HANDLE));
  }

  uint64_t size;
  zx_status_t status = zx_vmo_get_size(vmo->handle(), &size);

  return ConstructDartObject(kGetSizeResult, ToDart(status), ToDart(size));
}

zx_status_t System::VmoSetSize(fml::RefPtr<Handle> vmo, uint64_t size) {
  if (!vmo || !vmo->is_valid()) {
    return ZX_ERR_BAD_HANDLE;
  }
  return zx_vmo_set_size(vmo->handle(), size);
}

zx_status_t System::VmoWrite(fml::RefPtr<Handle> vmo,
                             uint64_t offset,
                             const tonic::DartByteData& data) {
  if (!vmo || !vmo->is_valid()) {
    data.Release();
    return ZX_ERR_BAD_HANDLE;
  }

  zx_status_t status =
      zx_vmo_write(vmo->handle(), data.data(), offset, data.length_in_bytes());

  data.Release();
  return status;
}

Dart_Handle System::VmoRead(fml::RefPtr<Handle> vmo,
                            uint64_t offset,
                            size_t size) {
  if (!vmo || !vmo->is_valid()) {
    return ConstructDartObject(kReadResult, ToDart(ZX_ERR_BAD_HANDLE));
  }

  // TODO: constrain size?
  ByteDataScope bytes(size);
  zx_status_t status = zx_vmo_read(vmo->handle(), bytes.data(), offset, size);
  bytes.Release();
  if (status == ZX_OK) {
    return ConstructDartObject(kReadResult, ToDart(status), bytes.dart_handle(),
                               ToDart(size));
  }
  return ConstructDartObject(kReadResult, ToDart(status));
}

struct SizedRegion {
  SizedRegion(void* r, size_t s) : region(r), size(s) {}
  void* region;
  size_t size;
};

void System::VmoMapFinalizer(void* isolate_callback_data, void* peer) {
  SizedRegion* r = reinterpret_cast<SizedRegion*>(peer);
  zx_vmar_unmap(zx_vmar_root_self(), reinterpret_cast<uintptr_t>(r->region),
                r->size);
  delete r;
}

Dart_Handle System::VmoMap(fml::RefPtr<Handle> vmo) {
  if (!vmo || !vmo->is_valid())
    return ConstructDartObject(kMapResult, ToDart(ZX_ERR_BAD_HANDLE));

  uint64_t size;
  zx_status_t status = zx_vmo_get_size(vmo->handle(), &size);
  if (status != ZX_OK)
    return ConstructDartObject(kMapResult, ToDart(status));

  uintptr_t mapped_addr;
  status = zx_vmar_map(zx_vmar_root_self(), ZX_VM_PERM_READ, 0, vmo->handle(),
                       0, size, &mapped_addr);
  if (status != ZX_OK)
    return ConstructDartObject(kMapResult, ToDart(status));

  void* data = reinterpret_cast<void*>(mapped_addr);
  Dart_Handle object = Dart_NewExternalTypedData(Dart_TypedData_kUint8, data,
                                                 static_cast<intptr_t>(size));
  FML_DCHECK(!tonic::LogIfError(object));

  SizedRegion* r = new SizedRegion(data, size);
  Dart_NewFinalizableHandle(object, reinterpret_cast<void*>(r),
                            static_cast<intptr_t>(size) + sizeof(*r),
                            System::VmoMapFinalizer);

  return ConstructDartObject(kMapResult, ToDart(ZX_OK), object);
}

uint64_t System::ClockGet(uint32_t clock_id) {
  zx_time_t result = 0;
  zx_clock_get(clock_id, &result);
  return result;
}

// clang-format: off

#define FOR_EACH_STATIC_BINDING(V) \
  V(System, ChannelCreate)         \
  V(System, ChannelFromFile)       \
  V(System, ChannelWrite)          \
  V(System, ChannelQueryAndRead)   \
  V(System, EventpairCreate)       \
  V(System, ConnectToService)      \
  V(System, SocketCreate)          \
  V(System, SocketWrite)           \
  V(System, SocketRead)            \
  V(System, VmoCreate)             \
  V(System, VmoFromFile)           \
  V(System, VmoGetSize)            \
  V(System, VmoSetSize)            \
  V(System, VmoRead)               \
  V(System, VmoWrite)              \
  V(System, VmoMap)                \
  V(System, ClockGet)

// clang-format: on

// Tonic is missing a comma.
#define DART_REGISTER_NATIVE_STATIC_(CLASS, METHOD) \
  DART_REGISTER_NATIVE_STATIC(CLASS, METHOD),

FOR_EACH_STATIC_BINDING(DART_NATIVE_CALLBACK_STATIC)

void System::RegisterNatives(tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_STATIC_BINDING(DART_REGISTER_NATIVE_STATIC_)});
}

}  // namespace dart
}  // namespace zircon

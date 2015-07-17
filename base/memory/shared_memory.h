// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MEMORY_SHARED_MEMORY_H_
#define BASE_MEMORY_SHARED_MEMORY_H_

#include "build/build_config.h"

#include <string>

#if defined(OS_POSIX)
#include <stdio.h>
#include <sys/types.h>
#include <semaphore.h>
#endif

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/memory/shared_memory_handle.h"
#include "base/process/process_handle.h"

#if defined(OS_POSIX)
#include "base/file_descriptor_posix.h"
#include "base/files/file_util.h"
#include "base/files/scoped_file.h"
#endif

namespace base {

class FilePath;

// Options for creating a shared memory object.
struct SharedMemoryCreateOptions {
  SharedMemoryCreateOptions()
      : name_deprecated(NULL),
        size(0),
        open_existing_deprecated(false),
        executable(false),
        share_read_only(false) {}

  // DEPRECATED (crbug.com/345734):
  // If NULL, the object is anonymous.  This pointer is owned by the caller
  // and must live through the call to Create().
  const std::string* name_deprecated;

  // Size of the shared memory object to be created.
  // When opening an existing object, this has no effect.
  size_t size;

  // DEPRECATED (crbug.com/345734):
  // If true, and the shared memory already exists, Create() will open the
  // existing shared memory and ignore the size parameter.  If false,
  // shared memory must not exist.  This flag is meaningless unless
  // name_deprecated is non-NULL.
  bool open_existing_deprecated;

  // If true, mappings might need to be made executable later.
  bool executable;

  // If true, the file can be shared read-only to a process.
  bool share_read_only;
};

// Platform abstraction for shared memory.  Provides a C++ wrapper
// around the OS primitive for a memory mapped file.
class BASE_EXPORT SharedMemory {
 public:
  SharedMemory();

#if defined(OS_WIN)
  // Similar to the default constructor, except that this allows for
  // calling LockDeprecated() to acquire the named mutex before either Create or
  // Open are called on Windows.
  explicit SharedMemory(const std::wstring& name);
#endif

  // Create a new SharedMemory object from an existing, open
  // shared memory file.
  //
  // WARNING: This does not reduce the OS-level permissions on the handle; it
  // only affects how the SharedMemory will be mmapped.  Use
  // ShareReadOnlyToProcess to drop permissions.  TODO(jln,jyasskin): DCHECK
  // that |read_only| matches the permissions of the handle.
  SharedMemory(const SharedMemoryHandle& handle, bool read_only);

  // Create a new SharedMemory object from an existing, open
  // shared memory file that was created by a remote process and not shared
  // to the current process.
  SharedMemory(const SharedMemoryHandle& handle,
               bool read_only,
               ProcessHandle process);

  // Closes any open files.
  ~SharedMemory();

  // Return true iff the given handle is valid (i.e. not the distingished
  // invalid value; NULL for a HANDLE and -1 for a file descriptor)
  static bool IsHandleValid(const SharedMemoryHandle& handle);

  // Returns invalid handle (see comment above for exact definition).
  static SharedMemoryHandle NULLHandle();

  // Closes a shared memory handle.
  static void CloseHandle(const SharedMemoryHandle& handle);

  // Returns the maximum number of handles that can be open at once per process.
  static size_t GetHandleLimit();

  // Duplicates The underlying OS primitive. Returns NULLHandle() on failure.
  // The caller is responsible for destroying the duplicated OS primitive.
  static SharedMemoryHandle DuplicateHandle(const SharedMemoryHandle& handle);

#if defined(OS_POSIX)
  // This method requires that the SharedMemoryHandle is backed by a POSIX fd.
  static int GetFdFromSharedMemoryHandle(const SharedMemoryHandle& handle);
#endif

#if defined(OS_POSIX) && !defined(OS_ANDROID)
  // Returns the size of the shared memory region referred to by |handle|.
  // Returns '-1' on a failure to determine the size.
  static int GetSizeFromSharedMemoryHandle(const SharedMemoryHandle& handle);
#endif  // defined(OS_POSIX) && !defined(OS_ANDROID)

  // Creates a shared memory object as described by the options struct.
  // Returns true on success and false on failure.
  bool Create(const SharedMemoryCreateOptions& options);

  // Creates and maps an anonymous shared memory segment of size size.
  // Returns true on success and false on failure.
  bool CreateAndMapAnonymous(size_t size);

  // Creates an anonymous shared memory segment of size size.
  // Returns true on success and false on failure.
  bool CreateAnonymous(size_t size) {
    SharedMemoryCreateOptions options;
    options.size = size;
    return Create(options);
  }

  // DEPRECATED (crbug.com/345734):
  // Creates or opens a shared memory segment based on a name.
  // If open_existing is true, and the shared memory already exists,
  // opens the existing shared memory and ignores the size parameter.
  // If open_existing is false, shared memory must not exist.
  // size is the size of the block to be created.
  // Returns true on success, false on failure.
  bool CreateNamedDeprecated(
      const std::string& name, bool open_existing, size_t size) {
    SharedMemoryCreateOptions options;
    options.name_deprecated = &name;
    options.open_existing_deprecated = open_existing;
    options.size = size;
    return Create(options);
  }

  // Deletes resources associated with a shared memory segment based on name.
  // Not all platforms require this call.
  bool Delete(const std::string& name);

  // Opens a shared memory segment based on a name.
  // If read_only is true, opens for read-only access.
  // Returns true on success, false on failure.
  bool Open(const std::string& name, bool read_only);

  // Maps the shared memory into the caller's address space.
  // Returns true on success, false otherwise.  The memory address
  // is accessed via the memory() accessor.  The mapped address is guaranteed to
  // have an alignment of at least MAP_MINIMUM_ALIGNMENT. This method will fail
  // if this object is currently mapped.
  bool Map(size_t bytes) {
    return MapAt(0, bytes);
  }

  // Same as above, but with |offset| to specify from begining of the shared
  // memory block to map.
  // |offset| must be alignent to value of |SysInfo::VMAllocationGranularity()|.
  bool MapAt(off_t offset, size_t bytes);
  enum { MAP_MINIMUM_ALIGNMENT = 32 };

  // Unmaps the shared memory from the caller's address space.
  // Returns true if successful; returns false on error or if the
  // memory is not mapped.
  bool Unmap();

  // The size requested when the map is first created.
  size_t requested_size() const { return requested_size_; }

  // The actual size of the mapped memory (may be larger than requested).
  size_t mapped_size() const { return mapped_size_; }

  // Gets a pointer to the opened memory space if it has been
  // Mapped via Map().  Returns NULL if it is not mapped.
  void *memory() const { return memory_; }

  // Returns the underlying OS handle for this segment.
  // Use of this handle for anything other than an opaque
  // identifier is not portable.
  SharedMemoryHandle handle() const;

  // Closes the open shared memory segment. The memory will remain mapped if
  // it was previously mapped.
  // It is safe to call Close repeatedly.
  void Close();

  // Shares the shared memory to another process.  Attempts to create a
  // platform-specific new_handle which can be used in a remote process to read
  // the shared memory file.  new_handle is an output parameter to receive the
  // handle for use in the remote process.
  //
  // |*this| must have been initialized using one of the Create*() or Open()
  // methods with share_read_only=true. If it was constructed from a
  // SharedMemoryHandle, this call will CHECK-fail.
  //
  // Returns true on success, false otherwise.
  bool ShareReadOnlyToProcess(ProcessHandle process,
                              SharedMemoryHandle* new_handle) {
    return ShareToProcessCommon(process, new_handle, false, SHARE_READONLY);
  }

  // Logically equivalent to:
  //   bool ok = ShareReadOnlyToProcess(process, new_handle);
  //   Close();
  //   return ok;
  // Note that the memory is unmapped by calling this method, regardless of the
  // return value.
  bool GiveReadOnlyToProcess(ProcessHandle process,
                             SharedMemoryHandle* new_handle) {
    return ShareToProcessCommon(process, new_handle, true, SHARE_READONLY);
  }

  // Shares the shared memory to another process.  Attempts
  // to create a platform-specific new_handle which can be
  // used in a remote process to access the shared memory
  // file.  new_handle is an output parameter to receive
  // the handle for use in the remote process.
  // Returns true on success, false otherwise.
  bool ShareToProcess(ProcessHandle process,
                      SharedMemoryHandle* new_handle) {
    return ShareToProcessCommon(process, new_handle, false, SHARE_CURRENT_MODE);
  }

  // Logically equivalent to:
  //   bool ok = ShareToProcess(process, new_handle);
  //   Close();
  //   return ok;
  // Note that the memory is unmapped by calling this method, regardless of the
  // return value.
  bool GiveToProcess(ProcessHandle process,
                     SharedMemoryHandle* new_handle) {
    return ShareToProcessCommon(process, new_handle, true, SHARE_CURRENT_MODE);
  }

 private:
#if defined(OS_POSIX) && !defined(OS_NACL) && !defined(OS_ANDROID)
  bool PrepareMapFile(ScopedFILE fp, ScopedFD readonly);
  bool FilePathForMemoryName(const std::string& mem_name, FilePath* path);
#endif  // defined(OS_POSIX) && !defined(OS_NACL) && !defined(OS_ANDROID)
  enum ShareMode {
    SHARE_READONLY,
    SHARE_CURRENT_MODE,
  };
  bool ShareToProcessCommon(ProcessHandle process,
                            SharedMemoryHandle* new_handle,
                            bool close_self,
                            ShareMode);

#if defined(OS_WIN)
  std::wstring       name_;
  HANDLE             mapped_file_;
#elif defined(OS_POSIX)
  int                mapped_file_;
  int                readonly_mapped_file_;
#endif
  size_t             mapped_size_;
  void*              memory_;
  bool               read_only_;
  size_t             requested_size_;

  DISALLOW_COPY_AND_ASSIGN(SharedMemory);
};
}  // namespace base

#endif  // BASE_MEMORY_SHARED_MEMORY_H_

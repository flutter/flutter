// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_file_util.h"

#include <windows.h>
#include <aclapi.h>
#include <shlwapi.h>

#include <vector>

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/string_split.h"
#include "base/threading/platform_thread.h"
#include "base/win/scoped_handle.h"

namespace base {

static const ptrdiff_t kOneMB = 1024 * 1024;

namespace {

struct PermissionInfo {
  PSECURITY_DESCRIPTOR security_descriptor;
  ACL dacl;
};

// Deny |permission| on the file |path|, for the current user.
bool DenyFilePermission(const FilePath& path, DWORD permission) {
  PACL old_dacl;
  PSECURITY_DESCRIPTOR security_descriptor;
  if (GetNamedSecurityInfo(const_cast<wchar_t*>(path.value().c_str()),
                           SE_FILE_OBJECT,
                           DACL_SECURITY_INFORMATION, NULL, NULL, &old_dacl,
                           NULL, &security_descriptor) != ERROR_SUCCESS) {
    return false;
  }

  EXPLICIT_ACCESS change;
  change.grfAccessPermissions = permission;
  change.grfAccessMode = DENY_ACCESS;
  change.grfInheritance = 0;
  change.Trustee.pMultipleTrustee = NULL;
  change.Trustee.MultipleTrusteeOperation = NO_MULTIPLE_TRUSTEE;
  change.Trustee.TrusteeForm = TRUSTEE_IS_NAME;
  change.Trustee.TrusteeType = TRUSTEE_IS_USER;
  change.Trustee.ptstrName = const_cast<wchar_t*>(L"CURRENT_USER");

  PACL new_dacl;
  if (SetEntriesInAcl(1, &change, old_dacl, &new_dacl) != ERROR_SUCCESS) {
    LocalFree(security_descriptor);
    return false;
  }

  DWORD rc = SetNamedSecurityInfo(const_cast<wchar_t*>(path.value().c_str()),
                                  SE_FILE_OBJECT, DACL_SECURITY_INFORMATION,
                                  NULL, NULL, new_dacl, NULL);
  LocalFree(security_descriptor);
  LocalFree(new_dacl);

  return rc == ERROR_SUCCESS;
}

// Gets a blob indicating the permission information for |path|.
// |length| is the length of the blob.  Zero on failure.
// Returns the blob pointer, or NULL on failure.
void* GetPermissionInfo(const FilePath& path, size_t* length) {
  DCHECK(length != NULL);
  *length = 0;
  PACL dacl = NULL;
  PSECURITY_DESCRIPTOR security_descriptor;
  if (GetNamedSecurityInfo(const_cast<wchar_t*>(path.value().c_str()),
                           SE_FILE_OBJECT,
                           DACL_SECURITY_INFORMATION, NULL, NULL, &dacl,
                           NULL, &security_descriptor) != ERROR_SUCCESS) {
    return NULL;
  }
  DCHECK(dacl != NULL);

  *length = sizeof(PSECURITY_DESCRIPTOR) + dacl->AclSize;
  PermissionInfo* info = reinterpret_cast<PermissionInfo*>(new char[*length]);
  info->security_descriptor = security_descriptor;
  memcpy(&info->dacl, dacl, dacl->AclSize);

  return info;
}

// Restores the permission information for |path|, given the blob retrieved
// using |GetPermissionInfo()|.
// |info| is the pointer to the blob.
// |length| is the length of the blob.
// Either |info| or |length| may be NULL/0, in which case nothing happens.
bool RestorePermissionInfo(const FilePath& path, void* info, size_t length) {
  if (!info || !length)
    return false;

  PermissionInfo* perm = reinterpret_cast<PermissionInfo*>(info);

  DWORD rc = SetNamedSecurityInfo(const_cast<wchar_t*>(path.value().c_str()),
                                  SE_FILE_OBJECT, DACL_SECURITY_INFORMATION,
                                  NULL, NULL, &perm->dacl, NULL);
  LocalFree(perm->security_descriptor);

  char* char_array = reinterpret_cast<char*>(info);
  delete [] char_array;

  return rc == ERROR_SUCCESS;
}

}  // namespace

bool DieFileDie(const FilePath& file, bool recurse) {
  // It turns out that to not induce flakiness a long timeout is needed.
  const int kIterations = 25;
  const TimeDelta kTimeout = TimeDelta::FromSeconds(10) / kIterations;

  if (!PathExists(file))
    return true;

  // Sometimes Delete fails, so try a few more times. Divide the timeout
  // into short chunks, so that if a try succeeds, we won't delay the test
  // for too long.
  for (int i = 0; i < kIterations; ++i) {
    if (DeleteFile(file, recurse))
      return true;
    PlatformThread::Sleep(kTimeout);
  }
  return false;
}

bool EvictFileFromSystemCache(const FilePath& file) {
  // Request exclusive access to the file and overwrite it with no buffering.
  base::win::ScopedHandle file_handle(
      CreateFile(file.value().c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL,
                 OPEN_EXISTING, FILE_FLAG_NO_BUFFERING, NULL));
  if (!file_handle.IsValid())
    return false;

  // Get some attributes to restore later.
  BY_HANDLE_FILE_INFORMATION bhi = {0};
  CHECK(::GetFileInformationByHandle(file_handle.Get(), &bhi));

  // Execute in chunks. It could be optimized. We want to do few of these since
  // these operations will be slow without the cache.

  // Allocate a buffer for the reads and the writes.
  char* buffer = reinterpret_cast<char*>(VirtualAlloc(NULL,
                                                      kOneMB,
                                                      MEM_COMMIT | MEM_RESERVE,
                                                      PAGE_READWRITE));

  // If the file size isn't a multiple of kOneMB, we'll need special
  // processing.
  bool file_is_aligned = true;
  int total_bytes = 0;
  DWORD bytes_read, bytes_written;
  for (;;) {
    bytes_read = 0;
    ::ReadFile(file_handle.Get(), buffer, kOneMB, &bytes_read, NULL);
    if (bytes_read == 0)
      break;

    if (bytes_read < kOneMB) {
      // Zero out the remaining part of the buffer.
      // WriteFile will fail if we provide a buffer size that isn't a
      // sector multiple, so we'll have to write the entire buffer with
      // padded zeros and then use SetEndOfFile to truncate the file.
      ZeroMemory(buffer + bytes_read, kOneMB - bytes_read);
      file_is_aligned = false;
    }

    // Move back to the position we just read from.
    // Note that SetFilePointer will also fail if total_bytes isn't sector
    // aligned, but that shouldn't happen here.
    DCHECK_EQ(total_bytes % kOneMB, 0);
    SetFilePointer(file_handle.Get(), total_bytes, NULL, FILE_BEGIN);
    if (!::WriteFile(file_handle.Get(), buffer, kOneMB, &bytes_written, NULL) ||
        bytes_written != kOneMB) {
      BOOL freed = VirtualFree(buffer, 0, MEM_RELEASE);
      DCHECK(freed);
      NOTREACHED();
      return false;
    }

    total_bytes += bytes_read;

    // If this is false, then we just processed the last portion of the file.
    if (!file_is_aligned)
      break;
  }

  BOOL freed = VirtualFree(buffer, 0, MEM_RELEASE);
  DCHECK(freed);

  if (!file_is_aligned) {
    // The size of the file isn't a multiple of 1 MB, so we'll have
    // to open the file again, this time without the FILE_FLAG_NO_BUFFERING
    // flag and use SetEndOfFile to mark EOF.
    file_handle.Set(NULL);
    file_handle.Set(CreateFile(file.value().c_str(), GENERIC_WRITE, 0, NULL,
                               OPEN_EXISTING, 0, NULL));
    CHECK_NE(SetFilePointer(file_handle.Get(), total_bytes, NULL, FILE_BEGIN),
             INVALID_SET_FILE_POINTER);
    CHECK(::SetEndOfFile(file_handle.Get()));
  }

  // Restore the file attributes.
  CHECK(::SetFileTime(file_handle.Get(), &bhi.ftCreationTime,
                      &bhi.ftLastAccessTime, &bhi.ftLastWriteTime));

  return true;
}

// Checks if the volume supports Alternate Data Streams. This is required for
// the Zone Identifier implementation.
bool VolumeSupportsADS(const FilePath& path) {
  wchar_t drive[MAX_PATH] = {0};
  wcscpy_s(drive, MAX_PATH, path.value().c_str());

  if (!PathStripToRootW(drive))
    return false;

  DWORD fs_flags = 0;
  if (!GetVolumeInformationW(drive, NULL, 0, 0, NULL, &fs_flags, NULL, 0))
    return false;

  if (fs_flags & FILE_NAMED_STREAMS)
    return true;

  return false;
}

// Return whether the ZoneIdentifier is correctly set to "Internet" (3)
// Only returns a valid result when called from same process as the
// one that (was supposed to have) set the zone identifier.
bool HasInternetZoneIdentifier(const FilePath& full_path) {
  FilePath zone_path(full_path.value() + L":Zone.Identifier");
  std::string zone_path_contents;
  if (!ReadFileToString(zone_path, &zone_path_contents))
    return false;

  std::vector<std::string> lines;
  // This call also trims whitespaces, including carriage-returns (\r).
  SplitString(zone_path_contents, '\n', &lines);

  switch (lines.size()) {
    case 3:
      // optional empty line at end of file:
      if (!lines[2].empty())
        return false;
      // fall through:
    case 2:
      return lines[0] == "[ZoneTransfer]" && lines[1] == "ZoneId=3";
    default:
      return false;
  }
}

bool MakeFileUnreadable(const FilePath& path) {
  return DenyFilePermission(path, GENERIC_READ);
}

bool MakeFileUnwritable(const FilePath& path) {
  return DenyFilePermission(path, GENERIC_WRITE);
}

FilePermissionRestorer::FilePermissionRestorer(const FilePath& path)
    : path_(path), info_(NULL), length_(0) {
  info_ = GetPermissionInfo(path_, &length_);
  DCHECK(info_ != NULL);
  DCHECK_NE(0u, length_);
}

FilePermissionRestorer::~FilePermissionRestorer() {
  if (!RestorePermissionInfo(path_, info_, length_))
    NOTREACHED();
}

}  // namespace base

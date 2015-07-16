// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/file_util.h"

#include <errno.h>
#include <linux/magic.h>
#include <sys/vfs.h>

#include "base/files/file_path.h"

namespace base {

bool GetFileSystemType(const FilePath& path, FileSystemType* type) {
  struct statfs statfs_buf;
  if (statfs(path.value().c_str(), &statfs_buf) < 0) {
    if (errno == ENOENT)
      return false;
    *type = FILE_SYSTEM_UNKNOWN;
    return true;
  }

  // Not all possible |statfs_buf.f_type| values are in linux/magic.h.
  // Missing values are copied from the statfs man page.
  switch (statfs_buf.f_type) {
    case 0:
      *type = FILE_SYSTEM_0;
      break;
    case EXT2_SUPER_MAGIC:  // Also ext3 and ext4
    case MSDOS_SUPER_MAGIC:
    case REISERFS_SUPER_MAGIC:
    case BTRFS_SUPER_MAGIC:
    case 0x5346544E:  // NTFS
    case 0x58465342:  // XFS
    case 0x3153464A:  // JFS
      *type = FILE_SYSTEM_ORDINARY;
      break;
    case NFS_SUPER_MAGIC:
      *type = FILE_SYSTEM_NFS;
      break;
    case SMB_SUPER_MAGIC:
    case 0xFF534D42:  // CIFS
      *type = FILE_SYSTEM_SMB;
      break;
    case CODA_SUPER_MAGIC:
      *type = FILE_SYSTEM_CODA;
      break;
    case HUGETLBFS_MAGIC:
    case RAMFS_MAGIC:
    case TMPFS_MAGIC:
      *type = FILE_SYSTEM_MEMORY;
      break;
    case CGROUP_SUPER_MAGIC:
      *type = FILE_SYSTEM_CGROUP;
      break;
    default:
      *type = FILE_SYSTEM_OTHER;
  }
  return true;
}

}  // namespace base

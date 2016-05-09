// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_SINGLETONS_H_
#define SERVICES_FILES_C_LIB_SINGLETONS_H_

#include "files/interfaces/directory.mojom.h"
#include "mojo/public/cpp/bindings/interface_handle.h"

namespace mojio {

class DirectoryWrapper;
class ErrnoImpl;
class FDTable;

namespace singletons {

// Gets the singleton |ErrnoImpl| (creating it if necessary), which gets/sets
// the "real" errno.
ErrnoImpl* GetErrnoImpl();
// Resets (destroys) the singleton |ErrnoImpl|. Warning: Do not call this unless
// things relying on the singleton |ErrnoImpl| have been reset first.
void ResetErrnoImpl();

// Gets the singleton |FDTable| (creating it if necessary, using
// MOJIO_CONFIG_MAX_NUM_FDS and the singleton |ErrnoImpl|).
FDTable* GetFDTable();
// Resets (destroys) the singleton |FDTable|.
void ResetFDTable();

// Explicitly set the singleton current working directory to |directory| (which
// should be valid). (The singleton |DirectoryWrapper| will be reset if
// necessary.) This uses the singleton |ErrnoImpl|.
void SetCurrentWorkingDirectory(
    mojo::InterfaceHandle<mojo::files::Directory> directory);
// Gets the current working directory (i.e., the singleton |DirectoryWrapper|).
// WARNING!!! This returns null if it was not previously set (see above) or has
// been reset, in which case it will also use the singleton |ErrnoImpl| (to set
// errno).
DirectoryWrapper* GetCurrentWorkingDirectory();
// Resets (destroys) the singleton |DirectoryWrapper|.
void ResetCurrentWorkingDirectory();

}  // namespace singletons
}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_SINGLETONS_H_

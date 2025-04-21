// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_COMPILER_FILESYSTEM_H_
#define FLUTTER_IMPELLER_COMPILER_FILESYSTEM_H_

#include "flutter/fml/mapping.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      Write the specified mapping to the filesystem.
///
///             Conceptually, this is identical to `fml::WriteAtomically`.
///             Except, it will first check if a file exists at the given path
///             and its contents are identical to the ones about to be written.
///             If both conditions hold, this function becomes a no-op.
///
///             The side-effect of skipping the update is that the modification
///             timestamp of the file will not be affected. Build systems such
///             as ninja and GN (using the `restat` argument) that check the
///             timestamp for modification will then be able to cull edges
///             leading to faster incremental builds.
///
/// @param[in]  base_directory  The base directory
/// @param[in]  file_name       The file name
/// @param[in]  data            The data
///
/// @return     If the file at the specified location contains the data
///             provided. This is regardless of whether there was already a file
///             with the specified contents at that location.
///
bool WriteAtomicallyIfChanged(const fml::UniqueFD& base_directory,
                              const char* file_name,
                              const fml::Mapping& data);

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_COMPILER_FILESYSTEM_H_

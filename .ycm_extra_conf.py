# Copyright 2016 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import ycm_core


compile_commands_dir = os.path.normpath(os.path.dirname(os.path.abspath(__file__)) + '/out')


if os.path.exists(compile_commands_dir):
  compilation_db = ycm_core.CompilationDatabase(compile_commands_dir)
else:
  compilation_db = None


path_flags = [
  '--sysroot=',
  '-I',
  '-iquote',
  '-isystem',
]

source_extensions = [
  ".cc",
  ".mm",
  ".cpp",
  ".m",
  ".c",
]

def MakeFlagAbsolute(working_dir, flag):
  # Check if its a flag that contains a path. (an ite, in the path_flags)
  for path_flag in path_flags:
    if flag.startswith(path_flag):
      path_component = flag[len(path_flag):]
      return path_flag + os.path.join(working_dir, path_component)

  # Check if its a regular flag that does not contain a path. (defines, warnings, etc..)
  if flag.startswith('-'):
    return flag

  # The file path is directly specified. (compiler, input, output, etc..)
  return os.path.join(working_dir, flag)


def MakeFlagsAbsolute(working_dir, flags):
  if not working_dir:
    return list(flags)

  updated_flags = []

  for flag in flags:
    updated_flags.append(MakeFlagAbsolute(working_dir, flag))

  return updated_flags


def FlagsForNamedFile(filename):
  info = compilation_db.GetCompilationInfoForFile(filename)

  if not info:
    return None

  extension = filename.rsplit(".", 1)[1]

  if extension == "mm":
    info.compiler_flags_.append("-x objc++")

  if extension == "m":
    info.compiler_flags_.append("-x objc")

  return MakeFlagsAbsolute(info.compiler_working_dir_,
                           info.compiler_flags_)


def FlagsForFile(filename, **kwargs):
  if not compilation_db:
    return None

  flags = FlagsForNamedFile(filename)

  if not flags:
    # The file could be a header, look for the corresponding source file as its
    # flags "should" be close enough.
    for source_extension in source_extensions:
      flags = FlagsForNamedFile(filename.rsplit( ".", 1 )[0] + source_extension)
      
      if flags:
        break

  return { 'flags' : flags }

" Copyright (c) 2012 The Chromium Authors. All rights reserved.
" Use of this source code is governed by a BSD-style license that can be
" found in the LICENSE file.
"
" Adds a "Compile this file" function, using ninja. On Mac, binds Cmd-k to
" this command. On Windows, Ctrl-F7 (which is the same as the VS default).
" On Linux, <Leader>o, which is \o by default ("o"=creates .o files)
"
" Adds a "Build this target" function, using ninja. This is not bound
" to any key by default, but can be used via the :CrBuild command.
" It builds 'chrome' by default, but :CrBuild target1 target2 etc works as well.
"
" Requires that gyp has already generated build.ninja files, and that ninja is
" in your path (which it is automatically if depot_tools is in your path).
"
" Add the following to your .vimrc file:
"     so /path/to/src/tools/vim/ninja-build.vim

python << endpython
import os
import vim


def path_to_current_buffer():
  """Returns the absolute path of the current buffer."""
  return vim.current.buffer.name


def path_to_source_root():
  """Returns the absolute path to the chromium source root."""
  candidate = os.path.dirname(path_to_current_buffer())
  # This is a list of files that need to identify the src directory. The shorter
  # it is, the more likely it's wrong (checking for just "build/common.gypi"
  # would find "src/v8" for files below "src/v8", as "src/v8/build/common.gypi"
  # exists). The longer it is, the more likely it is to break when we rename
  # directories.
  fingerprints = ['chrome', 'net', 'v8', 'build', 'skia']
  while candidate and not all(
      [os.path.isdir(os.path.join(candidate, fp)) for fp in fingerprints]):
    candidate = os.path.dirname(candidate)
  return candidate


def path_to_build_dir(configuration):
  """Returns <chrome_root>/<output_dir>/(Release|Debug)."""

  chrome_root = path_to_source_root()
  sys.path.append(os.path.join(chrome_root, 'tools', 'vim'))
  from ninja_output import GetNinjaOutputDirectory
  return GetNinjaOutputDirectory(chrome_root, configuration)

def compute_ninja_command_for_current_buffer(configuration=None):
  """Returns the shell command to compile the file in the current buffer."""
  build_dir = path_to_build_dir(configuration)

  # ninja needs filepaths for the ^ syntax to be relative to the
  # build directory.
  file_to_build = path_to_current_buffer()
  file_to_build = os.path.relpath(file_to_build, build_dir)

  build_cmd = ' '.join(['ninja', '-C', build_dir, file_to_build + '^'])
  if sys.platform == 'win32':
    # Escape \ for Vim, and ^ for both Vim and shell.
    build_cmd = build_cmd.replace('\\', '\\\\').replace('^', '^^^^')
  vim.command('return "%s"' % build_cmd)


def compute_ninja_command_for_targets(targets='', configuration=None):
  build_cmd = ' '.join(['ninja', '-C', path_to_build_dir(configuration),
                        targets])
  vim.command('return "%s"' % build_cmd)
endpython

fun! s:MakeWithCustomCommand(build_cmd)
  let l:oldmakepgr = &makeprg
  let &makeprg=a:build_cmd
  silent make | cwindow
  if !has('gui_running')
    redraw!
  endif
  let &makeprg = l:oldmakepgr
endfun

fun! s:NinjaCommandForCurrentBuffer()
  python compute_ninja_command_for_current_buffer()
endfun

fun! s:NinjaCommandForTargets(targets)
  python compute_ninja_command_for_targets(vim.eval('a:targets'))
endfun

fun! CrCompileFile()
  call s:MakeWithCustomCommand(s:NinjaCommandForCurrentBuffer())
endfun

fun! CrBuild(...)
  let l:targets = a:0 > 0 ? join(a:000, ' ') : ''
  if (l:targets !~ '\i')
    let l:targets = 'chrome'
  endif
  call s:MakeWithCustomCommand(s:NinjaCommandForTargets(l:targets))
endfun

command! CrCompileFile call CrCompileFile()
command! -nargs=* CrBuild call CrBuild(<q-args>)

if has('mac')
  map <D-k> :CrCompileFile<cr>
  imap <D-k> <esc>:CrCompileFile<cr>
elseif has('win32')
  map <C-F7> :CrCompileFile<cr>
  imap <C-F7> <esc>:CrCompileFile<cr>
elseif has('unix')
  map <Leader>o :CrCompileFile<cr>
endif

" Copyright (c) 2014 The Chromium Authors. All rights reserved.
" Use of this source code is governed by a BSD-style license that can be
" found in the LICENSE file.

" Binds cmd-shift-i (on Mac) or ctrl-shift-i (elsewhere) to invoking
" clang-format.py.
" It will format the current selection (and if there's no selection, the
" current line.)

let s:script = expand('<sfile>:p:h') .
  \'/../../buildtools/clang_format/script/clang-format.py'

if has('mac')
  execute "map <D-I> :pyf " . s:script . "<CR>"
  execute "imap <D-I> <ESC>:pyf " . s:script . "<CR>i"
else
  execute "map <C-I> :pyf " . s:script . "<CR>"
  execute "imap <C-I> <ESC>:pyf " . s:script . "<CR>i"
endif

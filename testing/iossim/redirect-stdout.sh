#!/bin/sh
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# This script executes the command given as the first argument, strips
# cxx_destruct from stdout, and redirects the remaining stdout to the file given
# as the second argument.
#
# Example: Write the text 'foo' to a file called out.txt:
#   RedirectStdout.sh "echo foo" out.txt
#
# This script is invoked from iossim.gyp in order to redirect the output of
# class-dump to a file (because gyp actions don't support redirecting output).
# This script also removes all lines with cxx_destruct. Perhaps newer versions
# of class-dump will fix this issue.  As of 3.5, 'cxx_destruct' still exists.

if [ ${#} -ne 2 ] ; then
  echo "usage: ${0} <command> <output file>"
  exit 2
fi

echo "// Treat class-dump output as a system header." > $2
echo "#pragma clang system_header" >> $2
$1 | sed /cxx_destruct/d >> $2

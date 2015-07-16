# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Use this sed script to reduce a Mac build log into something readable.

# Drop uninformative lines.
/^distcc/d
/^Check dependencies/d
/^    setenv /d
/^    cd /d
/^make: Nothing to be done/d
/^$/d

# Xcode prints a short "compiling foobar.o" line followed by the lengthy
# full command line.  These deletions drop the command line.
\|^    /Developer/usr/bin/|d
\|^    /Developer/Library/PrivateFrameworks/DevToolsCore\.framework/|d
\|^    /Developer/Library/Xcode/Plug-ins/CoreBuildTasks\.xcplugin/|d

# Drop any goma command lines as well.
\|^    .*/gomacc |d

# And, if you've overridden something from your own bin directory, remove those
# full command lines, too.
\|^    /Users/[^/]*/bin/|d

# There's already a nice note for bindings, don't need the command line.
\|^python scripts/rule_binding\.py|d

# Shorten the "compiling foobar.o" line.
s|^Distributed-CompileC (.*) normal i386 c\+\+ com\.apple\.compilers\.gcc\.4_2|    CC \1|
s|^CompileC (.*) normal i386 c\+\+ com\.apple\.compilers\.gcc\.4_2|    CC \1|

#!/usr/bin/env python
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""
Creates a library loader (a header and implementation file),
which is a wrapper for dlopen or direct linking with given library.

The loader makes it possible to have the same client code for both cases,
and also makes it easier to write code using dlopen (and also provides
a standard way to do so, and limits the ugliness just to generated files).

For more info refer to http://crbug.com/162733 .
"""


import optparse
import os.path
import re
import sys


HEADER_TEMPLATE = """// This is generated file. Do not modify directly.
// Path to the code generator: %(generator_path)s .

#ifndef %(unique_prefix)s
#define %(unique_prefix)s

%(wrapped_header_include)s

#include <string>

class %(class_name)s {
 public:
  %(class_name)s();
  ~%(class_name)s();

  bool Load(const std::string& library_name)
      __attribute__((warn_unused_result));

  bool loaded() const { return loaded_; }

%(member_decls)s

 private:
  void CleanUp(bool unload);

#if defined(%(unique_prefix)s_DLOPEN)
  void* library_;
#endif

  bool loaded_;

  // Disallow copy constructor and assignment operator.
  %(class_name)s(const %(class_name)s&);
  void operator=(const %(class_name)s&);
};

#endif  // %(unique_prefix)s
"""


HEADER_MEMBER_TEMPLATE = """  decltype(&::%(function_name)s) %(function_name)s;
"""


IMPL_TEMPLATE = """// This is generated file. Do not modify directly.
// Path to the code generator: %(generator_path)s .

#include "%(generated_header_name)s"

#include <dlfcn.h>

// Put these sanity checks here so that they fire at most once
// (to avoid cluttering the build output).
#if !defined(%(unique_prefix)s_DLOPEN) && !defined(%(unique_prefix)s_DT_NEEDED)
#error neither %(unique_prefix)s_DLOPEN nor %(unique_prefix)s_DT_NEEDED defined
#endif
#if defined(%(unique_prefix)s_DLOPEN) && defined(%(unique_prefix)s_DT_NEEDED)
#error both %(unique_prefix)s_DLOPEN and %(unique_prefix)s_DT_NEEDED defined
#endif

%(class_name)s::%(class_name)s() : loaded_(false) {
}

%(class_name)s::~%(class_name)s() {
  CleanUp(loaded_);
}

bool %(class_name)s::Load(const std::string& library_name) {
  if (loaded_)
    return false;

#if defined(%(unique_prefix)s_DLOPEN)
  library_ = dlopen(library_name.c_str(), RTLD_LAZY);
  if (!library_)
    return false;
#endif

%(member_init)s

  loaded_ = true;
  return true;
}

void %(class_name)s::CleanUp(bool unload) {
#if defined(%(unique_prefix)s_DLOPEN)
  if (unload) {
    dlclose(library_);
    library_ = NULL;
  }
#endif
  loaded_ = false;
%(member_cleanup)s
}
"""

IMPL_MEMBER_INIT_TEMPLATE = """
#if defined(%(unique_prefix)s_DLOPEN)
  %(function_name)s =
      reinterpret_cast<decltype(this->%(function_name)s)>(
          dlsym(library_, "%(function_name)s"));
#endif
#if defined(%(unique_prefix)s_DT_NEEDED)
  %(function_name)s = &::%(function_name)s;
#endif
  if (!%(function_name)s) {
    CleanUp(true);
    return false;
  }
"""

IMPL_MEMBER_CLEANUP_TEMPLATE = """  %(function_name)s = NULL;
"""

def main():
  parser = optparse.OptionParser()
  parser.add_option('--name')
  parser.add_option('--output-cc')
  parser.add_option('--output-h')
  parser.add_option('--header')

  parser.add_option('--bundled-header')
  parser.add_option('--use-extern-c', action='store_true', default=False)
  parser.add_option('--link-directly', type=int, default=0)

  options, args = parser.parse_args()

  if not options.name:
    parser.error('Missing --name parameter')
  if not options.output_cc:
    parser.error('Missing --output-cc parameter')
  if not options.output_h:
    parser.error('Missing --output-h parameter')
  if not options.header:
    parser.error('Missing --header paramater')
  if not args:
    parser.error('No function names specified')

  # Make sure we are always dealing with paths relative to source tree root
  # to avoid issues caused by different relative path roots.
  source_tree_root = os.path.abspath(
    os.path.join(os.path.dirname(__file__), '..', '..'))
  options.output_cc = os.path.relpath(options.output_cc, source_tree_root)
  options.output_h = os.path.relpath(options.output_h, source_tree_root)

  # Create a unique prefix, e.g. for header guards.
  # Stick a known string at the beginning to ensure this doesn't begin
  # with an underscore, which is reserved for the C++ implementation.
  unique_prefix = ('LIBRARY_LOADER_' +
                   re.sub(r'[\W]', '_', options.output_h).upper())

  member_decls = []
  member_init = []
  member_cleanup = []
  for fn in args:
    member_decls.append(HEADER_MEMBER_TEMPLATE % {
      'function_name': fn,
      'unique_prefix': unique_prefix
    })
    member_init.append(IMPL_MEMBER_INIT_TEMPLATE % {
      'function_name': fn,
      'unique_prefix': unique_prefix
    })
    member_cleanup.append(IMPL_MEMBER_CLEANUP_TEMPLATE % {
      'function_name': fn,
      'unique_prefix': unique_prefix
    })

  header = options.header
  if options.link_directly == 0 and options.bundled_header:
    header = options.bundled_header
  wrapped_header_include = '#include %s\n' % header

  # Some libraries (e.g. libpci) have headers that cannot be included
  # without extern "C", otherwise they cause the link to fail.
  # TODO(phajdan.jr): This is a workaround for broken headers. Remove it.
  if options.use_extern_c:
    wrapped_header_include = 'extern "C" {\n%s\n}\n' % wrapped_header_include

  # It seems cleaner just to have a single #define here and #ifdefs in bunch
  # of places, rather than having a different set of templates, duplicating
  # or complicating more code.
  if options.link_directly == 0:
    wrapped_header_include += '#define %s_DLOPEN\n' % unique_prefix
  elif options.link_directly == 1:
    wrapped_header_include += '#define %s_DT_NEEDED\n' % unique_prefix
  else:
    parser.error('Invalid value for --link-directly. Should be 0 or 1.')

  # Make it easier for people to find the code generator just in case.
  # Doing it this way is more maintainable, because it's going to work
  # even if file gets moved without updating the contents.
  generator_path = os.path.relpath(__file__, source_tree_root)

  header_contents = HEADER_TEMPLATE % {
    'generator_path': generator_path,
    'unique_prefix': unique_prefix,
    'wrapped_header_include': wrapped_header_include,
    'class_name': options.name,
    'member_decls': ''.join(member_decls),
  }

  impl_contents = IMPL_TEMPLATE % {
    'generator_path': generator_path,
    'unique_prefix': unique_prefix,
    'generated_header_name': options.output_h,
    'class_name': options.name,
    'member_init': ''.join(member_init),
    'member_cleanup': ''.join(member_cleanup),
  }

  header_file = open(os.path.join(source_tree_root, options.output_h), 'w')
  try:
    header_file.write(header_contents)
  finally:
    header_file.close()

  impl_file = open(os.path.join(source_tree_root, options.output_cc), 'w')
  try:
    impl_file.write(impl_contents)
  finally:
    impl_file.close()

  return 0

if __name__ == '__main__':
  sys.exit(main())

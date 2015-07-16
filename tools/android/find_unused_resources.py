#!/usr/bin/python
# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Lists unused Java strings and other resources."""

import optparse
import re
import subprocess
import sys


def GetLibraryResources(r_txt_paths):
  """Returns the resources packaged in a list of libraries.

  Args:
    r_txt_paths: paths to each library's generated R.txt file which lists the
        resources it contains.

  Returns:
    The resources in the libraries as a list of tuples (type, name). Example:
    [('drawable', 'arrow'), ('layout', 'month_picker'), ...]
  """
  resources = []
  for r_txt_path in r_txt_paths:
    with open(r_txt_path, 'r') as f:
      for line in f:
        line = line.strip()
        if not line:
          continue
        data_type, res_type, name, _ = line.split(None, 3)
        assert data_type in ('int', 'int[]')
        # Hide attrs, which are redundant with styleables and always appear
        # unused, and hide ids, which are innocuous even if unused.
        if res_type in ('attr', 'id'):
          continue
        resources.append((res_type, name))
  return resources


def GetUsedResources(source_paths, resource_types):
  """Returns the types and names of resources used in Java or resource files.

  Args:
    source_paths: a list of files or folders collectively containing all the
        Java files, resource files, and the AndroidManifest.xml.
    resource_types: a list of resource types to look for.  Example:
        ['string', 'drawable']

  Returns:
    The resources referenced by the Java and resource files as a list of tuples
    (type, name).  Example:
    [('drawable', 'app_icon'), ('layout', 'month_picker'), ...]
  """
  type_regex = '|'.join(map(re.escape, resource_types))
  patterns = [r'@(())(%s)/(\w+)' % type_regex,
              r'\b((\w+\.)*)R\.(%s)\.(\w+)' % type_regex]
  resources = []
  for pattern in patterns:
    p = subprocess.Popen(
        ['grep', '-REIhoe', pattern] + source_paths,
        stdout=subprocess.PIPE)
    grep_out, grep_err = p.communicate()
    # Check stderr instead of return code, since return code is 1 when no
    # matches are found.
    assert not grep_err, 'grep failed'
    matches = re.finditer(pattern, grep_out)
    for match in matches:
      package = match.group(1)
      if package == 'android.':
        continue
      type_ = match.group(3)
      name = match.group(4)
      resources.append((type_, name))
  return resources


def FormatResources(resources):
  """Formats a list of resources for printing.

  Args:
    resources: a list of resources, given as (type, name) tuples.
  """
  return '\n'.join(['%-12s %s' % (t, n) for t, n in sorted(resources)])


def ParseArgs(args):
  parser = optparse.OptionParser()
  parser.add_option('-v', help='Show verbose output', action='store_true')
  parser.add_option('-s', '--source-path', help='Specify a source folder path '
                    '(e.g. ui/android/java)', action='append', default=[])
  parser.add_option('-r', '--r-txt-path', help='Specify a "first-party" R.txt '
                    'file (e.g. out/Debug/content_shell_apk/R.txt)',
                    action='append', default=[])
  parser.add_option('-t', '--third-party-r-txt-path', help='Specify an R.txt '
                    'file for a third party library', action='append',
                    default=[])
  options, args = parser.parse_args(args=args)
  if args:
    parser.error('positional arguments not allowed')
  if not options.source_path:
    parser.error('at least one source folder path must be specified with -s')
  if not options.r_txt_path:
    parser.error('at least one R.txt path must be specified with -r')
  return (options.v, options.source_path, options.r_txt_path,
          options.third_party_r_txt_path)


def main(args=None):
  verbose, source_paths, r_txt_paths, third_party_r_txt_paths = ParseArgs(args)
  defined_resources = (set(GetLibraryResources(r_txt_paths)) -
                       set(GetLibraryResources(third_party_r_txt_paths)))
  resource_types = list(set([r[0] for r in defined_resources]))
  used_resources = set(GetUsedResources(source_paths, resource_types))
  unused_resources = defined_resources - used_resources
  undefined_resources = used_resources - defined_resources

  # aapt dump fails silently. Notify the user if things look wrong.
  if not defined_resources:
    print >> sys.stderr, (
        'Warning: No resources found. Did you provide the correct R.txt paths?')
  if not used_resources:
    print >> sys.stderr, (
        'Warning: No resources referenced from Java or resource files. Did you '
        'provide the correct source paths?')
  if undefined_resources:
    print >> sys.stderr, (
        'Warning: found %d "undefined" resources that are referenced by Java '
        'files or by other resources, but are not defined anywhere. Run with '
        '-v to see them.' % len(undefined_resources))

  if verbose:
    print '%d undefined resources:' % len(undefined_resources)
    print FormatResources(undefined_resources), '\n'
    print '%d resources defined:' % len(defined_resources)
    print FormatResources(defined_resources), '\n'
    print '%d used resources:' % len(used_resources)
    print FormatResources(used_resources), '\n'
    print '%d unused resources:' % len(unused_resources)
  print FormatResources(unused_resources)


if __name__ == '__main__':
  main()

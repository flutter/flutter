#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

#
# Derivative work of https://chromium.googlesource.com/chromium/src/+/HEAD/build/config/fuchsia/prepare_package_inputs.py
#

"""Creates a archive manifest used for Fuchsia package generation."""

import argparse
import json
import os
import shutil
import subprocess
import sys

# File extension of a component manifest for each Component Framework version
MANIFEST_VERSION_EXTENSIONS = {"v1": ".cmx", "v2": ".cm"}


def make_package_path(file_path, roots):
  """Computes a path for |file_path| relative to one of the |roots|.

  Args:
    file_path: The file path to relativize.
    roots: A list of directory paths which may serve as a relative root for
      |file_path|.

    For example:
        * make_package_path('/foo/bar.txt', ['/foo/']) 'bar.txt'
        * make_package_path('/foo/dir/bar.txt', ['/foo/']) 'dir/bar.txt'
        * make_package_path('/foo/out/Debug/bar.exe', ['/foo/', '/foo/out/Debug/']) 'bar.exe'
  """

  # Prevents greedily matching against a shallow path when a deeper, better
  # matching path exists.
  roots.sort(key=len, reverse=True)

  for next_root in roots:
    if not next_root.endswith(os.sep):
      next_root += os.sep

    if file_path.startswith(next_root):
      relative_path = file_path[len(next_root):]
      return relative_path

  return file_path


def _get_stripped_path(bin_path):
  """Finds the stripped version of |bin_path| in the build output directory.

        returns |bin_path| if no stripped path is found.
  """
  stripped_path = bin_path.replace('lib.unstripped/',
                                   'lib/').replace('exe.unstripped/', '')
  if os.path.exists(stripped_path):
    return stripped_path
  else:
    return bin_path


def _is_binary(path):
  """Checks if the file at |path| is an ELF executable.

        This is done by inspecting its FourCC header.
  """

  with open(path, 'rb') as f:
    file_tag = f.read(4)
  return file_tag == b'\x7fELF'


def _write_build_ids_txt(binary_paths, ids_txt_path):
  """Writes an index text file mapping build IDs to unstripped binaries."""

  READELF_FILE_PREFIX = 'File: '
  READELF_BUILD_ID_PREFIX = 'Build ID: '

  # List of binaries whose build IDs are awaiting processing by readelf.
  # Entries are removed as readelf's output is parsed.
  unprocessed_binary_paths = set(binary_paths)
  build_ids_map = {}

  # Sanity check that unstripped binaries do not also have their stripped
  # counterpart listed.
  for binary_path in binary_paths:
    stripped_binary_path = _get_stripped_path(binary_path)
    if stripped_binary_path != binary_path:
      unprocessed_binary_paths.discard(stripped_binary_path)

  with open(ids_txt_path, 'w') as ids_file:
    # TODO(richkadel): This script (originally from the Fuchsia GN SDK) was
    # changed, adding this `if unprocessed_binary_paths` check, because for
    # the Dart packages I tested (child-view and parent-view), this was
    # empty. Update the Fuchsia GN SDK? (Or figure out if the Dart packages
    # _should_ have at least one unprocessed_binary_path?)
    if unprocessed_binary_paths:
      # Create a set to dedupe stripped binary paths in case both the stripped and
      # unstripped versions of a binary are specified.
      readelf_stdout = subprocess.check_output(['readelf', '-n'] +
                                               sorted(unprocessed_binary_paths)
                                              ).decode('utf8')

      if len(binary_paths) == 1:
        # Readelf won't report a binary's path if only one was provided to the
        # tool.
        binary_path = binary_paths[0]
      else:
        binary_path = None

      for line in readelf_stdout.split('\n'):
        line = line.strip()

        if line.startswith(READELF_FILE_PREFIX):
          binary_path = line[len(READELF_FILE_PREFIX):]
          assert binary_path in unprocessed_binary_paths

        elif line.startswith(READELF_BUILD_ID_PREFIX):
          # Paths to the unstripped executables listed in "ids.txt" are specified
          # as relative paths to that file.
          unstripped_rel_path = os.path.relpath(
              os.path.abspath(binary_path),
              os.path.dirname(os.path.abspath(ids_txt_path))
          )

          build_id = line[len(READELF_BUILD_ID_PREFIX):]
          build_ids_map[build_id] = unstripped_rel_path
          unprocessed_binary_paths.remove(binary_path)

      for id_and_path in sorted(build_ids_map.items()):
        ids_file.write(id_and_path[0] + ' ' + id_and_path[1] + '\n')

  # Did readelf forget anything? Make sure that all binaries are accounted for.
  assert not unprocessed_binary_paths


def _parse_component(component_info_file):
  component_info = json.load(open(component_info_file, 'r'))
  return component_info


def _get_component_manifests(component_info):
  return [c for c in component_info if c.get('type') == 'manifest']


# TODO(richkadel): Changed, from the Fuchsia GN SDK version to add this function
# and related code, to include support for a file of resources that aren't known
# until compile time.
def _get_resource_items_from_json_items(component_info):
  nested_resources = []
  files = [
      c.get('source')
      for c in component_info
      if c.get('type') == 'json_of_resources'
  ]
  for json_file in files:
    for resource in _parse_component(json_file):
      nested_resources.append(resource)
  return nested_resources


def _get_resource_items(component_info):
  return ([c for c in component_info if c.get('type') == 'resource'] +
          _get_resource_items_from_json_items(component_info))


def _get_expanded_files(runtime_deps_file):
  """ Process the runtime deps file for file paths, recursively walking
    directories as needed.

    Returns a set of expanded files referenced by the runtime deps file.
    """

  # runtime_deps may contain duplicate paths, so use a set for
  # de-duplication.
  expanded_files = set()
  for next_path in open(runtime_deps_file, 'r'):
    next_path = next_path.strip()
    if os.path.isdir(next_path):
      for root, _, files in os.walk(next_path):
        for current_file in files:
          if current_file.startswith('.'):
            continue
          expanded_files.add(os.path.normpath(os.path.join(root, current_file)))
    else:
      expanded_files.add(os.path.normpath(next_path))
  return expanded_files


def _write_gn_deps_file(
    depfile_path, package_manifest, component_manifests, out_dir, expanded_files
):
  with open(depfile_path, 'w') as depfile:
    deps_list = [os.path.relpath(f, out_dir) for f in expanded_files]
    deps_list.extend(component_manifests)

    # The deps file is space-delimited, so filenames containing spaces
    # must have them escaped.
    deps_list = [f.replace(' ', '\\ ') for f in deps_list]

    deps_string = ' '.join(sorted(deps_list))
    depfile.write('%s: %s' % (package_manifest, deps_string))


def _write_meta_package_manifest(
    manifest_entries, manifest_path, app_name, out_dir, package_version
):
  # Write meta/package manifest file and add to archive manifest.
  meta_package = os.path.join(os.path.dirname(manifest_path), 'package')
  with open(meta_package, 'w') as package_json:
    json_payload = {'version': package_version, 'name': app_name}
    json.dump(json_payload, package_json)
    package_json_filepath = os.path.relpath(package_json.name, out_dir)
    manifest_entries['meta/package'] = package_json_filepath


def _write_component_manifest(
    manifest_entries, component_info, archive_manifest_path, out_dir
):
  """Copy component manifest files and add to archive manifest.

    Raises an exception if a component uses a unknown manifest version.
    """

  for component_manifest in _get_component_manifests(component_info):
    manifest_version = component_manifest.get('manifest_version')

    if manifest_version not in MANIFEST_VERSION_EXTENSIONS:
      raise Exception('Unknown manifest_version: {}'.format(manifest_version))

    # TODO(richkadel): Changed, from the Fuchsia GN SDK version, to assume
    # the given `output_name` already includes its extension. This change
    # has not been fully validate, in particular, it has not been tested
    # with CF v2 `.cm` (from `.cml`) files. Original implementation was:
    #
    # extension = MANIFEST_VERSION_EXTENSIONS.get(manifest_version)
    # manifest_dest_file_path = os.path.join(
    #     os.path.dirname(archive_manifest_path),
    #     component_manifest.get('output_name') + extension)
    manifest_dest_file_path = os.path.join(
        os.path.dirname(archive_manifest_path),
        component_manifest.get('output_name')
    )
    # Add the 'meta/' subdir, for example, if `output_name` includes it
    os.makedirs(os.path.dirname(manifest_dest_file_path), exist_ok=True)
    shutil.copy(component_manifest.get('source'), manifest_dest_file_path)

    manifest_entries['meta/%s' % os.path.basename(manifest_dest_file_path)
                    ] = os.path.relpath(manifest_dest_file_path, out_dir)
  return manifest_dest_file_path


def _write_package_manifest(
    manifest_entries, expanded_files, out_dir, exclude_file, root_dir,
    component_info
):
  """Writes the package manifest for a Fuchsia package

    Returns a list of binaries in the package.

    Raises an exception if excluded files are not found."""
  gen_dir = os.path.normpath(os.path.join(out_dir, 'gen'))
  excluded_files_set = set(exclude_file)
  roots = [gen_dir, root_dir, out_dir]

  # Filter out component manifests. These are written out elsewhere.
  excluded_files_set.update([
      make_package_path(os.path.relpath(cf.get('source'), out_dir), roots)
      for cf in _get_component_manifests(component_info)
      if os.path.relpath(cf.get('source'), out_dir) in expanded_files
  ])

  # Filter out json_of_resources since only their contents are written, and we
  # don't know the contained resources until late in the build cycle
  excluded_files_set.update([
      make_package_path(os.path.relpath(cf.get('source'), out_dir), roots)
      for cf in component_info
      if cf.get('type') == 'json_of_resources' and
      os.path.relpath(cf.get('source'), out_dir) in expanded_files
  ])

  # Write out resource files with specific package paths, and exclude them from
  # the list of expanded files so they are not listed twice in the manifest.
  for resource in _get_resource_items(component_info):
    relative_src_file = os.path.relpath(resource.get('source'), out_dir)
    resource_path = make_package_path(relative_src_file, roots)
    manifest_entries[resource.get('dest')] = relative_src_file
    if resource.get('type') == 'resource':
      excluded_files_set.add(resource_path)

  for current_file in expanded_files:
    current_file = _get_stripped_path(current_file)
    # make_package_path() may relativize to either the source root or
    # output directory.
    in_package_path = make_package_path(current_file, roots)

    if in_package_path in excluded_files_set:
      excluded_files_set.remove(in_package_path)
    else:
      manifest_entries[in_package_path] = current_file

  if excluded_files_set:
    raise Exception(
        'Some files were excluded with --exclude-file but '
        'not found in the deps list, or a resource (data) file '
        'was added and not filtered out. Excluded files and resources: '
        '%s' % ', '.join(excluded_files_set)
    )


def _build_manifest(args):
  # Use a sorted list to make sure the manifest order is deterministic.
  expanded_files = sorted(_get_expanded_files(args.runtime_deps_file))
  component_info = _parse_component(args.json_file)
  component_manifests = []

  # Collect the manifest entries in a map since duplication happens
  # because of runtime libraries.
  manifest_entries = {}
  _write_meta_package_manifest(
      manifest_entries, args.manifest_path, args.app_name, args.out_dir,
      args.package_version
  )
  for component_item in component_info:
    _write_package_manifest(
        manifest_entries, expanded_files, args.out_dir, args.exclude_file,
        args.root_dir, component_item
    )
    component_manifests.append(
        _write_component_manifest(
            manifest_entries, component_item, args.manifest_path, args.out_dir
        )
    )

  with open(args.manifest_path, 'w') as manifest:
    for key in sorted(manifest_entries.keys()):
      manifest.write('%s=%s\n' % (key, manifest_entries[key]))

  binaries = [f for f in expanded_files if _is_binary(f)]
  _write_build_ids_txt(sorted(binaries), args.build_ids_file)

  # Omit any excluded_files from the expanded_files written to the depfile.
  gen_dir = os.path.normpath(os.path.join(args.out_dir, 'gen'))
  roots = [gen_dir, args.root_dir, args.out_dir]
  excluded_files_set = set(args.exclude_file)
  expanded_deps_files = [
      path for path in expanded_files
      if make_package_path(path, roots) not in excluded_files_set
  ]

  _write_gn_deps_file(
      args.depfile_path, args.manifest_path, component_manifests, args.out_dir,
      expanded_deps_files
  )
  return 0


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--root-dir', required=True, help='Build root directory')
  parser.add_argument('--out-dir', required=True, help='Build output directory')
  parser.add_argument('--app-name', required=True, help='Package name')
  parser.add_argument(
      '--runtime-deps-file',
      required=True,
      help='File with the list of runtime dependencies.'
  )
  parser.add_argument(
      '--depfile-path', required=True, help='Path to write GN deps file.'
  )
  parser.add_argument(
      '--exclude-file',
      action='append',
      default=[],
      help='Package-relative file path to exclude from the package.'
  )
  parser.add_argument(
      '--manifest-path', required=True, help='Manifest output path.'
  )
  parser.add_argument(
      '--build-ids-file', required=True, help='Debug symbol index path.'
  )
  parser.add_argument('--json-file', required=True)
  parser.add_argument(
      '--package-version', default='0', help='Version of the package'
  )

  args = parser.parse_args()

  return _build_manifest(args)


if __name__ == '__main__':
  sys.exit(main())

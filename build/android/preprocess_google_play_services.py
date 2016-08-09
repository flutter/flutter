#!/usr/bin/env python
#
# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

'''Prepares the Google Play services split client libraries before usage by
Chrome's build system.

We need to preprocess Google Play services before using it in Chrome
builds for 2 main reasons:

- Getting rid of unused resources: unsupported languages, unused
drawables, etc.

- Merging the differents jars so that it can be proguarded more
easily. This is necessary since debug and test apks get very close
to the dex limit.

The script is supposed to be used with the maven repository that can be obtained
by downloading the "extra-google-m2repository" from the Android SDK Manager. It
also supports importing from already extracted AAR files using the
--is-extracted-repo flag.

The json config (see the -c argument) file should provide the following fields:

- lib_version: String. Used when building from the maven repository. It should
  be the package's version (e.g. "7.3.0")

- clients: String array. List of clients to pick. For example, when building
  from the maven repository, it's the artifactId (e.g. "play-services-base") of
  each client.

- client_filter: String array. Pattern of files to prune from the clients once
  extracted. Metacharacters are allowed. (e.g. "res/drawable*")

The output is a directory with the following structure:

    OUT_DIR
    +-- google-play-services.jar
    +-- res
    |   +-- CLIENT_1
    |   |   +-- color
    |   |   +-- values
    |   |   +-- etc.
    |   +-- CLIENT_2
    |       +-- ...
    +-- stub
        +-- res/[.git-keep-directory]
        +-- src/android/UnusedStub.java

Requires the `jar` utility in the path.

'''

import argparse
import glob
import itertools
import json
import os
import shutil
import stat
import sys

from pylib import cmd_helper
from pylib import constants

sys.path.append(
    os.path.join(constants.DIR_SOURCE_ROOT, 'build', 'android', 'gyp'))
from util import build_utils


M2_PKG_PATH = os.path.join('com', 'google', 'android', 'gms')


def main():
  parser = argparse.ArgumentParser(description=("Prepares the Google Play "
      "services split client libraries before usage by Chrome's build system"))
  parser.add_argument('-r',
                      '--repository',
                      help='The Google Play services repository location',
                      required=True,
                      metavar='FILE')
  parser.add_argument('-o',
                      '--out-dir',
                      help='The output directory',
                      required=True,
                      metavar='FILE')
  parser.add_argument('-c',
                      '--config-file',
                      help='Config file path',
                      required=True,
                      metavar='FILE')
  parser.add_argument('-g',
                      '--git-friendly',
                      action='store_true',
                      default=False,
                      help='Add a .gitkeep file to the empty directories')
  parser.add_argument('-x',
                      '--is-extracted-repo',
                      action='store_true',
                      default=False,
                      help='The provided repository is not made of AAR files.')

  args = parser.parse_args()

  ProcessGooglePlayServices(args.repository,
                            args.out_dir,
                            args.config_file,
                            args.git_friendly,
                            args.is_extracted_repo)


def ProcessGooglePlayServices(repo, out_dir, config_path, git_friendly,
                              is_extracted_repo):
  with open(config_path, 'r') as json_file:
    config = json.load(json_file)

  with build_utils.TempDir() as tmp_root:
    tmp_paths = _SetupTempDir(tmp_root)

    if is_extracted_repo:
      _ImportFromExtractedRepo(config, tmp_paths, repo)
    else:
      _ImportFromAars(config, tmp_paths, repo)

    _GenerateCombinedJar(tmp_paths)
    _ProcessResources(config, tmp_paths)
    _BuildOutput(config, tmp_paths, out_dir, git_friendly)


def _SetupTempDir(tmp_root):
  tmp_paths = {
    'root': tmp_root,
    'imported_clients': os.path.join(tmp_root, 'imported_clients'),
    'extracted_jars': os.path.join(tmp_root, 'jar'),
    'combined_jar': os.path.join(tmp_root, 'google-play-services.jar'),
  }
  os.mkdir(tmp_paths['imported_clients'])
  os.mkdir(tmp_paths['extracted_jars'])

  return tmp_paths


def _SetupOutputDir(out_dir):
  out_paths = {
    'root': out_dir,
    'res': os.path.join(out_dir, 'res'),
    'jar': os.path.join(out_dir, 'google-play-services.jar'),
    'stub': os.path.join(out_dir, 'stub'),
  }

  shutil.rmtree(out_paths['jar'], ignore_errors=True)
  shutil.rmtree(out_paths['res'], ignore_errors=True)
  shutil.rmtree(out_paths['stub'], ignore_errors=True)

  return out_paths


def _MakeWritable(dir_path):
  for root, dirs, files in os.walk(dir_path):
    for path in itertools.chain(dirs, files):
      st = os.stat(os.path.join(root, path))
      os.chmod(os.path.join(root, path), st.st_mode | stat.S_IWUSR)


def _ImportFromAars(config, tmp_paths, repo):
  for client in config['clients']:
    aar_name = '%s-%s.aar' % (client, config['lib_version'])
    aar_path = os.path.join(repo, M2_PKG_PATH, client,
                            config['lib_version'], aar_name)
    aar_out_path = os.path.join(tmp_paths['imported_clients'], client)
    build_utils.ExtractAll(aar_path, aar_out_path)

    client_jar_path = os.path.join(aar_out_path, 'classes.jar')
    build_utils.ExtractAll(client_jar_path, tmp_paths['extracted_jars'],
                           no_clobber=False)


def _ImportFromExtractedRepo(config, tmp_paths, repo):
  # Import the clients
  try:
    for client in config['clients']:
      client_out_dir = os.path.join(tmp_paths['imported_clients'], client)
      shutil.copytree(os.path.join(repo, client), client_out_dir)

      client_jar_path = os.path.join(client_out_dir, 'classes.jar')
      build_utils.ExtractAll(client_jar_path, tmp_paths['extracted_jars'],
                             no_clobber=False)
  finally:
    _MakeWritable(tmp_paths['imported_clients'])


def _GenerateCombinedJar(tmp_paths):
  out_file_name = tmp_paths['combined_jar']
  working_dir = tmp_paths['extracted_jars']
  cmd_helper.Call(['jar', '-cf', out_file_name, '-C', working_dir, '.'])


def _ProcessResources(config, tmp_paths):
  # Prune unused resources
  for res_filter in config['client_filter']:
    glob_pattern = os.path.join(tmp_paths['imported_clients'], '*', res_filter)
    for prune_target in glob.glob(glob_pattern):
      shutil.rmtree(prune_target)


def _BuildOutput(config, tmp_paths, out_dir, git_friendly):
  out_paths = _SetupOutputDir(out_dir)

  # Copy the resources to the output dir
  for client in config['clients']:
    res_in_tmp_dir = os.path.join(tmp_paths['imported_clients'], client, 'res')
    if os.path.isdir(res_in_tmp_dir) and os.listdir(res_in_tmp_dir):
      res_in_final_dir = os.path.join(out_paths['res'], client)
      shutil.copytree(res_in_tmp_dir, res_in_final_dir)

  # Copy the jar
  shutil.copyfile(tmp_paths['combined_jar'], out_paths['jar'])

  # Write the java dummy stub. Needed for gyp to create the resource jar
  stub_location = os.path.join(out_paths['stub'], 'src', 'android')
  os.makedirs(stub_location)
  with open(os.path.join(stub_location, 'UnusedStub.java'), 'w') as stub:
    stub.write('package android;'
               'public final class UnusedStub {'
               '    private UnusedStub() {}'
               '}')

  # Create the main res directory. Will be empty but is needed by gyp
  stub_res_location = os.path.join(out_paths['stub'], 'res')
  os.makedirs(stub_res_location)
  if git_friendly:
    build_utils.Touch(os.path.join(stub_res_location, '.git-keep-directory'))


if __name__ == '__main__':
  sys.exit(main())

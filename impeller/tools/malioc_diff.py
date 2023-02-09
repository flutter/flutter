#!/usr/bin/env vpython3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import os
import sys

# This script detects performance impacting changes to shaders.
#
# When the GN build is configured with the path to the `malioc` tool, the
# results of its analysis will be placed under `out/$CONFIG/gen/malioc` in
# separate .json files. That path should be supplied to this script as the
# `--after` argument. This script compares those results against previous
# results in a golden file checked in to the tree under
# `flutter/impeller/tools/malioc.json`. That file should be passed to this
# script as the `--before` argument. To create or update the golden file,
# passing the `--update` flag will cause the data from the `--after` path to
# overwrite the file at the `--before` path.
#
# Configure and build:
# $ flutter/tools/gn --malioc-path path/to/malioc
# $ ninja -C out/host_debug
#
# Analyze
# $ flutter/impeller/tools/malioc_diff.py \
#   --before flutter/impeller/tools/malioc.json \
#   --after out/host_debug/gen/malioc
#
# If there are differences between before and after, whether positive or
# negative, the exit code for this script will be 1, and 0 otherwise.

CORES = [
    'Mali-G78',  # Pixel 6 / 2020
    'Mali-T880',  # 2016
]


def parse_args(argv):
  parser = argparse.ArgumentParser(
      description='A script that compares before/after malioc analysis results',
  )
  parser.add_argument(
      '--after',
      '-a',
      type=str,
      help='The path to a directory tree containing new malioc results in json files.',
  )
  parser.add_argument(
      '--before',
      '-b',
      type=str,
      help='The path to a json file containing existing malioc results.',
  )
  parser.add_argument(
      '--update',
      '-u',
      default=False,
      action='store_true',
      help='Write results from the --after tree to the --before file.',
  )
  parser.add_argument(
      '--verbose',
      '-v',
      default=False,
      action='store_true',
      help='Emit verbose output.',
  )
  return parser.parse_args(argv)


def validate_args(args):
  if not args.after or not os.path.isdir(args.after):
    print('The --after argument must refer to a directory.')
    return False
  if not args.before or (not args.update and not os.path.isfile(args.before)):
    print('The --before argument must refer to an existing file.')
    return False
  return True


# Parses the json output from malioc, which follows the schema defined in
# `mali_offline_compiler/samples/json_schemas/performance-schema.json`.
def read_malioc_file(malioc_tree, json_file):
  with open(json_file, 'r') as file:
    json_obj = json.load(file)

  build_gen_dir = os.path.dirname(malioc_tree)

  results = []
  for shader in json_obj['shaders']:
    # Ignore cores not in the allowlist above.
    if shader['hardware']['core'] not in CORES:
      continue
    result = {}
    result['filename'] = os.path.relpath(shader['filename'], build_gen_dir)
    result['core'] = shader['hardware']['core']
    result['type'] = shader['shader']['type']
    for prop in shader['properties']:
      result[prop['name']] = prop['value']

    result['variants'] = {}
    for variant in shader['variants']:
      variant_result = {}
      for prop in variant['properties']:
        variant_result[prop['name']] = prop['value']

      performance = variant['performance']
      variant_result['pipelines'] = performance['pipelines']
      variant_result['longest_path_cycles'] = performance['longest_path_cycles'
                                                         ]['cycle_count']
      variant_result['shortest_path_cycles'] = performance[
          'shortest_path_cycles']['cycle_count']
      variant_result['total_cycles'] = performance['total_cycles']['cycle_count'
                                                                  ]
      result['variants'][variant['name']] = variant_result
    results.append(result)

  return results


# Parses a tree of malioc performance json files.
#
# The parsing results are returned in a map keyed by the shader file name, whose
# values are maps keyed by the core type. The values in these maps are the
# performance properties of the shader on the core reported by malioc. This
# structure allows for a fast lookup and comparison against the golen file.
def read_malioc_tree(malioc_tree):
  results = {}
  for root, _, files in os.walk(malioc_tree):
    for file in files:
      if not file.endswith('.json'):
        continue
      full_path = os.path.join(root, file)
      for shader in read_malioc_file(malioc_tree, full_path):
        if shader['filename'] not in results:
          results[shader['filename']] = {}
        results[shader['filename']][shader['core']] = shader
  return results


def compare_variants(befores, afters):
  differences = []
  for variant_name, before_variant in befores.items():
    after_variant = afters[variant_name]
    for variant_key, before_variant_val in before_variant.items():
      after_variant_val = after_variant[variant_key]
      if before_variant_val != after_variant_val:
        differences += [
            '{} in variant {}:\n  {} <- before\n  {} <- after'.format(
                variant_key, variant_name, before_variant_val, after_variant_val
            )
        ]
  return differences


def compare_shaders(malioc_tree, before_shader, after_shader):
  differences = []
  for key, before_val in before_shader.items():
    after_val = after_shader[key]
    if key == 'variants':
      differences += compare_variants(before_val, after_val)
    elif before_val != after_val:
      differences += [
          '{}:\n  {} <- before\n  {} <- after'.format(
              key, before_val, after_val
          )
      ]

  if bool(differences):
    build_gen_dir = os.path.dirname(malioc_tree)
    filename = before_shader['filename']
    core = before_shader['core']
    typ = before_shader['type']
    print('Changes found in shader {} on core {}:'.format(filename, core))
    for diff in differences:
      print(diff)
    print(
        '\nFor a full report, run:\n  $ malioc --{} --core {} {}/{}'.format(
            typ.lower(), core, build_gen_dir, filename
        )
    )

  return bool(differences)


def main(argv):
  args = parse_args(argv[1:])
  if not validate_args(args):
    return 1

  after_json = read_malioc_tree(args.after)
  if not bool(after_json):
    print('Did not find any malioc results under {}.'.format(args.after))
    return 1

  if args.update:
    # Write the new results to the file given by --before, then exit.
    with open(args.before, 'w') as file:
      json.dump(after_json, file, sort_keys=True)
    return 0

  with open(args.before, 'r') as file:
    before_json = json.load(file)

  changed = False
  for filename, shaders in before_json.items():
    for core, before_shader in shaders.items():
      if core not in after_json[filename].keys():
        continue
      after_shader = after_json[filename][core]
      if compare_shaders(args.after, before_shader, after_shader):
        changed = True

  for filename, shaders in after_json.items():
    if filename not in before_json:
      print(
          'Shader {} is new. Run with --update to update checked-in results'
          .format(filename)
      )
      changed = True

  return 1 if changed else 0


if __name__ == '__main__':
  sys.exit(main(sys.argv))

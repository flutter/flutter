#!/usr/bin/env python3
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Enforces the 3-Layer Dependency Firewall & Monotonic Header Ratchet (RFC 410, ADR-0010)."""

import json
import os
from pathlib import Path
import re
import sys
from typing import Dict, List, Set, Tuple

INTERNAL_PREFIXES = (
    'flutter/shell/common/',
    'flutter/flow/',
    'flutter/impeller/',
    'flutter/runtime/',
    'flutter/lib/ui/',
    'flutter/common/graphics/',
    'flutter/shell/gpu/',
    'impeller/',
)

FORBIDDEN_EMBEDDER_PREFIXES = (
    'flutter/assets/',
    'flutter/common/graphics/',
    'flutter/display_list/',
    'flutter/flow/',
    'flutter/impeller/',
    'flutter/lib/ui/',
    'flutter/runtime/',
    'flutter/shell/common/',
    'flutter/shell/gpu/',
    'flutter/skia/',
    'flutter/txt/',
    'flutter/vulkan/',
    'impeller/',
    'third_party/skia/',
)

EMBEDDER_NATIVE_SRC_FILES = {
    'android_engine_group.cc',
    'android_engine_group.h',
    'android_hardware_buffer.cc',
    'android_hardware_buffer.h',
    'android_mutators_mapper.cc',
    'android_mutators_mapper.h',
    'android_platform_views_controller.cc',
    'android_platform_views_controller.h',
    'android_semantics_mapper.cc',
    'android_semantics_mapper.h',
    'android_surface_control.cc',
    'android_surface_control.h',
    'android_vm_init.cc',
    'android_vm_init.h',
    'android_vsync_waiter.cc',
    'android_vsync_waiter.h',
    'android_vulkan_external_texture.cc',
    'android_vulkan_external_texture.h',
    'android_window_metrics_mapper.cc',
    'android_window_metrics_mapper.h',
    'apk_asset_provider.cc',
    'apk_asset_provider.h',
    'flutter_embedder_native.cc',
    'flutter_embedder_native.h',
    'jni_delegate.h',
    'jni_router.cc',
    'jni_router.h',
    'jvm_invoker.cc',
    'jvm_invoker.h',
}

ALLOWED_EMBEDDER_DEPS = {
    '//flutter/common',
    '//flutter/fml',
    '//flutter/shell/platform/embedder:embedder_headers',
}

INCLUDE_RE = re.compile(r'^\s*#\s*include\s+"([^"]+)"')


def verify_build_gn_firewall(android_dir: Path) -> List[str]:
  """Verifies BUILD.gn firewall constraints for :flutter_embedder_native_src."""
  build_gn_path = android_dir / 'BUILD.gn'
  if not build_gn_path.exists():
    return ['BUILD.gn not found in shell/platform/android/']
  content = build_gn_path.read_text(encoding='utf-8')
  errors = []
  if 'source_set("flutter_embedder_native_src")' not in content:
    errors.append('BUILD.gn is missing source_set("flutter_embedder_native_src")')
    return errors
  if '"FLUTTER_ENGINE_NO_PROTOTYPES"' not in content:
    errors.append('BUILD.gn is missing defines = [ "FLUTTER_ENGINE_NO_PROTOTYPES" ]')
  if 'check_includes = true' not in content:
    errors.append('BUILD.gn is missing check_includes = true')

  # Extract the flutter_embedder_native_src block and verify deps.
  start_idx = content.index('source_set("flutter_embedder_native_src")')
  depth = 0
  block_end = len(content)
  for idx in range(start_idx, len(content)):
    if content[idx] == '{':
      depth += 1
    elif content[idx] == '}':
      depth -= 1
      if depth == 0:
        block_end = idx + 1
        break
  block = content[start_idx:block_end]
  deps_match = re.search(r'(?:public_)?deps\s*=\s*\[([^\]]*)\]', block)
  if not deps_match:
    errors.append('flutter_embedder_native_src is missing deps = [ ... ]')
  else:
    deps_raw = deps_match.group(1)
    found_deps = set(re.findall(r'"([^"]+)"', deps_raw))
    unauthorized_deps = sorted(found_deps - ALLOWED_EMBEDDER_DEPS)
    if unauthorized_deps:
      errors.append('flutter_embedder_native_src has unauthorized deps: '
                    f'{unauthorized_deps}')
    missing_deps = sorted(ALLOWED_EMBEDDER_DEPS - found_deps)
    if missing_deps:
      errors.append(f'flutter_embedder_native_src is missing required deps: {missing_deps}')
  return errors


def collect_candidate_files(android_dir: Path) -> List[Path]:
  """Collects all source and GN files under shell/platform/android/."""
  candidates = []
  suffixes = ('.cc', '.h', '.cpp', '.mm', '.gn', '.gni')
  for root, _, files in os.walk(android_dir):
    for name in files:
      if name.endswith(suffixes):
        candidates.append(Path(root) / name)
  candidates.sort()
  return candidates


def scan_android_sources(android_dir: Path,) -> Tuple[Dict[str, List[str]], Set[str], List[str]]:
  """Scans Android embedder files for internal includes and nogncheck comments."""
  file_to_headers = {}
  unique_headers = set()
  violations = []

  for full_path in collect_candidate_files(android_dir):
    rel_path = full_path.relative_to(android_dir).as_posix()
    lines = full_path.read_text(encoding='utf-8').splitlines()
    matched_headers = set()

    for line_no, line in enumerate(lines, start=1):
      if 'nogncheck' in line:
        violations.append(f'{rel_path}:{line_no}: prohibited nogncheck comment')
      if full_path.suffix in ('.gn', '.gni'):
        continue
      match = INCLUDE_RE.match(line)
      if not match:
        continue
      header = match.group(1)
      if any(header.startswith(prefix) for prefix in INTERNAL_PREFIXES):
        matched_headers.add(header)
      if rel_path in EMBEDDER_NATIVE_SRC_FILES and any(
          header.startswith(prefix) for prefix in FORBIDDEN_EMBEDDER_PREFIXES):
        violations.append(
            f'{rel_path}:{line_no}: forbidden internal header "{header}" '
            'in :flutter_embedder_native_src'
        )

    if matched_headers:
      file_to_headers[rel_path] = sorted(matched_headers)
      unique_headers.update(matched_headers)

  return file_to_headers, unique_headers, violations


def write_baseline_file(
    baseline_path: Path,
    sorted_legacy_files: Dict[str, List[str]],
    sorted_unique_headers: List[str],
) -> int:
  """Writes the JSON-compatible YAML baseline file."""
  payload = {
      'allowed_legacy_files': sorted_legacy_files,
      'allowed_unique_headers': sorted_unique_headers,
      'governing_adr': 'ADR-0010',
      'rfc': 'RFC-410.0000',
      'total_allowed_internal_headers': len(sorted_unique_headers),
  }
  header_comment = (
      '# Copyright 2013 The Flutter Authors. All rights reserved.\n'
      '# Use of this source code is governed by a BSD-style license that can be\n'
      '# found in the LICENSE file.\n'
      '#\n'
      '# JSON-compatible YAML baseline for the 3-Layer Dependency Ratchet (ADR-0010).\n'
  )
  baseline_path.write_text(
      header_comment + json.dumps(payload, indent=2) + '\n',
      encoding='utf-8',
  )
  print(
      f'Generated {baseline_path} with {len(sorted_unique_headers)} unique '
      f'internal headers across {len(sorted_legacy_files)} legacy files.'
  )
  return 0


def check_against_baseline(
    baseline_path: Path,
    file_to_headers: Dict[str, List[str]],
    unique_headers: Set[str],
) -> List[str]:
  """Compares scanned internal headers against the baseline ratchet."""
  if not baseline_path.exists():
    return [f'Baseline file {baseline_path} does not exist.']

  raw_json = '\n'.join(
      line for line in baseline_path.read_text(encoding='utf-8').splitlines()
      if not line.lstrip().startswith('#')
  )
  baseline = json.loads(raw_json)
  allowed_count = int(baseline['total_allowed_internal_headers'])
  allowed_headers = set(baseline['allowed_unique_headers'])
  allowed_files = set(baseline['allowed_legacy_files'].keys())
  errors = []

  if len(unique_headers) > allowed_count:
    errors.append(
        'Monotonic header ratchet violation: found '
        f'{len(unique_headers)} unique internal headers, which exceeds '
        f'allowed maximum {allowed_count}.'
    )

  new_headers = sorted(unique_headers - allowed_headers)
  if new_headers:
    errors.append(f'Unauthorized new internal headers introduced: {new_headers}')

  new_files = sorted(set(file_to_headers.keys()) - allowed_files)
  if new_files:
    errors.append(f'Unauthorized new files including internal headers: {new_files}')
  return errors


def main(argv: List[str]) -> int:
  """Entry point for the Android embedder dependency ratchet check."""
  flutter_dir = Path(__file__).resolve().parent.parent
  android_dir = flutter_dir / 'shell' / 'platform' / 'android'
  baseline_path = android_dir / 'allowed_internal_headers.yaml'

  file_to_headers, unique_headers, scan_violations = scan_android_sources(android_dir)
  sorted_unique_headers = sorted(unique_headers)
  sorted_legacy_files = {key: file_to_headers[key] for key in sorted(file_to_headers.keys())}

  if '--generate-baseline' in argv:
    return write_baseline_file(baseline_path, sorted_legacy_files, sorted_unique_headers)

  errors = [
      *verify_build_gn_firewall(android_dir),
      *scan_violations,
      *check_against_baseline(baseline_path, file_to_headers, unique_headers),
  ]

  if errors:
    for err in errors:
      print(f'ERROR: {err}', file=sys.stderr)
    return 1

  print(
      '[PASS] Android Embedder Dependency Ratchet verified: '
      f'{len(sorted_unique_headers)} unique internal headers in legacy files, '
      '0 internal headers in :flutter_embedder_native_src.'
  )
  return 0


if __name__ == '__main__':
  sys.exit(main(sys.argv[1:]))

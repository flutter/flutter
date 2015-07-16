# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Top-level presubmit script for Chromium.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""


_EXCLUDED_PATHS = (
    r"^native_client_sdk/src/build_tools/make_rules.py",
    r"^native_client_sdk/src/build_tools/make_simple.py",
    r"^native_client_sdk/src/tools/.*.mk",
    r"^skia/.*",
    r"^v8/.*",
    r".*MakeFile$",
    r".+_autogen\.h$",
    r".+/pnacl_shim\.c$",
    r"^gpu/config/.*_list_json\.cc$",
    r"^tools/android_stack_parser/.*"
)

_SKY_PATHS = (
    r"^sky/.*",
)

# Fragment of a regular expression that matches C++ and Objective-C++
# implementation files.
_IMPLEMENTATION_EXTENSIONS = r'\.(cc|cpp|cxx|mm)$'

# Regular expression that matches code only used for test binaries
# (best effort).
_TEST_CODE_EXCLUDED_PATHS = (
    r'.*/(fake_|test_|mock_).+%s' % _IMPLEMENTATION_EXTENSIONS,
    r'.+_test_(base|support|util)%s' % _IMPLEMENTATION_EXTENSIONS,
    r'.+_(app|browser|perf|pixel|unit)?test(_[a-z]+)?%s' %
        _IMPLEMENTATION_EXTENSIONS,
    r'.*/(test|tool(s)?)/.*',
    # Non-production example code.
    r'mojo/examples/.*',
    # Launcher for running iOS tests on the simulator.
    r'testing/iossim/iossim\.mm$',
)

_TEST_ONLY_WARNING = (
    'You might be calling functions intended only for testing from\n'
    'production code.  It is OK to ignore this warning if you know what\n'
    'you are doing, as the heuristics used to detect the situation are\n'
    'not perfect.  The commit queue will not block on this warning.')


_INCLUDE_ORDER_WARNING = (
    'Your #include order seems to be broken. Send mail to\n'
    'marja@chromium.org if this is not the case.')


_BANNED_CPP_FUNCTIONS = (
    # Make sure that gtest's FRIEND_TEST() macro is not used; the
    # FRIEND_TEST_ALL_PREFIXES() macro from base/gtest_prod_util.h should be
    # used instead since that allows for FLAKY_ and DISABLED_ prefixes.
    (
      'FRIEND_TEST(',
      (
       'Chromium code should not use gtest\'s FRIEND_TEST() macro. Include',
       'base/gtest_prod_util.h and use FRIEND_TEST_ALL_PREFIXES() instead.',
      ),
      False,
      (),
    ),
    (
      'ScopedAllowIO',
      (
       'New code should not use ScopedAllowIO. Post a task to the blocking',
       'pool or the FILE thread instead.',
      ),
      True,
      (
        r"^base/process/process_metrics_linux\.cc$",
        r"^mojo/edk/embedder/simple_platform_shared_buffer_posix\.cc$",
      ),
    ),
    (
      'SkRefPtr',
      (
        'The use of SkRefPtr is prohibited. ',
        'Please use skia::RefPtr instead.'
      ),
      True,
      (),
    ),
    (
      'SkAutoRef',
      (
        'The indirect use of SkRefPtr via SkAutoRef is prohibited. ',
        'Please use skia::RefPtr instead.'
      ),
      True,
      (),
    ),
    (
      'SkAutoTUnref',
      (
        'The use of SkAutoTUnref is dangerous because it implicitly ',
        'converts to a raw pointer. Please use skia::RefPtr instead.'
      ),
      True,
      (),
    ),
    (
      'SkAutoUnref',
      (
        'The indirect use of SkAutoTUnref through SkAutoUnref is dangerous ',
        'because it implicitly converts to a raw pointer. ',
        'Please use skia::RefPtr instead.'
      ),
      True,
      (),
    ),
    (
      r'/HANDLE_EINTR\(.*close',
      (
       'HANDLE_EINTR(close) is invalid. If close fails with EINTR, the file',
       'descriptor will be closed, and it is incorrect to retry the close.',
       'Either call close directly and ignore its return value, or wrap close',
       'in IGNORE_EINTR to use its return value. See http://crbug.com/269623'
      ),
      True,
      (),
    ),
    (
      r'/IGNORE_EINTR\((?!.*close)',
      (
       'IGNORE_EINTR is only valid when wrapping close. To wrap other system',
       'calls, use HANDLE_EINTR. See http://crbug.com/269623',
      ),
      True,
      (
        # Files that #define IGNORE_EINTR.
        r'^base/posix/eintr_wrapper\.h$',
      ),
    ),
    (
      r'/v8::Extension\(',
      (
        'Do not introduce new v8::Extensions into the code base, use',
        'gin::Wrappable instead. See http://crbug.com/334679',
      ),
      True,
      (),
    ),
)


_VALID_OS_MACROS = (
    # Please keep sorted.
    'OS_ANDROID',
    'OS_ANDROID_HOST',
    'OS_BSD',
    'OS_CAT',       # For testing.
    'OS_CHROMEOS',
    'OS_FREEBSD',
    'OS_IOS',
    'OS_LINUX',
    'OS_MACOSX',
    'OS_NACL',
    'OS_OPENBSD',
    'OS_POSIX',
    'OS_QNX',
    'OS_SOLARIS',
    'OS_WIN',
)


def _CheckNoProductionCodeUsingTestOnlyFunctions(input_api, output_api):
  """Attempts to prevent use of functions intended only for testing in
  non-testing code. For now this is just a best-effort implementation
  that ignores header files and may have some false positives. A
  better implementation would probably need a proper C++ parser.
  """
  # We only scan .cc files and the like, as the declaration of
  # for-testing functions in header files are hard to distinguish from
  # calls to such functions without a proper C++ parser.
  file_inclusion_pattern = r'.+%s' % _IMPLEMENTATION_EXTENSIONS

  base_function_pattern = r'[ :]test::[^\s]+|ForTest(ing)?|for_test(ing)?'
  inclusion_pattern = input_api.re.compile(r'(%s)\s*\(' % base_function_pattern)
  comment_pattern = input_api.re.compile(r'//.*(%s)' % base_function_pattern)
  exclusion_pattern = input_api.re.compile(
    r'::[A-Za-z0-9_]+(%s)|(%s)[^;]+\{' % (
      base_function_pattern, base_function_pattern))

  def FilterFile(affected_file):
    black_list = (_EXCLUDED_PATHS +
                  _TEST_CODE_EXCLUDED_PATHS +
                  input_api.DEFAULT_BLACK_LIST)
    return input_api.FilterSourceFile(
      affected_file,
      white_list=(file_inclusion_pattern, ),
      black_list=black_list)

  problems = []
  for f in input_api.AffectedSourceFiles(FilterFile):
    local_path = f.LocalPath()
    for line_number, line in f.ChangedContents():
      if (inclusion_pattern.search(line) and
          not comment_pattern.search(line) and
          not exclusion_pattern.search(line)):
        problems.append(
          '%s:%d\n    %s' % (local_path, line_number, line.strip()))

  if problems:
    return [output_api.PresubmitPromptOrNotify(_TEST_ONLY_WARNING, problems)]
  else:
    return []


def _CheckNoIOStreamInHeaders(input_api, output_api):
  """Checks to make sure no .h files include <iostream>."""
  files = []
  pattern = input_api.re.compile(r'^#include\s*<iostream>',
                                 input_api.re.MULTILINE)
  for f in input_api.AffectedSourceFiles(input_api.FilterSourceFile):
    if not f.LocalPath().endswith('.h'):
      continue
    contents = input_api.ReadFile(f)
    if pattern.search(contents):
      files.append(f)

  if len(files):
    return [ output_api.PresubmitError(
        'Do not #include <iostream> in header files, since it inserts static '
        'initialization into every file including the header. Instead, '
        '#include <ostream>. See http://crbug.com/94794',
        files) ]
  return []


def _CheckNoUNIT_TESTInSourceFiles(input_api, output_api):
  """Checks to make sure no source files use UNIT_TEST"""
  problems = []
  for f in input_api.AffectedFiles():
    if (not f.LocalPath().endswith(('.cc', '.mm'))):
      continue

    for line_num, line in f.ChangedContents():
      if 'UNIT_TEST ' in line or line.endswith('UNIT_TEST'):
        problems.append('    %s:%d' % (f.LocalPath(), line_num))

  if not problems:
    return []
  return [output_api.PresubmitPromptWarning('UNIT_TEST is only for headers.\n' +
      '\n'.join(problems))]


def _CheckNoNewWStrings(input_api, output_api):
  """Checks to make sure we don't introduce use of wstrings."""
  problems = []
  for f in input_api.AffectedFiles():
    if (not f.LocalPath().endswith(('.cc', '.h')) or
        f.LocalPath().endswith(('test.cc', '_win.cc', '_win.h'))):
      continue

    allowWString = False
    for line_num, line in f.ChangedContents():
      if 'presubmit: allow wstring' in line:
        allowWString = True
      elif not allowWString and 'wstring' in line:
        problems.append('    %s:%d' % (f.LocalPath(), line_num))
        allowWString = False
      else:
        allowWString = False

  if not problems:
    return []
  return [output_api.PresubmitPromptWarning('New code should not use wstrings.'
      '  If you are calling a cross-platform API that accepts a wstring, '
      'fix the API.\n' +
      '\n'.join(problems))]


def _CheckNoDEPSGIT(input_api, output_api):
  """Make sure .DEPS.git is never modified manually."""
  if any(f.LocalPath().endswith('.DEPS.git') for f in
      input_api.AffectedFiles()):
    return [output_api.PresubmitError(
      'Never commit changes to .DEPS.git. This file is maintained by an\n'
      'automated system based on what\'s in DEPS and your changes will be\n'
      'overwritten.\n'
      'See https://sites.google.com/a/chromium.org/dev/developers/how-tos/get-the-code#Rolling_DEPS\n'
      'for more information')]
  return []


def _CheckValidHostsInDEPS(input_api, output_api):
  """Checks that DEPS file deps are from allowed_hosts."""
  # Run only if DEPS file has been modified to annoy fewer bystanders.
  if all(f.LocalPath() != 'DEPS' for f in input_api.AffectedFiles()):
    return []
  # Outsource work to gclient verify
  try:
    input_api.subprocess.check_output(['gclient', 'verify'])
    return []
  except input_api.subprocess.CalledProcessError, error:
    return [output_api.PresubmitError(
        'DEPS file must have only git dependencies.',
        long_text=error.output)]


def _CheckNoBannedFunctions(input_api, output_api):
  """Make sure that banned functions are not used."""
  warnings = []
  errors = []

  file_filter = lambda f: f.LocalPath().endswith(('.cc', '.mm', '.h'))
  for f in input_api.AffectedFiles(file_filter=file_filter):
    for line_num, line in f.ChangedContents():
      for func_name, message, error, excluded_paths in _BANNED_CPP_FUNCTIONS:
        def IsBlacklisted(affected_file, blacklist):
          local_path = affected_file.LocalPath()
          for item in blacklist:
            if input_api.re.match(item, local_path):
              return True
          return False
        if IsBlacklisted(f, excluded_paths):
          continue
        matched = False
        if func_name[0:1] == '/':
          regex = func_name[1:]
          if input_api.re.search(regex, line):
            matched = True
        elif func_name in line:
            matched = True
        if matched:
          problems = warnings;
          if error:
            problems = errors;
          problems.append('    %s:%d:' % (f.LocalPath(), line_num))
          for message_line in message:
            problems.append('      %s' % message_line)

  result = []
  if (warnings):
    result.append(output_api.PresubmitPromptWarning(
        'Banned functions were used.\n' + '\n'.join(warnings)))
  if (errors):
    result.append(output_api.PresubmitError(
        'Banned functions were used.\n' + '\n'.join(errors)))
  return result


def _CheckNoPragmaOnce(input_api, output_api):
  """Make sure that banned functions are not used."""
  files = []
  pattern = input_api.re.compile(r'^#pragma\s+once',
                                 input_api.re.MULTILINE)
  for f in input_api.AffectedSourceFiles(input_api.FilterSourceFile):
    if not f.LocalPath().endswith('.h'):
      continue
    contents = input_api.ReadFile(f)
    if pattern.search(contents):
      files.append(f)

  if files:
    return [output_api.PresubmitError(
        'Do not use #pragma once in header files.\n'
        'See http://www.chromium.org/developers/coding-style#TOC-File-headers',
        files)]
  return []


def _CheckNoTrinaryTrueFalse(input_api, output_api):
  """Checks to make sure we don't introduce use of foo ? true : false."""
  problems = []
  pattern = input_api.re.compile(r'\?\s*(true|false)\s*:\s*(true|false)')
  for f in input_api.AffectedFiles():
    if not f.LocalPath().endswith(('.cc', '.h', '.inl', '.m', '.mm')):
      continue

    for line_num, line in f.ChangedContents():
      if pattern.match(line):
        problems.append('    %s:%d' % (f.LocalPath(), line_num))

  if not problems:
    return []
  return [output_api.PresubmitPromptWarning(
      'Please consider avoiding the "? true : false" pattern if possible.\n' +
      '\n'.join(problems))]


def _CheckFilePermissions(input_api, output_api):
  """Check that all files have their permissions properly set."""
  if input_api.platform == 'win32':
    return []
  args = [input_api.python_executable, 'tools/checkperms/checkperms.py',
          '--root', input_api.change.RepositoryRoot()]
  for f in input_api.AffectedFiles():
    args += ['--file', f.LocalPath()]
  checkperms = input_api.subprocess.Popen(args,
                                          stdout=input_api.subprocess.PIPE)
  errors = checkperms.communicate()[0].strip()
  if errors:
    return [output_api.PresubmitError('checkperms.py failed.',
                                      errors.splitlines())]
  return []


def _CheckIncludeOrderForScope(scope, input_api, file_path, changed_linenums):
  """Checks that the lines in scope occur in the right order.

  1. C system files in alphabetical order
  2. C++ system files in alphabetical order
  3. Project's .h files
  """

  c_system_include_pattern = input_api.re.compile(r'\s*#include <.*\.h>')
  cpp_system_include_pattern = input_api.re.compile(r'\s*#include <.*>')
  custom_include_pattern = input_api.re.compile(r'\s*#include ".*')

  C_SYSTEM_INCLUDES, CPP_SYSTEM_INCLUDES, CUSTOM_INCLUDES = range(3)

  state = C_SYSTEM_INCLUDES

  previous_line = ''
  previous_line_num = 0
  problem_linenums = []
  for line_num, line in scope:
    if c_system_include_pattern.match(line):
      if state != C_SYSTEM_INCLUDES:
        problem_linenums.append((line_num, previous_line_num))
      elif previous_line and previous_line > line:
        problem_linenums.append((line_num, previous_line_num))
    elif cpp_system_include_pattern.match(line):
      if state == C_SYSTEM_INCLUDES:
        state = CPP_SYSTEM_INCLUDES
      elif state == CUSTOM_INCLUDES:
        problem_linenums.append((line_num, previous_line_num))
      elif previous_line and previous_line > line:
        problem_linenums.append((line_num, previous_line_num))
    elif custom_include_pattern.match(line):
      if state != CUSTOM_INCLUDES:
        state = CUSTOM_INCLUDES
      elif previous_line and previous_line > line:
        problem_linenums.append((line_num, previous_line_num))
    else:
      problem_linenums.append(line_num)
    previous_line = line
    previous_line_num = line_num

  warnings = []
  for (line_num, previous_line_num) in problem_linenums:
    if line_num in changed_linenums or previous_line_num in changed_linenums:
      warnings.append('    %s:%d' % (file_path, line_num))
  return warnings


def _CheckIncludeOrderInFile(input_api, f, changed_linenums):
  """Checks the #include order for the given file f."""

  system_include_pattern = input_api.re.compile(r'\s*#include \<.*')
  # Exclude the following includes from the check:
  # 1) #include <.../...>, e.g., <sys/...> includes often need to appear in a
  # specific order.
  # 2) <atlbase.h>, "build/build_config.h"
  excluded_include_pattern = input_api.re.compile(
      r'\s*#include (\<.*/.*|\<atlbase\.h\>|"build/build_config.h")')
  custom_include_pattern = input_api.re.compile(r'\s*#include "(?P<FILE>.*)"')
  # Match the final or penultimate token if it is xxxtest so we can ignore it
  # when considering the special first include.
  test_file_tag_pattern = input_api.re.compile(
    r'_[a-z]+test(?=(_[a-zA-Z0-9]+)?\.)')
  if_pattern = input_api.re.compile(
      r'\s*#\s*(if|elif|else|endif|define|undef).*')
  # Some files need specialized order of includes; exclude such files from this
  # check.
  uncheckable_includes_pattern = input_api.re.compile(
      r'\s*#include '
      '("ipc/.*macros\.h"|<windows\.h>|".*gl.*autogen.h")\s*')

  contents = f.NewContents()
  warnings = []
  line_num = 0

  # Handle the special first include. If the first include file is
  # some/path/file.h, the corresponding including file can be some/path/file.cc,
  # some/other/path/file.cc, some/path/file_platform.cc, some/path/file-suffix.h
  # etc. It's also possible that no special first include exists.
  # If the included file is some/path/file_platform.h the including file could
  # also be some/path/file_xxxtest_platform.h.
  including_file_base_name = test_file_tag_pattern.sub(
    '', input_api.os_path.basename(f.LocalPath()))

  for line in contents:
    line_num += 1
    if system_include_pattern.match(line):
      # No special first include -> process the line again along with normal
      # includes.
      line_num -= 1
      break
    match = custom_include_pattern.match(line)
    if match:
      match_dict = match.groupdict()
      header_basename = test_file_tag_pattern.sub(
        '', input_api.os_path.basename(match_dict['FILE'])).replace('.h', '')

      if header_basename not in including_file_base_name:
        # No special first include -> process the line again along with normal
        # includes.
        line_num -= 1
      break

  # Split into scopes: Each region between #if and #endif is its own scope.
  scopes = []
  current_scope = []
  for line in contents[line_num:]:
    line_num += 1
    if uncheckable_includes_pattern.match(line):
      continue
    if if_pattern.match(line):
      scopes.append(current_scope)
      current_scope = []
    elif ((system_include_pattern.match(line) or
           custom_include_pattern.match(line)) and
          not excluded_include_pattern.match(line)):
      current_scope.append((line_num, line))
  scopes.append(current_scope)

  for scope in scopes:
    warnings.extend(_CheckIncludeOrderForScope(scope, input_api, f.LocalPath(),
                                               changed_linenums))
  return warnings


def _CheckIncludeOrder(input_api, output_api):
  """Checks that the #include order is correct.

  1. The corresponding header for source files.
  2. C system files in alphabetical order
  3. C++ system files in alphabetical order
  4. Project's .h files in alphabetical order

  Each region separated by #if, #elif, #else, #endif, #define and #undef follows
  these rules separately.
  """
  def FileFilterIncludeOrder(affected_file):
    black_list = (_EXCLUDED_PATHS + input_api.DEFAULT_BLACK_LIST)
    return input_api.FilterSourceFile(affected_file, black_list=black_list)

  warnings = []
  for f in input_api.AffectedFiles(file_filter=FileFilterIncludeOrder):
    if f.LocalPath().endswith(('.cc', '.h')):
      changed_linenums = set(line_num for line_num, _ in f.ChangedContents())
      warnings.extend(_CheckIncludeOrderInFile(input_api, f, changed_linenums))

  results = []
  if warnings:
    results.append(output_api.PresubmitPromptOrNotify(_INCLUDE_ORDER_WARNING,
                                                      warnings))
  return results


def _CheckForVersionControlConflictsInFile(input_api, f):
  pattern = input_api.re.compile('^(?:<<<<<<<|>>>>>>>) |^=======$')
  errors = []
  for line_num, line in f.ChangedContents():
    if pattern.match(line):
      errors.append('    %s:%d %s' % (f.LocalPath(), line_num, line))
  return errors


def _CheckForVersionControlConflicts(input_api, output_api):
  """Usually this is not intentional and will cause a compile failure."""
  errors = []
  for f in input_api.AffectedFiles():
    errors.extend(_CheckForVersionControlConflictsInFile(input_api, f))

  results = []
  if errors:
    results.append(output_api.PresubmitError(
      'Version control conflict markers found, please resolve.', errors))
  return results


def _CheckHardcodedGoogleHostsInLowerLayers(input_api, output_api):
  def FilterFile(affected_file):
    """Filter function for use with input_api.AffectedSourceFiles,
    below.  This filters out everything except non-test files from
    top-level directories that generally speaking should not hard-code
    service URLs (e.g. src/android_webview/, src/content/ and others).
    """
    return input_api.FilterSourceFile(
      affected_file,
      white_list=(r'^base/.*', ),
      black_list=(_EXCLUDED_PATHS +
                  _TEST_CODE_EXCLUDED_PATHS +
                  input_api.DEFAULT_BLACK_LIST))

  base_pattern = '"[^"]*google\.com[^"]*"'
  comment_pattern = input_api.re.compile('//.*%s' % base_pattern)
  pattern = input_api.re.compile(base_pattern)
  problems = []  # items are (filename, line_number, line)
  for f in input_api.AffectedSourceFiles(FilterFile):
    for line_num, line in f.ChangedContents():
      if not comment_pattern.search(line) and pattern.search(line):
        problems.append((f.LocalPath(), line_num, line))

  if problems:
    return [output_api.PresubmitPromptOrNotify(
        'Most layers below src/chrome/ should not hardcode service URLs.\n'
        'Are you sure this is correct?',
        ['  %s:%d:  %s' % (
            problem[0], problem[1], problem[2]) for problem in problems])]
  else:
    return []


def _CheckNoAbbreviationInPngFileName(input_api, output_api):
  """Makes sure there are no abbreviations in the name of PNG files.
  """
  pattern = input_api.re.compile(r'.*_[a-z]_.*\.png$|.*_[a-z]\.png$')
  errors = []
  for f in input_api.AffectedFiles(include_deletes=False):
    if pattern.match(f.LocalPath()):
      errors.append('    %s' % f.LocalPath())

  results = []
  if errors:
    results.append(output_api.PresubmitError(
        'The name of PNG files should not have abbreviations. \n'
        'Use _hover.png, _center.png, instead of _h.png, _c.png.\n'
        'Contact oshima@chromium.org if you have questions.', errors))
  return results


def _CheckSpamLogging(input_api, output_api):
  file_inclusion_pattern = r'.+%s' % _IMPLEMENTATION_EXTENSIONS
  black_list = (_EXCLUDED_PATHS +
                _TEST_CODE_EXCLUDED_PATHS +
                input_api.DEFAULT_BLACK_LIST +
                (r"^base/logging\.h$",
                 r"^base/logging\.cc$",
                 r"^examples/wget/wget\.cc$",
                 r"^shell/application_manager/network_fetcher\.cc$",
                 r"^shell/tracer\.cc$",
                 r"^sandbox/linux/.*",
                 r"^tools/.*"))
  source_file_filter = lambda x: input_api.FilterSourceFile(
      x, white_list=(file_inclusion_pattern,), black_list=black_list)

  log_macro = input_api.re.compile(r"\bD?LOG\s*\(\s*INFO\s*\)")
  log_if_macro = input_api.re.compile(r"\bD?LOG_IF\s*\(\s*INFO\s*,")
  printf_macro = input_api.re.compile(r"\bprintf\(")
  fprintf_macro = input_api.re.compile(r"\bfprintf\((stdout|stderr)")

  log_info = []
  printf = []

  for f in input_api.AffectedSourceFiles(source_file_filter):
    for linenum, line in f.ChangedContents():
      if log_macro.search(line) or log_if_macro.search(line):
        log_info.append(f.LocalPath())
      if printf_macro.search(line) or fprintf_macro.search(line):
        printf.append(f.LocalPath())

  if log_info:
    return [output_api.PresubmitError(
      'These files spam the console log with LOG(INFO):',
      items=log_info)]
  if printf:
    return [output_api.PresubmitError(
      'These files spam the console log with printf/fprintf:',
      items=printf)]
  return []


def _CheckForAnonymousVariables(input_api, output_api):
  """These types are all expected to hold locks while in scope and
     so should never be anonymous (which causes them to be immediately
     destroyed)."""
  they_who_must_be_named = [
    'base::AutoLock',
    'base::AutoReset',
    'base::AutoUnlock',
    'SkAutoAlphaRestore',
    'SkAutoBitmapShaderInstall',
    'SkAutoBlitterChoose',
    'SkAutoBounderCommit',
    'SkAutoCallProc',
    'SkAutoCanvasRestore',
    'SkAutoCommentBlock',
    'SkAutoDescriptor',
    'SkAutoDisableDirectionCheck',
    'SkAutoDisableOvalCheck',
    'SkAutoFree',
    'SkAutoGlyphCache',
    'SkAutoHDC',
    'SkAutoLockColors',
    'SkAutoLockPixels',
    'SkAutoMalloc',
    'SkAutoMaskFreeImage',
    'SkAutoMutexAcquire',
    'SkAutoPathBoundsUpdate',
    'SkAutoPDFRelease',
    'SkAutoRasterClipValidate',
    'SkAutoRef',
    'SkAutoTime',
    'SkAutoTrace',
    'SkAutoUnref',
  ]
  anonymous = r'(%s)\s*[({]' % '|'.join(they_who_must_be_named)
  # bad: base::AutoLock(lock.get());
  # not bad: base::AutoLock lock(lock.get());
  bad_pattern = input_api.re.compile(anonymous)
  # good: new base::AutoLock(lock.get())
  good_pattern = input_api.re.compile(r'\bnew\s*' + anonymous)
  errors = []

  for f in input_api.AffectedFiles():
    if not f.LocalPath().endswith(('.cc', '.h', '.inl', '.m', '.mm')):
      continue
    for linenum, line in f.ChangedContents():
      if bad_pattern.search(line) and not good_pattern.search(line):
        errors.append('%s:%d' % (f.LocalPath(), linenum))

  if errors:
    return [output_api.PresubmitError(
      'These lines create anonymous variables that need to be named:',
      items=errors)]
  return []


def _GetJSONParseError(input_api, filename):
  try:
    contents = input_api.ReadFile(filename)
    input_api.json.loads(contents)
  except ValueError as e:
    return e
  return None


def _CheckParseErrors(input_api, output_api):
  """Check that JSON files do not contain syntax errors."""
  actions = {
    '.json': _GetJSONParseError,
  }
  # These paths contain test data and other known invalid JSON files.
  excluded_patterns = [
    r'test/data/',
  ]
  # Most JSON files are preprocessed and support comments, but these do not.
  json_no_comments_patterns = [
    r'^testing/',
  ]

  def get_action(affected_file):
    filename = affected_file.LocalPath()
    return actions.get(input_api.os_path.splitext(filename)[1])

  def MatchesFile(patterns, path):
    for pattern in patterns:
      if input_api.re.search(pattern, path):
        return True
    return False

  def FilterFile(affected_file):
    action = get_action(affected_file)
    if not action:
      return False
    path = affected_file.LocalPath()

    if MatchesFile(excluded_patterns, path):
      return False
    return True

  results = []
  for affected_file in input_api.AffectedFiles(
      file_filter=FilterFile, include_deletes=False):
    action = get_action(affected_file)
    parse_error = action(input_api, affected_file.AbsoluteLocalPath())
    if parse_error:
      results.append(output_api.PresubmitError('%s could not be parsed: %s' %
          (affected_file.LocalPath(), parse_error)))
  return results


def _CheckJavaStyle(input_api, output_api):
  """Runs checkstyle on changed java files and returns errors if any exist."""
  import sys
  original_sys_path = sys.path
  try:
    sys.path = sys.path + [input_api.os_path.join(
        input_api.PresubmitLocalPath(), 'tools', 'android', 'checkstyle')]
    import checkstyle
  finally:
    # Restore sys.path to what it was before.
    sys.path = original_sys_path

  return checkstyle.RunCheckstyle(
      input_api, output_api, 'tools/android/checkstyle/chromium-style-5.0.xml')


_DEPRECATED_CSS = [
  # Values
  ( "-webkit-box", "flex" ),
  ( "-webkit-inline-box", "inline-flex" ),
  ( "-webkit-flex", "flex" ),
  ( "-webkit-inline-flex", "inline-flex" ),
  ( "-webkit-min-content", "min-content" ),
  ( "-webkit-max-content", "max-content" ),

  # Properties
  ( "-webkit-background-clip", "background-clip" ),
  ( "-webkit-background-origin", "background-origin" ),
  ( "-webkit-background-size", "background-size" ),
  ( "-webkit-box-shadow", "box-shadow" ),

  # Functions
  ( "-webkit-gradient", "gradient" ),
  ( "-webkit-repeating-gradient", "repeating-gradient" ),
  ( "-webkit-linear-gradient", "linear-gradient" ),
  ( "-webkit-repeating-linear-gradient", "repeating-linear-gradient" ),
  ( "-webkit-radial-gradient", "radial-gradient" ),
  ( "-webkit-repeating-radial-gradient", "repeating-radial-gradient" ),
]

def _CheckNoDeprecatedCSS(input_api, output_api):
  """ Make sure that we don't use deprecated CSS
      properties, functions or values. Our external
      documentation is ignored by the hooks as it
      needs to be consumed by WebKit. """
  results = []
  file_inclusion_pattern = (r".+\.css$")
  black_list = (_EXCLUDED_PATHS +
                _TEST_CODE_EXCLUDED_PATHS +
                input_api.DEFAULT_BLACK_LIST +
                (r"^chrome/common/extensions/docs",
                 r"^chrome/docs",
                 r"^native_client_sdk"))
  file_filter = lambda f: input_api.FilterSourceFile(
      f, white_list=file_inclusion_pattern, black_list=black_list)
  for fpath in input_api.AffectedFiles(file_filter=file_filter):
    for line_num, line in fpath.ChangedContents():
      for (deprecated_value, value) in _DEPRECATED_CSS:
        if input_api.re.search(deprecated_value, line):
          results.append(output_api.PresubmitError(
              "%s:%d: Use of deprecated CSS %s, use %s instead" %
              (fpath.LocalPath(), line_num, deprecated_value, value)))
  return results


def _CheckForOverrideAndFinalRules(input_api, output_api):
  """Checks for final and override used as per C++11"""
  problems = []
  for f in input_api.AffectedFiles():
    if (f.LocalPath().endswith(('.cc', '.cpp', '.h', '.mm'))):
      for line_num, line in f.ChangedContents():
        if (input_api.re.search(r'\b(FINAL|OVERRIDE)\b', line)):
          problems.append('    %s:%d' % (f.LocalPath(), line_num))

  if not problems:
    return []
  return [output_api.PresubmitError('Use C++11\'s |final| and |override| '
                                    'rather than FINAL and OVERRIDE.',
                                    problems)]


def _CommonChecks(input_api, output_api):
  """Checks common to both upload and commit."""
  results = []
  results.extend(input_api.canned_checks.PanProjectChecks(
      input_api, output_api, excluded_paths=_EXCLUDED_PATHS + _SKY_PATHS))
  results.extend(_CheckAuthorizedAuthor(input_api, output_api))
  results.extend(
      _CheckNoProductionCodeUsingTestOnlyFunctions(input_api, output_api))
  results.extend(_CheckNoIOStreamInHeaders(input_api, output_api))
  results.extend(_CheckNoUNIT_TESTInSourceFiles(input_api, output_api))
  results.extend(_CheckNoNewWStrings(input_api, output_api))
  results.extend(_CheckNoDEPSGIT(input_api, output_api))
  results.extend(_CheckNoBannedFunctions(input_api, output_api))
  results.extend(_CheckNoPragmaOnce(input_api, output_api))
  results.extend(_CheckNoTrinaryTrueFalse(input_api, output_api))
  results.extend(_CheckFilePermissions(input_api, output_api))
  results.extend(_CheckIncludeOrder(input_api, output_api))
  results.extend(_CheckForVersionControlConflicts(input_api, output_api))
  results.extend(_CheckPatchFiles(input_api, output_api))
  results.extend(_CheckHardcodedGoogleHostsInLowerLayers(input_api, output_api))
  results.extend(_CheckNoAbbreviationInPngFileName(input_api, output_api))
  results.extend(_CheckForInvalidOSMacros(input_api, output_api))
  results.extend(_CheckForInvalidIfDefinedMacros(input_api, output_api))
  # TODO(danakj): Remove this when base/move.h is removed.
  results.extend(_CheckForUsingSideEffectsOfPass(input_api, output_api))
  results.extend(
      input_api.canned_checks.CheckChangeHasNoTabs(
          input_api,
          output_api,
          source_file_filter=lambda x: x.LocalPath().endswith('.grd')))
  results.extend(_CheckSpamLogging(input_api, output_api))
  results.extend(_CheckForAnonymousVariables(input_api, output_api))
  results.extend(_CheckNoDeprecatedCSS(input_api, output_api))
  results.extend(_CheckParseErrors(input_api, output_api))
  results.extend(_CheckForOverrideAndFinalRules(input_api, output_api))

  if any('PRESUBMIT.py' == f.LocalPath() for f in input_api.AffectedFiles()):
    results.extend(input_api.canned_checks.RunUnitTestsInDirectory(
        input_api, output_api,
        input_api.PresubmitLocalPath(),
        whitelist=[r'^PRESUBMIT_test\.py$']))
  return results


def _CheckAuthorizedAuthor(input_api, output_api):
  """For non-googler/chromites committers, verify the author's email address is
  in AUTHORS.
  """
  # TODO(maruel): Add it to input_api?
  import fnmatch

  author = input_api.change.author_email
  if not author:
    input_api.logging.info('No author, skipping AUTHOR check')
    return []
  authors_path = input_api.os_path.join(
      input_api.PresubmitLocalPath(), 'AUTHORS')
  valid_authors = (
      input_api.re.match(r'[^#]+\s+\<(.+?)\>\s*$', line)
      for line in open(authors_path))
  valid_authors = [item.group(1).lower() for item in valid_authors if item]
  if not any(fnmatch.fnmatch(author.lower(), valid) for valid in valid_authors):
    input_api.logging.info('Valid authors are %s', ', '.join(valid_authors))
    return [output_api.PresubmitPromptWarning(
        ('%s is not in AUTHORS file. If you are a new contributor, please visit'
        '\n'
        'http://www.chromium.org/developers/contributing-code and read the '
        '"Legal" section\n'
        'If you are a chromite, verify the contributor signed the CLA.') %
        author)]
  return []


def _CheckPatchFiles(input_api, output_api):
  problems = [f.LocalPath() for f in input_api.AffectedFiles()
      if f.LocalPath().endswith(('.orig', '.rej'))]
  if problems:
    return [output_api.PresubmitError(
        "Don't commit .rej and .orig files.", problems)]
  else:
    return []


def _DidYouMeanOSMacro(bad_macro):
  try:
    return {'A': 'OS_ANDROID',
            'B': 'OS_BSD',
            'C': 'OS_CHROMEOS',
            'F': 'OS_FREEBSD',
            'L': 'OS_LINUX',
            'M': 'OS_MACOSX',
            'N': 'OS_NACL',
            'O': 'OS_OPENBSD',
            'P': 'OS_POSIX',
            'S': 'OS_SOLARIS',
            'W': 'OS_WIN'}[bad_macro[3].upper()]
  except KeyError:
    return ''


def _CheckForInvalidOSMacrosInFile(input_api, f):
  """Check for sensible looking, totally invalid OS macros."""
  preprocessor_statement = input_api.re.compile(r'^\s*#')
  os_macro = input_api.re.compile(r'defined\((OS_[^)]+)\)')
  results = []
  for lnum, line in f.ChangedContents():
    if preprocessor_statement.search(line):
      for match in os_macro.finditer(line):
        if not match.group(1) in _VALID_OS_MACROS:
          good = _DidYouMeanOSMacro(match.group(1))
          did_you_mean = ' (did you mean %s?)' % good if good else ''
          results.append('    %s:%d %s%s' % (f.LocalPath(),
                                             lnum,
                                             match.group(1),
                                             did_you_mean))
  return results


def _CheckForInvalidOSMacros(input_api, output_api):
  """Check all affected files for invalid OS macros."""
  bad_macros = []
  for f in input_api.AffectedFiles():
    if not f.LocalPath().endswith(('.py', '.js', '.html', '.css')):
      bad_macros.extend(_CheckForInvalidOSMacrosInFile(input_api, f))

  if not bad_macros:
    return []

  return [output_api.PresubmitError(
      'Possibly invalid OS macro[s] found. Please fix your code\n'
      'or add your macro to src/PRESUBMIT.py.', bad_macros)]


def _CheckForInvalidIfDefinedMacrosInFile(input_api, f):
  """Check all affected files for invalid "if defined" macros."""
  ALWAYS_DEFINED_MACROS = (
      "TARGET_CPU_PPC",
      "TARGET_CPU_PPC64",
      "TARGET_CPU_68K",
      "TARGET_CPU_X86",
      "TARGET_CPU_ARM",
      "TARGET_CPU_MIPS",
      "TARGET_CPU_SPARC",
      "TARGET_CPU_ALPHA",
      "TARGET_IPHONE_SIMULATOR",
      "TARGET_OS_EMBEDDED",
      "TARGET_OS_IPHONE",
      "TARGET_OS_MAC",
      "TARGET_OS_UNIX",
      "TARGET_OS_WIN32",
  )
  ifdef_macro = input_api.re.compile(r'^\s*#.*(?:ifdef\s|defined\()([^\s\)]+)')
  results = []
  for lnum, line in f.ChangedContents():
    for match in ifdef_macro.finditer(line):
      if match.group(1) in ALWAYS_DEFINED_MACROS:
        always_defined = ' %s is always defined. ' % match.group(1)
        did_you_mean = 'Did you mean \'#if %s\'?' % match.group(1)
        results.append('    %s:%d %s\n\t%s' % (f.LocalPath(),
                                               lnum,
                                               always_defined,
                                               did_you_mean))
  return results


def _CheckForInvalidIfDefinedMacros(input_api, output_api):
  """Check all affected files for invalid "if defined" macros."""
  bad_macros = []
  for f in input_api.AffectedFiles():
    if f.LocalPath().endswith(('.h', '.c', '.cc', '.m', '.mm')):
      bad_macros.extend(_CheckForInvalidIfDefinedMacrosInFile(input_api, f))

  if not bad_macros:
    return []

  return [output_api.PresubmitError(
      'Found ifdef check on always-defined macro[s]. Please fix your code\n'
      'or check the list of ALWAYS_DEFINED_MACROS in src/PRESUBMIT.py.',
      bad_macros)]


def _CheckForUsingSideEffectsOfPass(input_api, output_api):
  """Check all affected files for using side effects of Pass."""
  errors = []
  for f in input_api.AffectedFiles():
    if f.LocalPath().endswith(('.h', '.c', '.cc', '.m', '.mm')):
      for lnum, line in f.ChangedContents():
        # Disallow Foo(*my_scoped_thing.Pass()); See crbug.com/418297.
        if input_api.re.search(r'\*[a-zA-Z0-9_]+\.Pass\(\)', line):
          errors.append(output_api.PresubmitError(
            ('%s:%d uses *foo.Pass() to delete the contents of scoped_ptr. ' +
             'See crbug.com/418297.') % (f.LocalPath(), lnum)))
  return errors


def CheckChangeOnUpload(input_api, output_api):
  results = []
  results.extend(_CommonChecks(input_api, output_api))
  results.extend(_CheckValidHostsInDEPS(input_api, output_api))
  results.extend(_CheckJavaStyle(input_api, output_api))
  results.extend(
      input_api.canned_checks.CheckGNFormatted(input_api, output_api))
  return results


def GetDefaultTryConfigs(bots=None):
  """Returns a list of ('bot', set(['tests']), optionally filtered by [bots].

  If 'bots' is specified, will only return configurations for bots in that list.
  """

  builders_and_tests = {
      'Mojo Android Builder (dbg) Try': ['defaulttests'],
      'Mojo Android Builder Try': ['defaulttests'],
      'Mojo Android Builder Tests (dbg) Try': ['defaulttests'],
      'Mojo Linux (dbg) Try': ['defaulttests'],
      'Mojo Linux ASan Try': ['defaulttests'],
      'Mojo Linux Try': ['defaulttests'],
  }

  if bots:
    filtered_builders_and_tests = dict((bot, set(builders_and_tests[bot]))
                                       for bot in bots)
  else:
    filtered_builders_and_tests = dict(
        (bot, set(tests))
        for bot, tests in builders_and_tests.iteritems())

  # Build up the mapping from tryserver master to bot/test.
  out = dict()
  for bot, tests in filtered_builders_and_tests.iteritems():
    out.setdefault("tryserver.client.mojo", {})[bot] = tests
  return out


def CheckChangeOnCommit(input_api, output_api):
  results = []
  results.extend(_CommonChecks(input_api, output_api))
  results.extend(input_api.canned_checks.CheckChangeHasBugField(
      input_api, output_api))
  results.extend(input_api.canned_checks.CheckChangeHasDescription(
      input_api, output_api))
  return results


def GetPreferredTryMasters(project, change):
  import re
  files = change.LocalPaths()

  if not files:
    return {}

  builders = [
      'Mojo Android Builder (dbg) Try',
      'Mojo Android Builder Try',
      'Mojo Android Builder Tests (dbg) Try',
      'Mojo Linux (dbg) Try',
      'Mojo Linux ASan Try',
      'Mojo Linux Try',
  ]

  return GetDefaultTryConfigs(builders)

def PostUploadHook(cl, change, output_api):
  import subprocess
  subprocess.check_call(["git", "cl", "try"])
  return []

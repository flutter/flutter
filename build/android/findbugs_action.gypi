
{
  'action_name': 'findbugs_<(_target_name)',
  'message': 'Running findbugs on <(_target_name)',
  'variables': {
  },
  'inputs': [
    '<(DEPTH)/build/android/findbugs_diff.py',
    '<(DEPTH)/build/android/findbugs_filter/findbugs_exclude.xml',
    '<(DEPTH)/build/android/pylib/utils/findbugs.py',
    '<(findbugs_target_jar_path)',
  ],
  'outputs': [
    '<(stamp_path)',
  ],
  'action': [
    'python', '<(DEPTH)/build/android/findbugs_diff.py',
    '--auxclasspath-gyp', '>(auxclasspath)',
    '--stamp', '<(stamp_path)',
    '<(findbugs_target_jar_path)',
  ],
}

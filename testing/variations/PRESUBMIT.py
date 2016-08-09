# Copyright 2015 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Presubmit script validating field trial configs.

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details on the presubmit API built into depot_tools.
"""

def ValidateData(json_data, file_path, message_type):
  """Validates the format of a fieldtrial configuration.

  Args:
    json_data: Parsed JSON object representing the fieldtrial config.
    file_path: String representing the path to the JSON file.
    message_type: Type of message from |output_api| to return in the case of
        errors/warnings.

  Returns:
    A list of |message_type| messages. In the case of all tests passing with no
    warnings/errors, this will return [].
  """
  if not isinstance(json_data, dict):
    return [message_type(
        'Malformed config file %s: Expecting dict' % file_path)]
  for (study, groups) in json_data.iteritems():
    if not isinstance(study, unicode):
      return [message_type(
          'Malformed config file %s: Expecting keys to be string, got %s'
          % (file_path, type(study)))]
    if not isinstance(groups, list):
      return [message_type(
          'Malformed config file %s: Expecting list for study %s'
          % (file_path, study))]
    for group in groups:
      if not isinstance(group, dict):
        return [message_type(
            'Malformed config file %s: Expecting dict for group in '
            'Study[%s]' % (file_path, study))]
      if not 'group_name' in group or not isinstance(group['group_name'],
          unicode):
        return [message_type(
            'Malformed config file %s: Missing valid group_name for group'
            ' in Study[%s]' % (file_path, study))]
      if 'params' in group:
        params = group['params']
        if not isinstance(params, dict):
          return [message_type(
              'Malformed config file %s: Invalid params for Group[%s]'
              ' in Study[%s]' % (file_path, group['group_name'],
              study))]
        for (key, value) in params.iteritems():
          if not isinstance(key, unicode) or not isinstance(value,
              unicode):
            return [message_type(
                'Malformed config file %s: Invalid params for Group[%s]'
                ' in Study[%s]' % (file_path, group['group_name'],
                study))]
  return []

def CommonChecks(input_api, output_api):
  affected_files = input_api.AffectedFiles(
      include_deletes=False,
      file_filter=lambda x: x.LocalPath().endswith('.json'))
  for f in affected_files:
    contents = input_api.ReadFile(f)
    try:
      json_data = input_api.json.loads(contents)
      result =  ValidateData(json_data, f.LocalPath(),
          output_api.PresubmitError)
      if len(result):
        return result
    except ValueError:
      return [output_api.PresubmitError(
          'Malformed JSON file: %s' % f.LocalPath())]
  return []

def CheckChangeOnUpload(input_api, output_api):
  return CommonChecks(input_api, output_api)

def CheckChangeOnCommit(input_api, output_api):
  return CommonChecks(input_api, output_api)

# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


"""A helper module for parsing JSON objects from perf tests results."""

import json


def GetAverageRunInfo(json_data, name):
  """Summarizes TraceEvent JSON data for performance metrics.

  Example JSON Inputs (More tags can be added but these are required):
  Measuring Duration:
  [
    { "cat": "Java",
      "ts": 10000000000,
      "ph": "S",
      "name": "TestTrace"
    },
    { "cat": "Java",
      "ts": 10000004000,
      "ph": "F",
      "name": "TestTrace"
    },
    ...
  ]

  Measuring Call Frequency (FPS):
  [
    { "cat": "Java",
      "ts": 10000000000,
      "ph": "I",
      "name": "TestTraceFPS"
    },
    { "cat": "Java",
      "ts": 10000004000,
      "ph": "I",
      "name": "TestTraceFPS"
    },
    ...
  ]

  Args:
    json_data: A list of dictonaries each representing a JSON object.
    name: The 'name' tag to filter on in the JSON file.

  Returns:
    A dictionary of result data with the following tags:
      min: The minimum value tracked.
      max: The maximum value tracked.
      average: The average of all the values tracked.
      count: The number of times the category/name pair was tracked.
      type: The type of tracking ('Instant' for instant tags and 'Span' for
            begin/end tags.
      category: The passed in category filter.
      name: The passed in name filter.
      data_points: A list of all of the times used to generate this data.
      units: The units for the values being reported.

  Raises:
    Exception: if entry contains invalid data.
  """

  def EntryFilter(entry):
    return entry['cat'] == 'Java' and entry['name'] == name
  filtered_entries = filter(EntryFilter, json_data)

  result = {}

  result['min'] = -1
  result['max'] = -1
  result['average'] = 0
  result['count'] = 0
  result['type'] = 'Unknown'
  result['category'] = 'Java'
  result['name'] = name
  result['data_points'] = []
  result['units'] = ''

  total_sum = 0

  last_val = 0
  val_type = None
  for entry in filtered_entries:
    if not val_type:
      if 'mem' in entry:
        val_type = 'mem'

        def GetVal(entry):
          return entry['mem']

        result['units'] = 'kb'
      elif 'ts' in entry:
        val_type = 'ts'

        def GetVal(entry):
          return float(entry['ts']) / 1000.0

        result['units'] = 'ms'
      else:
        raise Exception('Entry did not contain valid value info: %s' % entry)

    if not val_type in entry:
      raise Exception('Entry did not contain expected value type "%s" '
                      'information: %s' % (val_type, entry))
    val = GetVal(entry)
    if (entry['ph'] == 'S' and
        (result['type'] == 'Unknown' or result['type'] == 'Span')):
      result['type'] = 'Span'
      last_val = val
    elif ((entry['ph'] == 'F' and result['type'] == 'Span') or
          (entry['ph'] == 'I' and (result['type'] == 'Unknown' or
                                   result['type'] == 'Instant'))):
      if last_val > 0:
        delta = val - last_val
        if result['min'] == -1 or result['min'] > delta:
          result['min'] = delta
        if result['max'] == -1 or result['max'] < delta:
          result['max'] = delta
        total_sum += delta
        result['count'] += 1
        result['data_points'].append(delta)
      if entry['ph'] == 'I':
        result['type'] = 'Instant'
        last_val = val
  if result['count'] > 0:
    result['average'] = total_sum / result['count']

  return result


def GetAverageRunInfoFromJSONString(json_string, name):
  """Returns the results from GetAverageRunInfo using a JSON string.

  Args:
    json_string: The string containing JSON.
    name: The 'name' tag to filter on in the JSON file.

  Returns:
    See GetAverageRunInfo Returns section.
  """
  return GetAverageRunInfo(json.loads(json_string), name)


def GetAverageRunInfoFromFile(json_file, name):
  """Returns the results from GetAverageRunInfo using a JSON file.

  Args:
    json_file: The path to a JSON file.
    name: The 'name' tag to filter on in the JSON file.

  Returns:
    See GetAverageRunInfo Returns section.
  """
  with open(json_file, 'r') as f:
    data = f.read()
    perf = json.loads(data)

  return GetAverageRunInfo(perf, name)

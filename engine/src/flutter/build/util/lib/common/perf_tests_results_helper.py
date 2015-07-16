# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import re
import sys

import json
import logging
import math

import perf_result_data_type


# Mapping from result type to test output
RESULT_TYPES = {perf_result_data_type.UNIMPORTANT: 'RESULT ',
                perf_result_data_type.DEFAULT: '*RESULT ',
                perf_result_data_type.INFORMATIONAL: '',
                perf_result_data_type.UNIMPORTANT_HISTOGRAM: 'HISTOGRAM ',
                perf_result_data_type.HISTOGRAM: '*HISTOGRAM '}


def _EscapePerfResult(s):
  """Escapes |s| for use in a perf result."""
  return re.sub('[\:|=/#&,]', '_', s)


def FlattenList(values):
  """Returns a simple list without sub-lists."""
  ret = []
  for entry in values:
    if isinstance(entry, list):
      ret.extend(FlattenList(entry))
    else:
      ret.append(entry)
  return ret


def GeomMeanAndStdDevFromHistogram(histogram_json):
  histogram = json.loads(histogram_json)
  # Handle empty histograms gracefully.
  if not 'buckets' in histogram:
    return 0.0, 0.0
  count = 0
  sum_of_logs = 0
  for bucket in histogram['buckets']:
    if 'high' in bucket:
      bucket['mean'] = (bucket['low'] + bucket['high']) / 2.0
    else:
      bucket['mean'] = bucket['low']
    if bucket['mean'] > 0:
      sum_of_logs += math.log(bucket['mean']) * bucket['count']
      count += bucket['count']

  if count == 0:
    return 0.0, 0.0

  sum_of_squares = 0
  geom_mean = math.exp(sum_of_logs / count)
  for bucket in histogram['buckets']:
    if bucket['mean'] > 0:
      sum_of_squares += (bucket['mean'] - geom_mean) ** 2 * bucket['count']
  return geom_mean, math.sqrt(sum_of_squares / count)


def _ValueToString(v):
  # Special case for floats so we don't print using scientific notation.
  if isinstance(v, float):
    return '%f' % v
  else:
    return str(v)


def _MeanAndStdDevFromList(values):
  avg = None
  sd = None
  if len(values) > 1:
    try:
      value = '[%s]' % ','.join([_ValueToString(v) for v in values])
      avg = sum([float(v) for v in values]) / len(values)
      sqdiffs = [(float(v) - avg) ** 2 for v in values]
      variance = sum(sqdiffs) / (len(values) - 1)
      sd = math.sqrt(variance)
    except ValueError:
      value = ', '.join(values)
  else:
    value = values[0]
  return value, avg, sd


def PrintPages(page_list):
  """Prints list of pages to stdout in the format required by perf tests."""
  print 'Pages: [%s]' % ','.join([_EscapePerfResult(p) for p in page_list])


def PrintPerfResult(measurement, trace, values, units,
                    result_type=perf_result_data_type.DEFAULT,
                    print_to_stdout=True):
  """Prints numerical data to stdout in the format required by perf tests.

  The string args may be empty but they must not contain any colons (:) or
  equals signs (=).
  This is parsed by the buildbot using:
  http://src.chromium.org/viewvc/chrome/trunk/tools/build/scripts/slave/process_log_utils.py

  Args:
    measurement: A description of the quantity being measured, e.g. "vm_peak".
        On the dashboard, this maps to a particular graph. Mandatory.
    trace: A description of the particular data point, e.g. "reference".
        On the dashboard, this maps to a particular "line" in the graph.
        Mandatory.
    values: A list of numeric measured values. An N-dimensional list will be
        flattened and treated as a simple list.
    units: A description of the units of measure, e.g. "bytes".
    result_type: Accepts values of perf_result_data_type.ALL_TYPES.
    print_to_stdout: If True, prints the output in stdout instead of returning
        the output to caller.

    Returns:
      String of the formated perf result.
  """
  assert perf_result_data_type.IsValidType(result_type), \
         'result type: %s is invalid' % result_type

  trace_name = _EscapePerfResult(trace)

  if (result_type == perf_result_data_type.UNIMPORTANT or
      result_type == perf_result_data_type.DEFAULT or
      result_type == perf_result_data_type.INFORMATIONAL):
    assert isinstance(values, list)
    assert '/' not in measurement
    flattened_values = FlattenList(values)
    assert len(flattened_values)
    value, avg, sd = _MeanAndStdDevFromList(flattened_values)
    output = '%s%s: %s%s%s %s' % (
        RESULT_TYPES[result_type],
        _EscapePerfResult(measurement),
        trace_name,
        # Do not show equal sign if the trace is empty. Usually it happens when
        # measurement is enough clear to describe the result.
        '= ' if trace_name else '',
        value,
        units)
  else:
    assert perf_result_data_type.IsHistogram(result_type)
    assert isinstance(values, list)
    # The histograms can only be printed individually, there's no computation
    # across different histograms.
    assert len(values) == 1
    value = values[0]
    output = '%s%s: %s= %s %s' % (
        RESULT_TYPES[result_type],
        _EscapePerfResult(measurement),
        trace_name,
        value,
        units)
    avg, sd = GeomMeanAndStdDevFromHistogram(value)

  if avg:
    output += '\nAvg %s: %f%s' % (measurement, avg, units)
  if sd:
    output += '\nSd  %s: %f%s' % (measurement, sd, units)
  if print_to_stdout:
    print output
    sys.stdout.flush()
  return output

#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""A tool that uploads data to the performance dashboard."""

import argparse
import httplib
import json
import pprint
import re
import sys
import urllib
import urllib2

# TODO(yzshen): The following are missing currently:
#     (1) CL range on the dashboard;
#     (2) improvement direction on the dashboard;
#     (3) a link from the build step pointing to the dashboard page.


_PERF_LINE_FORMAT = r"""^\s*([^\s/]+)  # chart name
                        (/([^\s/]+))?  # trace name (optional, separated with
                                       # the chart name by a '/')
                        \s+(\S+)       # value
                        \s+(\S+)       # units
                        \s*$"""

_PRODUCTION_SERVER = "https://chromeperf.appspot.com"
_TESTING_SERVER = "https://chrome-perf.googleplex.com"


def UploadPerfData(master_name, perf_id, test_name, builder_name, build_number,
                   revision, perf_data, point_id, dry_run=False,
                   testing_dashboard=True):
  """Uploads perf data.

  Args:
    Please see the help for command-line args.

  Returns:
    A boolean value indicating whether the operation succeeded or not.
  """

  def _ConvertToUploadFormat():
    """Converts perf data to the format that the server understands.

    Returns:
      A dictionary that (after being converted to JSON) conforms to the server
      format.
    """
    charts = {}
    line_format = re.compile(_PERF_LINE_FORMAT, re.VERBOSE)
    for line in perf_data:
      match = re.match(line_format, line)
      assert match, "Unable to parse the following input: %s" % line

      chart_name = match.group(1)
      trace_name = match.group(3) if match.group(3) else "summary"

      if chart_name not in charts:
        charts[chart_name] = {}
      charts[chart_name][trace_name] = {
          "type": "scalar",
          "value": float(match.group(4)),
          "units": match.group(5)
      }

    return {
        "master": master_name,
        "bot": perf_id,
        "masterid": master_name,
        "buildername": builder_name,
        "buildnumber": build_number,
        "versions": {
            "mojo": revision
        },
        "point_id": point_id,
        "supplemental": {},
        "chart_data": {
            "format_version": "1.0",
            "benchmark_name": test_name,
            "charts": charts
        }
    }

  class _UploadException(Exception):
    pass

  def _Upload(server_url, json_data):
    """Make an HTTP POST with the given data to the performance dashboard.

    Args:
      server_url: URL of the performance dashboard instance.
      json_data: JSON string that contains the data to be sent.

    Raises:
      _UploadException: An error occurred during uploading.
    """
    # When data is provided to urllib2.Request, a POST is sent instead of GET.
    # The data must be in the application/x-www-form-urlencoded format.
    data = urllib.urlencode({"data": json_data})
    req = urllib2.Request("%s/add_point" % server_url, data)
    try:
      urllib2.urlopen(req)
    except urllib2.HTTPError as e:
      raise _UploadException("HTTPError: %d. Response: %s\n"
                             "JSON: %s\n" % (e.code, e.read(), json_data))
    except urllib2.URLError as e:
      raise _UploadException("URLError: %s for JSON %s\n" %
                             (str(e.reason), json_data))
    except httplib.HTTPException as e:
      raise _UploadException("HTTPException for JSON %s\n" % json_data)

  formatted_data = _ConvertToUploadFormat()

  server_url = _TESTING_SERVER if testing_dashboard else _PRODUCTION_SERVER

  if dry_run:
    print "Won't upload because --dry-run is specified."
    print "Server: %s" % server_url
    print "Data:"
    pprint.pprint(formatted_data)
  else:
    print "Uploading data to %s ..." % server_url
    try:
      _Upload(server_url, json.dumps(formatted_data))
    except _UploadException as e:
      print e
      return False

    print "Done."

    dashboard_params = urllib.urlencode({
        "masters": master_name,
        "bots": perf_id,
        "tests": test_name,
        "rev": point_id
    })
    print "Results Dashboard: %s/report?%s" % (server_url, dashboard_params)

  return True


def main():
  parser = argparse.ArgumentParser(
      description="A tool that uploads data to the performance dashboard.")

  parser.add_argument(
      "--master-name", required=True,
      help="Buildbot master name, used to construct link to buildbot log by "
           "the dashboard, and also as the top-level category for the data.")
  parser.add_argument(
      "--perf-id", required=True,
      help="Used as the second-level category for the data, usually the "
           "platform type.")
  parser.add_argument(
      "--test-name", required=True,
      help="Name of the test that the perf data was generated from.")
  parser.add_argument(
      "--builder-name", required=True,
      help="Buildbot builder name, used to construct link to buildbot log by "
           "the dashboard.")
  parser.add_argument(
      "--build-number", required=True, type=int,
      help="Build number, used to construct link to buildbot log by the "
           "dashboard.")
  parser.add_argument(
      "--revision", required=True, help="The mojo git commit hash.")
  parser.add_argument(
      "--perf-data", required=True, metavar="foo_perf.log",
      type=argparse.FileType("r"),
      help="A text file containing the perf data. Each line is a data point in "
           "the following format: chart_name[/trace_name] value units")
  parser.add_argument(
      "--point-id", required=True, type=int,
      help="The x coordinate for the data points.")
  parser.add_argument(
      "--dry-run", action="store_true",
      help="Display the server URL and the data to upload, but not actually "
           "upload the data.")
  server_group = parser.add_mutually_exclusive_group()
  server_group.add_argument(
      "--testing-dashboard", action="store_true", default=True,
      help="Upload the data to the testing dashboard (default).")
  server_group.add_argument(
      "--production-dashboard", dest="testing_dashboard", action="store_false",
      default=False, help="Upload the data to the production dashboard.")
  args = parser.parse_args()

  result = UploadPerfData(args.master_name, args.perf_id, args.test_name,
                          args.builder_name, args.build_number, args.revision,
                          args.perf_data, args.point_id, args.dry_run,
                          args.testing_dashboard)
  return 0 if result else 1


if __name__ == '__main__':
  sys.exit(main())

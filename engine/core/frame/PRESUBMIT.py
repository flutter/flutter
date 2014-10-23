# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Blink frame presubmit script

See http://dev.chromium.org/developers/how-tos/depottools/presubmit-scripts
for more details about the presubmit API built into gcl.
"""


def _RunUseCounterChecks(input_api, output_api):
    for f in input_api.AffectedFiles():
        if f.LocalPath().endswith('UseCounter.cpp'):
            useCounterCpp = f
            break
    else:
        return []

    largestFoundBucket = 0
    maximumBucket = 0
    # Looking for a line like "case CSSPropertyGrid: return 453;"
    bucketFinder = input_api.re.compile(r'.*CSSProperty.*return\s*([0-9]+).*')
    # Looking for a line like "static int maximumCSSSampleId() { return 452; }"
    maximumFinder = input_api.re.compile(
        r'static int maximumCSSSampleId\(\) { return ([0-9]+)')
    for line in useCounterCpp.NewContents():
        bucketMatch = bucketFinder.match(line)
        if bucketMatch:
            bucket = int(bucketMatch.group(1))
            largestFoundBucket = max(largestFoundBucket, bucket)
        else:
            maximumMatch = maximumFinder.match(line)
            if maximumMatch:
                maximumBucket = int(maximumMatch.group(1))

    if largestFoundBucket != maximumBucket:
        if input_api.is_committing:
            message_type = output_api.PresubmitError
        else:
            message_type = output_api.PresubmitPromptWarning

        return [message_type(
            'Largest found CSSProperty bucket Id (%d) does not match '
            'maximumCSSSampleId (%d)' %
                    (largestFoundBucket, maximumBucket),
            items=[useCounterCpp.LocalPath()])]

    return []


def CheckChangeOnUpload(input_api, output_api):
    return _RunUseCounterChecks(input_api, output_api)


def CheckChangeOnCommit(input_api, output_api):
    return _RunUseCounterChecks(input_api, output_api)

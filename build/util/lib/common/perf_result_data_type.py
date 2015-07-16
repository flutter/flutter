# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

DEFAULT = 'default'
UNIMPORTANT = 'unimportant'
HISTOGRAM = 'histogram'
UNIMPORTANT_HISTOGRAM = 'unimportant-histogram'
INFORMATIONAL = 'informational'

ALL_TYPES = [DEFAULT, UNIMPORTANT, HISTOGRAM, UNIMPORTANT_HISTOGRAM,
             INFORMATIONAL]


def IsValidType(datatype):
  return datatype in ALL_TYPES


def IsHistogram(datatype):
  return (datatype == HISTOGRAM or datatype == UNIMPORTANT_HISTOGRAM)

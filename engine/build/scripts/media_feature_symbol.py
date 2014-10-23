# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


def mediaFeatureSymbol(entry, suffix):
    name = entry['name']
    if name.startswith('-webkit-'):
        name = name[8:]

    foundDash = False
    newName = ""
    for chr in name:
        if chr == '-':
            foundDash = True
            continue
        if foundDash:
            chr = chr.upper()
            foundDash = False
        newName = newName + chr
    newName = newName + suffix
    return newName


def getMediaFeatureSymbolWithSuffix(suffix):
    def returnedFunction(entry):
        return mediaFeatureSymbol(entry, suffix)
    return returnedFunction

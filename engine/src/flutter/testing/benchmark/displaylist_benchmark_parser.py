#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import argparse
import json
import sys
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages as pdfp

class BenchmarkResult:
  def __init__(self, name, backend, timeUnit, drawCallCount):
    self.name = name
    self.series = {}
    self.seriesLabels = {}
    self.backend = backend
    self.largeYValues = False
    self.yLimit = 200
    self.timeUnit = timeUnit
    self.drawCallCount = drawCallCount

  def __repr__(self):
    return 'Name: % s\nBackend: % s\nSeries: % s\nSeriesLabels: % s\n' % (self.name, self.backend, self.series, self.seriesLabels)

  def addDataPoint(self, family, x, y):
    if family not in self.series:
      self.series[family] = { 'x': [], 'y': [] }

    self.series[family]['x'].append(x)
    self.series[family]['y'].append(y)

    if y > self.yLimit:
      self.largeYValues = True

  def setFamilyLabel(self, family, label):
    # I'm not keying the main series dict off the family label
    # just in case we get data where the two aren't a 1:1 mapping
    if family in self.seriesLabels:
      assert self.seriesLabels[family] == label
      return

    self.seriesLabels[family] = label

  def plot(self):
    figures = []
    figures.append(plt.figure(dpi=1200, frameon=False, figsize=(11, 8.5)))

    for family in self.series:
      plt.plot(self.series[family]['x'], self.series[family]['y'], label = self.seriesLabels[family])

    plt.xlabel('Benchmark Seed')
    plt.ylabel('Time (' + self.timeUnit + ')')

    title = ''
    # Crop the Y axis so that we can see what's going on at the lower end
    if self.largeYValues:
      plt.ylim((0, self.yLimit))
      title = self.name + ' ' + self.backend + ' (Cropped)'
    else:
      title = self.name + ' ' + self.backend

    if self.drawCallCount != -1:
      title += '\nDraw Call Count: ' + str(int(self.drawCallCount))

    plt.title(title)

    plt.grid(which='both', axis='both')

    plt.legend(fontsize='xx-small')
    plt.plot()

    if self.largeYValues:
      # Plot again but with the full Y axis visible
      figures.append(plt.figure(dpi=1200, frameon=False, figsize=(11, 8.5)))
      for family in self.series:
        plt.plot(self.series[family]['x'], self.series[family]['y'], label = self.seriesLabels[family])

      plt.xlabel('Benchmark Seed')
      plt.ylabel('Time (' + self.timeUnit + ')')
      title = self.name + ' ' + self.backend + ' (Complete)'

      if self.drawCallCount != -1:
        title += '\nDraw Call Count: ' + str(int(self.drawCallCount))

      plt.title(title)

      plt.grid(which='both', axis='both')

      plt.legend(fontsize='xx-small')
      plt.plot()

    return figures

def main():
  parser = argparse.ArgumentParser()

  parser.add_argument('filename', action='store',
      help='Path to the JSON output from Google Benchmark')
  parser.add_argument('-o', '--output-pdf', dest='outputPDF', action='store', default='output.pdf',
                      help='Filename to output the PDF of graphs to.')

  args = parser.parse_args()
  jsonData = parseJSON(args.filename)
  return processBenchmarkData(jsonData, args.outputPDF)

def error(message):
  print(message)
  exit(1)

def extractAttributesLabel(benchmarkResult):
  # Possible attribute keys are:
  #  AntiAliasing
  #  HairlineStroke
  #  StrokedStyle
  #  FilledStyle
  attributes = ['AntiAliasing', 'HairlineStroke', 'StrokedStyle', 'FilledStyle']
  label = ''

  for attr in attributes:
    try:
      if benchmarkResult[attr] != 0:
        label += attr + ', '
    except KeyError:
      pass

  return label[:-2]

def processBenchmarkData(benchmarkJSON, outputPDF):
  benchmarkResultsData = {}

  for benchmarkResult in benchmarkJSON:
    # Skip aggregate results
    if 'aggregate_name' in benchmarkResult:
      continue

    benchmarkVariant = benchmarkResult['name'].split('/')
    # The final split is always `real_time` and can be discarded
    benchmarkVariant.remove('real_time')

    splits = len(benchmarkVariant)
    # First split is always the benchmark function name
    benchmarkName = benchmarkVariant[0]
    # The last split is always the seeded value into the benchmark
    benchmarkSeededValue = benchmarkVariant[splits-1]
    # The second last split is always the backend
    benchmarkBackend = benchmarkVariant[splits-2]
    # Time taken (wall clock time) for benchmark to run
    benchmarkRealTime = benchmarkResult['real_time']
    benchmarkUnit = benchmarkResult['time_unit']

    benchmarkFamilyIndex = benchmarkResult['family_index']

    benchmarkFamilyLabel = ''
    if splits > 3:
      for i in range(1, splits-2):
        benchmarkFamilyLabel += benchmarkVariant[i] + ', '

    benchmarkFamilyAttributes = extractAttributesLabel(benchmarkResult)

    if benchmarkFamilyAttributes == '':
      benchmarkFamilyLabel = benchmarkFamilyLabel[:-2]
    else:
      benchmarkFamilyLabel = benchmarkFamilyLabel + benchmarkFamilyAttributes

    if 'DrawCallCount' in benchmarkResult:
      benchmarkDrawCallCount = benchmarkResult['DrawCallCount']
    else:
      benchmarkDrawCallCount = -1

    if benchmarkName not in benchmarkResultsData:
      benchmarkResultsData[benchmarkName] = BenchmarkResult(benchmarkName, benchmarkBackend, benchmarkUnit, benchmarkDrawCallCount)

    benchmarkResultsData[benchmarkName].addDataPoint(benchmarkFamilyIndex, benchmarkSeededValue, benchmarkRealTime)
    benchmarkResultsData[benchmarkName].setFamilyLabel(benchmarkFamilyIndex, benchmarkFamilyLabel)

  pp = pdfp(outputPDF)

  for benchmark in benchmarkResultsData:
    figures = benchmarkResultsData[benchmark].plot()
    for fig in figures:
      pp.savefig(fig)
  pp.close()


def parseJSON(filename):
  try:
    jsonFile = open(filename, 'r')
  except:
    error('Unable to load file.')

  try:
    jsonData = json.load(jsonFile)
  except JSONDecodeError:
    error('Invalid JSON. Unable to parse.')

  return jsonData['benchmarks']

if __name__ == '__main__':
  sys.exit(main())

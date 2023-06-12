// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' as math show Random, min;

import 'point_provider.dart';
import 'point_provider_lab.dart';
import 'quantizer.dart';

class DistanceAndIndex implements Comparable<DistanceAndIndex> {
  double distance;
  int index;

  DistanceAndIndex(this.distance, this.index);

  @override
  int compareTo(DistanceAndIndex other) {
    if (distance < other.distance) {
      return -1;
    } else if (distance > other.distance) {
      return 1;
    } else {
      return 0;
    }
  }
}

class QuantizerWsmeans {
  static const debug = false;

  static void debugLog(String log) {
    if (debug) {
      print(log);
    }
  }

  static QuantizerResult quantize(
    Iterable<int> inputPixels,
    int maxColors, {
    List<int> startingClusters = const [],
    PointProvider pointProvider = const PointProviderLab(),
    int maxIterations = 5,
    bool returnInputPixelToClusterPixel = false,
  }) {
    final pixelToCount = <int, int>{};
    final points = <List<double>>[];
    final pixels = <int>[];
    var pointCount = 0;
    inputPixels.forEach((inputPixel) {
      final pixelCount = pixelToCount.update(inputPixel, (value) => value + 1,
          ifAbsent: () => 1);
      if (pixelCount == 1) {
        pointCount++;
        points.add(pointProvider.fromInt(inputPixel));
        pixels.add(inputPixel);
      }
    });

    final counts = List<int>.filled(pointCount, 0);
    for (var i = 0; i < pointCount; i++) {
      final pixel = pixels[i];
      final count = pixelToCount[pixel]!;
      counts[i] = count;
    }

    var clusterCount = math.min(maxColors, pointCount);

    final clusters =
        startingClusters.map((e) => pointProvider.fromInt(e)).toList();
    final additionalClustersNeeded = clusterCount - clusters.length;
    if (additionalClustersNeeded > 0) {
      final random = math.Random(0x42688);
      final indices = <int>[];
      for (var i = 0; i < additionalClustersNeeded; i++) {
        // Use existing points rather than generating random centroids.
        //
        // KMeans is extremely sensitive to initial clusters. This quantizer
        // is meant to be used with a Wu quantizer that provides initial
        // centroids, but Wu is very slow on unscaled images and when extracting
        // more than 256 colors.
        //
        // Here, we can safely assume that more than 256 colors were requested
        // for extraction. Generating random centroids tends to lead to many
        // "empty" centroids, as the random centroids are nowhere near any pixels
        // in the image, and the centroids from Wu are very refined and close
        // to pixels in the image.
        //
        // Rather than generate random centroids, we'll pick centroids that
        // are actual pixels in the image, and avoid duplicating centroids.

        var index = random.nextInt(points.length);
        while (indices.contains(index)) {
          index = random.nextInt(points.length);
        }
        indices.add(index);
      }

      indices.forEach((index) {
        clusters.add(points[index]);
      });
    }
    debugLog(
      'have ${clusters.length} starting clusters, ${points.length} points',
    );
    final clusterIndexRandom = math.Random(0x42688);
    final clusterIndices =
        List<int>.generate(pointCount, (index) => index % clusterCount);
    final indexMatrix = List<List<int>>.generate(
        clusterCount, (_) => List.filled(clusterCount, 0));

    final distanceToIndexMatrix = List<List<DistanceAndIndex>>.generate(
        clusterCount,
        (index) => List<DistanceAndIndex>.generate(
            clusterCount, (index) => DistanceAndIndex(0, index)));

    final pixelCountSums = List<int>.filled(clusterCount, 0);
    for (var iteration = 0; iteration < maxIterations; iteration++) {
      if (debug) {
        for (var i = 0; i < clusterCount; i++) {
          pixelCountSums[i] = 0;
        }
        for (var i = 0; i < pointCount; i++) {
          final clusterIndex = clusterIndices[i];
          final count = counts[i];
          pixelCountSums[clusterIndex] += count;
        }
        var emptyClusters = 0;
        for (var cluster = 0; cluster < clusterCount; cluster++) {
          if (pixelCountSums[cluster] == 0) {
            emptyClusters++;
          }
        }
        debugLog(
          'starting iteration ${iteration + 1}; $emptyClusters clusters are empty of $clusterCount',
        );
      }

      var pointsMoved = 0;
      for (var i = 0; i < clusterCount; i++) {
        for (var j = i + 1; j < clusterCount; j++) {
          final distance = pointProvider.distance(clusters[i], clusters[j]);
          distanceToIndexMatrix[j][i].distance = distance;
          distanceToIndexMatrix[j][i].index = i;
          distanceToIndexMatrix[i][j].distance = distance;
          distanceToIndexMatrix[i][j].index = j;
        }
        distanceToIndexMatrix[i].sort();
        for (var j = 0; j < clusterCount; j++) {
          indexMatrix[i][j] = distanceToIndexMatrix[i][j].index;
        }
      }

      for (var i = 0; i < pointCount; i++) {
        final point = points[i];
        final previousClusterIndex = clusterIndices[i];
        final previousCluster = clusters[previousClusterIndex];
        final previousDistance = pointProvider.distance(point, previousCluster);
        var minimumDistance = previousDistance;
        var newClusterIndex = -1;
        for (var j = 0; j < clusterCount; j++) {
          if (distanceToIndexMatrix[previousClusterIndex][j].distance >=
              4 * previousDistance) {
            continue;
          }
          final distance = pointProvider.distance(point, clusters[j]);
          if (distance < minimumDistance) {
            minimumDistance = distance;
            newClusterIndex = j;
          }
        }
        if (newClusterIndex != -1) {
          pointsMoved++;
          clusterIndices[i] = newClusterIndex;
        }
      }

      if (pointsMoved == 0 && iteration > 0) {
        debugLog('terminated after $iteration k-means iterations');
        break;
      }

      debugLog('iteration ${iteration + 1} moved $pointsMoved');
      final componentASums = List<double>.filled(clusterCount, 0);
      final componentBSums = List<double>.filled(clusterCount, 0);
      final componentCSums = List<double>.filled(clusterCount, 0);

      for (var i = 0; i < clusterCount; i++) {
        pixelCountSums[i] = 0;
      }
      for (var i = 0; i < pointCount; i++) {
        final clusterIndex = clusterIndices[i];
        final point = points[i];
        final count = counts[i];
        pixelCountSums[clusterIndex] += count;
        componentASums[clusterIndex] += (point[0] * count);
        componentBSums[clusterIndex] += (point[1] * count);
        componentCSums[clusterIndex] += (point[2] * count);
      }
      for (var i = 0; i < clusterCount; i++) {
        final count = pixelCountSums[i];
        if (count == 0) {
          clusters[i] = [0.0, 0.0, 0.0];
          continue;
        }
        final a = componentASums[i] / count;
        final b = componentBSums[i] / count;
        final c = componentCSums[i] / count;
        clusters[i] = [a, b, c];
      }
    }

    final clusterArgbs = <int>[];
    final clusterPopulations = <int>[];
    for (var i = 0; i < clusterCount; i++) {
      final count = pixelCountSums[i];
      if (count == 0) {
        continue;
      }

      final possibleNewCluster = pointProvider.toInt(clusters[i]);
      if (clusterArgbs.contains(possibleNewCluster)) {
        continue;
      }

      clusterArgbs.add(possibleNewCluster);
      clusterPopulations.add(count);
    }
    debugLog(
      'kmeans finished and generated ${clusterArgbs.length} clusters; $clusterCount were requested',
    );

    final inputPixelToClusterPixel = <int, int>{};
    if (returnInputPixelToClusterPixel) {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < pixels.length; i++) {
        final inputPixel = pixels[i];
        final clusterIndex = clusterIndices[i];
        final cluster = clusters[clusterIndex];
        final clusterPixel = pointProvider.toInt(cluster);
        inputPixelToClusterPixel[inputPixel] = clusterPixel;
      }
      debugLog(
        'took ${stopwatch.elapsedMilliseconds} ms to create input to cluster map',
      );
    }

    return QuantizerResult(
      Map.fromIterables(clusterArgbs, clusterPopulations),
      inputPixelToClusterPixel: inputPixelToClusterPixel,
    );
  }
}

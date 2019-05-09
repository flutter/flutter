// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

const assetChannel = 'flutter/assets';

class Engine extends RuntimeDelegate {
  final Animator _animator;
  final dynamic _runtimeController;
  final AssetManager _assetManager;
  final dynamic _delegate;

  Engine(this._animator, this._runtimeController, this._assetManager,
      this._delegate);

  String get defaultRouteName => _initialRoute ?? '/';

  String _initialRoute;

  bool get haveSurface => true;

  ViewportMetrics _viewportMetrics;
  set viewportMetrics(ViewportMetrics metrics) {
    final dimensionsChanged =
        _viewportMetrics.physicalHeight != metrics.physicalHeight ||
            _viewportMetrics.physicalWidth != metrics.physicalWidth;
    _viewportMetrics = metrics;
    _runtimeController.viewportMetrics = _viewportMetrics;
    if (_animator != null) {
      if (dimensionsChanged) {
        _animator.setDimensionChangePending();
      }
      if (haveSurface) {
        scheduleFrame();
      }
    }
  }

  void scheduleFrame({bool regenerateLayerTree = true}) {
    _animator.requestFrame(regenerateLayerTree);
  }

  void render(LayerTree layerTree) {
    if (layerTree == null) return;

    final frameSize = ui.Size(
        _viewportMetrics.physicalWidth, _viewportMetrics.physicalHeight);

    if (frameSize.isEmpty) {
      return;
    }

    layerTree.frameSize = frameSize;
    _animator.render(layerTree);
  }

  void handlePlatformMessage(PlatformMessage message) {
    if (message.channel == assetChannel) {
      handleAssetPlatformMessage(message);
    } else {
      _delegate.onEngineHandlePlatformMessage(message);
    }
  }

  void handleAssetPlatformMessage(PlatformMessage message) {
    final response = message.response;
    if (response == null) return;

    final asset = utf8.decode(message.data.buffer.asUint8List());
    if (_assetManager != null) {
      _assetManager.load(asset).then((data) {
        if (data != null) {
          response.complete(data.buffer.asUint8List());
        } else {
          response.completeEmpty();
        }
      });
    } else {
      response.completeEmpty();
    }
  }

  FontCollection getFontCollection() => null;
}

class Animator {
  void setDimensionChangePending() {}
  void render(LayerTree layerTree) {}
  void requestFrame(bool regenerateLayerTree) {}
}

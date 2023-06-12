/// A way to represent the step of the "doubletap gesture cycle" in which PhotoView is.
enum PhotoViewScaleState {
  initial,
  covering,
  originalSize,
  zoomedIn,
  zoomedOut,
}

extension PhotoViewScaleStateIZoomingExtension on PhotoViewScaleState {
  bool get isScaleStateZooming =>
      this == PhotoViewScaleState.zoomedIn ||
      this == PhotoViewScaleState.zoomedOut;
}

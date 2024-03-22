{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    // Use the local CanvasKit bundle instead of the CDN to reduce test flakiness.
    canvasKitBaseUrl: "/canvaskit/",
  },
});
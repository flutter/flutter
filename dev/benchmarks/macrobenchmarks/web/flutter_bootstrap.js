{{flutter_js}}
{{flutter_build_config}}

const searchParams = new URLSearchParams(window.location.search);
const forceSt = searchParams.get('force_st');
const extraConfig = forceSt ? {forceSingleThreadedSkwasm: true} : {};
_flutter.loader.load({
  config: {
    // Use the local CanvasKit bundle instead of the CDN to reduce test flakiness.
    canvasKitBaseUrl: "/canvaskit/",
    ...extraConfig,
  },
});
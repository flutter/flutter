# Frequently Asked Questions

* How do you run `impeller_unittests` with Playgrounds enabled?
  * Playgrounds in the `impeller_unittests` harness can be enabled in one of
    three ways:
    * Edit `gn args` directly and add `impeller_enable_playground = true`.
    * Add the `--enable-impeller-playground` flag to your `./flutter/tools/gn`
      invocation.
    * Set the `FLUTTER_IMPELLER_ENABLE_PLAYGROUND` to `1` before invoking
      `./flutter/tools/gn`. Only do this if you frequently work with Playgrounds
      and don't want to have to set the flags manually. Also, it would be a bad
      idea to set this environment variable on CI.
* Does Impeller use Skia for rendering?
  * No. Impeller has no direct dependencies on Skia.
  * When running with Impeller, Flutter does not create a Skia graphics context.
  * However, while Impeller still performs text rendering, text layout and
    shaping needs to be done by a separate component. This component happens to
    be SkParagraph which is part of Skia.
  * Similarly, Impeller does not perform image decompression. Flutter uses a
    standard set of codecs wrapped by Skia before querying the system supplied
    image formats.
  * So, while Impeller does not use nor is it a wrapper for Skia, some Skia
    components are still used by Flutter when rendering using Impeller.
* Is Impeller going to be supported on the Web?
  * The current priority for Impeller is to be amazing on all platforms targeted
    by the C++ engine. This includes iOS, Android, desktops, and, all Embedder
    API users. This would be by building Metal, Open GL, Open GL ES, and, Vulkan
    rendering backends.
  * The Open GL ES backend ought to work fine to target WebGL/WebGL2 and the
    team can fix any issues found in such uses of the backend.
  * However, in Flutter, Impeller sits behind the Display List interface in the
    C++ engine. Display lists apply optimizations to the Flutter rendering
    intent. But, more importantly for Impeller, they also provide a generic
    interface with the ability to specify "dispatchers" to different rendering
    packages. Today, the engine has Skia and Impeller dispatchers for display
    lists.
  * The web engine is unique in that it doesn't use any C++ engine components.
    This includes the display lists mechanism. Instead, it interfaces directly
    with Skia via the CanvasKit package.
  * Updating the web engine to interface directly with Impeller is a non-goal at
    this time. It is a significant undertaking (compared to a flag to swap
    dispatchers that already exists) and also bypasses display list
    optimizations.
  * For this added implementation complexity, Web support has not been a
    priority at this time for the small team working on Impeller.
  * We are aware that these priorities might change in the future. There have
    been sanity checks to ensure that the Impeller API can be ported to WASM and
    also that Impeller shaders can be [compiled to WGSL](https://github.com/chinmaygarde/wgsl_sandbox)
    for eventual WebGPU support.

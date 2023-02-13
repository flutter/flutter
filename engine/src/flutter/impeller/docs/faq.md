# Frequently Asked Questions

* How do I enable Impeller to try it out myself?
  * See the instructions in the README on how to [try Impeller in
    Flutter](https://github.com/flutter/engine/tree/main/impeller#try-impeller-in-flutter).
  * Support on some platforms is further along than on others. The current
    priority for the team is to support iOS, Android, Desktops, and Embedder API
    users (in that rough order).
* I am running into issues when Impeller is enabled, how do I report them?
  * Like any other Flutter issue, you can report them on the [GitHub issue
    tracker](https://github.com/flutter/flutter/issues/new/choose).
  * Please explicitly mention that this is an Impeller specific regression. You
    can quickly swap between the Impeller and Skia backends using the command
    line flag flag detailed in [section in the README on how to try
    Impeller](https://github.com/flutter/engine/tree/main/impeller#try-impeller-in-flutter).
  * Reduced test cases are the most useful.
  * Please also report any performance regressions.
* What does it mean for an Impeller platform to be "in preview". How long will
  be the preview last?
  * The team is focused on getting one platform right at a time. This includes
    ensuring all fidelity issues are fixed, performance issues addressed, and
    compatibility with plugins guaranteed.
  * When the team believes that the majority of Flutter applications will
    benefit from Impeller on a specific platform, the backend will be declared
    to be in preview.
  * During the preview, Flutter developers will need to opt in to using
    Impeller.
  * The top priority of the team will be to address issues reported by
    developers opting into the preview. The team wants the preview phase for a
    platform to be as short as possible.
  * Once major issues reported by platforms in preview become manageable, the
    preview ends and Impeller becomes the default rendering backend.
  * Besides working on fixing issues reported on platforms in preview, and
    working on supporting additional platforms, the team is also undertaking a
    high-touch exercise of migrating large existing Flutter applications to use
    Impeller. The team will find and fix any issues it encounters during this
    exercise.
  * The length of the preview will depend on the number and nature of the issues
    filed by developers and discovered by the team.
  * Even once the preview ends, the developer can opt into the legacy rendering
    backend for a short period of time. The legacy backend will be removed after
    this period.
* What can I expect when I opt in to using Impeller?
  * A high level overview of the status of project is [present on the
    wiki](https://github.com/flutter/flutter/wiki/Impeller#status).
  * All Impeller related work items are tracked on a [project specific dashboard
    on GitHub](https://github.com/orgs/flutter/projects/21).
  * The team tracks known platform specific issues in their own milestones:
    * [iOS](https://github.com/flutter/flutter/milestone/77)
    * [Android](https://github.com/flutter/flutter/milestone/76)
* Does Impeller use Skia for rendering?
  * No. Impeller has no direct dependencies on Skia.
  * When running with Impeller, Flutter does not create a Skia graphics context.
  * However, while Impeller still performs text rendering, text layout and
    shaping needs to be done by a separate component. This component happens to
    be SkParagraph which is part of Skia.
  * Similarly, Impeller does not perform image decompression. Flutter uses a
    standard set of codecs wrapped by Skia before querying the system supplied
    image formats.
  * So, while Impeller does not use nor is a wrapper for Skia, some Skia
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
    also that Impeller shaders can be [compiled to
    WGSL](https://github.com/chinmaygarde/wgsl_sandbox) for eventual WebGPU
    support.
* How will Impeller affect the way in which Flutter applications are created and
  packaged?
  * It won't.
  * Impeller, like Skia, is an implementation detail of the Flutter Engine.
    Using a different rendering package will not affect the way in which the
    Flutter Engine is used.
  * Like with Skia today, none of Impellers symbols will be exposed from the
    Flutter Engine dynamic library.
  * The binary size overhead of Impeller is around 100 KB per architecture. This
    includes all precompiled shaders.
  * Impeller is compiled into the Flutter engine. It is currently behind a flag
    as development progresses.
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

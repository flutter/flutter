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

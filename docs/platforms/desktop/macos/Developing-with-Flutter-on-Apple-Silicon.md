Flutter includes support for developing on macOS devices with [Apple Silicon (M1) hardware](https://www.apple.com/mac/m1/). This wiki page documents ongoing work relating to the Flutter toolchain providing native support for this processor architecture.

We recommend using Flutter 2.5 or later on Apple Silicon machines. You must also have the [Rosetta 2 translation environment](https://developer.apple.com/documentation/apple_silicon/about_the_rosetta_translation_environment) available, which you can install manually by running:

```sh
$ sudo softwareupdate --install-rosetta --agree-to-license
```

If you see CocoaPods crashes related to `ffi`, try reinstalling the Ruby gem with the `--enable-libffi-alloc` flag:

```
sudo gem uninstall ffi && sudo gem install ffi -- --enable-libffi-alloc
```

## Using macOS on Apple Silicon to develop Flutter apps (host)

You can use Apple Silicon-based Mac devices as a developer workstation (host) for building Flutter apps. While some tools still use Rosetta, Apple Silicon-based Macs are fully supported as a host.

As we build more Apple Silicon support into the tooling, and depending on your tolerance for risk, [you may want to experiment with the `beta` channel](https://flutter.dev/docs/development/tools/sdk/upgrading#switching-flutter-channels). (This was previously also available on the dev channel, but [it has been retired](https://medium.com/flutter/whats-new-in-flutter-2-8-d085b763d181#34c4).)

[Issue 60118](https://github.com/flutter/flutter/issues/60118) tracks the full set of work to support this feature.

## Developing Flutter apps for macOS running on Apple Silicon (target)

Flutter has [support for building macOS apps](https://flutter.dev/desktop), with beta snapshots available in the `stable` channel and ongoing development taking place.

Compiled Intel macOS binaries work on Apple Silicon without change thanks to the [Rosetta 2 translation environment](https://developer.apple.com/documentation/apple_silicon/about_the_rosetta_translation_environment), which converts x86_64 instructions to ARM64 equivalents.

We also plan to offer support for compilation directly to ARM64, as well as universal binaries that combine x86_64 and ARM64 assets. [Issue 60113](https://github.com/flutter/flutter/issues/60113) is the umbrella bug tracking this work.

## Filing Issues

If you experience a problem relating to using Flutter on Apple Silicon hardware, please [file an issue on GitHub](https://github.com/flutter/flutter/issues/new?template=01_activation.yml) with specific repro steps and information about your hardware and software configuration (paste the results of `flutter doctor -v`). Thank you!

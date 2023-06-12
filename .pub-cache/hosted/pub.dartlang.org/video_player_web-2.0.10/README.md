# video_player_web

The web implementation of [`video_player`][1].

## Usage

This package is [endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin),
which means you can simply use `video_player`
normally. This package will be automatically included in your app when you do.

## dart:io

The Web platform does **not** suppport `dart:io`, so attempts to create a `VideoPlayerController.file` will throw an `UnimplementedError`.

## Autoplay
Playing videos without prior interaction with the site might be prohibited
by the browser and lead to runtime errors. See also: https://goo.gl/xX8pDD.

## Mixing audio with other audio sources

The `VideoPlayerOptions.mixWithOthers` option can't be implemented in web, at least at the moment. If you use this option it will be silently ignored.

## Supported Formats

**Different web browsers support different sets of video codecs.**

### Video codecs?

Check MDN's [**Web video codec guide**](https://developer.mozilla.org/en-US/docs/Web/Media/Formats/Video_codecs) to learn more about the pros and cons of each video codec.

### What codecs are supported?

Visit [**caniuse.com: 'video format'**](https://caniuse.com/#search=video%20format) for a breakdown of which browsers support what codecs. You can customize charts there for the users of your particular website(s).

Here's an abridged version of the data from caniuse, for a Global audience:

#### MPEG-4/H.264
[![Data on Global support for the MPEG-4/H.264 video format](https://caniuse.bitsofco.de/image/mpeg4.png)](https://caniuse.com/#feat=mpeg4)

#### WebM
[![Data on Global support for the WebM video format](https://caniuse.bitsofco.de/image/webm.png)](https://caniuse.com/#feat=webm)

#### Ogg/Theora
[![Data on Global support for the Ogg/Theora video format](https://caniuse.bitsofco.de/image/ogv.png)](https://caniuse.com/#feat=ogv)

#### AV1
[![Data on Global support for the AV1 video format](https://caniuse.bitsofco.de/image/av1.png)](https://caniuse.com/#feat=av1)

#### HEVC/H.265
[![Data on Global support for the HEVC/H.265 video format](https://caniuse.bitsofco.de/image/hevc.png)](https://caniuse.com/#feat=hevc)


[1]: ../video_player

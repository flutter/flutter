# Flutter Photo View 

[![Tests status](https://img.shields.io/github/workflow/status/bluefireteam/photo_view/Test/master?label=tests)](https://github.com/bluefireteam/photo_view/actions) [![Pub](https://img.shields.io/pub/v/photo_view.svg?style=popout)](https://pub.dartlang.org/packages/photo_view) [![Chat](https://img.shields.io/discord/509714518008528896)](https://discord.gg/pxrBmy4)

A simple zoomable image/content widget for Flutter.

PhotoView enables images to become able to zoom and pan with user gestures such as pinch, rotate and drag.

It also can show any widget instead of an image, such as Container, Text or a SVG. 

Even though being super simple to use, PhotoView is extremely customizable though its options and the controllers. 


## Installation

Add `photo_view` as a dependency in your pubspec.yaml file ([what?](https://flutter.io/using-packages/)).

Import Photo View:
```dart
import 'package:photo_view/photo_view.dart';
```

## Docs & API

The [API Docs](https://pub.dartlang.org/documentation/photo_view/latest/photo_view/photo_view-library.html) some detailed information about how to use PhotoView.


If you want to see it in practice, check the [example app](https://github.com/bluefireteam/photo_view/tree/master/example/lib) that explores most of Photo View's use cases or download the latest version apk on the [releases page](https://github.com/bluefireteam/photo_view/releases)
 

## (Very) Basic usage

Given a `ImageProvider imageProvider` (such as [AssetImage](https://docs.flutter.io/flutter/painting/AssetImage-class.html) or [NetworkImage](https://docs.flutter.io/flutter/painting/NetworkImage-class.html)):

```dart
@override
Widget build(BuildContext context) {
  return Container(
    child: PhotoView(
      imageProvider: AssetImage("assets/large-image.jpg"),
    )
  );
}
```

Result: 

![In action](https://user-images.githubusercontent.com/6718144/56463745-45ec0380-63b0-11e9-8e56-0dba5deabb1a.gif)


Read more about the `PhotoView` widget [here](https://pub.dartlang.org/documentation/photo_view/latest/photo_view/PhotoView-class.html).


## Gallery

To show several images and let user change between them, use `PhotoViewGallery`.

Read more about the gallery [here](https://pub.dartlang.org/documentation/photo_view/latest/photo_view_gallery/PhotoViewGallery-class.html).

```dart
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
// ...


@override
Widget build(BuildContext context) {
  return Container(
    child: PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: AssetImage(widget.galleryItems[index].image),
          initialScale: PhotoViewComputedScale.contained * 0.8,
          heroAttributes: PhotoViewHeroAttributes(tag: galleryItems[index].id),
        );
      },
      itemCount: galleryItems.length,
      loadingBuilder: (context, event) => Center(
        child: Container(
          width: 20.0,
          height: 20.0,
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / event.expectedTotalBytes,
          ),
        ),
      ),
      backgroundDecoration: widget.backgroundDecoration,
      pageController: widget.pageController,
      onPageChanged: onPageChanged,
    )
  );
}
```

Gallery sample in the example app: 

![In action](https://user-images.githubusercontent.com/6718144/56463769-e93d1880-63b0-11e9-8586-55827c95b89c.gif)

See the code [here](https://github.com/bluefireteam/photo_view/blob/master/example/lib/screens/examples/gallery/gallery_example.dart).



## Usage with controllers

When you need to interact with PhotoView's internal state values, `PhotoViewController` and `PhotoViewScaleStateController` are the way to.

Controllers, when specified to PhotoView widget, enables the author(you) to listen for state updates through a `Stream` and change those values externally.

Read more about controllers [here](https://pub.dartlang.org/documentation/photo_view/latest/photo_view/PhotoView-class.html#controllers).

In the example app, we can see what can be achieved with controllers: 

![In action](https://user-images.githubusercontent.com/6718144/56464051-3328fd00-63b7-11e9-9c4d-73b04f72a81e.gif)

### More screenshots


| **Custom background, <br>small image <br>and custom alignment** | **Limited scale** | **Hero animation** |
| ------------- | ------------- | ------------- |
| ![In action](https://user-images.githubusercontent.com/6718144/56464128-ff4ed700-63b8-11e9-802e-a933b3e79ea3.gif) | ![In action](https://user-images.githubusercontent.com/6718144/56464182-23f77e80-63ba-11e9-87a9-4838ef20af7e.gif) | ![In action](https://user-images.githubusercontent.com/6718144/56464202-9700f500-63ba-11e9-9f47-14e8bf441958.gif) |
| **Part of the screen** | **Custom child** |
| ![In action](https://user-images.githubusercontent.com/6718144/56464215-d92a3680-63ba-11e9-9c37-d4796e992123.gif) | ![In action](https://user-images.githubusercontent.com/6718144/56464225-1b537800-63bb-11e9-9c5b-ea8632c99969.gif) |

## Support us

You can support us by becoming a patron on Patreon, any support is much appreciated.

[![Patreon](https://c5.patreon.com/external/logo/become_a_patron_button.png)](https://www.patreon.com/fireslime)



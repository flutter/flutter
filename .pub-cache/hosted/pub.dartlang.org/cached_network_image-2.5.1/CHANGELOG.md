## [2.5.1] - 2021-03-09
* Update dependencies

## [2.5.0] - 2020-12-22
* Add support for resizing images in disk cache.
```dart
CachedNetworkImage(
  maxHeightDiskCache: 200,
  imageUrl: 'https://via.placeholder.com/3000x2000',
);
```

## [2.4.1] - 2020-12-01
* Fix a bug that an image is disposed when it shouldn't.

## [2.4.0] - 2020-11-30
* Added support for a cache key which is different from the image url.

## [2.3.3] - 2020-10-16
* Support for flutter_cache_manager 2.x.x.

## [2.3.2] - 2020-09-10
* Fixed placeholders and error widgets, those are not always centered anymore.
* Evict an image from ImageCache if image fails to load.
* Added method to evict an image from memory and disk cache.

## [2.3.1] - 2020-08-25
* Fixed fading when the image has no placeholder or progress indicator.

## [2.3.0] - 2020-08-25
* Improved image loading by using OctoImage. OctoImage uses the native callbacks of the ImageProvider instead of
 loading the file when the ImageWidget is build the first time.
* Set minimal Flutter version to 1.20.0; first compatible stable version.
* Added choice for rendering of images on web. Defaults to standard HTML ImageElement, but gives the option to use a
 custom HTTP Get for headers and skia support.
* Use a MultiImageStreamCompleter for when an image that is available in the cache is updated. 

## [2.3.0-rc] - 2020-06-20
* Added choice for rendering of images on web. Defaults to standard HTML ImageElement, but gives the option to use a
 custom HTTP Get for headers and skia support.
* Use a MultiImageStreamCompleter for when an image that is available in the cache is updated. 
* Increase minimal version of Flutter to 1.19.0-2.0.pre (currently requires Beta) due to an error listener bug.

## [2.3.0-beta.1] - 2020-05-28
* Improved web support: support for headers and skia.

## [2.3.0-beta] - 2020-05-20
* Rewrote image widget by using OctoImage.

## [2.2.0+1] - 2020-05-05
* Fix ImageProvider not using provided headers.

## [2.2.0] - 2020-04-30
* Upgrades on CachedNetworkImageProvider:
    * Support for download progress.
    * Basic web support (no caching).

## [2.1.0+1] - 2020-04-10
* Update minimal Dart sdk version

## [2.1.0] - 2020-04-10
* Update CacheManager
* Added option for progress indicator

## [2.0.0] - 2019-12-31
* Public release of 2.0 version

## [2.0.0-rc.1] - 2019-11-04
* Revert scaling of image due to issues with BoxFit.

## [2.0.0-rc] - 2019-10-17
* BREAKING CHANGE: Compatibility for [breaking change in Flutter 1.10.15](https://groups.google.com/forum/#!topic/flutter-announce/lUKzLAd8OG8)

## [1.1.3] - 2019-11-04
* Revert scaling of image due to issues with BoxFit.

## [1.1.2+1] - 2019-10-17
* Fix for widgets declared with infinite size.

## [1.1.2] - 2019-10-16
* Add filterQuality property.
* Scale image to size when showing in widget.
* Better error handling.
* Fix for useOldImageOnUrlChange.
* Update cache manager to 1.1.2.

## [1.1.1] - 2019-07-23
* Updated cache manager for error handling fix

## [1.1.0] - 2019-07-13

* Improved performance
* Keep fetched files in sync with filemanager.
* Better error handling.
* Added extra example to show the imageBuilder

## [1.0.0] - 2019-06-27
* Updated dependencies

## [0.8.0] - 2019-05-06
* Fixed compile error on informationCollector by temporarily disabling it.

## [0.7.0] - 2019-03-06
* BREAKING CHANGE: Renamed ErrorWidgetBuilder to LoadingErrorWidgetBuilder
* LoadingErrorWidgetBuilder returns an Object instead of an Exception
* Fixed BoxFit to also work when size is not defined

## [0.6.2] - 2019-02-27
* Added option to blend image with color
* Added option in CacheManager to clear the cache

## [0.6.1] - 2019-02-25 BREAKING CHANGES
* No longer assume infinite size.

## [0.6.0] - 2019-02-18 BREAKING CHANGES
* Breaking changes in API and behaviour
* Very much improved though
* Adapted for new cache manager library
* Completely rewritten image view
* Now using builders for placeholder and error widgets
* Added optional builder to customize the image

## [0.5.1] - 2018-11-19
* Fixed error throwing

## [0.5.0] - 2018-10-13
* Updated cache manager for http 0.12.0

## [0.4.2] - 2018-08-30
* Updated cache manager dependency

## [0.4.1] - 2018-04-27
* Improved error handling when a file could not be loaded.

## [0.4.0] - 2018-04-14
* Added optional headers.
* Changed to Dart 2.0
* Fixed bug when updating widget with new url

## [0.3.0] - 2018-02-09
* Added CachedNetworkImage with placeholder and error widgets.

## [0.2.1] - 2018-01-08
* Moved from OneFrameImageStreamCompleter to MultiFrameImageStreamCompleter.
* Updated CacheManager dependency for critical bug fix.

## [0.2.0] - 2017-12-29

* **Breaking change** Removed CachedNetworkImage. From now on only the ImageProvider is supported. For a placeholder use `FadeInImage`. See also ["Fallback for Network Images"](https://github.com/flutter/flutter/issues/6229).
* Moved CacheManager to a separate library for a more generic purpose.

## [0.1.0] - 2017-12-21

* **Breaking change**. Upgraded to Gradle 4.1 and Android Studio Gradle plugin
  3.0.1. Older Flutter projects need to upgrade their Gradle setup as well in
  order to use this version. Instructions can be found
  [here](https://github.com/flutter/flutter/wiki/Updating-Flutter-projects-to-Gradle-4.1-and-Android-Studio-Gradle-plugin-3.0.1).

## [0.0.2] - 10 December 2017
Added an ImageProvider and improved documentation

## [0.0.1] - 2 December 2017
Initial release, should be polished
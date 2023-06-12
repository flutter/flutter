# Cached network image
[![pub package](https://img.shields.io/pub/v/cached_network_image.svg)](https://pub.dartlang.org/packages/cached_network_image)
[![codecov](https://codecov.io/gh/Baseflow/flutter_cached_network_image/branch/master/graph/badge.svg?token=I5qW0RvoXN)](https://codecov.io/gh/Baseflow/flutter_cached_network_image)
[![Build Status](https://app.bitrise.io/app/4e1f9622c1f3458e/status.svg?token=sgBpcZPCUQwW37Z9J494HA&branch=master)](https://app.bitrise.io/app/4e1f9622c1f3458e)

A flutter library to show images from the internet and keep them in the cache directory.

## How to use
The CachedNetworkImage can be used directly or through the ImageProvider.
Both the CachedNetworkImage as CachedNetworkImageProvider have minimal support for web. It currently doesn't include caching.

With a placeholder:
```dart
CachedNetworkImage(
        imageUrl: "http://via.placeholder.com/350x150",
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
 ```
 
 Or with a progress indicator:
 ```dart
CachedNetworkImage(
        imageUrl: "http://via.placeholder.com/350x150",
        progressIndicatorBuilder: (context, url, downloadProgress) => 
                CircularProgressIndicator(value: downloadProgress.progress),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
 ```


````dart
Image(image: CachedNetworkImageProvider(url))
````

When you want to have both the placeholder functionality and want to get the imageprovider to use in another widget you can provide an imageBuilder:
```dart
CachedNetworkImage(
  imageUrl: "http://via.placeholder.com/200x150",
  imageBuilder: (context, imageProvider) => Container(
    decoration: BoxDecoration(
      image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          colorFilter:
              ColorFilter.mode(Colors.red, BlendMode.colorBurn)),
    ),
  ),
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
),
```

## How it works
The cached network images stores and retrieves files using the [flutter_cache_manager](https://pub.dartlang.org/packages/flutter_cache_manager). 

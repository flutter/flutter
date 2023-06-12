# OctoImage

[![pub package](https://img.shields.io/pub/v/octo_image.svg)](https://pub.dartlang.org/packages/octo_image) 
[![Build Status](https://app.bitrise.io/app/151357c29b430916/status.svg?token=U1ggYfh_wrBR0l5elPwryQ&branch=master)](https://app.bitrise.io/app/151357c29b430916)
[![codecov](https://codecov.io/gh/Baseflow/octo_image/branch/master/graph/badge.svg)](https://codecov.io/gh/Baseflow/octo_image)

An image library for showing placeholders, error widgets and transform your image.

Recommended using with [CachedNetworkImage](https://pub.dev/packages/cached_network_image) version 2.2.0 or newer.

<img src="https://raw.githubusercontent.com/Baseflow/octo_image/develop/resources/set-demo.gif" class="center"/>

## Getting Started
The OctoImage widget needs an [ImageProvider](#imageProviders) to show the image. 
You can either supply the widget with a [placeholder or progress indicator](#placeholders-and-progress-indicators), 
an [ImageBuilder](#image-builders) and/or an [error widget](#error-widgets).

However, what OctoImage makes is the use of [OctoSets](#octosets). OctoSets are predefined combinations of placeholders, imagebuilders and error widgets.


So, either set the all the components yourself:
```dart
OctoImage(
  image: CachedNetworkImageProvider(
      'https://blurha.sh/assets/images/img1.jpg'),
  placeholderBuilder: OctoPlaceholder.blurHash(
    'LEHV6nWB2yk8pyo0adR*.7kCMdnj',
  ),
  errorBuilder: OctoError.icon(color: Colors.red),
  fit: BoxFit.cover,
);
```
Or use an OctoSet:
```dart
OctoImage.fromSet(
  fit: BoxFit.cover,
  image: CachedNetworkImageProvider(
    'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4e/Macaca_nigra_self-portrait_large.jpg/1024px-Macaca_nigra_self-portrait_large.jpg',
  ),
  octoSet: OctoSet.circleAvatar(
    backgroundColor: Colors.red,
    text: Text("M"),
  ),
);
```
The CircleAvatar set shows a colored circle with the text inside during loading and when the image failed loading. When the image loads it animates to the image clipped as a circle.

## ImageProviders
The recommended one is CachedNetworkImageProvider, as that supports the progress indicator, error and caching. 
It also works on Android, iOS, web and macOS, although without caching on the web. Make sure you use at least version 2.2.0.

The second best is NetworkImage, but any ImageProvider works in theory. However, for some ImageProviders (such as MemoryImage)
it doesn't make sense to use OctoImage.

## Placeholders and progress indicators
It would be best if you used either a placeholder or a progress indicator, but not both. 
Placeholders are only building once the image starts loading, but progress indicators are rebuilt every time new progress information is received.
So if you don't use that progress indication, for example, with a static image, you should use a placeholder.

The most simple progress indicators use a CircularProgressIndicator.

```dart
OctoImage(
  image: image,
  progressIndicatorBuilder: (context) => 
    const CircularProgressIndicator(),
),
```

```dart
OctoImage(
  image: image,
  progressIndicatorBuilder: (context, progress) {
    double value;
    if (progress != null && progress.expectedTotalBytes != null) {
      value =
          progress.cumulativeBytesLoaded / progress.expectedTotalBytes;
    }
    return CircularProgressIndicator(value: value);
  },
),
```

However, because these are used so often, we prebuild these widgets for you. Just use `OctoProgressIndicator.circularProgressIndicator()`

```dart
OctoImage(
  image: image,
  progressIndicatorBuilder: OctoProgressIndicator.circularProgressIndicator(),
),
```

All included placeholders and progress indicators:

|**OctoPlaceholder**|**Explanation**|
|---|---|
|blurHash|Shows a [BlurHash](https://blurha.sh/) image|
|circleAvatar| Shows a colored circle with a text|
|circularProgressIndicator|Shows a circularProgressIndicator with indeterminate progress.|
|frame|Shows the Flutter Placeholder|

|**OctoProgressIndicator**|**Explanation**|
|---|---|
|circularProgressIndicator|Shows a simple CircularProgressIndicator|




## Error widgets
Error widgets are shown when the ImageProvider throws an error because the image failed loading. You can build a custom widget, or use the prebuild widgets:
```dart
OctoImage(
  image: image,
  errorBuilder: (context, error, stacktrace) =>
    const Icon(Icons.error),
);
```

```dart
OctoImage(
  image: image,
  errorBuilder: OctoError.icon(),
),
```

All included error widgets are:

|**OctoError**|**Explanation**|
|---|---|
|blurHash|Shows a BlurHash placeholder with an error icon.|
|circleAvatar|Shows a colored circle with a text|
|icon|Shows an icon, default to Icons.error|
|placeholderWithErrorIcon|Shows any placeholder with an icon op top.|

## Image builders
Image builders can be used to adapt the image before it is shown. For example the circleAvatar clips the image in a circle, but you could also add an overlay or anything else.

The builder function supplies a context and a child. The child is the image widget that is rendered.

An example that shows the image with 50% opacity:
```dart
OctoImage(
  image: image,
  imageBuilder: (context, child) => Opacity(
    opacity: 0.5,
    child: child,
  ),
),
```

A prebuild image transformer that clips the image as a circle:
```dart
OctoImage(
  image: image,
  imageBuilder: OctoImageTransformer.circleAvatar(),
),
```

All included image transformers are:

|**OctoImageTransformer**|**Explanation**|
|---|---|
|circleAvatar|Clips the image in a circle|

## OctoSets
You get the most out of OctoImage when you use OctoSets. These sets contain a combination of a placeholder or progress indicator,
an image builder and/or an error widget builder. It always contains at least a placeholder or progress indicator and an error widget.

You can use them with OctoImage.fromSet:
```dart
OctoImage.fromSet(
  image: image,
  octoSet: OctoSet.blurHash('LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
),
```

All included OctoSets are:

|**OctoSet**|**Explanation**|
|---|---|
|blurHash|Shows a blurhash as placeholder and error widget. When an error is thrown an icon is shown on top.|
|circleAvatar|Shows a colored circle with text during load and error. Clips the image after successful load.|
|circularIndicatorAndIcon|Shows a circularProgressIndicator with or without progress and an icon on error.|

# Contribute

If you would like to contribute to the plugin (e.g. by improving the documentation, solving a bug or adding a cool new feature), please carefully review our [contribution guide](CONTRIBUTING.md) and send us your [pull request](https://github.com/Baseflow/octo_image/pulls).

PR's with any new prebuild widgets or sets are highly appreciated.

# Support

* Feel free to open an issue. Make sure to use one of the templates!
* Commercial support is available. Integration with your app or services, samples, feature request, etc. Email: [hello@baseflow.com](mailto:hello@baseflow.com)
* Powered by: [baseflow.com](https://baseflow.com)

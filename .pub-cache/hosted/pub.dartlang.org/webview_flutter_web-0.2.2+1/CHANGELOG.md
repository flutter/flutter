## 0.2.2+1

* Updates links for the merge of flutter/plugins into flutter/packages.

## 0.2.2

* Updates `WebWebViewController.loadRequest` to only set the src of the iFrame
  when `LoadRequestParams.headers` and `LoadRequestParams.body` are empty and is
  using the HTTP GET request method. [#118573](https://github.com/flutter/flutter/issues/118573).
* Parses the `content-type` header of XHR responses to extract the correct
  MIME-type and charset. [#118090](https://github.com/flutter/flutter/issues/118090).
* Sets `width` and `height` of widget the way the Engine wants, to remove distracting
  warnings from the development console.
* Updates minimum Flutter version to 3.0.

## 0.2.1

* Adds auto registration of the `WebViewPlatform` implementation.

## 0.2.0

* **BREAKING CHANGE** Updates platform implementation to `2.0.0` release of
  `webview_flutter_platform_interface`. See README for updated usage.
* Updates minimum Flutter version to 2.10.

## 0.1.0+4

* Fixes incorrect escaping of some characters when setting the HTML to the iframe element.

## 0.1.0+3

* Minor fixes for new analysis options.

## 0.1.0+2

* Removes unnecessary imports.
* Fixes unit tests to run on latest `master` version of Flutter.
* Fixes library_private_types_in_public_api, sort_child_properties_last and use_key_in_widget_constructors
  lint warnings.

## 0.1.0+1

* Adds an explanation of registering the implementation in the README.

## 0.1.0

* First web implementation for webview_flutter

<div> 
<h1 align="center">ARCHIVED</h1>
<h3>This package has been archived and will not be maintained anymore. There are several reasons for why I had to make this decision.
<br><br>
This package was initially built as a proof of concept of how would a crossplatform webview work and look like. It was supposed to be used for loading static documents, for creating WYSIWYG editors, or things alike. And it worked (and still works!) fine for that purpose, but it still feels a bit clucky since not every feature can be implemented on all platforms. Like I said, a proof of concept.
<br><br>
But then I wanted to make the web version similar to the mobile version and that was the moment I made the big mistake of allowing the package to bypass websites' iframe policies using *PUBLIC* third party cors proxy servers.
<br><br>
After that, people started to use this package to load their auth forms/bank/paypal payment pages, etc. through *PUBLIC* proxies, which is very unsafe. I tried to explain in the issues that this is not a good idea, but issues regarding auth and similar topics kept popping up.
<br><br>
I should have done this a while ago, but I have to admit that lately I have been rather busy with other projects and didn't have much time for OSS. 
<br>
Thank you everyone.
</h3>
</div>

<p align="center">
<img src="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/images/webviewx_logo.png" height="400" alt="webviewx" />
</p>


[![pub package](https://shields.io/pub/v/webviewx.svg?style=flat-square&color=blue)](https://pub.dev/packages/webviewx)

A feature-rich cross-platform webview using [webview_flutter](https://pub.dev/packages/webview_flutter) for mobile and [iframe](https://api.flutter.dev/flutter/dart-html/IFrameElement-class.html) for web. JS interop-ready.

## Getting started

- [Gallery](#gallery)
- [Basic usage](#basic-usage)
- [Features](#features)
  - [Widget properties](#widget-properties)
  - [Controller properties](#controller-properties)
- [Limitations and notes](#limitations-and-notes)
- [Known issues and TODOs](#known-issues-and-todos)
- [Credits](#credits)
- [License](#license)

---

## Gallery

<div style="text-align: center">
    <table>
        <tr>
        </td>
            <td style="text-align: center;font-size: 22px">
                <p> Mobile</p>
            </td>
            <td style="text-align: center">
                <a href="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/mobile_1.gif">
                    <img src="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/mobile_1.gif" width="200"/>
                </a>
            </td>            
            <td style="text-align: center">
                <a href="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/mobile_2.gif">
                    <img src="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/mobile_2.gif" width="200"/>
                </a>
            </td>
        </tr>
        <tr>
             <td style="text-align: center;font-size: 22px">
                <p> Web</p>
            </td>
            <td style="text-align: center">
                <a href="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/web_1.gif">
                    <img src="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/web_1.gif" width="200"/>
                </a>
            <td style="text-align: center">
                <a href="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/web_2.gif">
                    <img src="https://raw.githubusercontent.com/adrianflutur/webviewx/master/doc/gifs/web_2.gif" width="200"/>
                </a>
            </td>
        </tr>
    </table>

</div>

---

## Basic usage

### **1.** Create a `WebViewXController` inside your stateful widget

```dart
late WebViewXController webviewController;
```

### **2.** Add the WebViewX widget inside the build method, and set the `onWebViewCreated` callback in order to retrieve the controller when the webview is initialized

```dart
WebViewX(
    initialContent: '<h2> Hello, world! </h2>',
    initialSourceType: SourceType.HTML,
    onWebViewCreated: (controller) => webviewController = controller,
    ...
    ... other options
);
```

## **Important !**

If you need to add other widgets on top of the webview (e.g. inside a Stack widget), you _**MUST**_ wrap those widgets with a **WebViewAware** widget.
This does nothing on mobile, but on web it allows widgets on top to intercept gestures. Otherwise, those widgets may not be clickable and/or the iframe will behave weird (unexpected refresh/reload - this is a well known issue).

Also, if you add widgets on top of the webview, wrap them and then you notice that the iframe still reloads unexpectedly, you should check if there are other widgets that sit on top without being noticed, or try to wrap InkWell, GestureRecognizer or Button widgets to see which one causes the problem.

### **3.** Interact with the controller (run the [example app](https://github.com/adrianflutur/webviewx/tree/main/example) to check out some use cases)

```dart
webviewController.loadContent(
    'https://flutter.dev',
    SourceType.url,
);
webviewController.goBack();

webviewController.goForward();
...
...
```

---

## Features

Note: For more detailed information about things such as `EmbeddedJsContent`, please visit each own's `.dart` file from the `utils` folder.

- ## Widget properties

| Feature                                                     | Details                                                                                                                                             |
| ----------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `String` initialContent                                     | Initial webview content                                                                                                                             |
| `SourceType` initialSourceType                              | Initial webview content type (`url, urlBypass or html`)                                                                                             |
| `String?` userAgent                                         | User agent                                                                                                                                          |
| `double` width                                              | Widget's width                                                                                                                                      |
| `double` height                                             | Widget's height                                                                                                                                     |
| `Function(WebViewXController controller)?` onWebViewCreated | Callback that gets executed when the webview has initialized                                                                                        |
| `Set<EmbeddedJsContent>` jsContent                          | A set of EmbeddedJsContent, which is an object that defines some javascript which will be embedded in the page, once loaded (check the example app) |
| `Set<DartCallback>` dartCallBacks                           | A set of DartCallback, which is an object that defines a dart callback function, which will be called from javascript (check the example app)       |
| `bool` ignoreAllGestures                                    | Boolean value that specifies if the widget should ignore all gestures right after it is initialized                                                 |
| `JavascriptMode` javascriptMode                             | This specifies if Javascript should be allowed to execute, or not (allowed by default, you must allow it in order to use above features)            |
| `AutoMediaPlaybackPolicy` initialMediaPlaybackPolicy        | This specifies if media content should be allowed to autoplay when initialized (i.e when the page is loaded)                                        |
| `void Function(String src)?` onPageStarted                  | Callback that gets executed when a page starts loading (e.g. after you change the content)                                                          |
| `void Function(String src)?` onPageFinished                 | Callback that gets executed when a page finishes loading                                                                                            |
| `NavigationDelegate?` navigationDelegate                    | Callback that, if not null, gets executed when the user clicks something in the webview (on Web it only works for `SourceType.urlBypass`, for now)  |
| `void Function(WebResourceError error)?` onWebResourceError | Callback that gets executed when there is an error when loading resources ( [issues on web](#known-issues-and-todos) )                              |
| `WebSpecificParams` webSpecificParams                       | This is an object that contains web-specific options. Theese are not available on mobile (_yet_)                                                    |
| `MobileSpecificParams` mobileSpecificParams                 | This is an object that contains mobile-specific options. Theese are not available on web (_yet_)                                                    |

---

- ## Controller properties

| Feature                                                   | Usage                                                                                          |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Load URL that allows iframe embedding                     | webviewController.`loadContent(URL, SourceType.URL)`                                           |
| Load URL that doesnt allow iframe embedding               | webviewController.`loadContent(URL, SourceType.URL_BYPASS)`                                    |
| Load URL that doesnt allow iframe embedding, with headers | webviewController.`loadContent(URL, SourceType.URL_BYPASS, headers: {'x-something': 'value'})` |
| Load HTML from string                                     | webviewController.`loadContent(HTML, SourceType.HTML)`                                         |
| Load HTML from assets                                     | webviewController.`loadContent(HTML, SourceType.HTML, fromAssets: true)`                       |
| Check if you can go back in history                       | webviewController.`canGoBack()`                                                                |
| Go back in history                                        | webviewController.`goBack()`                                                                   |
| Check if you can go forward in history                    | webviewController.`canGoForward()`                                                             |
| Go forward in history                                     | webviewController.`goForward()`                                                                |
| Reload current content                                    | webviewController.`reload()`                                                                   |
| Check if all gestures are ignored                         | webviewController.`ignoringAllGestures`                                                        |
| Set ignore all gestures                                   | webviewController.`setIgnoreAllGestures(value)`                                                |
| Evaluate "raw" javascript code                            | webviewController.`evalRawJavascript(JS)`                                                      |
| Evaluate "raw" javascript code in global context ("page") | webviewController.`evalRawJavascript(JS, inGlobalContext: true)`                               |
| Call a JS method                                          | webviewController.`callJsMethod(METHOD_NAME, PARAMS_LIST)`                                     |
| Retrieve webview's content                                | webviewController.`getContent()`                                                               |
| Get scroll position on X axis                             | webviewController.`getScrollX()`                                                               |
| Get scroll position on Y axis                             | webviewController.`getScrollY()`                                                               |
| Scrolls by `x` on X axis and by `y` on Y axis             | webviewController.`scrollBy(int x, int y)`                                                     |
| Scrolls exactly to the position `(x, y)`                  | webviewController.`scrollTo(int x, int y)`                                                     |
| Retrieves the inner page title                            | webviewController.`getTitle()`                                                                 |
| Clears cache                                              | webviewController.`clearCache()`                                                               |

---

## Limitations and notes

While this package aims to put together the best of both worlds, there are differences between web and mobile.

- Running and building

  First, this package was being developed while the default `web renderer` was `html`. Now(Flutter 2, Dart 2.12), the default renderer is `canvaskit`.

  From my experience, this package does behave a little bit weird on canvaskit, so you should use the `html` renderer.

  To do this, you have to run your ordinary `flutter run -d chrome` command with the `--web-renderer html` extra argument, like this:

  ```bash
  flutter run -d chrome --web-renderer html
  ```

  for running and

  ```bash
  flutter build web --web-renderer html
  ```

  for building.

- Diferences between Web and Mobile behaviour:

  See [issues/#27](https://github.com/adrianflutur/webviewx/issues/27)

- About content loading on Web

  To make the web version (iframe) work as it is, I had to use some of the code from [x-frame bypass](https://github.com/niutech/x-frame-bypass) in order to make a request to a CORS proxy, which removes the headers that block iframe embeddings.

  This might seem like a hack, and it really is, but I couldn't find any other way to make the iframe behave similar to the mobile webview (which is some kind of an actual browser, that's why everything works there by default).

- About Web navigation

  On web, the history navigation stack is built from scratch because I couldn't handle iframe's internal history the right way.

---

## Known issues and TODOs

- [ x ] On web, user-agent and headers only work when using `SourceType.urlBypass`, and they only have effect the first time being used (`view/web.dart`)

- [ x ] On web, it should be possible to send any errors caught when loading an `urlBypass` to a dart callback, which will then be sent through the `onWebResourceError` callback, just like on the mobile version (`utils/x_frame_options_bypass.dart`)

- [ x ] On web, it should be possible to add a custom proxy list without the js null-checking mess (`utils/x_frame_options_bypass.dart`)

- [ ? ] Eventually (if possible), most if not all properties from `WebSpecificParams` and `MobileSpecificParams` should merge and theese two objects may disappear

- [ x ] On mobile, the controller's value's source type becomes out of sync when moving back and forth in history. This happens because the url change is not yet intercepted and set the model accordingly (shouldn't be hard to fix).

- [ ] On mobile, the controller's callJsMethod doesnt throw an error if the operation failed. Instead it only shows the error in console.

- [ ] Add tests

- List open, there may be others

## Credits

This package wouldn't be possible without the following:

- [webview_flutter](https://github.com/flutter/plugins/tree/master/packages/webview_flutter) for the mobile version
- [easy_web_view](https://github.com/rodydavis/easy_web_view) for ideas and starting point for the web version
- [pointer_interceptor](https://pub.dev/packages/pointer_interceptor) for fixing iframe issues when other widgets are on top of it (see [above](#important-))
- [x-frame-bypass](https://github.com/niutech/x-frame-bypass) for allowing the iframe to bypass websites' X-Frame-Options: deny/same-origin headers, thus allowing us to load any webpage (just like on mobile)
- https://cors.bridged.cc/ for the free CORS proxy
- https://api.codetabs.com/ for the free CORS proxy

* And last but not least, http://deversoft.ro (the company I work for) for motivating me throughout the development process

## License

[MIT](https://github.com/adrianflutur/webviewx/blob/master/LICENSE)

## 0.2.1

- Breaking change

  - WebViewX width and height are now required (due to the fact that the web version always needs a width and a height)

- Added the option to use hybrid composition for Android WebViews in `MobileSpecificParams`
- Added a new public default CORS proxy service for Web
- Update dependencies

## 0.2.0

- Deprecated pedantic. Adopted lint instead.
- Abstracted the controller and the widget. Soon it will be possible to add multiple implementations, such as windows, macOs or linux.
- Renamed SourceType enum and AutoMediaPlaybackPolicy enums acording to lint rules (camelCase instead of SCREAM_CASE)
- (web) Moved huge part of JS logic to Dart = better control over what happens there (might move it all to Dart soon)
- (web) Added the option to supply your own list of BypassProxy objects. This means anyone can now spin up their own proxy server and add it to the list, if they don't want to run on the default public ones.
- (web) Implemented navigationDelegate
- (web) Fixed onPageStarted and onPageFinished callbacks. Now they provide the correct information.
- (web) Implemented missing features from WebviewXController which were available on mobile:

```
    Future getScrollX();
    Future getScrollY();
    Future scrollBy(int x, int y);
    Future scrollTo(int x, int y);
    Future<String?> getTitle();
    Future clearCache();
```

- (mobile) Fixed sourceType desync
- (mobile) Fixed URI data: source messing up sometimes due to the encoding
- Update documentation
- Update dependencies

## 0.1.0

- Migrated to null safety
- Fixed migration issues
- Updated the example app
- Bumped dependencies version

## 0.0.4

- It is now possible to add and execute JS inside webpages that were loaded using SourceType.URL_BYPASS
- Fixed small issue when loading urls, where the proxies would fail fetching the page with error 400
- Bumped dependencies version

## 0.0.3

- Fixed more analyzer warnings
- Fixed unidentified platform issue
- Improved code in the mobile version
- Bumped dependencies version

## 0.0.2

- Fixed many documentation issues and analyzer warnings

## 0.0.1

- Initial release

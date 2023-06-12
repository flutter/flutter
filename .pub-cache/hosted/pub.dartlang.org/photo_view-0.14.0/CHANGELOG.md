<a name="0.14.0"></a>
# [0.14.0](https://github.com/bluefireteam/photo_view/releases/tag/0.14.0) - 24 May 2022

## Fixed
- Made wantKeepAlive parameter to make it optional  #479
- Update README Urls #471
- Null check operator used on a null value #476
- Flutter Update: 2.10.0 - Fix: Looking up a deactivated widget's ancestor is unsafe fix  #499 




[Changes][0.14.0]


<a name="0.13.0"></a>
# [0.13.0](https://github.com/bluefireteam/photo_view/releases/tag/0.13.0) - 05 Oct 2021

## Fixed
- Network image issue on flutter 2.5 #467 #464

## Added
- allowImplicitScrolling for preloading next page on PageView #458
- `AutomaticKeepAliveClientMixin` to keep state on photoview #452





[Changes][0.13.0]


<a name="0.12.0"></a>
# [0.12.0](https://github.com/bluefireteam/photo_view/releases/tag/0.12.0) - 19 Jul 2021

## Fixed:
- 'PointerEvent' can't be assigned to the parameter type 'PointerDownEvent' https://github.com/fireslime/photo_view/issues/423#issuecomment-847681903 #420 #441 #442 #445
- Fix onScaleEnd operator #415

## Added:
- Added enablePanAlways to allow the user to pan any view without restrictions #427

[Changes][0.12.0]


<a name="0.11.1"></a>
# [0.11.1](https://github.com/bluefireteam/photo_view/releases/tag/0.11.1) - 09 Mar 2021

## Fixed:
- Wrong null check operator #399 #400 

[Changes][0.11.1]


<a name="0.11.0"></a>
# [0.11.0](https://github.com/bluefireteam/photo_view/releases/tag/0.11.0) - 07 Mar 2021


## Added
- `initialScale` on controller #322 #289 
- [Breaking] Sound null safety support thanks to @DevNico #375 

## Removed
- `loadFailedChild` in favor of `errorBuilder`. #320 #287

[Changes][0.11.0]


<a name="0.10.3"></a>
# [0.10.3](https://github.com/bluefireteam/photo_view/releases/tag/0.10.3) - 15 Nov 2020

## Fixed
- Fix double and single tap on gallery #293 #271 #326

[Changes][0.10.3]


<a name="0.10.2"></a>
# [0.10.2](https://github.com/bluefireteam/photo_view/releases/tag/0.10.2) - 22 Aug 2020

## Added
- `errorBuilder` option to show a widget when things go south when retrieving the image. #320 #287

## Deprecated
- `loadFailedChild` in favor of `errorBuilder`. #320 #287

## Fixed
- `loadFailedChild` doesn't show error widget #320 #316 
- Hero animation should work in all situations #320 #303 

[Changes][0.10.2]


<a name="0.10.1"></a>
# [0.10.1](https://github.com/bluefireteam/photo_view/releases/tag/0.10.1) - 18 Aug 2020

## Added
- Add ability to disable gestures #233 #234
- Allow programmatic rotate when PhotoView enableRotation is disabled #259 #257

[Changes][0.10.1]


<a name="0.10.0"></a>
# [0.10.0](https://github.com/bluefireteam/photo_view/releases/tag/0.10.0) - 12 Aug 2020

## Removed [breaking]
- `loadingChild` options in both `PhotoView` and `PhotoViewGallery` in favor of `loadingBuilder`.  Previously deprecated; #307 

## Fixed
- Unnecessary scale state controller value streamed #227 #267 
- GestureDetector winning arena issue that made the gallery not work well #266 #212 
- When the network goes down, photo_view would crash #275 #308 


## Internal
- Updatde example app #300 

[Changes][0.10.0]


<a name="0.9.2"></a>
# [0.9.2](https://github.com/bluefireteam/photo_view/releases/tag/0.9.2) - 15 Feb 2020

## Added
- `loadingBuilder` which provides a way to create a progress loader. Thanks to @neckaros #250 #254

## Deprecated
- `loadingChild` options in both `PhotoView` and `PhotoViewGallery` in favor of `loadingBuilder`;

## Fixed
- Gallery undefined issue #251
- PhotoViewCore throws when using PhotoCiewScaleStateController within gallery. #254 #217 
- `basePosition` on `PhotoViewGallery` being ignored #255 #219



[Changes][0.9.2]


<a name="0.9.1"></a>
# [0.9.1](https://github.com/bluefireteam/photo_view/releases/tag/0.9.1) - 07 Jan 2020

## Added
- `filterQuality` option to the property to improve image quality after scale #228 
- `loadFailedChild` option to specify a widget instance to be shown when the image retrieval process failed #231

## Changed
- **Internal:** stop using deprecated `inheritFromWidgetOfExactType` in favor of `dependOnInheritedWidgetOfExactType` #235
- Made childSize optional for PhotoViewGalleryPageOptions.customChild #229 


[Changes][0.9.1]


<a name="0.9.0"></a>
# [0.9.0](https://github.com/bluefireteam/photo_view/releases/tag/0.9.0) - 21 Nov 2019

## Added

- `tightMode` option that allows `PhotoView` to be used inside a dialog. #167 #211
- `PhotoViewGestureDetectorScope` widget that allows `PhotoView` to be used on scrollable contexts (PageView, list view etc) #211 
-  Dialogs and onetap example on the exmaple app #211

## Changed
- Made `childSize` to be optional. Now it expands if no value is provided #210 #199 

[Changes][0.9.0]


<a name="0.8.2"></a>
# [0.8.2](https://github.com/bluefireteam/photo_view/releases/tag/0.8.2) - 19 Nov 2019

## Fixed 
- Clamping position on controller #208 #160 

## Added
- Exposing hit test on gesture detector #209 

[Changes][0.8.2]


<a name="0.8.1"></a>
# [0.8.1](https://github.com/bluefireteam/photo_view/releases/tag/0.8.1) - 19 Nov 2019

## Added
- Web support on the example app, thanks to @YuyaAbo #201 

## Fixed
- ScaleState were not respected when resizing photoview widget. #163 #207 

[Changes][0.8.1]


<a name="0.8.0"></a>
# [0.8.0](https://github.com/bluefireteam/photo_view/releases/tag/0.8.0) - 07 Nov 2019

## Changed
- Change to our own custom gesture detector, making it work nicely with an extenal gesture detector. It solves #41 which was previously tackled on #185 but with some minor bugs (vertical scrolling pageviews and proper responsiveness on pan gestures). #197 
- Renamed `PhotoViewImageWrapper` to `PhotoViewCore` and reorganized src files, not externally relevant. #197 

## Removed
- [BREAKING] Removed unnecessary function typedefs like `PhotoViewScaleStateChangedCallback` #197 
- [BREAKING] Removed `usePageViewWrapper` option from the gallery #197 




[Changes][0.8.0]


<a name="0.7.0"></a>
# [0.7.0](https://github.com/bluefireteam/photo_view/releases/tag/0.7.0) - 05 Nov 2019

### Solving a one year issue

## Added
- Detect image edge behavior #185 #41 

[Changes][0.7.0]


<a name="0.6.0"></a>
# [0.6.0](https://github.com/bluefireteam/photo_view/releases/tag/0.6.0) - 16 Oct 2019

## Fixed
- Tons of typos on docs #189 
- Weird rotation behavior #189 #174 #92 
- Example app deps update #189 
- General code improvs #189 

[Changes][0.6.0]


<a name="0.5.0"></a>
# [0.5.0](https://github.com/bluefireteam/photo_view/releases/tag/0.5.0) - 07 Sep 2019

## Changed
 - [BREAKING] All hero attributes where moved into a new data class: `PhotoViewHeroAttributes`. #175 #177 
 - Some internal changes fixed a severe memory leak involving controllers delegate: #180 

[Changes][0.5.0]


<a name="0.4.2"></a>
# [0.4.2](https://github.com/bluefireteam/photo_view/releases/tag/0.4.2) - 23 Jul 2019

## Fixed
- `onTapUp` and `onTapDown` on `PhotoViewGallery` #146 

[Changes][0.4.2]


<a name="0.4.1"></a>
# [0.4.1](https://github.com/bluefireteam/photo_view/releases/tag/0.4.1) - 11 Jul 2019

First release since halt due to Flutter breaking changes.

With this version, Photo view is stable compatible. It means that every new release must be compatible with the channel master. Breaking changes that are still on master or beta channels will not be included on any new release.
## Added
- The PageView reverse parameter #159 

[Changes][0.4.1]


<a name="0.4.0"></a>
# [0.4.0](https://github.com/bluefireteam/photo_view/releases/tag/0.4.0) - 25 May 2019

 ** Fix Flutter breaking change **

- [BREAKING] This release requires Flutter 1.6.0, which in the date of this release, is not even beta. This is due to several master channel users who complained on a recent breaking change which broke one of the PhotoView core features. #144 #143 #147 https://github.com/flutter/flutter/pull/32936



[Changes][0.4.0]


<a name="0.3.3"></a>
# [0.3.3](https://github.com/bluefireteam/photo_view/releases/tag/0.3.3) - 08 May 2019

## Compatibility fix

- Dowgraded Flutter SDK version to 1.4.7

[Changes][0.3.3]


<a name="0.3.2"></a>
# [0.3.2](https://github.com/bluefireteam/photo_view/releases/tag/0.3.2) - 08 May 2019

## Fixed
- `FlutterError` compatibility with breaking changing breaking for Flutter channel master users. #135 #136 #137 
- `onTapUp` and `onTapDown` overriding higher onTap handle #134 #138 

[Changes][0.3.2]


<a name="0.3.1"></a>
# [0.3.1](https://github.com/bluefireteam/photo_view/releases/tag/0.3.1) - 23 Apr 2019

## Added
- Custom child builder to `PhotoViewGalleryPageOptions` that enables the usage of custom children in the gallery. #126 #131 

[Changes][0.3.1]


<a name="0.3.0"></a>
# [0.3.0](https://github.com/bluefireteam/photo_view/releases/tag/0.3.0) - 21 Apr 2019

## Changed
- [BREAKING] `PhotoViewControllerValue` does not contain `scaleState` value anymore, now you should control that value ona separate controller: `PhotoViewScaleStateController`. That is due to some concerns expressed #127. All details on [controller docs](https://pub.dartlang.org/documentation/photo_view/latest/photo_view/PhotoView-class.html#controllers) #129 #127 

## Added
- `scaleStateController` option to `PhotoView` and `PhotoViewGalleryPageOptions` #129 


[Changes][0.3.0]


<a name="0.2.5"></a>
# [0.2.5](https://github.com/bluefireteam/photo_view/releases/tag/0.2.5) - 20 Apr 2019

## Added
- Two new callbacks `onTapUp` and `onTapDown` #122 
- A exclusive stream for `scaleState` in the controller #124 

## Fixed
- Gallery swipe glitch: do not lock when zooming in #124 #105 
- `herotag` is an Object, not a String anymore #122 

## Removed
- [BREAKING] Scale state `zooming` has been replaced by `zoomingIn` and `zoomingOut` #124 



[Changes][0.2.5]


<a name="0.2.4"></a>
# [0.2.4](https://github.com/bluefireteam/photo_view/releases/tag/0.2.4) - 09 Apr 2019

## Changed
- [BREAKING] `PhotoViewController` no longer extends `ValueNotifier`, instead, it contains one. Method `addListener` is no longer available due to a race condition that creates bugs. #106 

[Changes][0.2.4]


<a name="0.2.3"></a>
# [0.2.3](https://github.com/bluefireteam/photo_view/releases/tag/0.2.3) - 09 Apr 2019

## Added
- New builder constructor for `PhotoViewGallery` #119  #78 #113 

[Changes][0.2.3]


<a name="0.2.2"></a>
# [0.2.2](https://github.com/bluefireteam/photo_view/releases/tag/0.2.2) - 08 Apr 2019

## Fixed:

- Make `initialScale`, `minScale` and `maxScale` option work on `PhotoViewGallery`

[Changes][0.2.2]


<a name="0.2.1"></a>
# [0.2.1](https://github.com/bluefireteam/photo_view/releases/tag/0.2.1) - 08 Apr 2019

## Added:
- `scrollPhisics` option to `PhotoViewGallery`

[Changes][0.2.1]


[0.14.0]: https://github.com/bluefireteam/photo_view/compare/0.13.0...0.14.0
[0.13.0]: https://github.com/bluefireteam/photo_view/compare/0.12.0...0.13.0
[0.12.0]: https://github.com/bluefireteam/photo_view/compare/0.11.1...0.12.0
[0.11.1]: https://github.com/bluefireteam/photo_view/compare/0.11.0...0.11.1
[0.11.0]: https://github.com/bluefireteam/photo_view/compare/0.10.3...0.11.0
[0.10.3]: https://github.com/bluefireteam/photo_view/compare/0.10.2...0.10.3
[0.10.2]: https://github.com/bluefireteam/photo_view/compare/0.10.1...0.10.2
[0.10.1]: https://github.com/bluefireteam/photo_view/compare/0.10.0...0.10.1
[0.10.0]: https://github.com/bluefireteam/photo_view/compare/0.9.2...0.10.0
[0.9.2]: https://github.com/bluefireteam/photo_view/compare/0.9.1...0.9.2
[0.9.1]: https://github.com/bluefireteam/photo_view/compare/0.9.0...0.9.1
[0.9.0]: https://github.com/bluefireteam/photo_view/compare/0.8.2...0.9.0
[0.8.2]: https://github.com/bluefireteam/photo_view/compare/0.8.1...0.8.2
[0.8.1]: https://github.com/bluefireteam/photo_view/compare/0.8.0...0.8.1
[0.8.0]: https://github.com/bluefireteam/photo_view/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/bluefireteam/photo_view/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/bluefireteam/photo_view/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/bluefireteam/photo_view/compare/0.4.2...0.5.0
[0.4.2]: https://github.com/bluefireteam/photo_view/compare/0.4.1...0.4.2
[0.4.1]: https://github.com/bluefireteam/photo_view/compare/0.4.0...0.4.1
[0.4.0]: https://github.com/bluefireteam/photo_view/compare/0.3.3...0.4.0
[0.3.3]: https://github.com/bluefireteam/photo_view/compare/0.3.2...0.3.3
[0.3.2]: https://github.com/bluefireteam/photo_view/compare/0.3.1...0.3.2
[0.3.1]: https://github.com/bluefireteam/photo_view/compare/0.3.0...0.3.1
[0.3.0]: https://github.com/bluefireteam/photo_view/compare/0.2.5...0.3.0
[0.2.5]: https://github.com/bluefireteam/photo_view/compare/0.2.4...0.2.5
[0.2.4]: https://github.com/bluefireteam/photo_view/compare/0.2.3...0.2.4
[0.2.3]: https://github.com/bluefireteam/photo_view/compare/0.2.2...0.2.3
[0.2.2]: https://github.com/bluefireteam/photo_view/compare/0.2.1...0.2.2
[0.2.1]: https://github.com/bluefireteam/photo_view/tree/0.2.1

 <!-- Generated by changelog-from-release -->

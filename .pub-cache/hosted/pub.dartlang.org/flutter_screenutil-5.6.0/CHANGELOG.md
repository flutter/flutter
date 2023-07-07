# 5.6.0
- bug fix: #434
- add w and h on EdgeInsets,Radius,BorderRadius,BoxConstraints

# 5.5.4
- Bug Fix: False sizes when using DevicePreview

# 5.5.3+2
- Fix #398

# 5.5.3+1
- Fix compatibility with flutter sdk 2.x

# 5.5.3
- Bug Fix: Some widgets disapear because of parent rebuild.
- Bug Fix: issue #362. Null check operator used on a null value when using ScreenUtil.init().
- Re-add context to builder parameters **(users request)**.
- Add some standard rebuild factors.

# 5.5.2
- Add rebuildFactor property
- Bug Fix: False sizes when resizing

# 5.5.1
- Bug Fix: Assertion Failed (Find MediaQuery in ancestors)
- Some performance improvements and fixes

# 5.5.0
- Bug Fix: Reaching context that no longer used.

# 5.4.0+1
- delete log

# 5.4.0
- merge #352

# 5.3.1
- add num.verticalSpacingRadius
  num.horizontalSpaceRadius
  num.setVerticalSpacingFromWidth
- update num.horizontalSpace
  
# 5.3.0
- For the size, use the context to get it first, which needs to provide the Context
  More rigorous context checking

# 5.2.0

- Rollback of 5.1.1 commit
- Fix the problem of inaccurate height
- merge #332(https://github.com/OpenFlutter/flutter_screenutil/pull/332)
  add
  num.setVerticalSpacing  // SizedBox(height: num * scaleHeight)
  num.horizontalSpace  // SizedBox(height: num * scaleWidth)

# 5.1.1

- .w,.h use MediaQuery

# 5.1.0

- Break Change: updated the first initialization method, please refer to README.md

# 5.0.4

- Break Change : add setContext() , the first initialization method requires calling
- fix # 310
- update ReadMe.md

# 5.0.3

- init method add "context" param
- update ReadMe.md

# 5.0.2+1

- fix splitScreenMode to false

# 5.0.2

- add "minTextAdapt" param , Font adaptation is based on the minimum value of width and height or
  only based on width(default)
- update readme

# 5.0.1+3

- fix .r

# 5.0.1+2

- Text adaptation no longer considers the height of the screen

# 5.0.1+1

- split default value change to false

# 5.0.1

- support for split screen
- add number.sm (return min(number.sp , number))

# 5.0.0+2

- update readme

# 5.0.0+1

- update readme

# 5.0.0

-Breaking change. Use a new way to set font scaling -Deprecated ssp and nsp

# 5.0.0-nullsafety.11

- revert 5.0.0-nullsafety.10
- fix #230

# 5.0.0-nullsafety.10

- fix #228

# 5.0.0-nullsafety.9

- Supplementary documentation, supports two initialization methods

# 5.0.0-nullsafety.8

- merge v4
- Add a method to get the screen orientation

# 5.0.0-nullsafety.7

- fix #221

# 5.0.0-nullsafety.6

- merge #216 #218

# 5.0.0-nullsafety.5

- Optimize initialization method

# 5.0.0-nullsafety.4

- merge #205

# 5.0.0-nullsafety.3

- merge 4.0.2+3

# 5.0.0-nullsafety.2

- merge 4.0.2+2 #186

# 5.0.0-nullsafety.1

- merge 4.0.1 ,4.0.2 #183

# 5.0.0-nullsafety.0

- Migrated flutter_screenutil to non-nullable

# 4.0.2

- add r(),adapt according to the smaller of width or height

# 4.0.1

- Modify the initialization unit to dp
- delete screenWidthPx and screenHeightPx(No one use these method,I guess)

# 4.0.0

- update to 4.0.0

# 4.0.0-beta3

- Optimize the way of initialization

# 4.0.0-beta2

- fix error:'window is not a type.'

# 4.0.0-beta1

- change readme

# 4.0.0-beta

- Modified the initialization method
- Support font adaptation in themedata

# 3.2.0

- Modify the method name to be more semantic: wp->sw , hp->sh
- Remove the restriction of flutter version
- Modify the return type num to double

# 3.1.1

- change readme

# 3.1.0

- Use the way back to v2 version
- Modify registration method

# 3.0.2+1

- Guide users to use V2 version

# 3.0.2

- Change the unit of'statusBarHeight' and 'bottomBarHeight' to dp

# 3.0.1

- update readme

# 3.0.0

- After a period of experimentation, I think it's time to release the official version

# 3.0.0-beta.2

- readme update

# 3.0.0-beta.1

**BREAKING CHANGES**

- `BuildContext` is no more required while initializing. i.e. ScreenUtil.init(~~context~~)
- Initialize size of design draft using `designSize` instead of width & height.
- All the static methods are now member methods.

# 2.3.1

- add textStyle Example.

# 2.3.0

- We still need context to initialize, sorry.

# 2.2.0

- add 'wp','hp'. Get the height/width of the screen proportionally
- For example: 0.5.wp : Half the width of the screen.

# 2.1.0

- add 'nsp' , you can use 'fontSize: 24.nsp' instead of 'fontSize: ScreenUtil().setSp(24,
  allowFontScalingSelf: false)'

# 2.0.0

- Use `MediaQueryData.fromWindow(window)` instead of `MediaQuery.of(context)`, no context parameter
  required
- API changes, please note

# 1.1.0

- support ExtensionMethod Dart-SDK-2.6.0
- you can use 'width: 50.w' instead of 'width: ScreenUtil().setWidth(50)'
  '50.h' instead of 'ScreenUtil().setHeight(50)'
  '24.sp' instead of 'ScreenUtil().setSp(24)'
  '24.ssp' instead of 'ScreenUtil().setSp(24, allowFontScalingSelf: true)'

# 1.0.2

- fix #89
- 优化屏幕旋转效果
- 字体适配统一使用宽度

# 1.0.1

- Rebuild code, change API Delete "getInstance()", please use "ScreenUtil ()" instead of "
  ScreenUtil.getInstance()"
  use "ScreenUtil().setSp(24, allowFontScalingSelf: true)" instead of "ScreenUtil.getInstance()
  .setSp(14, true)"
- Modify the initialization method
- Fix #68
- Change example code Example CompileSdkVersion change to 28

**If there is significant impact, please return to 0.7.0**

# 0.7.0

- Replace textScaleFactory with textScaleFactor , It's a typo.

# 0.6.1

- Add return types to all methods.

# 0.6.0

- Completing comments , adding English commentsWelcome to add, correct
- 参数同时支持传入 int / double 或者是var size = 100 , var size = 100.0.
- The argument also supports passing in in / double / var size = 100 /var size = 100.0

# 0.5.3

- Change the units of statusBarHeight and bottomBarHeight to dp

# 0.5.2

- Change the parameter type from int to double

- setWidth,setHeight,setSp. for example: you can use setWidth(100) or setWidth(100.0)

# 0.5.1

- Fix the wrong way of using

- It is recommended to use `ScreenUtil.getInstance()` instead of `ScreenUtil()` , for
  example: `ScreenUtil.getInstance().setHeight(25)` instead of `ScreenUtil().setHeight(25)`

# 0.4.4

- Fix bugs that default fonts change with the system

# 0.4.3

- Modify the font to change with the system zoom mode. The default value is false.

- setSp(int fontSize, [allowFontScaling = false]) => allowFontScaling ? setWidth(fontSize) \*
  \_textScaleFactor
  : setWidth(fontSize);

# 0.4.2

- add two Properties
- ///Current device width dp
- ///当前设备宽度 dp
- ScreenUtil.screenWidthDp

- ///Current device height dp
- ///当前设备高度 dp
- ScreenUtil.screenHeightDp

# 0.4.1

- Fix font adaptation issues

# 0.4.0

- Optimize font adaptation method

# 0.3.1

- Perfect documentation
- Width is enlarged relative to the design draft => The ratio of font and width to the size of the
  design
- Height is enlarged relative to the design draft => The ratio of height width to the size of the
  design

# 0.3.0

- Add font size adaptation

# 0.2.2

- Optimize documentation

# 0.0.2

- Fixed bug when releasing

# 0.0.1

- first version





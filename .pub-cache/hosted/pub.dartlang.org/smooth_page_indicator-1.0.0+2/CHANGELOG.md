# ChangeLog
## [1.0.0+2]
- fix readme file (attempt 2)
## [1.0.0+1]
- fix readme file
## [1.0.0] [Breaking change in JumpingDotEffect]
- Fix ignored active dot stroke in ColorTransitionEffect #40
- Fix crash when last item is removed #21
- Add loop support
- Add variants to SwapEffect (zRotation, YRotation)
- Add variants to WormEffect (thin worm)
- Rename [elevation] property from JumpingDotEffect [Breaking]
- Add customization params to JumpingDotEffect (jumpScale, verticalOffset)
- Add CustomizableEffect
## [0.3.0-nullsafety.0]
- Move to null safety
- Add runnable example
- change default offset value to 16.0 

## [0.2.0]
- Add support for vertical direction
- Add on dot clicked callback
- Add AnimatedSmoothIndicator which works without a PageController

## [0.1.5]
- Add off-canvas scrolling effect ScrollingDotsEffect
- Add Active color with transition to ScaleEffect

## [0.1.4]

- Add Active color with transition to ExpendingDotEffect

## [0.1.3]

- Fix indicator always starts at zero index regardless of the controller's initial page

## [0.1.2+1]

- Add individual demos for each effect to README file

## [0.1.2]

- Add Color Transition effect

### Breaking change!

- Replace isRTL with textDirection
- Directionality is now handled the flutter way instead of manually passing a bool value to isRTL property

## [0.1.1]

- Add documentation
- Edit README file

## [0.1.0+1]

- Edit README file.

## [0.1.0]

- Initial release.

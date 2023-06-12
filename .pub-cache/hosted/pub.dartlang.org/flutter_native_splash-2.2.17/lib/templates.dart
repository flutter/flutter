part of flutter_native_splash_cli;

// Android-related templates

const String _androidLaunchItemXml = '''
    <item>
        <bitmap android:gravity="center" android:src="@drawable/splash" />
    </item>
''';

const String _androidBrandingItemXml = '''
    <item>
        <bitmap android:gravity="center" android:src="@drawable/branding" />
    </item>
''';

const String _androidLaunchBackgroundXml = '''
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <bitmap android:gravity="fill" android:src="@drawable/background" />
    </item>
</layer-list>
''';

const String _androidStylesXml = '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''';

const String _androidStylesNightXml = '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is on -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:forceDarkAllowed">false</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''';

const String _androidV31StylesXml = '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.
         
         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''';

const String _androidV31StylesNightXml = '''
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowSplashScreenBackground">@drawable/launch_background</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.
         
         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
''';

// iOS-related templates
const String _iOSLaunchScreenStoryboardContent = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="12121" systemVersion="16G29" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
    <dependencies>
        <deployment identifier="iOS"/>
        <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="12089"/>
    </dependencies>
    <scenes>
        <!--View Controller-->
        <scene sceneID="EHf-IW-A2E">
            <objects>
                <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                    <layoutGuides>
                        <viewControllerLayoutGuide type="top" id="Ydg-fD-yQy"/>
                        <viewControllerLayoutGuide type="bottom" id="xbc-2k-c8Z"/>
                    </layoutGuides>
                    <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                        <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                        <subviews>
                            <imageView opaque="NO" clipsSubviews="YES" multipleTouchEnabled="YES" contentMode="center" image="[LAUNCH_IMAGE_PLACEHOLDER]" translatesAutoresizingMaskIntoConstraints="NO" id="YRO-k0-Ey4">
                            </imageView>
                        </subviews>
                        <color key="backgroundColor" red="1" green="1" blue="1" alpha="1" colorSpace="custom" customColorSpace="sRGB"/>
                        <constraints>
                            <constraint firstItem="YRO-k0-Ey4" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="1a2-6s-vTC"/>
                            <constraint firstItem="YRO-k0-Ey4" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="4X2-HB-R7a"/>
                        </constraints>
                    </view>
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
            </objects>
            <point key="canvasLocation" x="53" y="375"/>
        </scene>
    </scenes>
    <resources>
        <image name="[LAUNCH_IMAGE_PLACEHOLDER]" width="168" height="185"/>
    </resources>
</document>
''';

const String _iOSContentsJson = '''
{
  "images" : [
    {
      "filename" : "LaunchImage.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "LaunchImage@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "LaunchImage@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

const String _iOSContentsJsonDark = '''
{
  "images" : [
    {
      "filename" : "LaunchImage.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "LaunchImageDark.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "LaunchImage@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "LaunchImageDark@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "LaunchImage@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "LaunchImageDark@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

const String _iOSBrandingContentsJson = '''
{
  "images" : [
    {
      "filename" : "BrandingImage.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "BrandingImage@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "BrandingImage@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

const String _iOSBrandingContentsJsonDark = '''
{
  "images" : [
    {
      "filename" : "BrandingImage.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "BrandingImageDark.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "BrandingImage@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "BrandingImageDark@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "BrandingImage@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "BrandingImageDark@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

const String _iOSLaunchBackgroundJson = '''
{
  "images" : [
    {
      "filename" : "background.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

const String _iOSLaunchBackgroundDarkJson = '''
{
  "images" : [
    {
      "filename" : "background.png",
      "idiom" : "universal"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "darkbackground.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
''';

const String _iOSLaunchBackgroundSubview =
    '<imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleToFill" image="[LAUNCH_BACKGROUND_PLACEHOLDER]" translatesAutoresizingMaskIntoConstraints="NO" id="tWc-Dq-wcI" />';

const String _iOSBrandingSubview =
    '<imageView clipsSubviews="YES" userInteractionEnabled="NO" contentMode="scaleToFill" image="[BRANDING_IMAGE_PLACEHOLDER]" translatesAutoresizingMaskIntoConstraints="NO" id="Uyq-Kz-ftE" />';

const String _iOSLaunchBackgroundConstraints = '''
<constraints>
  <constraint firstItem="YRO-k0-Ey4" firstAttribute="leading" secondItem="Ze5-6b-2t3" secondAttribute="leading" id="3T2-ad-Qdv"/>
  <constraint firstItem="tWc-Dq-wcI" firstAttribute="bottom" secondItem="Ze5-6b-2t3" secondAttribute="bottom" id="RPx-PI-7Xg"/>
  <constraint firstItem="tWc-Dq-wcI" firstAttribute="top" secondItem="Ze5-6b-2t3" secondAttribute="top" id="SdS-ul-q2q"/>
  <constraint firstAttribute="trailing" secondItem="tWc-Dq-wcI" secondAttribute="trailing" id="Swv-Gf-Rwn"/>
  <constraint firstAttribute="trailing" secondItem="YRO-k0-Ey4" secondAttribute="trailing" id="TQA-XW-tRk"/>
  <constraint firstItem="YRO-k0-Ey4" firstAttribute="bottom" secondItem="Ze5-6b-2t3" secondAttribute="bottom" id="duK-uY-Gun"/>
  <constraint firstItem="tWc-Dq-wcI" firstAttribute="leading" secondItem="Ze5-6b-2t3" secondAttribute="leading" id="kV7-tw-vXt"/>
  <constraint firstItem="YRO-k0-Ey4" firstAttribute="top" secondItem="Ze5-6b-2t3" secondAttribute="top" id="xPn-NY-SIU"/>
</constraints>
''';

const String _iOSBrandingCenterBottomConstraints = '''
<constraints>
  <constraint firstItem="Uyq-Kz-ftE" firstAttribute="centerX" secondItem="YRO-k0-Ey4" secondAttribute="centerX" id="3kg-TC-cPP"/>
  <constraint firstAttribute="bottom" secondItem="Uyq-Kz-ftE" secondAttribute="bottom"  id="8Yb-q4-8bl"/>
</constraints>
''';

const String _iOSBrandingLeftBottomConstraints = '''
<constraints>
  <constraint firstAttribute="leading" secondItem="Uyq-Kz-ftE" secondAttribute="leading" id="3kg-TC-cPP"/>
  <constraint firstAttribute="bottom" secondItem="Uyq-Kz-ftE" secondAttribute="bottom" id="8Yb-q4-8bl"/>
</constraints>
''';

const String _iOSBrandingRightBottomConstraints = '''
<constraints>
  <constraint firstAttribute="trailing" secondItem="Uyq-Kz-ftE" secondAttribute="trailing" id="3kg-TC-cPP"/>                            
  <constraint firstAttribute="bottom" secondItem="Uyq-Kz-ftE" secondAttribute="bottom" id="8Yb-q4-8lb"/>                            
</constraints>
''';

/// Web related templates
const String _webCss = '''
html {
  height: 100%
}

body {
  margin: 0;
  min-height: 100%;
  background-color: [LIGHTBACKGROUNDCOLOR];
  [LIGHTBACKGROUNDIMAGE]
  background-size: 100% 100%;
}

.center {
  margin: 0;
  position: absolute;
  top: 50%;
  left: 50%;
  -ms-transform: translate(-50%, -50%);
  transform: translate(-50%, -50%);
}

.contain {
  display:block;
  width:100%; height:100%;
  object-fit: contain;
}

.stretch {
  display:block;
  width:100%; height:100%;
}

.cover {
  display:block;
  width:100%; height:100%;
  object-fit: cover;
}

.bottom {
  position: absolute;
  bottom: 0;
  left: 50%;
  -ms-transform: translate(-50%, 0);
  transform: translate(-50%, 0);
}

.bottomLeft {
  position: absolute;
  bottom: 0;
  left: 0;
}

.bottomRight {
  position: absolute;
  bottom: 0;
  right: 0;
}
''';

const String _webCssDark = '''

@media (prefers-color-scheme: dark) {
  body {
    background-color: [DARKBACKGROUNDCOLOR];
    [DARKBACKGROUNDIMAGE]
  }
}
''';

// XML's insertBefore can't have a newline at the end:
const String _indexHtmlPicture = '''
  <picture id="splash">
      <source srcset="splash/img/light-1x.png 1x, splash/img/light-2x.png 2x, splash/img/light-3x.png 3x, splash/img/light-4x.png 4x" media="(prefers-color-scheme: light)">
      <source srcset="splash/img/dark-1x.png 1x, splash/img/dark-2x.png 2x, splash/img/dark-3x.png 3x, splash/img/dark-4x.png 4x" media="(prefers-color-scheme: dark)">
      <img class="[IMAGEMODE]" aria-hidden="true" src="splash/img/light-1x.png" alt=""/>
  </picture>''';

// XML's insertBefore can't have a newline at the end:
const String _indexHtmlBrandingPicture = '''
  <picture id="splash-branding">
    <source srcset="splash/img/branding-1x.png 1x, splash/img/branding-2x.png 2x, splash/img/branding-3x.png 3x, splash/img/branding-4x.png 4x" media="(prefers-color-scheme: light)">
    <source srcset="splash/img/branding-dark-1x.png 1x, splash/img/branding-dark-2x.png 2x, splash/img/branding-dark-3x.png 3x, splash/img/branding-dark-4x.png 4x" media="(prefers-color-scheme: dark)">
    <img class="[BRANDINGMODE]" aria-hidden="true" src="splash/img/branding-1x.png" alt=""/>
  </picture>''';

const String _webJS = '''
function removeSplashFromWeb() {
  document.getElementById("splash")?.remove();
  document.getElementById("splash-branding")?.remove();
  document.body.style.background = "transparent";
}
''';

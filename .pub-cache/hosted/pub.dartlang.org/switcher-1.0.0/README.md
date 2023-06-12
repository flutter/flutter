
<img src="https://github.com/tiagosito/switcher/raw/main/doc/assets/switcher_logo_full.png" width="100%" alt="logo" />
<h2 align="center">
  A animated, beautiful and personalized switcher component.
</h2>

<h5  align="center">

Based on Eduardo Muñoz's widget [lite_rolling_switch](https://github.com/cgustav/lite_rolling_switch)

</h5>

<p>&nbsp;</p>

<p align="center">
<a href="https://pub.dartlang.org/packages/switcher">
  <img alt="Pub Package" src="https://img.shields.io/pub/v/switcher.svg">
</a>
  <a href="https://www.buymeacoffee.com/tiagosito" target="_blank"><img alt="Buy Me A Coffee" src="https://i.imgur.com/aV6DDA7.png" </a>
</p>
  
## Overview

A animated and beautiful Switcher

#### Contributing
  - [https://github.com/tiagosito/switcher](https://github.com/tiagosito/switcher)

#### Getting Started

In _pubspec.yaml_:

```yaml
dependencies:
  switcher: any
```

### See how:
<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_01.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_02.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_03.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_04.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_05.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_06.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher.gif?raw=true" width="50%" alt="Using switcher" />

<img src="https://github.com/tiagosito/switcher/blob/main/doc/assets/switcher_07.gif?raw=true" width="50%" alt="Using switcher" />

```dart
import 'package:switcher/switcher.dart';

Switcher(
    value: false,
    size: SwitcherSize.large,
    switcherButtonRadius: 50,
    enabledSwitcherButtonRotate: true,
    iconOff: Icons.lock,
    iconOn: Icons.lock_open,
    colorOff: Colors.blueGrey.withOpacity(0.3),
    colorOn: Colors.blue,
    onChanged: (bool state) {
    //
    },
),

 Switcher(
    value: false,
    size: SwitcherSize.large,
    switcherButtonRadius: 50,
    iconOff: null,
    enabledSwitcherButtonRotate: false,
    colorOff: Colors.blueGrey.withOpacity(0.3),
    colorOn: Colors.blue,
    onChanged: (bool state) {
    //
    },
),
```

## Features and bugs

Please send feature requests and bugs at the [issue tracker](https://github.com/tiagosito/switcher/issues).

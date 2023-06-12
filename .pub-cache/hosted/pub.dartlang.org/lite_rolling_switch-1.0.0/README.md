# lite_rolling_switch

Full customable rolling switch widget for flutter apps based on Pedro Massango's 'crazy-switch' widget https://github.com/pedromassango/crazy-switch

## About

Custom Switch button with attractive animation,
made to allow you to customize colors, icons and other cosmetic content. Manage the widget states in the same way you do with the classical material's switch widget.

> **NOTE**: Currently, you cannot directly change the widget height properties. This feature will be available soon.

## Previews

![Image preview](https://media.giphy.com/media/hTx1jlMxasyVejHa6U/giphy.gif)

![Image preview 2](https://media.giphy.com/media/TKSIVzM5RUDxnjucTf/giphy.gif)

## Basic Implementation

```dart
import 'package:lite_rolling_switch/lite_rolling_switch.dart';

LiteRollingSwitch(
    //initial value
    value: true,
    textOn: 'disponible',
    textOff: 'ocupado',
    colorOn: Colors.greenAccent[700],
    colorOff: Colors.redAccent[700],
    iconOn: Icons.done,
    iconOff: Icons.remove_circle_outline,
    textSize: 16.0,
    onChanged: (bool state) {
      //Use it to manage the different states
      print('Current State of SWITCH IS: $state');
    },
),

```

## Changelog

Visit the complete changelog [here](CHANGELOG.md).

## Contributors

- [@rodrigobastosv](https://github.com/rodrigobastosv) - Component state fixes
- [@eyupakky](https://github.com/eyupakky) - Enhanced text color customization
- [@adarshnagrikar14](https://github.com/adarshnagrikar14) - Null safety migration
- [@hasan-hm1](https://github.com/hasan-hm1) - RTL Support
- [@Automatik](https://github.com/Automatik) - Customable component width

### Other collaborators

- [@Rontu22](https://github.com/Rontu22) - Null safety hints
- [@Elvis-Sarfo](https://github.com/Elvis-Sarfo) - Null safety hints
- [@lulupointu](https://github.com/lulupointu) - Component management hints

## License

This project has been published under an MIT license, you can consult the license terms in detail [here](LICENSE).

## Other

- [Official pub.dev package](https://pub.dev/packages/lite_rolling_switch#-installing-tab-)

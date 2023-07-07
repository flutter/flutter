import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';

/// Convert a String to a ConnectivityResult value.
ConnectivityResult parseConnectivityResult(String state) {
  switch (state) {
    case 'wifi':
      return ConnectivityResult.wifi;
    case 'mobile':
      return ConnectivityResult.mobile;
    case 'none':
    default:
      return ConnectivityResult.none;
  }
}

/// Convert a String to a LocationAuthorizationStatus value.
LocationAuthorizationStatus parseLocationAuthorizationStatus(String result) {
  switch (result) {
    case 'notDetermined':
      return LocationAuthorizationStatus.notDetermined;
    case 'restricted':
      return LocationAuthorizationStatus.restricted;
    case 'denied':
      return LocationAuthorizationStatus.denied;
    case 'authorizedAlways':
      return LocationAuthorizationStatus.authorizedAlways;
    case 'authorizedWhenInUse':
      return LocationAuthorizationStatus.authorizedWhenInUse;
    default:
      return LocationAuthorizationStatus.unknown;
  }
}

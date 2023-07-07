/// Connection status check result.
enum ConnectivityResult {
  /// WiFi: Device connected via Wi-Fi
  wifi,

  /// Mobile: Device connected to cellular network
  mobile,

  /// None: Device not connected to any network
  none
}

/// The status of the location service authorization.
enum LocationAuthorizationStatus {
  /// The authorization of the location service is not determined.
  notDetermined,

  /// This app is not authorized to use location.
  restricted,

  /// User explicitly denied the location service.
  denied,

  /// User authorized the app to access the location at any time.
  authorizedAlways,

  /// User authorized the app to access the location when the app is visible to them.
  authorizedWhenInUse,

  /// Status unknown.
  unknown
}

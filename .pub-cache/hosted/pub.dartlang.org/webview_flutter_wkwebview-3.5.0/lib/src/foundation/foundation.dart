// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../common/instance_manager.dart';
import '../common/weak_reference_utils.dart';
import 'foundation_api_impls.dart';

/// The values that can be returned in a change map.
///
/// Wraps [NSKeyValueObservingOptions](https://developer.apple.com/documentation/foundation/nskeyvalueobservingoptions?language=objc).
enum NSKeyValueObservingOptions {
  /// Indicates that the change map should provide the new attribute value, if applicable.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvalueobservingoptions/nskeyvalueobservingoptionnew?language=objc.
  newValue,

  /// Indicates that the change map should contain the old attribute value, if applicable.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvalueobservingoptions/nskeyvalueobservingoptionold?language=objc.
  oldValue,

  /// Indicates a notification should be sent to the observer immediately.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvalueobservingoptions/nskeyvalueobservingoptioninitial?language=objc.
  initialValue,

  /// Whether separate notifications should be sent to the observer before and after each change.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvalueobservingoptions/nskeyvalueobservingoptionprior?language=objc.
  priorNotification,
}

/// The kinds of changes that can be observed.
///
/// Wraps [NSKeyValueChange](https://developer.apple.com/documentation/foundation/nskeyvaluechange?language=objc).
enum NSKeyValueChange {
  /// Indicates that the value of the observed key path was set to a new value.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechange/nskeyvaluechangesetting?language=objc.
  setting,

  /// Indicates that an object has been inserted into the to-many relationship that is being observed.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechange/nskeyvaluechangeinsertion?language=objc.
  insertion,

  /// Indicates that an object has been removed from the to-many relationship that is being observed.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechange/nskeyvaluechangeremoval?language=objc.
  removal,

  /// Indicates that an object has been replaced in the to-many relationship that is being observed.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechange/nskeyvaluechangereplacement?language=objc.
  replacement,
}

/// The keys that can appear in the change map.
///
/// Wraps [NSKeyValueChangeKey](https://developer.apple.com/documentation/foundation/nskeyvaluechangekey?language=objc).
enum NSKeyValueChangeKey {
  /// Indicates changes made in a collection.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechangeindexeskey?language=objc.
  indexes,

  /// Indicates what sort of change has occurred.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechangekindkey?language=objc.
  kind,

  /// Indicates the new value for the attribute.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechangenewkey?language=objc.
  newValue,

  /// Indicates a notification is sent prior to a change.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechangenotificationispriorkey?language=objc.
  notificationIsPrior,

  /// Indicates the value of this key is the value before the attribute was changed.
  ///
  /// See https://developer.apple.com/documentation/foundation/nskeyvaluechangeoldkey?language=objc.
  oldValue,

  /// An unknown change key.
  ///
  /// This does not represent an actual value provided by the platform and only
  /// indicates a value was provided that isn't currently supported.
  unknown,
}

/// The supported keys in a cookie attributes dictionary.
///
/// Wraps [NSHTTPCookiePropertyKey](https://developer.apple.com/documentation/foundation/nshttpcookiepropertykey).
enum NSHttpCookiePropertyKey {
  /// A String object containing the comment for the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiecomment.
  comment,

  /// A String object containing the comment URL for the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiecommenturl.
  commentUrl,

  /// A String object stating whether the cookie should be discarded at the end of the session.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiediscard.
  discard,

  /// A String object specifying the expiration date for the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiedomain.
  domain,

  /// A String object specifying the expiration date for the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookieexpires.
  expires,

  /// A String object containing an integer value stating how long in seconds the cookie should be kept, at most.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiemaximumage.
  maximumAge,

  /// A String object containing the name of the cookie (required).
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiename.
  name,

  /// A String object containing the URL that set this cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookieoriginurl.
  originUrl,

  /// A String object containing the path for the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiepath.
  path,

  /// A String object containing comma-separated integer values specifying the ports for the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookieport.
  port,

  /// A String indicating the same-site policy for the cookie.
  ///
  /// This is only supported on iOS version 13+. This value will be ignored on
  /// versions < 13.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiesamesitepolicy.
  sameSitePolicy,

  /// A String object indicating that the cookie should be transmitted only over secure channels.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookiesecure.
  secure,

  /// A String object containing the value of the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookievalue.
  value,

  /// A String object that specifies the version of the cookie.
  ///
  /// See https://developer.apple.com/documentation/foundation/nshttpcookieversion.
  version,
}

/// A URL load request that is independent of protocol or URL scheme.
///
/// Wraps [NSUrlRequest](https://developer.apple.com/documentation/foundation/nsurlrequest?language=objc).
@immutable
class NSUrlRequest {
  /// Constructs an [NSUrlRequest].
  const NSUrlRequest({
    required this.url,
    this.httpMethod,
    this.httpBody,
    this.allHttpHeaderFields = const <String, String>{},
  });

  /// The URL being requested.
  final String url;

  /// The HTTP request method.
  ///
  /// The default HTTP method is “GET”.
  final String? httpMethod;

  /// Data sent as the message body of a request, as in an HTTP POST request.
  final Uint8List? httpBody;

  /// All of the HTTP header fields for a request.
  final Map<String, String> allHttpHeaderFields;
}

/// Information about an error condition.
///
/// Wraps [NSError](https://developer.apple.com/documentation/foundation/nserror?language=objc).
@immutable
class NSError {
  /// Constructs an [NSError].
  const NSError({
    required this.code,
    required this.domain,
    required this.localizedDescription,
  });

  /// The error code.
  ///
  /// Note that errors are domain-specific.
  final int code;

  /// A string containing the error domain.
  final String domain;

  /// A string containing the localized description of the error.
  final String localizedDescription;
}

/// A representation of an HTTP cookie.
///
/// Wraps [NSHTTPCookie](https://developer.apple.com/documentation/foundation/nshttpcookie).
@immutable
class NSHttpCookie {
  /// Initializes an HTTP cookie object using the provided properties.
  const NSHttpCookie.withProperties(this.properties);

  /// Properties of the new cookie object.
  final Map<NSHttpCookiePropertyKey, Object> properties;
}

/// An object that represents the location of a resource, such as an item on a
/// remote server or the path to a local file.
///
/// See https://developer.apple.com/documentation/foundation/nsurl?language=objc.
class NSUrl extends NSObject {
  /// Instantiates a [NSUrl] without creating and attaching to an instance
  /// of the associated native class.
  ///
  /// This should only be used outside of tests by subclasses created by this
  /// library or to create a copy for an [InstanceManager].
  @protected
  NSUrl.detached({super.binaryMessenger, super.instanceManager})
      : _nsUrlHostApi = NSUrlHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ),
        super.detached();

  final NSUrlHostApiImpl _nsUrlHostApi;

  /// The URL string for the receiver as an absolute URL. (read-only)
  ///
  /// Represents [NSURL.absoluteString](https://developer.apple.com/documentation/foundation/nsurl/1409868-absolutestring?language=objc).
  Future<String?> getAbsoluteString() {
    return _nsUrlHostApi.getAbsoluteStringFromInstances(this);
  }

  @override
  NSObject copy() {
    return NSUrl.detached(
      binaryMessenger: _nsUrlHostApi.binaryMessenger,
      instanceManager: _nsUrlHostApi.instanceManager,
    );
  }
}

/// The root class of most Objective-C class hierarchies.
@immutable
class NSObject with Copyable {
  /// Constructs a [NSObject] without creating the associated
  /// Objective-C object.
  ///
  /// This should only be used by subclasses created by this library or to
  /// create copies.
  NSObject.detached({
    this.observeValue,
    BinaryMessenger? binaryMessenger,
    InstanceManager? instanceManager,
  }) : _api = NSObjectHostApiImpl(
          binaryMessenger: binaryMessenger,
          instanceManager: instanceManager,
        ) {
    // Ensures FlutterApis for the Foundation library are set up.
    FoundationFlutterApis.instance.ensureSetUp();
  }

  /// Release the reference to the Objective-C object.
  static void dispose(NSObject instance) {
    instance._api.instanceManager.removeWeakReference(instance);
  }

  /// Global instance of [InstanceManager].
  static final InstanceManager globalInstanceManager =
      InstanceManager(onWeakReferenceRemoved: (int instanceId) {
    NSObjectHostApiImpl().dispose(instanceId);
  });

  final NSObjectHostApiImpl _api;

  /// Informs the observing object when the value at the specified key path has
  /// changed.
  ///
  /// {@template webview_flutter_wkwebview.foundation.callbacks}
  /// For the associated Objective-C object to be automatically garbage
  /// collected, it is required that this Function doesn't contain a strong
  /// reference to the encapsulating class instance. Consider using
  /// `WeakReference` when referencing an object not received as a parameter.
  /// Otherwise, use [NSObject.dispose] to release the associated Objective-C
  /// object manually.
  ///
  /// See [withWeakReferenceTo].
  /// {@endtemplate}
  final void Function(
    String keyPath,
    NSObject object,
    Map<NSKeyValueChangeKey, Object?> change,
  )? observeValue;

  /// Registers the observer object to receive KVO notifications.
  Future<void> addObserver(
    NSObject observer, {
    required String keyPath,
    required Set<NSKeyValueObservingOptions> options,
  }) {
    assert(options.isNotEmpty);
    return _api.addObserverForInstances(
      this,
      observer,
      keyPath,
      options,
    );
  }

  /// Stops the observer object from receiving change notifications for the property.
  Future<void> removeObserver(NSObject observer, {required String keyPath}) {
    return _api.removeObserverForInstances(this, observer, keyPath);
  }

  @override
  NSObject copy() {
    return NSObject.detached(
      observeValue: observeValue,
      binaryMessenger: _api.binaryMessenger,
      instanceManager: _api.instanceManager,
    );
  }
}

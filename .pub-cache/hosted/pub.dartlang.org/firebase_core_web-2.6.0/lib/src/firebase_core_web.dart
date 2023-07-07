// ignore_for_file: unsafe_html
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_web;

/// Defines a Firebase service by name.
class FirebaseWebService {
  /// The name which matches the Firebase JS Web SDK postfix.
  String name;

  /// Naming of Firebase web products is different from Flutterfire plugins. This
  /// property allows overriding of web naming to Flutterfire plugin naming.
  String? override;

  /// Function to call to ensure the Firebase Service is initialized.
  /// Usually used to ensure that the Web SDK match the behavior
  /// of native SDKs.
  EnsurePluginInitialized ensurePluginInitialized;

  /// Creates a new [FirebaseWebService].
  FirebaseWebService._(
    this.name, {
    this.override,
    this.ensurePluginInitialized,
  });
}

typedef EnsurePluginInitialized = Future<void> Function(
  firebase.App firebaseApp,
)?;

/// The entry point for accessing Firebase.
///
/// You can get an instance by calling [FirebaseCore.instance].
class FirebaseCoreWeb extends FirebasePlatform {
  static Map<String, FirebaseWebService> _services = {
    'core': FirebaseWebService._('app', override: 'core'),
  };

  /// Internally registers a Firebase Service to be initialized.
  static void registerService(
    String service, {
    String? productNameOverride,
    EnsurePluginInitialized? ensurePluginInitialized,
  }) {
    _services.putIfAbsent(
      service,
      () => FirebaseWebService._(
        service,
        override: productNameOverride,
        ensurePluginInitialized: ensurePluginInitialized,
      ),
    );
  }

  /// Registers that [FirebaseCoreWeb] is the platform implementation.
  static void registerWith(Registrar registrar) {
    FirebasePlatform.instance = FirebaseCoreWeb();
  }

  /// Returns the Firebase JS SDK Version to use.
  ///
  /// You can override the supported version by attaching a version string to
  /// the window (window.flutterfire_web_sdk_version = 'x.x.x'). Do so at your
  /// own risk as the version might be unsupported or untested against.
  @visibleForTesting
  String get firebaseSDKVersion {
    return context['flutterfire_web_sdk_version'] ??
        supportedFirebaseJsSdkVersion;
  }

  /// Returns a list of services which won't be automatically injected on
  /// initialization. This is useful incases where you wish to manually include
  /// the scripts (e.g. in countries where you must request the users permission
  /// to include Analytics).
  ///
  /// You can do this by attaching an array of services to the window, e.g:
  ///
  /// window.flutterfire_ignore_scripts = ['analytics'];
  ///
  /// You must ensure the Firebase script is injected before using the service.
  List<String> get _ignoredServiceScripts {
    try {
      JsObject ignored =
          JsObject.fromBrowserObject(context['flutterfire_ignore_scripts']);

      if (ignored is Iterable) {
        return (ignored as Iterable)
            .map((e) => e.toString())
            .toList(growable: false);
      }
    } catch (e) {
      // Noop
    }

    return [];
  }

  final String _defaultTrustedPolicyName = 'flutterfire-';

  /// Injects a `script` with a `src` dynamically into the head of the current
  /// document.
  @visibleForTesting
  Future<void> injectSrcScript(String src, String windowVar) async {
    DomTrustedScriptUrl? trustedUrl;
    final trustedPolicyName = _defaultTrustedPolicyName + windowVar;
    if (trustedTypes != null) {
      console.debug(
        'TrustedTypes available. Creating policy:',
        trustedPolicyName,
      );
      final DomTrustedTypePolicyFactory factory = trustedTypes!;
      try {
        final DomTrustedTypePolicy policy = factory.createPolicy(
          trustedPolicyName,
          DomTrustedTypePolicyOptions(
            createScriptURL: allowInterop((String url) => src),
          ),
        );
        trustedUrl = policy.createScriptURL(src);
      } catch (e) {
        rethrow;
      }
    }
    ScriptElement script = ScriptElement();
    script.type = 'text/javascript';
    script.crossOrigin = 'anonymous';
    script.text = '''
      window.ff_trigger_$windowVar = async (callback) => {
        console.debug("Initializing Firebase $windowVar");
        callback(await import("${trustedUrl != null ? callMethod(trustedUrl, 'toString', []) : src}"));
      };
    ''';

    assert(document.head != null);
    document.head!.append(script);

    Completer completer = Completer();

    context.callMethod('ff_trigger_$windowVar', [
      (module) {
        context[windowVar] = module;
        context.deleteProperty('ff_trigger_$windowVar');
        completer.complete();
      }
    ]);

    await completer.future;
  }

  /// Initializes the Firebase JS SDKs by injecting them into the `head` of the
  /// document when Firebase is initialized.
  Future<void> _initializeCore() async {
    // If Firebase is already available, core has already been initialized
    // (or the user has added the scripts to their html file).
    if (context['firebase_core'] != null) {
      return;
    }

    String version = firebaseSDKVersion;
    List<String> ignored = _ignoredServiceScripts;

    await Future.wait(
      _services.values.map((service) {
        if (ignored.contains(service.override ?? service.name)) {
          return Future.value();
        }

        return injectSrcScript(
          'https://www.gstatic.com/firebasejs/$version/firebase-${service.name}.js',
          'firebase_${service.override ?? service.name}',
        );
      }),
    );
  }

  /// Returns all created [FirebaseAppPlatform] instances.
  @override
  List<FirebaseAppPlatform> get apps {
    return guardNotInitialized(
      () => firebase.apps.map(_createFromJsApp).toList(growable: false),
    );
  }

  /// Initializes a new [FirebaseAppPlatform] instance by [name] and [options] and returns
  /// the created app. This method should be called before any usage of FlutterFire plugins.
  ///
  /// The default app instance cannot be initialized here and should be created
  /// using the platform Firebase integration.
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    await _initializeCore();
    guardNotInitialized(() => firebase.SDK_VERSION);

    assert(
      () {
        if (firebase.SDK_VERSION != supportedFirebaseJsSdkVersion) {
          // ignore: avoid_print
          print(
            '''
            WARNING: FlutterFire for Web is explicitly tested against Firebase JS SDK version "$supportedFirebaseJsSdkVersion"
            but your currently specifying "${firebase.SDK_VERSION}" by either the imported Firebase JS SDKs in your web/index.html
            file or by providing an override - this may lead to unexpected issues in your application. It is recommended that you change all of the versions of the
            Firebase JS SDK version "$supportedFirebaseJsSdkVersion":

            If you override the version manually:
              change:
                <script>window.flutterfire_web_sdk_version = '${firebase.SDK_VERSION}';</script>
              to:
                <script>window.flutterfire_web_sdk_version = '$supportedFirebaseJsSdkVersion';</script>

            If you import the Firebase scripts in index.html, instead allow FlutterFire to manage this for you by removing
            any Firebase scripts in your web/index.html file:
                e.g. remove: <script src="https://www.gstatic.com/firebasejs/${firebase.SDK_VERSION}/firebase-app.js"></script>
          ''',
          );
        }

        return true;
      }(),
    );

    firebase.App? app;

    if (name == null || name == defaultFirebaseAppName) {
      bool defaultAppExists = false;

      try {
        app = firebase.app();
        defaultAppExists = true;
      } catch (e) {
        // noop
      }

      if (defaultAppExists) {
        if (options != null) {
          // If there is a default app already and the user provided options do a soft
          // check to see if options are roughly identical (so we don't unnecessarily
          // throw on minor differences such as platform specific keys missing,
          // e.g. hot reloads/restarts).
          if (options.apiKey != app!.options.apiKey ||
              options.databaseURL != app.options.databaseURL ||
              options.storageBucket != app.options.storageBucket) {
            // Options are different; throw.
            throw duplicateApp(defaultFirebaseAppName);
          }
        }
      } else {
        assert(
          options != null,
          'FirebaseOptions cannot be null when creating the default app.',
        );

        // At this point, there is no default app so we need to create it with
        // the users options.
        app = firebase.initializeApp(
          apiKey: options!.apiKey,
          authDomain: options.authDomain,
          databaseURL: options.databaseURL,
          projectId: options.projectId,
          storageBucket: options.storageBucket,
          messagingSenderId: options.messagingSenderId,
          appId: options.appId,
          measurementId: options.measurementId,
        );
      }
    }

    // Ensure the user has provided options for secondary apps.
    if (name != null && name != defaultFirebaseAppName) {
      assert(
        options != null,
        'FirebaseOptions cannot be null when creating a secondary Firebase app.',
      );

      try {
        app = firebase.initializeApp(
          name: name,
          apiKey: options!.apiKey,
          authDomain: options.authDomain,
          databaseURL: options.databaseURL,
          projectId: options.projectId,
          storageBucket: options.storageBucket,
          messagingSenderId: options.messagingSenderId,
          appId: options.appId,
          measurementId: options.measurementId,
        );
      } catch (e) {
        if (_getJSErrorCode(e) == 'app/duplicate-app') {
          throw duplicateApp(name);
        }

        throw _catchJSError(e);
      }
    }

    await Future.wait(
      _services.values.map((service) {
        final ensureInitializedFunction = service.ensurePluginInitialized;

        if (ensureInitializedFunction == null || app == null) {
          return Future.value();
        }

        return ensureInitializedFunction(app);
      }),
    );

    return _createFromJsApp(app!);
  }

  /// Returns a [FirebaseAppPlatform] instance.
  ///
  /// If no name is provided, the default app instance is returned.
  /// Throws if the app does not exist.
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    firebase.App app;

    try {
      app = guardNotInitialized(() => firebase.app(name));
    } catch (e) {
      if (_getJSErrorCode(e) == 'app/no-app') {
        throw noAppExists(name);
      }

      throw _catchJSError(e);
    }

    return _createFromJsApp(app);
  }
}

/// Converts a Exception to a FirebaseAdminException.
Never _handleException(Object exception, StackTrace stackTrace) {
  if (exception.toString().contains('of undefined')) {
    throw coreNotInitialized();
  }

  Error.throwWithStackTrace(exception, stackTrace);
}

/// A generic guard wrapper for API calls to handle exceptions.
R guardNotInitialized<R>(R Function() cb) {
  try {
    final value = cb();

    if (value is Future) {
      return value.catchError(
        _handleException,
      ) as R;
    }

    return value;
  } catch (error, stackTrace) {
    _handleException(error, stackTrace);
  }
}

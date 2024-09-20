// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file defines the module loader for the dart runtime.
if (!self.dart_library) {
  self.dart_library = typeof module != 'undefined' && module.exports || {};

  (function (dart_library) {
    'use strict';

    // Throws an error related to module loading.
    //
    // This does not throw a Dart error because the Dart SDK may not have loaded
    // yet, and module loading errors cannot be caught by Dart code.
    function throwLibraryError(message) {
      // Dispatch event to allow others to react to the load error without
      // capturing the exception.
      if (!!self.dispatchEvent) {
        self.dispatchEvent(
          new CustomEvent('dartLoadException', { detail: message }));
      }
      throw Error(message);
    }

    /**
     * Returns true if we're running in d8.
     *
     * TOOD(markzipan): Determine if this d8 check is too inexact.
     */
    self.dart_library.isD8 = self.document.head == void 0;

    const libraryImports = Symbol('libraryImports');
    self.dart_library.libraryImports = libraryImports;

    const _metrics = Symbol('metrics');

    // Returns a map from module name to various metrics for module.
    function moduleMetrics() {
      const map = {};
      const keys = Array.from(_libraries.keys());
      for (const key of keys) {
        const lib = _libraries.get(key);
        map[lib._name] = lib.firstLibraryValue[_metrics];
      }
      return map;
    }
    self.dart_library.moduleMetrics = moduleMetrics;

    // Returns an application level overview of the module metrics.
    function appMetrics() {
      const metrics = moduleMetrics();
      let dartSize = 0;
      let jsSize = 0;
      let sourceMapSize = 0;
      let evaluatedModules = 0;
      const keys = Array.from(_libraries.keys());

      let firstLoadStart = Number.MAX_VALUE;
      let lastLoadEnd = Number.MIN_VALUE;

      for (const module of keys) {
        let data = metrics[module];
        if (data != null) {
          evaluatedModules++;
          dartSize += data.dartSize;
          jsSize += data.jsSize;
          sourceMapSize += data.sourceMapSize;
          firstLoadStart = Math.min(firstLoadStart, data.loadStart);
          lastLoadEnd = Math.max(lastLoadEnd, data.loadEnd);
        }
      }
      return {
        'dartSize': dartSize,
        'jsSize': jsSize,
        'sourceMapSize': sourceMapSize,
        'evaluatedModules': evaluatedModules,
        'loadTimeMs': lastLoadEnd - firstLoadStart
      };
    }
    self.dart_library.appMetrics = appMetrics;

    function _sortFn(key1, key2) {
      const t1 = _libraries.get(key1).firstLibraryValue[_metrics].loadStart;
      const t2 = _libraries.get(key2).firstLibraryValue[_metrics].loadStart;
      return t1 - t2;
    }

    // Convenience method to print the metrics in the browser console
    // in CSV format.
    function metricsCsv() {
      let buffer =
        'Module, JS Size, Dart Size, Load Start, Load End, Cumulative JS Size\n';
      const keys = Array.from(_libraries.keys());
      keys.sort(_sortFn);
      let cumulativeJsSize = 0;
      for (const key of keys) {
        const lib = _libraries.get(key);
        const jsSize = lib.firstLibraryValue[_metrics].jsSize;
        cumulativeJsSize += jsSize;
        const dartSize = lib.firstLibraryValue[_metrics].dartSize;
        const loadStart = lib.firstLibraryValue[_metrics].loadStart;
        const loadEnd = lib.firstLibraryValue[_metrics].loadEnd;
        buffer += '"' + lib._name + '", ' + jsSize + ', ' + dartSize + ', ' +
          loadStart + ', ' + loadEnd + ', ' + cumulativeJsSize + '\n';
      }
      return buffer;
    }
    self.dart_library.metricsCsv = metricsCsv;

    // Module support.  This is a simplified module system for Dart.
    // Longer term, we can easily migrate to an existing JS module system:
    // ES6, AMD, RequireJS, ....

    // Returns a proxy that delegates to the underlying loader.
    // This defers loading of a module until a library is actually used.
    const loadedModule = Symbol('loadedModule');
    self.dart_library.defer = function (module, name, patch) {
      let done = false;
      function loadDeferred() {
        done = true;
        let mod = module[loadedModule];
        let lib = mod[name];
        // Install unproxied module and library in caller's context.
        patch(mod, lib);
      }
      // The deferred library object.  Note, the only legal operations on a Dart
      // library object should be get (to read a top-level variable, method, or
      // Class) or set (to write a top-level variable).
      return new Proxy({}, {
        get: function (o, p) {
          if (!done) loadDeferred();
          return module[name][p];
        },
        set: function (o, p, value) {
          if (!done) loadDeferred();
          module[name][p] = value;
          return true;
        },
      });
    };

    let _reverseImports = new Map();

    // App name to set of libraries that were not only loaded on the page but
    // also executed.
    const _executedLibraries = new Map();
    self.dart_library.executedLibraryCount = function () {
      let count = 0;
      _executedLibraries.forEach(function (executedLibraries, _) {
        count += executedLibraries.size;
      });
      return count;
    };

    // Library instance that is going to be loaded or has been loaded.
    class LibraryInstance {
      constructor(libraryValue) {
        this.libraryValue = libraryValue;
        // Cyclic import detection
        this.loadingState = LibraryLoader.NOT_LOADED;
      }

      get isNotLoaded() {
        return this.loadingState == LibraryLoader.NOT_LOADED;
      }
    }

    class LibraryLoader {
      constructor(name, defaultLibraryValue, imports, loader, data) {
        imports.forEach(function (i) {
          let deps = _reverseImports.get(i);
          if (!deps) {
            deps = new Set();
            _reverseImports.set(i, deps);
          }
          deps.add(name);
        });
        this._name = name;
        this._defaultLibraryValue =
          defaultLibraryValue ? defaultLibraryValue : {};
        this._imports = imports;
        this._loader = loader;
        data.jsSize = loader.toString().length;
        data.loadStart = NaN;
        data.loadEnd = NaN;
        this._metrics = data;

        // First loaded instance for supporting logic that assumes there is only
        // one app.
        // TODO(b/204209941): Remove _firstLibraryInstance after debugger and
        // metrics support multiple apps.
        this._firstLibraryInstance =
          new LibraryInstance(this._deepCopyDefaultValue());
        this._firstLibraryInstanceUsed = false;

        // App name to instance map.
        this._instanceMap = new Map();
      }

      /// First loaded value for supporting logic that assumes there is only
      /// one app.
      get firstLibraryValue() {
        return this._firstLibraryInstance.libraryValue;
      }

      /// The loaded instance value for the given `appName`.
      libraryValueInApp(appName) {
        return this._instanceMap.get(appName).libraryValue;
      }

      load(appName) {
        let instance = this._instanceMap.get(appName);
        if (!instance && !this._firstLibraryInstanceUsed) {
          // If `_firstLibraryInstance` is already assigned to an app, creates a
          // new instance clone (with deep copy) and assigns it the given app.
          // Otherwise, reuse `_firstLibraryInstance`.
          instance = this._firstLibraryInstance;
          this._firstLibraryInstanceUsed = true;
          this._instanceMap.set(appName, instance);
        }
        if (!instance) {
          instance = new LibraryInstance(this._deepCopyDefaultValue());
          this._instanceMap.set(appName, instance);
        }

        // Check for cycles
        if (instance.loadingState == LibraryLoader.LOADING) {
          throwLibraryError('Circular dependence on library: ' + this._name);
        } else if (instance.loadingState >= LibraryLoader.READY) {
          return instance.libraryValue;
        }
        if (!_executedLibraries.has(appName)) {
          _executedLibraries.set(appName, new Set());
        }
        _executedLibraries.get(appName).add(this._name);
        instance.loadingState = LibraryLoader.LOADING;

        // Handle imports
        let args = this._loadImports(appName);

        // Load the library
        let loader = this;
        let library = instance.libraryValue;

        library[libraryImports] = this._imports;
        library[loadedModule] = library;
        library[_metrics] = this._metrics;
        args.unshift(library);

        if (this._name == 'dart_sdk') {
          // Eagerly load the SDK.
          if (!!self.performance && !!self.performance.now) {
            library[_metrics].loadStart = self.performance.now();
          }
          this._loader.apply(null, args);
          if (!!self.performance && !!self.performance.now) {
            library[_metrics].loadEnd = self.performance.now();
          }
        } else {
          // Load / parse other modules on demand.
          let done = false;
          instance.libraryValue = new Proxy(library, {
            get: function (o, name) {
              if (name == _metrics) {
                return o[name];
              }
              if (!done) {
                done = true;
                if (!!self.performance && !!self.performance.now) {
                  library[_metrics].loadStart = self.performance.now();
                }
                loader._loader.apply(null, args);
                if (!!self.performance && !!self.performance.now) {
                  library[_metrics].loadEnd = self.performance.now();
                }
              }
              return o[name];
            }
          });
        }

        instance.loadingState = LibraryLoader.READY;
        return instance.libraryValue;
      }

      _loadImports(appName) {
        let results = [];
        for (let name of this._imports) {
          results.push(import_(name, appName));
        }
        return results;
      }

      _deepCopyDefaultValue() {
        return JSON.parse(JSON.stringify(this._defaultLibraryValue));
      }
    }
    LibraryLoader.NOT_LOADED = 0;
    LibraryLoader.LOADING = 1;
    LibraryLoader.READY = 2;

    // Map from name to LibraryLoader
    let _libraries = new Map();
    self.dart_library.libraries = function () {
      return _libraries.keys();
    };
    self.dart_library.debuggerLibraries = function () {
      let debuggerLibraries = [];
      _libraries.forEach(function (value, key, map) {
        debuggerLibraries.push(value.load(_firstStartedAppName));
      });
      Object.setPrototypeOf(debuggerLibraries, null);
      return debuggerLibraries;
    };

    // Invalidate a library and all things that depend on it
    function _invalidateLibrary(name) {
      let lib = _libraries.get(name);
      if (lib._instanceMap.size === 0) return;
      lib._firstLibraryInstance =
        new LibraryInstance(lib._deepCopyDefaultValue());
      lib._firstLibraryInstanceUsed = false;
      lib._instanceMap.clear();
      let deps = _reverseImports.get(name);
      if (!deps) return;
      deps.forEach(_invalidateLibrary);
    }

    function library(name, defaultLibraryValue, imports, loader, data = {}) {
      let result = _libraries.get(name);
      if (result) {
        console.log('Re-loading ' + name);
        _invalidateLibrary(name);
      }
      result =
        new LibraryLoader(name, defaultLibraryValue, imports, loader, data);
      _libraries.set(name, result);
      return result;
    }
    self.dart_library.library = library;

    // Store executed modules upon reload.
    if (!!self.addEventListener && !!self.localStorage) {
      self.addEventListener('beforeunload', function (event) {
        _nameToApp.forEach(function (_, appName) {
          if (!_executedLibraries.get(appName)) {
            return;
          }
          let libraryCache = {
            'time': new Date().getTime(),
            'modules': Array.from(_executedLibraries.get(appName).keys()),
          };
          self.localStorage.setItem(
            `dartLibraryCache:${appName}`, JSON.stringify(libraryCache));
        });
      });
    }

    // Map from module name to corresponding app to proxy library map.
    let _proxyLibs = new Map();

    function import_(name, appName) {
      // For backward compatibility.
      if (!appName && _lastStartedSubapp) {
        appName = _lastStartedSubapp.appName;
      }

      let proxy;
      if (_proxyLibs.has(name)) {
        proxy = _proxyLibs.get(name).get(appName);
      }
      if (proxy) return proxy;
      let proxyLib = new Proxy({}, {
        get: function (o, p) {
          let lib = _libraries.get(name);
          if (self.$dartJITModules) {
            // The backing module changed so update the reference
            if (!lib) {
              let xhr = new XMLHttpRequest();
              let sourceURL = self.$dartLoader.moduleIdToUrl.get(name);
              xhr.open('GET', sourceURL, false);
              xhr.withCredentials = true;
              xhr.send();
              // Add inline policy to make eval() call Trusted Types compatible
              // when running in a TT compatible browser
              let policy = {
                createScript: function (script) {
                  return script;
                }
              };
              if (self.trustedTypes && self.trustedTypes.createPolicy) {
                policy = self.trustedTypes.createPolicy(
                  'dartDdcModuleLoading#dart_library', policy);
              }
              // Append sourceUrl so the resource shows up in the Chrome
              // console.
              eval(policy.createScript(
                xhr.responseText + '//@ sourceURL=' + sourceURL));
              lib = _libraries.get(name);
            }
          }
          if (!lib) {
            throwLibraryError('Module ' + name + ' not loaded in the browser.');
          }
          // Always load the library before accessing a property as it may have
          // been invalidated.
          return lib.load(appName)[p];
        }
      });
      if (!_proxyLibs.has(name)) {
        _proxyLibs.set(name, new Map());
      }
      _proxyLibs.get(name).set(appName, proxyLib);
      return proxyLib;
    }
    self.dart_library.import = import_;

    // Removes the corresponding library and invalidates all things that
    // depend on it.
    function _invalidateImport(name) {
      let lib = _libraries.get(name);
      if (!lib) return;
      _invalidateLibrary(name);
      _libraries.delete(name);
    }
    self.dart_library.invalidateImport = _invalidateImport;

    let _debuggerInitialized = false;

    // Caches the last N runIds to prevent hot reload requests from the same
    // runId from executing more than once.
    const _hotRestartRunIdCache = new Array();

    // Called to initiate a hot restart of the application for a given uuid. If
    // it is not set, the last started application will be hot restarted.
    //
    // "Hot restart" means all application state is cleared, the newly compiled
    // modules are loaded, and `main()` is called.
    //
    // Note: `onReloadEnd()` can be provided, and if so will be used instead of
    // `main()` for hot restart.
    //
    // This happens in the following sequence:
    //
    // 1. Look for `onReloadStart()` in the same library that has `main()`, and
    //    call it if present. This function is implemented by the application to
    //    ensure any global browser/DOM state is cleared, so the application can
    //    restart.
    // 2. Wait for `onReloadStart()` to complete (either synchronously, or async
    //    if it returned a `Future`).
    // 3. Call dart:_runtime's `hotRestart()` function to clear any state that
    //    `dartdevc` is tracking, such as initialized static fields and type
    //    caches.
    // 4. Call `self.$dartReloadModifiedModules()` (provided by the HTML page)
    //    to reload the relevant JS modules, passing a callback that will invoke
    //    `main()`.
    // 5. `$dartReloadModifiedModules` calls the callback to rerun main.
    //
    async function hotRestart(config) {
      if (!self || !self.$dartReloadModifiedModules) {
        console.warn('Hot restart not supported in this environment.');
        return;
      }

      // If `config.runId` is set (e.g. a unique build ID that represent the
      // current build and shared by multiple subapps), skip the following runs
      // with the same id.
      if (config && config.runId) {
        if (_hotRestartRunIdCache.indexOf(config.runId) >= 0) {
          // The run has already started (by other subapp or app)
          return;
        }
        _hotRestartRunIdCache.push(config.runId);

        // Only cache the runIds for the last N runs. We assume that there are
        // less than N requests with different runId can happen in a very short
        // period of time (e.g. 1 second).
        if (_hotRestartRunIdCache.length > 10) {
          _hotRestartRunIdCache.shift();
        }
      }

      self.console.clear();
      const sdk = _libraries.get('dart_sdk');

      // Finds out what apps and their subapps should be hot restarted in
      // their starting order.
      const dirtyAppNames = new Array();
      const dirtySubapps = new Array();
      if (config && config.runId) {
        _nameToApp.forEach(function (app, appName) {
          dirtySubapps.push(...app.uuidToSubapp.values());
          dirtyAppNames.push(appName);
        });
      } else {
        dirtySubapps.push(_lastStartedSubapp);
        dirtyAppNames.push(_lastStartedSubapp.appName);
      }

      // Invokes onReloadStart for each subapp in reversed starting order.
      const onReloadStartPromises = new Array();
      for (const subapp of dirtySubapps.reverse()) {
        // Call the application's `onReloadStart()` function, if provided.
        if (subapp.library && subapp.library.onReloadStart) {
          const result = subapp.library.onReloadStart();
          if (result && result.then) {
            let resolve;
            onReloadStartPromises.push(new Promise(function (res, _) {
              resolve = res;
            }));
            const dart = sdk.libraryValueInApp(subapp.appName).dart;
            result.then(dart.dynamic, function () {
              resolve();
            });
          }
        }
      }
      // Reverse the subapps back to starting order.
      dirtySubapps.reverse();

      await Promise.all(onReloadStartPromises);

      // Invokes SDK `hotRestart` to reset all initialized fields and clears
      // type caches and other temporary data structures used by the
      // compiler/SDK.
      for (const appName of dirtyAppNames) {
        sdk.libraryValueInApp(appName).dart.hotRestart();
      }

      // Invoke `hotRestart` for the deferred loader to clear load ids and
      // other temporary state.
      if (self.deferred_loader) {
        self.deferred_loader.hotRestart();
      }

      // Starts the subapps in their starting order.
      for (const subapp of dirtySubapps) {
        // Call the module loader to reload the necessary modules.
        self.$dartReloadModifiedModules(subapp.appName, async function () {
          // If the promise `readyToRunMain` is provided, then wait for
          // it. This gives the debugging clients time to set any breakpoints.
          if (!!(config && config.readyToRunMain)) {
            await config.readyToRunMain;
          }
          // Once the modules are loaded, rerun `main()`.
          start(
            subapp.appName, subapp.uuid, subapp.moduleName,
            subapp.libraryName, true);
        });
      }
    }
    self.dart_library.reload = hotRestart;

    // Creates a script with the proper nonce value for strict CSP or noops on
    // invalid platforms.
    self.dart_library.createScript = (function () {
      // Exit early if we aren't modifying an HtmlElement (such as in D8).
      if (self.dart_library.isD8) return;
      // Find the nonce value. (Note, this is only computed once.)
      const scripts = Array.from(document.getElementsByTagName('script'));
      let nonce;
      scripts.some(
        script => (nonce = script.nonce || script.getAttribute('nonce')));
      // If present, return a closure that automatically appends the nonce.
      if (nonce) {
        return function () {
          let script = document.createElement('script');
          script.nonce = nonce;
          return script;
        };
      } else {
        return function () {
          return document.createElement('script');
        };
      }
    })();

    /// An App contains one or multiple Subapps, all of the subapps share the
    /// same memory copy of library instances, and as a result they share state
    /// in Dart statics and top-level fields. There can be one or multiple Apps
    /// in a browser window, all of the Apps are isolated from each other
    /// (i.e. they create different instances even for the same module).
    class App {
      constructor(name) {
        this.name = name;

        // Subapp's uuid to subapps in initial starting order.
        // (ES6 preserves iteration order)
        this.uuidToSubapp = new Map();
      }
    }

    class Subapp {
      constructor(uuid, appName, moduleName, libraryName, library) {
        this.uuid = uuid;
        this.appName = appName;
        this.moduleName = moduleName;
        this.libraryName = libraryName;
        this.library = library;

        this.originalBody = null;
      }
    }

    // App name to App map in initial starting order.
    // (ES6 preserves iteration order)
    const _nameToApp = new Map();
    let _firstStartedAppName;
    let _lastStartedSubapp;

    /// Starts a subapp that is identified with `uuid`, `moduleName`, and
    /// `libraryName` inside a parent app that is identified by `appName`.
    function start(appName, uuid, moduleName, libraryName, isReload) {
      console.info(
        `DDC: Subapp Module [${appName}:${moduleName}:${uuid}] is starting`);
      if (libraryName == null) libraryName = moduleName;
      const library = import_(moduleName, appName)[libraryName];

      let app = _nameToApp.get(appName);
      if (!isReload) {
        if (!app) {
          app = new App(appName);
          _nameToApp.set(appName, app);
        }

        let subapp = app.uuidToSubapp.get(uuid);
        if (!subapp) {
          subapp = new Subapp(uuid, appName, moduleName, libraryName, library);
          app.uuidToSubapp.set(uuid, subapp);
        }

        _lastStartedSubapp = subapp;
        if (!_firstStartedAppName) {
          _firstStartedAppName = appName;
        }
      }

      const subapp = app.uuidToSubapp.get(uuid);
      const sdk = import_('dart_sdk', appName);

      if (!_debuggerInitialized) {
        // This import is only needed for chrome debugging. We should provide an
        // option to compile without it.
        sdk._debugger.registerDevtoolsFormatter();

        // Create isolate.
        _debuggerInitialized = true;
      }
      if (isReload) {
        // subapp may have been modified during reload, `subapp.library` needs
        // to always point to the latest data.
        subapp.library = library;

        if (library.onReloadEnd) {
          library.onReloadEnd();
          return;
        } else {
          if (!!self.document) {
            // Note: we expect originalBody to be undefined in non-browser
            // environments, but in that case so is the body.
            if (!subapp.originalBody && !!self.document.body) {
              self.console.warn('No body saved to update on reload');
            } else {
              self.document.body = subapp.originalBody;
            }
          }
        }
      } else {
        // If not a reload and `onReloadEnd` is not defined, store the initial
        // html to reset it on reload.
        if (!library.onReloadEnd && !!self.document && !!self.document.body) {
          subapp.originalBody = self.document.body.cloneNode(true);
        }
      }
      library.main([]);
    }
    dart_library.start = start;
  })(dart_library);
}

// Initialize the DDC module loader.
//
// Scripts are JS objects with the following structure:
//   {"src": "path/to/script.js", "id": "lookup_id_for_script"}
(function () {
  let _currentDirectory = (function () {
    let _url = document.currentScript.src;
    let lastSlash = _url.lastIndexOf('/');
    if (lastSlash == -1) return _url;
    let currentDirectory = _url.substring(0, lastSlash + 1);
    return currentDirectory;
  })();

  let trimmedDirectory = _currentDirectory.endsWith("/") ?
    _currentDirectory.substring(0, _currentDirectory.length - 1)
    : _currentDirectory;

  if (!self.$dartLoader) {
    self.$dartLoader = {
      // Maps cosmetic (but stable) module names to their fully resolved URL.
      //
      // TODO(markzipan): Multi-app scripts can have module name conflicts.
      // This should ideally be separated per-app.
      moduleIdToUrl: new Map(),
      // Contains root directories below which scripts are resolved.
      rootDirectories: new Array(),
      // This mapping is required for proper translation of stack traces.
      urlToModuleId: new Map(),
      // The DDCLoader used for this app. Should not be used in multi-app
      // scenarios.
      loader: null,
      // The LoadConfiguration used for this app's DDCLoader. Should not be used
      // in multi-app scenarios.
      loadConfig: null
    };

    // Every distinct DDC app requires its own load configuration.
    self.$dartLoader.LoadConfiguration = class LoadConfiguration {
      constructor() {
        // Identifies the bootstrap script.
        // This should be set by bootstrappers for bootstrap-specific hooks.
        this.bootstrapScript = null;

        // True if the bootstrap script should be loaded on the this attempt.
        this.tryLoadBootstrapScript = false;

        // The underlying function that loads scripts.
        //
        // @param {function(!DDCLoader)}
        this.loadScriptFn = (_) => { };

        // The root for script URLs. Defaults to the root of this file.
        //
        // TODO(markzipan): Using the default is not safe in a multi-app scenario
        // due to apps clobbering state on dartLoader. Move this to the local
        // DDCLoader, which is unique per-app.
        this.root = trimmedDirectory;

        this.isWindows = false;

        // Optional event handlers.
        // Called when modules begin loading.
        this.onLoadStart = () => { };
        // Called when the app fails to load after retrying.
        this.onLoadError = () => { };
        // Called if loading the bootstrap script is successful.
        this.onBootstrapSuccess = () => { };
        // Called if the bootstrap script fails to load.
        this.onBootstrapError = () => { };

        this.maxRequestPoolSize = 1000;

        // Max retry to prevent from load failing scripts forever.
        this.maxAttempts = 6;
      }
    };
  }

  // Loads a single script onto the page.
  // TODO(markzipan): Is there a cleaner way to integrate this?
  self.$dartLoader.forceLoadScript = function (jsFile) {
    if (self.dart_library.isD8) {
      self.load(jsFile);
      return;
    }
    let script = self.dart_library.createScript();
    let policy = {
      createScriptURL: function (src) { return src; }
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.setAttribute('src', policy.createScriptURL(jsFile));
    document.head.appendChild(script);
  };

  self.$dartLoader.forceLoadModule = function (moduleName) {
    let modulePathScript = _currentDirectory + moduleName + '.js';
    self.$dartLoader.forceLoadScript(modulePathScript);
  };

  // Handles JS script downloads and evaluation for a DDC app.
  //
  // Every DDC application requires exactly one DDCLoader.
  self.$dartLoader.DDCLoader = class DDCLoader {
    constructor(loadConfig) {
      this.attemptCount = 0;

      this.loadConfig = loadConfig;

      // Scripts that await to be loaded.
      this.queue = new Array();

      // These refer to scripts already added to the document (as script tag).
      this.numToLoad = 0;
      this.numLoaded = 0;
      this.numFailed = 0;

      // Resets all the fields and makes a load attempt.
      this.nextAttempt = function () {
        if (this.attemptCount == 0) {
          this.loadConfig.onLoadStart();
        }
        this.attemptCount++;
        this.queue = new Array();
        this.numToLoad = 0;
        this.numLoaded = 0;
        this.numFailed = 0;

        this.loadConfig.loadScriptFn(this);
      };

      // The current hot restart generation.
      //
      // 0-indexed and increases by 1 on every successful hot restart.
      // This value is read to determine the 'current' hot restart generation
      // in our hot restart tests. This closely tracks but is not the same as
      // `hotRestartIteration` in DDC's runtime.
      this.hotRestartGeneration = 0;

      // The current 'intended' hot restart generation.
      //
      // 0-indexed and increases by 1 on every successful hot restart.
      // Unlike `hotRestartGeneration`, this is incremented when the intent to
      // perform a hot restart is established.
      // This is used to synchronize D8 timers and lookup files to load in
      // each generation for hot restart testing.
      this.intendedHotRestartGeneration = 0;

      // The current hot reload generation.
      //
      // 0-indexed and increases by 1 on every successful hot reload.
      this.hotReloadGeneration = 0;
    }

    // True if we are still processing scripts from the script queue.
    // 'Processing' means the script is 1) currently being downloaded/parsed
    // or 2) the script failed to download and is being retried.
    scriptsActivelyBeingLoaded() {
      return this.numToLoad > this.numLoaded + this.numFailed;
    };

    // Joins path segments from the root directory to [script]'s path to get a
    // complete URL.
    getScriptUrl(script) {
      let pathSlash = this.loadConfig.isWindows ? "\\" : "/";
      // Get path segments for src
      let splitSrc = script.src.toString().split(pathSlash);
      let j = 0;
      // Count number of relative path segments
      while (splitSrc[j] == "..") {
        j++;
      }
      // Get path segments for root directory
      let splitDir = !this.loadConfig.root
        || this.loadConfig.root == pathSlash ? []
        : this.loadConfig.root.split(pathSlash);
      // Account for relative path from the root directory
      let splitPath = splitDir
        .slice(0, splitDir.length - j)
        .concat(splitSrc.slice(j));
      // Join path segments to get a complete path
      return splitPath.join(pathSlash);
    };

    // Adds [script] to the dartLoader's internals as if it had been loaded and
    // returns its fully resolved source path.
    //
    // Should be called when scripts are loaded on the page externally from
    // dartLoader's API.
    registerScript(script) {
      const src = this.getScriptUrl(script);
      // TODO(markzipan): moduleIdToUrl and urlToModuleId may conflict in
      // multi-app scenarios. Fix this by moving them into the DDCLoader.
      self.$dartLoader.moduleIdToUrl.set(script.id, src);
      self.$dartLoader.urlToModuleId.set(src, script.id);
      return src;
    };

    // Adds [scripts] to [queue] according to validation function [allowScriptFn].
    //
    // Scripts aren't loaded until loadEnqueuedModules is called.
    addScriptsToQueue(scripts, allowScriptFn) {
      for (let i = 0; i < scripts.length; i++) {
        const script = scripts[i];

        // Only load the bootstrap script after every other script has finished loading.
        if (script.src == this.loadConfig.bootstrapScript.src) {
          this.loadConfig.tryLoadBootstrapScript = true;
          continue;
        }
        // Skip loading already-loaded scripts.
        if (script.id == null || self.$dartLoader.moduleIdToUrl.has(script.id)) {
          continue;
        }

        // Register this script's resolved URL.
        let resolvedSrc = this.registerScript(script);

        // Deferred scripts should be registered but not added during bootstrap.
        if (self.$dartLoader.bootstrapModules !== void 0 &&
          !self.$dartLoader.bootstrapModules.has(script.id)) {
          continue;
        }

        if (!allowScriptFn || allowScriptFn(script)) {
          this.queue.push({ id: script.id, src: resolvedSrc });
        }
      }

      if (this.queue.length > 0) {
        console.info(
          `DDC is about to load ${this.queue.length}/${scripts.length} scripts with pool size = ${this.loadConfig.maxRequestPoolSize}`);
      }
    };

    // Creates a script element to be loaded into the provided container.
    createAndLoadScript(src, id, container, onError, onLoad) {
      let el = self.dart_library.createScript();
      el.src = policy.createScriptURL(src);
      el.async = false;
      el.defer = true;
      el.id = id;
      el.onerror = onError;
      el.onload = onLoad;
      container.appendChild(el);
    };

    // Retrieves scripts from the loader queue, with at most [maxRequests]
    // outgoing requests.
    //
    // TODO(markzipan): Rewrite this with a promise pool.
    loadMore(maxRequests) {
      let fragment = document.createDocumentFragment();
      let inflightRequests = 0;
      while (this.queue.length > 0 && inflightRequests++ < maxRequests) {
        const script = this.queue.shift();
        this.numToLoad++;
        this.createAndLoadScript(
          script.src.toString(),
          script.id,
          fragment,
          this.onError.bind(this),
          this.onLoad.bind(this)
        );
      }
      if (inflightRequests > 0) {
        document.head.appendChild(fragment);
      } else if (!this.scriptsActivelyBeingLoaded()) {
        this.loadBootstrapJs();
      }
    };

    loadOneMore() {
      if (this.queue.length > 0) {
        this.loadMore(1);
      }
    };

    // Loads modules when running with Chrome.
    loadEnqueuedModules() {
      this.loadMore(this.loadConfig.maxRequestPoolSize);
    };

    // Loads modules when running with d8.
    loadEnqueuedModulesForD8() {
      if (!self.dart_library.isD8) {
        throw Error("'loadEnqueuedModulesForD8' is only supported in D8.");
      }
      // Load all enqueued scripts sequentially.
      for (let i = 0; i < this.queue.length; i++) {
        const script = this.queue[i];
        self.load(script.src.toString());
      }
      this.queue.length = 0;
      // Load the bootstrapper script if it wasn't already loaded.
      if (this.loadConfig.tryLoadBootstrapScript) {
        const script = this.loadConfig.bootstrapScript;
        const src = this.registerScript(script);
        self.load(src);
        this.loadConfig.tryLoadBootstrapScript = false;
      }
      return;
    };

    // Loads just the bootstrap script.
    //
    // The bootstrapper is loaded only after all other scripts are loaded.
    loadBootstrapJs() {
      if (!this.loadConfig.tryLoadBootstrapScript) {
        return;
      }
      const script = this.loadConfig.bootstrapScript;
      const src = this.registerScript(script);
      this.createAndLoadScript(src, script.id, document.head, null, null);
      this.loadConfig.tryLoadBootstrapScript = false;
    };

    // Loads/retries compiled JS scripts.
    //
    // Should always be called after a script is loaded or errors.
    processAfterLoadOrErrorEvent() {
      if (this.scriptsActivelyBeingLoaded()) {
        if (this.numFailed == 0) {
          this.loadOneMore();
        } else if (this.attemptCount > this.maxAttempts) {
          // Some scripts have failed to load. Continue loading the rest.
          this.loadOneMore();
        } else {
          // Some scripts have failed to load, but we can still make another
          // load attempt. Wait for scheduled scripts to finish.
        }
        return;
      }

      // Retry failed scripts to a limit, then load the bootstrap script.
      if (this.numFailed == 0) {
        this.loadBootstrapJs();
        return;
      }
      // Reload whatever failed if maxAttempts is not reached.
      if (this.numFailed > 0) {
        if (this.attemptCount <= this.loadConfig.maxAttempts) {
          this.nextAttempt();
        } else {
          console.error(
            `Failed to load DDC scripts after ${this.loadConfig.maxAttempts} tries`);
          this.loadConfig.onLoadError();
          this.loadBootstrapJs();
        }
      }
    };

    onLoad(e) {
      this.numLoaded++;
      if (e.target.src == this.loadConfig.bootstrapScript.src) {
        this.loadConfig.onBootstrapSuccess();
      }
      this.processAfterLoadOrErrorEvent();
    };

    onError(e) {
      this.numFailed++;
      const target = e.target;
      self.$dartLoader.moduleIdToUrl.delete(target.id);
      self.$dartLoader.urlToModuleId.delete(target.src);
      self.deferred_loader.clearModule(target.id);

      if (target.src == this.loadConfig.bootstrapScript.src) {
        this.loadConfig.onBootstrapError();
      }
      this.processAfterLoadOrErrorEvent();
    };

    // Initiates a hot reload.
    // TODO(markzipan): This function is currently stubbed out for testing.
    hotReload() {
      this.hotReloadGeneration += 1;
    }

    // Initiates a hot restart.
    hotRestart() {
      this.intendedHotRestartGeneration += 1;
      self.dart_library.reload();
    }
  };

  let policy = {
    createScriptURL: function (src) { return src; }
  };

  if (self.trustedTypes && self.trustedTypes.createPolicy) {
    policy = self.trustedTypes.createPolicy("dartDdcModuleUrl", policy);
  }

  self.$dartLoader.loadScripts = function (scripts, loader) {
    loader.loadConfig.loadScriptFn = function (loader) {
      loader.addScriptsToQueue(scripts, null);
      loader.loadEnqueuedModules();
    };
    loader.nextAttempt();
  };
})();

if (!self.deferred_loader) {
  self.deferred_loader = {
    // Module IDs already loaded on the page (e.g., during bootstrap or after
    // loadLibrary is called).
    loadedModules: new Set(),
    // An import graph of all direct imports (not deferred).
    moduleGraph: new Map(),
    // Maps module IDs to their resolved urls.
    moduleToUrl: new Map(),
    // Module IDs mapped to their resolved or resolving promises.
    moduleToPromise: new Map(),
    // Deferred libraries on which 'loadLibrary' have already been called.
    // Load Ids are a composite of the URI of originating load's library and
    // the target library name.
    loadIds: new Set(),
  };

  /**
   * Must be called before 'main' to initialize the deferred loader.
   * @param {!Map<string, string>} moduleToUrlMapping
   * @param {!Map<string, !Array<string>>} moduleGraph non-deferred import graph
   * @param {!Array<string>} loadedModules moduled loaded during bootstrap
   */
  self.deferred_loader.initDeferredLoader = function (
    moduleToUrlMapping, moduleGraph, loadedModules) {
    self.deferred_loader.moduleToUrl = moduleToUrlMapping;
    self.deferred_loader.moduleGraph = moduleGraph;
    for (let i = 0; i < loadedModules.length; i++) {
      let module = loadedModules[i];
      self.deferred_loader.loadedModules.add(module);
      self.deferred_loader.moduleToPromise.set(module, Promise.resolve());
    }
  };

  /**
   * Returns all modules downstream of [moduleId] that are visible
   * (i.e., not deferred) and have not already been loaded.
   * @param {string} moduleId
   * @return {!Array<string>} module IDs that must be loaded with [moduleId]
   */
  let dependenciesToLoad = function (moduleId) {
    let stack = [moduleId];
    let seen = new Set();
    while (stack.length > 0) {
      let module = stack.pop();
      if (seen.has(module)) continue;
      seen.add(module);
      stack = stack.concat(self.deferred_loader.moduleGraph.get(module));
    }
    let dependencies = [];
    seen.forEach(module => {
      if (self.deferred_loader.loadedModules.has(module)) return;
      dependencies.push(module);
    });
    return dependencies;
  };

  /**
   * Loads [moduleUrl] onto this instance's DDC app's page, then invokes
   * [onLoad].
   * @param {string} moduleUrl
   * @param {function()} onLoad Callback after a successful load
   */
  let loadScript = function (moduleUrl, onLoad) {
    // A head element won't be created for D8, so just load synchronously.
    if (self.dart_library.isD8) {
      self.load(moduleUrl);
      onLoad();
      return;
    }
    let script = dart_library.createScript();
    let policy = {
      createScriptURL: function (src) {
        return src;
      }
    };
    if (self.trustedTypes && self.trustedTypes.createPolicy) {
      policy = self.trustedTypes.createPolicy('dartDdcModuleUrl', policy);
    }
    script.setAttribute('src', policy.createScriptURL(moduleUrl));
    script.async = false;
    script.defer = true;
    script.onload = onLoad;
    self.document.head.appendChild(script);
  };

  /**
   * Performs a deferred load, calling [onSuccess] or [onError] callbacks when
   * the deferred load completes or fails, respectively.
   * @param {string} loadId {library URI}:{resource name being loaded}
   * @param {string} targetModule moduleId of the resource requested by [loadId]
   * @param {function(function())} onSuccess callback after a successful load
   * @param {function(!Error)} onError callback after a failed load
   */
  self.deferred_loader.loadDeferred = function (
    loadId, targetModule, onSuccess, onError) {
    // loadLibrary had already been called, and its module has already been
    // loaded, so just complete the future.
    if (self.deferred_loader.loadIds.has(loadId)) {
      onSuccess();
      return;
    }

    // The module's been loaded, so mark this import as loaded and finish.
    if (self.deferred_loader.loadedModules.has(targetModule)) {
      self.deferred_loader.loadIds.add(loadId);
      onSuccess();
      return;
    }

    // The import's module has not been loaded, so load it and its dependencies
    // before completing the callback.
    let modulesToLoad = dependenciesToLoad(targetModule);
    Promise
      .all(modulesToLoad.map(module => {
        let url = self.deferred_loader.moduleToUrl.get(module);
        if (url === void 0) {
          console.log('Unable to find URL for module: ' + module);
          return;
        }
        let promise = self.deferred_loader.moduleToPromise.get(module);
        if (promise !== void 0) return promise;
        self.deferred_loader.moduleToPromise.set(
          module,
          new Promise((resolve) => loadScript(url, () => {
            self.deferred_loader.loadedModules.add(module);
            resolve();
          })));
        return self.deferred_loader.moduleToPromise.get(module);
      }))
      .then(() => {
        onSuccess(() => self.deferred_loader.loadIds.add(loadId));
      })
      .catch((error) => {
        onError(error.message);
      });
  };

  /**
   * Returns whether or not the module containing [loadId] has finished loading.
   * @param {string} loadId library URI concatenated with the resource being
   *     loaded
   * @return {boolean}
   */
  self.deferred_loader.isLoaded = function (loadId) {
    return self.deferred_loader.loadIds.has(loadId);
  };

  /**
   * Removes references to [moduleId] in the deferred loader.
   * @param {string} moduleId
   *
   * TODO(markzipan): Determine how deep we should clear moduleId's references.
   */
  self.deferred_loader.clearModule = function (moduleId) {
    self.deferred_loader.loadedModules.delete(moduleId);
    self.deferred_loader.moduleToUrl.delete(moduleId);
    self.deferred_loader.moduleToPromise.delete(moduleId);
  };

  /**
   * Clears state required for hot restart.
   */
  self.deferred_loader.hotRestart = function () {
    self.deferred_loader.loadIds = new Set();
  };
}

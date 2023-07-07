// make sure to keep this as 'var'
// we don't want block scoping

var dartNodePreambleSelf = typeof global !== "undefined" ? global : window;

var self = Object.create(dartNodePreambleSelf);

self.scheduleImmediate = typeof setImmediate !== "undefined"
    ? function (cb) {
        setImmediate(cb);
      }
    : function(cb) {
        setTimeout(cb, 0);
      };

// CommonJS globals.
self.require = require;
self.exports = exports;

// Node.js specific exports, check to see if they exist & or polyfilled

if (typeof process !== "undefined") {
  self.process = process;
}

if (typeof __dirname !== "undefined") {
  self.__dirname = __dirname;
}

if (typeof __filename !== "undefined") {
  self.__filename = __filename;
}

if (typeof Buffer !== "undefined") {
  self.Buffer = Buffer;
}

// if we're running in a browser, Dart supports most of this out of box
// make sure we only run these in Node.js environment

var dartNodeIsActuallyNode = !dartNodePreambleSelf.window

try {
  // Check if we're in a Web Worker instead.
  if ("undefined" !== typeof WorkerGlobalScope && dartNodePreambleSelf instanceof WorkerGlobalScope) {
    dartNodeIsActuallyNode = false;
  }

  // Check if we're in Electron, with Node.js integration, and override if true.
  if ("undefined" !== typeof process && process.versions && process.versions.hasOwnProperty('electron') && process.versions.hasOwnProperty('node')) {
    dartNodeIsActuallyNode = true;
  }
} catch(e) {}

if (dartNodeIsActuallyNode) {
  // This line is to:
  // 1) Prevent Webpack from bundling.
  // 2) In Webpack on Node.js, make sure we're using the native Node.js require, which is available via __non_webpack_require__
  // https://github.com/mbullington/node_preamble.dart/issues/18#issuecomment-527305561
  var url = ("undefined" !== typeof __webpack_require__ ? __non_webpack_require__ : require)("url");

  // Setting `self.location=` in Electron throws a `TypeError`, so we define it
  // as a property instead to be safe.
  Object.defineProperty(self, "location", {
    value: {
      get href() {
        if (url.pathToFileURL) {
          return url.pathToFileURL(process.cwd()).href + "/";
        } else {
          // This isn't really a correct transformation, but it's the best we have
          // for versions of Node <10.12.0 which introduced `url.pathToFileURL()`.
          // For example, it will fail for paths that contain characters that need
          // to be escaped in URLs.
          return "file://" + (function() {
            var cwd = process.cwd();
            if (process.platform != "win32") return cwd;
            return "/" + cwd.replace(/\\/g, "/");
          })() + "/"
        }
      }
    }
  });

  (function() {
    function computeCurrentScript() {
      try {
        throw new Error();
      } catch(e) {
        var stack = e.stack;
        var re = new RegExp("^ *at [^(]*\\((.*):[0-9]*:[0-9]*\\)$", "mg");
        var lastMatch = null;
        do {
          var match = re.exec(stack);
          if (match != null) lastMatch = match;
        } while (match != null);
        return lastMatch[1];
      }
    }

    // Setting `self.document=` isn't known to throw an error anywhere like
    // `self.location=` does on Electron, but it's better to be future-proof
    // just in case..
    var cachedCurrentScript = null;
    Object.defineProperty(self, "document", {
      value: {
        get currentScript() {
          if (cachedCurrentScript == null) {
            cachedCurrentScript = {src: computeCurrentScript()};
          }
          return cachedCurrentScript;
        }
      }
    });
  })();

  self.dartDeferredLibraryLoader = function(uri, successCallback, errorCallback) {
    try {
     load(uri);
      successCallback();
    } catch (error) {
      errorCallback(error);
    }
  };
}

// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It should return a JS Array containing 2 elements. The first
  //   should be the bytes for the wasm module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The second
  //   should be the result of using the JS 'import' API on the js file path.
  async instantiate(additionalImports, {loadDeferredWasm, loadDynamicModule} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _3: (o, t) => typeof o === t,
      _4: (o, c) => o instanceof c,
      _5: o => Object.keys(o),
      _35: () => new Array(),
      _36: x0 => new Array(x0),
      _38: x0 => x0.length,
      _40: (x0,x1) => x0[x1],
      _41: (x0,x1,x2) => { x0[x1] = x2 },
      _43: x0 => new Promise(x0),
      _45: (x0,x1,x2) => new DataView(x0,x1,x2),
      _47: x0 => new Int8Array(x0),
      _48: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _49: x0 => new Uint8Array(x0),
      _51: x0 => new Uint8ClampedArray(x0),
      _53: x0 => new Int16Array(x0),
      _55: x0 => new Uint16Array(x0),
      _57: x0 => new Int32Array(x0),
      _59: x0 => new Uint32Array(x0),
      _61: x0 => new Float32Array(x0),
      _63: x0 => new Float64Array(x0),
      _65: (x0,x1,x2) => x0.call(x1,x2),
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _73: (s) => +s,
      _74: x0 => new Uint8Array(x0),
      _75: (x0,x1,x2) => x0.set(x1,x2),
      _76: (x0,x1) => x0.transferFromImageBitmap(x1),
      _78: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._78(f,arguments.length,x0) }),
      _79: x0 => new window.FinalizationRegistry(x0),
      _80: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _81: (x0,x1) => x0.unregister(x1),
      _82: (x0,x1,x2) => x0.slice(x1,x2),
      _83: (x0,x1) => x0.decode(x1),
      _84: (x0,x1) => x0.segment(x1),
      _85: () => new TextDecoder(),
      _87: x0 => x0.buffer,
      _88: x0 => x0.wasmMemory,
      _89: () => globalThis.window._flutter_skwasmInstance,
      _90: x0 => x0.rasterStartMilliseconds,
      _91: x0 => x0.rasterEndMilliseconds,
      _92: x0 => x0.imageBitmaps,
      _196: x0 => x0.stopPropagation(),
      _197: x0 => x0.preventDefault(),
      _199: x0 => x0.remove(),
      _200: (x0,x1) => x0.append(x1),
      _201: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _246: x0 => x0.unlock(),
      _247: x0 => x0.getReader(),
      _248: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _249: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _250: (x0,x1) => x0.item(x1),
      _251: x0 => x0.next(),
      _252: x0 => x0.now(),
      _253: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._253(f,arguments.length,x0) }),
      _254: (x0,x1) => x0.addListener(x1),
      _255: (x0,x1) => x0.removeListener(x1),
      _256: (x0,x1) => x0.matchMedia(x1),
      _257: (x0,x1) => x0.revokeObjectURL(x1),
      _258: x0 => x0.close(),
      _259: (x0,x1,x2,x3,x4) => ({type: x0,data: x1,premultiplyAlpha: x2,colorSpaceConversion: x3,preferAnimation: x4}),
      _260: x0 => new window.ImageDecoder(x0),
      _261: x0 => ({frameIndex: x0}),
      _262: (x0,x1) => x0.decode(x1),
      _263: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._263(f,arguments.length,x0) }),
      _264: (x0,x1) => x0.getModifierState(x1),
      _265: (x0,x1) => x0.removeProperty(x1),
      _266: (x0,x1) => x0.prepend(x1),
      _267: x0 => new Intl.Locale(x0),
      _268: x0 => x0.disconnect(),
      _269: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._269(f,arguments.length,x0) }),
      _270: (x0,x1) => x0.getAttribute(x1),
      _271: (x0,x1) => x0.contains(x1),
      _272: (x0,x1) => x0.querySelector(x1),
      _273: x0 => x0.blur(),
      _274: x0 => x0.hasFocus(),
      _275: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _276: (x0,x1) => x0.hasAttribute(x1),
      _277: (x0,x1) => x0.getModifierState(x1),
      _278: (x0,x1) => x0.createTextNode(x1),
      _279: (x0,x1) => x0.appendChild(x1),
      _280: (x0,x1) => x0.removeAttribute(x1),
      _281: x0 => x0.getBoundingClientRect(),
      _282: (x0,x1) => x0.observe(x1),
      _283: x0 => x0.disconnect(),
      _284: (x0,x1) => x0.closest(x1),
      _715: () => globalThis.window.flutterConfiguration,
      _717: x0 => x0.assetBase,
      _722: x0 => x0.canvasKitMaximumSurfaces,
      _723: x0 => x0.debugShowSemanticsNodes,
      _724: x0 => x0.hostElement,
      _725: x0 => x0.multiViewEnabled,
      _726: x0 => x0.nonce,
      _728: x0 => x0.fontFallbackBaseUrl,
      _738: x0 => x0.console,
      _739: x0 => x0.devicePixelRatio,
      _740: x0 => x0.document,
      _741: x0 => x0.history,
      _742: x0 => x0.innerHeight,
      _743: x0 => x0.innerWidth,
      _744: x0 => x0.location,
      _745: x0 => x0.navigator,
      _746: x0 => x0.visualViewport,
      _747: x0 => x0.performance,
      _749: x0 => x0.URL,
      _751: (x0,x1) => x0.getComputedStyle(x1),
      _752: x0 => x0.screen,
      _753: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._753(f,arguments.length,x0) }),
      _754: (x0,x1) => x0.requestAnimationFrame(x1),
      _759: (x0,x1) => x0.warn(x1),
      _761: (x0,x1) => x0.debug(x1),
      _762: x0 => globalThis.parseFloat(x0),
      _763: () => globalThis.window,
      _764: () => globalThis.Intl,
      _765: () => globalThis.Symbol,
      _766: (x0,x1,x2,x3,x4) => globalThis.createImageBitmap(x0,x1,x2,x3,x4),
      _768: x0 => x0.clipboard,
      _769: x0 => x0.maxTouchPoints,
      _770: x0 => x0.vendor,
      _771: x0 => x0.language,
      _772: x0 => x0.platform,
      _773: x0 => x0.userAgent,
      _774: (x0,x1) => x0.vibrate(x1),
      _775: x0 => x0.languages,
      _776: x0 => x0.documentElement,
      _777: (x0,x1) => x0.querySelector(x1),
      _780: (x0,x1) => x0.createElement(x1),
      _783: (x0,x1) => x0.createEvent(x1),
      _784: x0 => x0.activeElement,
      _787: x0 => x0.head,
      _788: x0 => x0.body,
      _790: (x0,x1) => { x0.title = x1 },
      _793: x0 => x0.visibilityState,
      _794: () => globalThis.document,
      _795: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._795(f,arguments.length,x0) }),
      _796: (x0,x1) => x0.dispatchEvent(x1),
      _804: x0 => x0.target,
      _806: x0 => x0.timeStamp,
      _807: x0 => x0.type,
      _809: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _815: x0 => x0.baseURI,
      _816: x0 => x0.firstChild,
      _820: x0 => x0.parentElement,
      _822: (x0,x1) => { x0.textContent = x1 },
      _823: x0 => x0.parentNode,
      _824: x0 => x0.nextSibling,
      _825: (x0,x1) => x0.removeChild(x1),
      _826: x0 => x0.isConnected,
      _831: x0 => x0.firstElementChild,
      _834: x0 => x0.clientHeight,
      _835: x0 => x0.clientWidth,
      _836: x0 => x0.offsetHeight,
      _837: x0 => x0.offsetWidth,
      _838: x0 => x0.id,
      _839: (x0,x1) => { x0.id = x1 },
      _842: (x0,x1) => { x0.spellcheck = x1 },
      _843: x0 => x0.tagName,
      _844: x0 => x0.style,
      _846: (x0,x1) => x0.querySelectorAll(x1),
      _847: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _848: x0 => x0.tabIndex,
      _849: (x0,x1) => { x0.tabIndex = x1 },
      _850: (x0,x1) => x0.focus(x1),
      _851: x0 => x0.scrollTop,
      _852: (x0,x1) => { x0.scrollTop = x1 },
      _853: x0 => x0.scrollLeft,
      _854: (x0,x1) => { x0.scrollLeft = x1 },
      _855: x0 => x0.classList,
      _856: (x0,x1) => { x0.className = x1 },
      _859: (x0,x1) => x0.getElementsByClassName(x1),
      _860: x0 => x0.click(),
      _861: (x0,x1) => x0.attachShadow(x1),
      _864: x0 => x0.computedStyleMap(),
      _865: (x0,x1) => x0.get(x1),
      _871: (x0,x1) => x0.getPropertyValue(x1),
      _872: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _873: x0 => x0.offsetLeft,
      _874: x0 => x0.offsetTop,
      _875: x0 => x0.offsetParent,
      _877: (x0,x1) => { x0.name = x1 },
      _878: x0 => x0.content,
      _879: (x0,x1) => { x0.content = x1 },
      _883: (x0,x1) => { x0.src = x1 },
      _884: x0 => x0.naturalWidth,
      _885: x0 => x0.naturalHeight,
      _889: (x0,x1) => { x0.crossOrigin = x1 },
      _891: (x0,x1) => { x0.decoding = x1 },
      _892: x0 => x0.decode(),
      _896: (x0,x1) => { x0.nonce = x1 },
      _902: (x0,x1) => { x0.width = x1 },
      _904: (x0,x1) => { x0.height = x1 },
      _907: (x0,x1) => x0.getContext(x1),
      _975: x0 => x0.width,
      _976: x0 => x0.height,
      _978: (x0,x1) => x0.fetch(x1),
      _979: x0 => x0.status,
      _981: x0 => x0.body,
      _982: x0 => x0.arrayBuffer(),
      _985: x0 => x0.read(),
      _986: x0 => x0.value,
      _987: x0 => x0.done,
      _994: x0 => x0.name,
      _995: x0 => x0.x,
      _996: x0 => x0.y,
      _999: x0 => x0.top,
      _1000: x0 => x0.right,
      _1001: x0 => x0.bottom,
      _1002: x0 => x0.left,
      _1012: x0 => x0.height,
      _1013: x0 => x0.width,
      _1014: x0 => x0.scale,
      _1015: (x0,x1) => { x0.value = x1 },
      _1018: (x0,x1) => { x0.placeholder = x1 },
      _1019: (x0,x1) => { x0.name = x1 },
      _1021: x0 => x0.selectionDirection,
      _1022: x0 => x0.selectionStart,
      _1023: x0 => x0.selectionEnd,
      _1026: x0 => x0.value,
      _1028: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1029: x0 => x0.readText(),
      _1030: (x0,x1) => x0.writeText(x1),
      _1032: x0 => x0.altKey,
      _1033: x0 => x0.code,
      _1034: x0 => x0.ctrlKey,
      _1035: x0 => x0.key,
      _1036: x0 => x0.keyCode,
      _1037: x0 => x0.location,
      _1038: x0 => x0.metaKey,
      _1039: x0 => x0.repeat,
      _1040: x0 => x0.shiftKey,
      _1041: x0 => x0.isComposing,
      _1043: x0 => x0.state,
      _1044: (x0,x1) => x0.go(x1),
      _1046: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _1047: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1048: x0 => x0.pathname,
      _1049: x0 => x0.search,
      _1050: x0 => x0.hash,
      _1054: x0 => x0.state,
      _1057: (x0,x1) => x0.createObjectURL(x1),
      _1059: x0 => new Blob(x0),
      _1061: x0 => new MutationObserver(x0),
      _1062: (x0,x1,x2) => x0.observe(x1,x2),
      _1063: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1063(f,arguments.length,x0,x1) }),
      _1066: x0 => x0.attributeName,
      _1067: x0 => x0.type,
      _1068: x0 => x0.matches,
      _1069: x0 => x0.matches,
      _1073: x0 => x0.relatedTarget,
      _1075: x0 => x0.clientX,
      _1076: x0 => x0.clientY,
      _1077: x0 => x0.offsetX,
      _1078: x0 => x0.offsetY,
      _1081: x0 => x0.button,
      _1082: x0 => x0.buttons,
      _1083: x0 => x0.ctrlKey,
      _1087: x0 => x0.pointerId,
      _1088: x0 => x0.pointerType,
      _1089: x0 => x0.pressure,
      _1090: x0 => x0.tiltX,
      _1091: x0 => x0.tiltY,
      _1092: x0 => x0.getCoalescedEvents(),
      _1095: x0 => x0.deltaX,
      _1096: x0 => x0.deltaY,
      _1097: x0 => x0.wheelDeltaX,
      _1098: x0 => x0.wheelDeltaY,
      _1099: x0 => x0.deltaMode,
      _1106: x0 => x0.changedTouches,
      _1109: x0 => x0.clientX,
      _1110: x0 => x0.clientY,
      _1113: x0 => x0.data,
      _1116: (x0,x1) => { x0.disabled = x1 },
      _1118: (x0,x1) => { x0.type = x1 },
      _1119: (x0,x1) => { x0.max = x1 },
      _1120: (x0,x1) => { x0.min = x1 },
      _1121: x0 => x0.value,
      _1122: (x0,x1) => { x0.value = x1 },
      _1123: x0 => x0.disabled,
      _1124: (x0,x1) => { x0.disabled = x1 },
      _1126: (x0,x1) => { x0.placeholder = x1 },
      _1128: (x0,x1) => { x0.name = x1 },
      _1130: (x0,x1) => { x0.autocomplete = x1 },
      _1131: x0 => x0.selectionDirection,
      _1132: x0 => x0.selectionStart,
      _1134: x0 => x0.selectionEnd,
      _1137: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1138: (x0,x1) => x0.add(x1),
      _1141: (x0,x1) => { x0.noValidate = x1 },
      _1142: (x0,x1) => { x0.method = x1 },
      _1143: (x0,x1) => { x0.action = x1 },
      _1169: x0 => x0.orientation,
      _1170: x0 => x0.width,
      _1171: x0 => x0.height,
      _1172: (x0,x1) => x0.lock(x1),
      _1191: x0 => new ResizeObserver(x0),
      _1194: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1194(f,arguments.length,x0,x1) }),
      _1202: x0 => x0.length,
      _1203: x0 => x0.iterator,
      _1204: x0 => x0.Segmenter,
      _1205: x0 => x0.v8BreakIterator,
      _1206: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1209: x0 => x0.language,
      _1210: x0 => x0.script,
      _1211: x0 => x0.region,
      _1229: x0 => x0.done,
      _1230: x0 => x0.value,
      _1231: x0 => x0.index,
      _1235: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1236: (x0,x1) => x0.adoptText(x1),
      _1237: x0 => x0.first(),
      _1238: x0 => x0.next(),
      _1239: x0 => x0.current(),
      _1253: x0 => x0.hostElement,
      _1254: x0 => x0.viewConstraints,
      _1257: x0 => x0.maxHeight,
      _1258: x0 => x0.maxWidth,
      _1259: x0 => x0.minHeight,
      _1260: x0 => x0.minWidth,
      _1261: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1261(f,arguments.length,x0) }),
      _1262: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1262(f,arguments.length,x0) }),
      _1263: (x0,x1) => ({addView: x0,removeView: x1}),
      _1266: x0 => x0.loader,
      _1267: () => globalThis._flutter,
      _1268: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1269: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1269(f,arguments.length,x0) }),
      _1270: f => finalizeWrapper(f, function() { return dartInstance.exports._1270(f,arguments.length) }),
      _1271: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1274: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1274(f,arguments.length,x0) }),
      _1275: x0 => ({runApp: x0}),
      _1277: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1277(f,arguments.length,x0,x1) }),
      _1278: x0 => x0.length,
      _1279: () => globalThis.window.ImageDecoder,
      _1280: x0 => x0.tracks,
      _1282: x0 => x0.completed,
      _1284: x0 => x0.image,
      _1290: x0 => x0.displayWidth,
      _1291: x0 => x0.displayHeight,
      _1292: x0 => x0.duration,
      _1295: x0 => x0.ready,
      _1296: x0 => x0.selectedTrack,
      _1297: x0 => x0.repetitionCount,
      _1298: x0 => x0.frameCount,
      _1341: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1341(f,arguments.length,x0) }),
      _1342: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1343: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1344: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _1345: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1345(f,arguments.length,x0) }),
      _1346: () => globalThis.initializeGA(),
      _1348: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33) => ({screen: x0,event_category: x1,event_label: x2,send_to: x3,value: x4,non_interaction: x5,user_app: x6,user_build: x7,user_platform: x8,devtools_platform: x9,devtools_chrome: x10,devtools_version: x11,ide_launched: x12,flutter_client_id: x13,is_external_build: x14,is_embedded: x15,g3_username: x16,ide_launched_feature: x17,is_wasm: x18,ui_duration_micros: x19,raster_duration_micros: x20,shader_compilation_duration_micros: x21,cpu_sample_count: x22,cpu_stack_depth: x23,trace_event_count: x24,heap_diff_objects_before: x25,heap_diff_objects_after: x26,heap_objects_total: x27,root_set_count: x28,row_count: x29,inspector_tree_controller_id: x30,android_app_id: x31,ios_bundle_id: x32,is_v2_inspector: x33}),
      _1349: x0 => x0.screen,
      _1350: x0 => x0.user_app,
      _1351: x0 => x0.user_build,
      _1352: x0 => x0.user_platform,
      _1353: x0 => x0.devtools_platform,
      _1354: x0 => x0.devtools_chrome,
      _1355: x0 => x0.devtools_version,
      _1356: x0 => x0.ide_launched,
      _1358: x0 => x0.is_external_build,
      _1359: x0 => x0.is_embedded,
      _1360: x0 => x0.g3_username,
      _1361: x0 => x0.ide_launched_feature,
      _1362: x0 => x0.is_wasm,
      _1363: x0 => x0.ui_duration_micros,
      _1364: x0 => x0.raster_duration_micros,
      _1365: x0 => x0.shader_compilation_duration_micros,
      _1366: x0 => x0.cpu_sample_count,
      _1367: x0 => x0.cpu_stack_depth,
      _1368: x0 => x0.trace_event_count,
      _1369: x0 => x0.heap_diff_objects_before,
      _1370: x0 => x0.heap_diff_objects_after,
      _1371: x0 => x0.heap_objects_total,
      _1372: x0 => x0.root_set_count,
      _1373: x0 => x0.row_count,
      _1374: x0 => x0.inspector_tree_controller_id,
      _1375: x0 => x0.android_app_id,
      _1376: x0 => x0.ios_bundle_id,
      _1377: x0 => x0.is_v2_inspector,
      _1379: (x0,x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29) => ({description: x0,fatal: x1,user_app: x2,user_build: x3,user_platform: x4,devtools_platform: x5,devtools_chrome: x6,devtools_version: x7,ide_launched: x8,flutter_client_id: x9,is_external_build: x10,is_embedded: x11,g3_username: x12,ide_launched_feature: x13,is_wasm: x14,ui_duration_micros: x15,raster_duration_micros: x16,shader_compilation_duration_micros: x17,cpu_sample_count: x18,cpu_stack_depth: x19,trace_event_count: x20,heap_diff_objects_before: x21,heap_diff_objects_after: x22,heap_objects_total: x23,root_set_count: x24,row_count: x25,inspector_tree_controller_id: x26,android_app_id: x27,ios_bundle_id: x28,is_v2_inspector: x29}),
      _1380: x0 => x0.user_app,
      _1381: x0 => x0.user_build,
      _1382: x0 => x0.user_platform,
      _1383: x0 => x0.devtools_platform,
      _1384: x0 => x0.devtools_chrome,
      _1385: x0 => x0.devtools_version,
      _1386: x0 => x0.ide_launched,
      _1388: x0 => x0.is_external_build,
      _1389: x0 => x0.is_embedded,
      _1390: x0 => x0.g3_username,
      _1391: x0 => x0.ide_launched_feature,
      _1392: x0 => x0.is_wasm,
      _1408: () => globalThis.getDevToolsPropertyID(),
      _1409: () => globalThis.hookupListenerForGA(),
      _1410: (x0,x1,x2) => globalThis.gtag(x0,x1,x2),
      _1412: x0 => x0.event_category,
      _1413: x0 => x0.event_label,
      _1415: x0 => x0.value,
      _1416: x0 => x0.non_interaction,
      _1419: x0 => x0.description,
      _1420: x0 => x0.fatal,
      _1421: (x0,x1) => x0.getItem(x1),
      _1422: (x0,x1,x2) => x0.setItem(x1,x2),
      _1423: (x0,x1) => x0.querySelectorAll(x1),
      _1424: (x0,x1) => x0.removeChild(x1),
      _1425: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1425(f,arguments.length,x0) }),
      _1426: (x0,x1) => x0.forEach(x1),
      _1427: x0 => x0.preventDefault(),
      _1428: (x0,x1) => x0.execCommand(x1),
      _1429: (x0,x1) => x0.createElement(x1),
      _1430: x0 => new Blob(x0),
      _1431: x0 => globalThis.URL.createObjectURL(x0),
      _1432: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _1433: (x0,x1) => x0.append(x1),
      _1434: x0 => x0.click(),
      _1435: x0 => x0.remove(),
      _1436: (x0,x1) => x0.item(x1),
      _1437: () => new FileReader(),
      _1438: (x0,x1) => x0.readAsText(x1),
      _1439: x0 => x0.createRange(),
      _1440: (x0,x1) => x0.selectNode(x1),
      _1441: x0 => x0.getSelection(),
      _1442: x0 => x0.removeAllRanges(),
      _1443: (x0,x1) => x0.addRange(x1),
      _1444: (x0,x1) => x0.createElement(x1),
      _1445: (x0,x1) => x0.append(x1),
      _1446: (x0,x1,x2) => x0.insertRule(x1,x2),
      _1447: (x0,x1) => x0.add(x1),
      _1448: x0 => x0.preventDefault(),
      _1449: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1449(f,arguments.length,x0) }),
      _1450: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _1451: () => globalThis.window.navigator.userAgent,
      _1452: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1452(f,arguments.length,x0) }),
      _1453: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1454: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1459: (x0,x1) => x0.closest(x1),
      _1460: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1461: x0 => x0.decode(),
      _1462: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1463: (x0,x1,x2) => x0.setRequestHeader(x1,x2),
      _1464: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1464(f,arguments.length,x0) }),
      _1465: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1465(f,arguments.length,x0) }),
      _1466: x0 => x0.send(),
      _1467: () => new XMLHttpRequest(),
      _1468: (x0,x1) => x0.querySelector(x1),
      _1469: (x0,x1) => x0.appendChild(x1),
      _1470: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1470(f,arguments.length,x0) }),
      _1471: Date.now,
      _1473: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1474: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1475: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1476: () => typeof dartUseDateNowForTicks !== "undefined",
      _1477: () => 1000 * performance.now(),
      _1478: () => Date.now(),
      _1479: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1480: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1481: () => new WeakMap(),
      _1482: (map, o) => map.get(o),
      _1483: (map, o, v) => map.set(o, v),
      _1484: x0 => new WeakRef(x0),
      _1485: x0 => x0.deref(),
      _1492: () => globalThis.WeakRef,
      _1496: s => JSON.stringify(s),
      _1497: s => printToConsole(s),
      _1498: (o, p, r) => o.replaceAll(p, () => r),
      _1499: (o, p, r) => o.replace(p, () => r),
      _1500: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1501: s => s.toUpperCase(),
      _1502: s => s.trim(),
      _1503: s => s.trimLeft(),
      _1504: s => s.trimRight(),
      _1505: (string, times) => string.repeat(times),
      _1506: Function.prototype.call.bind(String.prototype.indexOf),
      _1507: (s, p, i) => s.lastIndexOf(p, i),
      _1508: (string, token) => string.split(token),
      _1509: Object.is,
      _1510: o => o instanceof Array,
      _1511: (a, i) => a.push(i),
      _1512: (a, i) => a.splice(i, 1)[0],
      _1514: (a, l) => a.length = l,
      _1515: a => a.pop(),
      _1516: (a, i) => a.splice(i, 1),
      _1517: (a, s) => a.join(s),
      _1518: (a, s, e) => a.slice(s, e),
      _1519: (a, s, e) => a.splice(s, e),
      _1520: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1521: a => a.length,
      _1522: (a, l) => a.length = l,
      _1523: (a, i) => a[i],
      _1524: (a, i, v) => a[i] = v,
      _1526: o => {
        if (o instanceof ArrayBuffer) return 0;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 1;
        }
        return 2;
      },
      _1527: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1529: o => o instanceof Uint8Array,
      _1530: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1531: o => o instanceof Int8Array,
      _1532: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1533: o => o instanceof Uint8ClampedArray,
      _1534: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1535: o => o instanceof Uint16Array,
      _1536: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1537: o => o instanceof Int16Array,
      _1538: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1539: o => o instanceof Uint32Array,
      _1540: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1541: o => o instanceof Int32Array,
      _1542: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1544: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1545: o => o instanceof Float32Array,
      _1546: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1547: o => o instanceof Float64Array,
      _1548: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1549: (t, s) => t.set(s),
      _1551: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1552: o => o.byteLength,
      _1553: o => o.buffer,
      _1554: o => o.byteOffset,
      _1555: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1556: (b, o) => new DataView(b, o),
      _1557: (b, o, l) => new DataView(b, o, l),
      _1558: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1559: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1560: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1561: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1562: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1563: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1564: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1565: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1566: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1567: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1568: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1569: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1572: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1573: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1574: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1575: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1576: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1577: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1590: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1591: (handle) => clearTimeout(handle),
      _1592: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1593: (handle) => clearInterval(handle),
      _1594: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1595: () => Date.now(),
      _1596: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _1597: (x0,x1) => x0.exec(x1),
      _1598: (x0,x1) => x0.test(x1),
      _1599: x0 => x0.pop(),
      _1601: o => o === undefined,
      _1603: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _1605: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _1606: o => o instanceof RegExp,
      _1607: (l, r) => l === r,
      _1608: o => o,
      _1609: o => o,
      _1610: o => o,
      _1611: b => !!b,
      _1612: o => o.length,
      _1614: (o, i) => o[i],
      _1615: f => f.dartFunction,
      _1616: () => ({}),
      _1617: () => [],
      _1619: () => globalThis,
      _1620: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _1621: (o, p) => p in o,
      _1622: (o, p) => o[p],
      _1623: (o, p, v) => o[p] = v,
      _1624: (o, m, a) => o[m].apply(o, a),
      _1626: o => String(o),
      _1627: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _1628: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1628(f,arguments.length,x0) }),
      _1629: f => finalizeWrapper(f, function(x0,x1) { return dartInstance.exports._1629(f,arguments.length,x0,x1) }),
      _1630: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _1631: o => [o],
      _1632: (o0, o1) => [o0, o1],
      _1633: (o0, o1, o2) => [o0, o1, o2],
      _1634: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _1635: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1636: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1637: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI16ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1638: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI16ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1639: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1640: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1641: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1642: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1643: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1644: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1645: x0 => new ArrayBuffer(x0),
      _1646: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _1647: x0 => x0.input,
      _1648: x0 => x0.index,
      _1649: x0 => x0.groups,
      _1650: x0 => x0.flags,
      _1651: x0 => x0.multiline,
      _1652: x0 => x0.ignoreCase,
      _1653: x0 => x0.unicode,
      _1654: x0 => x0.dotAll,
      _1655: (x0,x1) => { x0.lastIndex = x1 },
      _1656: (o, p) => p in o,
      _1657: (o, p) => o[p],
      _1660: () => new XMLHttpRequest(),
      _1661: (x0,x1,x2,x3) => x0.open(x1,x2,x3),
      _1665: x0 => x0.send(),
      _1667: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1667(f,arguments.length,x0) }),
      _1668: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1668(f,arguments.length,x0) }),
      _1673: (x0,x1) => new WebSocket(x0,x1),
      _1674: (x0,x1) => x0.send(x1),
      _1675: (x0,x1,x2) => x0.close(x1,x2),
      _1677: x0 => x0.close(),
      _1681: (x0,x1) => x0.readAsArrayBuffer(x1),
      _1683: x0 => ({body: x0}),
      _1684: (x0,x1) => new Notification(x0,x1),
      _1685: () => globalThis.Notification.requestPermission(),
      _1686: x0 => x0.close(),
      _1687: x0 => x0.reload(),
      _1688: () => new AbortController(),
      _1689: x0 => x0.abort(),
      _1690: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _1691: (x0,x1) => globalThis.fetch(x0,x1),
      _1692: (x0,x1) => x0.get(x1),
      _1693: f => finalizeWrapper(f, function(x0,x1,x2) { return dartInstance.exports._1693(f,arguments.length,x0,x1,x2) }),
      _1694: (x0,x1) => x0.forEach(x1),
      _1695: x0 => x0.getReader(),
      _1696: x0 => x0.read(),
      _1697: x0 => x0.cancel(),
      _1698: x0 => ({withCredentials: x0}),
      _1699: (x0,x1) => new EventSource(x0,x1),
      _1700: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1700(f,arguments.length,x0) }),
      _1701: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1701(f,arguments.length,x0) }),
      _1702: x0 => x0.close(),
      _1703: (x0,x1,x2) => ({method: x0,body: x1,credentials: x2}),
      _1704: (x0,x1,x2) => x0.fetch(x1,x2),
      _1705: (x0,x1) => x0.groupCollapsed(x1),
      _1706: (x0,x1) => x0.log(x1),
      _1707: x0 => x0.groupEnd(),
      _1708: (x0,x1) => x0.warn(x1),
      _1709: (x0,x1) => x0.error(x1),
      _1710: x0 => x0.measureUserAgentSpecificMemory(),
      _1711: x0 => x0.bytes,
      _1721: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1721(f,arguments.length,x0) }),
      _1722: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._1722(f,arguments.length,x0) }),
      _1723: x0 => x0.blur(),
      _1724: (x0,x1) => x0.replace(x1),
      _1725: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1726: x0 => x0.random(),
      _1729: () => globalThis.Math,
      _1739: Function.prototype.call.bind(Number.prototype.toString),
      _1740: Function.prototype.call.bind(BigInt.prototype.toString),
      _1741: Function.prototype.call.bind(Number.prototype.toString),
      _1742: (d, digits) => d.toFixed(digits),
      _1745: (d, precision) => d.toPrecision(precision),
      _1746: () => globalThis.document,
      _1747: () => globalThis.window,
      _1752: (x0,x1) => { x0.height = x1 },
      _1754: (x0,x1) => { x0.width = x1 },
      _1757: x0 => x0.head,
      _1758: x0 => x0.classList,
      _1762: (x0,x1) => { x0.innerText = x1 },
      _1763: x0 => x0.style,
      _1765: x0 => x0.sheet,
      _1766: x0 => x0.src,
      _1767: (x0,x1) => { x0.src = x1 },
      _1768: x0 => x0.naturalWidth,
      _1769: x0 => x0.naturalHeight,
      _1776: x0 => x0.offsetX,
      _1777: x0 => x0.offsetY,
      _1778: x0 => x0.button,
      _1785: x0 => x0.status,
      _1786: (x0,x1) => { x0.responseType = x1 },
      _1788: x0 => x0.response,
      _1837: (x0,x1) => { x0.responseType = x1 },
      _1838: x0 => x0.response,
      _1913: x0 => x0.style,
      _2390: (x0,x1) => { x0.src = x1 },
      _2397: (x0,x1) => { x0.allow = x1 },
      _2409: x0 => x0.contentWindow,
      _2842: (x0,x1) => { x0.accept = x1 },
      _2856: x0 => x0.files,
      _2882: (x0,x1) => { x0.multiple = x1 },
      _2900: (x0,x1) => { x0.type = x1 },
      _3598: (x0,x1) => { x0.dropEffect = x1 },
      _3603: x0 => x0.files,
      _3615: x0 => x0.dataTransfer,
      _3619: () => globalThis.window,
      _3661: x0 => x0.location,
      _3662: x0 => x0.history,
      _3678: x0 => x0.parent,
      _3680: x0 => x0.navigator,
      _3935: x0 => x0.isSecureContext,
      _3936: x0 => x0.crossOriginIsolated,
      _3939: x0 => x0.performance,
      _3944: x0 => x0.localStorage,
      _3952: x0 => x0.origin,
      _3961: x0 => x0.pathname,
      _3975: x0 => x0.state,
      _4000: x0 => x0.message,
      _4062: x0 => x0.appVersion,
      _4063: x0 => x0.platform,
      _4066: x0 => x0.userAgent,
      _4067: x0 => x0.vendor,
      _4117: x0 => x0.data,
      _4118: x0 => x0.origin,
      _4490: x0 => x0.readyState,
      _4499: x0 => x0.protocol,
      _4503: (x0,x1) => { x0.binaryType = x1 },
      _4506: x0 => x0.code,
      _4507: x0 => x0.reason,
      _6174: x0 => x0.type,
      _6215: x0 => x0.signal,
      _6273: x0 => x0.parentNode,
      _6287: () => globalThis.document,
      _6369: x0 => x0.body,
      _6412: x0 => x0.activeElement,
      _7046: x0 => x0.offsetX,
      _7047: x0 => x0.offsetY,
      _7132: x0 => x0.key,
      _7133: x0 => x0.code,
      _7134: x0 => x0.location,
      _7135: x0 => x0.ctrlKey,
      _7136: x0 => x0.shiftKey,
      _7137: x0 => x0.altKey,
      _7138: x0 => x0.metaKey,
      _7139: x0 => x0.repeat,
      _7140: x0 => x0.isComposing,
      _7142: x0 => x0.keyCode,
      _8046: x0 => x0.value,
      _8048: x0 => x0.done,
      _8228: x0 => x0.size,
      _8229: x0 => x0.type,
      _8236: x0 => x0.name,
      _8237: x0 => x0.lastModified,
      _8242: x0 => x0.length,
      _8248: x0 => x0.result,
      _8743: x0 => x0.url,
      _8745: x0 => x0.status,
      _8747: x0 => x0.statusText,
      _8748: x0 => x0.headers,
      _8749: x0 => x0.body,
      _10831: (x0,x1) => { x0.backgroundColor = x1 },
      _10877: (x0,x1) => { x0.border = x1 },
      _11155: (x0,x1) => { x0.display = x1 },
      _11319: (x0,x1) => { x0.height = x1 },
      _12009: (x0,x1) => { x0.width = x1 },
      _12377: x0 => x0.name,
      _13096: () => globalThis.console,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      S: new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}

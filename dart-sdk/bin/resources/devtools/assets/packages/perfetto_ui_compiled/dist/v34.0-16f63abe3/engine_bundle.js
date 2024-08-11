var engine = (function () {
'use strict';

function getDefaultExportFromCjs (x) {
	return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
}

function getAugmentedNamespace(n) {
  if (n.__esModule) return n;
  var f = n.default;
	if (typeof f == "function") {
		var a = function a () {
			if (this instanceof a) {
				var args = [null];
				args.push.apply(args, arguments);
				var Ctor = Function.bind.apply(f, args);
				return new Ctor();
			}
			return f.apply(this, arguments);
		};
		a.prototype = f.prototype;
  } else a = {};
  Object.defineProperty(a, '__esModule', {value: true});
	Object.keys(n).forEach(function (k) {
		var d = Object.getOwnPropertyDescriptor(n, k);
		Object.defineProperty(a, k, d.get ? d : {
			enumerable: true,
			get: function () {
				return n[k];
			}
		});
	});
	return a;
}

var engine = {};

var logging = {};

var perfetto_version = {};

var hasRequiredPerfetto_version;

function requirePerfetto_version () {
	if (hasRequiredPerfetto_version) return perfetto_version;
	hasRequiredPerfetto_version = 1;
	Object.defineProperty(perfetto_version, "__esModule", { value: true });
	perfetto_version.SCM_REVISION = perfetto_version.VERSION = void 0;
	perfetto_version.VERSION = "v34.0-16f63abe3";
	perfetto_version.SCM_REVISION = "16f63abe33753ce31d9b29e3a4281a5435773fc7";
	
	return perfetto_version;
}

var hasRequiredLogging;

function requireLogging () {
	if (hasRequiredLogging) return logging;
	hasRequiredLogging = 1;
	// Copyright (C) 2018 The Android Open Source Project
	//
	// Licensed under the Apache License, Version 2.0 (the "License");
	// you may not use this file except in compliance with the License.
	// You may obtain a copy of the License at
	//
	//      http://www.apache.org/licenses/LICENSE-2.0
	//
	// Unless required by applicable law or agreed to in writing, software
	// distributed under the License is distributed on an "AS IS" BASIS,
	// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	// See the License for the specific language governing permissions and
	// limitations under the License.
	Object.defineProperty(logging, "__esModule", { value: true });
	logging.assertUnreachable = logging.reportError = logging.setErrorHandler = logging.assertFalse = logging.assertTrue = logging.assertExists = void 0;
	const perfetto_version_1 = requirePerfetto_version();
	let errorHandler = (_) => { };
	function assertExists(value) {
	    if (value === null || value === undefined) {
	        throw new Error('Value doesn\'t exist');
	    }
	    return value;
	}
	logging.assertExists = assertExists;
	function assertTrue(value, optMsg) {
	    if (!value) {
	        throw new Error(optMsg ?? 'Failed assertion');
	    }
	}
	logging.assertTrue = assertTrue;
	function assertFalse(value, optMsg) {
	    assertTrue(!value, optMsg);
	}
	logging.assertFalse = assertFalse;
	function setErrorHandler(handler) {
	    errorHandler = handler;
	}
	logging.setErrorHandler = setErrorHandler;
	function reportError(err) {
	    let errLog = '';
	    let errorObj = undefined;
	    if (err instanceof ErrorEvent) {
	        errLog = err.message;
	        errorObj = err.error;
	    }
	    else if (err instanceof PromiseRejectionEvent) {
	        errLog = `${err.reason}`;
	        errorObj = err.reason;
	    }
	    else {
	        errLog = `${err}`;
	    }
	    if (errorObj !== undefined && errorObj !== null) {
	        const errStack = errorObj.stack;
	        errLog += '\n';
	        errLog += errStack !== undefined ? errStack : JSON.stringify(errorObj);
	    }
	    errLog += '\n\n';
	    errLog += `${perfetto_version_1.VERSION} ${perfetto_version_1.SCM_REVISION}\n`;
	    errLog += `UA: ${navigator.userAgent}\n`;
	    console.error(errLog, err);
	    errorHandler(errLog);
	}
	logging.reportError = reportError;
	// This function serves two purposes.
	// 1) A runtime check - if we are ever called, we throw an exception.
	// This is useful for checking that code we suspect should never be reached is
	// actually never reached.
	// 2) A compile time check where typescript asserts that the value passed can be
	// cast to the "never" type.
	// This is useful for ensuring we exhastively check union types.
	function assertUnreachable(_x) {
	    throw new Error('This code should not be reachable');
	}
	logging.assertUnreachable = assertUnreachable;
	
	return logging;
}

var wasm_bridge = {};

/******************************************************************************
Copyright (c) Microsoft Corporation.

Permission to use, copy, modify, and/or distribute this software for any
purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
PERFORMANCE OF THIS SOFTWARE.
***************************************************************************** */
/* global Reflect, Promise */

var extendStatics = function(d, b) {
    extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (Object.prototype.hasOwnProperty.call(b, p)) d[p] = b[p]; };
    return extendStatics(d, b);
};

function __extends(d, b) {
    if (typeof b !== "function" && b !== null)
        throw new TypeError("Class extends value " + String(b) + " is not a constructor or null");
    extendStatics(d, b);
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
}

var __assign = function() {
    __assign = Object.assign || function __assign(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p)) t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};

function __rest(s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
}

function __decorate(decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
}

function __param(paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
}

function __esDecorate(ctor, descriptorIn, decorators, contextIn, initializers, extraInitializers) {
    function accept(f) { if (f !== void 0 && typeof f !== "function") throw new TypeError("Function expected"); return f; }
    var kind = contextIn.kind, key = kind === "getter" ? "get" : kind === "setter" ? "set" : "value";
    var target = !descriptorIn && ctor ? contextIn["static"] ? ctor : ctor.prototype : null;
    var descriptor = descriptorIn || (target ? Object.getOwnPropertyDescriptor(target, contextIn.name) : {});
    var _, done = false;
    for (var i = decorators.length - 1; i >= 0; i--) {
        var context = {};
        for (var p in contextIn) context[p] = p === "access" ? {} : contextIn[p];
        for (var p in contextIn.access) context.access[p] = contextIn.access[p];
        context.addInitializer = function (f) { if (done) throw new TypeError("Cannot add initializers after decoration has completed"); extraInitializers.push(accept(f || null)); };
        var result = (0, decorators[i])(kind === "accessor" ? { get: descriptor.get, set: descriptor.set } : descriptor[key], context);
        if (kind === "accessor") {
            if (result === void 0) continue;
            if (result === null || typeof result !== "object") throw new TypeError("Object expected");
            if (_ = accept(result.get)) descriptor.get = _;
            if (_ = accept(result.set)) descriptor.set = _;
            if (_ = accept(result.init)) initializers.push(_);
        }
        else if (_ = accept(result)) {
            if (kind === "field") initializers.push(_);
            else descriptor[key] = _;
        }
    }
    if (target) Object.defineProperty(target, contextIn.name, descriptor);
    done = true;
}
function __runInitializers(thisArg, initializers, value) {
    var useValue = arguments.length > 2;
    for (var i = 0; i < initializers.length; i++) {
        value = useValue ? initializers[i].call(thisArg, value) : initializers[i].call(thisArg);
    }
    return useValue ? value : void 0;
}
function __propKey(x) {
    return typeof x === "symbol" ? x : "".concat(x);
}
function __setFunctionName(f, name, prefix) {
    if (typeof name === "symbol") name = name.description ? "[".concat(name.description, "]") : "";
    return Object.defineProperty(f, "name", { configurable: true, value: prefix ? "".concat(prefix, " ", name) : name });
}
function __metadata(metadataKey, metadataValue) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(metadataKey, metadataValue);
}

function __awaiter(thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
}

function __generator(thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
}

var __createBinding = Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
        desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
});

function __exportStar(m, o) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(o, p)) __createBinding(o, m, p);
}

function __values(o) {
    var s = typeof Symbol === "function" && Symbol.iterator, m = s && o[s], i = 0;
    if (m) return m.call(o);
    if (o && typeof o.length === "number") return {
        next: function () {
            if (o && i >= o.length) o = void 0;
            return { value: o && o[i++], done: !o };
        }
    };
    throw new TypeError(s ? "Object is not iterable." : "Symbol.iterator is not defined.");
}

function __read(o, n) {
    var m = typeof Symbol === "function" && o[Symbol.iterator];
    if (!m) return o;
    var i = m.call(o), r, ar = [], e;
    try {
        while ((n === void 0 || n-- > 0) && !(r = i.next()).done) ar.push(r.value);
    }
    catch (error) { e = { error: error }; }
    finally {
        try {
            if (r && !r.done && (m = i["return"])) m.call(i);
        }
        finally { if (e) throw e.error; }
    }
    return ar;
}

/** @deprecated */
function __spread() {
    for (var ar = [], i = 0; i < arguments.length; i++)
        ar = ar.concat(__read(arguments[i]));
    return ar;
}

/** @deprecated */
function __spreadArrays() {
    for (var s = 0, i = 0, il = arguments.length; i < il; i++) s += arguments[i].length;
    for (var r = Array(s), k = 0, i = 0; i < il; i++)
        for (var a = arguments[i], j = 0, jl = a.length; j < jl; j++, k++)
            r[k] = a[j];
    return r;
}

function __spreadArray(to, from, pack) {
    if (pack || arguments.length === 2) for (var i = 0, l = from.length, ar; i < l; i++) {
        if (ar || !(i in from)) {
            if (!ar) ar = Array.prototype.slice.call(from, 0, i);
            ar[i] = from[i];
        }
    }
    return to.concat(ar || Array.prototype.slice.call(from));
}

function __await(v) {
    return this instanceof __await ? (this.v = v, this) : new __await(v);
}

function __asyncGenerator(thisArg, _arguments, generator) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var g = generator.apply(thisArg, _arguments || []), i, q = [];
    return i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i;
    function verb(n) { if (g[n]) i[n] = function (v) { return new Promise(function (a, b) { q.push([n, v, a, b]) > 1 || resume(n, v); }); }; }
    function resume(n, v) { try { step(g[n](v)); } catch (e) { settle(q[0][3], e); } }
    function step(r) { r.value instanceof __await ? Promise.resolve(r.value.v).then(fulfill, reject) : settle(q[0][2], r); }
    function fulfill(value) { resume("next", value); }
    function reject(value) { resume("throw", value); }
    function settle(f, v) { if (f(v), q.shift(), q.length) resume(q[0][0], q[0][1]); }
}

function __asyncDelegator(o) {
    var i, p;
    return i = {}, verb("next"), verb("throw", function (e) { throw e; }), verb("return"), i[Symbol.iterator] = function () { return this; }, i;
    function verb(n, f) { i[n] = o[n] ? function (v) { return (p = !p) ? { value: __await(o[n](v)), done: false } : f ? f(v) : v; } : f; }
}

function __asyncValues(o) {
    if (!Symbol.asyncIterator) throw new TypeError("Symbol.asyncIterator is not defined.");
    var m = o[Symbol.asyncIterator], i;
    return m ? m.call(o) : (o = typeof __values === "function" ? __values(o) : o[Symbol.iterator](), i = {}, verb("next"), verb("throw"), verb("return"), i[Symbol.asyncIterator] = function () { return this; }, i);
    function verb(n) { i[n] = o[n] && function (v) { return new Promise(function (resolve, reject) { v = o[n](v), settle(resolve, reject, v.done, v.value); }); }; }
    function settle(resolve, reject, d, v) { Promise.resolve(v).then(function(v) { resolve({ value: v, done: d }); }, reject); }
}

function __makeTemplateObject(cooked, raw) {
    if (Object.defineProperty) { Object.defineProperty(cooked, "raw", { value: raw }); } else { cooked.raw = raw; }
    return cooked;
}
var __setModuleDefault = Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
};

function __importStar(mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
}

function __importDefault(mod) {
    return (mod && mod.__esModule) ? mod : { default: mod };
}

function __classPrivateFieldGet(receiver, state, kind, f) {
    if (kind === "a" && !f) throw new TypeError("Private accessor was defined without a getter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver)) throw new TypeError("Cannot read private member from an object whose class did not declare it");
    return kind === "m" ? f : kind === "a" ? f.call(receiver) : f ? f.value : state.get(receiver);
}

function __classPrivateFieldSet(receiver, state, value, kind, f) {
    if (kind === "m") throw new TypeError("Private method is not writable");
    if (kind === "a" && !f) throw new TypeError("Private accessor was defined without a setter");
    if (typeof state === "function" ? receiver !== state || !f : !state.has(receiver)) throw new TypeError("Cannot write private member to an object whose class did not declare it");
    return (kind === "a" ? f.call(receiver, value) : f ? f.value = value : state.set(receiver, value)), value;
}

function __classPrivateFieldIn(state, receiver) {
    if (receiver === null || (typeof receiver !== "object" && typeof receiver !== "function")) throw new TypeError("Cannot use 'in' operator on non-object");
    return typeof state === "function" ? receiver === state : state.has(receiver);
}

var tslib_es6 = /*#__PURE__*/Object.freeze({
__proto__: null,
__extends: __extends,
get __assign () { return __assign; },
__rest: __rest,
__decorate: __decorate,
__param: __param,
__esDecorate: __esDecorate,
__runInitializers: __runInitializers,
__propKey: __propKey,
__setFunctionName: __setFunctionName,
__metadata: __metadata,
__awaiter: __awaiter,
__generator: __generator,
__createBinding: __createBinding,
__exportStar: __exportStar,
__values: __values,
__read: __read,
__spread: __spread,
__spreadArrays: __spreadArrays,
__spreadArray: __spreadArray,
__await: __await,
__asyncGenerator: __asyncGenerator,
__asyncDelegator: __asyncDelegator,
__asyncValues: __asyncValues,
__makeTemplateObject: __makeTemplateObject,
__importStar: __importStar,
__importDefault: __importDefault,
__classPrivateFieldGet: __classPrivateFieldGet,
__classPrivateFieldSet: __classPrivateFieldSet,
__classPrivateFieldIn: __classPrivateFieldIn
});

var require$$0 = /*@__PURE__*/getAugmentedNamespace(tslib_es6);

var deferred = {};

var hasRequiredDeferred;

function requireDeferred () {
	if (hasRequiredDeferred) return deferred;
	hasRequiredDeferred = 1;
	// Copyright (C) 2018 The Android Open Source Project
	//
	// Licensed under the Apache License, Version 2.0 (the "License");
	// you may not use this file except in compliance with the License.
	// You may obtain a copy of the License at
	//
	//      http://www.apache.org/licenses/LICENSE-2.0
	//
	// Unless required by applicable law or agreed to in writing, software
	// distributed under the License is distributed on an "AS IS" BASIS,
	// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	// See the License for the specific language governing permissions and
	// limitations under the License.
	Object.defineProperty(deferred, "__esModule", { value: true });
	deferred.defer = void 0;
	// Create a promise with exposed resolve and reject callbacks.
	function defer() {
	    let resolve = null;
	    let reject = null;
	    const p = new Promise((res, rej) => [resolve, reject] = [res, rej]);
	    return Object.assign(p, { resolve, reject });
	}
	deferred.defer = defer;
	
	return deferred;
}

var trace_processorExports = {};
var trace_processor = {
  get exports(){ return trace_processorExports; },
  set exports(v){ trace_processorExports = v; },
};

var hasRequiredTrace_processor;

function requireTrace_processor () {
	if (hasRequiredTrace_processor) return trace_processorExports;
	hasRequiredTrace_processor = 1;
	(function (module, exports) {
		var trace_processor_wasm = (function() {
		  var _scriptDir = typeof document !== 'undefined' && document.currentScript ? document.currentScript.src : undefined;
		  
		  return (
		function(trace_processor_wasm) {
		  trace_processor_wasm = trace_processor_wasm || {};

		var Module = typeof trace_processor_wasm !== "undefined" ? trace_processor_wasm : {};

		var readyPromiseResolve, readyPromiseReject;

		Module["ready"] = new Promise(function(resolve, reject) {
		 readyPromiseResolve = resolve;
		 readyPromiseReject = reject;
		});

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_main")) {
		 Object.defineProperty(Module["ready"], "_main", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _main on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_main", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _main on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_emscripten_stack_get_end")) {
		 Object.defineProperty(Module["ready"], "_emscripten_stack_get_end", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _emscripten_stack_get_end on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_emscripten_stack_get_end", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _emscripten_stack_get_end on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_emscripten_stack_get_free")) {
		 Object.defineProperty(Module["ready"], "_emscripten_stack_get_free", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _emscripten_stack_get_free on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_emscripten_stack_get_free", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _emscripten_stack_get_free on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_emscripten_stack_init")) {
		 Object.defineProperty(Module["ready"], "_emscripten_stack_init", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _emscripten_stack_init on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_emscripten_stack_init", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _emscripten_stack_init on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_stackSave")) {
		 Object.defineProperty(Module["ready"], "_stackSave", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _stackSave on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_stackSave", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _stackSave on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_stackRestore")) {
		 Object.defineProperty(Module["ready"], "_stackRestore", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _stackRestore on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_stackRestore", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _stackRestore on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_stackAlloc")) {
		 Object.defineProperty(Module["ready"], "_stackAlloc", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _stackAlloc on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_stackAlloc", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _stackAlloc on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "___wasm_call_ctors")) {
		 Object.defineProperty(Module["ready"], "___wasm_call_ctors", {
		  configurable: true,
		  get: function() {
		   abort("You are getting ___wasm_call_ctors on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "___wasm_call_ctors", {
		  configurable: true,
		  set: function() {
		   abort("You are setting ___wasm_call_ctors on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_fflush")) {
		 Object.defineProperty(Module["ready"], "_fflush", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _fflush on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_fflush", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _fflush on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "___errno_location")) {
		 Object.defineProperty(Module["ready"], "___errno_location", {
		  configurable: true,
		  get: function() {
		   abort("You are getting ___errno_location on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "___errno_location", {
		  configurable: true,
		  set: function() {
		   abort("You are setting ___errno_location on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_malloc")) {
		 Object.defineProperty(Module["ready"], "_malloc", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _malloc on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_malloc", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _malloc on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_free")) {
		 Object.defineProperty(Module["ready"], "_free", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _free on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_free", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _free on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_memalign")) {
		 Object.defineProperty(Module["ready"], "_memalign", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _memalign on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_memalign", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _memalign on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_memset")) {
		 Object.defineProperty(Module["ready"], "_memset", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _memset on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_memset", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _memset on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "__get_tzname")) {
		 Object.defineProperty(Module["ready"], "__get_tzname", {
		  configurable: true,
		  get: function() {
		   abort("You are getting __get_tzname on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "__get_tzname", {
		  configurable: true,
		  set: function() {
		   abort("You are setting __get_tzname on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "__get_daylight")) {
		 Object.defineProperty(Module["ready"], "__get_daylight", {
		  configurable: true,
		  get: function() {
		   abort("You are getting __get_daylight on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "__get_daylight", {
		  configurable: true,
		  set: function() {
		   abort("You are setting __get_daylight on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "__get_timezone")) {
		 Object.defineProperty(Module["ready"], "__get_timezone", {
		  configurable: true,
		  get: function() {
		   abort("You are getting __get_timezone on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "__get_timezone", {
		  configurable: true,
		  set: function() {
		   abort("You are setting __get_timezone on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_emscripten_main_thread_process_queued_calls")) {
		 Object.defineProperty(Module["ready"], "_emscripten_main_thread_process_queued_calls", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _emscripten_main_thread_process_queued_calls on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_emscripten_main_thread_process_queued_calls", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _emscripten_main_thread_process_queued_calls on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "_usleep")) {
		 Object.defineProperty(Module["ready"], "_usleep", {
		  configurable: true,
		  get: function() {
		   abort("You are getting _usleep on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "_usleep", {
		  configurable: true,
		  set: function() {
		   abort("You are setting _usleep on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		if (!Object.getOwnPropertyDescriptor(Module["ready"], "onRuntimeInitialized")) {
		 Object.defineProperty(Module["ready"], "onRuntimeInitialized", {
		  configurable: true,
		  get: function() {
		   abort("You are getting onRuntimeInitialized on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		 Object.defineProperty(Module["ready"], "onRuntimeInitialized", {
		  configurable: true,
		  set: function() {
		   abort("You are setting onRuntimeInitialized on the Promise object, instead of the instance. Use .then() to get called back with the instance, see the MODULARIZE docs in src/settings.js");
		  }
		 });
		}

		var moduleOverrides = {};

		var key;

		for (key in Module) {
		 if (Module.hasOwnProperty(key)) {
		  moduleOverrides[key] = Module[key];
		 }
		}

		var arguments_ = [];

		var thisProgram = "./this.program";

		var quit_ = function(status, toThrow) {
		 throw toThrow;
		};

		var ENVIRONMENT_IS_WEB = false;

		var ENVIRONMENT_IS_WORKER = false;

		ENVIRONMENT_IS_WEB = typeof window === "object";

		ENVIRONMENT_IS_WORKER = typeof importScripts === "function";

		typeof process === "object" && typeof process.versions === "object" && typeof process.versions.node === "string";

		if (Module["ENVIRONMENT"]) {
		 throw new Error("Module.ENVIRONMENT has been deprecated. To force the environment, use the ENVIRONMENT compile-time option (for example, -s ENVIRONMENT=web or -s ENVIRONMENT=node)");
		}

		var scriptDirectory = "";

		function locateFile(path) {
		 if (Module["locateFile"]) {
		  return Module["locateFile"](path, scriptDirectory);
		 }
		 return scriptDirectory + path;
		}

		var read_, readBinary;

		if (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER) {
		 if (ENVIRONMENT_IS_WORKER) {
		  scriptDirectory = self.location.href;
		 } else if (typeof document !== "undefined" && document.currentScript) {
		  scriptDirectory = document.currentScript.src;
		 }
		 if (_scriptDir) {
		  scriptDirectory = _scriptDir;
		 }
		 if (scriptDirectory.indexOf("blob:") !== 0) {
		  scriptDirectory = scriptDirectory.substr(0, scriptDirectory.lastIndexOf("/") + 1);
		 } else {
		  scriptDirectory = "";
		 }
		 if (!(typeof window === "object" || typeof importScripts === "function")) throw new Error("not compiled for this environment (did you build to HTML and try to run it not on the web, or set ENVIRONMENT to something - like node - and run it someplace else - like on the web?)");
		 {
		  read_ = function(url) {
		   var xhr = new XMLHttpRequest();
		   xhr.open("GET", url, false);
		   xhr.send(null);
		   return xhr.responseText;
		  };
		  if (ENVIRONMENT_IS_WORKER) {
		   readBinary = function(url) {
		    var xhr = new XMLHttpRequest();
		    xhr.open("GET", url, false);
		    xhr.responseType = "arraybuffer";
		    xhr.send(null);
		    return new Uint8Array(xhr.response);
		   };
		  }
		 }
		} else {
		 throw new Error("environment detection error");
		}

		var out = Module["print"] || console.log.bind(console);

		var err = Module["printErr"] || console.warn.bind(console);

		for (key in moduleOverrides) {
		 if (moduleOverrides.hasOwnProperty(key)) {
		  Module[key] = moduleOverrides[key];
		 }
		}

		moduleOverrides = null;

		if (Module["arguments"]) arguments_ = Module["arguments"];

		if (!Object.getOwnPropertyDescriptor(Module, "arguments")) Object.defineProperty(Module, "arguments", {
		 configurable: true,
		 get: function() {
		  abort("Module.arguments has been replaced with plain arguments_ (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		if (Module["thisProgram"]) thisProgram = Module["thisProgram"];

		if (!Object.getOwnPropertyDescriptor(Module, "thisProgram")) Object.defineProperty(Module, "thisProgram", {
		 configurable: true,
		 get: function() {
		  abort("Module.thisProgram has been replaced with plain thisProgram (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		if (Module["quit"]) quit_ = Module["quit"];

		if (!Object.getOwnPropertyDescriptor(Module, "quit")) Object.defineProperty(Module, "quit", {
		 configurable: true,
		 get: function() {
		  abort("Module.quit has been replaced with plain quit_ (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		assert(typeof Module["memoryInitializerPrefixURL"] === "undefined", "Module.memoryInitializerPrefixURL option was removed, use Module.locateFile instead");

		assert(typeof Module["pthreadMainPrefixURL"] === "undefined", "Module.pthreadMainPrefixURL option was removed, use Module.locateFile instead");

		assert(typeof Module["cdInitializerPrefixURL"] === "undefined", "Module.cdInitializerPrefixURL option was removed, use Module.locateFile instead");

		assert(typeof Module["filePackagePrefixURL"] === "undefined", "Module.filePackagePrefixURL option was removed, use Module.locateFile instead");

		assert(typeof Module["read"] === "undefined", "Module.read option was removed (modify read_ in JS)");

		assert(typeof Module["readAsync"] === "undefined", "Module.readAsync option was removed (modify readAsync in JS)");

		assert(typeof Module["readBinary"] === "undefined", "Module.readBinary option was removed (modify readBinary in JS)");

		assert(typeof Module["setWindowTitle"] === "undefined", "Module.setWindowTitle option was removed (modify setWindowTitle in JS)");

		assert(typeof Module["TOTAL_MEMORY"] === "undefined", "Module.TOTAL_MEMORY has been renamed Module.INITIAL_MEMORY");

		if (!Object.getOwnPropertyDescriptor(Module, "read")) Object.defineProperty(Module, "read", {
		 configurable: true,
		 get: function() {
		  abort("Module.read has been replaced with plain read_ (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		if (!Object.getOwnPropertyDescriptor(Module, "readAsync")) Object.defineProperty(Module, "readAsync", {
		 configurable: true,
		 get: function() {
		  abort("Module.readAsync has been replaced with plain readAsync (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		if (!Object.getOwnPropertyDescriptor(Module, "readBinary")) Object.defineProperty(Module, "readBinary", {
		 configurable: true,
		 get: function() {
		  abort("Module.readBinary has been replaced with plain readBinary (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		if (!Object.getOwnPropertyDescriptor(Module, "setWindowTitle")) Object.defineProperty(Module, "setWindowTitle", {
		 configurable: true,
		 get: function() {
		  abort("Module.setWindowTitle has been replaced with plain setWindowTitle (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		var STACK_ALIGN = 16;

		function alignMemory(size, factor) {
		 if (!factor) factor = STACK_ALIGN;
		 return Math.ceil(size / factor) * factor;
		}

		function warnOnce(text) {
		 if (!warnOnce.shown) warnOnce.shown = {};
		 if (!warnOnce.shown[text]) {
		  warnOnce.shown[text] = 1;
		  err(text);
		 }
		}

		function convertJsFunctionToWasm(func, sig) {
		 if (typeof WebAssembly.Function === "function") {
		  var typeNames = {
		   "i": "i32",
		   "j": "i64",
		   "f": "f32",
		   "d": "f64"
		  };
		  var type = {
		   parameters: [],
		   results: sig[0] == "v" ? [] : [ typeNames[sig[0]] ]
		  };
		  for (var i = 1; i < sig.length; ++i) {
		   type.parameters.push(typeNames[sig[i]]);
		  }
		  return new WebAssembly.Function(type, func);
		 }
		 var typeSection = [ 1, 0, 1, 96 ];
		 var sigRet = sig.slice(0, 1);
		 var sigParam = sig.slice(1);
		 var typeCodes = {
		  "i": 127,
		  "j": 126,
		  "f": 125,
		  "d": 124
		 };
		 typeSection.push(sigParam.length);
		 for (var i = 0; i < sigParam.length; ++i) {
		  typeSection.push(typeCodes[sigParam[i]]);
		 }
		 if (sigRet == "v") {
		  typeSection.push(0);
		 } else {
		  typeSection = typeSection.concat([ 1, typeCodes[sigRet] ]);
		 }
		 typeSection[1] = typeSection.length - 2;
		 var bytes = new Uint8Array([ 0, 97, 115, 109, 1, 0, 0, 0 ].concat(typeSection, [ 2, 7, 1, 1, 101, 1, 102, 0, 0, 7, 5, 1, 1, 102, 0, 0 ]));
		 var module = new WebAssembly.Module(bytes);
		 var instance = new WebAssembly.Instance(module, {
		  "e": {
		   "f": func
		  }
		 });
		 var wrappedFunc = instance.exports["f"];
		 return wrappedFunc;
		}

		var freeTableIndexes = [];

		var functionsInTableMap;

		function getEmptyTableSlot() {
		 if (freeTableIndexes.length) {
		  return freeTableIndexes.pop();
		 }
		 try {
		  wasmTable.grow(1);
		 } catch (err) {
		  if (!(err instanceof RangeError)) {
		   throw err;
		  }
		  throw "Unable to grow wasm table. Set ALLOW_TABLE_GROWTH.";
		 }
		 return wasmTable.length - 1;
		}

		function addFunctionWasm(func, sig) {
		 if (!functionsInTableMap) {
		  functionsInTableMap = new WeakMap();
		  for (var i = 0; i < wasmTable.length; i++) {
		   var item = wasmTable.get(i);
		   if (item) {
		    functionsInTableMap.set(item, i);
		   }
		  }
		 }
		 if (functionsInTableMap.has(func)) {
		  return functionsInTableMap.get(func);
		 }
		 var ret = getEmptyTableSlot();
		 try {
		  wasmTable.set(ret, func);
		 } catch (err) {
		  if (!(err instanceof TypeError)) {
		   throw err;
		  }
		  assert(typeof sig !== "undefined", "Missing signature argument to addFunction: " + func);
		  var wrapped = convertJsFunctionToWasm(func, sig);
		  wasmTable.set(ret, wrapped);
		 }
		 functionsInTableMap.set(func, ret);
		 return ret;
		}

		function addFunction(func, sig) {
		 assert(typeof func !== "undefined");
		 return addFunctionWasm(func, sig);
		}

		var wasmBinary;

		if (Module["wasmBinary"]) wasmBinary = Module["wasmBinary"];

		if (!Object.getOwnPropertyDescriptor(Module, "wasmBinary")) Object.defineProperty(Module, "wasmBinary", {
		 configurable: true,
		 get: function() {
		  abort("Module.wasmBinary has been replaced with plain wasmBinary (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		var noExitRuntime;

		if (Module["noExitRuntime"]) noExitRuntime = Module["noExitRuntime"];

		if (!Object.getOwnPropertyDescriptor(Module, "noExitRuntime")) Object.defineProperty(Module, "noExitRuntime", {
		 configurable: true,
		 get: function() {
		  abort("Module.noExitRuntime has been replaced with plain noExitRuntime (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		if (typeof WebAssembly !== "object") {
		 abort("no native wasm support detected");
		}

		var wasmMemory;

		var ABORT = false;

		function assert(condition, text) {
		 if (!condition) {
		  abort("Assertion failed: " + text);
		 }
		}

		function getCFunc(ident) {
		 var func = Module["_" + ident];
		 assert(func, "Cannot call unknown function " + ident + ", make sure it is exported");
		 return func;
		}

		function ccall(ident, returnType, argTypes, args, opts) {
		 var toC = {
		  "string": function(str) {
		   var ret = 0;
		   if (str !== null && str !== undefined && str !== 0) {
		    var len = (str.length << 2) + 1;
		    ret = stackAlloc(len);
		    stringToUTF8(str, ret, len);
		   }
		   return ret;
		  },
		  "array": function(arr) {
		   var ret = stackAlloc(arr.length);
		   writeArrayToMemory(arr, ret);
		   return ret;
		  }
		 };
		 function convertReturnValue(ret) {
		  if (returnType === "string") return UTF8ToString(ret);
		  if (returnType === "boolean") return Boolean(ret);
		  return ret;
		 }
		 var func = getCFunc(ident);
		 var cArgs = [];
		 var stack = 0;
		 assert(returnType !== "array", 'Return type should not be "array".');
		 if (args) {
		  for (var i = 0; i < args.length; i++) {
		   var converter = toC[argTypes[i]];
		   if (converter) {
		    if (stack === 0) stack = stackSave();
		    cArgs[i] = converter(args[i]);
		   } else {
		    cArgs[i] = args[i];
		   }
		  }
		 }
		 var ret = func.apply(null, cArgs);
		 ret = convertReturnValue(ret);
		 if (stack !== 0) stackRestore(stack);
		 return ret;
		}

		var UTF8Decoder = typeof TextDecoder !== "undefined" ? new TextDecoder("utf8") : undefined;

		function UTF8ArrayToString(heap, idx, maxBytesToRead) {
		 var endIdx = idx + maxBytesToRead;
		 var endPtr = idx;
		 while (heap[endPtr] && !(endPtr >= endIdx)) ++endPtr;
		 if (endPtr - idx > 16 && heap.subarray && UTF8Decoder) {
		  return UTF8Decoder.decode(heap.subarray(idx, endPtr));
		 } else {
		  var str = "";
		  while (idx < endPtr) {
		   var u0 = heap[idx++];
		   if (!(u0 & 128)) {
		    str += String.fromCharCode(u0);
		    continue;
		   }
		   var u1 = heap[idx++] & 63;
		   if ((u0 & 224) == 192) {
		    str += String.fromCharCode((u0 & 31) << 6 | u1);
		    continue;
		   }
		   var u2 = heap[idx++] & 63;
		   if ((u0 & 240) == 224) {
		    u0 = (u0 & 15) << 12 | u1 << 6 | u2;
		   } else {
		    if ((u0 & 248) != 240) warnOnce("Invalid UTF-8 leading byte 0x" + u0.toString(16) + " encountered when deserializing a UTF-8 string on the asm.js/wasm heap to a JS string!");
		    u0 = (u0 & 7) << 18 | u1 << 12 | u2 << 6 | heap[idx++] & 63;
		   }
		   if (u0 < 65536) {
		    str += String.fromCharCode(u0);
		   } else {
		    var ch = u0 - 65536;
		    str += String.fromCharCode(55296 | ch >> 10, 56320 | ch & 1023);
		   }
		  }
		 }
		 return str;
		}

		function UTF8ToString(ptr, maxBytesToRead) {
		 return ptr ? UTF8ArrayToString(HEAPU8, ptr, maxBytesToRead) : "";
		}

		function stringToUTF8Array(str, heap, outIdx, maxBytesToWrite) {
		 if (!(maxBytesToWrite > 0)) return 0;
		 var startIdx = outIdx;
		 var endIdx = outIdx + maxBytesToWrite - 1;
		 for (var i = 0; i < str.length; ++i) {
		  var u = str.charCodeAt(i);
		  if (u >= 55296 && u <= 57343) {
		   var u1 = str.charCodeAt(++i);
		   u = 65536 + ((u & 1023) << 10) | u1 & 1023;
		  }
		  if (u <= 127) {
		   if (outIdx >= endIdx) break;
		   heap[outIdx++] = u;
		  } else if (u <= 2047) {
		   if (outIdx + 1 >= endIdx) break;
		   heap[outIdx++] = 192 | u >> 6;
		   heap[outIdx++] = 128 | u & 63;
		  } else if (u <= 65535) {
		   if (outIdx + 2 >= endIdx) break;
		   heap[outIdx++] = 224 | u >> 12;
		   heap[outIdx++] = 128 | u >> 6 & 63;
		   heap[outIdx++] = 128 | u & 63;
		  } else {
		   if (outIdx + 3 >= endIdx) break;
		   if (u >= 2097152) warnOnce("Invalid Unicode code point 0x" + u.toString(16) + " encountered when serializing a JS string to an UTF-8 string on the asm.js/wasm heap! (Valid unicode code points should be in range 0-0x1FFFFF).");
		   heap[outIdx++] = 240 | u >> 18;
		   heap[outIdx++] = 128 | u >> 12 & 63;
		   heap[outIdx++] = 128 | u >> 6 & 63;
		   heap[outIdx++] = 128 | u & 63;
		  }
		 }
		 heap[outIdx] = 0;
		 return outIdx - startIdx;
		}

		function stringToUTF8(str, outPtr, maxBytesToWrite) {
		 assert(typeof maxBytesToWrite == "number", "stringToUTF8(str, outPtr, maxBytesToWrite) is missing the third parameter that specifies the length of the output buffer!");
		 return stringToUTF8Array(str, HEAPU8, outPtr, maxBytesToWrite);
		}

		function lengthBytesUTF8(str) {
		 var len = 0;
		 for (var i = 0; i < str.length; ++i) {
		  var u = str.charCodeAt(i);
		  if (u >= 55296 && u <= 57343) u = 65536 + ((u & 1023) << 10) | str.charCodeAt(++i) & 1023;
		  if (u <= 127) ++len; else if (u <= 2047) len += 2; else if (u <= 65535) len += 3; else len += 4;
		 }
		 return len;
		}

		typeof TextDecoder !== "undefined" ? new TextDecoder("utf-16le") : undefined;

		function allocateUTF8(str) {
		 var size = lengthBytesUTF8(str) + 1;
		 var ret = _malloc(size);
		 if (ret) stringToUTF8Array(str, HEAP8, ret, size);
		 return ret;
		}

		function allocateUTF8OnStack(str) {
		 var size = lengthBytesUTF8(str) + 1;
		 var ret = stackAlloc(size);
		 stringToUTF8Array(str, HEAP8, ret, size);
		 return ret;
		}

		function writeArrayToMemory(array, buffer) {
		 assert(array.length >= 0, "writeArrayToMemory array must have a length (should be an array or typed array)");
		 HEAP8.set(array, buffer);
		}

		function writeAsciiToMemory(str, buffer, dontAddNull) {
		 for (var i = 0; i < str.length; ++i) {
		  assert(str.charCodeAt(i) === str.charCodeAt(i) & 255);
		  HEAP8[buffer++ >> 0] = str.charCodeAt(i);
		 }
		 if (!dontAddNull) HEAP8[buffer >> 0] = 0;
		}

		function alignUp(x, multiple) {
		 if (x % multiple > 0) {
		  x += multiple - x % multiple;
		 }
		 return x;
		}

		var buffer, HEAP8, HEAPU8, HEAP16, HEAP32, HEAPU32;

		function updateGlobalBufferAndViews(buf) {
		 buffer = buf;
		 Module["HEAP8"] = HEAP8 = new Int8Array(buf);
		 Module["HEAP16"] = HEAP16 = new Int16Array(buf);
		 Module["HEAP32"] = HEAP32 = new Int32Array(buf);
		 Module["HEAPU8"] = HEAPU8 = new Uint8Array(buf);
		 Module["HEAPU16"] = new Uint16Array(buf);
		 Module["HEAPU32"] = HEAPU32 = new Uint32Array(buf);
		 Module["HEAPF32"] = new Float32Array(buf);
		 Module["HEAPF64"] = new Float64Array(buf);
		}

		var TOTAL_STACK = 5242880;

		if (Module["TOTAL_STACK"]) assert(TOTAL_STACK === Module["TOTAL_STACK"], "the stack size can no longer be determined at runtime");

		var INITIAL_MEMORY = Module["INITIAL_MEMORY"] || 33554432;

		if (!Object.getOwnPropertyDescriptor(Module, "INITIAL_MEMORY")) Object.defineProperty(Module, "INITIAL_MEMORY", {
		 configurable: true,
		 get: function() {
		  abort("Module.INITIAL_MEMORY has been replaced with plain INITIAL_MEMORY (the initial value can be provided on Module, but after startup the value is only looked for on a local variable of that name)");
		 }
		});

		assert(INITIAL_MEMORY >= TOTAL_STACK, "INITIAL_MEMORY should be larger than TOTAL_STACK, was " + INITIAL_MEMORY + "! (TOTAL_STACK=" + TOTAL_STACK + ")");

		assert(typeof Int32Array !== "undefined" && typeof Float64Array !== "undefined" && Int32Array.prototype.subarray !== undefined && Int32Array.prototype.set !== undefined, "JS engine does not provide full typed array support");

		assert(!Module["wasmMemory"], "Use of `wasmMemory` detected.  Use -s IMPORTED_MEMORY to define wasmMemory externally");

		assert(INITIAL_MEMORY == 33554432, "Detected runtime INITIAL_MEMORY setting.  Use -s IMPORTED_MEMORY to define wasmMemory dynamically");

		var wasmTable;

		function writeStackCookie() {
		 var max = _emscripten_stack_get_end();
		 assert((max & 3) == 0);
		 HEAPU32[(max >> 2) + 1] = 34821223;
		 HEAPU32[(max >> 2) + 2] = 2310721022;
		 HEAP32[0] = 1668509029;
		}

		function checkStackCookie() {
		 if (ABORT) return;
		 var max = _emscripten_stack_get_end();
		 var cookie1 = HEAPU32[(max >> 2) + 1];
		 var cookie2 = HEAPU32[(max >> 2) + 2];
		 if (cookie1 != 34821223 || cookie2 != 2310721022) {
		  abort("Stack overflow! Stack cookie has been overwritten, expected hex dwords 0x89BACDFE and 0x2135467, but received 0x" + cookie2.toString(16) + " " + cookie1.toString(16));
		 }
		 if (HEAP32[0] !== 1668509029) abort("Runtime error: The application has corrupted its heap memory area (address zero)!");
		}

		(function() {
		 var h16 = new Int16Array(1);
		 var h8 = new Int8Array(h16.buffer);
		 h16[0] = 25459;
		 if (h8[0] !== 115 || h8[1] !== 99) throw "Runtime error: expected the system to be little-endian!";
		})();

		var __ATPRERUN__ = [];

		var __ATINIT__ = [];

		var __ATMAIN__ = [];

		var __ATPOSTRUN__ = [];

		var runtimeInitialized = false;

		var runtimeExited = false;

		__ATINIT__.push({
		 func: function() {
		  ___wasm_call_ctors();
		 }
		});

		function preRun() {
		 if (Module["preRun"]) {
		  if (typeof Module["preRun"] == "function") Module["preRun"] = [ Module["preRun"] ];
		  while (Module["preRun"].length) {
		   addOnPreRun(Module["preRun"].shift());
		  }
		 }
		 callRuntimeCallbacks(__ATPRERUN__);
		}

		function initRuntime() {
		 checkStackCookie();
		 assert(!runtimeInitialized);
		 runtimeInitialized = true;
		 if (!Module["noFSInit"] && !FS.init.initialized) FS.init();
		 callRuntimeCallbacks(__ATINIT__);
		}

		function preMain() {
		 checkStackCookie();
		 FS.ignorePermissions = false;
		 callRuntimeCallbacks(__ATMAIN__);
		}

		function exitRuntime() {
		 checkStackCookie();
		 runtimeExited = true;
		}

		function postRun() {
		 checkStackCookie();
		 if (Module["postRun"]) {
		  if (typeof Module["postRun"] == "function") Module["postRun"] = [ Module["postRun"] ];
		  while (Module["postRun"].length) {
		   addOnPostRun(Module["postRun"].shift());
		  }
		 }
		 callRuntimeCallbacks(__ATPOSTRUN__);
		}

		function addOnPreRun(cb) {
		 __ATPRERUN__.unshift(cb);
		}

		function addOnPostRun(cb) {
		 __ATPOSTRUN__.unshift(cb);
		}

		assert(Math.imul, "This browser does not support Math.imul(), build with LEGACY_VM_SUPPORT or POLYFILL_OLD_MATH_FUNCTIONS to add in a polyfill");

		assert(Math.fround, "This browser does not support Math.fround(), build with LEGACY_VM_SUPPORT or POLYFILL_OLD_MATH_FUNCTIONS to add in a polyfill");

		assert(Math.clz32, "This browser does not support Math.clz32(), build with LEGACY_VM_SUPPORT or POLYFILL_OLD_MATH_FUNCTIONS to add in a polyfill");

		assert(Math.trunc, "This browser does not support Math.trunc(), build with LEGACY_VM_SUPPORT or POLYFILL_OLD_MATH_FUNCTIONS to add in a polyfill");

		var runDependencies = 0;

		var runDependencyWatcher = null;

		var dependenciesFulfilled = null;

		var runDependencyTracking = {};

		function getUniqueRunDependency(id) {
		 var orig = id;
		 while (1) {
		  if (!runDependencyTracking[id]) return id;
		  id = orig + Math.random();
		 }
		}

		function addRunDependency(id) {
		 runDependencies++;
		 if (Module["monitorRunDependencies"]) {
		  Module["monitorRunDependencies"](runDependencies);
		 }
		 if (id) {
		  assert(!runDependencyTracking[id]);
		  runDependencyTracking[id] = 1;
		  if (runDependencyWatcher === null && typeof setInterval !== "undefined") {
		   runDependencyWatcher = setInterval(function() {
		    if (ABORT) {
		     clearInterval(runDependencyWatcher);
		     runDependencyWatcher = null;
		     return;
		    }
		    var shown = false;
		    for (var dep in runDependencyTracking) {
		     if (!shown) {
		      shown = true;
		      err("still waiting on run dependencies:");
		     }
		     err("dependency: " + dep);
		    }
		    if (shown) {
		     err("(end of list)");
		    }
		   }, 1e4);
		  }
		 } else {
		  err("warning: run dependency added without ID");
		 }
		}

		function removeRunDependency(id) {
		 runDependencies--;
		 if (Module["monitorRunDependencies"]) {
		  Module["monitorRunDependencies"](runDependencies);
		 }
		 if (id) {
		  assert(runDependencyTracking[id]);
		  delete runDependencyTracking[id];
		 } else {
		  err("warning: run dependency removed without ID");
		 }
		 if (runDependencies == 0) {
		  if (runDependencyWatcher !== null) {
		   clearInterval(runDependencyWatcher);
		   runDependencyWatcher = null;
		  }
		  if (dependenciesFulfilled) {
		   var callback = dependenciesFulfilled;
		   dependenciesFulfilled = null;
		   callback();
		  }
		 }
		}

		Module["preloadedImages"] = {};

		Module["preloadedAudios"] = {};

		function abort(what) {
		 if (Module["onAbort"]) {
		  Module["onAbort"](what);
		 }
		 what += "";
		 err(what);
		 ABORT = true;
		 var output = "abort(" + what + ") at " + stackTrace();
		 what = output;
		 var e = new WebAssembly.RuntimeError(what);
		 readyPromiseReject(e);
		 throw e;
		}

		function hasPrefix(str, prefix) {
		 return String.prototype.startsWith ? str.startsWith(prefix) : str.indexOf(prefix) === 0;
		}

		var dataURIPrefix = "data:application/octet-stream;base64,";

		function isDataURI(filename) {
		 return hasPrefix(filename, dataURIPrefix);
		}

		function createExportWrapper(name, fixedasm) {
		 return function() {
		  var displayName = name;
		  var asm = fixedasm;
		  if (!fixedasm) {
		   asm = Module["asm"];
		  }
		  assert(runtimeInitialized, "native function `" + displayName + "` called before runtime initialization");
		  assert(!runtimeExited, "native function `" + displayName + "` called after runtime exit (use NO_EXIT_RUNTIME to keep it alive after main() exits)");
		  if (!asm[name]) {
		   assert(asm[name], "exported native function `" + displayName + "` not found");
		  }
		  return asm[name].apply(null, arguments);
		 };
		}

		var wasmBinaryFile = "trace_processor.wasm";

		if (!isDataURI(wasmBinaryFile)) {
		 wasmBinaryFile = locateFile(wasmBinaryFile);
		}

		function getBinary(file) {
		 try {
		  if (file == wasmBinaryFile && wasmBinary) {
		   return new Uint8Array(wasmBinary);
		  }
		  if (readBinary) {
		   return readBinary(file);
		  } else {
		   throw "sync fetching of the wasm failed: you can preload it to Module['wasmBinary'] manually, or emcc.py will do that for you when generating HTML (but not JS)";
		  }
		 } catch (err) {
		  abort(err);
		 }
		}

		function instantiateSync(file, info) {
		 var instance;
		 var module;
		 var binary;
		 try {
		  binary = getBinary(file);
		  module = new WebAssembly.Module(binary);
		  instance = new WebAssembly.Instance(module, info);
		 } catch (e) {
		  var str = e.toString();
		  err("failed to compile wasm module: " + str);
		  if (str.indexOf("imported Memory") >= 0 || str.indexOf("memory import") >= 0) {
		   err("Memory size incompatibility issues may be due to changing INITIAL_MEMORY at runtime to something too large. Use ALLOW_MEMORY_GROWTH to allow any size memory (and also make sure not to set INITIAL_MEMORY at runtime to something smaller than it was at compile time).");
		  }
		  throw e;
		 }
		 return [ instance, module ];
		}

		function createWasm() {
		 var info = {
		  "env": asmLibraryArg,
		  "wasi_snapshot_preview1": asmLibraryArg
		 };
		 function receiveInstance(instance, module) {
		  var exports = instance.exports;
		  Module["asm"] = exports;
		  wasmMemory = Module["asm"]["memory"];
		  assert(wasmMemory, "memory not found in wasm exports");
		  updateGlobalBufferAndViews(wasmMemory.buffer);
		  wasmTable = Module["asm"]["__indirect_function_table"];
		  assert(wasmTable, "table not found in wasm exports");
		  removeRunDependency("wasm-instantiate");
		 }
		 addRunDependency("wasm-instantiate");
		 if (Module["instantiateWasm"]) {
		  try {
		   var exports = Module["instantiateWasm"](info, receiveInstance);
		   return exports;
		  } catch (e) {
		   err("Module.instantiateWasm callback failed with error: " + e);
		   return false;
		  }
		 }
		 var result = instantiateSync(wasmBinaryFile, info);
		 receiveInstance(result[0]);
		 return Module["asm"];
		}

		var tempDouble;

		var tempI64;

		function callRuntimeCallbacks(callbacks) {
		 while (callbacks.length > 0) {
		  var callback = callbacks.shift();
		  if (typeof callback == "function") {
		   callback(Module);
		   continue;
		  }
		  var func = callback.func;
		  if (typeof func === "number") {
		   if (callback.arg === undefined) {
		    wasmTable.get(func)();
		   } else {
		    wasmTable.get(func)(callback.arg);
		   }
		  } else {
		   func(callback.arg === undefined ? null : callback.arg);
		  }
		 }
		}

		function demangle(func) {
		 warnOnce("warning: build with  -s DEMANGLE_SUPPORT=1  to link in libcxxabi demangling");
		 return func;
		}

		function demangleAll(text) {
		 var regex = /\b_Z[\w\d_]+/g;
		 return text.replace(regex, function(x) {
		  var y = demangle(x);
		  return x === y ? x : y + " [" + x + "]";
		 });
		}

		function jsStackTrace() {
		 var error = new Error();
		 if (!error.stack) {
		  try {
		   throw new Error();
		  } catch (e) {
		   error = e;
		  }
		  if (!error.stack) {
		   return "(no stack trace available)";
		  }
		 }
		 return error.stack.toString();
		}

		function stackTrace() {
		 var js = jsStackTrace();
		 if (Module["extraStackTrace"]) js += "\n" + Module["extraStackTrace"]();
		 return demangleAll(js);
		}

		function _atexit(func, arg) {}

		function ___cxa_atexit(a0, a1) {
		 return _atexit();
		}

		function _gmtime_r(time, tmPtr) {
		 var date = new Date(HEAP32[time >> 2] * 1e3);
		 HEAP32[tmPtr >> 2] = date.getUTCSeconds();
		 HEAP32[tmPtr + 4 >> 2] = date.getUTCMinutes();
		 HEAP32[tmPtr + 8 >> 2] = date.getUTCHours();
		 HEAP32[tmPtr + 12 >> 2] = date.getUTCDate();
		 HEAP32[tmPtr + 16 >> 2] = date.getUTCMonth();
		 HEAP32[tmPtr + 20 >> 2] = date.getUTCFullYear() - 1900;
		 HEAP32[tmPtr + 24 >> 2] = date.getUTCDay();
		 HEAP32[tmPtr + 36 >> 2] = 0;
		 HEAP32[tmPtr + 32 >> 2] = 0;
		 var start = Date.UTC(date.getUTCFullYear(), 0, 1, 0, 0, 0, 0);
		 var yday = (date.getTime() - start) / (1e3 * 60 * 60 * 24) | 0;
		 HEAP32[tmPtr + 28 >> 2] = yday;
		 if (!_gmtime_r.GMTString) _gmtime_r.GMTString = allocateUTF8("GMT");
		 HEAP32[tmPtr + 40 >> 2] = _gmtime_r.GMTString;
		 return tmPtr;
		}

		function ___gmtime_r(a0, a1) {
		 return _gmtime_r(a0, a1);
		}

		function _tzset() {
		 if (_tzset.called) return;
		 _tzset.called = true;
		 var currentYear = new Date().getFullYear();
		 var winter = new Date(currentYear, 0, 1);
		 var summer = new Date(currentYear, 6, 1);
		 var winterOffset = winter.getTimezoneOffset();
		 var summerOffset = summer.getTimezoneOffset();
		 var stdTimezoneOffset = Math.max(winterOffset, summerOffset);
		 HEAP32[__get_timezone() >> 2] = stdTimezoneOffset * 60;
		 HEAP32[__get_daylight() >> 2] = Number(winterOffset != summerOffset);
		 function extractZone(date) {
		  var match = date.toTimeString().match(/\(([A-Za-z ]+)\)$/);
		  return match ? match[1] : "GMT";
		 }
		 var winterName = extractZone(winter);
		 var summerName = extractZone(summer);
		 var winterNamePtr = allocateUTF8(winterName);
		 var summerNamePtr = allocateUTF8(summerName);
		 if (summerOffset < winterOffset) {
		  HEAP32[__get_tzname() >> 2] = winterNamePtr;
		  HEAP32[__get_tzname() + 4 >> 2] = summerNamePtr;
		 } else {
		  HEAP32[__get_tzname() >> 2] = summerNamePtr;
		  HEAP32[__get_tzname() + 4 >> 2] = winterNamePtr;
		 }
		}

		function _localtime_r(time, tmPtr) {
		 _tzset();
		 var date = new Date(HEAP32[time >> 2] * 1e3);
		 HEAP32[tmPtr >> 2] = date.getSeconds();
		 HEAP32[tmPtr + 4 >> 2] = date.getMinutes();
		 HEAP32[tmPtr + 8 >> 2] = date.getHours();
		 HEAP32[tmPtr + 12 >> 2] = date.getDate();
		 HEAP32[tmPtr + 16 >> 2] = date.getMonth();
		 HEAP32[tmPtr + 20 >> 2] = date.getFullYear() - 1900;
		 HEAP32[tmPtr + 24 >> 2] = date.getDay();
		 var start = new Date(date.getFullYear(), 0, 1);
		 var yday = (date.getTime() - start.getTime()) / (1e3 * 60 * 60 * 24) | 0;
		 HEAP32[tmPtr + 28 >> 2] = yday;
		 HEAP32[tmPtr + 36 >> 2] = -(date.getTimezoneOffset() * 60);
		 var summerOffset = new Date(date.getFullYear(), 6, 1).getTimezoneOffset();
		 var winterOffset = start.getTimezoneOffset();
		 var dst = (summerOffset != winterOffset && date.getTimezoneOffset() == Math.min(winterOffset, summerOffset)) | 0;
		 HEAP32[tmPtr + 32 >> 2] = dst;
		 var zonePtr = HEAP32[__get_tzname() + (dst ? 4 : 0) >> 2];
		 HEAP32[tmPtr + 40 >> 2] = zonePtr;
		 return tmPtr;
		}

		function ___localtime_r(a0, a1) {
		 return _localtime_r(a0, a1);
		}

		var PATH = {
		 splitPath: function(filename) {
		  var splitPathRe = /^(\/?|)([\s\S]*?)((?:\.{1,2}|[^\/]+?|)(\.[^.\/]*|))(?:[\/]*)$/;
		  return splitPathRe.exec(filename).slice(1);
		 },
		 normalizeArray: function(parts, allowAboveRoot) {
		  var up = 0;
		  for (var i = parts.length - 1; i >= 0; i--) {
		   var last = parts[i];
		   if (last === ".") {
		    parts.splice(i, 1);
		   } else if (last === "..") {
		    parts.splice(i, 1);
		    up++;
		   } else if (up) {
		    parts.splice(i, 1);
		    up--;
		   }
		  }
		  if (allowAboveRoot) {
		   for (;up; up--) {
		    parts.unshift("..");
		   }
		  }
		  return parts;
		 },
		 normalize: function(path) {
		  var isAbsolute = path.charAt(0) === "/", trailingSlash = path.substr(-1) === "/";
		  path = PATH.normalizeArray(path.split("/").filter(function(p) {
		   return !!p;
		  }), !isAbsolute).join("/");
		  if (!path && !isAbsolute) {
		   path = ".";
		  }
		  if (path && trailingSlash) {
		   path += "/";
		  }
		  return (isAbsolute ? "/" : "") + path;
		 },
		 dirname: function(path) {
		  var result = PATH.splitPath(path), root = result[0], dir = result[1];
		  if (!root && !dir) {
		   return ".";
		  }
		  if (dir) {
		   dir = dir.substr(0, dir.length - 1);
		  }
		  return root + dir;
		 },
		 basename: function(path) {
		  if (path === "/") return "/";
		  path = PATH.normalize(path);
		  path = path.replace(/\/$/, "");
		  var lastSlash = path.lastIndexOf("/");
		  if (lastSlash === -1) return path;
		  return path.substr(lastSlash + 1);
		 },
		 extname: function(path) {
		  return PATH.splitPath(path)[3];
		 },
		 join: function() {
		  var paths = Array.prototype.slice.call(arguments, 0);
		  return PATH.normalize(paths.join("/"));
		 },
		 join2: function(l, r) {
		  return PATH.normalize(l + "/" + r);
		 }
		};

		function getRandomDevice() {
		 if (typeof crypto === "object" && typeof crypto["getRandomValues"] === "function") {
		  var randomBuffer = new Uint8Array(1);
		  return function() {
		   crypto.getRandomValues(randomBuffer);
		   return randomBuffer[0];
		  };
		 } else return function() {
		  abort("no cryptographic support found for randomDevice. consider polyfilling it if you want to use something insecure like Math.random(), e.g. put this in a --pre-js: var crypto = { getRandomValues: function(array) { for (var i = 0; i < array.length; i++) array[i] = (Math.random()*256)|0 } };");
		 };
		}

		var PATH_FS = {
		 resolve: function() {
		  var resolvedPath = "", resolvedAbsolute = false;
		  for (var i = arguments.length - 1; i >= -1 && !resolvedAbsolute; i--) {
		   var path = i >= 0 ? arguments[i] : FS.cwd();
		   if (typeof path !== "string") {
		    throw new TypeError("Arguments to path.resolve must be strings");
		   } else if (!path) {
		    return "";
		   }
		   resolvedPath = path + "/" + resolvedPath;
		   resolvedAbsolute = path.charAt(0) === "/";
		  }
		  resolvedPath = PATH.normalizeArray(resolvedPath.split("/").filter(function(p) {
		   return !!p;
		  }), !resolvedAbsolute).join("/");
		  return (resolvedAbsolute ? "/" : "") + resolvedPath || ".";
		 },
		 relative: function(from, to) {
		  from = PATH_FS.resolve(from).substr(1);
		  to = PATH_FS.resolve(to).substr(1);
		  function trim(arr) {
		   var start = 0;
		   for (;start < arr.length; start++) {
		    if (arr[start] !== "") break;
		   }
		   var end = arr.length - 1;
		   for (;end >= 0; end--) {
		    if (arr[end] !== "") break;
		   }
		   if (start > end) return [];
		   return arr.slice(start, end - start + 1);
		  }
		  var fromParts = trim(from.split("/"));
		  var toParts = trim(to.split("/"));
		  var length = Math.min(fromParts.length, toParts.length);
		  var samePartsLength = length;
		  for (var i = 0; i < length; i++) {
		   if (fromParts[i] !== toParts[i]) {
		    samePartsLength = i;
		    break;
		   }
		  }
		  var outputParts = [];
		  for (var i = samePartsLength; i < fromParts.length; i++) {
		   outputParts.push("..");
		  }
		  outputParts = outputParts.concat(toParts.slice(samePartsLength));
		  return outputParts.join("/");
		 }
		};

		var TTY = {
		 ttys: [],
		 init: function() {},
		 shutdown: function() {},
		 register: function(dev, ops) {
		  TTY.ttys[dev] = {
		   input: [],
		   output: [],
		   ops: ops
		  };
		  FS.registerDevice(dev, TTY.stream_ops);
		 },
		 stream_ops: {
		  open: function(stream) {
		   var tty = TTY.ttys[stream.node.rdev];
		   if (!tty) {
		    throw new FS.ErrnoError(43);
		   }
		   stream.tty = tty;
		   stream.seekable = false;
		  },
		  close: function(stream) {
		   stream.tty.ops.flush(stream.tty);
		  },
		  flush: function(stream) {
		   stream.tty.ops.flush(stream.tty);
		  },
		  read: function(stream, buffer, offset, length, pos) {
		   if (!stream.tty || !stream.tty.ops.get_char) {
		    throw new FS.ErrnoError(60);
		   }
		   var bytesRead = 0;
		   for (var i = 0; i < length; i++) {
		    var result;
		    try {
		     result = stream.tty.ops.get_char(stream.tty);
		    } catch (e) {
		     throw new FS.ErrnoError(29);
		    }
		    if (result === undefined && bytesRead === 0) {
		     throw new FS.ErrnoError(6);
		    }
		    if (result === null || result === undefined) break;
		    bytesRead++;
		    buffer[offset + i] = result;
		   }
		   if (bytesRead) {
		    stream.node.timestamp = Date.now();
		   }
		   return bytesRead;
		  },
		  write: function(stream, buffer, offset, length, pos) {
		   if (!stream.tty || !stream.tty.ops.put_char) {
		    throw new FS.ErrnoError(60);
		   }
		   try {
		    for (var i = 0; i < length; i++) {
		     stream.tty.ops.put_char(stream.tty, buffer[offset + i]);
		    }
		   } catch (e) {
		    throw new FS.ErrnoError(29);
		   }
		   if (length) {
		    stream.node.timestamp = Date.now();
		   }
		   return i;
		  }
		 },
		 default_tty_ops: {
		  get_char: function(tty) {
		   if (!tty.input.length) {
		    var result = null;
		    if (typeof window != "undefined" && typeof window.prompt == "function") {
		     result = window.prompt("Input: ");
		     if (result !== null) {
		      result += "\n";
		     }
		    } else if (typeof readline == "function") {
		     result = readline();
		     if (result !== null) {
		      result += "\n";
		     }
		    }
		    if (!result) {
		     return null;
		    }
		    tty.input = intArrayFromString(result, true);
		   }
		   return tty.input.shift();
		  },
		  put_char: function(tty, val) {
		   if (val === null || val === 10) {
		    out(UTF8ArrayToString(tty.output, 0));
		    tty.output = [];
		   } else {
		    if (val != 0) tty.output.push(val);
		   }
		  },
		  flush: function(tty) {
		   if (tty.output && tty.output.length > 0) {
		    out(UTF8ArrayToString(tty.output, 0));
		    tty.output = [];
		   }
		  }
		 },
		 default_tty1_ops: {
		  put_char: function(tty, val) {
		   if (val === null || val === 10) {
		    err(UTF8ArrayToString(tty.output, 0));
		    tty.output = [];
		   } else {
		    if (val != 0) tty.output.push(val);
		   }
		  },
		  flush: function(tty) {
		   if (tty.output && tty.output.length > 0) {
		    err(UTF8ArrayToString(tty.output, 0));
		    tty.output = [];
		   }
		  }
		 }
		};

		function mmapAlloc(size) {
		 var alignedSize = alignMemory(size, 16384);
		 var ptr = _malloc(alignedSize);
		 while (size < alignedSize) HEAP8[ptr + size++] = 0;
		 return ptr;
		}

		var MEMFS = {
		 ops_table: null,
		 mount: function(mount) {
		  return MEMFS.createNode(null, "/", 16384 | 511, 0);
		 },
		 createNode: function(parent, name, mode, dev) {
		  if (FS.isBlkdev(mode) || FS.isFIFO(mode)) {
		   throw new FS.ErrnoError(63);
		  }
		  if (!MEMFS.ops_table) {
		   MEMFS.ops_table = {
		    dir: {
		     node: {
		      getattr: MEMFS.node_ops.getattr,
		      setattr: MEMFS.node_ops.setattr,
		      lookup: MEMFS.node_ops.lookup,
		      mknod: MEMFS.node_ops.mknod,
		      rename: MEMFS.node_ops.rename,
		      unlink: MEMFS.node_ops.unlink,
		      rmdir: MEMFS.node_ops.rmdir,
		      readdir: MEMFS.node_ops.readdir,
		      symlink: MEMFS.node_ops.symlink
		     },
		     stream: {
		      llseek: MEMFS.stream_ops.llseek
		     }
		    },
		    file: {
		     node: {
		      getattr: MEMFS.node_ops.getattr,
		      setattr: MEMFS.node_ops.setattr
		     },
		     stream: {
		      llseek: MEMFS.stream_ops.llseek,
		      read: MEMFS.stream_ops.read,
		      write: MEMFS.stream_ops.write,
		      allocate: MEMFS.stream_ops.allocate,
		      mmap: MEMFS.stream_ops.mmap,
		      msync: MEMFS.stream_ops.msync
		     }
		    },
		    link: {
		     node: {
		      getattr: MEMFS.node_ops.getattr,
		      setattr: MEMFS.node_ops.setattr,
		      readlink: MEMFS.node_ops.readlink
		     },
		     stream: {}
		    },
		    chrdev: {
		     node: {
		      getattr: MEMFS.node_ops.getattr,
		      setattr: MEMFS.node_ops.setattr
		     },
		     stream: FS.chrdev_stream_ops
		    }
		   };
		  }
		  var node = FS.createNode(parent, name, mode, dev);
		  if (FS.isDir(node.mode)) {
		   node.node_ops = MEMFS.ops_table.dir.node;
		   node.stream_ops = MEMFS.ops_table.dir.stream;
		   node.contents = {};
		  } else if (FS.isFile(node.mode)) {
		   node.node_ops = MEMFS.ops_table.file.node;
		   node.stream_ops = MEMFS.ops_table.file.stream;
		   node.usedBytes = 0;
		   node.contents = null;
		  } else if (FS.isLink(node.mode)) {
		   node.node_ops = MEMFS.ops_table.link.node;
		   node.stream_ops = MEMFS.ops_table.link.stream;
		  } else if (FS.isChrdev(node.mode)) {
		   node.node_ops = MEMFS.ops_table.chrdev.node;
		   node.stream_ops = MEMFS.ops_table.chrdev.stream;
		  }
		  node.timestamp = Date.now();
		  if (parent) {
		   parent.contents[name] = node;
		   parent.timestamp = node.timestamp;
		  }
		  return node;
		 },
		 getFileDataAsRegularArray: function(node) {
		  if (node.contents && node.contents.subarray) {
		   var arr = [];
		   for (var i = 0; i < node.usedBytes; ++i) arr.push(node.contents[i]);
		   return arr;
		  }
		  return node.contents;
		 },
		 getFileDataAsTypedArray: function(node) {
		  if (!node.contents) return new Uint8Array(0);
		  if (node.contents.subarray) return node.contents.subarray(0, node.usedBytes);
		  return new Uint8Array(node.contents);
		 },
		 expandFileStorage: function(node, newCapacity) {
		  var prevCapacity = node.contents ? node.contents.length : 0;
		  if (prevCapacity >= newCapacity) return;
		  var CAPACITY_DOUBLING_MAX = 1024 * 1024;
		  newCapacity = Math.max(newCapacity, prevCapacity * (prevCapacity < CAPACITY_DOUBLING_MAX ? 2 : 1.125) >>> 0);
		  if (prevCapacity != 0) newCapacity = Math.max(newCapacity, 256);
		  var oldContents = node.contents;
		  node.contents = new Uint8Array(newCapacity);
		  if (node.usedBytes > 0) node.contents.set(oldContents.subarray(0, node.usedBytes), 0);
		  return;
		 },
		 resizeFileStorage: function(node, newSize) {
		  if (node.usedBytes == newSize) return;
		  if (newSize == 0) {
		   node.contents = null;
		   node.usedBytes = 0;
		   return;
		  }
		  if (!node.contents || node.contents.subarray) {
		   var oldContents = node.contents;
		   node.contents = new Uint8Array(newSize);
		   if (oldContents) {
		    node.contents.set(oldContents.subarray(0, Math.min(newSize, node.usedBytes)));
		   }
		   node.usedBytes = newSize;
		   return;
		  }
		  if (!node.contents) node.contents = [];
		  if (node.contents.length > newSize) node.contents.length = newSize; else while (node.contents.length < newSize) node.contents.push(0);
		  node.usedBytes = newSize;
		 },
		 node_ops: {
		  getattr: function(node) {
		   var attr = {};
		   attr.dev = FS.isChrdev(node.mode) ? node.id : 1;
		   attr.ino = node.id;
		   attr.mode = node.mode;
		   attr.nlink = 1;
		   attr.uid = 0;
		   attr.gid = 0;
		   attr.rdev = node.rdev;
		   if (FS.isDir(node.mode)) {
		    attr.size = 4096;
		   } else if (FS.isFile(node.mode)) {
		    attr.size = node.usedBytes;
		   } else if (FS.isLink(node.mode)) {
		    attr.size = node.link.length;
		   } else {
		    attr.size = 0;
		   }
		   attr.atime = new Date(node.timestamp);
		   attr.mtime = new Date(node.timestamp);
		   attr.ctime = new Date(node.timestamp);
		   attr.blksize = 4096;
		   attr.blocks = Math.ceil(attr.size / attr.blksize);
		   return attr;
		  },
		  setattr: function(node, attr) {
		   if (attr.mode !== undefined) {
		    node.mode = attr.mode;
		   }
		   if (attr.timestamp !== undefined) {
		    node.timestamp = attr.timestamp;
		   }
		   if (attr.size !== undefined) {
		    MEMFS.resizeFileStorage(node, attr.size);
		   }
		  },
		  lookup: function(parent, name) {
		   throw FS.genericErrors[44];
		  },
		  mknod: function(parent, name, mode, dev) {
		   return MEMFS.createNode(parent, name, mode, dev);
		  },
		  rename: function(old_node, new_dir, new_name) {
		   if (FS.isDir(old_node.mode)) {
		    var new_node;
		    try {
		     new_node = FS.lookupNode(new_dir, new_name);
		    } catch (e) {}
		    if (new_node) {
		     for (var i in new_node.contents) {
		      throw new FS.ErrnoError(55);
		     }
		    }
		   }
		   delete old_node.parent.contents[old_node.name];
		   old_node.parent.timestamp = Date.now();
		   old_node.name = new_name;
		   new_dir.contents[new_name] = old_node;
		   new_dir.timestamp = old_node.parent.timestamp;
		   old_node.parent = new_dir;
		  },
		  unlink: function(parent, name) {
		   delete parent.contents[name];
		   parent.timestamp = Date.now();
		  },
		  rmdir: function(parent, name) {
		   var node = FS.lookupNode(parent, name);
		   for (var i in node.contents) {
		    throw new FS.ErrnoError(55);
		   }
		   delete parent.contents[name];
		   parent.timestamp = Date.now();
		  },
		  readdir: function(node) {
		   var entries = [ ".", ".." ];
		   for (var key in node.contents) {
		    if (!node.contents.hasOwnProperty(key)) {
		     continue;
		    }
		    entries.push(key);
		   }
		   return entries;
		  },
		  symlink: function(parent, newname, oldpath) {
		   var node = MEMFS.createNode(parent, newname, 511 | 40960, 0);
		   node.link = oldpath;
		   return node;
		  },
		  readlink: function(node) {
		   if (!FS.isLink(node.mode)) {
		    throw new FS.ErrnoError(28);
		   }
		   return node.link;
		  }
		 },
		 stream_ops: {
		  read: function(stream, buffer, offset, length, position) {
		   var contents = stream.node.contents;
		   if (position >= stream.node.usedBytes) return 0;
		   var size = Math.min(stream.node.usedBytes - position, length);
		   assert(size >= 0);
		   if (size > 8 && contents.subarray) {
		    buffer.set(contents.subarray(position, position + size), offset);
		   } else {
		    for (var i = 0; i < size; i++) buffer[offset + i] = contents[position + i];
		   }
		   return size;
		  },
		  write: function(stream, buffer, offset, length, position, canOwn) {
		   assert(!(buffer instanceof ArrayBuffer));
		   if (buffer.buffer === HEAP8.buffer) {
		    canOwn = false;
		   }
		   if (!length) return 0;
		   var node = stream.node;
		   node.timestamp = Date.now();
		   if (buffer.subarray && (!node.contents || node.contents.subarray)) {
		    if (canOwn) {
		     assert(position === 0, "canOwn must imply no weird position inside the file");
		     node.contents = buffer.subarray(offset, offset + length);
		     node.usedBytes = length;
		     return length;
		    } else if (node.usedBytes === 0 && position === 0) {
		     node.contents = buffer.slice(offset, offset + length);
		     node.usedBytes = length;
		     return length;
		    } else if (position + length <= node.usedBytes) {
		     node.contents.set(buffer.subarray(offset, offset + length), position);
		     return length;
		    }
		   }
		   MEMFS.expandFileStorage(node, position + length);
		   if (node.contents.subarray && buffer.subarray) {
		    node.contents.set(buffer.subarray(offset, offset + length), position);
		   } else {
		    for (var i = 0; i < length; i++) {
		     node.contents[position + i] = buffer[offset + i];
		    }
		   }
		   node.usedBytes = Math.max(node.usedBytes, position + length);
		   return length;
		  },
		  llseek: function(stream, offset, whence) {
		   var position = offset;
		   if (whence === 1) {
		    position += stream.position;
		   } else if (whence === 2) {
		    if (FS.isFile(stream.node.mode)) {
		     position += stream.node.usedBytes;
		    }
		   }
		   if (position < 0) {
		    throw new FS.ErrnoError(28);
		   }
		   return position;
		  },
		  allocate: function(stream, offset, length) {
		   MEMFS.expandFileStorage(stream.node, offset + length);
		   stream.node.usedBytes = Math.max(stream.node.usedBytes, offset + length);
		  },
		  mmap: function(stream, address, length, position, prot, flags) {
		   if (address !== 0) {
		    throw new FS.ErrnoError(28);
		   }
		   if (!FS.isFile(stream.node.mode)) {
		    throw new FS.ErrnoError(43);
		   }
		   var ptr;
		   var allocated;
		   var contents = stream.node.contents;
		   if (!(flags & 2) && contents.buffer === buffer) {
		    allocated = false;
		    ptr = contents.byteOffset;
		   } else {
		    if (position > 0 || position + length < contents.length) {
		     if (contents.subarray) {
		      contents = contents.subarray(position, position + length);
		     } else {
		      contents = Array.prototype.slice.call(contents, position, position + length);
		     }
		    }
		    allocated = true;
		    ptr = mmapAlloc(length);
		    if (!ptr) {
		     throw new FS.ErrnoError(48);
		    }
		    HEAP8.set(contents, ptr);
		   }
		   return {
		    ptr: ptr,
		    allocated: allocated
		   };
		  },
		  msync: function(stream, buffer, offset, length, mmapFlags) {
		   if (!FS.isFile(stream.node.mode)) {
		    throw new FS.ErrnoError(43);
		   }
		   if (mmapFlags & 2) {
		    return 0;
		   }
		   MEMFS.stream_ops.write(stream, buffer, 0, length, offset, false);
		   return 0;
		  }
		 }
		};

		var WORKERFS = {
		 DIR_MODE: 16895,
		 FILE_MODE: 33279,
		 reader: null,
		 mount: function(mount) {
		  assert(ENVIRONMENT_IS_WORKER);
		  if (!WORKERFS.reader) WORKERFS.reader = new FileReaderSync();
		  var root = WORKERFS.createNode(null, "/", WORKERFS.DIR_MODE, 0);
		  var createdParents = {};
		  function ensureParent(path) {
		   var parts = path.split("/");
		   var parent = root;
		   for (var i = 0; i < parts.length - 1; i++) {
		    var curr = parts.slice(0, i + 1).join("/");
		    if (!createdParents[curr]) {
		     createdParents[curr] = WORKERFS.createNode(parent, parts[i], WORKERFS.DIR_MODE, 0);
		    }
		    parent = createdParents[curr];
		   }
		   return parent;
		  }
		  function base(path) {
		   var parts = path.split("/");
		   return parts[parts.length - 1];
		  }
		  Array.prototype.forEach.call(mount.opts["files"] || [], function(file) {
		   WORKERFS.createNode(ensureParent(file.name), base(file.name), WORKERFS.FILE_MODE, 0, file, file.lastModifiedDate);
		  });
		  (mount.opts["blobs"] || []).forEach(function(obj) {
		   WORKERFS.createNode(ensureParent(obj["name"]), base(obj["name"]), WORKERFS.FILE_MODE, 0, obj["data"]);
		  });
		  (mount.opts["packages"] || []).forEach(function(pack) {
		   pack["metadata"].files.forEach(function(file) {
		    var name = file.filename.substr(1);
		    WORKERFS.createNode(ensureParent(name), base(name), WORKERFS.FILE_MODE, 0, pack["blob"].slice(file.start, file.end));
		   });
		  });
		  return root;
		 },
		 createNode: function(parent, name, mode, dev, contents, mtime) {
		  var node = FS.createNode(parent, name, mode);
		  node.mode = mode;
		  node.node_ops = WORKERFS.node_ops;
		  node.stream_ops = WORKERFS.stream_ops;
		  node.timestamp = (mtime || new Date()).getTime();
		  assert(WORKERFS.FILE_MODE !== WORKERFS.DIR_MODE);
		  if (mode === WORKERFS.FILE_MODE) {
		   node.size = contents.size;
		   node.contents = contents;
		  } else {
		   node.size = 4096;
		   node.contents = {};
		  }
		  if (parent) {
		   parent.contents[name] = node;
		  }
		  return node;
		 },
		 node_ops: {
		  getattr: function(node) {
		   return {
		    dev: 1,
		    ino: node.id,
		    mode: node.mode,
		    nlink: 1,
		    uid: 0,
		    gid: 0,
		    rdev: undefined,
		    size: node.size,
		    atime: new Date(node.timestamp),
		    mtime: new Date(node.timestamp),
		    ctime: new Date(node.timestamp),
		    blksize: 4096,
		    blocks: Math.ceil(node.size / 4096)
		   };
		  },
		  setattr: function(node, attr) {
		   if (attr.mode !== undefined) {
		    node.mode = attr.mode;
		   }
		   if (attr.timestamp !== undefined) {
		    node.timestamp = attr.timestamp;
		   }
		  },
		  lookup: function(parent, name) {
		   throw new FS.ErrnoError(44);
		  },
		  mknod: function(parent, name, mode, dev) {
		   throw new FS.ErrnoError(63);
		  },
		  rename: function(oldNode, newDir, newName) {
		   throw new FS.ErrnoError(63);
		  },
		  unlink: function(parent, name) {
		   throw new FS.ErrnoError(63);
		  },
		  rmdir: function(parent, name) {
		   throw new FS.ErrnoError(63);
		  },
		  readdir: function(node) {
		   var entries = [ ".", ".." ];
		   for (var key in node.contents) {
		    if (!node.contents.hasOwnProperty(key)) {
		     continue;
		    }
		    entries.push(key);
		   }
		   return entries;
		  },
		  symlink: function(parent, newName, oldPath) {
		   throw new FS.ErrnoError(63);
		  },
		  readlink: function(node) {
		   throw new FS.ErrnoError(63);
		  }
		 },
		 stream_ops: {
		  read: function(stream, buffer, offset, length, position) {
		   if (position >= stream.node.size) return 0;
		   var chunk = stream.node.contents.slice(position, position + length);
		   var ab = WORKERFS.reader.readAsArrayBuffer(chunk);
		   buffer.set(new Uint8Array(ab), offset);
		   return chunk.size;
		  },
		  write: function(stream, buffer, offset, length, position) {
		   throw new FS.ErrnoError(29);
		  },
		  llseek: function(stream, offset, whence) {
		   var position = offset;
		   if (whence === 1) {
		    position += stream.position;
		   } else if (whence === 2) {
		    if (FS.isFile(stream.node.mode)) {
		     position += stream.node.size;
		    }
		   }
		   if (position < 0) {
		    throw new FS.ErrnoError(28);
		   }
		   return position;
		  }
		 }
		};

		var ERRNO_MESSAGES = {
		 0: "Success",
		 1: "Arg list too long",
		 2: "Permission denied",
		 3: "Address already in use",
		 4: "Address not available",
		 5: "Address family not supported by protocol family",
		 6: "No more processes",
		 7: "Socket already connected",
		 8: "Bad file number",
		 9: "Trying to read unreadable message",
		 10: "Mount device busy",
		 11: "Operation canceled",
		 12: "No children",
		 13: "Connection aborted",
		 14: "Connection refused",
		 15: "Connection reset by peer",
		 16: "File locking deadlock error",
		 17: "Destination address required",
		 18: "Math arg out of domain of func",
		 19: "Quota exceeded",
		 20: "File exists",
		 21: "Bad address",
		 22: "File too large",
		 23: "Host is unreachable",
		 24: "Identifier removed",
		 25: "Illegal byte sequence",
		 26: "Connection already in progress",
		 27: "Interrupted system call",
		 28: "Invalid argument",
		 29: "I/O error",
		 30: "Socket is already connected",
		 31: "Is a directory",
		 32: "Too many symbolic links",
		 33: "Too many open files",
		 34: "Too many links",
		 35: "Message too long",
		 36: "Multihop attempted",
		 37: "File or path name too long",
		 38: "Network interface is not configured",
		 39: "Connection reset by network",
		 40: "Network is unreachable",
		 41: "Too many open files in system",
		 42: "No buffer space available",
		 43: "No such device",
		 44: "No such file or directory",
		 45: "Exec format error",
		 46: "No record locks available",
		 47: "The link has been severed",
		 48: "Not enough core",
		 49: "No message of desired type",
		 50: "Protocol not available",
		 51: "No space left on device",
		 52: "Function not implemented",
		 53: "Socket is not connected",
		 54: "Not a directory",
		 55: "Directory not empty",
		 56: "State not recoverable",
		 57: "Socket operation on non-socket",
		 59: "Not a typewriter",
		 60: "No such device or address",
		 61: "Value too large for defined data type",
		 62: "Previous owner died",
		 63: "Not super-user",
		 64: "Broken pipe",
		 65: "Protocol error",
		 66: "Unknown protocol",
		 67: "Protocol wrong type for socket",
		 68: "Math result not representable",
		 69: "Read only file system",
		 70: "Illegal seek",
		 71: "No such process",
		 72: "Stale file handle",
		 73: "Connection timed out",
		 74: "Text file busy",
		 75: "Cross-device link",
		 100: "Device not a stream",
		 101: "Bad font file fmt",
		 102: "Invalid slot",
		 103: "Invalid request code",
		 104: "No anode",
		 105: "Block device required",
		 106: "Channel number out of range",
		 107: "Level 3 halted",
		 108: "Level 3 reset",
		 109: "Link number out of range",
		 110: "Protocol driver not attached",
		 111: "No CSI structure available",
		 112: "Level 2 halted",
		 113: "Invalid exchange",
		 114: "Invalid request descriptor",
		 115: "Exchange full",
		 116: "No data (for no delay io)",
		 117: "Timer expired",
		 118: "Out of streams resources",
		 119: "Machine is not on the network",
		 120: "Package not installed",
		 121: "The object is remote",
		 122: "Advertise error",
		 123: "Srmount error",
		 124: "Communication error on send",
		 125: "Cross mount point (not really error)",
		 126: "Given log. name not unique",
		 127: "f.d. invalid for this operation",
		 128: "Remote address changed",
		 129: "Can   access a needed shared lib",
		 130: "Accessing a corrupted shared lib",
		 131: ".lib section in a.out corrupted",
		 132: "Attempting to link in too many libs",
		 133: "Attempting to exec a shared library",
		 135: "Streams pipe error",
		 136: "Too many users",
		 137: "Socket type not supported",
		 138: "Not supported",
		 139: "Protocol family not supported",
		 140: "Can't send after socket shutdown",
		 141: "Too many references",
		 142: "Host is down",
		 148: "No medium (in tape drive)",
		 156: "Level 2 not synchronized"
		};

		var ERRNO_CODES = {
		 EPERM: 63,
		 ENOENT: 44,
		 ESRCH: 71,
		 EINTR: 27,
		 EIO: 29,
		 ENXIO: 60,
		 E2BIG: 1,
		 ENOEXEC: 45,
		 EBADF: 8,
		 ECHILD: 12,
		 EAGAIN: 6,
		 EWOULDBLOCK: 6,
		 ENOMEM: 48,
		 EACCES: 2,
		 EFAULT: 21,
		 ENOTBLK: 105,
		 EBUSY: 10,
		 EEXIST: 20,
		 EXDEV: 75,
		 ENODEV: 43,
		 ENOTDIR: 54,
		 EISDIR: 31,
		 EINVAL: 28,
		 ENFILE: 41,
		 EMFILE: 33,
		 ENOTTY: 59,
		 ETXTBSY: 74,
		 EFBIG: 22,
		 ENOSPC: 51,
		 ESPIPE: 70,
		 EROFS: 69,
		 EMLINK: 34,
		 EPIPE: 64,
		 EDOM: 18,
		 ERANGE: 68,
		 ENOMSG: 49,
		 EIDRM: 24,
		 ECHRNG: 106,
		 EL2NSYNC: 156,
		 EL3HLT: 107,
		 EL3RST: 108,
		 ELNRNG: 109,
		 EUNATCH: 110,
		 ENOCSI: 111,
		 EL2HLT: 112,
		 EDEADLK: 16,
		 ENOLCK: 46,
		 EBADE: 113,
		 EBADR: 114,
		 EXFULL: 115,
		 ENOANO: 104,
		 EBADRQC: 103,
		 EBADSLT: 102,
		 EDEADLOCK: 16,
		 EBFONT: 101,
		 ENOSTR: 100,
		 ENODATA: 116,
		 ETIME: 117,
		 ENOSR: 118,
		 ENONET: 119,
		 ENOPKG: 120,
		 EREMOTE: 121,
		 ENOLINK: 47,
		 EADV: 122,
		 ESRMNT: 123,
		 ECOMM: 124,
		 EPROTO: 65,
		 EMULTIHOP: 36,
		 EDOTDOT: 125,
		 EBADMSG: 9,
		 ENOTUNIQ: 126,
		 EBADFD: 127,
		 EREMCHG: 128,
		 ELIBACC: 129,
		 ELIBBAD: 130,
		 ELIBSCN: 131,
		 ELIBMAX: 132,
		 ELIBEXEC: 133,
		 ENOSYS: 52,
		 ENOTEMPTY: 55,
		 ENAMETOOLONG: 37,
		 ELOOP: 32,
		 EOPNOTSUPP: 138,
		 EPFNOSUPPORT: 139,
		 ECONNRESET: 15,
		 ENOBUFS: 42,
		 EAFNOSUPPORT: 5,
		 EPROTOTYPE: 67,
		 ENOTSOCK: 57,
		 ENOPROTOOPT: 50,
		 ESHUTDOWN: 140,
		 ECONNREFUSED: 14,
		 EADDRINUSE: 3,
		 ECONNABORTED: 13,
		 ENETUNREACH: 40,
		 ENETDOWN: 38,
		 ETIMEDOUT: 73,
		 EHOSTDOWN: 142,
		 EHOSTUNREACH: 23,
		 EINPROGRESS: 26,
		 EALREADY: 7,
		 EDESTADDRREQ: 17,
		 EMSGSIZE: 35,
		 EPROTONOSUPPORT: 66,
		 ESOCKTNOSUPPORT: 137,
		 EADDRNOTAVAIL: 4,
		 ENETRESET: 39,
		 EISCONN: 30,
		 ENOTCONN: 53,
		 ETOOMANYREFS: 141,
		 EUSERS: 136,
		 EDQUOT: 19,
		 ESTALE: 72,
		 ENOTSUP: 138,
		 ENOMEDIUM: 148,
		 EILSEQ: 25,
		 EOVERFLOW: 61,
		 ECANCELED: 11,
		 ENOTRECOVERABLE: 56,
		 EOWNERDEAD: 62,
		 ESTRPIPE: 135
		};

		var FS = {
		 root: null,
		 mounts: [],
		 devices: {},
		 streams: [],
		 nextInode: 1,
		 nameTable: null,
		 currentPath: "/",
		 initialized: false,
		 ignorePermissions: true,
		 trackingDelegate: {},
		 tracking: {
		  openFlags: {
		   READ: 1,
		   WRITE: 2
		  }
		 },
		 ErrnoError: null,
		 genericErrors: {},
		 filesystems: null,
		 syncFSRequests: 0,
		 lookupPath: function(path, opts) {
		  path = PATH_FS.resolve(FS.cwd(), path);
		  opts = opts || {};
		  if (!path) return {
		   path: "",
		   node: null
		  };
		  var defaults = {
		   follow_mount: true,
		   recurse_count: 0
		  };
		  for (var key in defaults) {
		   if (opts[key] === undefined) {
		    opts[key] = defaults[key];
		   }
		  }
		  if (opts.recurse_count > 8) {
		   throw new FS.ErrnoError(32);
		  }
		  var parts = PATH.normalizeArray(path.split("/").filter(function(p) {
		   return !!p;
		  }), false);
		  var current = FS.root;
		  var current_path = "/";
		  for (var i = 0; i < parts.length; i++) {
		   var islast = i === parts.length - 1;
		   if (islast && opts.parent) {
		    break;
		   }
		   current = FS.lookupNode(current, parts[i]);
		   current_path = PATH.join2(current_path, parts[i]);
		   if (FS.isMountpoint(current)) {
		    if (!islast || islast && opts.follow_mount) {
		     current = current.mounted.root;
		    }
		   }
		   if (!islast || opts.follow) {
		    var count = 0;
		    while (FS.isLink(current.mode)) {
		     var link = FS.readlink(current_path);
		     current_path = PATH_FS.resolve(PATH.dirname(current_path), link);
		     var lookup = FS.lookupPath(current_path, {
		      recurse_count: opts.recurse_count
		     });
		     current = lookup.node;
		     if (count++ > 40) {
		      throw new FS.ErrnoError(32);
		     }
		    }
		   }
		  }
		  return {
		   path: current_path,
		   node: current
		  };
		 },
		 getPath: function(node) {
		  var path;
		  while (true) {
		   if (FS.isRoot(node)) {
		    var mount = node.mount.mountpoint;
		    if (!path) return mount;
		    return mount[mount.length - 1] !== "/" ? mount + "/" + path : mount + path;
		   }
		   path = path ? node.name + "/" + path : node.name;
		   node = node.parent;
		  }
		 },
		 hashName: function(parentid, name) {
		  var hash = 0;
		  for (var i = 0; i < name.length; i++) {
		   hash = (hash << 5) - hash + name.charCodeAt(i) | 0;
		  }
		  return (parentid + hash >>> 0) % FS.nameTable.length;
		 },
		 hashAddNode: function(node) {
		  var hash = FS.hashName(node.parent.id, node.name);
		  node.name_next = FS.nameTable[hash];
		  FS.nameTable[hash] = node;
		 },
		 hashRemoveNode: function(node) {
		  var hash = FS.hashName(node.parent.id, node.name);
		  if (FS.nameTable[hash] === node) {
		   FS.nameTable[hash] = node.name_next;
		  } else {
		   var current = FS.nameTable[hash];
		   while (current) {
		    if (current.name_next === node) {
		     current.name_next = node.name_next;
		     break;
		    }
		    current = current.name_next;
		   }
		  }
		 },
		 lookupNode: function(parent, name) {
		  var errCode = FS.mayLookup(parent);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode, parent);
		  }
		  var hash = FS.hashName(parent.id, name);
		  for (var node = FS.nameTable[hash]; node; node = node.name_next) {
		   var nodeName = node.name;
		   if (node.parent.id === parent.id && nodeName === name) {
		    return node;
		   }
		  }
		  return FS.lookup(parent, name);
		 },
		 createNode: function(parent, name, mode, rdev) {
		  assert(typeof parent === "object");
		  var node = new FS.FSNode(parent, name, mode, rdev);
		  FS.hashAddNode(node);
		  return node;
		 },
		 destroyNode: function(node) {
		  FS.hashRemoveNode(node);
		 },
		 isRoot: function(node) {
		  return node === node.parent;
		 },
		 isMountpoint: function(node) {
		  return !!node.mounted;
		 },
		 isFile: function(mode) {
		  return (mode & 61440) === 32768;
		 },
		 isDir: function(mode) {
		  return (mode & 61440) === 16384;
		 },
		 isLink: function(mode) {
		  return (mode & 61440) === 40960;
		 },
		 isChrdev: function(mode) {
		  return (mode & 61440) === 8192;
		 },
		 isBlkdev: function(mode) {
		  return (mode & 61440) === 24576;
		 },
		 isFIFO: function(mode) {
		  return (mode & 61440) === 4096;
		 },
		 isSocket: function(mode) {
		  return (mode & 49152) === 49152;
		 },
		 flagModes: {
		  "r": 0,
		  "r+": 2,
		  "w": 577,
		  "w+": 578,
		  "a": 1089,
		  "a+": 1090
		 },
		 modeStringToFlags: function(str) {
		  var flags = FS.flagModes[str];
		  if (typeof flags === "undefined") {
		   throw new Error("Unknown file open mode: " + str);
		  }
		  return flags;
		 },
		 flagsToPermissionString: function(flag) {
		  var perms = [ "r", "w", "rw" ][flag & 3];
		  if (flag & 512) {
		   perms += "w";
		  }
		  return perms;
		 },
		 nodePermissions: function(node, perms) {
		  if (FS.ignorePermissions) {
		   return 0;
		  }
		  if (perms.indexOf("r") !== -1 && !(node.mode & 292)) {
		   return 2;
		  } else if (perms.indexOf("w") !== -1 && !(node.mode & 146)) {
		   return 2;
		  } else if (perms.indexOf("x") !== -1 && !(node.mode & 73)) {
		   return 2;
		  }
		  return 0;
		 },
		 mayLookup: function(dir) {
		  var errCode = FS.nodePermissions(dir, "x");
		  if (errCode) return errCode;
		  if (!dir.node_ops.lookup) return 2;
		  return 0;
		 },
		 mayCreate: function(dir, name) {
		  try {
		   var node = FS.lookupNode(dir, name);
		   return 20;
		  } catch (e) {}
		  return FS.nodePermissions(dir, "wx");
		 },
		 mayDelete: function(dir, name, isdir) {
		  var node;
		  try {
		   node = FS.lookupNode(dir, name);
		  } catch (e) {
		   return e.errno;
		  }
		  var errCode = FS.nodePermissions(dir, "wx");
		  if (errCode) {
		   return errCode;
		  }
		  if (isdir) {
		   if (!FS.isDir(node.mode)) {
		    return 54;
		   }
		   if (FS.isRoot(node) || FS.getPath(node) === FS.cwd()) {
		    return 10;
		   }
		  } else {
		   if (FS.isDir(node.mode)) {
		    return 31;
		   }
		  }
		  return 0;
		 },
		 mayOpen: function(node, flags) {
		  if (!node) {
		   return 44;
		  }
		  if (FS.isLink(node.mode)) {
		   return 32;
		  } else if (FS.isDir(node.mode)) {
		   if (FS.flagsToPermissionString(flags) !== "r" || flags & 512) {
		    return 31;
		   }
		  }
		  return FS.nodePermissions(node, FS.flagsToPermissionString(flags));
		 },
		 MAX_OPEN_FDS: 4096,
		 nextfd: function(fd_start, fd_end) {
		  fd_start = fd_start || 0;
		  fd_end = fd_end || FS.MAX_OPEN_FDS;
		  for (var fd = fd_start; fd <= fd_end; fd++) {
		   if (!FS.streams[fd]) {
		    return fd;
		   }
		  }
		  throw new FS.ErrnoError(33);
		 },
		 getStream: function(fd) {
		  return FS.streams[fd];
		 },
		 createStream: function(stream, fd_start, fd_end) {
		  if (!FS.FSStream) {
		   FS.FSStream = function() {};
		   FS.FSStream.prototype = {
		    object: {
		     get: function() {
		      return this.node;
		     },
		     set: function(val) {
		      this.node = val;
		     }
		    },
		    isRead: {
		     get: function() {
		      return (this.flags & 2097155) !== 1;
		     }
		    },
		    isWrite: {
		     get: function() {
		      return (this.flags & 2097155) !== 0;
		     }
		    },
		    isAppend: {
		     get: function() {
		      return this.flags & 1024;
		     }
		    }
		   };
		  }
		  var newStream = new FS.FSStream();
		  for (var p in stream) {
		   newStream[p] = stream[p];
		  }
		  stream = newStream;
		  var fd = FS.nextfd(fd_start, fd_end);
		  stream.fd = fd;
		  FS.streams[fd] = stream;
		  return stream;
		 },
		 closeStream: function(fd) {
		  FS.streams[fd] = null;
		 },
		 chrdev_stream_ops: {
		  open: function(stream) {
		   var device = FS.getDevice(stream.node.rdev);
		   stream.stream_ops = device.stream_ops;
		   if (stream.stream_ops.open) {
		    stream.stream_ops.open(stream);
		   }
		  },
		  llseek: function() {
		   throw new FS.ErrnoError(70);
		  }
		 },
		 major: function(dev) {
		  return dev >> 8;
		 },
		 minor: function(dev) {
		  return dev & 255;
		 },
		 makedev: function(ma, mi) {
		  return ma << 8 | mi;
		 },
		 registerDevice: function(dev, ops) {
		  FS.devices[dev] = {
		   stream_ops: ops
		  };
		 },
		 getDevice: function(dev) {
		  return FS.devices[dev];
		 },
		 getMounts: function(mount) {
		  var mounts = [];
		  var check = [ mount ];
		  while (check.length) {
		   var m = check.pop();
		   mounts.push(m);
		   check.push.apply(check, m.mounts);
		  }
		  return mounts;
		 },
		 syncfs: function(populate, callback) {
		  if (typeof populate === "function") {
		   callback = populate;
		   populate = false;
		  }
		  FS.syncFSRequests++;
		  if (FS.syncFSRequests > 1) {
		   err("warning: " + FS.syncFSRequests + " FS.syncfs operations in flight at once, probably just doing extra work");
		  }
		  var mounts = FS.getMounts(FS.root.mount);
		  var completed = 0;
		  function doCallback(errCode) {
		   assert(FS.syncFSRequests > 0);
		   FS.syncFSRequests--;
		   return callback(errCode);
		  }
		  function done(errCode) {
		   if (errCode) {
		    if (!done.errored) {
		     done.errored = true;
		     return doCallback(errCode);
		    }
		    return;
		   }
		   if (++completed >= mounts.length) {
		    doCallback(null);
		   }
		  }
		  mounts.forEach(function(mount) {
		   if (!mount.type.syncfs) {
		    return done(null);
		   }
		   mount.type.syncfs(mount, populate, done);
		  });
		 },
		 mount: function(type, opts, mountpoint) {
		  if (typeof type === "string") {
		   throw type;
		  }
		  var root = mountpoint === "/";
		  var pseudo = !mountpoint;
		  var node;
		  if (root && FS.root) {
		   throw new FS.ErrnoError(10);
		  } else if (!root && !pseudo) {
		   var lookup = FS.lookupPath(mountpoint, {
		    follow_mount: false
		   });
		   mountpoint = lookup.path;
		   node = lookup.node;
		   if (FS.isMountpoint(node)) {
		    throw new FS.ErrnoError(10);
		   }
		   if (!FS.isDir(node.mode)) {
		    throw new FS.ErrnoError(54);
		   }
		  }
		  var mount = {
		   type: type,
		   opts: opts,
		   mountpoint: mountpoint,
		   mounts: []
		  };
		  var mountRoot = type.mount(mount);
		  mountRoot.mount = mount;
		  mount.root = mountRoot;
		  if (root) {
		   FS.root = mountRoot;
		  } else if (node) {
		   node.mounted = mount;
		   if (node.mount) {
		    node.mount.mounts.push(mount);
		   }
		  }
		  return mountRoot;
		 },
		 unmount: function(mountpoint) {
		  var lookup = FS.lookupPath(mountpoint, {
		   follow_mount: false
		  });
		  if (!FS.isMountpoint(lookup.node)) {
		   throw new FS.ErrnoError(28);
		  }
		  var node = lookup.node;
		  var mount = node.mounted;
		  var mounts = FS.getMounts(mount);
		  Object.keys(FS.nameTable).forEach(function(hash) {
		   var current = FS.nameTable[hash];
		   while (current) {
		    var next = current.name_next;
		    if (mounts.indexOf(current.mount) !== -1) {
		     FS.destroyNode(current);
		    }
		    current = next;
		   }
		  });
		  node.mounted = null;
		  var idx = node.mount.mounts.indexOf(mount);
		  assert(idx !== -1);
		  node.mount.mounts.splice(idx, 1);
		 },
		 lookup: function(parent, name) {
		  return parent.node_ops.lookup(parent, name);
		 },
		 mknod: function(path, mode, dev) {
		  var lookup = FS.lookupPath(path, {
		   parent: true
		  });
		  var parent = lookup.node;
		  var name = PATH.basename(path);
		  if (!name || name === "." || name === "..") {
		   throw new FS.ErrnoError(28);
		  }
		  var errCode = FS.mayCreate(parent, name);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  if (!parent.node_ops.mknod) {
		   throw new FS.ErrnoError(63);
		  }
		  return parent.node_ops.mknod(parent, name, mode, dev);
		 },
		 create: function(path, mode) {
		  mode = mode !== undefined ? mode : 438;
		  mode &= 4095;
		  mode |= 32768;
		  return FS.mknod(path, mode, 0);
		 },
		 mkdir: function(path, mode) {
		  mode = mode !== undefined ? mode : 511;
		  mode &= 511 | 512;
		  mode |= 16384;
		  return FS.mknod(path, mode, 0);
		 },
		 mkdirTree: function(path, mode) {
		  var dirs = path.split("/");
		  var d = "";
		  for (var i = 0; i < dirs.length; ++i) {
		   if (!dirs[i]) continue;
		   d += "/" + dirs[i];
		   try {
		    FS.mkdir(d, mode);
		   } catch (e) {
		    if (e.errno != 20) throw e;
		   }
		  }
		 },
		 mkdev: function(path, mode, dev) {
		  if (typeof dev === "undefined") {
		   dev = mode;
		   mode = 438;
		  }
		  mode |= 8192;
		  return FS.mknod(path, mode, dev);
		 },
		 symlink: function(oldpath, newpath) {
		  if (!PATH_FS.resolve(oldpath)) {
		   throw new FS.ErrnoError(44);
		  }
		  var lookup = FS.lookupPath(newpath, {
		   parent: true
		  });
		  var parent = lookup.node;
		  if (!parent) {
		   throw new FS.ErrnoError(44);
		  }
		  var newname = PATH.basename(newpath);
		  var errCode = FS.mayCreate(parent, newname);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  if (!parent.node_ops.symlink) {
		   throw new FS.ErrnoError(63);
		  }
		  return parent.node_ops.symlink(parent, newname, oldpath);
		 },
		 rename: function(old_path, new_path) {
		  var old_dirname = PATH.dirname(old_path);
		  var new_dirname = PATH.dirname(new_path);
		  var old_name = PATH.basename(old_path);
		  var new_name = PATH.basename(new_path);
		  var lookup, old_dir, new_dir;
		  lookup = FS.lookupPath(old_path, {
		   parent: true
		  });
		  old_dir = lookup.node;
		  lookup = FS.lookupPath(new_path, {
		   parent: true
		  });
		  new_dir = lookup.node;
		  if (!old_dir || !new_dir) throw new FS.ErrnoError(44);
		  if (old_dir.mount !== new_dir.mount) {
		   throw new FS.ErrnoError(75);
		  }
		  var old_node = FS.lookupNode(old_dir, old_name);
		  var relative = PATH_FS.relative(old_path, new_dirname);
		  if (relative.charAt(0) !== ".") {
		   throw new FS.ErrnoError(28);
		  }
		  relative = PATH_FS.relative(new_path, old_dirname);
		  if (relative.charAt(0) !== ".") {
		   throw new FS.ErrnoError(55);
		  }
		  var new_node;
		  try {
		   new_node = FS.lookupNode(new_dir, new_name);
		  } catch (e) {}
		  if (old_node === new_node) {
		   return;
		  }
		  var isdir = FS.isDir(old_node.mode);
		  var errCode = FS.mayDelete(old_dir, old_name, isdir);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  errCode = new_node ? FS.mayDelete(new_dir, new_name, isdir) : FS.mayCreate(new_dir, new_name);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  if (!old_dir.node_ops.rename) {
		   throw new FS.ErrnoError(63);
		  }
		  if (FS.isMountpoint(old_node) || new_node && FS.isMountpoint(new_node)) {
		   throw new FS.ErrnoError(10);
		  }
		  if (new_dir !== old_dir) {
		   errCode = FS.nodePermissions(old_dir, "w");
		   if (errCode) {
		    throw new FS.ErrnoError(errCode);
		   }
		  }
		  try {
		   if (FS.trackingDelegate["willMovePath"]) {
		    FS.trackingDelegate["willMovePath"](old_path, new_path);
		   }
		  } catch (e) {
		   err("FS.trackingDelegate['willMovePath']('" + old_path + "', '" + new_path + "') threw an exception: " + e.message);
		  }
		  FS.hashRemoveNode(old_node);
		  try {
		   old_dir.node_ops.rename(old_node, new_dir, new_name);
		  } catch (e) {
		   throw e;
		  } finally {
		   FS.hashAddNode(old_node);
		  }
		  try {
		   if (FS.trackingDelegate["onMovePath"]) FS.trackingDelegate["onMovePath"](old_path, new_path);
		  } catch (e) {
		   err("FS.trackingDelegate['onMovePath']('" + old_path + "', '" + new_path + "') threw an exception: " + e.message);
		  }
		 },
		 rmdir: function(path) {
		  var lookup = FS.lookupPath(path, {
		   parent: true
		  });
		  var parent = lookup.node;
		  var name = PATH.basename(path);
		  var node = FS.lookupNode(parent, name);
		  var errCode = FS.mayDelete(parent, name, true);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  if (!parent.node_ops.rmdir) {
		   throw new FS.ErrnoError(63);
		  }
		  if (FS.isMountpoint(node)) {
		   throw new FS.ErrnoError(10);
		  }
		  try {
		   if (FS.trackingDelegate["willDeletePath"]) {
		    FS.trackingDelegate["willDeletePath"](path);
		   }
		  } catch (e) {
		   err("FS.trackingDelegate['willDeletePath']('" + path + "') threw an exception: " + e.message);
		  }
		  parent.node_ops.rmdir(parent, name);
		  FS.destroyNode(node);
		  try {
		   if (FS.trackingDelegate["onDeletePath"]) FS.trackingDelegate["onDeletePath"](path);
		  } catch (e) {
		   err("FS.trackingDelegate['onDeletePath']('" + path + "') threw an exception: " + e.message);
		  }
		 },
		 readdir: function(path) {
		  var lookup = FS.lookupPath(path, {
		   follow: true
		  });
		  var node = lookup.node;
		  if (!node.node_ops.readdir) {
		   throw new FS.ErrnoError(54);
		  }
		  return node.node_ops.readdir(node);
		 },
		 unlink: function(path) {
		  var lookup = FS.lookupPath(path, {
		   parent: true
		  });
		  var parent = lookup.node;
		  var name = PATH.basename(path);
		  var node = FS.lookupNode(parent, name);
		  var errCode = FS.mayDelete(parent, name, false);
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  if (!parent.node_ops.unlink) {
		   throw new FS.ErrnoError(63);
		  }
		  if (FS.isMountpoint(node)) {
		   throw new FS.ErrnoError(10);
		  }
		  try {
		   if (FS.trackingDelegate["willDeletePath"]) {
		    FS.trackingDelegate["willDeletePath"](path);
		   }
		  } catch (e) {
		   err("FS.trackingDelegate['willDeletePath']('" + path + "') threw an exception: " + e.message);
		  }
		  parent.node_ops.unlink(parent, name);
		  FS.destroyNode(node);
		  try {
		   if (FS.trackingDelegate["onDeletePath"]) FS.trackingDelegate["onDeletePath"](path);
		  } catch (e) {
		   err("FS.trackingDelegate['onDeletePath']('" + path + "') threw an exception: " + e.message);
		  }
		 },
		 readlink: function(path) {
		  var lookup = FS.lookupPath(path);
		  var link = lookup.node;
		  if (!link) {
		   throw new FS.ErrnoError(44);
		  }
		  if (!link.node_ops.readlink) {
		   throw new FS.ErrnoError(28);
		  }
		  return PATH_FS.resolve(FS.getPath(link.parent), link.node_ops.readlink(link));
		 },
		 stat: function(path, dontFollow) {
		  var lookup = FS.lookupPath(path, {
		   follow: !dontFollow
		  });
		  var node = lookup.node;
		  if (!node) {
		   throw new FS.ErrnoError(44);
		  }
		  if (!node.node_ops.getattr) {
		   throw new FS.ErrnoError(63);
		  }
		  return node.node_ops.getattr(node);
		 },
		 lstat: function(path) {
		  return FS.stat(path, true);
		 },
		 chmod: function(path, mode, dontFollow) {
		  var node;
		  if (typeof path === "string") {
		   var lookup = FS.lookupPath(path, {
		    follow: !dontFollow
		   });
		   node = lookup.node;
		  } else {
		   node = path;
		  }
		  if (!node.node_ops.setattr) {
		   throw new FS.ErrnoError(63);
		  }
		  node.node_ops.setattr(node, {
		   mode: mode & 4095 | node.mode & ~4095,
		   timestamp: Date.now()
		  });
		 },
		 lchmod: function(path, mode) {
		  FS.chmod(path, mode, true);
		 },
		 fchmod: function(fd, mode) {
		  var stream = FS.getStream(fd);
		  if (!stream) {
		   throw new FS.ErrnoError(8);
		  }
		  FS.chmod(stream.node, mode);
		 },
		 chown: function(path, uid, gid, dontFollow) {
		  var node;
		  if (typeof path === "string") {
		   var lookup = FS.lookupPath(path, {
		    follow: !dontFollow
		   });
		   node = lookup.node;
		  } else {
		   node = path;
		  }
		  if (!node.node_ops.setattr) {
		   throw new FS.ErrnoError(63);
		  }
		  node.node_ops.setattr(node, {
		   timestamp: Date.now()
		  });
		 },
		 lchown: function(path, uid, gid) {
		  FS.chown(path, uid, gid, true);
		 },
		 fchown: function(fd, uid, gid) {
		  var stream = FS.getStream(fd);
		  if (!stream) {
		   throw new FS.ErrnoError(8);
		  }
		  FS.chown(stream.node, uid, gid);
		 },
		 truncate: function(path, len) {
		  if (len < 0) {
		   throw new FS.ErrnoError(28);
		  }
		  var node;
		  if (typeof path === "string") {
		   var lookup = FS.lookupPath(path, {
		    follow: true
		   });
		   node = lookup.node;
		  } else {
		   node = path;
		  }
		  if (!node.node_ops.setattr) {
		   throw new FS.ErrnoError(63);
		  }
		  if (FS.isDir(node.mode)) {
		   throw new FS.ErrnoError(31);
		  }
		  if (!FS.isFile(node.mode)) {
		   throw new FS.ErrnoError(28);
		  }
		  var errCode = FS.nodePermissions(node, "w");
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  node.node_ops.setattr(node, {
		   size: len,
		   timestamp: Date.now()
		  });
		 },
		 ftruncate: function(fd, len) {
		  var stream = FS.getStream(fd);
		  if (!stream) {
		   throw new FS.ErrnoError(8);
		  }
		  if ((stream.flags & 2097155) === 0) {
		   throw new FS.ErrnoError(28);
		  }
		  FS.truncate(stream.node, len);
		 },
		 utime: function(path, atime, mtime) {
		  var lookup = FS.lookupPath(path, {
		   follow: true
		  });
		  var node = lookup.node;
		  node.node_ops.setattr(node, {
		   timestamp: Math.max(atime, mtime)
		  });
		 },
		 open: function(path, flags, mode, fd_start, fd_end) {
		  if (path === "") {
		   throw new FS.ErrnoError(44);
		  }
		  flags = typeof flags === "string" ? FS.modeStringToFlags(flags) : flags;
		  mode = typeof mode === "undefined" ? 438 : mode;
		  if (flags & 64) {
		   mode = mode & 4095 | 32768;
		  } else {
		   mode = 0;
		  }
		  var node;
		  if (typeof path === "object") {
		   node = path;
		  } else {
		   path = PATH.normalize(path);
		   try {
		    var lookup = FS.lookupPath(path, {
		     follow: !(flags & 131072)
		    });
		    node = lookup.node;
		   } catch (e) {}
		  }
		  var created = false;
		  if (flags & 64) {
		   if (node) {
		    if (flags & 128) {
		     throw new FS.ErrnoError(20);
		    }
		   } else {
		    node = FS.mknod(path, mode, 0);
		    created = true;
		   }
		  }
		  if (!node) {
		   throw new FS.ErrnoError(44);
		  }
		  if (FS.isChrdev(node.mode)) {
		   flags &= ~512;
		  }
		  if (flags & 65536 && !FS.isDir(node.mode)) {
		   throw new FS.ErrnoError(54);
		  }
		  if (!created) {
		   var errCode = FS.mayOpen(node, flags);
		   if (errCode) {
		    throw new FS.ErrnoError(errCode);
		   }
		  }
		  if (flags & 512) {
		   FS.truncate(node, 0);
		  }
		  flags &= ~(128 | 512 | 131072);
		  var stream = FS.createStream({
		   node: node,
		   path: FS.getPath(node),
		   flags: flags,
		   seekable: true,
		   position: 0,
		   stream_ops: node.stream_ops,
		   ungotten: [],
		   error: false
		  }, fd_start, fd_end);
		  if (stream.stream_ops.open) {
		   stream.stream_ops.open(stream);
		  }
		  if (Module["logReadFiles"] && !(flags & 1)) {
		   if (!FS.readFiles) FS.readFiles = {};
		   if (!(path in FS.readFiles)) {
		    FS.readFiles[path] = 1;
		    err("FS.trackingDelegate error on read file: " + path);
		   }
		  }
		  try {
		   if (FS.trackingDelegate["onOpenFile"]) {
		    var trackingFlags = 0;
		    if ((flags & 2097155) !== 1) {
		     trackingFlags |= FS.tracking.openFlags.READ;
		    }
		    if ((flags & 2097155) !== 0) {
		     trackingFlags |= FS.tracking.openFlags.WRITE;
		    }
		    FS.trackingDelegate["onOpenFile"](path, trackingFlags);
		   }
		  } catch (e) {
		   err("FS.trackingDelegate['onOpenFile']('" + path + "', flags) threw an exception: " + e.message);
		  }
		  return stream;
		 },
		 close: function(stream) {
		  if (FS.isClosed(stream)) {
		   throw new FS.ErrnoError(8);
		  }
		  if (stream.getdents) stream.getdents = null;
		  try {
		   if (stream.stream_ops.close) {
		    stream.stream_ops.close(stream);
		   }
		  } catch (e) {
		   throw e;
		  } finally {
		   FS.closeStream(stream.fd);
		  }
		  stream.fd = null;
		 },
		 isClosed: function(stream) {
		  return stream.fd === null;
		 },
		 llseek: function(stream, offset, whence) {
		  if (FS.isClosed(stream)) {
		   throw new FS.ErrnoError(8);
		  }
		  if (!stream.seekable || !stream.stream_ops.llseek) {
		   throw new FS.ErrnoError(70);
		  }
		  if (whence != 0 && whence != 1 && whence != 2) {
		   throw new FS.ErrnoError(28);
		  }
		  stream.position = stream.stream_ops.llseek(stream, offset, whence);
		  stream.ungotten = [];
		  return stream.position;
		 },
		 read: function(stream, buffer, offset, length, position) {
		  if (length < 0 || position < 0) {
		   throw new FS.ErrnoError(28);
		  }
		  if (FS.isClosed(stream)) {
		   throw new FS.ErrnoError(8);
		  }
		  if ((stream.flags & 2097155) === 1) {
		   throw new FS.ErrnoError(8);
		  }
		  if (FS.isDir(stream.node.mode)) {
		   throw new FS.ErrnoError(31);
		  }
		  if (!stream.stream_ops.read) {
		   throw new FS.ErrnoError(28);
		  }
		  var seeking = typeof position !== "undefined";
		  if (!seeking) {
		   position = stream.position;
		  } else if (!stream.seekable) {
		   throw new FS.ErrnoError(70);
		  }
		  var bytesRead = stream.stream_ops.read(stream, buffer, offset, length, position);
		  if (!seeking) stream.position += bytesRead;
		  return bytesRead;
		 },
		 write: function(stream, buffer, offset, length, position, canOwn) {
		  if (length < 0 || position < 0) {
		   throw new FS.ErrnoError(28);
		  }
		  if (FS.isClosed(stream)) {
		   throw new FS.ErrnoError(8);
		  }
		  if ((stream.flags & 2097155) === 0) {
		   throw new FS.ErrnoError(8);
		  }
		  if (FS.isDir(stream.node.mode)) {
		   throw new FS.ErrnoError(31);
		  }
		  if (!stream.stream_ops.write) {
		   throw new FS.ErrnoError(28);
		  }
		  if (stream.seekable && stream.flags & 1024) {
		   FS.llseek(stream, 0, 2);
		  }
		  var seeking = typeof position !== "undefined";
		  if (!seeking) {
		   position = stream.position;
		  } else if (!stream.seekable) {
		   throw new FS.ErrnoError(70);
		  }
		  var bytesWritten = stream.stream_ops.write(stream, buffer, offset, length, position, canOwn);
		  if (!seeking) stream.position += bytesWritten;
		  try {
		   if (stream.path && FS.trackingDelegate["onWriteToFile"]) FS.trackingDelegate["onWriteToFile"](stream.path);
		  } catch (e) {
		   err("FS.trackingDelegate['onWriteToFile']('" + stream.path + "') threw an exception: " + e.message);
		  }
		  return bytesWritten;
		 },
		 allocate: function(stream, offset, length) {
		  if (FS.isClosed(stream)) {
		   throw new FS.ErrnoError(8);
		  }
		  if (offset < 0 || length <= 0) {
		   throw new FS.ErrnoError(28);
		  }
		  if ((stream.flags & 2097155) === 0) {
		   throw new FS.ErrnoError(8);
		  }
		  if (!FS.isFile(stream.node.mode) && !FS.isDir(stream.node.mode)) {
		   throw new FS.ErrnoError(43);
		  }
		  if (!stream.stream_ops.allocate) {
		   throw new FS.ErrnoError(138);
		  }
		  stream.stream_ops.allocate(stream, offset, length);
		 },
		 mmap: function(stream, address, length, position, prot, flags) {
		  if ((prot & 2) !== 0 && (flags & 2) === 0 && (stream.flags & 2097155) !== 2) {
		   throw new FS.ErrnoError(2);
		  }
		  if ((stream.flags & 2097155) === 1) {
		   throw new FS.ErrnoError(2);
		  }
		  if (!stream.stream_ops.mmap) {
		   throw new FS.ErrnoError(43);
		  }
		  return stream.stream_ops.mmap(stream, address, length, position, prot, flags);
		 },
		 msync: function(stream, buffer, offset, length, mmapFlags) {
		  if (!stream || !stream.stream_ops.msync) {
		   return 0;
		  }
		  return stream.stream_ops.msync(stream, buffer, offset, length, mmapFlags);
		 },
		 munmap: function(stream) {
		  return 0;
		 },
		 ioctl: function(stream, cmd, arg) {
		  if (!stream.stream_ops.ioctl) {
		   throw new FS.ErrnoError(59);
		  }
		  return stream.stream_ops.ioctl(stream, cmd, arg);
		 },
		 readFile: function(path, opts) {
		  opts = opts || {};
		  opts.flags = opts.flags || 0;
		  opts.encoding = opts.encoding || "binary";
		  if (opts.encoding !== "utf8" && opts.encoding !== "binary") {
		   throw new Error('Invalid encoding type "' + opts.encoding + '"');
		  }
		  var ret;
		  var stream = FS.open(path, opts.flags);
		  var stat = FS.stat(path);
		  var length = stat.size;
		  var buf = new Uint8Array(length);
		  FS.read(stream, buf, 0, length, 0);
		  if (opts.encoding === "utf8") {
		   ret = UTF8ArrayToString(buf, 0);
		  } else if (opts.encoding === "binary") {
		   ret = buf;
		  }
		  FS.close(stream);
		  return ret;
		 },
		 writeFile: function(path, data, opts) {
		  opts = opts || {};
		  opts.flags = opts.flags || 577;
		  var stream = FS.open(path, opts.flags, opts.mode);
		  if (typeof data === "string") {
		   var buf = new Uint8Array(lengthBytesUTF8(data) + 1);
		   var actualNumBytes = stringToUTF8Array(data, buf, 0, buf.length);
		   FS.write(stream, buf, 0, actualNumBytes, undefined, opts.canOwn);
		  } else if (ArrayBuffer.isView(data)) {
		   FS.write(stream, data, 0, data.byteLength, undefined, opts.canOwn);
		  } else {
		   throw new Error("Unsupported data type");
		  }
		  FS.close(stream);
		 },
		 cwd: function() {
		  return FS.currentPath;
		 },
		 chdir: function(path) {
		  var lookup = FS.lookupPath(path, {
		   follow: true
		  });
		  if (lookup.node === null) {
		   throw new FS.ErrnoError(44);
		  }
		  if (!FS.isDir(lookup.node.mode)) {
		   throw new FS.ErrnoError(54);
		  }
		  var errCode = FS.nodePermissions(lookup.node, "x");
		  if (errCode) {
		   throw new FS.ErrnoError(errCode);
		  }
		  FS.currentPath = lookup.path;
		 },
		 createDefaultDirectories: function() {
		  FS.mkdir("/tmp");
		  FS.mkdir("/home");
		  FS.mkdir("/home/web_user");
		 },
		 createDefaultDevices: function() {
		  FS.mkdir("/dev");
		  FS.registerDevice(FS.makedev(1, 3), {
		   read: function() {
		    return 0;
		   },
		   write: function(stream, buffer, offset, length, pos) {
		    return length;
		   }
		  });
		  FS.mkdev("/dev/null", FS.makedev(1, 3));
		  TTY.register(FS.makedev(5, 0), TTY.default_tty_ops);
		  TTY.register(FS.makedev(6, 0), TTY.default_tty1_ops);
		  FS.mkdev("/dev/tty", FS.makedev(5, 0));
		  FS.mkdev("/dev/tty1", FS.makedev(6, 0));
		  var random_device = getRandomDevice();
		  FS.createDevice("/dev", "random", random_device);
		  FS.createDevice("/dev", "urandom", random_device);
		  FS.mkdir("/dev/shm");
		  FS.mkdir("/dev/shm/tmp");
		 },
		 createSpecialDirectories: function() {
		  FS.mkdir("/proc");
		  var proc_self = FS.mkdir("/proc/self");
		  FS.mkdir("/proc/self/fd");
		  FS.mount({
		   mount: function() {
		    var node = FS.createNode(proc_self, "fd", 16384 | 511, 73);
		    node.node_ops = {
		     lookup: function(parent, name) {
		      var fd = +name;
		      var stream = FS.getStream(fd);
		      if (!stream) throw new FS.ErrnoError(8);
		      var ret = {
		       parent: null,
		       mount: {
		        mountpoint: "fake"
		       },
		       node_ops: {
		        readlink: function() {
		         return stream.path;
		        }
		       }
		      };
		      ret.parent = ret;
		      return ret;
		     }
		    };
		    return node;
		   }
		  }, {}, "/proc/self/fd");
		 },
		 createStandardStreams: function() {
		  if (Module["stdin"]) {
		   FS.createDevice("/dev", "stdin", Module["stdin"]);
		  } else {
		   FS.symlink("/dev/tty", "/dev/stdin");
		  }
		  if (Module["stdout"]) {
		   FS.createDevice("/dev", "stdout", null, Module["stdout"]);
		  } else {
		   FS.symlink("/dev/tty", "/dev/stdout");
		  }
		  if (Module["stderr"]) {
		   FS.createDevice("/dev", "stderr", null, Module["stderr"]);
		  } else {
		   FS.symlink("/dev/tty1", "/dev/stderr");
		  }
		  var stdin = FS.open("/dev/stdin", 0);
		  var stdout = FS.open("/dev/stdout", 1);
		  var stderr = FS.open("/dev/stderr", 1);
		  assert(stdin.fd === 0, "invalid handle for stdin (" + stdin.fd + ")");
		  assert(stdout.fd === 1, "invalid handle for stdout (" + stdout.fd + ")");
		  assert(stderr.fd === 2, "invalid handle for stderr (" + stderr.fd + ")");
		 },
		 ensureErrnoError: function() {
		  if (FS.ErrnoError) return;
		  FS.ErrnoError = function ErrnoError(errno, node) {
		   this.node = node;
		   this.setErrno = function(errno) {
		    this.errno = errno;
		    for (var key in ERRNO_CODES) {
		     if (ERRNO_CODES[key] === errno) {
		      this.code = key;
		      break;
		     }
		    }
		   };
		   this.setErrno(errno);
		   this.message = ERRNO_MESSAGES[errno];
		   if (this.stack) {
		    Object.defineProperty(this, "stack", {
		     value: new Error().stack,
		     writable: true
		    });
		    this.stack = demangleAll(this.stack);
		   }
		  };
		  FS.ErrnoError.prototype = new Error();
		  FS.ErrnoError.prototype.constructor = FS.ErrnoError;
		  [ 44 ].forEach(function(code) {
		   FS.genericErrors[code] = new FS.ErrnoError(code);
		   FS.genericErrors[code].stack = "<generic error, no stack>";
		  });
		 },
		 staticInit: function() {
		  FS.ensureErrnoError();
		  FS.nameTable = new Array(4096);
		  FS.mount(MEMFS, {}, "/");
		  FS.createDefaultDirectories();
		  FS.createDefaultDevices();
		  FS.createSpecialDirectories();
		  FS.filesystems = {
		   "MEMFS": MEMFS,
		   "WORKERFS": WORKERFS
		  };
		 },
		 init: function(input, output, error) {
		  assert(!FS.init.initialized, "FS.init was previously called. If you want to initialize later with custom parameters, remove any earlier calls (note that one is automatically added to the generated code)");
		  FS.init.initialized = true;
		  FS.ensureErrnoError();
		  Module["stdin"] = input || Module["stdin"];
		  Module["stdout"] = output || Module["stdout"];
		  Module["stderr"] = error || Module["stderr"];
		  FS.createStandardStreams();
		 },
		 quit: function() {
		  FS.init.initialized = false;
		  var fflush = Module["_fflush"];
		  if (fflush) fflush(0);
		  for (var i = 0; i < FS.streams.length; i++) {
		   var stream = FS.streams[i];
		   if (!stream) {
		    continue;
		   }
		   FS.close(stream);
		  }
		 },
		 getMode: function(canRead, canWrite) {
		  var mode = 0;
		  if (canRead) mode |= 292 | 73;
		  if (canWrite) mode |= 146;
		  return mode;
		 },
		 findObject: function(path, dontResolveLastLink) {
		  var ret = FS.analyzePath(path, dontResolveLastLink);
		  if (ret.exists) {
		   return ret.object;
		  } else {
		   return null;
		  }
		 },
		 analyzePath: function(path, dontResolveLastLink) {
		  try {
		   var lookup = FS.lookupPath(path, {
		    follow: !dontResolveLastLink
		   });
		   path = lookup.path;
		  } catch (e) {}
		  var ret = {
		   isRoot: false,
		   exists: false,
		   error: 0,
		   name: null,
		   path: null,
		   object: null,
		   parentExists: false,
		   parentPath: null,
		   parentObject: null
		  };
		  try {
		   var lookup = FS.lookupPath(path, {
		    parent: true
		   });
		   ret.parentExists = true;
		   ret.parentPath = lookup.path;
		   ret.parentObject = lookup.node;
		   ret.name = PATH.basename(path);
		   lookup = FS.lookupPath(path, {
		    follow: !dontResolveLastLink
		   });
		   ret.exists = true;
		   ret.path = lookup.path;
		   ret.object = lookup.node;
		   ret.name = lookup.node.name;
		   ret.isRoot = lookup.path === "/";
		  } catch (e) {
		   ret.error = e.errno;
		  }
		  return ret;
		 },
		 createPath: function(parent, path, canRead, canWrite) {
		  parent = typeof parent === "string" ? parent : FS.getPath(parent);
		  var parts = path.split("/").reverse();
		  while (parts.length) {
		   var part = parts.pop();
		   if (!part) continue;
		   var current = PATH.join2(parent, part);
		   try {
		    FS.mkdir(current);
		   } catch (e) {}
		   parent = current;
		  }
		  return current;
		 },
		 createFile: function(parent, name, properties, canRead, canWrite) {
		  var path = PATH.join2(typeof parent === "string" ? parent : FS.getPath(parent), name);
		  var mode = FS.getMode(canRead, canWrite);
		  return FS.create(path, mode);
		 },
		 createDataFile: function(parent, name, data, canRead, canWrite, canOwn) {
		  var path = name ? PATH.join2(typeof parent === "string" ? parent : FS.getPath(parent), name) : parent;
		  var mode = FS.getMode(canRead, canWrite);
		  var node = FS.create(path, mode);
		  if (data) {
		   if (typeof data === "string") {
		    var arr = new Array(data.length);
		    for (var i = 0, len = data.length; i < len; ++i) arr[i] = data.charCodeAt(i);
		    data = arr;
		   }
		   FS.chmod(node, mode | 146);
		   var stream = FS.open(node, 577);
		   FS.write(stream, data, 0, data.length, 0, canOwn);
		   FS.close(stream);
		   FS.chmod(node, mode);
		  }
		  return node;
		 },
		 createDevice: function(parent, name, input, output) {
		  var path = PATH.join2(typeof parent === "string" ? parent : FS.getPath(parent), name);
		  var mode = FS.getMode(!!input, !!output);
		  if (!FS.createDevice.major) FS.createDevice.major = 64;
		  var dev = FS.makedev(FS.createDevice.major++, 0);
		  FS.registerDevice(dev, {
		   open: function(stream) {
		    stream.seekable = false;
		   },
		   close: function(stream) {
		    if (output && output.buffer && output.buffer.length) {
		     output(10);
		    }
		   },
		   read: function(stream, buffer, offset, length, pos) {
		    var bytesRead = 0;
		    for (var i = 0; i < length; i++) {
		     var result;
		     try {
		      result = input();
		     } catch (e) {
		      throw new FS.ErrnoError(29);
		     }
		     if (result === undefined && bytesRead === 0) {
		      throw new FS.ErrnoError(6);
		     }
		     if (result === null || result === undefined) break;
		     bytesRead++;
		     buffer[offset + i] = result;
		    }
		    if (bytesRead) {
		     stream.node.timestamp = Date.now();
		    }
		    return bytesRead;
		   },
		   write: function(stream, buffer, offset, length, pos) {
		    for (var i = 0; i < length; i++) {
		     try {
		      output(buffer[offset + i]);
		     } catch (e) {
		      throw new FS.ErrnoError(29);
		     }
		    }
		    if (length) {
		     stream.node.timestamp = Date.now();
		    }
		    return i;
		   }
		  });
		  return FS.mkdev(path, mode, dev);
		 },
		 forceLoadFile: function(obj) {
		  if (obj.isDevice || obj.isFolder || obj.link || obj.contents) return true;
		  if (typeof XMLHttpRequest !== "undefined") {
		   throw new Error("Lazy loading should have been performed (contents set) in createLazyFile, but it was not. Lazy loading only works in web workers. Use --embed-file or --preload-file in emcc on the main thread.");
		  } else if (read_) {
		   try {
		    obj.contents = intArrayFromString(read_(obj.url), true);
		    obj.usedBytes = obj.contents.length;
		   } catch (e) {
		    throw new FS.ErrnoError(29);
		   }
		  } else {
		   throw new Error("Cannot load without read() or XMLHttpRequest.");
		  }
		 },
		 createLazyFile: function(parent, name, url, canRead, canWrite) {
		  function LazyUint8Array() {
		   this.lengthKnown = false;
		   this.chunks = [];
		  }
		  LazyUint8Array.prototype.get = function LazyUint8Array_get(idx) {
		   if (idx > this.length - 1 || idx < 0) {
		    return undefined;
		   }
		   var chunkOffset = idx % this.chunkSize;
		   var chunkNum = idx / this.chunkSize | 0;
		   return this.getter(chunkNum)[chunkOffset];
		  };
		  LazyUint8Array.prototype.setDataGetter = function LazyUint8Array_setDataGetter(getter) {
		   this.getter = getter;
		  };
		  LazyUint8Array.prototype.cacheLength = function LazyUint8Array_cacheLength() {
		   var xhr = new XMLHttpRequest();
		   xhr.open("HEAD", url, false);
		   xhr.send(null);
		   if (!(xhr.status >= 200 && xhr.status < 300 || xhr.status === 304)) throw new Error("Couldn't load " + url + ". Status: " + xhr.status);
		   var datalength = Number(xhr.getResponseHeader("Content-length"));
		   var header;
		   var hasByteServing = (header = xhr.getResponseHeader("Accept-Ranges")) && header === "bytes";
		   var usesGzip = (header = xhr.getResponseHeader("Content-Encoding")) && header === "gzip";
		   var chunkSize = 1024 * 1024;
		   if (!hasByteServing) chunkSize = datalength;
		   var doXHR = function(from, to) {
		    if (from > to) throw new Error("invalid range (" + from + ", " + to + ") or no bytes requested!");
		    if (to > datalength - 1) throw new Error("only " + datalength + " bytes available! programmer error!");
		    var xhr = new XMLHttpRequest();
		    xhr.open("GET", url, false);
		    if (datalength !== chunkSize) xhr.setRequestHeader("Range", "bytes=" + from + "-" + to);
		    if (typeof Uint8Array != "undefined") xhr.responseType = "arraybuffer";
		    if (xhr.overrideMimeType) {
		     xhr.overrideMimeType("text/plain; charset=x-user-defined");
		    }
		    xhr.send(null);
		    if (!(xhr.status >= 200 && xhr.status < 300 || xhr.status === 304)) throw new Error("Couldn't load " + url + ". Status: " + xhr.status);
		    if (xhr.response !== undefined) {
		     return new Uint8Array(xhr.response || []);
		    } else {
		     return intArrayFromString(xhr.responseText || "", true);
		    }
		   };
		   var lazyArray = this;
		   lazyArray.setDataGetter(function(chunkNum) {
		    var start = chunkNum * chunkSize;
		    var end = (chunkNum + 1) * chunkSize - 1;
		    end = Math.min(end, datalength - 1);
		    if (typeof lazyArray.chunks[chunkNum] === "undefined") {
		     lazyArray.chunks[chunkNum] = doXHR(start, end);
		    }
		    if (typeof lazyArray.chunks[chunkNum] === "undefined") throw new Error("doXHR failed!");
		    return lazyArray.chunks[chunkNum];
		   });
		   if (usesGzip || !datalength) {
		    chunkSize = datalength = 1;
		    datalength = this.getter(0).length;
		    chunkSize = datalength;
		    out("LazyFiles on gzip forces download of the whole file when length is accessed");
		   }
		   this._length = datalength;
		   this._chunkSize = chunkSize;
		   this.lengthKnown = true;
		  };
		  if (typeof XMLHttpRequest !== "undefined") {
		   if (!ENVIRONMENT_IS_WORKER) throw "Cannot do synchronous binary XHRs outside webworkers in modern browsers. Use --embed-file or --preload-file in emcc";
		   var lazyArray = new LazyUint8Array();
		   Object.defineProperties(lazyArray, {
		    length: {
		     get: function() {
		      if (!this.lengthKnown) {
		       this.cacheLength();
		      }
		      return this._length;
		     }
		    },
		    chunkSize: {
		     get: function() {
		      if (!this.lengthKnown) {
		       this.cacheLength();
		      }
		      return this._chunkSize;
		     }
		    }
		   });
		   var properties = {
		    isDevice: false,
		    contents: lazyArray
		   };
		  } else {
		   var properties = {
		    isDevice: false,
		    url: url
		   };
		  }
		  var node = FS.createFile(parent, name, properties, canRead, canWrite);
		  if (properties.contents) {
		   node.contents = properties.contents;
		  } else if (properties.url) {
		   node.contents = null;
		   node.url = properties.url;
		  }
		  Object.defineProperties(node, {
		   usedBytes: {
		    get: function() {
		     return this.contents.length;
		    }
		   }
		  });
		  var stream_ops = {};
		  var keys = Object.keys(node.stream_ops);
		  keys.forEach(function(key) {
		   var fn = node.stream_ops[key];
		   stream_ops[key] = function forceLoadLazyFile() {
		    FS.forceLoadFile(node);
		    return fn.apply(null, arguments);
		   };
		  });
		  stream_ops.read = function stream_ops_read(stream, buffer, offset, length, position) {
		   FS.forceLoadFile(node);
		   var contents = stream.node.contents;
		   if (position >= contents.length) return 0;
		   var size = Math.min(contents.length - position, length);
		   assert(size >= 0);
		   if (contents.slice) {
		    for (var i = 0; i < size; i++) {
		     buffer[offset + i] = contents[position + i];
		    }
		   } else {
		    for (var i = 0; i < size; i++) {
		     buffer[offset + i] = contents.get(position + i);
		    }
		   }
		   return size;
		  };
		  node.stream_ops = stream_ops;
		  return node;
		 },
		 createPreloadedFile: function(parent, name, url, canRead, canWrite, onload, onerror, dontCreateFile, canOwn, preFinish) {
		  Browser.init();
		  var fullname = name ? PATH_FS.resolve(PATH.join2(parent, name)) : parent;
		  var dep = getUniqueRunDependency("cp " + fullname);
		  function processData(byteArray) {
		   function finish(byteArray) {
		    if (preFinish) preFinish();
		    if (!dontCreateFile) {
		     FS.createDataFile(parent, name, byteArray, canRead, canWrite, canOwn);
		    }
		    if (onload) onload();
		    removeRunDependency(dep);
		   }
		   var handled = false;
		   Module["preloadPlugins"].forEach(function(plugin) {
		    if (handled) return;
		    if (plugin["canHandle"](fullname)) {
		     plugin["handle"](byteArray, fullname, finish, function() {
		      if (onerror) onerror();
		      removeRunDependency(dep);
		     });
		     handled = true;
		    }
		   });
		   if (!handled) finish(byteArray);
		  }
		  addRunDependency(dep);
		  if (typeof url == "string") {
		   Browser.asyncLoad(url, function(byteArray) {
		    processData(byteArray);
		   }, onerror);
		  } else {
		   processData(url);
		  }
		 },
		 indexedDB: function() {
		  return window.indexedDB || window.mozIndexedDB || window.webkitIndexedDB || window.msIndexedDB;
		 },
		 DB_NAME: function() {
		  return "EM_FS_" + window.location.pathname;
		 },
		 DB_VERSION: 20,
		 DB_STORE_NAME: "FILE_DATA",
		 saveFilesToDB: function(paths, onload, onerror) {
		  onload = onload || function() {};
		  onerror = onerror || function() {};
		  var indexedDB = FS.indexedDB();
		  try {
		   var openRequest = indexedDB.open(FS.DB_NAME(), FS.DB_VERSION);
		  } catch (e) {
		   return onerror(e);
		  }
		  openRequest.onupgradeneeded = function openRequest_onupgradeneeded() {
		   out("creating db");
		   var db = openRequest.result;
		   db.createObjectStore(FS.DB_STORE_NAME);
		  };
		  openRequest.onsuccess = function openRequest_onsuccess() {
		   var db = openRequest.result;
		   var transaction = db.transaction([ FS.DB_STORE_NAME ], "readwrite");
		   var files = transaction.objectStore(FS.DB_STORE_NAME);
		   var ok = 0, fail = 0, total = paths.length;
		   function finish() {
		    if (fail == 0) onload(); else onerror();
		   }
		   paths.forEach(function(path) {
		    var putRequest = files.put(FS.analyzePath(path).object.contents, path);
		    putRequest.onsuccess = function putRequest_onsuccess() {
		     ok++;
		     if (ok + fail == total) finish();
		    };
		    putRequest.onerror = function putRequest_onerror() {
		     fail++;
		     if (ok + fail == total) finish();
		    };
		   });
		   transaction.onerror = onerror;
		  };
		  openRequest.onerror = onerror;
		 },
		 loadFilesFromDB: function(paths, onload, onerror) {
		  onload = onload || function() {};
		  onerror = onerror || function() {};
		  var indexedDB = FS.indexedDB();
		  try {
		   var openRequest = indexedDB.open(FS.DB_NAME(), FS.DB_VERSION);
		  } catch (e) {
		   return onerror(e);
		  }
		  openRequest.onupgradeneeded = onerror;
		  openRequest.onsuccess = function openRequest_onsuccess() {
		   var db = openRequest.result;
		   try {
		    var transaction = db.transaction([ FS.DB_STORE_NAME ], "readonly");
		   } catch (e) {
		    onerror(e);
		    return;
		   }
		   var files = transaction.objectStore(FS.DB_STORE_NAME);
		   var ok = 0, fail = 0, total = paths.length;
		   function finish() {
		    if (fail == 0) onload(); else onerror();
		   }
		   paths.forEach(function(path) {
		    var getRequest = files.get(path);
		    getRequest.onsuccess = function getRequest_onsuccess() {
		     if (FS.analyzePath(path).exists) {
		      FS.unlink(path);
		     }
		     FS.createDataFile(PATH.dirname(path), PATH.basename(path), getRequest.result, true, true, true);
		     ok++;
		     if (ok + fail == total) finish();
		    };
		    getRequest.onerror = function getRequest_onerror() {
		     fail++;
		     if (ok + fail == total) finish();
		    };
		   });
		   transaction.onerror = onerror;
		  };
		  openRequest.onerror = onerror;
		 },
		 absolutePath: function() {
		  abort("FS.absolutePath has been removed; use PATH_FS.resolve instead");
		 },
		 createFolder: function() {
		  abort("FS.createFolder has been removed; use FS.mkdir instead");
		 },
		 createLink: function() {
		  abort("FS.createLink has been removed; use FS.symlink instead");
		 },
		 joinPath: function() {
		  abort("FS.joinPath has been removed; use PATH.join instead");
		 },
		 mmapAlloc: function() {
		  abort("FS.mmapAlloc has been replaced by the top level function mmapAlloc");
		 },
		 standardizePath: function() {
		  abort("FS.standardizePath has been removed; use PATH.normalize instead");
		 }
		};

		var SYSCALLS = {
		 mappings: {},
		 DEFAULT_POLLMASK: 5,
		 umask: 511,
		 calculateAt: function(dirfd, path) {
		  if (path[0] !== "/") {
		   var dir;
		   if (dirfd === -100) {
		    dir = FS.cwd();
		   } else {
		    var dirstream = FS.getStream(dirfd);
		    if (!dirstream) throw new FS.ErrnoError(8);
		    dir = dirstream.path;
		   }
		   path = PATH.join2(dir, path);
		  }
		  return path;
		 },
		 doStat: function(func, path, buf) {
		  try {
		   var stat = func(path);
		  } catch (e) {
		   if (e && e.node && PATH.normalize(path) !== PATH.normalize(FS.getPath(e.node))) {
		    return -54;
		   }
		   throw e;
		  }
		  HEAP32[buf >> 2] = stat.dev;
		  HEAP32[buf + 4 >> 2] = 0;
		  HEAP32[buf + 8 >> 2] = stat.ino;
		  HEAP32[buf + 12 >> 2] = stat.mode;
		  HEAP32[buf + 16 >> 2] = stat.nlink;
		  HEAP32[buf + 20 >> 2] = stat.uid;
		  HEAP32[buf + 24 >> 2] = stat.gid;
		  HEAP32[buf + 28 >> 2] = stat.rdev;
		  HEAP32[buf + 32 >> 2] = 0;
		  tempI64 = [ stat.size >>> 0, (tempDouble = stat.size, +Math.abs(tempDouble) >= 1 ? tempDouble > 0 ? (Math.min(+Math.floor(tempDouble / 4294967296), 4294967295) | 0) >>> 0 : ~~+Math.ceil((tempDouble - +(~~tempDouble >>> 0)) / 4294967296) >>> 0 : 0) ], 
		  HEAP32[buf + 40 >> 2] = tempI64[0], HEAP32[buf + 44 >> 2] = tempI64[1];
		  HEAP32[buf + 48 >> 2] = 4096;
		  HEAP32[buf + 52 >> 2] = stat.blocks;
		  HEAP32[buf + 56 >> 2] = stat.atime.getTime() / 1e3 | 0;
		  HEAP32[buf + 60 >> 2] = 0;
		  HEAP32[buf + 64 >> 2] = stat.mtime.getTime() / 1e3 | 0;
		  HEAP32[buf + 68 >> 2] = 0;
		  HEAP32[buf + 72 >> 2] = stat.ctime.getTime() / 1e3 | 0;
		  HEAP32[buf + 76 >> 2] = 0;
		  tempI64 = [ stat.ino >>> 0, (tempDouble = stat.ino, +Math.abs(tempDouble) >= 1 ? tempDouble > 0 ? (Math.min(+Math.floor(tempDouble / 4294967296), 4294967295) | 0) >>> 0 : ~~+Math.ceil((tempDouble - +(~~tempDouble >>> 0)) / 4294967296) >>> 0 : 0) ], 
		  HEAP32[buf + 80 >> 2] = tempI64[0], HEAP32[buf + 84 >> 2] = tempI64[1];
		  return 0;
		 },
		 doMsync: function(addr, stream, len, flags, offset) {
		  var buffer = HEAPU8.slice(addr, addr + len);
		  FS.msync(stream, buffer, offset, len, flags);
		 },
		 doMkdir: function(path, mode) {
		  path = PATH.normalize(path);
		  if (path[path.length - 1] === "/") path = path.substr(0, path.length - 1);
		  FS.mkdir(path, mode, 0);
		  return 0;
		 },
		 doMknod: function(path, mode, dev) {
		  switch (mode & 61440) {
		  case 32768:
		  case 8192:
		  case 24576:
		  case 4096:
		  case 49152:
		   break;

		  default:
		   return -28;
		  }
		  FS.mknod(path, mode, dev);
		  return 0;
		 },
		 doReadlink: function(path, buf, bufsize) {
		  if (bufsize <= 0) return -28;
		  var ret = FS.readlink(path);
		  var len = Math.min(bufsize, lengthBytesUTF8(ret));
		  var endChar = HEAP8[buf + len];
		  stringToUTF8(ret, buf, bufsize + 1);
		  HEAP8[buf + len] = endChar;
		  return len;
		 },
		 doAccess: function(path, amode) {
		  if (amode & ~7) {
		   return -28;
		  }
		  var node;
		  var lookup = FS.lookupPath(path, {
		   follow: true
		  });
		  node = lookup.node;
		  if (!node) {
		   return -44;
		  }
		  var perms = "";
		  if (amode & 4) perms += "r";
		  if (amode & 2) perms += "w";
		  if (amode & 1) perms += "x";
		  if (perms && FS.nodePermissions(node, perms)) {
		   return -2;
		  }
		  return 0;
		 },
		 doDup: function(path, flags, suggestFD) {
		  var suggest = FS.getStream(suggestFD);
		  if (suggest) FS.close(suggest);
		  return FS.open(path, flags, 0, suggestFD, suggestFD).fd;
		 },
		 doReadv: function(stream, iov, iovcnt, offset) {
		  var ret = 0;
		  for (var i = 0; i < iovcnt; i++) {
		   var ptr = HEAP32[iov + i * 8 >> 2];
		   var len = HEAP32[iov + (i * 8 + 4) >> 2];
		   var curr = FS.read(stream, HEAP8, ptr, len, offset);
		   if (curr < 0) return -1;
		   ret += curr;
		   if (curr < len) break;
		  }
		  return ret;
		 },
		 doWritev: function(stream, iov, iovcnt, offset) {
		  var ret = 0;
		  for (var i = 0; i < iovcnt; i++) {
		   var ptr = HEAP32[iov + i * 8 >> 2];
		   var len = HEAP32[iov + (i * 8 + 4) >> 2];
		   var curr = FS.write(stream, HEAP8, ptr, len, offset);
		   if (curr < 0) return -1;
		   ret += curr;
		  }
		  return ret;
		 },
		 varargs: undefined,
		 get: function() {
		  assert(SYSCALLS.varargs != undefined);
		  SYSCALLS.varargs += 4;
		  var ret = HEAP32[SYSCALLS.varargs - 4 >> 2];
		  return ret;
		 },
		 getStr: function(ptr) {
		  var ret = UTF8ToString(ptr);
		  return ret;
		 },
		 getStreamFromFD: function(fd) {
		  var stream = FS.getStream(fd);
		  if (!stream) throw new FS.ErrnoError(8);
		  return stream;
		 },
		 get64: function(low, high) {
		  if (low >= 0) assert(high === 0); else assert(high === -1);
		  return low;
		 }
		};

		function ___sys_access(path, amode) {
		 try {
		  path = SYSCALLS.getStr(path);
		  return SYSCALLS.doAccess(path, amode);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_chmod(path, mode) {
		 try {
		  path = SYSCALLS.getStr(path);
		  FS.chmod(path, mode);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_chown32(path, owner, group) {
		 try {
		  path = SYSCALLS.getStr(path);
		  FS.chown(path, owner, group);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_fchmod(fd, mode) {
		 try {
		  FS.fchmod(fd, mode);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_fchown32(fd, owner, group) {
		 try {
		  FS.fchown(fd, owner, group);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function setErrNo(value) {
		 HEAP32[___errno_location() >> 2] = value;
		 return value;
		}

		function ___sys_fcntl64(fd, cmd, varargs) {
		 SYSCALLS.varargs = varargs;
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  switch (cmd) {
		  case 0:
		   {
		    var arg = SYSCALLS.get();
		    if (arg < 0) {
		     return -28;
		    }
		    var newStream;
		    newStream = FS.open(stream.path, stream.flags, 0, arg);
		    return newStream.fd;
		   }

		  case 1:
		  case 2:
		   return 0;

		  case 3:
		   return stream.flags;

		  case 4:
		   {
		    var arg = SYSCALLS.get();
		    stream.flags |= arg;
		    return 0;
		   }

		  case 12:
		   {
		    var arg = SYSCALLS.get();
		    var offset = 0;
		    HEAP16[arg + offset >> 1] = 2;
		    return 0;
		   }

		  case 13:
		  case 14:
		   return 0;

		  case 16:
		  case 8:
		   return -28;

		  case 9:
		   setErrNo(28);
		   return -1;

		  default:
		   {
		    return -28;
		   }
		  }
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_fstat64(fd, buf) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  return SYSCALLS.doStat(FS.stat, stream.path, buf);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_ftruncate64(fd, zero, low, high) {
		 try {
		  var length = SYSCALLS.get64(low, high);
		  FS.ftruncate(fd, length);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_getcwd(buf, size) {
		 try {
		  if (size === 0) return -28;
		  var cwd = FS.cwd();
		  var cwdLengthInBytes = lengthBytesUTF8(cwd);
		  if (size < cwdLengthInBytes + 1) return -68;
		  stringToUTF8(cwd, buf, size);
		  return buf;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_getegid32() {
		 return 0;
		}

		function ___sys_geteuid32() {
		 return ___sys_getegid32();
		}

		function ___sys_getpid() {
		 return 42;
		}

		function ___sys_ioctl(fd, op, varargs) {
		 SYSCALLS.varargs = varargs;
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  switch (op) {
		  case 21509:
		  case 21505:
		   {
		    if (!stream.tty) return -59;
		    return 0;
		   }

		  case 21510:
		  case 21511:
		  case 21512:
		  case 21506:
		  case 21507:
		  case 21508:
		   {
		    if (!stream.tty) return -59;
		    return 0;
		   }

		  case 21519:
		   {
		    if (!stream.tty) return -59;
		    var argp = SYSCALLS.get();
		    HEAP32[argp >> 2] = 0;
		    return 0;
		   }

		  case 21520:
		   {
		    if (!stream.tty) return -59;
		    return -28;
		   }

		  case 21531:
		   {
		    var argp = SYSCALLS.get();
		    return FS.ioctl(stream, op, argp);
		   }

		  case 21523:
		   {
		    if (!stream.tty) return -59;
		    return 0;
		   }

		  case 21524:
		   {
		    if (!stream.tty) return -59;
		    return 0;
		   }

		  default:
		   abort("bad ioctl syscall " + op);
		  }
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_lstat64(path, buf) {
		 try {
		  path = SYSCALLS.getStr(path);
		  return SYSCALLS.doStat(FS.lstat, path, buf);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_mkdir(path, mode) {
		 try {
		  path = SYSCALLS.getStr(path);
		  return SYSCALLS.doMkdir(path, mode);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function syscallMmap2(addr, len, prot, flags, fd, off) {
		 off <<= 12;
		 var ptr;
		 var allocated = false;
		 if ((flags & 16) !== 0 && addr % 16384 !== 0) {
		  return -28;
		 }
		 if ((flags & 32) !== 0) {
		  ptr = _memalign(16384, len);
		  if (!ptr) return -48;
		  _memset(ptr, 0, len);
		  allocated = true;
		 } else {
		  var info = FS.getStream(fd);
		  if (!info) return -8;
		  var res = FS.mmap(info, addr, len, off, prot, flags);
		  ptr = res.ptr;
		  allocated = res.allocated;
		 }
		 SYSCALLS.mappings[ptr] = {
		  malloc: ptr,
		  len: len,
		  allocated: allocated,
		  fd: fd,
		  prot: prot,
		  flags: flags,
		  offset: off
		 };
		 return ptr;
		}

		function ___sys_mmap2(addr, len, prot, flags, fd, off) {
		 try {
		  return syscallMmap2(addr, len, prot, flags, fd, off);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_mprotect(addr, len, size) {
		 return 0;
		}

		function syscallMunmap(addr, len) {
		 if ((addr | 0) === -1 || len === 0) {
		  return -28;
		 }
		 var info = SYSCALLS.mappings[addr];
		 if (!info) return 0;
		 if (len === info.len) {
		  var stream = FS.getStream(info.fd);
		  if (stream) {
		   if (info.prot & 2) {
		    SYSCALLS.doMsync(addr, stream, len, info.flags, info.offset);
		   }
		   FS.munmap(stream);
		  }
		  SYSCALLS.mappings[addr] = null;
		  if (info.allocated) {
		   _free(info.malloc);
		  }
		 }
		 return 0;
		}

		function ___sys_munmap(addr, len) {
		 try {
		  return syscallMunmap(addr, len);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_open(path, flags, varargs) {
		 SYSCALLS.varargs = varargs;
		 try {
		  var pathname = SYSCALLS.getStr(path);
		  var mode = varargs ? SYSCALLS.get() : 0;
		  var stream = FS.open(pathname, flags, mode);
		  return stream.fd;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_readlink(path, buf, bufsize) {
		 try {
		  path = SYSCALLS.getStr(path);
		  return SYSCALLS.doReadlink(path, buf, bufsize);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_rmdir(path) {
		 try {
		  path = SYSCALLS.getStr(path);
		  FS.rmdir(path);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_stat64(path, buf) {
		 try {
		  path = SYSCALLS.getStr(path);
		  return SYSCALLS.doStat(FS.stat, path, buf);
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function ___sys_unlink(path) {
		 try {
		  path = SYSCALLS.getStr(path);
		  FS.unlink(path);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return -e.errno;
		 }
		}

		function _abort() {
		 abort();
		}

		var _emscripten_get_now;

		_emscripten_get_now = function() {
		 return performance.now();
		};

		var _emscripten_get_now_is_monotonic = true;

		function _clock_gettime(clk_id, tp) {
		 var now;
		 if (clk_id === 0) {
		  now = Date.now();
		 } else if ((clk_id === 1 || clk_id === 4) && _emscripten_get_now_is_monotonic) {
		  now = _emscripten_get_now();
		 } else {
		  setErrNo(28);
		  return -1;
		 }
		 HEAP32[tp >> 2] = now / 1e3 | 0;
		 HEAP32[tp + 4 >> 2] = now % 1e3 * 1e3 * 1e3 | 0;
		 return 0;
		}

		function _emscripten_memcpy_big(dest, src, num) {
		 HEAPU8.copyWithin(dest, src, src + num);
		}

		function _emscripten_get_heap_size() {
		 return HEAPU8.length;
		}

		function emscripten_realloc_buffer(size) {
		 try {
		  wasmMemory.grow(size - buffer.byteLength + 65535 >>> 16);
		  updateGlobalBufferAndViews(wasmMemory.buffer);
		  return 1;
		 } catch (e) {
		  console.error("emscripten_realloc_buffer: Attempted to grow heap from " + buffer.byteLength + " bytes to " + size + " bytes, but got error: " + e);
		 }
		}

		function _emscripten_resize_heap(requestedSize) {
		 requestedSize = requestedSize >>> 0;
		 var oldSize = _emscripten_get_heap_size();
		 assert(requestedSize > oldSize);
		 var maxHeapSize = 2147483648;
		 if (requestedSize > maxHeapSize) {
		  err("Cannot enlarge memory, asked to go up to " + requestedSize + " bytes, but the limit is " + maxHeapSize + " bytes!");
		  return false;
		 }
		 var minHeapSize = 16777216;
		 for (var cutDown = 1; cutDown <= 4; cutDown *= 2) {
		  var overGrownHeapSize = oldSize * (1 + .2 / cutDown);
		  overGrownHeapSize = Math.min(overGrownHeapSize, requestedSize + 100663296);
		  var newSize = Math.min(maxHeapSize, alignUp(Math.max(minHeapSize, requestedSize, overGrownHeapSize), 65536));
		  var replacement = emscripten_realloc_buffer(newSize);
		  if (replacement) {
		   return true;
		  }
		 }
		 err("Failed to grow the heap from " + oldSize + " bytes to " + newSize + " bytes, not enough memory!");
		 return false;
		}

		function _emscripten_thread_sleep(msecs) {
		 var start = _emscripten_get_now();
		 while (_emscripten_get_now() - start < msecs) {}
		}

		var ENV = {};

		function getExecutableName() {
		 return thisProgram || "./this.program";
		}

		function getEnvStrings() {
		 if (!getEnvStrings.strings) {
		  var lang = (typeof navigator === "object" && navigator.languages && navigator.languages[0] || "C").replace("-", "_") + ".UTF-8";
		  var env = {
		   "USER": "web_user",
		   "LOGNAME": "web_user",
		   "PATH": "/",
		   "PWD": "/",
		   "HOME": "/home/web_user",
		   "LANG": lang,
		   "_": getExecutableName()
		  };
		  for (var x in ENV) {
		   env[x] = ENV[x];
		  }
		  var strings = [];
		  for (var x in env) {
		   strings.push(x + "=" + env[x]);
		  }
		  getEnvStrings.strings = strings;
		 }
		 return getEnvStrings.strings;
		}

		function _environ_get(__environ, environ_buf) {
		 try {
		  var bufSize = 0;
		  getEnvStrings().forEach(function(string, i) {
		   var ptr = environ_buf + bufSize;
		   HEAP32[__environ + i * 4 >> 2] = ptr;
		   writeAsciiToMemory(string, ptr);
		   bufSize += string.length + 1;
		  });
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _environ_sizes_get(penviron_count, penviron_buf_size) {
		 try {
		  var strings = getEnvStrings();
		  HEAP32[penviron_count >> 2] = strings.length;
		  var bufSize = 0;
		  strings.forEach(function(string) {
		   bufSize += string.length + 1;
		  });
		  HEAP32[penviron_buf_size >> 2] = bufSize;
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _fd_close(fd) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  FS.close(stream);
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _fd_fdstat_get(fd, pbuf) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  var type = stream.tty ? 2 : FS.isDir(stream.mode) ? 3 : FS.isLink(stream.mode) ? 7 : 4;
		  HEAP8[pbuf >> 0] = type;
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _fd_read(fd, iov, iovcnt, pnum) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  var num = SYSCALLS.doReadv(stream, iov, iovcnt);
		  HEAP32[pnum >> 2] = num;
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _fd_seek(fd, offset_low, offset_high, whence, newOffset) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  var HIGH_OFFSET = 4294967296;
		  var offset = offset_high * HIGH_OFFSET + (offset_low >>> 0);
		  var DOUBLE_LIMIT = 9007199254740992;
		  if (offset <= -DOUBLE_LIMIT || offset >= DOUBLE_LIMIT) {
		   return -61;
		  }
		  FS.llseek(stream, offset, whence);
		  tempI64 = [ stream.position >>> 0, (tempDouble = stream.position, +Math.abs(tempDouble) >= 1 ? tempDouble > 0 ? (Math.min(+Math.floor(tempDouble / 4294967296), 4294967295) | 0) >>> 0 : ~~+Math.ceil((tempDouble - +(~~tempDouble >>> 0)) / 4294967296) >>> 0 : 0) ], 
		  HEAP32[newOffset >> 2] = tempI64[0], HEAP32[newOffset + 4 >> 2] = tempI64[1];
		  if (stream.getdents && offset === 0 && whence === 0) stream.getdents = null;
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _fd_sync(fd) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  if (stream.stream_ops && stream.stream_ops.fsync) {
		   return -stream.stream_ops.fsync(stream);
		  }
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _fd_write(fd, iov, iovcnt, pnum) {
		 try {
		  var stream = SYSCALLS.getStreamFromFD(fd);
		  var num = SYSCALLS.doWritev(stream, iov, iovcnt);
		  HEAP32[pnum >> 2] = num;
		  return 0;
		 } catch (e) {
		  if (typeof FS === "undefined" || !(e instanceof FS.ErrnoError)) abort(e);
		  return e.errno;
		 }
		}

		function _gettimeofday(ptr) {
		 var now = Date.now();
		 HEAP32[ptr >> 2] = now / 1e3 | 0;
		 HEAP32[ptr + 4 >> 2] = now % 1e3 * 1e3 | 0;
		 return 0;
		}

		function _setTempRet0($i) {
		}

		function __isLeapYear(year) {
		 return year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
		}

		function __arraySum(array, index) {
		 var sum = 0;
		 for (var i = 0; i <= index; sum += array[i++]) {}
		 return sum;
		}

		var __MONTH_DAYS_LEAP = [ 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

		var __MONTH_DAYS_REGULAR = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

		function __addDays(date, days) {
		 var newDate = new Date(date.getTime());
		 while (days > 0) {
		  var leap = __isLeapYear(newDate.getFullYear());
		  var currentMonth = newDate.getMonth();
		  var daysInCurrentMonth = (leap ? __MONTH_DAYS_LEAP : __MONTH_DAYS_REGULAR)[currentMonth];
		  if (days > daysInCurrentMonth - newDate.getDate()) {
		   days -= daysInCurrentMonth - newDate.getDate() + 1;
		   newDate.setDate(1);
		   if (currentMonth < 11) {
		    newDate.setMonth(currentMonth + 1);
		   } else {
		    newDate.setMonth(0);
		    newDate.setFullYear(newDate.getFullYear() + 1);
		   }
		  } else {
		   newDate.setDate(newDate.getDate() + days);
		   return newDate;
		  }
		 }
		 return newDate;
		}

		function _strftime(s, maxsize, format, tm) {
		 var tm_zone = HEAP32[tm + 40 >> 2];
		 var date = {
		  tm_sec: HEAP32[tm >> 2],
		  tm_min: HEAP32[tm + 4 >> 2],
		  tm_hour: HEAP32[tm + 8 >> 2],
		  tm_mday: HEAP32[tm + 12 >> 2],
		  tm_mon: HEAP32[tm + 16 >> 2],
		  tm_year: HEAP32[tm + 20 >> 2],
		  tm_wday: HEAP32[tm + 24 >> 2],
		  tm_yday: HEAP32[tm + 28 >> 2],
		  tm_isdst: HEAP32[tm + 32 >> 2],
		  tm_gmtoff: HEAP32[tm + 36 >> 2],
		  tm_zone: tm_zone ? UTF8ToString(tm_zone) : ""
		 };
		 var pattern = UTF8ToString(format);
		 var EXPANSION_RULES_1 = {
		  "%c": "%a %b %d %H:%M:%S %Y",
		  "%D": "%m/%d/%y",
		  "%F": "%Y-%m-%d",
		  "%h": "%b",
		  "%r": "%I:%M:%S %p",
		  "%R": "%H:%M",
		  "%T": "%H:%M:%S",
		  "%x": "%m/%d/%y",
		  "%X": "%H:%M:%S",
		  "%Ec": "%c",
		  "%EC": "%C",
		  "%Ex": "%m/%d/%y",
		  "%EX": "%H:%M:%S",
		  "%Ey": "%y",
		  "%EY": "%Y",
		  "%Od": "%d",
		  "%Oe": "%e",
		  "%OH": "%H",
		  "%OI": "%I",
		  "%Om": "%m",
		  "%OM": "%M",
		  "%OS": "%S",
		  "%Ou": "%u",
		  "%OU": "%U",
		  "%OV": "%V",
		  "%Ow": "%w",
		  "%OW": "%W",
		  "%Oy": "%y"
		 };
		 for (var rule in EXPANSION_RULES_1) {
		  pattern = pattern.replace(new RegExp(rule, "g"), EXPANSION_RULES_1[rule]);
		 }
		 var WEEKDAYS = [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ];
		 var MONTHS = [ "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ];
		 function leadingSomething(value, digits, character) {
		  var str = typeof value === "number" ? value.toString() : value || "";
		  while (str.length < digits) {
		   str = character[0] + str;
		  }
		  return str;
		 }
		 function leadingNulls(value, digits) {
		  return leadingSomething(value, digits, "0");
		 }
		 function compareByDay(date1, date2) {
		  function sgn(value) {
		   return value < 0 ? -1 : value > 0 ? 1 : 0;
		  }
		  var compare;
		  if ((compare = sgn(date1.getFullYear() - date2.getFullYear())) === 0) {
		   if ((compare = sgn(date1.getMonth() - date2.getMonth())) === 0) {
		    compare = sgn(date1.getDate() - date2.getDate());
		   }
		  }
		  return compare;
		 }
		 function getFirstWeekStartDate(janFourth) {
		  switch (janFourth.getDay()) {
		  case 0:
		   return new Date(janFourth.getFullYear() - 1, 11, 29);

		  case 1:
		   return janFourth;

		  case 2:
		   return new Date(janFourth.getFullYear(), 0, 3);

		  case 3:
		   return new Date(janFourth.getFullYear(), 0, 2);

		  case 4:
		   return new Date(janFourth.getFullYear(), 0, 1);

		  case 5:
		   return new Date(janFourth.getFullYear() - 1, 11, 31);

		  case 6:
		   return new Date(janFourth.getFullYear() - 1, 11, 30);
		  }
		 }
		 function getWeekBasedYear(date) {
		  var thisDate = __addDays(new Date(date.tm_year + 1900, 0, 1), date.tm_yday);
		  var janFourthThisYear = new Date(thisDate.getFullYear(), 0, 4);
		  var janFourthNextYear = new Date(thisDate.getFullYear() + 1, 0, 4);
		  var firstWeekStartThisYear = getFirstWeekStartDate(janFourthThisYear);
		  var firstWeekStartNextYear = getFirstWeekStartDate(janFourthNextYear);
		  if (compareByDay(firstWeekStartThisYear, thisDate) <= 0) {
		   if (compareByDay(firstWeekStartNextYear, thisDate) <= 0) {
		    return thisDate.getFullYear() + 1;
		   } else {
		    return thisDate.getFullYear();
		   }
		  } else {
		   return thisDate.getFullYear() - 1;
		  }
		 }
		 var EXPANSION_RULES_2 = {
		  "%a": function(date) {
		   return WEEKDAYS[date.tm_wday].substring(0, 3);
		  },
		  "%A": function(date) {
		   return WEEKDAYS[date.tm_wday];
		  },
		  "%b": function(date) {
		   return MONTHS[date.tm_mon].substring(0, 3);
		  },
		  "%B": function(date) {
		   return MONTHS[date.tm_mon];
		  },
		  "%C": function(date) {
		   var year = date.tm_year + 1900;
		   return leadingNulls(year / 100 | 0, 2);
		  },
		  "%d": function(date) {
		   return leadingNulls(date.tm_mday, 2);
		  },
		  "%e": function(date) {
		   return leadingSomething(date.tm_mday, 2, " ");
		  },
		  "%g": function(date) {
		   return getWeekBasedYear(date).toString().substring(2);
		  },
		  "%G": function(date) {
		   return getWeekBasedYear(date);
		  },
		  "%H": function(date) {
		   return leadingNulls(date.tm_hour, 2);
		  },
		  "%I": function(date) {
		   var twelveHour = date.tm_hour;
		   if (twelveHour == 0) twelveHour = 12; else if (twelveHour > 12) twelveHour -= 12;
		   return leadingNulls(twelveHour, 2);
		  },
		  "%j": function(date) {
		   return leadingNulls(date.tm_mday + __arraySum(__isLeapYear(date.tm_year + 1900) ? __MONTH_DAYS_LEAP : __MONTH_DAYS_REGULAR, date.tm_mon - 1), 3);
		  },
		  "%m": function(date) {
		   return leadingNulls(date.tm_mon + 1, 2);
		  },
		  "%M": function(date) {
		   return leadingNulls(date.tm_min, 2);
		  },
		  "%n": function() {
		   return "\n";
		  },
		  "%p": function(date) {
		   if (date.tm_hour >= 0 && date.tm_hour < 12) {
		    return "AM";
		   } else {
		    return "PM";
		   }
		  },
		  "%S": function(date) {
		   return leadingNulls(date.tm_sec, 2);
		  },
		  "%t": function() {
		   return "\t";
		  },
		  "%u": function(date) {
		   return date.tm_wday || 7;
		  },
		  "%U": function(date) {
		   var janFirst = new Date(date.tm_year + 1900, 0, 1);
		   var firstSunday = janFirst.getDay() === 0 ? janFirst : __addDays(janFirst, 7 - janFirst.getDay());
		   var endDate = new Date(date.tm_year + 1900, date.tm_mon, date.tm_mday);
		   if (compareByDay(firstSunday, endDate) < 0) {
		    var februaryFirstUntilEndMonth = __arraySum(__isLeapYear(endDate.getFullYear()) ? __MONTH_DAYS_LEAP : __MONTH_DAYS_REGULAR, endDate.getMonth() - 1) - 31;
		    var firstSundayUntilEndJanuary = 31 - firstSunday.getDate();
		    var days = firstSundayUntilEndJanuary + februaryFirstUntilEndMonth + endDate.getDate();
		    return leadingNulls(Math.ceil(days / 7), 2);
		   }
		   return compareByDay(firstSunday, janFirst) === 0 ? "01" : "00";
		  },
		  "%V": function(date) {
		   var janFourthThisYear = new Date(date.tm_year + 1900, 0, 4);
		   var janFourthNextYear = new Date(date.tm_year + 1901, 0, 4);
		   var firstWeekStartThisYear = getFirstWeekStartDate(janFourthThisYear);
		   var firstWeekStartNextYear = getFirstWeekStartDate(janFourthNextYear);
		   var endDate = __addDays(new Date(date.tm_year + 1900, 0, 1), date.tm_yday);
		   if (compareByDay(endDate, firstWeekStartThisYear) < 0) {
		    return "53";
		   }
		   if (compareByDay(firstWeekStartNextYear, endDate) <= 0) {
		    return "01";
		   }
		   var daysDifference;
		   if (firstWeekStartThisYear.getFullYear() < date.tm_year + 1900) {
		    daysDifference = date.tm_yday + 32 - firstWeekStartThisYear.getDate();
		   } else {
		    daysDifference = date.tm_yday + 1 - firstWeekStartThisYear.getDate();
		   }
		   return leadingNulls(Math.ceil(daysDifference / 7), 2);
		  },
		  "%w": function(date) {
		   return date.tm_wday;
		  },
		  "%W": function(date) {
		   var janFirst = new Date(date.tm_year, 0, 1);
		   var firstMonday = janFirst.getDay() === 1 ? janFirst : __addDays(janFirst, janFirst.getDay() === 0 ? 1 : 7 - janFirst.getDay() + 1);
		   var endDate = new Date(date.tm_year + 1900, date.tm_mon, date.tm_mday);
		   if (compareByDay(firstMonday, endDate) < 0) {
		    var februaryFirstUntilEndMonth = __arraySum(__isLeapYear(endDate.getFullYear()) ? __MONTH_DAYS_LEAP : __MONTH_DAYS_REGULAR, endDate.getMonth() - 1) - 31;
		    var firstMondayUntilEndJanuary = 31 - firstMonday.getDate();
		    var days = firstMondayUntilEndJanuary + februaryFirstUntilEndMonth + endDate.getDate();
		    return leadingNulls(Math.ceil(days / 7), 2);
		   }
		   return compareByDay(firstMonday, janFirst) === 0 ? "01" : "00";
		  },
		  "%y": function(date) {
		   return (date.tm_year + 1900).toString().substring(2);
		  },
		  "%Y": function(date) {
		   return date.tm_year + 1900;
		  },
		  "%z": function(date) {
		   var off = date.tm_gmtoff;
		   var ahead = off >= 0;
		   off = Math.abs(off) / 60;
		   off = off / 60 * 100 + off % 60;
		   return (ahead ? "+" : "-") + String("0000" + off).slice(-4);
		  },
		  "%Z": function(date) {
		   return date.tm_zone;
		  },
		  "%%": function() {
		   return "%";
		  }
		 };
		 for (var rule in EXPANSION_RULES_2) {
		  if (pattern.indexOf(rule) >= 0) {
		   pattern = pattern.replace(new RegExp(rule, "g"), EXPANSION_RULES_2[rule](date));
		  }
		 }
		 var bytes = intArrayFromString(pattern, false);
		 if (bytes.length > maxsize) {
		  return 0;
		 }
		 writeArrayToMemory(bytes, s);
		 return bytes.length - 1;
		}

		function _strftime_l(s, maxsize, format, tm) {
		 return _strftime(s, maxsize, format, tm);
		}

		function _sysconf(name) {
		 switch (name) {
		 case 30:
		  return 16384;

		 case 85:
		  var maxHeapSize = 2147483648;
		  return maxHeapSize / 16384;

		 case 132:
		 case 133:
		 case 12:
		 case 137:
		 case 138:
		 case 15:
		 case 235:
		 case 16:
		 case 17:
		 case 18:
		 case 19:
		 case 20:
		 case 149:
		 case 13:
		 case 10:
		 case 236:
		 case 153:
		 case 9:
		 case 21:
		 case 22:
		 case 159:
		 case 154:
		 case 14:
		 case 77:
		 case 78:
		 case 139:
		 case 82:
		 case 68:
		 case 67:
		 case 164:
		 case 11:
		 case 29:
		 case 47:
		 case 48:
		 case 95:
		 case 52:
		 case 51:
		 case 46:
		  return 200809;

		 case 27:
		 case 246:
		 case 127:
		 case 128:
		 case 23:
		 case 24:
		 case 160:
		 case 161:
		 case 181:
		 case 182:
		 case 242:
		 case 183:
		 case 184:
		 case 243:
		 case 244:
		 case 245:
		 case 165:
		 case 178:
		 case 179:
		 case 49:
		 case 50:
		 case 168:
		 case 169:
		 case 175:
		 case 170:
		 case 171:
		 case 172:
		 case 97:
		 case 76:
		 case 32:
		 case 173:
		 case 35:
		 case 80:
		 case 81:
		 case 79:
		  return -1;

		 case 176:
		 case 177:
		 case 7:
		 case 155:
		 case 8:
		 case 157:
		 case 125:
		 case 126:
		 case 92:
		 case 93:
		 case 129:
		 case 130:
		 case 131:
		 case 94:
		 case 91:
		  return 1;

		 case 74:
		 case 60:
		 case 69:
		 case 70:
		 case 4:
		  return 1024;

		 case 31:
		 case 42:
		 case 72:
		  return 32;

		 case 87:
		 case 26:
		 case 33:
		  return 2147483647;

		 case 34:
		 case 1:
		  return 47839;

		 case 38:
		 case 36:
		  return 99;

		 case 43:
		 case 37:
		  return 2048;

		 case 0:
		  return 2097152;

		 case 3:
		  return 65536;

		 case 28:
		  return 32768;

		 case 44:
		  return 32767;

		 case 75:
		  return 16384;

		 case 39:
		  return 1e3;

		 case 89:
		  return 700;

		 case 71:
		  return 256;

		 case 40:
		  return 255;

		 case 2:
		  return 100;

		 case 180:
		  return 64;

		 case 25:
		  return 20;

		 case 5:
		  return 16;

		 case 6:
		  return 6;

		 case 73:
		  return 4;

		 case 84:
		  {
		   if (typeof navigator === "object") return navigator["hardwareConcurrency"] || 1;
		   return 1;
		  }
		 }
		 setErrNo(28);
		 return -1;
		}

		function _timegm(tmPtr) {
		 _tzset();
		 var time = Date.UTC(HEAP32[tmPtr + 20 >> 2] + 1900, HEAP32[tmPtr + 16 >> 2], HEAP32[tmPtr + 12 >> 2], HEAP32[tmPtr + 8 >> 2], HEAP32[tmPtr + 4 >> 2], HEAP32[tmPtr >> 2], 0);
		 var date = new Date(time);
		 HEAP32[tmPtr + 24 >> 2] = date.getUTCDay();
		 var start = Date.UTC(date.getUTCFullYear(), 0, 1, 0, 0, 0, 0);
		 var yday = (date.getTime() - start) / (1e3 * 60 * 60 * 24) | 0;
		 HEAP32[tmPtr + 28 >> 2] = yday;
		 return date.getTime() / 1e3 | 0;
		}

		function setFileTime(path, time) {
		 path = UTF8ToString(path);
		 try {
		  FS.utime(path, time, time);
		  return 0;
		 } catch (e) {
		  if (!(e instanceof FS.ErrnoError)) throw e + " : " + stackTrace();
		  setErrNo(e.errno);
		  return -1;
		 }
		}

		function _utime(path, times) {
		 var time;
		 if (times) {
		  time = HEAP32[times + 4 >> 2] * 1e3;
		 } else {
		  time = Date.now();
		 }
		 return setFileTime(path, time);
		}

		var FSNode = function(parent, name, mode, rdev) {
		 if (!parent) {
		  parent = this;
		 }
		 this.parent = parent;
		 this.mount = parent.mount;
		 this.mounted = null;
		 this.id = FS.nextInode++;
		 this.name = name;
		 this.mode = mode;
		 this.node_ops = {};
		 this.stream_ops = {};
		 this.rdev = rdev;
		};

		var readMode = 292 | 73;

		var writeMode = 146;

		Object.defineProperties(FSNode.prototype, {
		 read: {
		  get: function() {
		   return (this.mode & readMode) === readMode;
		  },
		  set: function(val) {
		   val ? this.mode |= readMode : this.mode &= ~readMode;
		  }
		 },
		 write: {
		  get: function() {
		   return (this.mode & writeMode) === writeMode;
		  },
		  set: function(val) {
		   val ? this.mode |= writeMode : this.mode &= ~writeMode;
		  }
		 },
		 isFolder: {
		  get: function() {
		   return FS.isDir(this.mode);
		  }
		 },
		 isDevice: {
		  get: function() {
		   return FS.isChrdev(this.mode);
		  }
		 }
		});

		FS.FSNode = FSNode;

		FS.staticInit();

		function intArrayFromString(stringy, dontAddNull, length) {
		 var len = length > 0 ? length : lengthBytesUTF8(stringy) + 1;
		 var u8array = new Array(len);
		 var numBytesWritten = stringToUTF8Array(stringy, u8array, 0, u8array.length);
		 if (dontAddNull) u8array.length = numBytesWritten;
		 return u8array;
		}

		var asmLibraryArg = {
		 "__cxa_atexit": ___cxa_atexit,
		 "__gmtime_r": ___gmtime_r,
		 "__localtime_r": ___localtime_r,
		 "__sys_access": ___sys_access,
		 "__sys_chmod": ___sys_chmod,
		 "__sys_chown32": ___sys_chown32,
		 "__sys_fchmod": ___sys_fchmod,
		 "__sys_fchown32": ___sys_fchown32,
		 "__sys_fcntl64": ___sys_fcntl64,
		 "__sys_fstat64": ___sys_fstat64,
		 "__sys_ftruncate64": ___sys_ftruncate64,
		 "__sys_getcwd": ___sys_getcwd,
		 "__sys_geteuid32": ___sys_geteuid32,
		 "__sys_getpid": ___sys_getpid,
		 "__sys_ioctl": ___sys_ioctl,
		 "__sys_lstat64": ___sys_lstat64,
		 "__sys_mkdir": ___sys_mkdir,
		 "__sys_mmap2": ___sys_mmap2,
		 "__sys_mprotect": ___sys_mprotect,
		 "__sys_munmap": ___sys_munmap,
		 "__sys_open": ___sys_open,
		 "__sys_readlink": ___sys_readlink,
		 "__sys_rmdir": ___sys_rmdir,
		 "__sys_stat64": ___sys_stat64,
		 "__sys_unlink": ___sys_unlink,
		 "abort": _abort,
		 "clock_gettime": _clock_gettime,
		 "emscripten_get_now": _emscripten_get_now,
		 "emscripten_memcpy_big": _emscripten_memcpy_big,
		 "emscripten_resize_heap": _emscripten_resize_heap,
		 "emscripten_thread_sleep": _emscripten_thread_sleep,
		 "environ_get": _environ_get,
		 "environ_sizes_get": _environ_sizes_get,
		 "fd_close": _fd_close,
		 "fd_fdstat_get": _fd_fdstat_get,
		 "fd_read": _fd_read,
		 "fd_seek": _fd_seek,
		 "fd_sync": _fd_sync,
		 "fd_write": _fd_write,
		 "gettimeofday": _gettimeofday,
		 "setTempRet0": _setTempRet0,
		 "strftime_l": _strftime_l,
		 "sysconf": _sysconf,
		 "timegm": _timegm,
		 "utime": _utime
		};

		var asm = createWasm();

		var ___wasm_call_ctors = Module["___wasm_call_ctors"] = createExportWrapper("__wasm_call_ctors", asm);

		var ___errno_location = Module["___errno_location"] = createExportWrapper("__errno_location", asm);

		var _memset = Module["_memset"] = createExportWrapper("memset", asm);

		var _malloc = Module["_malloc"] = createExportWrapper("malloc", asm);

		var _free = Module["_free"] = createExportWrapper("free", asm);

		Module["_fflush"] = createExportWrapper("fflush", asm);

		Module["_usleep"] = createExportWrapper("usleep", asm);

		Module["_trace_processor_rpc_init"] = createExportWrapper("trace_processor_rpc_init", asm);

		Module["_trace_processor_on_rpc_request"] = createExportWrapper("trace_processor_on_rpc_request", asm);

		Module["_main"] = createExportWrapper("main", asm);

		var __get_tzname = Module["__get_tzname"] = createExportWrapper("_get_tzname", asm);

		var __get_daylight = Module["__get_daylight"] = createExportWrapper("_get_daylight", asm);

		var __get_timezone = Module["__get_timezone"] = createExportWrapper("_get_timezone", asm);

		Module["_emscripten_main_thread_process_queued_calls"] = createExportWrapper("emscripten_main_thread_process_queued_calls", asm);

		var _emscripten_stack_get_end = Module["_emscripten_stack_get_end"] = asm["emscripten_stack_get_end"];

		var stackSave = Module["stackSave"] = createExportWrapper("stackSave", asm);

		var stackRestore = Module["stackRestore"] = createExportWrapper("stackRestore", asm);

		var stackAlloc = Module["stackAlloc"] = createExportWrapper("stackAlloc", asm);

		var _emscripten_stack_init = Module["_emscripten_stack_init"] = asm["emscripten_stack_init"];

		Module["_emscripten_stack_get_free"] = asm["emscripten_stack_get_free"];

		var _memalign = Module["_memalign"] = createExportWrapper("memalign", asm);

		Module["dynCall_iiiij"] = createExportWrapper("dynCall_iiiij", asm);

		Module["dynCall_iij"] = createExportWrapper("dynCall_iij", asm);

		Module["dynCall_iijii"] = createExportWrapper("dynCall_iijii", asm);

		Module["dynCall_iiji"] = createExportWrapper("dynCall_iiji", asm);

		Module["dynCall_iiiiiij"] = createExportWrapper("dynCall_iiiiiij", asm);

		Module["dynCall_viijdi"] = createExportWrapper("dynCall_viijdi", asm);

		Module["dynCall_viijdii"] = createExportWrapper("dynCall_viijdii", asm);

		Module["dynCall_viijiiii"] = createExportWrapper("dynCall_viijiiii", asm);

		Module["dynCall_viijiiiji"] = createExportWrapper("dynCall_viijiiiji", asm);

		Module["dynCall_viijiii"] = createExportWrapper("dynCall_viijiii", asm);

		Module["dynCall_viiiijii"] = createExportWrapper("dynCall_viiiijii", asm);

		Module["dynCall_viijii"] = createExportWrapper("dynCall_viijii", asm);

		Module["dynCall_viiji"] = createExportWrapper("dynCall_viiji", asm);

		Module["dynCall_viij"] = createExportWrapper("dynCall_viij", asm);

		Module["dynCall_viji"] = createExportWrapper("dynCall_viji", asm);

		Module["dynCall_ji"] = createExportWrapper("dynCall_ji", asm);

		Module["dynCall_iiij"] = createExportWrapper("dynCall_iiij", asm);

		Module["dynCall_viijiiijiii"] = createExportWrapper("dynCall_viijiiijiii", asm);

		Module["dynCall_jiji"] = createExportWrapper("dynCall_jiji", asm);

		Module["dynCall_iiiiij"] = createExportWrapper("dynCall_iiiiij", asm);

		Module["dynCall_iiiiijj"] = createExportWrapper("dynCall_iiiiijj", asm);

		Module["dynCall_iiiiiijj"] = createExportWrapper("dynCall_iiiiiijj", asm);

		if (!Object.getOwnPropertyDescriptor(Module, "intArrayFromString")) Module["intArrayFromString"] = function() {
		 abort("'intArrayFromString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "intArrayToString")) Module["intArrayToString"] = function() {
		 abort("'intArrayToString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		Module["ccall"] = ccall;

		if (!Object.getOwnPropertyDescriptor(Module, "cwrap")) Module["cwrap"] = function() {
		 abort("'cwrap' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setValue")) Module["setValue"] = function() {
		 abort("'setValue' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getValue")) Module["getValue"] = function() {
		 abort("'getValue' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "allocate")) Module["allocate"] = function() {
		 abort("'allocate' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "UTF8ArrayToString")) Module["UTF8ArrayToString"] = function() {
		 abort("'UTF8ArrayToString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "UTF8ToString")) Module["UTF8ToString"] = function() {
		 abort("'UTF8ToString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stringToUTF8Array")) Module["stringToUTF8Array"] = function() {
		 abort("'stringToUTF8Array' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stringToUTF8")) Module["stringToUTF8"] = function() {
		 abort("'stringToUTF8' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "lengthBytesUTF8")) Module["lengthBytesUTF8"] = function() {
		 abort("'lengthBytesUTF8' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stackTrace")) Module["stackTrace"] = function() {
		 abort("'stackTrace' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "addOnPreRun")) Module["addOnPreRun"] = function() {
		 abort("'addOnPreRun' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "addOnInit")) Module["addOnInit"] = function() {
		 abort("'addOnInit' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "addOnPreMain")) Module["addOnPreMain"] = function() {
		 abort("'addOnPreMain' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "addOnExit")) Module["addOnExit"] = function() {
		 abort("'addOnExit' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "addOnPostRun")) Module["addOnPostRun"] = function() {
		 abort("'addOnPostRun' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeStringToMemory")) Module["writeStringToMemory"] = function() {
		 abort("'writeStringToMemory' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeArrayToMemory")) Module["writeArrayToMemory"] = function() {
		 abort("'writeArrayToMemory' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeAsciiToMemory")) Module["writeAsciiToMemory"] = function() {
		 abort("'writeAsciiToMemory' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "addRunDependency")) Module["addRunDependency"] = function() {
		 abort("'addRunDependency' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "removeRunDependency")) Module["removeRunDependency"] = function() {
		 abort("'removeRunDependency' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createFolder")) Module["FS_createFolder"] = function() {
		 abort("'FS_createFolder' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createPath")) Module["FS_createPath"] = function() {
		 abort("'FS_createPath' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createDataFile")) Module["FS_createDataFile"] = function() {
		 abort("'FS_createDataFile' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createPreloadedFile")) Module["FS_createPreloadedFile"] = function() {
		 abort("'FS_createPreloadedFile' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createLazyFile")) Module["FS_createLazyFile"] = function() {
		 abort("'FS_createLazyFile' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createLink")) Module["FS_createLink"] = function() {
		 abort("'FS_createLink' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_createDevice")) Module["FS_createDevice"] = function() {
		 abort("'FS_createDevice' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "FS_unlink")) Module["FS_unlink"] = function() {
		 abort("'FS_unlink' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ). Alternatively, forcing filesystem support (-s FORCE_FILESYSTEM=1) can export this for you");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getLEB")) Module["getLEB"] = function() {
		 abort("'getLEB' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getFunctionTables")) Module["getFunctionTables"] = function() {
		 abort("'getFunctionTables' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "alignFunctionTables")) Module["alignFunctionTables"] = function() {
		 abort("'alignFunctionTables' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerFunctions")) Module["registerFunctions"] = function() {
		 abort("'registerFunctions' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		Module["addFunction"] = addFunction;

		if (!Object.getOwnPropertyDescriptor(Module, "removeFunction")) Module["removeFunction"] = function() {
		 abort("'removeFunction' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getFuncWrapper")) Module["getFuncWrapper"] = function() {
		 abort("'getFuncWrapper' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "prettyPrint")) Module["prettyPrint"] = function() {
		 abort("'prettyPrint' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "makeBigInt")) Module["makeBigInt"] = function() {
		 abort("'makeBigInt' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "dynCall")) Module["dynCall"] = function() {
		 abort("'dynCall' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getCompilerSetting")) Module["getCompilerSetting"] = function() {
		 abort("'getCompilerSetting' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "print")) Module["print"] = function() {
		 abort("'print' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "printErr")) Module["printErr"] = function() {
		 abort("'printErr' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getTempRet0")) Module["getTempRet0"] = function() {
		 abort("'getTempRet0' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setTempRet0")) Module["setTempRet0"] = function() {
		 abort("'setTempRet0' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		Module["callMain"] = callMain;

		if (!Object.getOwnPropertyDescriptor(Module, "abort")) Module["abort"] = function() {
		 abort("'abort' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stringToNewUTF8")) Module["stringToNewUTF8"] = function() {
		 abort("'stringToNewUTF8' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setFileTime")) Module["setFileTime"] = function() {
		 abort("'setFileTime' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "emscripten_realloc_buffer")) Module["emscripten_realloc_buffer"] = function() {
		 abort("'emscripten_realloc_buffer' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "ENV")) Module["ENV"] = function() {
		 abort("'ENV' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "ERRNO_CODES")) Module["ERRNO_CODES"] = function() {
		 abort("'ERRNO_CODES' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "ERRNO_MESSAGES")) Module["ERRNO_MESSAGES"] = function() {
		 abort("'ERRNO_MESSAGES' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setErrNo")) Module["setErrNo"] = function() {
		 abort("'setErrNo' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "DNS")) Module["DNS"] = function() {
		 abort("'DNS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getHostByName")) Module["getHostByName"] = function() {
		 abort("'getHostByName' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "GAI_ERRNO_MESSAGES")) Module["GAI_ERRNO_MESSAGES"] = function() {
		 abort("'GAI_ERRNO_MESSAGES' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "Protocols")) Module["Protocols"] = function() {
		 abort("'Protocols' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "Sockets")) Module["Sockets"] = function() {
		 abort("'Sockets' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getRandomDevice")) Module["getRandomDevice"] = function() {
		 abort("'getRandomDevice' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "traverseStack")) Module["traverseStack"] = function() {
		 abort("'traverseStack' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "UNWIND_CACHE")) Module["UNWIND_CACHE"] = function() {
		 abort("'UNWIND_CACHE' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "withBuiltinMalloc")) Module["withBuiltinMalloc"] = function() {
		 abort("'withBuiltinMalloc' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "readAsmConstArgsArray")) Module["readAsmConstArgsArray"] = function() {
		 abort("'readAsmConstArgsArray' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "readAsmConstArgs")) Module["readAsmConstArgs"] = function() {
		 abort("'readAsmConstArgs' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "mainThreadEM_ASM")) Module["mainThreadEM_ASM"] = function() {
		 abort("'mainThreadEM_ASM' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "jstoi_q")) Module["jstoi_q"] = function() {
		 abort("'jstoi_q' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "jstoi_s")) Module["jstoi_s"] = function() {
		 abort("'jstoi_s' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getExecutableName")) Module["getExecutableName"] = function() {
		 abort("'getExecutableName' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "listenOnce")) Module["listenOnce"] = function() {
		 abort("'listenOnce' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "autoResumeAudioContext")) Module["autoResumeAudioContext"] = function() {
		 abort("'autoResumeAudioContext' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "dynCallLegacy")) Module["dynCallLegacy"] = function() {
		 abort("'dynCallLegacy' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getDynCaller")) Module["getDynCaller"] = function() {
		 abort("'getDynCaller' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "dynCall")) Module["dynCall"] = function() {
		 abort("'dynCall' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "callRuntimeCallbacks")) Module["callRuntimeCallbacks"] = function() {
		 abort("'callRuntimeCallbacks' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "abortStackOverflow")) Module["abortStackOverflow"] = function() {
		 abort("'abortStackOverflow' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "reallyNegative")) Module["reallyNegative"] = function() {
		 abort("'reallyNegative' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "unSign")) Module["unSign"] = function() {
		 abort("'unSign' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "reSign")) Module["reSign"] = function() {
		 abort("'reSign' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "formatString")) Module["formatString"] = function() {
		 abort("'formatString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "PATH")) Module["PATH"] = function() {
		 abort("'PATH' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "PATH_FS")) Module["PATH_FS"] = function() {
		 abort("'PATH_FS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SYSCALLS")) Module["SYSCALLS"] = function() {
		 abort("'SYSCALLS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "syscallMmap2")) Module["syscallMmap2"] = function() {
		 abort("'syscallMmap2' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "syscallMunmap")) Module["syscallMunmap"] = function() {
		 abort("'syscallMunmap' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "JSEvents")) Module["JSEvents"] = function() {
		 abort("'JSEvents' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerKeyEventCallback")) Module["registerKeyEventCallback"] = function() {
		 abort("'registerKeyEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "specialHTMLTargets")) Module["specialHTMLTargets"] = function() {
		 abort("'specialHTMLTargets' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "maybeCStringToJsString")) Module["maybeCStringToJsString"] = function() {
		 abort("'maybeCStringToJsString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "findEventTarget")) Module["findEventTarget"] = function() {
		 abort("'findEventTarget' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "findCanvasEventTarget")) Module["findCanvasEventTarget"] = function() {
		 abort("'findCanvasEventTarget' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getBoundingClientRect")) Module["getBoundingClientRect"] = function() {
		 abort("'getBoundingClientRect' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillMouseEventData")) Module["fillMouseEventData"] = function() {
		 abort("'fillMouseEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerMouseEventCallback")) Module["registerMouseEventCallback"] = function() {
		 abort("'registerMouseEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerWheelEventCallback")) Module["registerWheelEventCallback"] = function() {
		 abort("'registerWheelEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerUiEventCallback")) Module["registerUiEventCallback"] = function() {
		 abort("'registerUiEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerFocusEventCallback")) Module["registerFocusEventCallback"] = function() {
		 abort("'registerFocusEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillDeviceOrientationEventData")) Module["fillDeviceOrientationEventData"] = function() {
		 abort("'fillDeviceOrientationEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerDeviceOrientationEventCallback")) Module["registerDeviceOrientationEventCallback"] = function() {
		 abort("'registerDeviceOrientationEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillDeviceMotionEventData")) Module["fillDeviceMotionEventData"] = function() {
		 abort("'fillDeviceMotionEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerDeviceMotionEventCallback")) Module["registerDeviceMotionEventCallback"] = function() {
		 abort("'registerDeviceMotionEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "screenOrientation")) Module["screenOrientation"] = function() {
		 abort("'screenOrientation' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillOrientationChangeEventData")) Module["fillOrientationChangeEventData"] = function() {
		 abort("'fillOrientationChangeEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerOrientationChangeEventCallback")) Module["registerOrientationChangeEventCallback"] = function() {
		 abort("'registerOrientationChangeEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillFullscreenChangeEventData")) Module["fillFullscreenChangeEventData"] = function() {
		 abort("'fillFullscreenChangeEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerFullscreenChangeEventCallback")) Module["registerFullscreenChangeEventCallback"] = function() {
		 abort("'registerFullscreenChangeEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerRestoreOldStyle")) Module["registerRestoreOldStyle"] = function() {
		 abort("'registerRestoreOldStyle' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "hideEverythingExceptGivenElement")) Module["hideEverythingExceptGivenElement"] = function() {
		 abort("'hideEverythingExceptGivenElement' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "restoreHiddenElements")) Module["restoreHiddenElements"] = function() {
		 abort("'restoreHiddenElements' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setLetterbox")) Module["setLetterbox"] = function() {
		 abort("'setLetterbox' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "currentFullscreenStrategy")) Module["currentFullscreenStrategy"] = function() {
		 abort("'currentFullscreenStrategy' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "restoreOldWindowedStyle")) Module["restoreOldWindowedStyle"] = function() {
		 abort("'restoreOldWindowedStyle' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "softFullscreenResizeWebGLRenderTarget")) Module["softFullscreenResizeWebGLRenderTarget"] = function() {
		 abort("'softFullscreenResizeWebGLRenderTarget' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "doRequestFullscreen")) Module["doRequestFullscreen"] = function() {
		 abort("'doRequestFullscreen' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillPointerlockChangeEventData")) Module["fillPointerlockChangeEventData"] = function() {
		 abort("'fillPointerlockChangeEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerPointerlockChangeEventCallback")) Module["registerPointerlockChangeEventCallback"] = function() {
		 abort("'registerPointerlockChangeEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerPointerlockErrorEventCallback")) Module["registerPointerlockErrorEventCallback"] = function() {
		 abort("'registerPointerlockErrorEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "requestPointerLock")) Module["requestPointerLock"] = function() {
		 abort("'requestPointerLock' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillVisibilityChangeEventData")) Module["fillVisibilityChangeEventData"] = function() {
		 abort("'fillVisibilityChangeEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerVisibilityChangeEventCallback")) Module["registerVisibilityChangeEventCallback"] = function() {
		 abort("'registerVisibilityChangeEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerTouchEventCallback")) Module["registerTouchEventCallback"] = function() {
		 abort("'registerTouchEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillGamepadEventData")) Module["fillGamepadEventData"] = function() {
		 abort("'fillGamepadEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerGamepadEventCallback")) Module["registerGamepadEventCallback"] = function() {
		 abort("'registerGamepadEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerBeforeUnloadEventCallback")) Module["registerBeforeUnloadEventCallback"] = function() {
		 abort("'registerBeforeUnloadEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "fillBatteryEventData")) Module["fillBatteryEventData"] = function() {
		 abort("'fillBatteryEventData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "battery")) Module["battery"] = function() {
		 abort("'battery' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "registerBatteryEventCallback")) Module["registerBatteryEventCallback"] = function() {
		 abort("'registerBatteryEventCallback' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setCanvasElementSize")) Module["setCanvasElementSize"] = function() {
		 abort("'setCanvasElementSize' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getCanvasElementSize")) Module["getCanvasElementSize"] = function() {
		 abort("'getCanvasElementSize' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "polyfillSetImmediate")) Module["polyfillSetImmediate"] = function() {
		 abort("'polyfillSetImmediate' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "demangle")) Module["demangle"] = function() {
		 abort("'demangle' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "demangleAll")) Module["demangleAll"] = function() {
		 abort("'demangleAll' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "jsStackTrace")) Module["jsStackTrace"] = function() {
		 abort("'jsStackTrace' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stackTrace")) Module["stackTrace"] = function() {
		 abort("'stackTrace' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getEnvStrings")) Module["getEnvStrings"] = function() {
		 abort("'getEnvStrings' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "checkWasiClock")) Module["checkWasiClock"] = function() {
		 abort("'checkWasiClock' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeI53ToI64")) Module["writeI53ToI64"] = function() {
		 abort("'writeI53ToI64' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeI53ToI64Clamped")) Module["writeI53ToI64Clamped"] = function() {
		 abort("'writeI53ToI64Clamped' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeI53ToI64Signaling")) Module["writeI53ToI64Signaling"] = function() {
		 abort("'writeI53ToI64Signaling' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeI53ToU64Clamped")) Module["writeI53ToU64Clamped"] = function() {
		 abort("'writeI53ToU64Clamped' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeI53ToU64Signaling")) Module["writeI53ToU64Signaling"] = function() {
		 abort("'writeI53ToU64Signaling' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "readI53FromI64")) Module["readI53FromI64"] = function() {
		 abort("'readI53FromI64' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "readI53FromU64")) Module["readI53FromU64"] = function() {
		 abort("'readI53FromU64' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "convertI32PairToI53")) Module["convertI32PairToI53"] = function() {
		 abort("'convertI32PairToI53' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "convertU32PairToI53")) Module["convertU32PairToI53"] = function() {
		 abort("'convertU32PairToI53' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "uncaughtExceptionCount")) Module["uncaughtExceptionCount"] = function() {
		 abort("'uncaughtExceptionCount' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "exceptionLast")) Module["exceptionLast"] = function() {
		 abort("'exceptionLast' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "exceptionCaught")) Module["exceptionCaught"] = function() {
		 abort("'exceptionCaught' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "ExceptionInfoAttrs")) Module["ExceptionInfoAttrs"] = function() {
		 abort("'ExceptionInfoAttrs' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "ExceptionInfo")) Module["ExceptionInfo"] = function() {
		 abort("'ExceptionInfo' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "CatchInfo")) Module["CatchInfo"] = function() {
		 abort("'CatchInfo' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "exception_addRef")) Module["exception_addRef"] = function() {
		 abort("'exception_addRef' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "exception_decRef")) Module["exception_decRef"] = function() {
		 abort("'exception_decRef' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "Browser")) Module["Browser"] = function() {
		 abort("'Browser' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "funcWrappers")) Module["funcWrappers"] = function() {
		 abort("'funcWrappers' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "getFuncWrapper")) Module["getFuncWrapper"] = function() {
		 abort("'getFuncWrapper' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "setMainLoop")) Module["setMainLoop"] = function() {
		 abort("'setMainLoop' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		Module["FS"] = FS;

		if (!Object.getOwnPropertyDescriptor(Module, "mmapAlloc")) Module["mmapAlloc"] = function() {
		 abort("'mmapAlloc' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "MEMFS")) Module["MEMFS"] = function() {
		 abort("'MEMFS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "TTY")) Module["TTY"] = function() {
		 abort("'TTY' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "PIPEFS")) Module["PIPEFS"] = function() {
		 abort("'PIPEFS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SOCKFS")) Module["SOCKFS"] = function() {
		 abort("'SOCKFS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "tempFixedLengthArray")) Module["tempFixedLengthArray"] = function() {
		 abort("'tempFixedLengthArray' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "miniTempWebGLFloatBuffers")) Module["miniTempWebGLFloatBuffers"] = function() {
		 abort("'miniTempWebGLFloatBuffers' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "heapObjectForWebGLType")) Module["heapObjectForWebGLType"] = function() {
		 abort("'heapObjectForWebGLType' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "heapAccessShiftForWebGLHeap")) Module["heapAccessShiftForWebGLHeap"] = function() {
		 abort("'heapAccessShiftForWebGLHeap' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "GL")) Module["GL"] = function() {
		 abort("'GL' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "emscriptenWebGLGet")) Module["emscriptenWebGLGet"] = function() {
		 abort("'emscriptenWebGLGet' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "computeUnpackAlignedImageSize")) Module["computeUnpackAlignedImageSize"] = function() {
		 abort("'computeUnpackAlignedImageSize' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "emscriptenWebGLGetTexPixelData")) Module["emscriptenWebGLGetTexPixelData"] = function() {
		 abort("'emscriptenWebGLGetTexPixelData' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "emscriptenWebGLGetUniform")) Module["emscriptenWebGLGetUniform"] = function() {
		 abort("'emscriptenWebGLGetUniform' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "emscriptenWebGLGetVertexAttrib")) Module["emscriptenWebGLGetVertexAttrib"] = function() {
		 abort("'emscriptenWebGLGetVertexAttrib' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "writeGLArray")) Module["writeGLArray"] = function() {
		 abort("'writeGLArray' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "AL")) Module["AL"] = function() {
		 abort("'AL' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SDL_unicode")) Module["SDL_unicode"] = function() {
		 abort("'SDL_unicode' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SDL_ttfContext")) Module["SDL_ttfContext"] = function() {
		 abort("'SDL_ttfContext' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SDL_audio")) Module["SDL_audio"] = function() {
		 abort("'SDL_audio' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SDL")) Module["SDL"] = function() {
		 abort("'SDL' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "SDL_gfx")) Module["SDL_gfx"] = function() {
		 abort("'SDL_gfx' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "GLUT")) Module["GLUT"] = function() {
		 abort("'GLUT' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "EGL")) Module["EGL"] = function() {
		 abort("'EGL' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "GLFW_Window")) Module["GLFW_Window"] = function() {
		 abort("'GLFW_Window' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "GLFW")) Module["GLFW"] = function() {
		 abort("'GLFW' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "GLEW")) Module["GLEW"] = function() {
		 abort("'GLEW' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "IDBStore")) Module["IDBStore"] = function() {
		 abort("'IDBStore' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "runAndAbortIfError")) Module["runAndAbortIfError"] = function() {
		 abort("'runAndAbortIfError' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "WORKERFS")) Module["WORKERFS"] = function() {
		 abort("'WORKERFS' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "warnOnce")) Module["warnOnce"] = function() {
		 abort("'warnOnce' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stackSave")) Module["stackSave"] = function() {
		 abort("'stackSave' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stackRestore")) Module["stackRestore"] = function() {
		 abort("'stackRestore' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stackAlloc")) Module["stackAlloc"] = function() {
		 abort("'stackAlloc' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "AsciiToString")) Module["AsciiToString"] = function() {
		 abort("'AsciiToString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stringToAscii")) Module["stringToAscii"] = function() {
		 abort("'stringToAscii' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "UTF16ToString")) Module["UTF16ToString"] = function() {
		 abort("'UTF16ToString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stringToUTF16")) Module["stringToUTF16"] = function() {
		 abort("'stringToUTF16' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "lengthBytesUTF16")) Module["lengthBytesUTF16"] = function() {
		 abort("'lengthBytesUTF16' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "UTF32ToString")) Module["UTF32ToString"] = function() {
		 abort("'UTF32ToString' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "stringToUTF32")) Module["stringToUTF32"] = function() {
		 abort("'stringToUTF32' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "lengthBytesUTF32")) Module["lengthBytesUTF32"] = function() {
		 abort("'lengthBytesUTF32' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "allocateUTF8")) Module["allocateUTF8"] = function() {
		 abort("'allocateUTF8' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		if (!Object.getOwnPropertyDescriptor(Module, "allocateUTF8OnStack")) Module["allocateUTF8OnStack"] = function() {
		 abort("'allocateUTF8OnStack' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		};

		Module["writeStackCookie"] = writeStackCookie;

		Module["checkStackCookie"] = checkStackCookie;

		if (!Object.getOwnPropertyDescriptor(Module, "ALLOC_NORMAL")) Object.defineProperty(Module, "ALLOC_NORMAL", {
		 configurable: true,
		 get: function() {
		  abort("'ALLOC_NORMAL' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		 }
		});

		if (!Object.getOwnPropertyDescriptor(Module, "ALLOC_STACK")) Object.defineProperty(Module, "ALLOC_STACK", {
		 configurable: true,
		 get: function() {
		  abort("'ALLOC_STACK' was not exported. add it to EXTRA_EXPORTED_RUNTIME_METHODS (see the FAQ)");
		 }
		});

		var calledRun;

		function ExitStatus(status) {
		 this.name = "ExitStatus";
		 this.message = "Program terminated with exit(" + status + ")";
		 this.status = status;
		}

		dependenciesFulfilled = function runCaller() {
		 if (!calledRun) run();
		 if (!calledRun) dependenciesFulfilled = runCaller;
		};

		function callMain(args) {
		 assert(runDependencies == 0, 'cannot call main when async dependencies remain! (listen on Module["onRuntimeInitialized"])');
		 assert(__ATPRERUN__.length == 0, "cannot call main when preRun functions remain to be called");
		 var entryFunction = Module["_main"];
		 args = args || [];
		 var argc = args.length + 1;
		 var argv = stackAlloc((argc + 1) * 4);
		 HEAP32[argv >> 2] = allocateUTF8OnStack(thisProgram);
		 for (var i = 1; i < argc; i++) {
		  HEAP32[(argv >> 2) + i] = allocateUTF8OnStack(args[i - 1]);
		 }
		 HEAP32[(argv >> 2) + argc] = 0;
		 try {
		  var ret = entryFunction(argc, argv);
		  exit(ret, true);
		 } catch (e) {
		  if (e instanceof ExitStatus) {
		   return;
		  } else if (e == "unwind") {
		   noExitRuntime = true;
		   return;
		  } else {
		   var toLog = e;
		   if (e && typeof e === "object" && e.stack) {
		    toLog = [ e, e.stack ];
		   }
		   err("exception thrown: " + toLog);
		   quit_(1, e);
		  }
		 } finally {
		 }
		}

		function run(args) {
		 args = args || arguments_;
		 if (runDependencies > 0) {
		  return;
		 }
		 _emscripten_stack_init();
		 writeStackCookie();
		 preRun();
		 if (runDependencies > 0) return;
		 function doRun() {
		  if (calledRun) return;
		  calledRun = true;
		  Module["calledRun"] = true;
		  if (ABORT) return;
		  initRuntime();
		  preMain();
		  readyPromiseResolve(Module);
		  if (Module["onRuntimeInitialized"]) Module["onRuntimeInitialized"]();
		  if (shouldRunNow) callMain(args);
		  postRun();
		 }
		 if (Module["setStatus"]) {
		  Module["setStatus"]("Running...");
		  setTimeout(function() {
		   setTimeout(function() {
		    Module["setStatus"]("");
		   }, 1);
		   doRun();
		  }, 1);
		 } else {
		  doRun();
		 }
		 checkStackCookie();
		}

		Module["run"] = run;

		function checkUnflushedContent() {
		 var oldOut = out;
		 var oldErr = err;
		 var has = false;
		 out = err = function(x) {
		  has = true;
		 };
		 try {
		  var flush = Module["_fflush"];
		  if (flush) flush(0);
		  [ "stdout", "stderr" ].forEach(function(name) {
		   var info = FS.analyzePath("/dev/" + name);
		   if (!info) return;
		   var stream = info.object;
		   var rdev = stream.rdev;
		   var tty = TTY.ttys[rdev];
		   if (tty && tty.output && tty.output.length) {
		    has = true;
		   }
		  });
		 } catch (e) {}
		 out = oldOut;
		 err = oldErr;
		 if (has) {
		  warnOnce("stdio streams had content in them that was not flushed. you should set EXIT_RUNTIME to 1 (see the FAQ), or make sure to emit a newline when you printf etc.");
		 }
		}

		function exit(status, implicit) {
		 checkUnflushedContent();
		 if (implicit && noExitRuntime && status === 0) {
		  return;
		 }
		 if (noExitRuntime) {
		  if (!implicit) {
		   var msg = "program exited (with status: " + status + "), but EXIT_RUNTIME is not set, so halting execution but not exiting the runtime or preventing further async execution (build with EXIT_RUNTIME=1, if you want a true shutdown)";
		   readyPromiseReject(msg);
		   err(msg);
		  }
		 } else {
		  exitRuntime();
		  if (Module["onExit"]) Module["onExit"](status);
		  ABORT = true;
		 }
		 quit_(status, new ExitStatus(status));
		}

		if (Module["preInit"]) {
		 if (typeof Module["preInit"] == "function") Module["preInit"] = [ Module["preInit"] ];
		 while (Module["preInit"].length > 0) {
		  Module["preInit"].pop()();
		 }
		}

		var shouldRunNow = true;

		if (Module["noInitialRun"]) shouldRunNow = false;

		noExitRuntime = true;

		run();


		  return trace_processor_wasm
		}
		);
		})();
		module.exports = trace_processor_wasm;
} (trace_processor));
	return trace_processorExports;
}

var hasRequiredWasm_bridge;

function requireWasm_bridge () {
	if (hasRequiredWasm_bridge) return wasm_bridge;
	hasRequiredWasm_bridge = 1;
	// Copyright (C) 2018 The Android Open Source Project
	//
	// Licensed under the Apache License, Version 2.0 (the "License");
	// you may not use this file except in compliance with the License.
	// You may obtain a copy of the License at
	//
	//      http://www.apache.org/licenses/LICENSE-2.0
	//
	// Unless required by applicable law or agreed to in writing, software
	// distributed under the License is distributed on an "AS IS" BASIS,
	// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	// See the License for the specific language governing permissions and
	// limitations under the License.
	Object.defineProperty(wasm_bridge, "__esModule", { value: true });
	wasm_bridge.WasmBridge = void 0;
	const tslib_1 = require$$0;
	const deferred_1 = requireDeferred();
	const logging_1 = requireLogging();
	const trace_processor_1 = tslib_1.__importDefault(requireTrace_processor());
	// The Initialize() call will allocate a buffer of REQ_BUF_SIZE bytes which
	// will be used to copy the input request data. This is to avoid passing the
	// input data on the stack, which has a limited (~1MB) size.
	// The buffer will be allocated by the C++ side and reachable at
	// HEAPU8[reqBufferAddr, +REQ_BUFFER_SIZE].
	const REQ_BUF_SIZE = 32 * 1024 * 1024;
	// The end-to-end interaction between JS and Wasm is as follows:
	// - [JS] Inbound data received by the worker (onmessage() in engine/index.ts).
	//   - [JS] onRpcDataReceived() (this file)
	//     - [C++] trace_processor_on_rpc_request (wasm_bridge.cc)
	//       - [C++] some TraceProcessor::method()
	//         for (batch in result_rows)
	//           - [C++] RpcResponseFunction(bytes) (wasm_bridge.cc)
	//             - [JS] onReply() (this file)
	//               - [JS] postMessage() (this file)
	class WasmBridge {
	    constructor() {
	        this.reqBufferAddr = 0;
	        this.lastStderr = [];
	        this.aborted = false;
	        const deferredRuntimeInitialized = (0, deferred_1.defer)();
	        this.connection = (0, trace_processor_1.default)({
	            locateFile: (s) => s,
	            print: (line) => console.log(line),
	            printErr: (line) => this.appendAndLogErr(line),
	            onRuntimeInitialized: () => deferredRuntimeInitialized.resolve(),
	        });
	        this.whenInitialized = deferredRuntimeInitialized.then(() => {
	            const fn = this.connection.addFunction(this.onReply.bind(this), 'vii');
	            this.reqBufferAddr = this.connection.ccall('trace_processor_rpc_init', 
	            /* return=*/ 'number', 
	            /* args=*/ ['number', 'number'], [fn, REQ_BUF_SIZE]);
	        });
	    }
	    initialize(port) {
	        // Ensure that initialize() is called only once.
	        (0, logging_1.assertTrue)(this.messagePort === undefined);
	        this.messagePort = port;
	        // Note: setting .onmessage implicitly calls port.start() and dispatches the
	        // queued messages. addEventListener('message') doesn't.
	        this.messagePort.onmessage = this.onMessage.bind(this);
	    }
	    onMessage(msg) {
	        if (this.aborted) {
	            throw new Error('Wasm module crashed');
	        }
	        (0, logging_1.assertTrue)(msg.data instanceof Uint8Array);
	        const data = msg.data;
	        let wrSize = 0;
	        // If the request data is larger than our JS<>Wasm interop buffer, split it
	        // into multiple writes. The RPC channel is byte-oriented and is designed to
	        // deal with arbitrary fragmentations.
	        while (wrSize < data.length) {
	            const sliceLen = Math.min(data.length - wrSize, REQ_BUF_SIZE);
	            const dataSlice = data.subarray(wrSize, wrSize + sliceLen);
	            this.connection.HEAPU8.set(dataSlice, this.reqBufferAddr);
	            wrSize += sliceLen;
	            try {
	                this.connection.ccall('trace_processor_on_rpc_request', // C function name.
	                'void', // Return type.
	                ['number'], // Arg types.
	                [sliceLen]);
	            }
	            catch (err) {
	                this.aborted = true;
	                let abortReason = `${err}`;
	                if (err instanceof Error) {
	                    abortReason = `${err.name}: ${err.message}\n${err.stack}`;
	                }
	                abortReason += '\n\nstderr: \n' + this.lastStderr.join('\n');
	                throw new Error(abortReason);
	            }
	        } // while(wrSize < data.length)
	    }
	    // This function is bound and passed to Initialize and is called by the C++
	    // code while in the ccall(trace_processor_on_rpc_request).
	    onReply(heapPtr, size) {
	        const data = this.connection.HEAPU8.slice(heapPtr, heapPtr + size);
	        (0, logging_1.assertExists)(this.messagePort).postMessage(data, [data.buffer]);
	    }
	    appendAndLogErr(line) {
	        console.warn(line);
	        // Keep the last N lines in the |lastStderr| buffer.
	        this.lastStderr.push(line);
	        if (this.lastStderr.length > 512) {
	            this.lastStderr.shift();
	        }
	    }
	}
	wasm_bridge.WasmBridge = WasmBridge;
	
	return wasm_bridge;
}

var hasRequiredEngine;

function requireEngine () {
	if (hasRequiredEngine) return engine;
	hasRequiredEngine = 1;
	// Copyright (C) 2018 The Android Open Source Project
	//
	// Licensed under the Apache License, Version 2.0 (the "License");
	// you may not use this file except in compliance with the License.
	// You may obtain a copy of the License at
	//
	//      http://www.apache.org/licenses/LICENSE-2.0
	//
	// Unless required by applicable law or agreed to in writing, software
	// distributed under the License is distributed on an "AS IS" BASIS,
	// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	// See the License for the specific language governing permissions and
	// limitations under the License.
	Object.defineProperty(engine, "__esModule", { value: true });
	const logging_1 = requireLogging();
	const wasm_bridge_1 = requireWasm_bridge();
	const selfWorker = self;
	const wasmBridge = new wasm_bridge_1.WasmBridge();
	// There are two message handlers here:
	// 1. The Worker (self.onmessage) handler.
	// 2. The MessagePort handler.
	// When the app bootstraps, frontend/index.ts creates a MessageChannel and sends
	// one end to the controller (the other worker) and the other end to us, so that
	// the controller can interact with the Wasm worker without roundtrips through
	// the frontend.
	// The sequence of actions is the following:
	// 1. The frontend does one postMessage({port: MessagePort}) on the Worker
	//    scope. This message transfers the MessagePort (whose other end is
	//    connected to the Conotroller). This is the only postMessage we'll ever
	//    receive here.
	// 2. All the other messages (i.e. the TraceProcessor RPC binary pipe) will be
	//    received on the MessagePort.
	// Receives the boostrap message from the frontend with the MessagePort.
	selfWorker.onmessage = (msg) => {
	    const port = (0, logging_1.assertExists)(msg.data.enginePort);
	    wasmBridge.initialize(port);
	};
	
	return engine;
}

var engineExports = requireEngine();
var index = /*@__PURE__*/getDefaultExportFromCjs(engineExports);

return index;

})();
//# sourceMappingURL=engine_bundle.js.map

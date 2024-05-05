"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.equals = exports.isVanillaObject = exports.isFunction = exports.isObject = exports.isArray = exports.comparable = exports.typeChecker = void 0;
const typeChecker = (type) => {
    const typeString = "[object " + type + "]";
    return function (value) {
        return getClassName(value) === typeString;
    };
};
exports.typeChecker = typeChecker;
const getClassName = value => Object.prototype.toString.call(value);
const comparable = (value) => {
    if (value instanceof Date) {
        return value.getTime();
    }
    else if ((0, exports.isArray)(value)) {
        return value.map(exports.comparable);
    }
    else if (value && typeof value.toJSON === "function") {
        return value.toJSON();
    }
    return value;
};
exports.comparable = comparable;
exports.isArray = (0, exports.typeChecker)("Array");
exports.isObject = (0, exports.typeChecker)("Object");
exports.isFunction = (0, exports.typeChecker)("Function");
const isVanillaObject = value => {
    return (value &&
        (value.constructor === Object ||
            value.constructor === Array ||
            value.constructor.toString() === "function Object() { [native code] }" ||
            value.constructor.toString() === "function Array() { [native code] }") &&
        !value.toJSON);
};
exports.isVanillaObject = isVanillaObject;
const equals = (a, b) => {
    if (a == null && a == b) {
        return true;
    }
    if (a === b) {
        return true;
    }
    if (Object.prototype.toString.call(a) !== Object.prototype.toString.call(b)) {
        return false;
    }
    if ((0, exports.isArray)(a)) {
        if (a.length !== b.length) {
            return false;
        }
        for (let i = 0, { length } = a; i < length; i++) {
            if (!(0, exports.equals)(a[i], b[i]))
                return false;
        }
        return true;
    }
    else if ((0, exports.isObject)(a)) {
        if (Object.keys(a).length !== Object.keys(b).length) {
            return false;
        }
        for (const key in a) {
            if (!(0, exports.equals)(a[key], b[key]))
                return false;
        }
        return true;
    }
    return false;
};
exports.equals = equals;
//# sourceMappingURL=utils.js.map
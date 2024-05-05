export type Key = string | number;
export type Comparator = (a, b) => boolean;
export const typeChecker = <TType>(type) => {
  const typeString = "[object " + type + "]";
  return function(value): value is TType {
    return getClassName(value) === typeString;
  };
};

const getClassName = value => Object.prototype.toString.call(value);

export const comparable = (value: any) => {
  if (value instanceof Date) {
    return value.getTime();
  } else if (isArray(value)) {
    return value.map(comparable);
  } else if (value && typeof value.toJSON === "function") {
    return value.toJSON();
  }

  return value;
};

export const isArray = typeChecker<Array<any>>("Array");
export const isObject = typeChecker<Object>("Object");
export const isFunction = typeChecker<Function>("Function");
export const isVanillaObject = value => {
  return (
    value &&
    (value.constructor === Object ||
      value.constructor === Array ||
      value.constructor.toString() === "function Object() { [native code] }" ||
      value.constructor.toString() === "function Array() { [native code] }") &&
    !value.toJSON
  );
};

export const equals = (a, b) => {
  if (a == null && a == b) {
    return true;
  }
  if (a === b) {
    return true;
  }

  if (Object.prototype.toString.call(a) !== Object.prototype.toString.call(b)) {
    return false;
  }

  if (isArray(a)) {
    if (a.length !== b.length) {
      return false;
    }
    for (let i = 0, { length } = a; i < length; i++) {
      if (!equals(a[i], b[i])) return false;
    }
    return true;
  } else if (isObject(a)) {
    if (Object.keys(a).length !== Object.keys(b).length) {
      return false;
    }
    for (const key in a) {
      if (!equals(a[key], b[key])) return false;
    }
    return true;
  }
  return false;
};

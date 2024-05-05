const typeChecker = (type) => {
    const typeString = "[object " + type + "]";
    return function (value) {
        return getClassName(value) === typeString;
    };
};
const getClassName = value => Object.prototype.toString.call(value);
const comparable = (value) => {
    if (value instanceof Date) {
        return value.getTime();
    }
    else if (isArray(value)) {
        return value.map(comparable);
    }
    else if (value && typeof value.toJSON === "function") {
        return value.toJSON();
    }
    return value;
};
const isArray = typeChecker("Array");
const isObject = typeChecker("Object");
const isFunction = typeChecker("Function");
const isVanillaObject = value => {
    return (value &&
        (value.constructor === Object ||
            value.constructor === Array ||
            value.constructor.toString() === "function Object() { [native code] }" ||
            value.constructor.toString() === "function Array() { [native code] }") &&
        !value.toJSON);
};
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
    if (isArray(a)) {
        if (a.length !== b.length) {
            return false;
        }
        for (let i = 0, { length } = a; i < length; i++) {
            if (!equals(a[i], b[i]))
                return false;
        }
        return true;
    }
    else if (isObject(a)) {
        if (Object.keys(a).length !== Object.keys(b).length) {
            return false;
        }
        for (const key in a) {
            if (!equals(a[key], b[key]))
                return false;
        }
        return true;
    }
    return false;
};

/**
 * Walks through each value given the context - used for nested operations. E.g:
 * { "person.address": { $eq: "blarg" }}
 */
const walkKeyPathValues = (item, keyPath, next, depth, key, owner) => {
    const currentKey = keyPath[depth];
    // if array, then try matching. Might fall through for cases like:
    // { $eq: [1, 2, 3] }, [ 1, 2, 3 ].
    if (isArray(item) && isNaN(Number(currentKey))) {
        for (let i = 0, { length } = item; i < length; i++) {
            // if FALSE is returned, then terminate walker. For operations, this simply
            // means that the search critera was met.
            if (!walkKeyPathValues(item[i], keyPath, next, depth, i, item)) {
                return false;
            }
        }
    }
    if (depth === keyPath.length || item == null) {
        return next(item, key, owner, depth === 0);
    }
    return walkKeyPathValues(item[currentKey], keyPath, next, depth + 1, currentKey, item);
};
class BaseOperation {
    constructor(params, owneryQuery, options, name) {
        this.params = params;
        this.owneryQuery = owneryQuery;
        this.options = options;
        this.name = name;
        this.init();
    }
    init() { }
    reset() {
        this.done = false;
        this.keep = false;
    }
}
class GroupOperation extends BaseOperation {
    constructor(params, owneryQuery, options, children) {
        super(params, owneryQuery, options);
        this.children = children;
    }
    /**
     */
    reset() {
        this.keep = false;
        this.done = false;
        for (let i = 0, { length } = this.children; i < length; i++) {
            this.children[i].reset();
        }
    }
    /**
     */
    childrenNext(item, key, owner, root) {
        let done = true;
        let keep = true;
        for (let i = 0, { length } = this.children; i < length; i++) {
            const childOperation = this.children[i];
            if (!childOperation.done) {
                childOperation.next(item, key, owner, root);
            }
            if (!childOperation.keep) {
                keep = false;
            }
            if (childOperation.done) {
                if (!childOperation.keep) {
                    break;
                }
            }
            else {
                done = false;
            }
        }
        this.done = done;
        this.keep = keep;
    }
}
class NamedGroupOperation extends GroupOperation {
    constructor(params, owneryQuery, options, children, name) {
        super(params, owneryQuery, options, children);
        this.name = name;
    }
}
class QueryOperation extends GroupOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    /**
     */
    next(item, key, parent, root) {
        this.childrenNext(item, key, parent, root);
    }
}
class NestedOperation extends GroupOperation {
    constructor(keyPath, params, owneryQuery, options, children) {
        super(params, owneryQuery, options, children);
        this.keyPath = keyPath;
        this.propop = true;
        /**
         */
        this._nextNestedValue = (value, key, owner, root) => {
            this.childrenNext(value, key, owner, root);
            return !this.done;
        };
    }
    /**
     */
    next(item, key, parent) {
        walkKeyPathValues(item, this.keyPath, this._nextNestedValue, 0, key, parent);
    }
}
const createTester = (a, compare) => {
    if (a instanceof Function) {
        return a;
    }
    if (a instanceof RegExp) {
        return b => {
            const result = typeof b === "string" && a.test(b);
            a.lastIndex = 0;
            return result;
        };
    }
    const comparableA = comparable(a);
    return b => compare(comparableA, comparable(b));
};
class EqualsOperation extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._test = createTester(this.params, this.options.compare);
    }
    next(item, key, parent) {
        if (!Array.isArray(parent) || parent.hasOwnProperty(key)) {
            if (this._test(item, key, parent)) {
                this.done = true;
                this.keep = true;
            }
        }
    }
}
const createEqualsOperation = (params, owneryQuery, options) => new EqualsOperation(params, owneryQuery, options);
class NopeOperation extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    next() {
        this.done = true;
        this.keep = false;
    }
}
const numericalOperationCreator = (createNumericalOperation) => (params, owneryQuery, options, name) => {
    if (params == null) {
        return new NopeOperation(params, owneryQuery, options, name);
    }
    return createNumericalOperation(params, owneryQuery, options, name);
};
const numericalOperation = (createTester) => numericalOperationCreator((params, owneryQuery, options, name) => {
    const typeofParams = typeof comparable(params);
    const test = createTester(params);
    return new EqualsOperation(b => {
        return typeof comparable(b) === typeofParams && test(b);
    }, owneryQuery, options, name);
});
const createNamedOperation = (name, params, parentQuery, options) => {
    const operationCreator = options.operations[name];
    if (!operationCreator) {
        throwUnsupportedOperation(name);
    }
    return operationCreator(params, parentQuery, options, name);
};
const throwUnsupportedOperation = (name) => {
    throw new Error(`Unsupported operation: ${name}`);
};
const containsOperation = (query, options) => {
    for (const key in query) {
        if (options.operations.hasOwnProperty(key) || key.charAt(0) === "$")
            return true;
    }
    return false;
};
const createNestedOperation = (keyPath, nestedQuery, parentKey, owneryQuery, options) => {
    if (containsOperation(nestedQuery, options)) {
        const [selfOperations, nestedOperations] = createQueryOperations(nestedQuery, parentKey, options);
        if (nestedOperations.length) {
            throw new Error(`Property queries must contain only operations, or exact objects.`);
        }
        return new NestedOperation(keyPath, nestedQuery, owneryQuery, options, selfOperations);
    }
    return new NestedOperation(keyPath, nestedQuery, owneryQuery, options, [
        new EqualsOperation(nestedQuery, owneryQuery, options)
    ]);
};
const createQueryOperation = (query, owneryQuery = null, { compare, operations } = {}) => {
    const options = {
        compare: compare || equals,
        operations: Object.assign({}, operations || {})
    };
    const [selfOperations, nestedOperations] = createQueryOperations(query, null, options);
    const ops = [];
    if (selfOperations.length) {
        ops.push(new NestedOperation([], query, owneryQuery, options, selfOperations));
    }
    ops.push(...nestedOperations);
    if (ops.length === 1) {
        return ops[0];
    }
    return new QueryOperation(query, owneryQuery, options, ops);
};
const createQueryOperations = (query, parentKey, options) => {
    const selfOperations = [];
    const nestedOperations = [];
    if (!isVanillaObject(query)) {
        selfOperations.push(new EqualsOperation(query, query, options));
        return [selfOperations, nestedOperations];
    }
    for (const key in query) {
        if (options.operations.hasOwnProperty(key)) {
            const op = createNamedOperation(key, query[key], query, options);
            if (op) {
                if (!op.propop && parentKey && !options.operations[parentKey]) {
                    throw new Error(`Malformed query. ${key} cannot be matched against property.`);
                }
            }
            // probably just a flag for another operation (like $options)
            if (op != null) {
                selfOperations.push(op);
            }
        }
        else if (key.charAt(0) === "$") {
            throwUnsupportedOperation(key);
        }
        else {
            nestedOperations.push(createNestedOperation(key.split("."), query[key], key, query, options));
        }
    }
    return [selfOperations, nestedOperations];
};
const createOperationTester = (operation) => (item, key, owner) => {
    operation.reset();
    operation.next(item, key, owner);
    return operation.keep;
};
const createQueryTester = (query, options = {}) => {
    return createOperationTester(createQueryOperation(query, null, options));
};

class $Ne extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._test = createTester(this.params, this.options.compare);
    }
    reset() {
        super.reset();
        this.keep = true;
    }
    next(item) {
        if (this._test(item)) {
            this.done = true;
            this.keep = false;
        }
    }
}
// https://docs.mongodb.com/manual/reference/operator/query/elemMatch/
class $ElemMatch extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        if (!this.params || typeof this.params !== "object") {
            throw new Error(`Malformed query. $elemMatch must by an object.`);
        }
        this._queryOperation = createQueryOperation(this.params, this.owneryQuery, this.options);
    }
    reset() {
        super.reset();
        this._queryOperation.reset();
    }
    next(item) {
        if (isArray(item)) {
            for (let i = 0, { length } = item; i < length; i++) {
                // reset query operation since item being tested needs to pass _all_ query
                // operations for it to be a success
                this._queryOperation.reset();
                const child = item[i];
                this._queryOperation.next(child, i, item, false);
                this.keep = this.keep || this._queryOperation.keep;
            }
            this.done = true;
        }
        else {
            this.done = false;
            this.keep = false;
        }
    }
}
class $Not extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._queryOperation = createQueryOperation(this.params, this.owneryQuery, this.options);
    }
    reset() {
        super.reset();
        this._queryOperation.reset();
    }
    next(item, key, owner, root) {
        this._queryOperation.next(item, key, owner, root);
        this.done = this._queryOperation.done;
        this.keep = !this._queryOperation.keep;
    }
}
class $Size extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() { }
    next(item) {
        if (isArray(item) && item.length === this.params) {
            this.done = true;
            this.keep = true;
        }
        // if (parent && parent.length === this.params) {
        //   this.done = true;
        //   this.keep = true;
        // }
    }
}
const assertGroupNotEmpty = (values) => {
    if (values.length === 0) {
        throw new Error(`$and/$or/$nor must be a nonempty array`);
    }
};
class $Or extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = false;
    }
    init() {
        assertGroupNotEmpty(this.params);
        this._ops = this.params.map(op => createQueryOperation(op, null, this.options));
    }
    reset() {
        this.done = false;
        this.keep = false;
        for (let i = 0, { length } = this._ops; i < length; i++) {
            this._ops[i].reset();
        }
    }
    next(item, key, owner) {
        let done = false;
        let success = false;
        for (let i = 0, { length } = this._ops; i < length; i++) {
            const op = this._ops[i];
            op.next(item, key, owner);
            if (op.keep) {
                done = true;
                success = op.keep;
                break;
            }
        }
        this.keep = success;
        this.done = done;
    }
}
class $Nor extends $Or {
    constructor() {
        super(...arguments);
        this.propop = false;
    }
    next(item, key, owner) {
        super.next(item, key, owner);
        this.keep = !this.keep;
    }
}
class $In extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._testers = this.params.map(value => {
            if (containsOperation(value, this.options)) {
                throw new Error(`cannot nest $ under ${this.name.toLowerCase()}`);
            }
            return createTester(value, this.options.compare);
        });
    }
    next(item, key, owner) {
        let done = false;
        let success = false;
        for (let i = 0, { length } = this._testers; i < length; i++) {
            const test = this._testers[i];
            if (test(item)) {
                done = true;
                success = true;
                break;
            }
        }
        this.keep = success;
        this.done = done;
    }
}
class $Nin extends BaseOperation {
    constructor(params, ownerQuery, options, name) {
        super(params, ownerQuery, options, name);
        this.propop = true;
        this._in = new $In(params, ownerQuery, options, name);
    }
    next(item, key, owner, root) {
        this._in.next(item, key, owner);
        if (isArray(owner) && !root) {
            if (this._in.keep) {
                this.keep = false;
                this.done = true;
            }
            else if (key == owner.length - 1) {
                this.keep = true;
                this.done = true;
            }
        }
        else {
            this.keep = !this._in.keep;
            this.done = true;
        }
    }
    reset() {
        super.reset();
        this._in.reset();
    }
}
class $Exists extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    next(item, key, owner) {
        if (owner.hasOwnProperty(key) === this.params) {
            this.done = true;
            this.keep = true;
        }
    }
}
class $And extends NamedGroupOperation {
    constructor(params, owneryQuery, options, name) {
        super(params, owneryQuery, options, params.map(query => createQueryOperation(query, owneryQuery, options)), name);
        this.propop = false;
        assertGroupNotEmpty(params);
    }
    next(item, key, owner, root) {
        this.childrenNext(item, key, owner, root);
    }
}
class $All extends NamedGroupOperation {
    constructor(params, owneryQuery, options, name) {
        super(params, owneryQuery, options, params.map(query => createQueryOperation(query, owneryQuery, options)), name);
        this.propop = true;
    }
    next(item, key, owner, root) {
        this.childrenNext(item, key, owner, root);
    }
}
const $eq = (params, owneryQuery, options) => new EqualsOperation(params, owneryQuery, options);
const $ne = (params, owneryQuery, options, name) => new $Ne(params, owneryQuery, options, name);
const $or = (params, owneryQuery, options, name) => new $Or(params, owneryQuery, options, name);
const $nor = (params, owneryQuery, options, name) => new $Nor(params, owneryQuery, options, name);
const $elemMatch = (params, owneryQuery, options, name) => new $ElemMatch(params, owneryQuery, options, name);
const $nin = (params, owneryQuery, options, name) => new $Nin(params, owneryQuery, options, name);
const $in = (params, owneryQuery, options, name) => {
    return new $In(params, owneryQuery, options, name);
};
const $lt = numericalOperation(params => b => b < params);
const $lte = numericalOperation(params => b => b <= params);
const $gt = numericalOperation(params => b => b > params);
const $gte = numericalOperation(params => b => b >= params);
const $mod = ([mod, equalsValue], owneryQuery, options) => new EqualsOperation(b => comparable(b) % mod === equalsValue, owneryQuery, options);
const $exists = (params, owneryQuery, options, name) => new $Exists(params, owneryQuery, options, name);
const $regex = (pattern, owneryQuery, options) => new EqualsOperation(new RegExp(pattern, owneryQuery.$options), owneryQuery, options);
const $not = (params, owneryQuery, options, name) => new $Not(params, owneryQuery, options, name);
const typeAliases = {
    number: v => typeof v === "number",
    string: v => typeof v === "string",
    bool: v => typeof v === "boolean",
    array: v => Array.isArray(v),
    null: v => v === null,
    timestamp: v => v instanceof Date
};
const $type = (clazz, owneryQuery, options) => new EqualsOperation(b => {
    if (typeof clazz === "string") {
        if (!typeAliases[clazz]) {
            throw new Error(`Type alias does not exist`);
        }
        return typeAliases[clazz](b);
    }
    return b != null ? b instanceof clazz || b.constructor === clazz : false;
}, owneryQuery, options);
const $and = (params, ownerQuery, options, name) => new $And(params, ownerQuery, options, name);
const $all = (params, ownerQuery, options, name) => new $All(params, ownerQuery, options, name);
const $size = (params, ownerQuery, options) => new $Size(params, ownerQuery, options, "$size");
const $options = () => null;
const $where = (params, ownerQuery, options) => {
    let test;
    if (isFunction(params)) {
        test = params;
    }
    else if (!process.env.CSP_ENABLED) {
        test = new Function("obj", "return " + params);
    }
    else {
        throw new Error(`In CSP mode, sift does not support strings in "$where" condition`);
    }
    return new EqualsOperation(b => test.bind(b)(b), ownerQuery, options);
};

var defaultOperations = /*#__PURE__*/Object.freeze({
    __proto__: null,
    $Size: $Size,
    $eq: $eq,
    $ne: $ne,
    $or: $or,
    $nor: $nor,
    $elemMatch: $elemMatch,
    $nin: $nin,
    $in: $in,
    $lt: $lt,
    $lte: $lte,
    $gt: $gt,
    $gte: $gte,
    $mod: $mod,
    $exists: $exists,
    $regex: $regex,
    $not: $not,
    $type: $type,
    $and: $and,
    $all: $all,
    $size: $size,
    $options: $options,
    $where: $where
});

const createDefaultQueryOperation = (query, ownerQuery, { compare, operations } = {}) => {
    return createQueryOperation(query, ownerQuery, {
        compare,
        operations: Object.assign({}, defaultOperations, operations || {})
    });
};
const createDefaultQueryTester = (query, options = {}) => {
    const op = createDefaultQueryOperation(query, null, options);
    return createOperationTester(op);
};

export default createDefaultQueryTester;
export { $Size, $all, $and, $elemMatch, $eq, $exists, $gt, $gte, $in, $lt, $lte, $mod, $ne, $nin, $nor, $not, $options, $or, $regex, $size, $type, $where, EqualsOperation, createDefaultQueryOperation, createEqualsOperation, createOperationTester, createQueryOperation, createQueryTester };
//# sourceMappingURL=index.js.map

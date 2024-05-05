"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createQueryTester = exports.createOperationTester = exports.createQueryOperation = exports.containsOperation = exports.numericalOperation = exports.numericalOperationCreator = exports.NopeOperation = exports.createEqualsOperation = exports.EqualsOperation = exports.createTester = exports.NestedOperation = exports.QueryOperation = exports.NamedGroupOperation = exports.BaseOperation = void 0;
const utils_1 = require("./utils");
/**
 * Walks through each value given the context - used for nested operations. E.g:
 * { "person.address": { $eq: "blarg" }}
 */
const walkKeyPathValues = (item, keyPath, next, depth, key, owner) => {
    const currentKey = keyPath[depth];
    // if array, then try matching. Might fall through for cases like:
    // { $eq: [1, 2, 3] }, [ 1, 2, 3 ].
    if ((0, utils_1.isArray)(item) && isNaN(Number(currentKey))) {
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
exports.BaseOperation = BaseOperation;
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
exports.NamedGroupOperation = NamedGroupOperation;
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
exports.QueryOperation = QueryOperation;
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
exports.NestedOperation = NestedOperation;
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
    const comparableA = (0, utils_1.comparable)(a);
    return b => compare(comparableA, (0, utils_1.comparable)(b));
};
exports.createTester = createTester;
class EqualsOperation extends BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._test = (0, exports.createTester)(this.params, this.options.compare);
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
exports.EqualsOperation = EqualsOperation;
const createEqualsOperation = (params, owneryQuery, options) => new EqualsOperation(params, owneryQuery, options);
exports.createEqualsOperation = createEqualsOperation;
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
exports.NopeOperation = NopeOperation;
const numericalOperationCreator = (createNumericalOperation) => (params, owneryQuery, options, name) => {
    if (params == null) {
        return new NopeOperation(params, owneryQuery, options, name);
    }
    return createNumericalOperation(params, owneryQuery, options, name);
};
exports.numericalOperationCreator = numericalOperationCreator;
const numericalOperation = (createTester) => (0, exports.numericalOperationCreator)((params, owneryQuery, options, name) => {
    const typeofParams = typeof (0, utils_1.comparable)(params);
    const test = createTester(params);
    return new EqualsOperation(b => {
        return typeof (0, utils_1.comparable)(b) === typeofParams && test(b);
    }, owneryQuery, options, name);
});
exports.numericalOperation = numericalOperation;
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
exports.containsOperation = containsOperation;
const createNestedOperation = (keyPath, nestedQuery, parentKey, owneryQuery, options) => {
    if ((0, exports.containsOperation)(nestedQuery, options)) {
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
        compare: compare || utils_1.equals,
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
exports.createQueryOperation = createQueryOperation;
const createQueryOperations = (query, parentKey, options) => {
    const selfOperations = [];
    const nestedOperations = [];
    if (!(0, utils_1.isVanillaObject)(query)) {
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
exports.createOperationTester = createOperationTester;
const createQueryTester = (query, options = {}) => {
    return (0, exports.createOperationTester)((0, exports.createQueryOperation)(query, null, options));
};
exports.createQueryTester = createQueryTester;
//# sourceMappingURL=core.js.map
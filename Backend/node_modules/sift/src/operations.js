"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.$where = exports.$options = exports.$size = exports.$all = exports.$and = exports.$type = exports.$not = exports.$regex = exports.$exists = exports.$mod = exports.$gte = exports.$gt = exports.$lte = exports.$lt = exports.$in = exports.$nin = exports.$elemMatch = exports.$nor = exports.$or = exports.$ne = exports.$eq = exports.$Size = void 0;
const core_1 = require("./core");
const utils_1 = require("./utils");
class $Ne extends core_1.BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._test = (0, core_1.createTester)(this.params, this.options.compare);
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
class $ElemMatch extends core_1.BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        if (!this.params || typeof this.params !== "object") {
            throw new Error(`Malformed query. $elemMatch must by an object.`);
        }
        this._queryOperation = (0, core_1.createQueryOperation)(this.params, this.owneryQuery, this.options);
    }
    reset() {
        super.reset();
        this._queryOperation.reset();
    }
    next(item) {
        if ((0, utils_1.isArray)(item)) {
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
class $Not extends core_1.BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._queryOperation = (0, core_1.createQueryOperation)(this.params, this.owneryQuery, this.options);
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
class $Size extends core_1.BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() { }
    next(item) {
        if ((0, utils_1.isArray)(item) && item.length === this.params) {
            this.done = true;
            this.keep = true;
        }
        // if (parent && parent.length === this.params) {
        //   this.done = true;
        //   this.keep = true;
        // }
    }
}
exports.$Size = $Size;
const assertGroupNotEmpty = (values) => {
    if (values.length === 0) {
        throw new Error(`$and/$or/$nor must be a nonempty array`);
    }
};
class $Or extends core_1.BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = false;
    }
    init() {
        assertGroupNotEmpty(this.params);
        this._ops = this.params.map(op => (0, core_1.createQueryOperation)(op, null, this.options));
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
class $In extends core_1.BaseOperation {
    constructor() {
        super(...arguments);
        this.propop = true;
    }
    init() {
        this._testers = this.params.map(value => {
            if ((0, core_1.containsOperation)(value, this.options)) {
                throw new Error(`cannot nest $ under ${this.name.toLowerCase()}`);
            }
            return (0, core_1.createTester)(value, this.options.compare);
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
class $Nin extends core_1.BaseOperation {
    constructor(params, ownerQuery, options, name) {
        super(params, ownerQuery, options, name);
        this.propop = true;
        this._in = new $In(params, ownerQuery, options, name);
    }
    next(item, key, owner, root) {
        this._in.next(item, key, owner);
        if ((0, utils_1.isArray)(owner) && !root) {
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
class $Exists extends core_1.BaseOperation {
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
class $And extends core_1.NamedGroupOperation {
    constructor(params, owneryQuery, options, name) {
        super(params, owneryQuery, options, params.map(query => (0, core_1.createQueryOperation)(query, owneryQuery, options)), name);
        this.propop = false;
        assertGroupNotEmpty(params);
    }
    next(item, key, owner, root) {
        this.childrenNext(item, key, owner, root);
    }
}
class $All extends core_1.NamedGroupOperation {
    constructor(params, owneryQuery, options, name) {
        super(params, owneryQuery, options, params.map(query => (0, core_1.createQueryOperation)(query, owneryQuery, options)), name);
        this.propop = true;
    }
    next(item, key, owner, root) {
        this.childrenNext(item, key, owner, root);
    }
}
const $eq = (params, owneryQuery, options) => new core_1.EqualsOperation(params, owneryQuery, options);
exports.$eq = $eq;
const $ne = (params, owneryQuery, options, name) => new $Ne(params, owneryQuery, options, name);
exports.$ne = $ne;
const $or = (params, owneryQuery, options, name) => new $Or(params, owneryQuery, options, name);
exports.$or = $or;
const $nor = (params, owneryQuery, options, name) => new $Nor(params, owneryQuery, options, name);
exports.$nor = $nor;
const $elemMatch = (params, owneryQuery, options, name) => new $ElemMatch(params, owneryQuery, options, name);
exports.$elemMatch = $elemMatch;
const $nin = (params, owneryQuery, options, name) => new $Nin(params, owneryQuery, options, name);
exports.$nin = $nin;
const $in = (params, owneryQuery, options, name) => {
    return new $In(params, owneryQuery, options, name);
};
exports.$in = $in;
exports.$lt = (0, core_1.numericalOperation)(params => b => b < params);
exports.$lte = (0, core_1.numericalOperation)(params => b => b <= params);
exports.$gt = (0, core_1.numericalOperation)(params => b => b > params);
exports.$gte = (0, core_1.numericalOperation)(params => b => b >= params);
const $mod = ([mod, equalsValue], owneryQuery, options) => new core_1.EqualsOperation(b => (0, utils_1.comparable)(b) % mod === equalsValue, owneryQuery, options);
exports.$mod = $mod;
const $exists = (params, owneryQuery, options, name) => new $Exists(params, owneryQuery, options, name);
exports.$exists = $exists;
const $regex = (pattern, owneryQuery, options) => new core_1.EqualsOperation(new RegExp(pattern, owneryQuery.$options), owneryQuery, options);
exports.$regex = $regex;
const $not = (params, owneryQuery, options, name) => new $Not(params, owneryQuery, options, name);
exports.$not = $not;
const typeAliases = {
    number: v => typeof v === "number",
    string: v => typeof v === "string",
    bool: v => typeof v === "boolean",
    array: v => Array.isArray(v),
    null: v => v === null,
    timestamp: v => v instanceof Date
};
const $type = (clazz, owneryQuery, options) => new core_1.EqualsOperation(b => {
    if (typeof clazz === "string") {
        if (!typeAliases[clazz]) {
            throw new Error(`Type alias does not exist`);
        }
        return typeAliases[clazz](b);
    }
    return b != null ? b instanceof clazz || b.constructor === clazz : false;
}, owneryQuery, options);
exports.$type = $type;
const $and = (params, ownerQuery, options, name) => new $And(params, ownerQuery, options, name);
exports.$and = $and;
const $all = (params, ownerQuery, options, name) => new $All(params, ownerQuery, options, name);
exports.$all = $all;
const $size = (params, ownerQuery, options) => new $Size(params, ownerQuery, options, "$size");
exports.$size = $size;
const $options = () => null;
exports.$options = $options;
const $where = (params, ownerQuery, options) => {
    let test;
    if ((0, utils_1.isFunction)(params)) {
        test = params;
    }
    else if (!process.env.CSP_ENABLED) {
        test = new Function("obj", "return " + params);
    }
    else {
        throw new Error(`In CSP mode, sift does not support strings in "$where" condition`);
    }
    return new core_1.EqualsOperation(b => test.bind(b)(b), ownerQuery, options);
};
exports.$where = $where;
//# sourceMappingURL=operations.js.map
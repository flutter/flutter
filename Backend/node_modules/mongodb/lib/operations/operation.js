"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defineAspects = exports.AbstractOperation = exports.Aspect = void 0;
const bson_1 = require("../bson");
const read_preference_1 = require("../read_preference");
exports.Aspect = {
    READ_OPERATION: Symbol('READ_OPERATION'),
    WRITE_OPERATION: Symbol('WRITE_OPERATION'),
    RETRYABLE: Symbol('RETRYABLE'),
    EXPLAINABLE: Symbol('EXPLAINABLE'),
    SKIP_COLLATION: Symbol('SKIP_COLLATION'),
    CURSOR_CREATING: Symbol('CURSOR_CREATING'),
    MUST_SELECT_SAME_SERVER: Symbol('MUST_SELECT_SAME_SERVER')
};
/** @internal */
const kSession = Symbol('session');
/**
 * This class acts as a parent class for any operation and is responsible for setting this.options,
 * as well as setting and getting a session.
 * Additionally, this class implements `hasAspect`, which determines whether an operation has
 * a specific aspect.
 * @internal
 */
class AbstractOperation {
    constructor(options = {}) {
        this.readPreference = this.hasAspect(exports.Aspect.WRITE_OPERATION)
            ? read_preference_1.ReadPreference.primary
            : read_preference_1.ReadPreference.fromOptions(options) ?? read_preference_1.ReadPreference.primary;
        // Pull the BSON serialize options from the already-resolved options
        this.bsonOptions = (0, bson_1.resolveBSONOptions)(options);
        this[kSession] = options.session != null ? options.session : undefined;
        this.options = options;
        this.bypassPinningCheck = !!options.bypassPinningCheck;
        this.trySecondaryWrite = false;
    }
    hasAspect(aspect) {
        const ctor = this.constructor;
        if (ctor.aspects == null) {
            return false;
        }
        return ctor.aspects.has(aspect);
    }
    get session() {
        return this[kSession];
    }
    clearSession() {
        this[kSession] = undefined;
    }
    get canRetryRead() {
        return true;
    }
    get canRetryWrite() {
        return true;
    }
}
exports.AbstractOperation = AbstractOperation;
function defineAspects(operation, aspects) {
    if (!Array.isArray(aspects) && !(aspects instanceof Set)) {
        aspects = [aspects];
    }
    aspects = new Set(aspects);
    Object.defineProperty(operation, 'aspects', {
        value: aspects,
        writable: false
    });
    return aspects;
}
exports.defineAspects = defineAspects;
//# sourceMappingURL=operation.js.map
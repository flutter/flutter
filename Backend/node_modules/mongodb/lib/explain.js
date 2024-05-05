"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Explain = exports.ExplainVerbosity = void 0;
const error_1 = require("./error");
/** @public */
exports.ExplainVerbosity = Object.freeze({
    queryPlanner: 'queryPlanner',
    queryPlannerExtended: 'queryPlannerExtended',
    executionStats: 'executionStats',
    allPlansExecution: 'allPlansExecution'
});
/** @internal */
class Explain {
    constructor(verbosity) {
        if (typeof verbosity === 'boolean') {
            this.verbosity = verbosity
                ? exports.ExplainVerbosity.allPlansExecution
                : exports.ExplainVerbosity.queryPlanner;
        }
        else {
            this.verbosity = verbosity;
        }
    }
    static fromOptions(options) {
        if (options?.explain == null)
            return;
        const explain = options.explain;
        if (typeof explain === 'boolean' || typeof explain === 'string') {
            return new Explain(explain);
        }
        throw new error_1.MongoInvalidArgumentError('Field "explain" must be a string or a boolean');
    }
}
exports.Explain = Explain;
//# sourceMappingURL=explain.js.map
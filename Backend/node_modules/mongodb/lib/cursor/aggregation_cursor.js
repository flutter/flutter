"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AggregationCursor = void 0;
const aggregate_1 = require("../operations/aggregate");
const execute_operation_1 = require("../operations/execute_operation");
const utils_1 = require("../utils");
const abstract_cursor_1 = require("./abstract_cursor");
/** @internal */
const kPipeline = Symbol('pipeline');
/** @internal */
const kOptions = Symbol('options');
/**
 * The **AggregationCursor** class is an internal class that embodies an aggregation cursor on MongoDB
 * allowing for iteration over the results returned from the underlying query. It supports
 * one by one document iteration, conversion to an array or can be iterated as a Node 4.X
 * or higher stream
 * @public
 */
class AggregationCursor extends abstract_cursor_1.AbstractCursor {
    /** @internal */
    constructor(client, namespace, pipeline = [], options = {}) {
        super(client, namespace, options);
        this[kPipeline] = pipeline;
        this[kOptions] = options;
    }
    get pipeline() {
        return this[kPipeline];
    }
    clone() {
        const clonedOptions = (0, utils_1.mergeOptions)({}, this[kOptions]);
        delete clonedOptions.session;
        return new AggregationCursor(this.client, this.namespace, this[kPipeline], {
            ...clonedOptions
        });
    }
    map(transform) {
        return super.map(transform);
    }
    /** @internal */
    async _initialize(session) {
        const aggregateOperation = new aggregate_1.AggregateOperation(this.namespace, this[kPipeline], {
            ...this[kOptions],
            ...this.cursorOptions,
            session
        });
        const response = await (0, execute_operation_1.executeOperation)(this.client, aggregateOperation);
        // TODO: NODE-2882
        return { server: aggregateOperation.server, session, response };
    }
    /** Execute the explain for the cursor */
    async explain(verbosity) {
        return (0, execute_operation_1.executeOperation)(this.client, new aggregate_1.AggregateOperation(this.namespace, this[kPipeline], {
            ...this[kOptions],
            ...this.cursorOptions,
            explain: verbosity ?? true
        }));
    }
    group($group) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $group });
        return this;
    }
    /** Add a limit stage to the aggregation pipeline */
    limit($limit) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $limit });
        return this;
    }
    /** Add a match stage to the aggregation pipeline */
    match($match) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $match });
        return this;
    }
    /** Add an out stage to the aggregation pipeline */
    out($out) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $out });
        return this;
    }
    /**
     * Add a project stage to the aggregation pipeline
     *
     * @remarks
     * In order to strictly type this function you must provide an interface
     * that represents the effect of your projection on the result documents.
     *
     * By default chaining a projection to your cursor changes the returned type to the generic {@link Document} type.
     * You should specify a parameterized type to have assertions on your final results.
     *
     * @example
     * ```typescript
     * // Best way
     * const docs: AggregationCursor<{ a: number }> = cursor.project<{ a: number }>({ _id: 0, a: true });
     * // Flexible way
     * const docs: AggregationCursor<Document> = cursor.project({ _id: 0, a: true });
     * ```
     *
     * @remarks
     * In order to strictly type this function you must provide an interface
     * that represents the effect of your projection on the result documents.
     *
     * **Note for Typescript Users:** adding a transform changes the return type of the iteration of this cursor,
     * it **does not** return a new instance of a cursor. This means when calling project,
     * you should always assign the result to a new variable in order to get a correctly typed cursor variable.
     * Take note of the following example:
     *
     * @example
     * ```typescript
     * const cursor: AggregationCursor<{ a: number; b: string }> = coll.aggregate([]);
     * const projectCursor = cursor.project<{ a: number }>({ _id: 0, a: true });
     * const aPropOnlyArray: {a: number}[] = await projectCursor.toArray();
     *
     * // or always use chaining and save the final cursor
     *
     * const cursor = coll.aggregate().project<{ a: string }>({
     *   _id: 0,
     *   a: { $convert: { input: '$a', to: 'string' }
     * }});
     * ```
     */
    project($project) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $project });
        return this;
    }
    /** Add a lookup stage to the aggregation pipeline */
    lookup($lookup) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $lookup });
        return this;
    }
    /** Add a redact stage to the aggregation pipeline */
    redact($redact) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $redact });
        return this;
    }
    /** Add a skip stage to the aggregation pipeline */
    skip($skip) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $skip });
        return this;
    }
    /** Add a sort stage to the aggregation pipeline */
    sort($sort) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $sort });
        return this;
    }
    /** Add a unwind stage to the aggregation pipeline */
    unwind($unwind) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $unwind });
        return this;
    }
    /** Add a geoNear stage to the aggregation pipeline */
    geoNear($geoNear) {
        (0, abstract_cursor_1.assertUninitialized)(this);
        this[kPipeline].push({ $geoNear });
        return this;
    }
}
exports.AggregationCursor = AggregationCursor;
//# sourceMappingURL=aggregation_cursor.js.map
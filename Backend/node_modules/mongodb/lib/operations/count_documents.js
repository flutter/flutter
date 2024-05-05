"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CountDocumentsOperation = void 0;
const aggregate_1 = require("./aggregate");
/** @internal */
class CountDocumentsOperation extends aggregate_1.AggregateOperation {
    constructor(collection, query, options) {
        const pipeline = [];
        pipeline.push({ $match: query });
        if (typeof options.skip === 'number') {
            pipeline.push({ $skip: options.skip });
        }
        if (typeof options.limit === 'number') {
            pipeline.push({ $limit: options.limit });
        }
        pipeline.push({ $group: { _id: 1, n: { $sum: 1 } } });
        super(collection.s.namespace, pipeline, options);
    }
    async execute(server, session) {
        const result = await super.execute(server, session);
        // NOTE: We're avoiding creating a cursor here to reduce the callstack.
        const response = result;
        if (response.cursor == null || response.cursor.firstBatch == null) {
            return 0;
        }
        const docs = response.cursor.firstBatch;
        return docs.length ? docs[0].n : 0;
    }
}
exports.CountDocumentsOperation = CountDocumentsOperation;
//# sourceMappingURL=count_documents.js.map
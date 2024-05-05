import type { Document } from '../bson';
import type { Collection } from '../collection';
import type { Server } from '../sdam/server';
import type { ClientSession } from '../sessions';
import { AggregateOperation, type AggregateOptions } from './aggregate';

/** @public */
export interface CountDocumentsOptions extends AggregateOptions {
  /** The number of documents to skip. */
  skip?: number;
  /** The maximum amounts to count before aborting. */
  limit?: number;
}

/** @internal */
export class CountDocumentsOperation extends AggregateOperation<number> {
  constructor(collection: Collection, query: Document, options: CountDocumentsOptions) {
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

  override async execute(server: Server, session: ClientSession | undefined): Promise<number> {
    const result = await super.execute(server, session);

    // NOTE: We're avoiding creating a cursor here to reduce the callstack.
    const response = result as unknown as Document;
    if (response.cursor == null || response.cursor.firstBatch == null) {
      return 0;
    }

    const docs = response.cursor.firstBatch;
    return docs.length ? docs[0].n : 0;
  }
}

import type {
  AnyBulkWriteOperation,
  BulkOperationBase,
  BulkWriteOptions,
  BulkWriteResult
} from '../bulk/common';
import type { Collection } from '../collection';
import type { Server } from '../sdam/server';
import type { ClientSession } from '../sessions';
import { AbstractOperation, Aspect, defineAspects } from './operation';

/** @internal */
export class BulkWriteOperation extends AbstractOperation<BulkWriteResult> {
  override options: BulkWriteOptions;
  collection: Collection;
  operations: AnyBulkWriteOperation[];

  constructor(
    collection: Collection,
    operations: AnyBulkWriteOperation[],
    options: BulkWriteOptions
  ) {
    super(options);
    this.options = options;
    this.collection = collection;
    this.operations = operations;
  }

  override get commandName() {
    return 'bulkWrite' as const;
  }

  override async execute(
    server: Server,
    session: ClientSession | undefined
  ): Promise<BulkWriteResult> {
    const coll = this.collection;
    const operations = this.operations;
    const options = { ...this.options, ...this.bsonOptions, readPreference: this.readPreference };

    // Create the bulk operation
    const bulk: BulkOperationBase =
      options.ordered === false
        ? coll.initializeUnorderedBulkOp(options)
        : coll.initializeOrderedBulkOp(options);

    // for each op go through and add to the bulk
    for (let i = 0; i < operations.length; i++) {
      bulk.raw(operations[i]);
    }

    // Execute the bulk
    const result = await bulk.execute({ ...options, session });
    return result;
  }
}

defineAspects(BulkWriteOperation, [Aspect.WRITE_OPERATION]);

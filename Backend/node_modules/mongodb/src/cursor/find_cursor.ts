import { type Document, Long } from '../bson';
import { MongoInvalidArgumentError, MongoTailableCursorError } from '../error';
import { type ExplainVerbosityLike } from '../explain';
import type { MongoClient } from '../mongo_client';
import type { CollationOptions } from '../operations/command';
import { CountOperation, type CountOptions } from '../operations/count';
import { executeOperation, type ExecutionResult } from '../operations/execute_operation';
import { FindOperation, type FindOptions } from '../operations/find';
import type { Hint } from '../operations/operation';
import type { ClientSession } from '../sessions';
import { formatSort, type Sort, type SortDirection } from '../sort';
import { emitWarningOnce, mergeOptions, type MongoDBNamespace } from '../utils';
import { AbstractCursor, assertUninitialized } from './abstract_cursor';

/** @internal */
const kFilter = Symbol('filter');
/** @internal */
const kNumReturned = Symbol('numReturned');
/** @internal */
const kBuiltOptions = Symbol('builtOptions');

/** @public Flags allowed for cursor */
export const FLAGS = [
  'tailable',
  'oplogReplay',
  'noCursorTimeout',
  'awaitData',
  'exhaust',
  'partial'
] as const;

/** @public */
export class FindCursor<TSchema = any> extends AbstractCursor<TSchema> {
  /** @internal */
  [kFilter]: Document;
  /** @internal */
  [kNumReturned]?: number;
  /** @internal */
  [kBuiltOptions]: FindOptions;

  /** @internal */
  constructor(
    client: MongoClient,
    namespace: MongoDBNamespace,
    filter: Document = {},
    options: FindOptions = {}
  ) {
    super(client, namespace, options);

    this[kFilter] = filter;
    this[kBuiltOptions] = options;

    if (options.sort != null) {
      this[kBuiltOptions].sort = formatSort(options.sort);
    }
  }

  clone(): FindCursor<TSchema> {
    const clonedOptions = mergeOptions({}, this[kBuiltOptions]);
    delete clonedOptions.session;
    return new FindCursor(this.client, this.namespace, this[kFilter], {
      ...clonedOptions
    });
  }

  override map<T>(transform: (doc: TSchema) => T): FindCursor<T> {
    return super.map(transform) as FindCursor<T>;
  }

  /** @internal */
  async _initialize(session: ClientSession): Promise<ExecutionResult> {
    const findOperation = new FindOperation(undefined, this.namespace, this[kFilter], {
      ...this[kBuiltOptions], // NOTE: order matters here, we may need to refine this
      ...this.cursorOptions,
      session
    });

    const response = await executeOperation(this.client, findOperation);

    // the response is not a cursor when `explain` is enabled
    this[kNumReturned] = response.cursor?.firstBatch?.length;

    // TODO: NODE-2882
    return { server: findOperation.server, session, response };
  }

  /** @internal */
  override async getMore(batchSize: number): Promise<Document | null> {
    const numReturned = this[kNumReturned];
    if (numReturned) {
      // TODO(DRIVERS-1448): Remove logic to enforce `limit` in the driver
      const limit = this[kBuiltOptions].limit;
      batchSize =
        limit && limit > 0 && numReturned + batchSize > limit ? limit - numReturned : batchSize;

      if (batchSize <= 0) {
        // this is an optimization for the special case of a limit for a find command to avoid an
        // extra getMore when the limit has been reached and the limit is a multiple of the batchSize.
        // This is a consequence of the new query engine in 5.0 having no knowledge of the limit as it
        // produces results for the find command.  Once a batch is filled up, it is returned and only
        // on the subsequent getMore will the query framework consider the limit, determine the cursor
        // is exhausted and return a cursorId of zero.
        // instead, if we determine there are no more documents to request from the server, we preemptively
        // close the cursor
        await this.close().catch(() => null);
        return { cursor: { id: Long.ZERO, nextBatch: [] } };
      }
    }

    const response = await super.getMore(batchSize);
    // TODO: wrap this in some logic to prevent it from happening if we don't need this support
    if (response) {
      this[kNumReturned] = this[kNumReturned] + response.cursor.nextBatch.length;
    }

    return response;
  }

  /**
   * Get the count of documents for this cursor
   * @deprecated Use `collection.estimatedDocumentCount` or `collection.countDocuments` instead
   */
  async count(options?: CountOptions): Promise<number> {
    emitWarningOnce(
      'cursor.count is deprecated and will be removed in the next major version, please use `collection.estimatedDocumentCount` or `collection.countDocuments` instead '
    );
    if (typeof options === 'boolean') {
      throw new MongoInvalidArgumentError('Invalid first parameter to count');
    }
    return executeOperation(
      this.client,
      new CountOperation(this.namespace, this[kFilter], {
        ...this[kBuiltOptions], // NOTE: order matters here, we may need to refine this
        ...this.cursorOptions,
        ...options
      })
    );
  }

  /** Execute the explain for the cursor */
  async explain(verbosity?: ExplainVerbosityLike): Promise<Document> {
    return executeOperation(
      this.client,
      new FindOperation(undefined, this.namespace, this[kFilter], {
        ...this[kBuiltOptions], // NOTE: order matters here, we may need to refine this
        ...this.cursorOptions,
        explain: verbosity ?? true
      })
    );
  }

  /** Set the cursor query */
  filter(filter: Document): this {
    assertUninitialized(this);
    this[kFilter] = filter;
    return this;
  }

  /**
   * Set the cursor hint
   *
   * @param hint - If specified, then the query system will only consider plans using the hinted index.
   */
  hint(hint: Hint): this {
    assertUninitialized(this);
    this[kBuiltOptions].hint = hint;
    return this;
  }

  /**
   * Set the cursor min
   *
   * @param min - Specify a $min value to specify the inclusive lower bound for a specific index in order to constrain the results of find(). The $min specifies the lower bound for all keys of a specific index in order.
   */
  min(min: Document): this {
    assertUninitialized(this);
    this[kBuiltOptions].min = min;
    return this;
  }

  /**
   * Set the cursor max
   *
   * @param max - Specify a $max value to specify the exclusive upper bound for a specific index in order to constrain the results of find(). The $max specifies the upper bound for all keys of a specific index in order.
   */
  max(max: Document): this {
    assertUninitialized(this);
    this[kBuiltOptions].max = max;
    return this;
  }

  /**
   * Set the cursor returnKey.
   * If set to true, modifies the cursor to only return the index field or fields for the results of the query, rather than documents.
   * If set to true and the query does not use an index to perform the read operation, the returned documents will not contain any fields.
   *
   * @param value - the returnKey value.
   */
  returnKey(value: boolean): this {
    assertUninitialized(this);
    this[kBuiltOptions].returnKey = value;
    return this;
  }

  /**
   * Modifies the output of a query by adding a field $recordId to matching documents. $recordId is the internal key which uniquely identifies a document in a collection.
   *
   * @param value - The $showDiskLoc option has now been deprecated and replaced with the showRecordId field. $showDiskLoc will still be accepted for OP_QUERY stye find.
   */
  showRecordId(value: boolean): this {
    assertUninitialized(this);
    this[kBuiltOptions].showRecordId = value;
    return this;
  }

  /**
   * Add a query modifier to the cursor query
   *
   * @param name - The query modifier (must start with $, such as $orderby etc)
   * @param value - The modifier value.
   */
  addQueryModifier(name: string, value: string | boolean | number | Document): this {
    assertUninitialized(this);
    if (name[0] !== '$') {
      throw new MongoInvalidArgumentError(`${name} is not a valid query modifier`);
    }

    // Strip of the $
    const field = name.substr(1);

    // NOTE: consider some TS magic for this
    switch (field) {
      case 'comment':
        this[kBuiltOptions].comment = value as string | Document;
        break;

      case 'explain':
        this[kBuiltOptions].explain = value as boolean;
        break;

      case 'hint':
        this[kBuiltOptions].hint = value as string | Document;
        break;

      case 'max':
        this[kBuiltOptions].max = value as Document;
        break;

      case 'maxTimeMS':
        this[kBuiltOptions].maxTimeMS = value as number;
        break;

      case 'min':
        this[kBuiltOptions].min = value as Document;
        break;

      case 'orderby':
        this[kBuiltOptions].sort = formatSort(value as string | Document);
        break;

      case 'query':
        this[kFilter] = value as Document;
        break;

      case 'returnKey':
        this[kBuiltOptions].returnKey = value as boolean;
        break;

      case 'showDiskLoc':
        this[kBuiltOptions].showRecordId = value as boolean;
        break;

      default:
        throw new MongoInvalidArgumentError(`Invalid query modifier: ${name}`);
    }

    return this;
  }

  /**
   * Add a comment to the cursor query allowing for tracking the comment in the log.
   *
   * @param value - The comment attached to this query.
   */
  comment(value: string): this {
    assertUninitialized(this);
    this[kBuiltOptions].comment = value;
    return this;
  }

  /**
   * Set a maxAwaitTimeMS on a tailing cursor query to allow to customize the timeout value for the option awaitData (Only supported on MongoDB 3.2 or higher, ignored otherwise)
   *
   * @param value - Number of milliseconds to wait before aborting the tailed query.
   */
  maxAwaitTimeMS(value: number): this {
    assertUninitialized(this);
    if (typeof value !== 'number') {
      throw new MongoInvalidArgumentError('Argument for maxAwaitTimeMS must be a number');
    }

    this[kBuiltOptions].maxAwaitTimeMS = value;
    return this;
  }

  /**
   * Set a maxTimeMS on the cursor query, allowing for hard timeout limits on queries (Only supported on MongoDB 2.6 or higher)
   *
   * @param value - Number of milliseconds to wait before aborting the query.
   */
  override maxTimeMS(value: number): this {
    assertUninitialized(this);
    if (typeof value !== 'number') {
      throw new MongoInvalidArgumentError('Argument for maxTimeMS must be a number');
    }

    this[kBuiltOptions].maxTimeMS = value;
    return this;
  }

  /**
   * Add a project stage to the aggregation pipeline
   *
   * @remarks
   * In order to strictly type this function you must provide an interface
   * that represents the effect of your projection on the result documents.
   *
   * By default chaining a projection to your cursor changes the returned type to the generic
   * {@link Document} type.
   * You should specify a parameterized type to have assertions on your final results.
   *
   * @example
   * ```typescript
   * // Best way
   * const docs: FindCursor<{ a: number }> = cursor.project<{ a: number }>({ _id: 0, a: true });
   * // Flexible way
   * const docs: FindCursor<Document> = cursor.project({ _id: 0, a: true });
   * ```
   *
   * @remarks
   *
   * **Note for Typescript Users:** adding a transform changes the return type of the iteration of this cursor,
   * it **does not** return a new instance of a cursor. This means when calling project,
   * you should always assign the result to a new variable in order to get a correctly typed cursor variable.
   * Take note of the following example:
   *
   * @example
   * ```typescript
   * const cursor: FindCursor<{ a: number; b: string }> = coll.find();
   * const projectCursor = cursor.project<{ a: number }>({ _id: 0, a: true });
   * const aPropOnlyArray: {a: number}[] = await projectCursor.toArray();
   *
   * // or always use chaining and save the final cursor
   *
   * const cursor = coll.find().project<{ a: string }>({
   *   _id: 0,
   *   a: { $convert: { input: '$a', to: 'string' }
   * }});
   * ```
   */
  project<T extends Document = Document>(value: Document): FindCursor<T> {
    assertUninitialized(this);
    this[kBuiltOptions].projection = value;
    return this as unknown as FindCursor<T>;
  }

  /**
   * Sets the sort order of the cursor query.
   *
   * @param sort - The key or keys set for the sort.
   * @param direction - The direction of the sorting (1 or -1).
   */
  sort(sort: Sort | string, direction?: SortDirection): this {
    assertUninitialized(this);
    if (this[kBuiltOptions].tailable) {
      throw new MongoTailableCursorError('Tailable cursor does not support sorting');
    }

    this[kBuiltOptions].sort = formatSort(sort, direction);
    return this;
  }

  /**
   * Allows disk use for blocking sort operations exceeding 100MB memory. (MongoDB 3.2 or higher)
   *
   * @remarks
   * {@link https://www.mongodb.com/docs/manual/reference/command/find/#find-cmd-allowdiskuse | find command allowDiskUse documentation}
   */
  allowDiskUse(allow = true): this {
    assertUninitialized(this);

    if (!this[kBuiltOptions].sort) {
      throw new MongoInvalidArgumentError('Option "allowDiskUse" requires a sort specification');
    }

    // As of 6.0 the default is true. This allows users to get back to the old behavior.
    if (!allow) {
      this[kBuiltOptions].allowDiskUse = false;
      return this;
    }

    this[kBuiltOptions].allowDiskUse = true;
    return this;
  }

  /**
   * Set the collation options for the cursor.
   *
   * @param value - The cursor collation options (MongoDB 3.4 or higher) settings for update operation (see 3.4 documentation for available fields).
   */
  collation(value: CollationOptions): this {
    assertUninitialized(this);
    this[kBuiltOptions].collation = value;
    return this;
  }

  /**
   * Set the limit for the cursor.
   *
   * @param value - The limit for the cursor query.
   */
  limit(value: number): this {
    assertUninitialized(this);
    if (this[kBuiltOptions].tailable) {
      throw new MongoTailableCursorError('Tailable cursor does not support limit');
    }

    if (typeof value !== 'number') {
      throw new MongoInvalidArgumentError('Operation "limit" requires an integer');
    }

    this[kBuiltOptions].limit = value;
    return this;
  }

  /**
   * Set the skip for the cursor.
   *
   * @param value - The skip for the cursor query.
   */
  skip(value: number): this {
    assertUninitialized(this);
    if (this[kBuiltOptions].tailable) {
      throw new MongoTailableCursorError('Tailable cursor does not support skip');
    }

    if (typeof value !== 'number') {
      throw new MongoInvalidArgumentError('Operation "skip" requires an integer');
    }

    this[kBuiltOptions].skip = value;
    return this;
  }
}

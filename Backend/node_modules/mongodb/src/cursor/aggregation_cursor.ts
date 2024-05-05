import type { Document } from '../bson';
import type { ExplainVerbosityLike } from '../explain';
import type { MongoClient } from '../mongo_client';
import { AggregateOperation, type AggregateOptions } from '../operations/aggregate';
import { executeOperation, type ExecutionResult } from '../operations/execute_operation';
import type { ClientSession } from '../sessions';
import type { Sort } from '../sort';
import type { MongoDBNamespace } from '../utils';
import { mergeOptions } from '../utils';
import type { AbstractCursorOptions } from './abstract_cursor';
import { AbstractCursor, assertUninitialized } from './abstract_cursor';

/** @public */
export interface AggregationCursorOptions extends AbstractCursorOptions, AggregateOptions {}

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
export class AggregationCursor<TSchema = any> extends AbstractCursor<TSchema> {
  /** @internal */
  [kPipeline]: Document[];
  /** @internal */
  [kOptions]: AggregateOptions;

  /** @internal */
  constructor(
    client: MongoClient,
    namespace: MongoDBNamespace,
    pipeline: Document[] = [],
    options: AggregateOptions = {}
  ) {
    super(client, namespace, options);

    this[kPipeline] = pipeline;
    this[kOptions] = options;
  }

  get pipeline(): Document[] {
    return this[kPipeline];
  }

  clone(): AggregationCursor<TSchema> {
    const clonedOptions = mergeOptions({}, this[kOptions]);
    delete clonedOptions.session;
    return new AggregationCursor(this.client, this.namespace, this[kPipeline], {
      ...clonedOptions
    });
  }

  override map<T>(transform: (doc: TSchema) => T): AggregationCursor<T> {
    return super.map(transform) as AggregationCursor<T>;
  }

  /** @internal */
  async _initialize(session: ClientSession): Promise<ExecutionResult> {
    const aggregateOperation = new AggregateOperation(this.namespace, this[kPipeline], {
      ...this[kOptions],
      ...this.cursorOptions,
      session
    });

    const response = await executeOperation(this.client, aggregateOperation);

    // TODO: NODE-2882
    return { server: aggregateOperation.server, session, response };
  }

  /** Execute the explain for the cursor */
  async explain(verbosity?: ExplainVerbosityLike): Promise<Document> {
    return executeOperation(
      this.client,
      new AggregateOperation(this.namespace, this[kPipeline], {
        ...this[kOptions], // NOTE: order matters here, we may need to refine this
        ...this.cursorOptions,
        explain: verbosity ?? true
      })
    );
  }

  /** Add a group stage to the aggregation pipeline */
  group<T = TSchema>($group: Document): AggregationCursor<T>;
  group($group: Document): this {
    assertUninitialized(this);
    this[kPipeline].push({ $group });
    return this;
  }

  /** Add a limit stage to the aggregation pipeline */
  limit($limit: number): this {
    assertUninitialized(this);
    this[kPipeline].push({ $limit });
    return this;
  }

  /** Add a match stage to the aggregation pipeline */
  match($match: Document): this {
    assertUninitialized(this);
    this[kPipeline].push({ $match });
    return this;
  }

  /** Add an out stage to the aggregation pipeline */
  out($out: { db: string; coll: string } | string): this {
    assertUninitialized(this);
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
  project<T extends Document = Document>($project: Document): AggregationCursor<T> {
    assertUninitialized(this);
    this[kPipeline].push({ $project });
    return this as unknown as AggregationCursor<T>;
  }

  /** Add a lookup stage to the aggregation pipeline */
  lookup($lookup: Document): this {
    assertUninitialized(this);
    this[kPipeline].push({ $lookup });
    return this;
  }

  /** Add a redact stage to the aggregation pipeline */
  redact($redact: Document): this {
    assertUninitialized(this);
    this[kPipeline].push({ $redact });
    return this;
  }

  /** Add a skip stage to the aggregation pipeline */
  skip($skip: number): this {
    assertUninitialized(this);
    this[kPipeline].push({ $skip });
    return this;
  }

  /** Add a sort stage to the aggregation pipeline */
  sort($sort: Sort): this {
    assertUninitialized(this);
    this[kPipeline].push({ $sort });
    return this;
  }

  /** Add a unwind stage to the aggregation pipeline */
  unwind($unwind: Document | string): this {
    assertUninitialized(this);
    this[kPipeline].push({ $unwind });
    return this;
  }

  /** Add a geoNear stage to the aggregation pipeline */
  geoNear($geoNear: Document): this {
    assertUninitialized(this);
    this[kPipeline].push({ $geoNear });
    return this;
  }
}

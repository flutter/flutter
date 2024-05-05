declare module 'mongoose' {

  import stream = require('stream');

  type CursorFlag = 'tailable' | 'oplogReplay' | 'noCursorTimeout' | 'awaitData' | 'partial';

  interface EachAsyncOptions {
    parallel?: number;
    batchSize?: number;
    continueOnError?: boolean;
  }

  class Cursor<DocType = any, Options = never> extends stream.Readable {
    [Symbol.asyncIterator](): AsyncIterableIterator<DocType>;

    /**
     * Adds a [cursor flag](https://mongodb.github.io/node-mongodb-native/4.9/classes/FindCursor.html#addCursorFlag).
     * Useful for setting the `noCursorTimeout` and `tailable` flags.
     */
    addCursorFlag(flag: CursorFlag, value: boolean): this;

    /**
     * Marks this cursor as closed. Will stop streaming and subsequent calls to
     * `next()` will error.
     */
    close(): Promise<void>;

    /**
     * Rewind this cursor to its uninitialized state. Any options that are present on the cursor will
     * remain in effect. Iterating this cursor will cause new queries to be sent to the server, even
     * if the resultant data has already been retrieved by this cursor.
     */
    rewind(): this;

    /**
     * Execute `fn` for every document(s) in the cursor. If batchSize is provided
     * `fn` will be executed for each batch of documents. If `fn` returns a promise,
     * will wait for the promise to resolve before iterating on to the next one.
     * Returns a promise that resolves when done.
     */
    eachAsync(fn: (doc: DocType[], i: number) => any, options: EachAsyncOptions & { batchSize: number }): Promise<void>;
    eachAsync(fn: (doc: DocType, i: number) => any, options?: EachAsyncOptions): Promise<void>;

    /**
     * Registers a transform function which subsequently maps documents retrieved
     * via the streams interface or `.next()`
     */
    map<ResultType>(fn: (res: DocType) => ResultType): Cursor<ResultType, Options>;

    /**
     * Get the next document from this cursor. Will return `null` when there are
     * no documents left.
     */
    next(): Promise<DocType>;

    options: Options;
  }
}

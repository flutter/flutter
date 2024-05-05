
declare module 'mongoose' {
  import mongodb = require('mongodb');
  import bson = require('bson');

  class NativeBuffer extends Buffer {}

  namespace Types {
    class Array<T> extends global.Array<T> {
      /** Pops the array atomically at most one time per document `save()`. */
      $pop(): T;

      /** Atomically shifts the array at most one time per document `save()`. */
      $shift(): T;

      /** Adds values to the array if not already present. */
      addToSet(...args: any[]): any[];

      isMongooseArray: true;

      /** Pushes items to the array non-atomically. */
      nonAtomicPush(...args: any[]): number;

      /** Wraps [`Array#push`](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/push) with proper change tracking. */
      push(...args: any[]): number;

      /**
       * Pulls items from the array atomically. Equality is determined by casting
       * the provided value to an embedded document and comparing using
       * [the `Document.equals()` function.](./api/document.html#document_Document-equals)
       */
      pull(...args: any[]): this;

      /**
       * Alias of [pull](#mongoosearray_MongooseArray-pull)
       */
      remove(...args: any[]): this;

      /** Sets the casted `val` at index `i` and marks the array modified. */
      set(index: number, val: T): this;

      /** Atomically shifts the array at most one time per document `save()`. */
      shift(): T;

      /** Returns a native js Array. */
      toObject(options?: ToObjectOptions): any;
      toObject<T>(options?: ToObjectOptions<T>): T;

      /** Wraps [`Array#unshift`](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array/unshift) with proper change tracking. */
      unshift(...args: any[]): number;
    }

    class Buffer extends NativeBuffer {
      /** Sets the subtype option and marks the buffer modified. */
      subtype(subtype: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 128 | ToObjectOptions): void;

      /** Converts this buffer to its Binary type representation. */
      toObject(subtype?: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 128): mongodb.Binary;
    }

    class Decimal128 extends mongodb.Decimal128 { }

    class DocumentArray<T> extends Types.Array<T extends Types.Subdocument ? T : Types.Subdocument<InferId<T>, any, T> & T> {
      /** DocumentArray constructor */
      constructor(values: AnyObject[]);

      isMongooseDocumentArray: true;

      /** Creates a subdocument casted to this schema. */
      create(obj: any): T extends Types.Subdocument ? T : Types.Subdocument<InferId<T>> & T;

      /** Searches array items for the first document with a matching _id. */
      id(id: any): (T extends Types.Subdocument ? T : Types.Subdocument<InferId<T>> & T) | null;

      push(...args: (AnyKeys<T> & AnyObject)[]): number;
    }

    class Map<V> extends global.Map<string, V> {
      /** Converts a Mongoose map into a vanilla JavaScript map. */
      toObject(options?: ToObjectOptions & { flattenMaps?: boolean }): any;
    }

    class ObjectId extends mongodb.ObjectId {
    }

    class Subdocument<IdType = any, TQueryHelpers = any, DocType = any> extends Document<IdType, TQueryHelpers, DocType> {
      $isSingleNested: true;

      /** Returns the top level document of this sub-document. */
      ownerDocument(): Document;

      /** Returns this sub-documents parent document. */
      parent(): Document;

      /** Returns this sub-documents parent document. */
      $parent(): Document;
    }

    class ArraySubdocument<IdType = any> extends Subdocument<IdType> {
      /** Returns this sub-documents parent array. */
      parentArray(): Types.DocumentArray<unknown>;
    }

    class UUID extends bson.UUID {}
  }
}

import {
  isArray,
  Key,
  Comparator,
  isVanillaObject,
  comparable,
  equals
} from "./utils";

export interface Operation<TItem> {
  readonly keep: boolean;
  readonly done: boolean;
  propop: boolean;
  reset();
  next(item: TItem, key?: Key, owner?: any, root?: boolean);
}

export type Tester = (
  item: any,
  key?: Key,
  owner?: any,
  root?: boolean
) => boolean;

export interface NamedOperation {
  name: string;
}

export type OperationCreator<TItem> = (
  params: any,
  parentQuery: any,
  options: Options,
  name: string
) => Operation<TItem>;

export type BasicValueQuery<TValue> = {
  $eq?: TValue;
  $ne?: TValue;
  $lt?: TValue;
  $gt?: TValue;
  $lte?: TValue;
  $gte?: TValue;
  $in?: TValue[];
  $nin?: TValue[];
  $all?: TValue[];
  $mod?: [number, number];
  $exists?: boolean;
  $regex?: string | RegExp;
  $size?: number;
  $where?: ((this: TValue, obj: TValue) => boolean) | string;
  $options?: "i" | "g" | "m" | "u";
  $type?: Function;
  $not?: NestedQuery<TValue>;
  $or?: NestedQuery<TValue>[];
  $nor?: NestedQuery<TValue>[];
  $and?: NestedQuery<TValue>[];
};

export type ArrayValueQuery<TValue> = {
  $elemMatch?: Query<TValue>;
} & BasicValueQuery<TValue>;
type Unpacked<T> = T extends (infer U)[] ? U : T;

export type ValueQuery<TValue> = TValue extends Array<any>
  ? ArrayValueQuery<Unpacked<TValue>>
  : BasicValueQuery<TValue>;

type NotObject = string | number | Date | boolean | Array<any>;
export type ShapeQuery<TItemSchema> = TItemSchema extends NotObject
  ? {}
  : { [k in keyof TItemSchema]?: TItemSchema[k] | ValueQuery<TItemSchema[k]> };

export type NestedQuery<TItemSchema> = ValueQuery<TItemSchema> &
  ShapeQuery<TItemSchema>;
export type Query<TItemSchema> =
  | TItemSchema
  | RegExp
  | NestedQuery<TItemSchema>;

export type QueryOperators<TValue = any> = keyof ValueQuery<TValue>;

/**
 * Walks through each value given the context - used for nested operations. E.g:
 * { "person.address": { $eq: "blarg" }}
 */

const walkKeyPathValues = (
  item: any,
  keyPath: Key[],
  next: Tester,
  depth: number,
  key: Key,
  owner: any
) => {
  const currentKey = keyPath[depth];

  // if array, then try matching. Might fall through for cases like:
  // { $eq: [1, 2, 3] }, [ 1, 2, 3 ].
  if (isArray(item) && isNaN(Number(currentKey))) {
    for (let i = 0, { length } = item; i < length; i++) {
      // if FALSE is returned, then terminate walker. For operations, this simply
      // means that the search critera was met.
      if (!walkKeyPathValues(item[i], keyPath, next, depth, i, item)) {
        return false;
      }
    }
  }

  if (depth === keyPath.length || item == null) {
    return next(item, key, owner, depth === 0);
  }

  return walkKeyPathValues(
    item[currentKey],
    keyPath,
    next,
    depth + 1,
    currentKey,
    item
  );
};

export abstract class BaseOperation<TParams, TItem = any>
  implements Operation<TItem> {
  keep: boolean;
  done: boolean;
  abstract propop: boolean;
  constructor(
    readonly params: TParams,
    readonly owneryQuery: any,
    readonly options: Options,
    readonly name?: string
  ) {
    this.init();
  }
  protected init() {}
  reset() {
    this.done = false;
    this.keep = false;
  }
  abstract next(item: any, key: Key, parent: any, root: boolean);
}

abstract class GroupOperation extends BaseOperation<any> {
  keep: boolean;
  done: boolean;

  constructor(
    params: any,
    owneryQuery: any,
    options: Options,
    public readonly children: Operation<any>[]
  ) {
    super(params, owneryQuery, options);
  }

  /**
   */

  reset() {
    this.keep = false;
    this.done = false;
    for (let i = 0, { length } = this.children; i < length; i++) {
      this.children[i].reset();
    }
  }

  abstract next(item: any, key: Key, owner: any, root: boolean);

  /**
   */

  protected childrenNext(item: any, key: Key, owner: any, root: boolean) {
    let done = true;
    let keep = true;
    for (let i = 0, { length } = this.children; i < length; i++) {
      const childOperation = this.children[i];
      if (!childOperation.done) {
        childOperation.next(item, key, owner, root);
      }
      if (!childOperation.keep) {
        keep = false;
      }
      if (childOperation.done) {
        if (!childOperation.keep) {
          break;
        }
      } else {
        done = false;
      }
    }
    this.done = done;
    this.keep = keep;
  }
}

export abstract class NamedGroupOperation extends GroupOperation
  implements NamedOperation {
  abstract propop: boolean;
  constructor(
    params: any,
    owneryQuery: any,
    options: Options,
    children: Operation<any>[],
    readonly name: string
  ) {
    super(params, owneryQuery, options, children);
  }
}

export class QueryOperation<TItem> extends GroupOperation {
  readonly propop = true;
  /**
   */

  next(item: TItem, key: Key, parent: any, root: boolean) {
    this.childrenNext(item, key, parent, root);
  }
}

export class NestedOperation extends GroupOperation {
  readonly propop = true;
  constructor(
    readonly keyPath: Key[],
    params: any,
    owneryQuery: any,
    options: Options,
    children: Operation<any>[]
  ) {
    super(params, owneryQuery, options, children);
  }
  /**
   */

  next(item: any, key: Key, parent: any) {
    walkKeyPathValues(
      item,
      this.keyPath,
      this._nextNestedValue,
      0,
      key,
      parent
    );
  }

  /**
   */

  private _nextNestedValue = (
    value: any,
    key: Key,
    owner: any,
    root: boolean
  ) => {
    this.childrenNext(value, key, owner, root);
    return !this.done;
  };
}

export const createTester = (a, compare: Comparator) => {
  if (a instanceof Function) {
    return a;
  }
  if (a instanceof RegExp) {
    return b => {
      const result = typeof b === "string" && a.test(b);
      a.lastIndex = 0;
      return result;
    };
  }
  const comparableA = comparable(a);
  return b => compare(comparableA, comparable(b));
};

export class EqualsOperation<TParam> extends BaseOperation<TParam> {
  readonly propop = true;
  private _test: Tester;
  init() {
    this._test = createTester(this.params, this.options.compare);
  }
  next(item, key: Key, parent: any) {
    if (!Array.isArray(parent) || parent.hasOwnProperty(key)) {
      if (this._test(item, key, parent)) {
        this.done = true;
        this.keep = true;
      }
    }
  }
}

export const createEqualsOperation = (
  params: any,
  owneryQuery: any,
  options: Options
) => new EqualsOperation(params, owneryQuery, options);

export class NopeOperation<TParam> extends BaseOperation<TParam> {
  readonly propop = true;
  next() {
    this.done = true;
    this.keep = false;
  }
}

export const numericalOperationCreator = (
  createNumericalOperation: OperationCreator<any>
) => (params: any, owneryQuery: any, options: Options, name: string) => {
  if (params == null) {
    return new NopeOperation(params, owneryQuery, options, name);
  }

  return createNumericalOperation(params, owneryQuery, options, name);
};

export const numericalOperation = (createTester: (any) => Tester) =>
  numericalOperationCreator(
    (params: any, owneryQuery: Query<any>, options: Options, name: string) => {
      const typeofParams = typeof comparable(params);
      const test = createTester(params);
      return new EqualsOperation(
        b => {
          return typeof comparable(b) === typeofParams && test(b);
        },
        owneryQuery,
        options,
        name
      );
    }
  );

export type Options = {
  operations: {
    [identifier: string]: OperationCreator<any>;
  };
  compare: (a, b) => boolean;
};

const createNamedOperation = (
  name: string,
  params: any,
  parentQuery: any,
  options: Options
) => {
  const operationCreator = options.operations[name];
  if (!operationCreator) {
    throwUnsupportedOperation(name);
  }
  return operationCreator(params, parentQuery, options, name);
};

const throwUnsupportedOperation = (name: string) => {
  throw new Error(`Unsupported operation: ${name}`);
};

export const containsOperation = (query: any, options: Options) => {
  for (const key in query) {
    if (options.operations.hasOwnProperty(key) || key.charAt(0) === "$")
      return true;
  }
  return false;
};
const createNestedOperation = (
  keyPath: Key[],
  nestedQuery: any,
  parentKey: string,
  owneryQuery: any,
  options: Options
) => {
  if (containsOperation(nestedQuery, options)) {
    const [selfOperations, nestedOperations] = createQueryOperations(
      nestedQuery,
      parentKey,
      options
    );
    if (nestedOperations.length) {
      throw new Error(
        `Property queries must contain only operations, or exact objects.`
      );
    }
    return new NestedOperation(
      keyPath,
      nestedQuery,
      owneryQuery,
      options,
      selfOperations
    );
  }
  return new NestedOperation(keyPath, nestedQuery, owneryQuery, options, [
    new EqualsOperation(nestedQuery, owneryQuery, options)
  ]);
};

export const createQueryOperation = <TItem, TSchema = TItem>(
  query: Query<TSchema>,
  owneryQuery: any = null,
  { compare, operations }: Partial<Options> = {}
): QueryOperation<TItem> => {
  const options = {
    compare: compare || equals,
    operations: Object.assign({}, operations || {})
  };

  const [selfOperations, nestedOperations] = createQueryOperations(
    query,
    null,
    options
  );

  const ops = [];

  if (selfOperations.length) {
    ops.push(
      new NestedOperation([], query, owneryQuery, options, selfOperations)
    );
  }

  ops.push(...nestedOperations);

  if (ops.length === 1) {
    return ops[0];
  }
  return new QueryOperation(query, owneryQuery, options, ops);
};

const createQueryOperations = (
  query: any,
  parentKey: string,
  options: Options
) => {
  const selfOperations = [];
  const nestedOperations = [];
  if (!isVanillaObject(query)) {
    selfOperations.push(new EqualsOperation(query, query, options));
    return [selfOperations, nestedOperations];
  }
  for (const key in query) {
    if (options.operations.hasOwnProperty(key)) {
      const op = createNamedOperation(key, query[key], query, options);

      if (op) {
        if (!op.propop && parentKey && !options.operations[parentKey]) {
          throw new Error(
            `Malformed query. ${key} cannot be matched against property.`
          );
        }
      }

      // probably just a flag for another operation (like $options)
      if (op != null) {
        selfOperations.push(op);
      }
    } else if (key.charAt(0) === "$") {
      throwUnsupportedOperation(key);
    } else {
      nestedOperations.push(
        createNestedOperation(key.split("."), query[key], key, query, options)
      );
    }
  }

  return [selfOperations, nestedOperations];
};

export const createOperationTester = <TItem>(operation: Operation<TItem>) => (
  item: TItem,
  key?: Key,
  owner?: any
) => {
  operation.reset();
  operation.next(item, key, owner);
  return operation.keep;
};

export const createQueryTester = <TItem, TSchema = TItem>(
  query: Query<TSchema>,
  options: Partial<Options> = {}
) => {
  return createOperationTester(
    createQueryOperation<TItem, TSchema>(query, null, options)
  );
};

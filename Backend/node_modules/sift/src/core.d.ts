import { Key, Comparator } from "./utils";
export interface Operation<TItem> {
    readonly keep: boolean;
    readonly done: boolean;
    propop: boolean;
    reset(): any;
    next(item: TItem, key?: Key, owner?: any, root?: boolean): any;
}
export declare type Tester = (item: any, key?: Key, owner?: any, root?: boolean) => boolean;
export interface NamedOperation {
    name: string;
}
export declare type OperationCreator<TItem> = (params: any, parentQuery: any, options: Options, name: string) => Operation<TItem>;
export declare type BasicValueQuery<TValue> = {
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
export declare type ArrayValueQuery<TValue> = {
    $elemMatch?: Query<TValue>;
} & BasicValueQuery<TValue>;
declare type Unpacked<T> = T extends (infer U)[] ? U : T;
export declare type ValueQuery<TValue> = TValue extends Array<any> ? ArrayValueQuery<Unpacked<TValue>> : BasicValueQuery<TValue>;
declare type NotObject = string | number | Date | boolean | Array<any>;
export declare type ShapeQuery<TItemSchema> = TItemSchema extends NotObject ? {} : {
    [k in keyof TItemSchema]?: TItemSchema[k] | ValueQuery<TItemSchema[k]>;
};
export declare type NestedQuery<TItemSchema> = ValueQuery<TItemSchema> & ShapeQuery<TItemSchema>;
export declare type Query<TItemSchema> = TItemSchema | RegExp | NestedQuery<TItemSchema>;
export declare type QueryOperators<TValue = any> = keyof ValueQuery<TValue>;
export declare abstract class BaseOperation<TParams, TItem = any> implements Operation<TItem> {
    readonly params: TParams;
    readonly owneryQuery: any;
    readonly options: Options;
    readonly name?: string;
    keep: boolean;
    done: boolean;
    abstract propop: boolean;
    constructor(params: TParams, owneryQuery: any, options: Options, name?: string);
    protected init(): void;
    reset(): void;
    abstract next(item: any, key: Key, parent: any, root: boolean): any;
}
declare abstract class GroupOperation extends BaseOperation<any> {
    readonly children: Operation<any>[];
    keep: boolean;
    done: boolean;
    constructor(params: any, owneryQuery: any, options: Options, children: Operation<any>[]);
    /**
     */
    reset(): void;
    abstract next(item: any, key: Key, owner: any, root: boolean): any;
    /**
     */
    protected childrenNext(item: any, key: Key, owner: any, root: boolean): void;
}
export declare abstract class NamedGroupOperation extends GroupOperation implements NamedOperation {
    readonly name: string;
    abstract propop: boolean;
    constructor(params: any, owneryQuery: any, options: Options, children: Operation<any>[], name: string);
}
export declare class QueryOperation<TItem> extends GroupOperation {
    readonly propop = true;
    /**
     */
    next(item: TItem, key: Key, parent: any, root: boolean): void;
}
export declare class NestedOperation extends GroupOperation {
    readonly keyPath: Key[];
    readonly propop = true;
    constructor(keyPath: Key[], params: any, owneryQuery: any, options: Options, children: Operation<any>[]);
    /**
     */
    next(item: any, key: Key, parent: any): void;
    /**
     */
    private _nextNestedValue;
}
export declare const createTester: (a: any, compare: Comparator) => any;
export declare class EqualsOperation<TParam> extends BaseOperation<TParam> {
    readonly propop = true;
    private _test;
    init(): void;
    next(item: any, key: Key, parent: any): void;
}
export declare const createEqualsOperation: (params: any, owneryQuery: any, options: Options) => EqualsOperation<any>;
export declare class NopeOperation<TParam> extends BaseOperation<TParam> {
    readonly propop = true;
    next(): void;
}
export declare const numericalOperationCreator: (createNumericalOperation: OperationCreator<any>) => (params: any, owneryQuery: any, options: Options, name: string) => Operation<any> | NopeOperation<any>;
export declare const numericalOperation: (createTester: (any: any) => Tester) => (params: any, owneryQuery: any, options: Options, name: string) => Operation<any> | NopeOperation<any>;
export declare type Options = {
    operations: {
        [identifier: string]: OperationCreator<any>;
    };
    compare: (a: any, b: any) => boolean;
};
export declare const containsOperation: (query: any, options: Options) => boolean;
export declare const createQueryOperation: <TItem, TSchema = TItem>(query: Query<TSchema>, owneryQuery?: any, { compare, operations }?: Partial<Options>) => QueryOperation<TItem>;
export declare const createOperationTester: <TItem>(operation: Operation<TItem>) => (item: TItem, key?: Key, owner?: any) => boolean;
export declare const createQueryTester: <TItem, TSchema = TItem>(query: Query<TSchema>, options?: Partial<Options>) => (item: TItem, key?: Key, owner?: any) => boolean;
export {};

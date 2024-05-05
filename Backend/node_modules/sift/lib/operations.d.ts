import { BaseOperation, EqualsOperation, Options, Operation, Query, NamedGroupOperation } from "./core";
import { Key } from "./utils";
declare class $Ne extends BaseOperation<any> {
    readonly propop = true;
    private _test;
    init(): void;
    reset(): void;
    next(item: any): void;
}
declare class $ElemMatch extends BaseOperation<Query<any>> {
    readonly propop = true;
    private _queryOperation;
    init(): void;
    reset(): void;
    next(item: any): void;
}
declare class $Not extends BaseOperation<Query<any>> {
    readonly propop = true;
    private _queryOperation;
    init(): void;
    reset(): void;
    next(item: any, key: Key, owner: any, root: boolean): void;
}
export declare class $Size extends BaseOperation<any> {
    readonly propop = true;
    init(): void;
    next(item: any): void;
}
declare class $Or extends BaseOperation<any> {
    readonly propop = false;
    private _ops;
    init(): void;
    reset(): void;
    next(item: any, key: Key, owner: any): void;
}
declare class $Nor extends $Or {
    readonly propop = false;
    next(item: any, key: Key, owner: any): void;
}
declare class $In extends BaseOperation<any> {
    readonly propop = true;
    private _testers;
    init(): void;
    next(item: any, key: Key, owner: any): void;
}
declare class $Nin extends BaseOperation<any> {
    readonly propop = true;
    private _in;
    constructor(params: any, ownerQuery: any, options: Options, name: string);
    next(item: any, key: Key, owner: any, root: boolean): void;
    reset(): void;
}
declare class $Exists extends BaseOperation<boolean> {
    readonly propop = true;
    next(item: any, key: Key, owner: any): void;
}
declare class $And extends NamedGroupOperation {
    readonly propop = false;
    constructor(params: Query<any>[], owneryQuery: Query<any>, options: Options, name: string);
    next(item: any, key: Key, owner: any, root: boolean): void;
}
declare class $All extends NamedGroupOperation {
    readonly propop = true;
    constructor(params: Query<any>[], owneryQuery: Query<any>, options: Options, name: string);
    next(item: any, key: Key, owner: any, root: boolean): void;
}
export declare const $eq: (params: any, owneryQuery: Query<any>, options: Options) => EqualsOperation<any>;
export declare const $ne: (params: any, owneryQuery: Query<any>, options: Options, name: string) => $Ne;
export declare const $or: (params: Query<any>[], owneryQuery: Query<any>, options: Options, name: string) => $Or;
export declare const $nor: (params: Query<any>[], owneryQuery: Query<any>, options: Options, name: string) => $Nor;
export declare const $elemMatch: (params: any, owneryQuery: Query<any>, options: Options, name: string) => $ElemMatch;
export declare const $nin: (params: any, owneryQuery: Query<any>, options: Options, name: string) => $Nin;
export declare const $in: (params: any, owneryQuery: Query<any>, options: Options, name: string) => $In;
export declare const $lt: (params: any, owneryQuery: any, options: Options, name: string) => Operation<any>;
export declare const $lte: (params: any, owneryQuery: any, options: Options, name: string) => Operation<any>;
export declare const $gt: (params: any, owneryQuery: any, options: Options, name: string) => Operation<any>;
export declare const $gte: (params: any, owneryQuery: any, options: Options, name: string) => Operation<any>;
export declare const $mod: ([mod, equalsValue]: number[], owneryQuery: Query<any>, options: Options) => EqualsOperation<(b: any) => boolean>;
export declare const $exists: (params: boolean, owneryQuery: Query<any>, options: Options, name: string) => $Exists;
export declare const $regex: (pattern: string, owneryQuery: Query<any>, options: Options) => EqualsOperation<RegExp>;
export declare const $not: (params: any, owneryQuery: Query<any>, options: Options, name: string) => $Not;
export declare const $type: (clazz: Function | string, owneryQuery: Query<any>, options: Options) => EqualsOperation<(b: any) => any>;
export declare const $and: (params: Query<any>[], ownerQuery: Query<any>, options: Options, name: string) => $And;
export declare const $all: (params: Query<any>[], ownerQuery: Query<any>, options: Options, name: string) => $All;
export declare const $size: (params: number, ownerQuery: Query<any>, options: Options) => $Size;
export declare const $options: () => any;
export declare const $where: (params: string | Function, ownerQuery: Query<any>, options: Options) => EqualsOperation<(b: any) => any>;
export {};

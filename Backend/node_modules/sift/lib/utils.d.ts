export declare type Key = string | number;
export declare type Comparator = (a: any, b: any) => boolean;
export declare const typeChecker: <TType>(type: any) => (value: any) => value is TType;
export declare const comparable: (value: any) => any;
export declare const isArray: (value: any) => value is any[];
export declare const isObject: (value: any) => value is Object;
export declare const isFunction: (value: any) => value is Function;
export declare const isVanillaObject: (value: any) => boolean;
export declare const equals: (a: any, b: any) => boolean;

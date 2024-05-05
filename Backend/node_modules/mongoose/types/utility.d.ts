declare module 'mongoose' {
  type IfAny<IFTYPE, THENTYPE, ELSETYPE = IFTYPE> = 0 extends (1 & IFTYPE) ? THENTYPE : ELSETYPE;
  type IfUnknown<IFTYPE, THENTYPE> = unknown extends IFTYPE ? THENTYPE : IFTYPE;

  /**
    * @summary Removes keys from a type
    * @description It helps to exclude keys from a type
    * @param {T} T A generic type to be checked.
    * @param {K} K Keys from T that are to be excluded from the generic type
    * @returns T with the keys in K excluded
    */
  type ExcludeKeys<T, K extends keyof T> = {
    [P in keyof T as P extends K ? never : P]: T[P];
  };

  type Unpacked<T> = T extends (infer U)[] ?
    U :
    T extends ReadonlyArray<infer U> ? U : T;

  type UnpackedIntersection<T, U> = T extends null ? null : T extends (infer A)[]
    ? (Omit<A, keyof U> & U)[]
    : keyof U extends never
      ? T
      : Omit<T, keyof U> & U;

  type MergeType<A, B> = Omit<A, keyof B> & B;

  /**
   * @summary Converts Unions to one record "object".
   * @description It makes intellisense dialog box easier to read as a single object instead of showing that in multiple object unions.
   * @param {T} T The type to be converted.
   */
  type FlatRecord<T> = { [K in keyof T]: T[K] };

  /**
    * @summary Checks if a type is "Record" or "any".
    * @description It Helps to check if user has provided schema type "EnforcedDocType"
    * @param {T} T A generic type to be checked.
    * @returns true if {@link T} is Record OR false if {@link T} is of any type.
    */
  type IsItRecordAndNotAny<T> = IfEquals<T, any, false, T extends Record<any, any> ? true : false>;

/**
 * @summary Checks if two types are identical.
 * @param {T} T The first type to be compared with {@link U}.
 * @param {U} U The seconde type to be compared with {@link T}.
 * @param {Y} Y A type to be returned if {@link T} &  {@link U} are identical.
 * @param {N} N A type to be returned if {@link T} &  {@link U} are not identical.
 */
type IfEquals<T, U, Y = true, N = false> =
    (<G>() => G extends T ? 1 : 0) extends
    (<G>() => G extends U ? 1 : 0) ? Y : N;

/**
 * @summary Extracts 'this' parameter from a function, if it exists. Otherwise, returns fallback.
 * @param {T} T Function type to extract 'this' parameter from.
 * @param {F} F Fallback type to return if 'this' parameter does not exist.
 */
type ThisParameter<T, F> = T extends { (this: infer This): void }
  ? This
  : F;

/**
 * @summary Decorates all functions in an object with 'this' parameter.
 * @param {T} T Object with functions as values to add 'D' parameter to as 'this'. {@link D}
 * @param {D} D The type to be added as 'this' parameter to all functions in {@link T}.
 */
type AddThisParameter<T, D> = {
  [K in keyof T]: T[K] extends (...args: infer A) => infer R
    ? ThisParameter<T[K], unknown> extends unknown
      ? (this: D, ...args: A) => R
      : T[K]
    : T[K];
};

}

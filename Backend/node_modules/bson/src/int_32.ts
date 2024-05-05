import { BSONValue } from './bson_value';
import type { EJSONOptions } from './extended_json';
import { type InspectFn, defaultInspect } from './parser/utils';

/** @public */
export interface Int32Extended {
  $numberInt: string;
}

/**
 * A class representation of a BSON Int32 type.
 * @public
 * @category BSONType
 */
export class Int32 extends BSONValue {
  get _bsontype(): 'Int32' {
    return 'Int32';
  }

  value!: number;
  /**
   * Create an Int32 type
   *
   * @param value - the number we want to represent as an int32.
   */
  constructor(value: number | string) {
    super();
    if ((value as unknown) instanceof Number) {
      value = value.valueOf();
    }

    this.value = +value | 0;
  }

  /**
   * Access the number value.
   *
   * @returns returns the wrapped int32 number.
   */
  valueOf(): number {
    return this.value;
  }

  toString(radix?: number): string {
    return this.value.toString(radix);
  }

  toJSON(): number {
    return this.value;
  }

  /** @internal */
  toExtendedJSON(options?: EJSONOptions): number | Int32Extended {
    if (options && (options.relaxed || options.legacy)) return this.value;
    return { $numberInt: this.value.toString() };
  }

  /** @internal */
  static fromExtendedJSON(doc: Int32Extended, options?: EJSONOptions): number | Int32 {
    return options && options.relaxed ? parseInt(doc.$numberInt, 10) : new Int32(doc.$numberInt);
  }

  inspect(depth?: number, options?: unknown, inspect?: InspectFn): string {
    inspect ??= defaultInspect;
    return `new Int32(${inspect(this.value, options)})`;
  }
}

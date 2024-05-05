declare module 'mongoose' {

  /** The Mongoose Date [SchemaType](/docs/schematypes.html). */
  type Date = Schema.Types.Date;

  /**
   * The Mongoose Decimal128 [SchemaType](/docs/schematypes.html). Used for
   * declaring paths in your schema that should be
   * [128-bit decimal floating points](http://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-34-decimal.html).
   * Do not use this to create a new Decimal128 instance, use `mongoose.Types.Decimal128`
   * instead.
   */
  type Decimal128 = Schema.Types.Decimal128;

  /**
   * The Mongoose Mixed [SchemaType](/docs/schematypes.html). Used for
   * declaring paths in your schema that Mongoose's change tracking, casting,
   * and validation should ignore.
   */
  type Mixed = Schema.Types.Mixed;

  /**
   * The Mongoose Number [SchemaType](/docs/schematypes.html). Used for
   * declaring paths in your schema that Mongoose should cast to numbers.
   */
  type Number = Schema.Types.Number;

  /**
   * The Mongoose ObjectId [SchemaType](/docs/schematypes.html). Used for
   * declaring paths in your schema that should be
   * [MongoDB ObjectIds](https://www.mongodb.com/docs/manual/reference/method/ObjectId/).
   * Do not use this to create a new ObjectId instance, use `mongoose.Types.ObjectId`
   * instead.
   */
  type ObjectId = Schema.Types.ObjectId;

  /** The various Mongoose SchemaTypes. */
  const SchemaTypes: typeof Schema.Types;

  type DefaultType<T> = T extends Schema.Types.Mixed ? any : Partial<ExtractMongooseArray<T>>;

  class SchemaTypeOptions<T, EnforcedDocType = any> {
    type?:
    T extends string ? StringSchemaDefinition :
      T extends number ? NumberSchemaDefinition :
        T extends boolean ? BooleanSchemaDefinition :
          T extends NativeDate ? DateSchemaDefinition :
            T extends Map<any, any> ? SchemaDefinition<typeof Map> :
              T extends Buffer ? SchemaDefinition<typeof Buffer> :
                T extends Types.ObjectId ? ObjectIdSchemaDefinition :
                  T extends Types.ObjectId[] ? AnyArray<ObjectIdSchemaDefinition> | AnyArray<SchemaTypeOptions<ObjectId, EnforcedDocType>> :
                    T extends object[] ? (AnyArray<Schema<any, any, any>> | AnyArray<SchemaDefinition<Unpacked<T>>> | AnyArray<SchemaTypeOptions<Unpacked<T>, EnforcedDocType>>) :
                      T extends string[] ? AnyArray<StringSchemaDefinition> | AnyArray<SchemaTypeOptions<string, EnforcedDocType>> :
                        T extends number[] ? AnyArray<NumberSchemaDefinition> | AnyArray<SchemaTypeOptions<number, EnforcedDocType>> :
                          T extends boolean[] ? AnyArray<BooleanSchemaDefinition> | AnyArray<SchemaTypeOptions<boolean, EnforcedDocType>> :
                            T extends Function[] ? AnyArray<Function | string> | AnyArray<SchemaTypeOptions<Unpacked<T>, EnforcedDocType>> :
                              T | typeof SchemaType | Schema<any, any, any> | SchemaDefinition<T> | Function | AnyArray<Function>;

    /** Defines a virtual with the given name that gets/sets this path. */
    alias?: string | string[];

    /** Function or object describing how to validate this schematype. See [validation docs](https://mongoosejs.com/docs/validation.html). */
    validate?: SchemaValidator<T> | AnyArray<SchemaValidator<T>>;

    /** Allows overriding casting logic for this individual path. If a string, the given string overwrites Mongoose's default cast error message. */
    cast?: string |
    boolean |
    ((value: any) => T) |
    [(value: any) => T, string] |
    [((value: any) => T) | null, (value: any, path: string, model: Model<any>, kind: string) => string];

    /**
     * If true, attach a required validator to this path, which ensures this path
     * path cannot be set to a nullish value. If a function, Mongoose calls the
     * function and only checks for nullish values if the function returns a truthy value.
     */
    required?: boolean | ((this: EnforcedDocType) => boolean) | [boolean, string] | [(this: EnforcedDocType) => boolean, string];

    /**
     * The default value for this path. If a function, Mongoose executes the function
     * and uses the return value as the default.
     */
    default?: DefaultType<T> | ((this: EnforcedDocType, doc: any) => DefaultType<T>) | null;

    /**
     * The model that `populate()` should use if populating this path.
     */
    ref?: string | Model<any> | ((this: any, doc: any) => string | Model<any>);

    /**
     * The path in the document that `populate()` should use to find the model
     * to use.
     */

    refPath?: string | ((this: any, doc: any) => string);

    /**
     * Whether to include or exclude this path by default when loading documents
     * using `find()`, `findOne()`, etc.
     */
    select?: boolean | number;

    /**
     * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose will
     * build an index on this path when the model is compiled.
     */
    index?: boolean | IndexDirection | IndexOptions;

    /**
     * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose
     * will build a unique index on this path when the
     * model is compiled. [The `unique` option is **not** a validator](/docs/validation.html#the-unique-option-is-not-a-validator).
     */
    unique?: boolean | number;

    /**
     * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose will
     * disallow changes to this path once the document is saved to the database for the first time. Read more
     * about [immutability in Mongoose here](http://thecodebarbarian.com/whats-new-in-mongoose-5-6-immutable-properties.html).
     */
    immutable?: boolean | ((this: any, doc: any) => boolean);

    /**
     * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose will
     * build a sparse index on this path.
     */
    sparse?: boolean | number;

    /**
     * If [truthy](https://masteringjs.io/tutorials/fundamentals/truthy), Mongoose
     * will build a text index on this path.
     */
    text?: boolean | number | any;

    /**
     * Define a transform function for this individual schema type.
     * Only called when calling `toJSON()` or `toObject()`.
     */
    transform?: (this: any, val: T) => any;

    /** defines a custom getter for this property using [`Object.defineProperty()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty). */
    get?: (value: any, doc?: this) => T | undefined;

    /** defines a custom setter for this property using [`Object.defineProperty()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty). */
    set?: (value: any, priorVal?: T, doc?: this) => any;

    /** array of allowed values for this path. Allowed for strings, numbers, and arrays of strings */
    enum?: Array<string | number | null> | ReadonlyArray<string | number | null> | { values: Array<string | number | null> | ReadonlyArray<string | number | null>, message?: string } | { [path: string]: string | number | null };

    /** The default [subtype](http://bsonspec.org/spec.html) associated with this buffer when it is stored in MongoDB. Only allowed for buffer paths */
    subtype?: number;

    /** The minimum value allowed for this path. Only allowed for numbers and dates. */
    min?: number | NativeDate | [number, string] | [NativeDate, string] | readonly [number, string] | readonly [NativeDate, string];

    /** The maximum value allowed for this path. Only allowed for numbers and dates. */
    max?: number | NativeDate | [number, string] | [NativeDate, string] | readonly [number, string] | readonly [NativeDate, string];

    /** Defines a TTL index on this path. Only allowed for dates. */
    expires?: string | number;

    /** If `true`, Mongoose will skip gathering indexes on subpaths. Only allowed for subdocuments and subdocument arrays. */
    excludeIndexes?: boolean;

    /** If set, overrides the child schema's `_id` option. Only allowed for subdocuments and subdocument arrays. */
    _id?: boolean;

    /** If set, specifies the type of this map's values. Mongoose will cast this map's values to the given type. */
    of?: Function | SchemaDefinitionProperty<any>;

    /** If true, uses Mongoose's default `_id` settings. Only allowed for ObjectIds */
    auto?: boolean;

    /** Attaches a validator that succeeds if the data string matches the given regular expression, and fails otherwise. */
    match?: RegExp | [RegExp, string] | readonly [RegExp, string];

    /** If truthy, Mongoose will add a custom setter that lowercases this string using JavaScript's built-in `String#toLowerCase()`. */
    lowercase?: boolean;

    /** If truthy, Mongoose will add a custom setter that removes leading and trailing whitespace using JavaScript's built-in `String#trim()`. */
    trim?: boolean;

    /** If truthy, Mongoose will add a custom setter that uppercases this string using JavaScript's built-in `String#toUpperCase()`. */
    uppercase?: boolean;

    /** If set, Mongoose will add a custom validator that ensures the given string's `length` is at least the given number. */
    minlength?: number | [number, string] | readonly [number, string];

    /** If set, Mongoose will add a custom validator that ensures the given string's `length` is at most the given number. */
    maxlength?: number | [number, string] | readonly [number, string];

    [other: string]: any;
  }

  interface Validator<DocType = any> {
    message?: string | ((props: ValidatorProps) => string);
    type?: string;
    validator?: ValidatorFunction<DocType>;
    reason?: Error;
  }

  type ValidatorFunction<DocType = any> = (this: DocType, value: any, validatorProperties?: Validator) => any;

  class SchemaType<T = any, DocType = any> {
    /** SchemaType constructor */
    constructor(path: string, options?: AnyObject, instance?: string);

    /** Get/set the function used to cast arbitrary values to this type. */
    static cast(caster?: Function | boolean): Function;

    static checkRequired(checkRequired?: (v: any) => boolean): (v: any) => boolean;

    /** Sets a default option for this schema type. */
    static set(option: string, value: any): void;

    /** Attaches a getter for all instances of this schema type. */
    static get(getter: (value: any) => any): void;

    /** The class that Mongoose uses internally to instantiate this SchemaType's `options` property. */
    OptionsConstructor: SchemaTypeOptions<T>;

    /** Cast `val` to this schema type. Each class that inherits from schema type should implement this function. */
    cast(val: any, doc: Document<any>, init: boolean, prev?: any, options?: any): any;

    /** Sets a default value for this SchemaType. */
    default(val: any): any;

    /** Adds a getter to this schematype. */
    get(fn: Function): this;

    /**
     * Defines this path as immutable. Mongoose prevents you from changing
     * immutable paths unless the parent document has [`isNew: true`](/docs/api/document.html#document_Document-isNew).
     */
    immutable(bool: boolean): this;

    /** Declares the index options for this schematype. */
    index(options: any): this;

    /** String representation of what type this is, like 'ObjectID' or 'Number' */
    instance: string;

    /** True if this SchemaType has a required validator. False otherwise. */
    isRequired?: boolean;

    /** The options this SchemaType was instantiated with */
    options: AnyObject;

    /** The path to this SchemaType in a Schema. */
    path: string;

    /**
     * Set the model that this path refers to. This is the option that [populate](https://mongoosejs.com/docs/populate.html)
     * looks at to determine the foreign collection it should query.
     */
    ref(ref: string | boolean | Model<any>): this;

    /**
     * Adds a required validator to this SchemaType. The validator gets added
     * to the front of this SchemaType's validators array using unshift().
     */
    required(required: boolean, message?: string): this;

    /** The schema this SchemaType instance is part of */
    schema: Schema<any>;

    /** Sets default select() behavior for this path. */
    select(val: boolean): this;

    /** Adds a setter to this schematype. */
    set(fn: Function): this;

    /** Declares a sparse index. */
    sparse(bool: boolean): this;

    /** Declares a full text index. */
    text(bool: boolean): this;

    /** Defines a custom function for transforming this path when converting a document to JSON. */
    transform(fn: (value: any) => any): this;

    /** Declares an unique index. */
    unique(bool: boolean): this;

    /** The validators that Mongoose should run to validate properties at this SchemaType's path. */
    validators: Validator[];

    /** Adds validator(s) for this document path. */
    validate(obj: RegExp | ValidatorFunction<DocType> | Validator<DocType>, errorMsg?: string, type?: string): this;

    /** Adds multiple validators for this document path. */
    validateAll(validators: Array<RegExp | ValidatorFunction<DocType> | Validator<DocType>>): this;

    /** Default options for this SchemaType */
    defaultOptions?: Record<string, any>;
  }

  namespace Schema {
    namespace Types {
      class Array extends SchemaType implements AcceptsDiscriminator {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Array';

        static options: { castNonArrays: boolean; };

        discriminator<T, U>(name: string | number, schema: Schema<T, U>, value?: string): U;
        discriminator<D>(name: string | number, schema: Schema, value?: string): Model<D>;

        /** The schematype embedded in this array */
        caster?: SchemaType;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;

        /**
         * Adds an enum validator if this is an array of strings or numbers. Equivalent to
         * `SchemaString.prototype.enum()` or `SchemaNumber.prototype.enum()`
         */
        enum(vals: string[] | number[]): this;
      }

      class BigInt extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'BigInt';

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Boolean extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Boolean';

        /** Configure which values get casted to `true`. */
        static convertToTrue: Set<any>;

        /** Configure which values get casted to `false`. */
        static convertToFalse: Set<any>;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Buffer extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Buffer';

        /**
         * Sets the default [subtype](https://studio3t.com/whats-new/best-practices-uuid-mongodb/)
         * for this buffer. You can find a [list of allowed subtypes here](http://api.mongodb.com/python/current/api/bson/binary.html).
         */
        subtype(subtype: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 128): this;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Date extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Date';

        /** Declares a TTL index (rounded to the nearest second) for _Date_ types only. */
        expires(when: number | string): this;

        /** Sets a maximum date validator. */
        max(value: NativeDate, message: string): this;

        /** Sets a minimum date validator. */
        min(value: NativeDate, message: string): this;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Decimal128 extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Decimal128';

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class DocumentArray extends SchemaType implements AcceptsDiscriminator {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'DocumentArray';

        static options: { castNonArrays: boolean; };

        discriminator<D>(name: string | number, schema: Schema, value?: string): Model<D>;
        discriminator<T, U>(name: string | number, schema: Schema<T, U>, value?: string): U;

        /** The schema used for documents in this array */
        schema: Schema;

        /** The constructor used for subdocuments in this array */
        caster?: typeof Types.Subdocument;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Map extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Map';

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Mixed extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Mixed';

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Number extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'Number';

        /** Sets a enum validator */
        enum(vals: number[]): this;

        /** Sets a maximum number validator. */
        max(value: number, message: string): this;

        /** Sets a minimum number validator. */
        min(value: number, message: string): this;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class ObjectId extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'ObjectId';

        /** Adds an auto-generated ObjectId default if turnOn is true. */
        auto(turnOn: boolean): this;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class Subdocument extends SchemaType implements AcceptsDiscriminator {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: string;

        /** The document's schema */
        schema: Schema;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;

        discriminator<T, U>(name: string | number, schema: Schema<T, U>, value?: string): U;
        discriminator<D>(name: string | number, schema: Schema, value?: string): Model<D>;
      }

      class String extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'String';

        /** Adds an enum validator */
        enum(vals: string[] | any): this;

        /** Adds a lowercase [setter](http://mongoosejs.com/docs/api/schematype.html#schematype_SchemaType-set). */
        lowercase(shouldApply?: boolean): this;

        /** Sets a regexp validator. */
        match(value: RegExp, message: string): this;

        /** Sets a maximum length validator. */
        maxlength(value: number, message: string): this;

        /** Sets a minimum length validator. */
        minlength(value: number, message: string): this;

        /** Adds a trim [setter](http://mongoosejs.com/docs/api/schematype.html#schematype_SchemaType-set). */
        trim(shouldTrim?: boolean): this;

        /** Adds an uppercase [setter](http://mongoosejs.com/docs/api/schematype.html#schematype_SchemaType-set). */
        uppercase(shouldApply?: boolean): this;

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }

      class UUID extends SchemaType {
        /** This schema type's name, to defend against minifiers that mangle function names. */
        static schemaName: 'UUID';

        /** Default options for this SchemaType */
        defaultOptions: Record<string, any>;
      }
    }
  }
}

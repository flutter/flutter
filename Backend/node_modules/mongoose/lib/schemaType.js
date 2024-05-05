'use strict';

/*!
 * Module dependencies.
 */

const MongooseError = require('./error/index');
const SchemaTypeOptions = require('./options/schemaTypeOptions');
const $exists = require('./schema/operators/exists');
const $type = require('./schema/operators/type');
const clone = require('./helpers/clone');
const handleImmutable = require('./helpers/schematype/handleImmutable');
const isAsyncFunction = require('./helpers/isAsyncFunction');
const isSimpleValidator = require('./helpers/isSimpleValidator');
const immediate = require('./helpers/immediate');
const schemaTypeSymbol = require('./helpers/symbols').schemaTypeSymbol;
const utils = require('./utils');
const validatorErrorSymbol = require('./helpers/symbols').validatorErrorSymbol;
const documentIsModified = require('./helpers/symbols').documentIsModified;

const populateModelSymbol = require('./helpers/symbols').populateModelSymbol;

const CastError = MongooseError.CastError;
const ValidatorError = MongooseError.ValidatorError;

const setOptionsForDefaults = { _skipMarkModified: true };

/**
 * SchemaType constructor. Do **not** instantiate `SchemaType` directly.
 * Mongoose converts your schema paths into SchemaTypes automatically.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String });
 *     schema.path('name') instanceof SchemaType; // true
 *
 * @param {String} path
 * @param {SchemaTypeOptions} [options] See [SchemaTypeOptions docs](https://mongoosejs.com/docs/api/schematypeoptions.html)
 * @param {String} [instance]
 * @api public
 */

function SchemaType(path, options, instance) {
  this[schemaTypeSymbol] = true;
  this.path = path;
  this.instance = instance;
  this.validators = [];
  this.getters = this.constructor.hasOwnProperty('getters') ?
    this.constructor.getters.slice() :
    [];
  this.setters = this.constructor.hasOwnProperty('setters') ?
    this.constructor.setters.slice() :
    [];

  this.splitPath();

  options = options || {};
  const defaultOptions = this.constructor.defaultOptions || {};
  const defaultOptionsKeys = Object.keys(defaultOptions);

  for (const option of defaultOptionsKeys) {
    if (option === 'validate') {
      this.validate(defaultOptions.validate);
    } else if (defaultOptions.hasOwnProperty(option) && !Object.prototype.hasOwnProperty.call(options, option)) {
      options[option] = defaultOptions[option];
    }
  }

  if (options.select == null) {
    delete options.select;
  }

  const Options = this.OptionsConstructor || SchemaTypeOptions;
  this.options = new Options(options);
  this._index = null;


  if (utils.hasUserDefinedProperty(this.options, 'immutable')) {
    this.$immutable = this.options.immutable;

    handleImmutable(this);
  }

  const keys = Object.keys(this.options);
  for (const prop of keys) {
    if (prop === 'cast') {
      if (Array.isArray(this.options[prop])) {
        this.castFunction.apply(this, this.options[prop]);
      } else {
        this.castFunction(this.options[prop]);
      }
      continue;
    }
    if (utils.hasUserDefinedProperty(this.options, prop) && typeof this[prop] === 'function') {
      // { unique: true, index: true }
      if (prop === 'index' && this._index) {
        if (options.index === false) {
          const index = this._index;
          if (typeof index === 'object' && index != null) {
            if (index.unique) {
              throw new Error('Path "' + this.path + '" may not have `index` ' +
                'set to false and `unique` set to true');
            }
            if (index.sparse) {
              throw new Error('Path "' + this.path + '" may not have `index` ' +
                'set to false and `sparse` set to true');
            }
          }

          this._index = false;
        }
        continue;
      }

      const val = options[prop];
      // Special case so we don't screw up array defaults, see gh-5780
      if (prop === 'default') {
        this.default(val);
        continue;
      }

      const opts = Array.isArray(val) ? val : [val];

      this[prop].apply(this, opts);
    }
  }

  Object.defineProperty(this, '$$context', {
    enumerable: false,
    configurable: false,
    writable: true,
    value: null
  });
}

/**
 * The class that Mongoose uses internally to instantiate this SchemaType's `options` property.
 * @memberOf SchemaType
 * @instance
 * @api private
 */

SchemaType.prototype.OptionsConstructor = SchemaTypeOptions;

/**
 * The path to this SchemaType in a Schema.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: String });
 *     schema.path('name').path; // 'name'
 *
 * @property path
 * @api public
 * @memberOf SchemaType
 */

SchemaType.prototype.path;

/**
 * The validators that Mongoose should run to validate properties at this SchemaType's path.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: { type: String, required: true } });
 *     schema.path('name').validators.length; // 1, the `required` validator
 *
 * @property validators
 * @api public
 * @memberOf SchemaType
 */

SchemaType.prototype.validators;

/**
 * True if this SchemaType has a required validator. False otherwise.
 *
 * #### Example:
 *
 *     const schema = new Schema({ name: { type: String, required: true } });
 *     schema.path('name').isRequired; // true
 *
 *     schema.path('name').required(false);
 *     schema.path('name').isRequired; // false
 *
 * @property isRequired
 * @api public
 * @memberOf SchemaType
 */

SchemaType.prototype.isRequired;

/**
 * Split the current dottet path into segments
 *
 * @return {String[]|undefined}
 * @api private
 */

SchemaType.prototype.splitPath = function() {
  if (this._presplitPath != null) {
    return this._presplitPath;
  }
  if (this.path == null) {
    return undefined;
  }

  this._presplitPath = this.path.indexOf('.') === -1 ? [this.path] : this.path.split('.');
  return this._presplitPath;
};

/**
 * Get/set the function used to cast arbitrary values to this type.
 *
 * #### Example:
 *
 *     // Disallow `null` for numbers, and don't try to cast any values to
 *     // numbers, so even strings like '123' will cause a CastError.
 *     mongoose.Number.cast(function(v) {
 *       assert.ok(v === undefined || typeof v === 'number');
 *       return v;
 *     });
 *
 * @param {Function|false} caster Function that casts arbitrary values to this type, or throws an error if casting failed
 * @return {Function}
 * @static
 * @memberOf SchemaType
 * @function cast
 * @api public
 */

SchemaType.cast = function cast(caster) {
  if (arguments.length === 0) {
    return this._cast;
  }
  if (caster === false) {
    caster = v => v;
  }
  this._cast = caster;

  return this._cast;
};

/**
 * Get/set the function used to cast arbitrary values to this particular schematype instance.
 * Overrides `SchemaType.cast()`.
 *
 * #### Example:
 *
 *     // Disallow `null` for numbers, and don't try to cast any values to
 *     // numbers, so even strings like '123' will cause a CastError.
 *     const number = new mongoose.Number('mypath', {});
 *     number.cast(function(v) {
 *       assert.ok(v === undefined || typeof v === 'number');
 *       return v;
 *     });
 *
 * @param {Function|false} caster Function that casts arbitrary values to this type, or throws an error if casting failed
 * @return {Function}
 * @memberOf SchemaType
 * @api public
 */

SchemaType.prototype.castFunction = function castFunction(caster, message) {
  if (arguments.length === 0) {
    return this._castFunction;
  }

  if (caster === false) {
    caster = this.constructor._defaultCaster || (v => v);
  }
  if (typeof caster === 'string') {
    this._castErrorMessage = caster;
    return this._castFunction;
  }
  if (caster != null) {
    this._castFunction = caster;
  }
  if (message != null) {
    this._castErrorMessage = message;
  }

  return this._castFunction;
};

/**
 * The function that Mongoose calls to cast arbitrary values to this SchemaType.
 *
 * @param {Object} value value to cast
 * @param {Document} doc document that triggers the casting
 * @param {Boolean} init
 * @api public
 */

SchemaType.prototype.cast = function cast() {
  throw new Error('Base SchemaType class does not implement a `cast()` function');
};

/**
 * Sets a default option for this schema type.
 *
 * #### Example:
 *
 *     // Make all strings be trimmed by default
 *     mongoose.SchemaTypes.String.set('trim', true);
 *
 * @param {String} option The name of the option you'd like to set (e.g. trim, lowercase, etc...)
 * @param {Any} value The value of the option you'd like to set.
 * @return {void}
 * @static
 * @memberOf SchemaType
 * @function set
 * @api public
 */

SchemaType.set = function set(option, value) {
  if (!this.hasOwnProperty('defaultOptions')) {
    this.defaultOptions = Object.assign({}, this.defaultOptions);
  }
  this.defaultOptions[option] = value;
};

/**
 * Attaches a getter for all instances of this schema type.
 *
 * #### Example:
 *
 *     // Make all numbers round down
 *     mongoose.Number.get(function(v) { return Math.floor(v); });
 *
 * @param {Function} getter
 * @return {this}
 * @static
 * @memberOf SchemaType
 * @function get
 * @api public
 */

SchemaType.get = function(getter) {
  this.getters = this.hasOwnProperty('getters') ? this.getters : [];
  this.getters.push(getter);
};

/**
 * Sets a default value for this SchemaType.
 *
 * #### Example:
 *
 *     const schema = new Schema({ n: { type: Number, default: 10 })
 *     const M = db.model('M', schema)
 *     const m = new M;
 *     console.log(m.n) // 10
 *
 * Defaults can be either `functions` which return the value to use as the default or the literal value itself. Either way, the value will be cast based on its schema type before being set during document creation.
 *
 * #### Example:
 *
 *     // values are cast:
 *     const schema = new Schema({ aNumber: { type: Number, default: 4.815162342 }})
 *     const M = db.model('M', schema)
 *     const m = new M;
 *     console.log(m.aNumber) // 4.815162342
 *
 *     // default unique objects for Mixed types:
 *     const schema = new Schema({ mixed: Schema.Types.Mixed });
 *     schema.path('mixed').default(function () {
 *       return {};
 *     });
 *
 *     // if we don't use a function to return object literals for Mixed defaults,
 *     // each document will receive a reference to the same object literal creating
 *     // a "shared" object instance:
 *     const schema = new Schema({ mixed: Schema.Types.Mixed });
 *     schema.path('mixed').default({});
 *     const M = db.model('M', schema);
 *     const m1 = new M;
 *     m1.mixed.added = 1;
 *     console.log(m1.mixed); // { added: 1 }
 *     const m2 = new M;
 *     console.log(m2.mixed); // { added: 1 }
 *
 * @param {Function|any} val The default value to set
 * @return {Any|undefined} Returns the set default value.
 * @api public
 */

SchemaType.prototype.default = function(val) {
  if (arguments.length === 1) {
    if (val === void 0) {
      this.defaultValue = void 0;
      return void 0;
    }

    if (val != null && val.instanceOfSchema) {
      throw new MongooseError('Cannot set default value of path `' + this.path +
        '` to a mongoose Schema instance.');
    }

    this.defaultValue = val;
    return this.defaultValue;
  } else if (arguments.length > 1) {
    this.defaultValue = [...arguments];
  }
  return this.defaultValue;
};

/**
 * Declares the index options for this schematype.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: { type: String, index: true })
 *     const s = new Schema({ name: { type: String, index: -1 })
 *     const s = new Schema({ loc: { type: [Number], index: 'hashed' })
 *     const s = new Schema({ loc: { type: [Number], index: '2d', sparse: true })
 *     const s = new Schema({ loc: { type: [Number], index: { type: '2dsphere', sparse: true }})
 *     const s = new Schema({ date: { type: Date, index: { unique: true, expires: '1d' }})
 *     s.path('my.path').index(true);
 *     s.path('my.date').index({ expires: 60 });
 *     s.path('my.path').index({ unique: true, sparse: true });
 *
 * #### Note:
 *
 * _Indexes are created [in the background](https://www.mongodb.com/docs/manual/core/index-creation/#index-creation-background)
 * by default. If `background` is set to `false`, MongoDB will not execute any
 * read/write operations you send until the index build.
 * Specify `background: false` to override Mongoose's default._
 *
 * @param {Object|Boolean|String|Number} options
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.index = function(options) {
  this._index = options;
  utils.expires(this._index);
  return this;
};

/**
 * Declares an unique index.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: { type: String, unique: true } });
 *     s.path('name').index({ unique: true });
 *
 * _NOTE: violating the constraint returns an `E11000` error from MongoDB when saving, not a Mongoose validation error._
 *
 * @param {Boolean} bool
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.unique = function(bool) {
  if (this._index === false) {
    if (!bool) {
      return;
    }
    throw new Error('Path "' + this.path + '" may not have `index` set to ' +
      'false and `unique` set to true');
  }

  if (!this.options.hasOwnProperty('index') && bool === false) {
    return this;
  }

  if (this._index == null || this._index === true) {
    this._index = {};
  } else if (typeof this._index === 'string') {
    this._index = { type: this._index };
  }

  this._index.unique = bool;
  return this;
};

/**
 * Declares a full text index.
 *
 * ### Example:
 *
 *      const s = new Schema({ name : { type: String, text : true } })
 *      s.path('name').index({ text : true });
 *
 * @param {Boolean} bool
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.text = function(bool) {
  if (this._index === false) {
    if (!bool) {
      return this;
    }
    throw new Error('Path "' + this.path + '" may not have `index` set to ' +
      'false and `text` set to true');
  }

  if (!this.options.hasOwnProperty('index') && bool === false) {
    return this;
  }

  if (this._index === null || this._index === undefined ||
    typeof this._index === 'boolean') {
    this._index = {};
  } else if (typeof this._index === 'string') {
    this._index = { type: this._index };
  }

  this._index.text = bool;
  return this;
};

/**
 * Declares a sparse index.
 *
 * #### Example:
 *
 *     const s = new Schema({ name: { type: String, sparse: true } });
 *     s.path('name').index({ sparse: true });
 *
 * @param {Boolean} bool
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.sparse = function(bool) {
  if (this._index === false) {
    if (!bool) {
      return this;
    }
    throw new Error('Path "' + this.path + '" may not have `index` set to ' +
      'false and `sparse` set to true');
  }

  if (!this.options.hasOwnProperty('index') && bool === false) {
    return this;
  }

  if (this._index == null || typeof this._index === 'boolean') {
    this._index = {};
  } else if (typeof this._index === 'string') {
    this._index = { type: this._index };
  }

  this._index.sparse = bool;
  return this;
};

/**
 * Defines this path as immutable. Mongoose prevents you from changing
 * immutable paths unless the parent document has [`isNew: true`](https://mongoosejs.com/docs/api/document.html#Document.prototype.isNew()).
 *
 * #### Example:
 *
 *     const schema = new Schema({
 *       name: { type: String, immutable: true },
 *       age: Number
 *     });
 *     const Model = mongoose.model('Test', schema);
 *
 *     await Model.create({ name: 'test' });
 *     const doc = await Model.findOne();
 *
 *     doc.isNew; // false
 *     doc.name = 'new name';
 *     doc.name; // 'test', because `name` is immutable
 *
 * Mongoose also prevents changing immutable properties using `updateOne()`
 * and `updateMany()` based on [strict mode](https://mongoosejs.com/docs/guide.html#strict).
 *
 * #### Example:
 *
 *     // Mongoose will strip out the `name` update, because `name` is immutable
 *     Model.updateOne({}, { $set: { name: 'test2' }, $inc: { age: 1 } });
 *
 *     // If `strict` is set to 'throw', Mongoose will throw an error if you
 *     // update `name`
 *     const err = await Model.updateOne({}, { name: 'test2' }, { strict: 'throw' }).
 *       then(() => null, err => err);
 *     err.name; // StrictModeError
 *
 *     // If `strict` is `false`, Mongoose allows updating `name` even though
 *     // the property is immutable.
 *     Model.updateOne({}, { name: 'test2' }, { strict: false });
 *
 * @param {Boolean} bool
 * @return {SchemaType} this
 * @see isNew https://mongoosejs.com/docs/api/document.html#Document.prototype.isNew()
 * @api public
 */

SchemaType.prototype.immutable = function(bool) {
  this.$immutable = bool;
  handleImmutable(this);

  return this;
};

/**
 * Defines a custom function for transforming this path when converting a document to JSON.
 *
 * Mongoose calls this function with one parameter: the current `value` of the path. Mongoose
 * then uses the return value in the JSON output.
 *
 * #### Example:
 *
 *     const schema = new Schema({
 *       date: { type: Date, transform: v => v.getFullYear() }
 *     });
 *     const Model = mongoose.model('Test', schema);
 *
 *     await Model.create({ date: new Date('2016-06-01') });
 *     const doc = await Model.findOne();
 *
 *     doc.date instanceof Date; // true
 *
 *     doc.toJSON().date; // 2016 as a number
 *     JSON.stringify(doc); // '{"_id":...,"date":2016}'
 *
 * @param {Function} fn
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.transform = function(fn) {
  this.options.transform = fn;

  return this;
};

/**
 * Adds a setter to this schematype.
 *
 * #### Example:
 *
 *     function capitalize (val) {
 *       if (typeof val !== 'string') val = '';
 *       return val.charAt(0).toUpperCase() + val.substring(1);
 *     }
 *
 *     // defining within the schema
 *     const s = new Schema({ name: { type: String, set: capitalize }});
 *
 *     // or with the SchemaType
 *     const s = new Schema({ name: String })
 *     s.path('name').set(capitalize);
 *
 * Setters allow you to transform the data before it gets to the raw mongodb
 * document or query.
 *
 * Suppose you are implementing user registration for a website. Users provide
 * an email and password, which gets saved to mongodb. The email is a string
 * that you will want to normalize to lower case, in order to avoid one email
 * having more than one account -- e.g., otherwise, avenue@q.com can be registered for 2 accounts via avenue@q.com and AvEnUe@Q.CoM.
 *
 * You can set up email lower case normalization easily via a Mongoose setter.
 *
 *     function toLower(v) {
 *       return v.toLowerCase();
 *     }
 *
 *     const UserSchema = new Schema({
 *       email: { type: String, set: toLower }
 *     });
 *
 *     const User = db.model('User', UserSchema);
 *
 *     const user = new User({email: 'AVENUE@Q.COM'});
 *     console.log(user.email); // 'avenue@q.com'
 *
 *     // or
 *     const user = new User();
 *     user.email = 'Avenue@Q.com';
 *     console.log(user.email); // 'avenue@q.com'
 *     User.updateOne({ _id: _id }, { $set: { email: 'AVENUE@Q.COM' } }); // update to 'avenue@q.com'
 *
 * As you can see above, setters allow you to transform the data before it
 * stored in MongoDB, or before executing a query.
 *
 * _NOTE: we could have also just used the built-in `lowercase: true` SchemaType option instead of defining our own function._
 *
 *     new Schema({ email: { type: String, lowercase: true }})
 *
 * Setters are also passed a second argument, the schematype on which the setter was defined. This allows for tailored behavior based on options passed in the schema.
 *
 *     function inspector (val, priorValue, schematype) {
 *       if (schematype.options.required) {
 *         return schematype.path + ' is required';
 *       } else {
 *         return val;
 *       }
 *     }
 *
 *     const VirusSchema = new Schema({
 *       name: { type: String, required: true, set: inspector },
 *       taxonomy: { type: String, set: inspector }
 *     })
 *
 *     const Virus = db.model('Virus', VirusSchema);
 *     const v = new Virus({ name: 'Parvoviridae', taxonomy: 'Parvovirinae' });
 *
 *     console.log(v.name);     // name is required
 *     console.log(v.taxonomy); // Parvovirinae
 *
 * You can also use setters to modify other properties on the document. If
 * you're setting a property `name` on a document, the setter will run with
 * `this` as the document. Be careful, in mongoose 5 setters will also run
 * when querying by `name` with `this` as the query.
 *
 *     const nameSchema = new Schema({ name: String, keywords: [String] });
 *     nameSchema.path('name').set(function(v) {
 *       // Need to check if `this` is a document, because in mongoose 5
 *       // setters will also run on queries, in which case `this` will be a
 *       // mongoose query object.
 *       if (this instanceof Document && v != null) {
 *         this.keywords = v.split(' ');
 *       }
 *       return v;
 *     });
 *
 * @param {Function} fn
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.set = function(fn) {
  if (typeof fn !== 'function') {
    throw new TypeError('A setter must be a function.');
  }
  this.setters.push(fn);
  return this;
};

/**
 * Adds a getter to this schematype.
 *
 * #### Example:
 *
 *     function dob (val) {
 *       if (!val) return val;
 *       return (val.getMonth() + 1) + "/" + val.getDate() + "/" + val.getFullYear();
 *     }
 *
 *     // defining within the schema
 *     const s = new Schema({ born: { type: Date, get: dob })
 *
 *     // or by retreiving its SchemaType
 *     const s = new Schema({ born: Date })
 *     s.path('born').get(dob)
 *
 * Getters allow you to transform the representation of the data as it travels from the raw mongodb document to the value that you see.
 *
 * Suppose you are storing credit card numbers and you want to hide everything except the last 4 digits to the mongoose user. You can do so by defining a getter in the following way:
 *
 *     function obfuscate (cc) {
 *       return '****-****-****-' + cc.slice(cc.length-4, cc.length);
 *     }
 *
 *     const AccountSchema = new Schema({
 *       creditCardNumber: { type: String, get: obfuscate }
 *     });
 *
 *     const Account = db.model('Account', AccountSchema);
 *
 *     Account.findById(id, function (err, found) {
 *       console.log(found.creditCardNumber); // '****-****-****-1234'
 *     });
 *
 * Getters are also passed a second argument, the schematype on which the getter was defined. This allows for tailored behavior based on options passed in the schema.
 *
 *     function inspector (val, priorValue, schematype) {
 *       if (schematype.options.required) {
 *         return schematype.path + ' is required';
 *       } else {
 *         return schematype.path + ' is not';
 *       }
 *     }
 *
 *     const VirusSchema = new Schema({
 *       name: { type: String, required: true, get: inspector },
 *       taxonomy: { type: String, get: inspector }
 *     })
 *
 *     const Virus = db.model('Virus', VirusSchema);
 *
 *     Virus.findById(id, function (err, virus) {
 *       console.log(virus.name);     // name is required
 *       console.log(virus.taxonomy); // taxonomy is not
 *     })
 *
 * @param {Function} fn
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.get = function(fn) {
  if (typeof fn !== 'function') {
    throw new TypeError('A getter must be a function.');
  }
  this.getters.push(fn);
  return this;
};

/**
 * Adds multiple validators for this document path.
 * Calls `validate()` for every element in validators.
 *
 * @param {Array<RegExp|Function|Object>} validators
 * @returns this
 */

SchemaType.prototype.validateAll = function(validators) {
  for (let i = 0; i < validators.length; i++) {
    this.validate(validators[i]);
  }
  return this;
};

/**
 * Adds validator(s) for this document path.
 *
 * Validators always receive the value to validate as their first argument and
 * must return `Boolean`. Returning `false` or throwing an error means
 * validation failed.
 *
 * The error message argument is optional. If not passed, the [default generic error message template](https://mongoosejs.com/docs/api/error.html#Error.messages) will be used.
 *
 * #### Example:
 *
 *     // make sure every value is equal to "something"
 *     function validator (val) {
 *       return val === 'something';
 *     }
 *     new Schema({ name: { type: String, validate: validator }});
 *
 *     // with a custom error message
 *
 *     const custom = [validator, 'Uh oh, {PATH} does not equal "something".']
 *     new Schema({ name: { type: String, validate: custom }});
 *
 *     // adding many validators at a time
 *
 *     const many = [
 *         { validator: validator, message: 'uh oh' }
 *       , { validator: anotherValidator, message: 'failed' }
 *     ]
 *     new Schema({ name: { type: String, validate: many }});
 *
 *     // or utilizing SchemaType methods directly:
 *
 *     const schema = new Schema({ name: 'string' });
 *     schema.path('name').validate(validator, 'validation of `{PATH}` failed with value `{VALUE}`');
 *
 * #### Error message templates:
 *
 * Below is a list of supported template keywords:
 *
 * - PATH: The schema path where the error is being triggered.
 * - VALUE: The value assigned to the PATH that is triggering the error.
 * - KIND: The validation property that triggered the error i.e. required.
 * - REASON: The error object that caused this error if there was one.
 *
 * If Mongoose's built-in error message templating isn't enough, Mongoose
 * supports setting the `message` property to a function.
 *
 *     schema.path('name').validate({
 *       validator: function(v) { return v.length > 5; },
 *       // `errors['name']` will be "name must have length 5, got 'foo'"
 *       message: function(props) {
 *         return `${props.path} must have length 5, got '${props.value}'`;
 *       }
 *     });
 *
 * To bypass Mongoose's error messages and just copy the error message that
 * the validator throws, do this:
 *
 *     schema.path('name').validate({
 *       validator: function() { throw new Error('Oops!'); },
 *       // `errors['name'].message` will be "Oops!"
 *       message: function(props) { return props.reason.message; }
 *     });
 *
 * #### Asynchronous validation:
 *
 * Mongoose supports validators that return a promise. A validator that returns
 * a promise is called an _async validator_. Async validators run in
 * parallel, and `validate()` will wait until all async validators have settled.
 *
 *     schema.path('name').validate({
 *       validator: function (value) {
 *         return new Promise(function (resolve, reject) {
 *           resolve(false); // validation failed
 *         });
 *       }
 *     });
 *
 * You might use asynchronous validators to retreive other documents from the database to validate against or to meet other I/O bound validation needs.
 *
 * Validation occurs `pre('save')` or whenever you manually execute [document#validate](https://mongoosejs.com/docs/api/document.html#Document.prototype.validate()).
 *
 * If validation fails during `pre('save')` and no callback was passed to receive the error, an `error` event will be emitted on your Models associated db [connection](https://mongoosejs.com/docs/api/connection.html#Connection()), passing the validation error object along.
 *
 *     const conn = mongoose.createConnection(..);
 *     conn.on('error', handleError);
 *
 *     const Product = conn.model('Product', yourSchema);
 *     const dvd = new Product(..);
 *     dvd.save(); // emits error on the `conn` above
 *
 * If you want to handle these errors at the Model level, add an `error`
 * listener to your Model as shown below.
 *
 *     // registering an error listener on the Model lets us handle errors more locally
 *     Product.on('error', handleError);
 *
 * @param {RegExp|Function|Object} obj validator function, or hash describing options
 * @param {Function} [obj.validator] validator function. If the validator function returns `undefined` or a truthy value, validation succeeds. If it returns [falsy](https://masteringjs.io/tutorials/fundamentals/falsy) (except `undefined`) or throws an error, validation fails.
 * @param {String|Function} [obj.message] optional error message. If function, should return the error message as a string
 * @param {Boolean} [obj.propsParameter=false] If true, Mongoose will pass the validator properties object (with the `validator` function, `message`, etc.) as the 2nd arg to the validator function. This is disabled by default because many validators [rely on positional args](https://github.com/chriso/validator.js#validators), so turning this on may cause unpredictable behavior in external validators.
 * @param {String|Function} [errorMsg] optional error message. If function, should return the error message as a string
 * @param {String} [type] optional validator type
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.validate = function(obj, message, type) {
  if (typeof obj === 'function' || obj && utils.getFunctionName(obj.constructor) === 'RegExp') {
    let properties;
    if (typeof message === 'function') {
      properties = { validator: obj, message: message };
      properties.type = type || 'user defined';
    } else if (message instanceof Object && !type) {
      properties = isSimpleValidator(message) ? Object.assign({}, message) : clone(message);
      if (!properties.message) {
        properties.message = properties.msg;
      }
      properties.validator = obj;
      properties.type = properties.type || 'user defined';
    } else {
      if (message == null) {
        message = MongooseError.messages.general.default;
      }
      if (!type) {
        type = 'user defined';
      }
      properties = { message: message, type: type, validator: obj };
    }

    this.validators.push(properties);
    return this;
  }

  let i;
  let length;
  let arg;

  for (i = 0, length = arguments.length; i < length; i++) {
    arg = arguments[i];
    if (!utils.isPOJO(arg)) {
      const msg = 'Invalid validator. Received (' + typeof arg + ') '
        + arg
        + '. See https://mongoosejs.com/docs/api/schematype.html#SchemaType.prototype.validate()';

      throw new Error(msg);
    }
    this.validate(arg.validator, arg);
  }

  return this;
};

/**
 * Adds a required validator to this SchemaType. The validator gets added
 * to the front of this SchemaType's validators array using `unshift()`.
 *
 * #### Example:
 *
 *     const s = new Schema({ born: { type: Date, required: true })
 *
 *     // or with custom error message
 *
 *     const s = new Schema({ born: { type: Date, required: '{PATH} is required!' })
 *
 *     // or with a function
 *
 *     const s = new Schema({
 *       userId: ObjectId,
 *       username: {
 *         type: String,
 *         required: function() { return this.userId != null; }
 *       }
 *     })
 *
 *     // or with a function and a custom message
 *     const s = new Schema({
 *       userId: ObjectId,
 *       username: {
 *         type: String,
 *         required: [
 *           function() { return this.userId != null; },
 *           'username is required if id is specified'
 *         ]
 *       }
 *     })
 *
 *     // or through the path API
 *
 *     s.path('name').required(true);
 *
 *     // with custom error messaging
 *
 *     s.path('name').required(true, 'grrr :( ');
 *
 *     // or make a path conditionally required based on a function
 *     const isOver18 = function() { return this.age >= 18; };
 *     s.path('voterRegistrationId').required(isOver18);
 *
 * The required validator uses the SchemaType's `checkRequired` function to
 * determine whether a given value satisfies the required validator. By default,
 * a value satisfies the required validator if `val != null` (that is, if
 * the value is not null nor undefined). However, most built-in mongoose schema
 * types override the default `checkRequired` function:
 *
 * @param {Boolean|Function|Object} required enable/disable the validator, or function that returns required boolean, or options object
 * @param {Boolean|Function} [options.isRequired] enable/disable the validator, or function that returns required boolean
 * @param {Function} [options.ErrorConstructor] custom error constructor. The constructor receives 1 parameter, an object containing the validator properties.
 * @param {String} [message] optional custom error message
 * @return {SchemaType} this
 * @see Customized Error Messages https://mongoosejs.com/docs/api/error.html#Error.messages
 * @see SchemaArray#checkRequired https://mongoosejs.com/docs/api/schemaarray.html#SchemaArray.prototype.checkRequired()
 * @see SchemaBoolean#checkRequired https://mongoosejs.com/docs/api/schemaboolean.html#SchemaBoolean.prototype.checkRequired()
 * @see SchemaBuffer#checkRequired https://mongoosejs.com/docs/api/schemabuffer.html#SchemaBuffer.prototype.checkRequired()
 * @see SchemaNumber#checkRequired https://mongoosejs.com/docs/api/schemanumber.html#SchemaNumber.prototype.checkRequired()
 * @see SchemaObjectId#checkRequired https://mongoosejs.com/docs/api/schemaobjectid.html#ObjectId.prototype.checkRequired()
 * @see SchemaString#checkRequired https://mongoosejs.com/docs/api/schemastring.html#SchemaString.prototype.checkRequired()
 * @api public
 */

SchemaType.prototype.required = function(required, message) {
  let customOptions = {};

  if (arguments.length > 0 && required == null) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.requiredValidator;
    }, this);

    this.isRequired = false;
    delete this.originalRequiredValue;
    return this;
  }

  if (typeof required === 'object') {
    customOptions = required;
    message = customOptions.message || message;
    required = required.isRequired;
  }

  if (required === false) {
    this.validators = this.validators.filter(function(v) {
      return v.validator !== this.requiredValidator;
    }, this);

    this.isRequired = false;
    delete this.originalRequiredValue;
    return this;
  }

  const _this = this;
  this.isRequired = true;

  this.requiredValidator = function(v) {
    const cachedRequired = this && this.$__ && this.$__.cachedRequired;

    // no validation when this path wasn't selected in the query.
    if (cachedRequired != null && !this.$__isSelected(_this.path) && !this[documentIsModified](_this.path)) {
      return true;
    }

    // `$cachedRequired` gets set in `_evaluateRequiredFunctions()` so we
    // don't call required functions multiple times in one validate call
    // See gh-6801
    if (cachedRequired != null && _this.path in cachedRequired) {
      const res = cachedRequired[_this.path] ?
        _this.checkRequired(v, this) :
        true;
      delete cachedRequired[_this.path];
      return res;
    } else if (typeof required === 'function') {
      return required.apply(this) ? _this.checkRequired(v, this) : true;
    }

    return _this.checkRequired(v, this);
  };
  this.originalRequiredValue = required;

  if (typeof required === 'string') {
    message = required;
    required = undefined;
  }

  const msg = message || MongooseError.messages.general.required;
  this.validators.unshift(Object.assign({}, customOptions, {
    validator: this.requiredValidator,
    message: msg,
    type: 'required'
  }));

  return this;
};

/**
 * Set the model that this path refers to. This is the option that [populate](https://mongoosejs.com/docs/populate.html)
 * looks at to determine the foreign collection it should query.
 *
 * #### Example:
 *
 *     const userSchema = new Schema({ name: String });
 *     const User = mongoose.model('User', userSchema);
 *
 *     const postSchema = new Schema({ user: mongoose.ObjectId });
 *     postSchema.path('user').ref('User'); // Can set ref to a model name
 *     postSchema.path('user').ref(User); // Or a model class
 *     postSchema.path('user').ref(() => 'User'); // Or a function that returns the model name
 *     postSchema.path('user').ref(() => User); // Or a function that returns the model class
 *
 *     // Or you can just declare the `ref` inline in your schema
 *     const postSchema2 = new Schema({
 *       user: { type: mongoose.ObjectId, ref: User }
 *     });
 *
 * @param {String|Model|Function} ref either a model name, a [Model](https://mongoosejs.com/docs/models.html), or a function that returns a model name or model.
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.ref = function(ref) {
  this.options.ref = ref;
  return this;
};

/**
 * Gets the default value
 *
 * @param {Object} scope the scope which callback are executed
 * @param {Boolean} init
 * @return {Any} The Stored default value.
 * @api private
 */

SchemaType.prototype.getDefault = function(scope, init, options) {
  let ret;
  if (typeof this.defaultValue === 'function') {
    if (
      this.defaultValue === Date.now ||
      this.defaultValue === Array ||
      this.defaultValue.name.toLowerCase() === 'objectid'
    ) {
      ret = this.defaultValue.call(scope);
    } else {
      ret = this.defaultValue.call(scope, scope);
    }
  } else {
    ret = this.defaultValue;
  }

  if (ret !== null && ret !== undefined) {
    if (typeof ret === 'object' && (!this.options || !this.options.shared)) {
      ret = clone(ret);
    }

    if (options && options.skipCast) {
      return this._applySetters(ret, scope);
    }

    const casted = this.applySetters(ret, scope, init, undefined, setOptionsForDefaults);
    if (casted && !Array.isArray(casted) && casted.$isSingleNested) {
      casted.$__parent = scope;
    }
    return casted;
  }
  return ret;
};

/**
 * Applies setters without casting
 *
 * @param {Any} value
 * @param {Any} scope
 * @param {Boolean} init
 * @param {Any} priorVal
 * @param {Object} [options]
 * @instance
 * @api private
 */

SchemaType.prototype._applySetters = function(value, scope, init, priorVal, options) {
  let v = value;
  if (init) {
    return v;
  }
  const setters = this.setters;

  for (let i = setters.length - 1; i >= 0; i--) {
    v = setters[i].call(scope, v, priorVal, this, options);
  }

  return v;
};

/*!
 * ignore
 */

SchemaType.prototype._castNullish = function _castNullish(v) {
  return v;
};

/**
 * Applies setters
 *
 * @param {Object} value
 * @param {Object} scope
 * @param {Boolean} init
 * @return {Any}
 * @api private
 */

SchemaType.prototype.applySetters = function(value, scope, init, priorVal, options) {
  let v = this._applySetters(value, scope, init, priorVal, options);
  if (v == null) {
    return this._castNullish(v);
  }
  // do not cast until all setters are applied #665
  v = this.cast(v, scope, init, priorVal, options);

  return v;
};

/**
 * Applies getters to a value
 *
 * @param {Object} value
 * @param {Object} scope
 * @return {Any}
 * @api private
 */

SchemaType.prototype.applyGetters = function(value, scope) {
  let v = value;
  const getters = this.getters;
  const len = getters.length;

  if (len === 0) {
    return v;
  }

  for (let i = 0; i < len; ++i) {
    v = getters[i].call(scope, v, this);
  }

  return v;
};

/**
 * Sets default `select()` behavior for this path.
 *
 * Set to `true` if this path should always be included in the results, `false` if it should be excluded by default. This setting can be overridden at the query level.
 *
 * #### Example:
 *
 *     T = db.model('T', new Schema({ x: { type: String, select: true }}));
 *     T.find(..); // field x will always be selected ..
 *     // .. unless overridden;
 *     T.find().select('-x').exec(callback);
 *
 * @param {Boolean} val
 * @return {SchemaType} this
 * @api public
 */

SchemaType.prototype.select = function select(val) {
  this.selected = !!val;
  return this;
};

/**
 * Performs a validation of `value` using the validators declared for this SchemaType.
 *
 * @param {Any} value
 * @param {Function} callback
 * @param {Object} scope
 * @param {Object} [options]
 * @param {String} [options.path]
 * @return {Any} If no validators, returns the output from calling `fn`, otherwise no return
 * @api public
 */

SchemaType.prototype.doValidate = function(value, fn, scope, options) {
  let err = false;
  const path = this.path;
  if (typeof fn !== 'function') {
    throw new TypeError(`Must pass callback function to doValidate(), got ${typeof fn}`);
  }

  // Avoid non-object `validators`
  const validators = this.validators.
    filter(v => typeof v === 'object' && v !== null);

  let count = validators.length;

  if (!count) {
    return fn(null);
  }

  for (let i = 0, len = validators.length; i < len; ++i) {
    if (err) {
      break;
    }

    const v = validators[i];
    const validator = v.validator;
    let ok;

    const validatorProperties = isSimpleValidator(v) ? Object.assign({}, v) : clone(v);
    validatorProperties.path = options && options.path ? options.path : path;
    validatorProperties.fullPath = this.$fullPath;
    validatorProperties.value = value;

    if (validator instanceof RegExp) {
      validate(validator.test(value), validatorProperties, scope);
      continue;
    }

    if (typeof validator !== 'function') {
      continue;
    }

    if (value === undefined && validator !== this.requiredValidator) {
      validate(true, validatorProperties, scope);
      continue;
    }

    try {
      if (validatorProperties.propsParameter) {
        ok = validator.call(scope, value, validatorProperties);
      } else {
        ok = validator.call(scope, value);
      }
    } catch (error) {
      ok = false;
      validatorProperties.reason = error;
      if (error.message) {
        validatorProperties.message = error.message;
      }
    }

    if (ok != null && typeof ok.then === 'function') {
      ok.then(
        function(ok) { validate(ok, validatorProperties, scope); },
        function(error) {
          validatorProperties.reason = error;
          validatorProperties.message = error.message;
          ok = false;
          validate(ok, validatorProperties, scope);
        });
    } else {
      validate(ok, validatorProperties, scope);
    }
  }

  function validate(ok, validatorProperties, scope) {
    if (err) {
      return;
    }
    if (ok === undefined || ok) {
      if (--count <= 0) {
        immediate(function() {
          fn(null);
        });
      }
    } else {
      const ErrorConstructor = validatorProperties.ErrorConstructor || ValidatorError;
      err = new ErrorConstructor(validatorProperties, scope);
      err[validatorErrorSymbol] = true;
      immediate(function() {
        fn(err);
      });
    }
  }
};


function _validate(ok, validatorProperties) {
  if (ok !== undefined && !ok) {
    const ErrorConstructor = validatorProperties.ErrorConstructor || ValidatorError;
    const err = new ErrorConstructor(validatorProperties);
    err[validatorErrorSymbol] = true;
    return err;
  }
}

/**
 * Performs a validation of `value` using the validators declared for this SchemaType.
 *
 * #### Note:
 *
 * This method ignores the asynchronous validators.
 *
 * @param {Any} value
 * @param {Object} scope
 * @param {Object} [options]
 * @param {Object} [options.path]
 * @return {MongooseError|null}
 * @api private
 */

SchemaType.prototype.doValidateSync = function(value, scope, options) {
  const path = this.path;
  const count = this.validators.length;

  if (!count) {
    return null;
  }

  let validators = this.validators;
  if (value === void 0) {
    if (this.validators.length !== 0 && this.validators[0].type === 'required') {
      validators = [this.validators[0]];
    } else {
      return null;
    }
  }

  let err = null;
  let i = 0;
  const len = validators.length;
  for (i = 0; i < len; ++i) {
    const v = validators[i];

    if (v === null || typeof v !== 'object') {
      continue;
    }

    const validator = v.validator;
    const validatorProperties = isSimpleValidator(v) ? Object.assign({}, v) : clone(v);
    validatorProperties.path = options && options.path ? options.path : path;
    validatorProperties.fullPath = this.$fullPath;
    validatorProperties.value = value;
    let ok = false;

    // Skip any explicit async validators. Validators that return a promise
    // will still run, but won't trigger any errors.
    if (isAsyncFunction(validator)) {
      continue;
    }

    if (validator instanceof RegExp) {
      err = _validate(validator.test(value), validatorProperties);
      continue;
    }

    if (typeof validator !== 'function') {
      continue;
    }

    try {
      if (validatorProperties.propsParameter) {
        ok = validator.call(scope, value, validatorProperties);
      } else {
        ok = validator.call(scope, value);
      }
    } catch (error) {
      ok = false;
      validatorProperties.reason = error;
    }

    // Skip any validators that return a promise, we can't handle those
    // synchronously
    if (ok != null && typeof ok.then === 'function') {
      continue;
    }
    err = _validate(ok, validatorProperties);
    if (err) {
      break;
    }
  }

  return err;
};

/**
 * Determines if value is a valid Reference.
 *
 * @param {SchemaType} self
 * @param {Object} value
 * @param {Document} doc
 * @param {Boolean} init
 * @return {Boolean}
 * @api private
 */

SchemaType._isRef = function(self, value, doc, init) {
  // fast path
  let ref = init && self.options && (self.options.ref || self.options.refPath);

  if (!ref && doc && doc.$__ != null) {
    // checks for
    // - this populated with adhoc model and no ref was set in schema OR
    // - setting / pushing values after population
    const path = doc.$__fullPath(self.path, true);

    const owner = doc.ownerDocument();
    ref = (path != null && owner.$populated(path)) || doc.$populated(self.path);
  }

  if (ref) {
    if (value == null) {
      return true;
    }
    if (!Buffer.isBuffer(value) && // buffers are objects too
      value._bsontype !== 'Binary' // raw binary value from the db
      && utils.isObject(value) // might have deselected _id in population query
    ) {
      return true;
    }

    return init;
  }

  return false;
};

/*!
 * ignore
 */

SchemaType.prototype._castRef = function _castRef(value, doc, init) {
  if (value == null) {
    return value;
  }

  if (value.$__ != null) {
    value.$__.wasPopulated = value.$__.wasPopulated || { value: value._id };
    return value;
  }

  // setting a populated path
  if (Buffer.isBuffer(value) || !utils.isObject(value)) {
    if (init) {
      return value;
    }
    throw new CastError(this.instance, value, this.path, null, this);
  }

  // Handle the case where user directly sets a populated
  // path to a plain object; cast to the Model used in
  // the population query.
  const path = doc.$__fullPath(this.path, true);
  const owner = doc.ownerDocument();
  const pop = owner.$populated(path, true);

  let ret = value;
  if (!doc.$__.populated ||
    !doc.$__.populated[path] ||
    !doc.$__.populated[path].options ||
    !doc.$__.populated[path].options.options ||
    !doc.$__.populated[path].options.options.lean) {
    ret = new pop.options[populateModelSymbol](value);
    ret.$__.wasPopulated = { value: ret._id };
  }

  return ret;
};

/*!
 * ignore
 */

function handleSingle(val, context) {
  return this.castForQuery(null, val, context);
}

/*!
 * ignore
 */

function handleArray(val, context) {
  const _this = this;
  if (!Array.isArray(val)) {
    return [this.castForQuery(null, val, context)];
  }
  return val.map(function(m) {
    return _this.castForQuery(null, m, context);
  });
}

/**
 * Just like handleArray, except also allows `[]` because surprisingly
 * `$in: [1, []]` works fine
 * @api private
 */

function handle$in(val, context) {
  const _this = this;
  if (!Array.isArray(val)) {
    return [this.castForQuery(null, val, context)];
  }
  return val.map(function(m) {
    if (Array.isArray(m) && m.length === 0) {
      return m;
    }
    return _this.castForQuery(null, m, context);
  });
}

/*!
 * ignore
 */

SchemaType.prototype.$conditionalHandlers = {
  $all: handleArray,
  $eq: handleSingle,
  $in: handle$in,
  $ne: handleSingle,
  $nin: handle$in,
  $exists: $exists,
  $type: $type
};

/**
 * Cast the given value with the given optional query operator.
 *
 * @param {String} [$conditional] query operator, like `$eq` or `$in`
 * @param {Any} val
 * @param {Query} context
 * @return {Any}
 * @api private
 */

SchemaType.prototype.castForQuery = function($conditional, val, context) {
  let handler;
  if ($conditional != null) {
    handler = this.$conditionalHandlers[$conditional];
    if (!handler) {
      throw new Error('Can\'t use ' + $conditional);
    }
    return handler.call(this, val, context);
  }

  try {
    return this.applySetters(val, context);
  } catch (err) {
    if (err instanceof CastError && err.path === this.path && this.$fullPath != null) {
      err.path = this.$fullPath;
    }
    throw err;
  }
};

/**
 * Set & Get the `checkRequired` function
 * Override the function the required validator uses to check whether a value
 * passes the `required` check. Override this on the individual SchemaType.
 *
 * #### Example:
 *
 *     // Use this to allow empty strings to pass the `required` validator
 *     mongoose.Schema.Types.String.checkRequired(v => typeof v === 'string');
 *
 * @param {Function} [fn] If set, will overwrite the current set function
 * @return {Function} The input `fn` or the already set function
 * @static
 * @memberOf SchemaType
 * @function checkRequired
 * @api public
 */

SchemaType.checkRequired = function(fn) {
  if (arguments.length !== 0) {
    this._checkRequired = fn;
  }

  return this._checkRequired;
};

/**
 * Default check for if this path satisfies the `required` validator.
 *
 * @param {Any} val
 * @return {Boolean} `true` when the value is not `null`, `false` otherwise
 * @api private
 */

SchemaType.prototype.checkRequired = function(val) {
  return val != null;
};

/**
 * Clone the current SchemaType
 *
 * @return {SchemaType} The cloned SchemaType instance
 * @api private
 */

SchemaType.prototype.clone = function() {
  const options = Object.assign({}, this.options);
  const schematype = new this.constructor(this.path, options, this.instance);
  schematype.validators = this.validators.slice();
  if (this.requiredValidator !== undefined) schematype.requiredValidator = this.requiredValidator;
  if (this.defaultValue !== undefined) schematype.defaultValue = this.defaultValue;
  if (this.$immutable !== undefined && this.options.immutable === undefined) {
    schematype.$immutable = this.$immutable;

    handleImmutable(schematype);
  }
  if (this._index !== undefined) schematype._index = this._index;
  if (this.selected !== undefined) schematype.selected = this.selected;
  if (this.isRequired !== undefined) schematype.isRequired = this.isRequired;
  if (this.originalRequiredValue !== undefined) schematype.originalRequiredValue = this.originalRequiredValue;
  schematype.getters = this.getters.slice();
  schematype.setters = this.setters.slice();
  return schematype;
};

/*!
 * Module exports.
 */

module.exports = exports = SchemaType;

exports.CastError = CastError;

exports.ValidatorError = ValidatorError;

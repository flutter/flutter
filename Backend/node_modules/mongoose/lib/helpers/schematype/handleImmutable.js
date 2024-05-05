'use strict';

const StrictModeError = require('../../error/strict');

/*!
 * ignore
 */

module.exports = function(schematype) {
  if (schematype.$immutable) {
    schematype.$immutableSetter = createImmutableSetter(schematype.path,
      schematype.options.immutable);
    schematype.set(schematype.$immutableSetter);
  } else if (schematype.$immutableSetter) {
    schematype.setters = schematype.setters.
      filter(fn => fn !== schematype.$immutableSetter);
    delete schematype.$immutableSetter;
  }
};

function createImmutableSetter(path, immutable) {
  return function immutableSetter(v, _priorVal, _doc, options) {
    if (this == null || this.$__ == null) {
      return v;
    }
    if (this.isNew) {
      return v;
    }
    if (options && options.overwriteImmutable) {
      return v;
    }

    const _immutable = typeof immutable === 'function' ?
      immutable.call(this, this) :
      immutable;
    if (!_immutable) {
      return v;
    }

    const _value = this.$__.priorDoc != null ?
      this.$__.priorDoc.$__getValue(path) :
      this.$__getValue(path);
    if (this.$__.strictMode === 'throw' && v !== _value) {
      throw new StrictModeError(path, 'Path `' + path + '` is immutable ' +
        'and strict mode is set to throw.', true);
    }

    return _value;
  };
}

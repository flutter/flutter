'use strict';

/*!
 * ignore
 */

module.exports = function validateBeforeSave(schema) {
  const unshift = true;
  schema.pre('save', false, function validateBeforeSave(next, options) {
    const _this = this;
    // Nested docs have their own presave
    if (this.$isSubdocument) {
      return next();
    }

    const hasValidateBeforeSaveOption = options &&
        (typeof options === 'object') &&
        ('validateBeforeSave' in options);

    let shouldValidate;
    if (hasValidateBeforeSaveOption) {
      shouldValidate = !!options.validateBeforeSave;
    } else {
      shouldValidate = this.$__schema.options.validateBeforeSave;
    }

    // Validate
    if (shouldValidate) {
      const hasValidateModifiedOnlyOption = options &&
          (typeof options === 'object') &&
          ('validateModifiedOnly' in options);
      const validateOptions = hasValidateModifiedOnlyOption ?
        { validateModifiedOnly: options.validateModifiedOnly } :
        null;
      this.$validate(validateOptions).then(
        () => {
          this.$op = 'save';
          next();
        },
        error => {
          _this.$__schema.s.hooks.execPost('save:error', _this, [_this], { error: error }, function(error) {
            _this.$op = 'save';
            next(error);
          });
        }
      );
    } else {
      next();
    }
  }, null, unshift);
};

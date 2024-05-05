
/**
 * The default built-in validator error messages. These may be customized.
 *
 *     // customize within each schema or globally like so
 *     const mongoose = require('mongoose');
 *     mongoose.Error.messages.String.enum  = "Your custom message for {PATH}.";
 *
 * Error messages support basic templating. Mongoose will replace the following strings with the corresponding value.
 *
 * - `{PATH}` is replaced with the invalid document path
 * - `{VALUE}` is replaced with the invalid value
 * - `{TYPE}` is replaced with the validator type such as "regexp", "min", or "user defined"
 * - `{MIN}` is replaced with the declared min value for the Number.min validator
 * - `{MAX}` is replaced with the declared max value for the Number.max validator
 *
 * Click the "show code" link below to see all defaults.
 *
 * @static
 * @memberOf MongooseError
 * @api public
 */

'use strict';

const msg = module.exports = exports = {};

msg.DocumentNotFoundError = null;

msg.general = {};
msg.general.default = 'Validator failed for path `{PATH}` with value `{VALUE}`';
msg.general.required = 'Path `{PATH}` is required.';

msg.Number = {};
msg.Number.min = 'Path `{PATH}` ({VALUE}) is less than minimum allowed value ({MIN}).';
msg.Number.max = 'Path `{PATH}` ({VALUE}) is more than maximum allowed value ({MAX}).';
msg.Number.enum = '`{VALUE}` is not a valid enum value for path `{PATH}`.';

msg.Date = {};
msg.Date.min = 'Path `{PATH}` ({VALUE}) is before minimum allowed value ({MIN}).';
msg.Date.max = 'Path `{PATH}` ({VALUE}) is after maximum allowed value ({MAX}).';

msg.String = {};
msg.String.enum = '`{VALUE}` is not a valid enum value for path `{PATH}`.';
msg.String.match = 'Path `{PATH}` is invalid ({VALUE}).';
msg.String.minlength = 'Path `{PATH}` (`{VALUE}`) is shorter than the minimum allowed length ({MINLENGTH}).';
msg.String.maxlength = 'Path `{PATH}` (`{VALUE}`) is longer than the maximum allowed length ({MAXLENGTH}).';

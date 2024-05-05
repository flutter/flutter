'use strict';

module.exports = function stringToParts(str) {
  const result = [];

  let curPropertyName = '';
  let state = 'DEFAULT';
  for (let i = 0; i < str.length; ++i) {
    // Fall back to treating as property name rather than bracket notation if
    // square brackets contains something other than a number.
    if (state === 'IN_SQUARE_BRACKETS' && !/\d/.test(str[i]) && str[i] !== ']') {
      state = 'DEFAULT';
      curPropertyName = result[result.length - 1] + '[' + curPropertyName;
      result.splice(result.length - 1, 1);
    }

    if (str[i] === '[') {
      if (state !== 'IMMEDIATELY_AFTER_SQUARE_BRACKETS') {
        result.push(curPropertyName);
        curPropertyName = '';
      }
      state = 'IN_SQUARE_BRACKETS';
    } else if (str[i] === ']') {
      if (state === 'IN_SQUARE_BRACKETS') {
        state = 'IMMEDIATELY_AFTER_SQUARE_BRACKETS';
        result.push(curPropertyName);
        curPropertyName = '';
      } else {
        state = 'DEFAULT';
        curPropertyName += str[i];
      }
    } else if (str[i] === '.') {
      if (state !== 'IMMEDIATELY_AFTER_SQUARE_BRACKETS') {
        result.push(curPropertyName);
        curPropertyName = '';
      }
      state = 'DEFAULT';
    } else {
      curPropertyName += str[i];
    }
  }

  if (state !== 'IMMEDIATELY_AFTER_SQUARE_BRACKETS') {
    result.push(curPropertyName);
  }

  return result;
};
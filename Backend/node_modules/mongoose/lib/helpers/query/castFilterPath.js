'use strict';

const isOperator = require('./isOperator');

module.exports = function castFilterPath(ctx, schematype, val) {
  const any$conditionals = Object.keys(val).some(isOperator);

  if (!any$conditionals) {
    return schematype.castForQuery(
      null,
      val,
      ctx
    );
  }

  const ks = Object.keys(val);

  let k = ks.length;

  while (k--) {
    const $cond = ks[k];
    const nested = val[$cond];

    if ($cond === '$not') {
      if (nested && schematype && !schematype.caster) {
        const _keys = Object.keys(nested);
        if (_keys.length && isOperator(_keys[0])) {
          for (const key of Object.keys(nested)) {
            nested[key] = schematype.castForQuery(
              key,
              nested[key],
              ctx
            );
          }
        } else {
          val[$cond] = schematype.castForQuery(
            $cond,
            nested,
            ctx
          );
        }
        continue;
      }
    } else {
      val[$cond] = schematype.castForQuery(
        $cond,
        nested,
        ctx
      );
    }
  }

  return val;
};

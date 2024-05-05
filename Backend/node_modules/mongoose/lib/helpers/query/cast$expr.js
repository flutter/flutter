'use strict';

const CastError = require('../../error/cast');
const StrictModeError = require('../../error/strict');
const castNumber = require('../../cast/number');

const booleanComparison = new Set(['$and', '$or']);
const comparisonOperator = new Set(['$cmp', '$eq', '$lt', '$lte', '$gt', '$gte']);
const arithmeticOperatorArray = new Set([
  // avoid casting '$add' or '$subtract', because expressions can be either number or date,
  // and we don't have a good way of inferring which arguments should be numbers and which should
  // be dates.
  '$multiply',
  '$divide',
  '$log',
  '$mod',
  '$trunc',
  '$avg',
  '$max',
  '$min',
  '$stdDevPop',
  '$stdDevSamp',
  '$sum'
]);
const arithmeticOperatorNumber = new Set([
  '$abs',
  '$exp',
  '$ceil',
  '$floor',
  '$ln',
  '$log10',
  '$sqrt',
  '$sin',
  '$cos',
  '$tan',
  '$asin',
  '$acos',
  '$atan',
  '$atan2',
  '$asinh',
  '$acosh',
  '$atanh',
  '$sinh',
  '$cosh',
  '$tanh',
  '$degreesToRadians',
  '$radiansToDegrees'
]);
const arrayElementOperators = new Set([
  '$arrayElemAt',
  '$first',
  '$last'
]);
const dateOperators = new Set([
  '$year',
  '$month',
  '$week',
  '$dayOfMonth',
  '$dayOfYear',
  '$hour',
  '$minute',
  '$second',
  '$isoDayOfWeek',
  '$isoWeekYear',
  '$isoWeek',
  '$millisecond'
]);
const expressionOperator = new Set(['$not']);

module.exports = function cast$expr(val, schema, strictQuery) {
  if (typeof val !== 'object' || val === null) {
    throw new Error('`$expr` must be an object');
  }

  return _castExpression(val, schema, strictQuery);
};

function _castExpression(val, schema, strictQuery) {
  // Preserve the value if it represents a path or if it's null
  if (isPath(val) || val === null) {
    return val;
  }

  if (val.$cond != null) {
    if (Array.isArray(val.$cond)) {
      val.$cond = val.$cond.map(expr => _castExpression(expr, schema, strictQuery));
    } else {
      val.$cond.if = _castExpression(val.$cond.if, schema, strictQuery);
      val.$cond.then = _castExpression(val.$cond.then, schema, strictQuery);
      val.$cond.else = _castExpression(val.$cond.else, schema, strictQuery);
    }
  } else if (val.$ifNull != null) {
    val.$ifNull.map(v => _castExpression(v, schema, strictQuery));
  } else if (val.$switch != null) {
    val.branches.map(v => _castExpression(v, schema, strictQuery));
    val.default = _castExpression(val.default, schema, strictQuery);
  }

  const keys = Object.keys(val);
  for (const key of keys) {
    if (booleanComparison.has(key)) {
      val[key] = val[key].map(v => _castExpression(v, schema, strictQuery));
    } else if (comparisonOperator.has(key)) {
      val[key] = castComparison(val[key], schema, strictQuery);
    } else if (arithmeticOperatorArray.has(key)) {
      val[key] = castArithmetic(val[key], schema, strictQuery);
    } else if (arithmeticOperatorNumber.has(key)) {
      val[key] = castNumberOperator(val[key], schema, strictQuery);
    } else if (expressionOperator.has(key)) {
      val[key] = _castExpression(val[key], schema, strictQuery);
    }
  }

  if (val.$in) {
    val.$in = castIn(val.$in, schema, strictQuery);
  }
  if (val.$size) {
    val.$size = castNumberOperator(val.$size, schema, strictQuery);
  }
  if (val.$round) {
    const $round = val.$round;
    if (!Array.isArray($round) || $round.length < 1 || $round.length > 2) {
      throw new CastError('Array', $round, '$round');
    }
    val.$round = $round.map(v => castNumberOperator(v, schema, strictQuery));
  }

  _omitUndefined(val);

  return val;
}

function _omitUndefined(val) {
  const keys = Object.keys(val);
  for (let i = 0, len = keys.length; i < len; ++i) {
    (val[keys[i]] === void 0) && delete val[keys[i]];
  }
}

// { $op: <number> }
function castNumberOperator(val) {
  if (!isLiteral(val)) {
    return val;
  }

  try {
    return castNumber(val);
  } catch (err) {
    throw new CastError('Number', val);
  }
}

function castIn(val, schema, strictQuery) {
  const path = val[1];
  if (!isPath(path)) {
    return val;
  }
  const search = val[0];

  const schematype = schema.path(path.slice(1));
  if (schematype === null) {
    if (strictQuery === false) {
      return val;
    } else if (strictQuery === 'throw') {
      throw new StrictModeError('$in');
    }

    return void 0;
  }

  if (!schematype.$isMongooseArray) {
    throw new Error('Path must be an array for $in');
  }

  return [
    schematype.$isMongooseDocumentArray ? schematype.$embeddedSchemaType.cast(search) : schematype.caster.cast(search),
    path
  ];
}

// { $op: [<number>, <number>] }
function castArithmetic(val) {
  if (!Array.isArray(val)) {
    if (!isLiteral(val)) {
      return val;
    }
    try {
      return castNumber(val);
    } catch (err) {
      throw new CastError('Number', val);
    }
  }

  return val.map(v => {
    if (!isLiteral(v)) {
      return v;
    }
    try {
      return castNumber(v);
    } catch (err) {
      throw new CastError('Number', v);
    }
  });
}

// { $op: [expression, expression] }
function castComparison(val, schema, strictQuery) {
  if (!Array.isArray(val) || val.length !== 2) {
    throw new Error('Comparison operator must be an array of length 2');
  }

  val[0] = _castExpression(val[0], schema, strictQuery);
  const lhs = val[0];

  if (isLiteral(val[1])) {
    let path = null;
    let schematype = null;
    let caster = null;
    if (isPath(lhs)) {
      path = lhs.slice(1);
      schematype = schema.path(path);
    } else if (typeof lhs === 'object' && lhs != null) {
      for (const key of Object.keys(lhs)) {
        if (dateOperators.has(key) && isPath(lhs[key])) {
          path = lhs[key].slice(1) + '.' + key;
          caster = castNumber;
        } else if (arrayElementOperators.has(key) && isPath(lhs[key])) {
          path = lhs[key].slice(1) + '.' + key;
          schematype = schema.path(lhs[key].slice(1));
          if (schematype != null) {
            if (schematype.$isMongooseDocumentArray) {
              schematype = schematype.$embeddedSchemaType;
            } else if (schematype.$isMongooseArray) {
              schematype = schematype.caster;
            }
          }
        }
      }
    }

    const is$literal = typeof val[1] === 'object' && val[1] != null && val[1].$literal != null;
    if (schematype != null) {
      if (is$literal) {
        val[1] = { $literal: schematype.cast(val[1].$literal) };
      } else {
        val[1] = schematype.cast(val[1]);
      }
    } else if (caster != null) {
      if (is$literal) {
        try {
          val[1] = { $literal: caster(val[1].$literal) };
        } catch (err) {
          throw new CastError(caster.name.replace(/^cast/, ''), val[1], path + '.$literal');
        }
      } else {
        try {
          val[1] = caster(val[1]);
        } catch (err) {
          throw new CastError(caster.name.replace(/^cast/, ''), val[1], path);
        }
      }
    } else if (path != null && strictQuery === true) {
      return void 0;
    } else if (path != null && strictQuery === 'throw') {
      throw new StrictModeError(path);
    }
  } else {
    val[1] = _castExpression(val[1]);
  }

  return val;
}

function isPath(val) {
  return typeof val === 'string' && val[0] === '$';
}

function isLiteral(val) {
  if (typeof val === 'string' && val[0] === '$') {
    return false;
  }
  if (typeof val === 'object' && val !== null && Object.keys(val).find(key => key[0] === '$')) {
    // The `$literal` expression can make an object a literal
    // https://www.mongodb.com/docs/manual/reference/operator/aggregation/literal/#mongodb-expression-exp.-literal
    return val.$literal != null;
  }
  return true;
}

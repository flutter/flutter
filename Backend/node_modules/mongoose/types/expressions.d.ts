declare module 'mongoose' {

  /**
   * [Expressions reference](https://www.mongodb.com/docs/manual/meta/aggregation-quick-reference/#expressions)
   */
  type AggregationVariables =
    SpecialPathVariables |
    '$$NOW' |
    '$$CLUSTER_TIME' |
    '$$DESCEND' |
    '$$PRUNE' |
    '$$KEEP';

  type SpecialPathVariables =
    '$$ROOT' |
    '$$CURRENT' |
    '$$REMOVE';

  export namespace Expression {
    export interface Abs {
      /**
       * Returns the absolute value of a number.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/abs/#mongodb-expression-exp.-abs
       */
      $abs: Path | ArithmeticExpressionOperator;
    }

    export interface Add {
      /**
       * Adds numbers to return the sum, or adds numbers and a date to return a new date. If adding numbers and a date, treats the numbers as milliseconds. Accepts any number of argument expressions, but at most, one expression can resolve to a date.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/add/#mongodb-expression-exp.-add
       */
      $add: Expression[];
    }

    export interface Ceil {
      /**
       * Returns the smallest integer greater than or equal to the specified number.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/ceil/#mongodb-expression-exp.-ceil
       */
      $ceil: NumberExpression;
    }

    export interface Divide {
      /**
       * Returns the result of dividing the first number by the second. Accepts two argument expressions.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/divide/#mongodb-expression-exp.-divide
       */
      $divide: NumberExpression[];
    }

    export interface Exp {
      /**
       * Raises e to the specified exponent.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/exp/#mongodb-expression-exp.-exp
       */
      $exp: NumberExpression;
    }

    export interface Floor {
      /**
       * Returns the largest integer less than or equal to the specified number.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/floor/#mongodb-expression-exp.-floor
       */
      $floor: NumberExpression;
    }

    export interface Ln {
      /**
       * Calculates the natural log of a number.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/ln/#mongodb-expression-exp.-ln
       */
      $ln: NumberExpression;
    }

    export interface Log {
      /**
       * Calculates the log of a number in the specified base.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/log/#mongodb-expression-exp.-log
       */
      $log: [NumberExpression, NumberExpression];
    }

    export interface Log10 {
      /**
       * Calculates the log base 10 of a number.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/log10/#mongodb-expression-exp.-log10
       */
      $log10: NumberExpression;
    }

    export interface Mod {
      /**
       * Returns the remainder of the first number divided by the second. Accepts two argument expressions.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/mod/#mongodb-expression-exp.-mod
       */
      $mod: [NumberExpression, NumberExpression];
    }
    export interface Multiply {
      /**
       * Multiplies numbers to return the product. Accepts any number of argument expressions.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/multiply/#mongodb-expression-exp.-multiply
       */
      $multiply: NumberExpression[];
    }

    export interface Pow {
      /**
       * Raises a number to the specified exponent.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/pow/#mongodb-expression-exp.-pow
       */
      $pow: [NumberExpression, NumberExpression];
    }

    export interface Round {
      /**
       * Rounds a number to to a whole integer or to a specified decimal place.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/round/#mongodb-expression-exp.-round
       */
      $round: [NumberExpression, NumberExpression?];
    }

    export interface Sqrt {
      /**
       * Calculates the square root.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/sqrt/#mongodb-expression-exp.-sqrt
       */
      $sqrt: NumberExpression;
    }

    export interface Subtract {
      /**
       * Returns the result of subtracting the second value from the first. If the two values are numbers, return the difference. If the two values are dates, return the difference in milliseconds. If the two values are a date and a number in milliseconds, return the resulting date. Accepts two argument expressions. If the two values are a date and a number, specify the date argument first as it is not meaningful to subtract a date from a number.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/subtract/#mongodb-expression-exp.-subtract
       */
      $subtract: (NumberExpression | DateExpression)[];
    }

    export interface Trunc {
      /**
       * Truncates a number to a whole integer or to a specified decimal place.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/trunc/#mongodb-expression-exp.-trunc
       */
      $trunc: [NumberExpression, NumberExpression?];
    }

    export interface Sin {
      /**
       * Returns the sine of a value that is measured in radians.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/sin/#mongodb-expression-exp.-sin
       */
      $sin: NumberExpression;
    }

    export interface Cos {
      /**
       * Returns the cosine of a value that is measured in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/cos/#mongodb-expression-exp.-cos
       */
      $cos: NumberExpression;
    }

    export interface Tan {
      /**
       * Returns the tangent of a value that is measured in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/tan/#mongodb-expression-exp.-tan
       */
      $tan: NumberExpression;
    }

    export interface Asin {
      /**
       * Returns the inverse sin (arc sine) of a value in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/asin/#mongodb-expression-exp.-asin
       */
      $asin: NumberExpression;
    }

    export interface Acos {
      /**
       * Returns the inverse cosine (arc cosine) of a value in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/acos/#mongodb-expression-exp.-acos
       */
      $acos: NumberExpression;
    }

    export interface Atan {
      /**
       * Returns the inverse tangent (arc tangent) of a value in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/atan/#mongodb-expression-exp.-atan
       */
      $atan: NumberExpression;
    }

    export interface Atan2 {
      /**
       * Returns the inverse tangent (arc tangent) of y / x in radians, where y and x are the first and second values passed to the expression respectively.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/atan2/#mongodb-expression-exp.-atan2
       */
      $atan2: NumberExpression;
    }

    export interface Asinh {
      /**
       * Returns the inverse hyperbolic sine (hyperbolic arc sine) of a value in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/asinh/#mongodb-expression-exp.-asinh
       */
      $asinh: NumberExpression;
    }

    export interface Acosh {
      /**
       * Returns the inverse hyperbolic cosine (hyperbolic arc cosine) of a value in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/acosh/#mongodb-expression-exp.-acosh
       */
      $acosh: NumberExpression;
    }

    export interface Atanh {

      /**
       * Returns the inverse hyperbolic tangent (hyperbolic arc tangent) of a value in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/atanh/#mongodb-expression-exp.-atanh
       */
      $atanh: NumberExpression;
    }

    export interface Sinh {
      /**
       * Returns the hyperbolic sine of a value that is measured in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/sinh/#mongodb-expression-exp.-sinh
       */
      $sinh: NumberExpression;
    }

    export interface Cosh {
      /**
       * Returns the hyperbolic cosine of a value that is measured in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/cosh/#mongodb-expression-exp.-cosh
       */
      $cosh: NumberExpression;
    }

    export interface Tanh {
      /**
       * Returns the hyperbolic tangent of a value that is measured in radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/tanh/#mongodb-expression-exp.-tanh
       */
      $tanh: NumberExpression;
    }

    export interface DegreesToRadians {
      /**
       * Converts a value from degrees to radians.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/degreesToRadians/#mongodb-expression-exp.-degreesToRadians
       */
      $degreesToRadians: NumberExpression;
    }

    export interface RadiansToDegrees {
      /**
       * Converts a value from radians to degrees.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/radiansToDegrees/#mongodb-expression-exp.-radiansToDegrees
       */
      $radiansToDegrees: NumberExpression;
    }

    export interface Meta {
      /**
       * Access available per-document metadata related to the aggregation operation.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/meta/#mongodb-expression-exp.-meta
       */
      $meta: 'textScore' | 'indexKey';
    }

    export interface DateAdd {
      /**
       * Adds a number of time units to a date object.
       *
       * @version 5.0.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateAdd/#mongodb-expression-exp.-dateAdd
       */
      $dateAdd: {
        /**
         * The beginning date, in UTC, for the addition operation. The startDate can be any expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        startDate: DateExpression;
        /**
         * The unit used to measure the amount of time added to the startDate. The unit is an expression that resolves to one of the following strings:
         * - year
         * - quarter
         * - week
         * - month
         * - day
         * - hour
         * - minute
         * - second
         * - millisecond
         */
        unit: StringExpression<DateUnit>;
        /**
         * The number of units added to the startDate. The amount is an expression that resolves to an integer or long. The amount can also resolve to an integral decimal or a double if that value can be converted to a long without loss of precision.
         */
        amount: NumberExpression;
        /**
         * The timezone to carry out the operation. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface DateDiff {
      /**
       * Returns the difference between two dates.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateDiff/#mongodb-expression-exp.-dateDiff
       */
      $dateDiff: {
        /**
         * The start of the time period. The startDate can be any expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        startDate: DateExpression;
        /**
         * The end of the time period. The endDate can be any expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        endDate: DateExpression;
        /**
         * The time measurement unit between the startDate and endDate. It is an expression that resolves to a string:
         * - year
         * - quarter
         * - week
         * - month
         * - day
         * - hour
         * - minute
         * - second
         * - millisecond
         */
        unit: StringExpression<DateUnit>;
        /**
         * The timezone to carry out the operation. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
        /**
         * Used when the unit is equal to week. Defaults to Sunday. The startOfWeek parameter is an expression that resolves to a case insensitive string:
         * - monday (or mon)
         * - tuesday (or tue)
         * - wednesday (or wed)
         * - thursday (or thu)
         * - friday (or fri)
         * - saturday (or sat)
         * - sunday (or sun)
         */
        startOfWeek?: StringExpression<StartOfWeek>;
      }
    }

    // TODO: Can be done better
    export interface DateFromParts {
      /**
       * Constructs a BSON Date object given the date's constituent parts.
       *
       * @version 3.6
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateFromParts/#mongodb-expression-exp.-dateFromParts
       */
      $dateFromParts: {
        /**
         * ISO Week Date Year. Can be any expression that evaluates to a number.
         *
         * Value range: 1-9999
         *
         * If the number specified is outside this range, $dateFromParts errors. Starting in MongoDB 4.4, the lower bound for this value is 1. In previous versions of MongoDB, the lower bound was 0.
         */
        isoWeekYear?: NumberExpression;
        /**
         * Week of year. Can be any expression that evaluates to a number.
         *
         * Defaults to 1.
         *
         * Value range: 1-53
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        isoWeek?: NumberExpression;
        /**
         * Day of week (Monday 1 - Sunday 7). Can be any expression that evaluates to a number.
         *
         * Defaults to 1.
         *
         * Value range: 1-7
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        isoDayOfWeek?: NumberExpression;
        /**
         * Calendar year. Can be any expression that evaluates to a number.
         *
         * Value range: 1-9999
         *
         * If the number specified is outside this range, $dateFromParts errors. Starting in MongoDB 4.4, the lower bound for this value is 1. In previous versions of MongoDB, the lower bound was 0.
         */
        year?: NumberExpression;
        /**
         * Month. Can be any expression that evaluates to a number.
         *
         * Defaults to 1.
         *
         * Value range: 1-12
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        month?: NumberExpression;
        /**
         * Day of month. Can be any expression that evaluates to a number.
         *
         * Defaults to 1.
         *
         * Value range: 1-31
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        day?: NumberExpression;
        /**
         * Hour. Can be any expression that evaluates to a number.
         *
         * Defaults to 0.
         *
         * Value range: 0-23
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        hour?: NumberExpression;
        /**
         * Minute. Can be any expression that evaluates to a number.
         *
         * Defaults to 0.
         *
         * Value range: 0-59 Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        minute?: NumberExpression;
        /**
         * Second. Can be any expression that evaluates to a number.
         *
         * Defaults to 0.
         *
         * Value range: 0-59
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        second?: NumberExpression;
        /**
         * Millisecond. Can be any expression that evaluates to a number.
         *
         * Defaults to 0.
         *
         * Value range: 0-999
         *
         * Starting in MongoDB 4.0, if the number specified is outside this range, $dateFromParts incorporates the difference in the date calculation. See Value Range for examples.
         */
        millisecond?: NumberExpression;
        /**
         * The timezone to carry out the operation. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface DateFromString {
      /**
       * Converts a date/time string to a date object.
       *
       * @version 3.6
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateFromString/#mongodb-expression-exp.-dateFromString
       */
      $dateFromString: {
        dateString: StringExpression<string>;
        /**
         * The date format specification of the dateString. The format can be any expression that evaluates to a string literal, containing 0 or more format specifiers. For a list of specifiers available, see Format Specifiers.
         *
         * If unspecified, $dateFromString uses "%Y-%m-%dT%H:%M:%S.%LZ" as the default format.
         * @version 4.0
         */
        format?: FormatString;
        /**
         * The time zone to use to format the date.
         *
         * Note: If the dateString argument is formatted like '2017-02-08T12:10:40.787Z', in which the 'Z' at the end indicates Zulu time (UTC time zone), you cannot specify the timezone argument.
         */
        timezone?: tzExpression;
        /**
         * Optional. If $dateFromString encounters an error while parsing the given dateString, it outputs the result value of the provided onError expression. This result value can be of any type.
         *
         * If you do not specify onError, $dateFromString throws an error if it cannot parse dateString.
         */
        onError?: Expression;
        /**
         * Optional. If the dateString provided to $dateFromString is null or missing, it outputs the result value of the provided onNull expression. This result value can be of any type.
         *
         * If you do not specify onNull and dateString is null or missing, then $dateFromString outputs null.
         */
        onNull?: Expression;
      };
    }

    export interface DateSubtract {
      /**
       * Subtracts a number of time units from a date object.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateSubtract/#mongodb-expression-exp.-dateSubtract
       */
      $dateSubtract: {
        /**
         * The beginning date, in UTC, for the subtraction operation. The startDate can be any expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        startDate: DateExpression;
        /**
         * The unit of time, specified as an expression that must resolve to one of these strings:
         * - year
         * - quarter
         * - week
         * - month
         * - day
         * - hour
         * - minute
         * - second
         * - millisecond
         *
         * Together, binSize and unit specify the time period used in the $dateTrunc calculation.
         */
        unit: StringExpression<DateUnit>;
        /**
         * The number of units subtracted from the startDate. The amount is an expression that resolves to an integer or long. The amount can also resolve to an integral decimal and or a double if that value can be converted to a long without loss of precision.
         */
        amount: NumberExpression;
        /**
         * The timezone to carry out the operation. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface DateToParts {
      /**
       * Returns a document containing the constituent parts of a date.
       *
       * @version 3.6
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateToParts/#mongodb-expression-exp.-dateToParts
       */
      $dateToParts: {
        /**
         * The input date for which to return parts. <dateExpression> can be any expression that resolves to a Date, a Timestamp, or an ObjectID. For more information on expressions, see Expressions.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         *
         * @version 3.6
         */
        timezone?: tzExpression;
        /**
         * If set to true, modifies the output document to use ISO week date fields. Defaults to false.
         */
        iso8601?: boolean;
      };
    }

    export interface DateToString {
      /**
       * Returns the date as a formatted string.
       *
       * @version 3.6
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateToString/#mongodb-expression-exp.-dateToString
       */
      $dateToString: {
        /**
         * The date to convert to string. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The date format specification. <formatString> can be any string literal, containing 0 or more format specifiers. For a list of specifiers available, see Format Specifiers.
         *
         * If unspecified, $dateToString uses "%Y-%m-%dT%H:%M:%S.%LZ" as the default format.
         *
         * Changed in version 4.0: The format field is optional if featureCompatibilityVersion (fCV) is set to "4.0" or greater. For more information on fCV, see setFeatureCompatibilityVersion.
         */
        format?: FormatString;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         *
         * @version 3.6
         */
        timezone?: tzExpression;
        /**
         * The value to return if the date is null or missing. The arguments can be any valid expression.
         *
         * If unspecified, $dateToString returns null if the date is null or missing.
         *
         * Changed in version 4.0: Requires featureCompatibilityVersion (fCV) set to "4.0" or greater. For more information on fCV, see setFeatureCompatibilityVersion.
         */
        onNull?: Expression;
      };
    }

    export interface DateTrunc {
      /**
       * Truncates a date.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dateTrunc/#mongodb-expression-exp.-dateTrunc
       */
      $dateTrunc: {
        /**
         * The date to truncate, specified in UTC. The date can be any expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The unit of time, specified as an expression that must resolve to one of these strings:
         * - year
         * - quarter
         * - week
         * - month
         * - day
         * - hour
         * - minute
         * - second
         * - millisecond
         *
         * Together, binSize and unit specify the time period used in the $dateTrunc calculation.
         */
        unit: StringExpression<DateUnit>;
        /**
         * The numeric time value, specified as an expression that must resolve to a positive non-zero number. Defaults to 1.
         *
         * Together, binSize and unit specify the time period used in the $dateTrunc calculation.
         */
        binSize?: NumberExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
        /**
         * Used when the unit is equal to week. Defaults to Sunday. The startOfWeek parameter is an expression that resolves to a case insensitive string:
         * - monday (or mon)
         * - tuesday (or tue)
         * - wednesday (or wed)
         * - thursday (or thu)
         * - friday (or fri)
         * - saturday (or sat)
         * - sunday (or sun)
         */
        startOfWeek?: StringExpression<StartOfWeek>;
      }
    }

    export interface DayOfMonth {
      /**
       * Returns the day of the month for a date as a number between 1 and 31.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dayOfMonth/#mongodb-expression-exp.-dayOfMonth
       */
      $dayOfMonth: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface DayOfWeek {
      /**
       * Returns the day of the week for a date as a number between 1 (Sunday) and 7 (Saturday).
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dayOfWeek/#mongodb-expression-exp.-dayOfWeek
       */
      $dayOfWeek: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface DayOfYear {
      /**
       * Returns the day of the year for a date as a number between 1 and 366 (leap year).
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/dayOfYear/#mongodb-expression-exp.-dayOfYear
       */
      $dayOfYear: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface Hour {
      /**
       * Returns the hour for a date as a number between 0 and 23.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/hour/#mongodb-expression-exp.-hour
       */
      $hour: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface IsoDayOfWeek {
      /**
       * Returns the weekday number in ISO 8601 format, ranging from 1 (for Monday) to 7 (for Sunday).
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/isoDayOfWeek/#mongodb-expression-exp.-isoDayOfWeek
       */
      $isoDayOfWeek: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface IsoWeek {
      /**
       * Returns the week number in ISO 8601 format, ranging from 1 to 53. Week numbers start at 1 with the week (Monday through Sunday) that contains the year's first Thursday.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/isoWeek/#mongodb-expression-exp.-isoWeek
       */
      $isoWeek: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface IsoWeekYear {
      /**
       * Returns the year number in ISO 8601 format. The year starts with the Monday of week 1 (ISO 8601) and ends with the Sunday of the last week (ISO 8601).
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/isoWeekYear/#mongodb-expression-exp.-isoWeekYear
       */
      $isoWeekYear: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface Millisecond {
      /**
       * Returns the milliseconds of a date as a number between 0 and 999.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/millisecond/#mongodb-expression-exp.-millisecond
       */
      $millisecond: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface Minute {
      /**
       * Returns the minute for a date as a number between 0 and 59.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/minute/#mongodb-expression-exp.-minute
       */
      $minute: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface Month {
      /**
       * Returns the month for a date as a number between 1 (January) and 12 (December).
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/month/#mongodb-expression-exp.-month
       */
      $month: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface Second {
      /**
       * Returns the seconds for a date as a number between 0 and 60 (leap seconds).
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/second/#mongodb-expression-exp.-second
       */
      $second: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface ToDate {
      /**
       * Converts value to a Date.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toDate/#mongodb-expression-exp.-toDate
       */
      $toDate: Expression;
    }

    export interface Week {
      /**
       * Returns the week number for a date as a number between 0 (the partial week that precedes the first Sunday of the year) and 53 (leap year).
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/week/#mongodb-expression-exp.-week
       */
      $week: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface Year {
      /**
       * Returns the year for a date as a number (e.g. 2014).
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/year/#mongodb-expression-exp.-year
       */
      $year: DateExpression | {
        /**
         * The date to which the operator is applied. <dateExpression> must be a valid expression that resolves to a Date, a Timestamp, or an ObjectID.
         */
        date: DateExpression;
        /**
         * The timezone of the operation result. <tzExpression> must be a valid expression that resolves to a string formatted as either an Olson Timezone Identifier or a UTC Offset. If no timezone is provided, the result is displayed in UTC.
         */
        timezone?: tzExpression;
      };
    }

    export interface And {
      /**
       * Returns true only when all its expressions evaluate to true. Accepts any number of argument expressions.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/and/#mongodb-expression-exp.-and
       */
      $and: (Expression | Record<string, Expression>)[];
    }

    export interface Not {
      /**
       * Returns the boolean value that is the opposite of its argument expression. Accepts a single argument expression.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/not/#mongodb-expression-exp.-not
       */
      $not: [Expression];
    }

    export interface Or {
      /**
       * Returns true when any of its expressions evaluates to true. Accepts any number of argument expressions.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/or/#mongodb-expression-exp.-or
       */
      $or: (Expression | Record<string, Expression>)[];
    }

    export interface Cmp {
      /**
       * Returns 0 if the two values are equivalent, 1 if the first value is greater than the second, and -1 if the first value is less than the second.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/cmp/#mongodb-expression-exp.-cmp
       */
      $cmp: [Record<string, AnyExpression> | Expression, Record<string, AnyExpression> | Expression];
    }

    export interface Eq {
      /**
       * Returns true if the values are equivalent.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/eq/#mongodb-expression-exp.-eq
       */
      $eq: AnyExpression | [AnyExpression, AnyExpression];
    }

    export interface Gt {
      /**
       * Returns true if the first value is greater than the second.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/gt/#mongodb-expression-exp.-gt
       */
      $gt: NumberExpression | [NumberExpression, NumberExpression];
    }

    export interface Gte {
      /**
       * Returns true if the first value is greater than or equal to the second.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/gte/#mongodb-expression-exp.-gte
       */
      $gte: NumberExpression | [NumberExpression, NumberExpression];
    }

    export interface Lt {
      /**
       * Returns true if the first value is less than the second.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/lt/#mongodb-expression-exp.-lt
       */
      $lt: NumberExpression | [NumberExpression, NumberExpression];
    }

    export interface Lte {
      /**
       * Returns true if the first value is less than or equal to the second.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/lte/#mongodb-expression-exp.-lte
       */
      $lte: NumberExpression | [NumberExpression, NumberExpression];
    }

    export interface Ne {
      /**
       * Returns true if the values are not equivalent.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/ne/#mongodb-expression-exp.-ne
       */
      $ne: Expression | [Expression, Expression | NullExpression] | null;
    }

    export interface Cond {
      /**
       * A ternary operator that evaluates one expression, and depending on the result, returns the value of one of the other two expressions. Accepts either three expressions in an ordered list or three named parameters.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/cond/#mongodb-expression-exp.-cond
       */
      $cond: { if: Expression, then: AnyExpression, else: AnyExpression } | [BooleanExpression, AnyExpression, AnyExpression];
    }

    export interface IfNull {
      /**
       * Returns either the non-null result of the first expression or the result of the second expression if the first expression results in a null result. Null result encompasses instances of undefined values or missing fields. Accepts two expressions as arguments. The result of the second expression can be null.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/ifNull/#mongodb-expression-exp.-ifNull
       */
      $ifNull: Expression[];
    }

    export interface Switch {
      /**
       * Evaluates a series of case expressions. When it finds an expression which evaluates to true, $switch executes a specified expression and breaks out of the control flow.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/switch/#mongodb-expression-exp.-switch
       */
      $switch: {
        /**
         * An array of control branch documents. Each branch is a document with the following fields:
         * - $case
         * - $then
         */
        branches: { case: Expression, then: Expression }[];
        /**
         * The path to take if no branch case expression evaluates to true.
         *
         * Although optional, if default is unspecified and no branch case evaluates to true, $switch returns an error.
         */
        default: Expression;
      };
    }

    export interface ArrayElemAt {
      /**
       * Returns the element at the specified array index.
       *
       * @version 3.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/arrayElemAt/#mongodb-expression-exp.-arrayElemAt
       */
      $arrayElemAt: [ArrayExpression, NumberExpression];
    }

    export interface ArrayToObject {
      /**
       * Converts an array of key value pairs to a document.
       *
       * @version 3.4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/arrayToObject/#mongodb-expression-exp.-arrayToObject
       */
      $arrayToObject: ArrayExpression;
    }

    export interface ConcatArrays {
      /**
       * Concatenates arrays to return the concatenated array.
       *
       * @version 3.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/concatArrays/#mongodb-expression-exp.-concatArrays
       */
      $concatArrays: Expression[];
    }

    export interface Filter {
      /**
       * Selects a subset of the array to return an array with only the elements that match the filter condition.
       *
       * @version 3.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/filter/#mongodb-expression-exp.-filter
       */
      $filter: {
        /**
         * An expression that resolves to an array.
         */
        input: ArrayExpression;
        /**
         * A name for the variable that represents each individual element of the input array. If no name is specified, the variable name defaults to this.
         */
        as?: string;
        /**
         * An expression that resolves to a boolean value used to determine if an element should be included in the output array. The expression references each element of the input array individually with the variable name specified in as.
         */
        cond: BooleanExpression;
        /**
         * A number expression that restricts the number of matching array elements that $filter returns. You cannot specify a limit less than 1. The matching array elements are returned in the order they appear in the input array.
         *
         * If the specified limit is greater than the number of matching array elements, $filter returns all matching array elements.
         * If the limit is null, $filter returns all matching array elements.
         *
         * @version 5.2
         * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/filter/#using-the-limit-field
         */
        limit?: NumberExpression;
      }
    }

    export interface First {
      /**
       * Returns the first array element. Distinct from $first accumulator.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/first/#mongodb-expression-exp.-first
       */
      $first: Expression;
    }

    export interface In {
      /**
       * Returns a boolean indicating whether a specified value is in an array.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/in/#mongodb-expression-exp.-in
       */
      $in: [Expression, ArrayExpression];
    }

    export interface IndexOfArray {
      /**
       * Searches an array for an occurrence of a specified value and returns the array index of the first occurrence. If the substring is not found, returns -1.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/indexOfArray/#mongodb-expression-exp.-indexOfArray
       */
      $indexOfArray: [ArrayExpression, Expression] | [ArrayExpression, Expression, NumberExpression] | [ArrayExpression, Expression, NumberExpression, NumberExpression];
    }

    export interface IsArray {
      /**
       * Determines if the operand is an array. Returns a boolean.
       *
       * @version 3.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/isArray/#mongodb-expression-exp.-isArray
       */
      $isArray: [Expression];
    }

    export interface Last {
      /**
       * Returns the last array element. Distinct from $last accumulator.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/last/#mongodb-expression-exp.-last
       */
      $last: Expression;
    }

    export interface LinearFill {
      /**
       * Fills null and missing fields in a window using linear interpolation based on surrounding field values.
       *
       * @version 5.3
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/linearFill
       */
      $linearFill: Expression
    }

    export interface Locf {
      /**
       * Last observation carried forward. Sets values for null and missing fields in a window to the last non-null value for the field.
       *
       * @version 5.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/locf
       */
      $locf: Expression
    }

    export interface Map {
      /**
       * Applies a subexpression to each element of an array and returns the array of resulting values in order. Accepts named parameters.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/map/#mongodb-expression-exp.-map
       */
      $map: {
        /**
         * An expression that resolves to an array.
         */
        input: ArrayExpression;
        /**
         * A name for the variable that represents each individual element of the input array. If no name is specified, the variable name defaults to this.
         */
        as?: string;
        /**
         * An expression that is applied to each element of the input array. The expression references each element individually with the variable name specified in as.
         */
        in: Expression;
      };
    }

    export interface ObjectToArray {
      /**
       * Converts a document to an array of documents representing key-value pairs.
       *
       * @version 3.4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/objectToArray/#mongodb-expression-exp.-objectToArray
       */
      $objectToArray: ObjectExpression;
    }

    export interface Range {
      /**
       * Outputs an array containing a sequence of integers according to user-defined inputs.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/range/#mongodb-expression-exp.-range
       */
      $range: [NumberExpression, NumberExpression] | [NumberExpression, NumberExpression, NumberExpression];
    }

    export interface Reduce {
      /**
       * Applies an expression to each element in an array and combines them into a single value.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/reduce/#mongodb-expression-exp.-reduce
       */
      $reduce: {
        /**
         * Can be any valid expression that resolves to an array. For more information on expressions, see Expressions.
         *
         * If the argument resolves to a value of null or refers to a missing field, $reduce returns null.
         *
         * If the argument does not resolve to an array or null nor refers to a missing field, $reduce returns an error.
         */
        input: ArrayExpression;
        /**
         * The initial cumulative value set before in is applied to the first element of the input array.
         */
        initialValue: Expression;
        /**
         * A valid expression that $reduce applies to each element in the input array in left-to-right order. Wrap the input value with $reverseArray to yield the equivalent of applying the combining expression from right-to-left.
         *
         * During evaluation of the in expression, two variables will be available:
         * - `value` is the variable that represents the cumulative value of the expression.
         * - `this` is the variable that refers to the element being processed.
         */
        in: Expression;
      };
    }

    export interface ReverseArray {
      /**
       * Returns an array with the elements in reverse order.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/reverseArray/#mongodb-expression-exp.-reverseArray
       */
      $reverseArray: ArrayExpression;
    }

    export interface Size {
      /**
       * Returns the number of elements in the array. Accepts a single expression as argument.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/size/#mongodb-expression-exp.-size
       */
      $size: ArrayExpression;
    }

    export interface Slice {
      /**
       * Returns a subset of an array.
       *
       * @version 3.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/slice/#mongodb-expression-exp.-slice
       */
      $slice: [ArrayExpression, NumberExpression] | [ArrayExpression, NumberExpression, NumberExpression];
    }

    export interface Zip {
      /**
       * Merge two arrays together.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/zip/#mongodb-expression-exp.-zip
       */
      $zip: {
        /**
         * An array of expressions that resolve to arrays. The elements of these input arrays combine to form the arrays of the output array.
         *
         * If any of the inputs arrays resolves to a value of null or refers to a missing field, $zip returns null.
         *
         * If any of the inputs arrays does not resolve to an array or null nor refers to a missing field, $zip returns an error.
         */
        inputs: ArrayExpression[];
        /**
         * A boolean which specifies whether the length of the longest array determines the number of arrays in the output array.
         *
         * The default value is false: the shortest array length determines the number of arrays in the output array.
         */
        useLongestLength?: boolean;
        /**
         * An array of default element values to use if the input arrays have different lengths. You must specify useLongestLength: true along with this field, or else $zip will return an error.
         *
         * If useLongestLength: true but defaults is empty or not specified, $zip uses null as the default value.
         *
         * If specifying a non-empty defaults, you must specify a default for each input array or else $zip will return an error.
         */
        defaults?: ArrayExpression;
      };
    }

    export interface Concat {
      /**
       * Concatenates any number of strings.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/concat/#mongodb-expression-exp.-concat
       */
      $concat: StringExpression[];
    }

    export interface IndexOfBytes {
      /**
       * Searches a string for an occurrence of a substring and returns the UTF-8 byte index of the first occurrence. If the substring is not found, returns -1.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/indexOfBytes/#mongodb-expression-exp.-indexOfBytes
       */
      $indexOfBytes: [StringExpression, StringExpression] | [StringExpression, StringExpression, NumberExpression] | [StringExpression, StringExpression, NumberExpression, NumberExpression];
    }

    export interface IndexOfCP {
      /**
       * Searches a string for an occurrence of a substring and returns the UTF-8 code point index of the first occurrence. If the substring is not found, returns -1
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/indexOfCP/#mongodb-expression-exp.-indexOfCP
       */
      $indexOfCP: [StringExpression, StringExpression] | [StringExpression, StringExpression, NumberExpression] | [StringExpression, StringExpression, NumberExpression, NumberExpression];
    }

    export interface Ltrim {
      /**
       * Removes whitespace or the specified characters from the beginning of a string.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/ltrim/#mongodb-expression-exp.-ltrim
       */
      $ltrim: {
        /**
         * The string to trim. The argument can be any valid expression that resolves to a string. For more information on expressions, see Expressions.
         */
        input: StringExpression;
        /**
         * The character(s) to trim from the beginning of the input.
         *
         * The argument can be any valid expression that resolves to a string. The $ltrim operator breaks down the string into individual UTF code point to trim from input.
         *
         * If unspecified, $ltrim removes whitespace characters, including the null character. For the list of whitespace characters, see Whitespace Characters.
         */
        chars?: StringExpression;
      };
    }

    export interface RegexFind {
      /**
       * Applies a regular expression (regex) to a string and returns information on the first matched substring.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/regexFind/#mongodb-expression-exp.-regexFind
       */
      $regexFind: {
        /**
         * The string on which you wish to apply the regex pattern. Can be a string or any valid expression that resolves to a string.
         */
        input: Expression; // TODO: Resolving to string, which ones?
        /**
         * The regex pattern to apply. Can be any valid expression that resolves to either a string or regex pattern /<pattern>/. When using the regex /<pattern>/, you can also specify the regex options i and m (but not the s or x options):
         * - "pattern"
         * - /pattern/
         * - /pattern/options
         *
         * Alternatively, you can also specify the regex options with the options field. To specify the s or x options, you must use the options field.
         *
         * You cannot specify options in both the regex and the options field.
         */
        regex: RegExp | string;
        /**
         * The following <options> are available for use with regular expression.
         *
         * Note: You cannot specify options in both the regex and the options field.
         *
         * Option   Description
         *
         * `i`      Case insensitivity to match both upper and lower cases. You can specify the option in the options field or as part of the regex field.
         *
         * `m`      For patterns that include anchors (i.e. ^ for the start, $ for the end), match at the beginning or end of each line for strings with multiline values. Without this option, these anchors match at beginning or end of the string.
         *          If the pattern contains no anchors or if the string value has no newline characters (e.g. \n), the m option has no effect.
         *
         * `x`      "Extended" capability to ignore all white space characters in the pattern unless escaped or included in a character class.
         *          Additionally, it ignores characters in-between and including an un-escaped hash/pound (#) character and the next new line, so that you may include comments in complicated patterns. This only applies to data characters; white space characters may never appear within special character sequences in a pattern.
         *          The x option does not affect the handling of the VT character (i.e. code 11).
         *          You can specify the option only in the options field.
         *
         * `s`      Allows the dot character (i.e. .) to match all characters including newline characters.
         *          You can specify the option only in the options field.
         */
        options?: RegexOptions;
      };
    }

    export interface RegexFindAll {
      /**
       * Applies a regular expression (regex) to a string and returns information on the all matched substrings.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/regexFindAll/#mongodb-expression-exp.-regexFindAll
       */
      $regexFindAll: {
        /**
         * The string on which you wish to apply the regex pattern. Can be a string or any valid expression that resolves to a string.
         */
        input: Expression; // TODO: Resolving to string, which ones?
        /**
         * The regex pattern to apply. Can be any valid expression that resolves to either a string or regex pattern /<pattern>/. When using the regex /<pattern>/, you can also specify the regex options i and m (but not the s or x options):
         * - "pattern"
         * - /pattern/
         * - /pattern/options
         *
         * Alternatively, you can also specify the regex options with the options field. To specify the s or x options, you must use the options field.
         *
         * You cannot specify options in both the regex and the options field.
         */
        regex: RegExp | string;
        /**
         * The following <options> are available for use with regular expression.
         *
         * Note: You cannot specify options in both the regex and the options field.
         *
         * Option   Description
         *
         * `i`      Case insensitivity to match both upper and lower cases. You can specify the option in the options field or as part of the regex field.
         *
         * `m`      For patterns that include anchors (i.e. ^ for the start, $ for the end), match at the beginning or end of each line for strings with multiline values. Without this option, these anchors match at beginning or end of the string.
         *          If the pattern contains no anchors or if the string value has no newline characters (e.g. \n), the m option has no effect.
         *
         * `x`      "Extended" capability to ignore all white space characters in the pattern unless escaped or included in a character class.
         *          Additionally, it ignores characters in-between and including an un-escaped hash/pound (#) character and the next new line, so that you may include comments in complicated patterns. This only applies to data characters; white space characters may never appear within special character sequences in a pattern.
         *          The x option does not affect the handling of the VT character (i.e. code 11).
         *          You can specify the option only in the options field.
         *
         * `s`      Allows the dot character (i.e. .) to match all characters including newline characters.
         *          You can specify the option only in the options field.
         */
        options?: RegexOptions;
      };
    }

    export interface RegexMatch {
      /**
       * Applies a regular expression (regex) to a string and returns a boolean that indicates if a match is found or not.
       *
       * @version 4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/regexMatch/#mongodb-expression-exp.-regexMatch
       */
      $regexMatch: {
        /**
         * The string on which you wish to apply the regex pattern. Can be a string or any valid expression that resolves to a string.
         */
        input: Expression; // TODO: Resolving to string, which ones?
        /**
         * The regex pattern to apply. Can be any valid expression that resolves to either a string or regex pattern /<pattern>/. When using the regex /<pattern>/, you can also specify the regex options i and m (but not the s or x options):
         * - "pattern"
         * - /pattern/
         * - /pattern/options
         *
         * Alternatively, you can also specify the regex options with the options field. To specify the s or x options, you must use the options field.
         *
         * You cannot specify options in both the regex and the options field.
         */
        regex: RegExp | string;
        /**
         * The following <options> are available for use with regular expression.
         *
         * Note: You cannot specify options in both the regex and the options field.
         *
         * Option   Description
         *
         * `i`      Case insensitivity to match both upper and lower cases. You can specify the option in the options field or as part of the regex field.
         *
         * `m`      For patterns that include anchors (i.e. ^ for the start, $ for the end), match at the beginning or end of each line for strings with multiline values. Without this option, these anchors match at beginning or end of the string.
         *          If the pattern contains no anchors or if the string value has no newline characters (e.g. \n), the m option has no effect.
         *
         * `x`      "Extended" capability to ignore all white space characters in the pattern unless escaped or included in a character class.
         *          Additionally, it ignores characters in-between and including an un-escaped hash/pound (#) character and the next new line, so that you may include comments in complicated patterns. This only applies to data characters; white space characters may never appear within special character sequences in a pattern.
         *          The x option does not affect the handling of the VT character (i.e. code 11).
         *          You can specify the option only in the options field.
         *
         * `s`      Allows the dot character (i.e. .) to match all characters including newline characters.
         *          You can specify the option only in the options field.
         */
        options?: RegexOptions;
      };
    }

    export interface ReplaceOne {
      /**
       * Replaces the first instance of a matched string in a given input.
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/replaceOne/#mongodb-expression-exp.-replaceOne
       */
      $replaceOne: {
        /**
         * The string on which you wish to apply the find. Can be any valid expression that resolves to a string or a null. If input refers to a field that is missing, $replaceOne returns null.
         */
        input: StringExpression;
        /**
         * The string to search for within the given input. Can be any valid expression that resolves to a string or a null. If find refers to a field that is missing, $replaceOne returns null.
         */
        find: StringExpression;
        /**
         * The string to use to replace the first matched instance of find in input. Can be any valid expression that resolves to a string or a null.
         */
        replacement: StringExpression;
      };
    }

    export interface ReplaceAll {
      /**
       * Replaces all instances of a matched string in a given input.
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/replaceAll/#mongodb-expression-exp.-replaceAll
       */
      $replaceAll: {
        /**
         * The string on which you wish to apply the find. Can be any valid expression that resolves to a string or a null. If input refers to a field that is missing, $replaceAll returns null.
         */
        input: StringExpression;
        /**
         * The string to search for within the given input. Can be any valid expression that resolves to a string or a null. If find refers to a field that is missing, $replaceAll returns null.
         */
        find: StringExpression;
        /**
         * The string to use to replace all matched instances of find in input. Can be any valid expression that resolves to a string or a null.
         */
        replacement: StringExpression;
      };
    }

    export interface Rtrim {
      /**
       * Removes whitespace or the specified characters from the end of a string.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/rtrim/#mongodb-expression-exp.-rtrim
       */
      $rtrim: {
        /**
         * The string to trim. The argument can be any valid expression that resolves to a string. For more information on expressions, see Expressions.
         */
        input: StringExpression;
        /**
         * The character(s) to trim from the beginning of the input.
         *
         * The argument can be any valid expression that resolves to a string. The $rtrim operator breaks down the string into individual UTF code point to trim from input.
         *
         * If unspecified, $rtrim removes whitespace characters, including the null character. For the list of whitespace characters, see Whitespace Characters.
         */
        chars?: StringExpression;
      };
    }

    export interface Split {
      /**
       * Splits a string into substrings based on a delimiter. Returns an array of substrings. If the delimiter is not found within the string, returns an array containing the original string.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/split/#mongodb-expression-exp.-split
       */
      $split: [StringExpression, StringExpression];
    }

    export interface StrLenBytes {
      /**
       * Returns the number of UTF-8 encoded bytes in a string.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/strLenBytes/#mongodb-expression-exp.-strLenBytes
       */
      $strLenBytes: StringExpression;
    }

    export interface StrLenCP {
      /**
       * Returns the number of UTF-8 code points in a string.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/strLenCP/#mongodb-expression-exp.-strLenCP
       */
      $strLenCP: StringExpression;
    }

    export interface Strcasecmp {
      /**
       * Performs case-insensitive string comparison and returns: 0 if two strings are equivalent, 1 if the first string is greater than the second, and -1 if the first string is less than the second.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/strcasecmp/#mongodb-expression-exp.-strcasecmp
       */
      $strcasecmp: [StringExpression, StringExpression];
    }

    export interface Substr {
      /**
       * Deprecated. Use $substrBytes or $substrCP.
       *
       * @deprecated 3.4
       * @alias {Expression.SubstrBytes}
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/substr/#mongodb-expression-exp.-substr
       */
      $substr: [StringExpression, number, number];
    }

    export interface SubstrBytes {
      /**
       * Returns the substring of a string. Starts with the character at the specified UTF-8 byte index (zero-based) in the string and continues for the specified number of bytes.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/substrBytes/#mongodb-expression-exp.-substrBytes
       */
      $substrBytes: [StringExpression, number, number];
    }

    export interface SubstrCP {
      /**
       * Returns the substring of a string. Starts with the character at the specified UTF-8 code point (CP) index (zero-based) in the string and continues for the number of code points specified.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/substrCP/#mongodb-expression-exp.-substrCP
       */
      $substrCP: [StringExpression, number, number];
    }

    export interface ToLower {
      /**
       * Converts a string to lowercase. Accepts a single argument expression.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toLower/#mongodb-expression-exp.-toLower
       */
      $toLower: StringExpression;
    }

    export interface ToString {
      /**
       * Converts value to a string.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toString/#mongodb-expression-exp.-toString
       */
      $toString: Expression;
    }

    export interface Trim {
      /**
       * Removes whitespace or the specified characters from the beginning and end of a string.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/trim/#mongodb-expression-exp.-trim
       */
      $trim: {
        /**
         * The string to trim. The argument can be any valid expression that resolves to a string. For more information on expressions, see Expressions.
         */
        input: StringExpression;
        /**
         * The character(s) to trim from the beginning of the input.
         *
         * The argument can be any valid expression that resolves to a string. The $trim operator breaks down the string into individual UTF code point to trim from input.
         *
         * If unspecified, $trim removes whitespace characters, including the null character. For the list of whitespace characters, see Whitespace Characters.
         */
        chars?: StringExpression;
      };
    }

    export interface ToUpper {
      /**
       * Converts a string to uppercase. Accepts a single argument expression.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toUpper/#mongodb-expression-exp.-toUpper
       */
      $toUpper: StringExpression;
    }

    export interface Literal {

      /**
       * Returns a value without parsing. Use for values that the aggregation pipeline may interpret as an
       * expression.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/literal/#mongodb-expression-exp.-literal
       */
      $literal: any;
    }

    export interface GetField {

      /**
       * Returns the value of a specified field from a document. If you don't specify an object, $getField returns
       * the value of the field from $$CURRENT.
       *
       * @version 4.4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/getField/#mongodb-expression-exp.-getField
       */
      $getField: {
        /**
         * Field in the input object for which you want to return a value. field can be any valid expression that
         * resolves to a string constant.
         */
        field: StringExpression;
        /**
         * A valid expression that contains the field for which you want to return a value. input must resolve to an
         * object, missing, null, or undefined. If omitted, defaults to the document currently being processed in the
         * pipeline ($$CURRENT).
         */
        input?: ObjectExpression | SpecialPathVariables | NullExpression;
      }
    }

    export interface Rand {

      /**
       * Returns a random float between 0 and 1 each time it is called.
       *
       * @version 4.4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/rand/#mongodb-expression-exp.-rand
       */
      $rand: Record<string | number | symbol, never>;
    }

    export interface SampleRate {

      /**
       * Matches a random selection of input documents. The number of documents selected approximates the sample
       * rate expressed as a percentage of the total number of documents.
       *
       * @version 4.4.2
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/sampleRate/#mongodb-expression-exp.-sampleRate
       */
      $sampleRate: number;
    }

    export interface MergeObjects {

      /**
       * Combines multiple documents into a single document.
       *
       * @version 3.6
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/mergeObjects/#mongodb-expression-exp.-mergeObjects
       */
      $mergeObjects: ObjectExpression | ObjectExpression[] | ArrayExpression | Record<string, string>;
    }

    export interface SetField {

      /**
       * Adds, updates, or removes a specified field in a document.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/setField/#mongodb-expression-exp.-setField
       */
      $setField: {
        /**
         * Field in the input object that you want to add, update, or remove. field can be any valid expression that
         * resolves to a string constant.
         */
        field: StringExpression;
        /**
         * Document that contains the field that you want to add or update. input must resolve to an object, missing,
         * null, or undefined
         */
        input?: ObjectExpression | NullExpression;
        /**
         * The value that you want to assign to field. value can be any valid expression.
         */
        value?: Expression | SpecialPathVariables;
      }
    }

    export interface UnsetField {

      /**
       * Removes a specified field in a document.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/unsetField/#mongodb-expression-exp.-unsetField
       */
      $unsetField: {
        /**
         * Field in the input object that you want to add, update, or remove. field can be any valid expression that
         * resolves to a string constant.
         */
        field: StringExpression;
        /**
         * Document that contains the field that you want to add or update. input must resolve to an object, missing,
         * null, or undefined.
         */
        input?: ObjectExpression | SpecialPathVariables | NullExpression;
      }
    }

    export interface Let {

      /**
       * Binds variables for use in the specified expression, and returns the result of the expression.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/let/#mongodb-expression-exp.-let
       */
      $let: {
        /**
         * Assignment block for the variables accessible in the in expression. To assign a variable, specify a
         * string for the variable name and assign a valid expression for the value.
         */
        vars: { [key: string]: Expression; };
        /**
         * The expression to evaluate.
         */
        in: Expression;
      }
    }

    export interface AllElementsTrue {
      /**
       * Evaluates an array as a set and returns true if no element in the array is false. Otherwise, returns false. An
       * empty array returns true.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/allElementsTrue/#mongodb-expression-exp.-allElementsTrue
       */
      $allElementsTrue: ArrayExpression;
    }

    export interface AnyElementsTrue {
      /**
       * Evaluates an array as a set and returns true if any of the elements are true and false otherwise. An empty
       * array returns false.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/anyElementsTrue/#mongodb-expression-exp.-anyElementsTrue
       */
      $anyElementTrue: ArrayExpression;
    }

    export interface SetDifference {
      /**
       * Takes two sets and returns an array containing the elements that only exist in the first set; i.e. performs a
       * relative complement of the second set relative to the first.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/setDifference/#mongodb-expression-exp.-setDifference
       */
      $setDifference: [ArrayExpression, ArrayExpression];
    }

    export interface SetEquals {
      /**
       * Compares two or more arrays and returns true if they have the same distinct elements and false otherwise.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/setEquals/#mongodb-expression-exp.-setEquals
       */
      $setEquals: ArrayExpression[];
    }

    export interface SetIntersection {
      /**
       * Takes two or more arrays and returns an array that contains the elements that appear in every input array.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/setIntersection/#mongodb-expression-exp.-setIntersection
       */
      $setIntersection: ArrayExpression[];
    }

    export interface SetIsSubset {
      /**
       * Takes two arrays and returns true when the first array is a subset of the second, including when the first
       * array equals the second array, and false otherwise.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/setIsSubset/#mongodb-expression-exp.-setIsSubset
       */
      $setIsSubset: [ArrayExpression, ArrayExpression];
    }

    export interface SetUnion {
      /**
       * Takes two or more arrays and returns an array containing the elements that appear in any input array.
       *
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/setUnion/#mongodb-expression-exp.-setUnion
       */
      $setUnion: ArrayExpression[];
    }

    export interface Accumulator {
      /**
       * Defines a custom accumulator operator. Accumulators are operators that maintain their state (e.g. totals,
       * maximums, minimums, and related data) as documents progress through the pipeline. Use the $accumulator operator
       * to execute your own JavaScript functions to implement behavior not supported by the MongoDB Query Language. See
       * also $function.
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/accumulator/#mongodb-expression-exp.-accumulator
       */
      $accumulator: {
        /**
         * Function used to initialize the state. The init function receives its arguments from the initArgs array
         * expression. You can specify the function definition as either BSON type Code or String.
         */
        init: CodeExpression;
        /**
         * Arguments passed to the init function.
         */
        initArgs?: ArrayExpression;
        /**
         * Function used to accumulate documents. The accumulate function receives its arguments from the current state
         * and accumulateArgs array expression. The result of the accumulate function becomes the new state. You can
         * specify the function definition as either BSON type Code or String.
         */
        accumulate: CodeExpression;
        /**
         * Arguments passed to the accumulate function. You can use accumulateArgs to specify what field value(s) to
         * pass to the accumulate function.
         */
        accumulateArgs: ArrayExpression;
        /**
         * Function used to merge two internal states. merge must be either a String or Code BSON type. merge returns
         * the combined result of the two merged states. For information on when the merge function is called, see Merge
         * Two States with $merge.
         */
        merge: CodeExpression;
        /**
         * Function used to update the result of the accumulation.
         */
        finalize?: CodeExpression;
        /**
         * The language used in the $accumulator code.
         */
        lang: 'js';
      }
    }

    export interface AddToSet {
      /**
       * Returns an array of all unique values that results from applying an expression to each document in a group.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/addToSet/#mongodb-expression-exp.-addToSet
       */
      $addToSet: Expression | Record<string, Expression>;
    }

    export interface Avg {
      /**
       * Returns the average value of the numeric values. $avg ignores non-numeric values.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/avg/#mongodb-expression-exp.-avg
       */
      $avg: Expression;
    }

    export interface Count {
      /**
       * Returns the number of documents in a group.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/count/#mongodb-expression-exp.-count
       */
      $count: Record<string | number | symbol, never> | Path;
    }

    export interface CovariancePop {
      /**
       * Returns the population covariance of two numeric expressions that are evaluated using documents in the
       * $setWindowFields stage window.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/covariancePop/#mongodb-expression-exp.-covariancePop
       */
      $covariancePop: [NumberExpression, NumberExpression];
    }

    export interface CovarianceSamp {
      /**
       * Returns the sample covariance of two numeric expressions that are evaluated using documents in the
       * $setWindowFields stage window.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/covarianceSamp/#mongodb-expression-exp.-covarianceSamp
       */
      $covarianceSamp: [NumberExpression, NumberExpression];
    }

    export interface DenseRank {
      /**
       * Returns the document position (known as the rank) relative to other documents in the $setWindowFields stage
       * partition.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/denseRank/#mongodb-expression-exp.-denseRank
       */
      $denseRank: Record<string | number | symbol, never>;
    }

    export interface Derivative {
      /**
       * Returns the average rate of change within the specified window, which is calculated using the:
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/derivative/#mongodb-expression-exp.-derivative
       */
      $derivative: {
        /**
         * Specifies the expression to evaluate. The expression must evaluate to a number.
         */
        input: NumberExpression;
        /**
         * A string that specifies the time unit.
         */
        unit?: DateUnit;
      }
    }

    export interface DocumentNumber {
      /**
       * Returns the position of a document (known as the document number) in the $setWindowFields stage partition.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/documentNumber/#mongodb-expression-exp.-documentNumber
       */
      $documentNumber: Record<string | number | symbol, never>;
    }

    export interface ExpMovingAvg {
      /**
       * Returns the exponential moving average of numeric expressions applied to documents in a partition defined in
       * the $setWindowFields stage.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/expMovingAvg/#mongodb-expression-exp.-expMovingAvg
       */
      $expMovingAvg: {
        /**
         * Specifies the expression to evaluate. Non-numeric expressions are ignored.
         */
        input: Expression;

        /**
         * An integer that specifies the number of historical documents that have a significant mathematical weight in
         * the exponential moving average calculation, with the most recent documents contributing the most weight.
         *
         * You must specify either N or alpha. You cannot specify both.
         */
        N: NumberExpression;

        /**
         * A double that specifies the exponential decay value to use in the exponential moving average calculation. A
         * higher alpha value assigns a lower mathematical significance to previous results from the calculation.
         *
         * You must specify either N or alpha. You cannot specify both.
         */
        alpha?: never;
      } |
      {
        /**
         * Specifies the expression to evaluate. Non-numeric expressions are ignored.
         */
        input: Expression;

        /**
         * An integer that specifies the number of historical documents that have a significant mathematical weight in
         * the exponential moving average calculation, with the most recent documents contributing the most weight.
         *
         * You must specify either N or alpha. You cannot specify both.
         */
        N?: never;

        /**
         * A double that specifies the exponential decay value to use in the exponential moving average calculation. A
         * higher alpha value assigns a lower mathematical significance to previous results from the calculation.
         *
         * You must specify either N or alpha. You cannot specify both.
         */
        alpha: NumberExpression;
      }
    }

    export interface Integral {
      /**
       * Returns the approximation of the area under a curve, which is calculated using the trapezoidal rule where each
       * set of adjacent documents form a trapezoid using the:
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/integral/#mongodb-expression-exp.-integral
       */
      $integral: {
        /**
         * Specifies the expression to evaluate. You must provide an expression that returns a number.
         */
        input: NumberExpression;

        /**
         * A string that specifies the time unit.
         */
        unit?: DateUnit;
      }
    }

    export interface Max {
      /**
       * Returns the maximum value. $max compares both value and type, using the specified BSON comparison order for
       * values of different types.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/max/#mongodb-expression-exp.-max
       */
      $max: Expression | Expression[];
    }

    export interface Min {
      /**
       * Returns the minimum value. $min compares both value and type, using the specified BSON comparison order for
       * values of different types.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/min/#mongodb-expression-exp.-min
       */
      $min: Expression | Expression[];
    }

    export interface Push {
      /**
       * Returns an array of all values that result from applying an expression to documents.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/push/#mongodb-expression-exp.-push
       */
      $push: Expression | Record<string, Expression>;
    }

    export interface Rank {
      /**
       * Returns the document position (known as the rank) relative to other documents in the $setWindowFields stage
       * partition.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/rank/#mongodb-expression-exp.-rank
       */
      $rank: Record<string | number | symbol, never>;
    }

    export interface Shift {
      /**
       * Returns the value from an expression applied to a document in a specified position relative to the current
       * document in the $setWindowFields stage partition.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/shift/#mongodb-expression-exp.-shift
       */
      $shift: {
        /**
         * Specifies an expression to evaluate and return in the output.
         */
        output: Expression;
        /**
         * Specifies an integer with a numeric document position relative to the current document in the output.
         */
        by: number;
        /**
         * Specifies an optional default expression to evaluate if the document position is outside of the implicit
         * $setWindowFields stage window. The implicit window contains all the documents in the partition.
         */
        default?: Expression;
      }
    }

    export interface StdDevPop {
      /**
       * Calculates the population standard deviation of the input values. Use if the values encompass the entire
       * population of data you want to represent and do not wish to generalize about a larger population. $stdDevPop
       * ignores non-numeric values.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/stdDevPop/#mongodb-expression-exp.-stdDevPop
       */
      $stdDevPop: Expression;
    }

    export interface StdDevSamp {
      /**
       * Calculates the sample standard deviation of the input values. Use if the values encompass a sample of a
       * population of data from which to generalize about the population. $stdDevSamp ignores non-numeric values.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/stdDevSamp/#mongodb-expression-exp.-stdDevSamp
       */
      $stdDevSamp: Expression;
    }

    export interface Sum {
      /**
       * Calculates and returns the collective sum of numeric values. $sum ignores non-numeric values.
       *
       * @version 5.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/sum/#mongodb-expression-exp.-sum
       */
      $sum: number | Expression | Expression[];
    }

    export interface Convert<K extends 'double' | 1 | 'string' | 2 | 'objectId' | 7 | 'bool' | 8 | 'date' | 9 | 'int' | 16 | 'long' | 18 | 'decimal' | 19 = 'double' | 1 | 'string' | 2 | 'objectId' | 7 | 'bool' | 8 | 'date' | 9 | 'int' | 16 | 'long' | 18 | 'decimal' | 19> {
      /**
       * Checks if the specified expression resolves to one of the following numeric
       * - Integer
       * - Decimal
       * - Double
       * - Long
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/convert/#mongodb-expression-exp.-convert
       */
      $convert: {
        input: Expression;
        to: K;
        onError?: Expression;
        onNull?: Expression;
      };
    }

    export interface IsNumber {
      /**
       * Checks if the specified expression resolves to one of the following numeric
       * - Integer
       * - Decimal
       * - Double
       * - Long
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/isNumber/#mongodb-expression-exp.-isNumber
       */
      $isNumber: Expression;
    }

    export interface ToBool {
      /**
       * Converts a value to a boolean.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toBool/#mongodb-expression-exp.-toBool
       */
      $toBool: Expression;
    }

    export interface ToDecimal {
      /**
       * Converts a value to a decimal. If the value cannot be converted to a decimal, $toDecimal errors. If the value
       * is null or missing, $toDecimal returns null.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toDecimal/#mongodb-expression-exp.-toDecimal
       */
      $toDecimal: Expression;
    }

    export interface ToDouble {
      /**
       * Converts a value to a double. If the value cannot be converted to an double, $toDouble errors. If the value is
       * null or missing, $toDouble returns null.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toDouble/#mongodb-expression-exp.-toDouble
       */
      $toDouble: Expression;
    }

    export interface ToInt {
      /**
       * Converts a value to a long. If the value cannot be converted to a long, $toLong errors. If the value is null or
       * missing, $toLong returns null.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toInt/#mongodb-expression-exp.-toInt
       */
      $toInt: Expression;
    }

    export interface ToLong {
      /**
       * Converts a value to a long. If the value cannot be converted to a long, $toLong errors. If the value is null or
       * missing, $toLong returns null.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toLong/#mongodb-expression-exp.-toLong
       */
      $toLong: Expression;
    }

    export interface ToObjectId {
      /**
       * Converts a value to an ObjectId(). If the value cannot be converted to an ObjectId, $toObjectId errors. If the
       * value is null or missing, $toObjectId returns null.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toObjectId/#mongodb-expression-exp.-toObjectId
       */
      $toObjectId: Expression;
    }

    export interface Top {
      $top: {
        sortBy: AnyObject,
        output: Expression
      };
    }

    export interface TopN {
      $topN: {
        n: Expression,
        sortBy: AnyObject,
        output: Expression
      };
    }

    export interface ToString {
      /**
       * Converts a value to a string. If the value cannot be converted to a string, $toString errors. If the value is
       * null or missing, $toString returns null.
       *
       * @version 4.0
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/toString/#mongodb-expression-exp.-toString
       */
      $toString: Expression;
    }

    export interface Type {
      /**
       * Returns a string that specifies the BSON type of the argument.
       *
       * @version 3.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/type/#mongodb-expression-exp.-type
       */
      $type: Expression;
    }

    export interface BinarySize {
      /**
       * Returns the size of a given string or binary data value's content in bytes.
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/binarySize/#mongodb-expression-exp.-binarySize
       */
      $binarySize: NullExpression | StringExpression | BinaryExpression;
    }

    export interface BsonSize {
      /**
       * Returns the size in bytes of a given document (i.e. bsontype Object) when encoded as BSON. You can use
       * $bsonSize as an alternative to the Object.bsonSize() method.
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/bsonSize/#mongodb-expression-exp.-bsonSize
       */
      $bsonSize: NullExpression | ObjectExpression;
    }

    export interface Function {
      /**
       * Defines a custom aggregation function or expression in JavaScript.
       *
       * @version 4.4
       * @see https://www.mongodb.com/docs/manual/reference/operator/aggregation/function/#mongodb-expression-exp.-function
       */
      $function: {
        /**
         * 	The function definition. You can specify the function definition as either BSON type Code or String.
         */
        body: CodeExpression;
        /**
         * Arguments passed to the function body. If the body function does not take an argument, you can specify an
         * empty array [ ]
         */
        args: ArrayExpression;
        /**
         * The language used in the body. You must specify lang: "js".
         */
        lang: 'js'
      };
    }
  }

  type Path = string;


  export type Expression =
    Path |
    ArithmeticExpressionOperator |
    ArrayExpressionOperator |
    BooleanExpressionOperator |
    ComparisonExpressionOperator |
    ConditionalExpressionOperator |
    CustomAggregationExpressionOperator |
    DataSizeOperator |
    DateExpressionOperator |
    LiteralExpressionOperator |
    MiscellaneousExpressionOperator |
    ObjectExpressionOperator |
    SetExpressionOperator |
    StringExpressionOperator |
    TextExpressionOperator |
    TrigonometryExpressionOperator |
    TypeExpressionOperator |
    AccumulatorOperator |
    VariableExpressionOperator |
    WindowOperator |
    Expression.Top |
    Expression.TopN |
    any;

  export type NullExpression = null;

  export type CodeExpression =
    string |
    Function;

  export type BinaryExpression =
    Path;

  export type FunctionExpression =
    Expression.Function;

  export type AnyExpression =
    ArrayExpression |
    BooleanExpression |
    NumberExpression |
    ObjectExpression |
    StringExpression |
    DateExpression |
    BinaryExpression |
    FunctionExpression |
    ObjectIdExpression |
    ConditionalExpressionOperator |
    any;

  export type ObjectIdExpression =
    TypeExpressionOperatorReturningObjectId;

  export type ArrayExpression<T = any> =
    T[] |
    Path |
    ArrayExpressionOperatorReturningAny |
    ArrayExpressionOperatorReturningArray |
    StringExpressionOperatorReturningArray |
    ObjectExpressionOperatorReturningArray |
    SetExpressionOperatorReturningArray |
    LiteralExpressionOperatorReturningAny |
    WindowOperatorReturningArray |
    CustomAggregationExpressionOperatorReturningAny |
    WindowOperatorReturningAny;

  export type BooleanExpression =
    boolean |
    Path |
    BooleanExpressionOperator |
    ArrayExpressionOperatorReturningAny |
    ComparisonExpressionOperatorReturningBoolean |
    StringExpressionOperatorReturningBoolean |
    SetExpressionOperatorReturningBoolean |
    LiteralExpressionOperatorReturningAny |
    CustomAggregationExpressionOperatorReturningAny |
    TypeExpressionOperatorReturningBoolean;

  export type NumberExpression =
    number |
    Path |
    ArrayExpressionOperatorReturningAny |
    ArrayExpressionOperatorReturningNumber |
    ArithmeticExpressionOperator |
    ComparisonExpressionOperatorReturningNumber |
    TrigonometryExpressionOperator |
    MiscellaneousExpressionOperatorReturningNumber |
    StringExpressionOperatorReturningNumber |
    LiteralExpressionOperatorReturningAny |
    ObjectExpressionOperator |
    SetExpressionOperator |
    WindowOperatorReturningNumber |
    WindowOperatorReturningAny |
    DataSizeOperatorReturningNumber |
    CustomAggregationExpressionOperatorReturningAny |
    TypeExpressionOperatorReturningNumber |
    DateExpression |
    DateExpressionOperatorReturningNumber;

  export type ObjectExpression =
    Path |
    ArrayExpressionOperatorReturningAny |
    DateExpressionOperatorReturningObject |
    StringExpressionOperatorReturningObject |
    ObjectExpressionOperatorReturningObject |
    CustomAggregationExpressionOperatorReturningAny |
    LiteralExpressionOperatorReturningAny;

  export type StringExpression<T = string> =
    Path |
    ArrayExpressionOperatorReturningAny |
    DateExpressionOperatorReturningString |
    StringExpressionOperatorReturningString |
    LiteralExpressionReturningAny |
    CustomAggregationExpressionOperatorReturningAny |
    TypeExpressionOperatorReturningString |
    T;

  export type DateExpression =
    Path |
    NativeDate |
    DateExpressionOperatorReturningDate |
    TypeExpressionOperatorReturningDate |
    LiteralExpressionReturningAny;

  export type ArithmeticExpressionOperator =
    Expression.Abs |
    Expression.Add |
    Expression.Ceil |
    Expression.Divide |
    Expression.Exp |
    Expression.Floor |
    Expression.Ln |
    Expression.Log |
    Expression.Log10 |
    Expression.Mod |
    Expression.Multiply |
    Expression.Pow |
    Expression.Round |
    Expression.Sqrt |
    Expression.Subtract |
    Expression.Trunc;

  export type ArrayExpressionOperator =
    ArrayExpressionOperatorReturningAny |
    ArrayExpressionOperatorReturningBoolean |
    ArrayExpressionOperatorReturningNumber |
    ArrayExpressionOperatorReturningObject;

  export type LiteralExpressionOperator =
    Expression.Literal;

  export type LiteralExpressionReturningAny =
    LiteralExpressionOperatorReturningAny;

  export type LiteralExpressionOperatorReturningAny =
    Expression.Literal;

  export type MiscellaneousExpressionOperator =
    Expression.Rand |
    Expression.SampleRate;

  export type MiscellaneousExpressionOperatorReturningNumber =
    Expression.Rand;

  export type ArrayExpressionOperatorReturningAny =
    Expression.ArrayElemAt |
    Expression.First |
    Expression.Last |
    Expression.Reduce;

  export type ArrayExpressionOperatorReturningArray =
    Expression.ConcatArrays |
    Expression.Filter |
    Expression.Map |
    Expression.ObjectToArray |
    Expression.Range |
    Expression.ReverseArray |
    Expression.Slice |
    Expression.Zip;

  export type ArrayExpressionOperatorReturningNumber =
    Expression.IndexOfArray |
    Expression.Size;

  export type ArrayExpressionOperatorReturningObject =
    Expression.ArrayToObject;

  export type ArrayExpressionOperatorReturningBoolean =
    Expression.In |
    Expression.IsArray;

  export type BooleanExpressionOperator =
    Expression.And |
    Expression.Or |
    Expression.Not;

  export type ComparisonExpressionOperator =
    ComparisonExpressionOperatorReturningBoolean |
    ComparisonExpressionOperatorReturningNumber;

  export type ComparisonExpressionOperatorReturningBoolean =
    Expression.Eq |
    Expression.Gt |
    Expression.Gte |
    Expression.Lt |
    Expression.Lte |
    Expression.Ne;

  export type ComparisonExpressionOperatorReturningNumber =
    Expression.Cmp;

  export type ConditionalExpressionOperator =
    Expression.Cond |
    Expression.IfNull |
    Expression.Switch;

  export type StringExpressionOperator =
    StringExpressionOperatorReturningArray |
    StringExpressionOperatorReturningBoolean |
    StringExpressionOperatorReturningNumber |
    StringExpressionOperatorReturningObject |
    StringExpressionOperatorReturningString;

  export type StringExpressionOperatorReturningArray =
    Expression.RegexFindAll |
    Expression.Split;

  export type StringExpressionOperatorReturningBoolean =
    Expression.RegexMatch;

  export type StringExpressionOperatorReturningNumber =
    Expression.IndexOfBytes |
    Expression.IndexOfCP |
    Expression.Strcasecmp |
    Expression.StrLenBytes |
    Expression.StrLenCP;

  export type StringExpressionOperatorReturningObject =
    Expression.RegexFind;

  export type StringExpressionOperatorReturningString =
    Expression.Concat |
    Expression.Ltrim |
    Expression.Ltrim |
    Expression.ReplaceOne |
    Expression.ReplaceAll |
    Expression.Substr |
    Expression.SubstrBytes |
    Expression.SubstrCP |
    Expression.ToLower |
    Expression.ToString |
    Expression.ToUpper |
    Expression.Trim;

  export type ObjectExpressionOperator =
    Expression.MergeObjects |
    Expression.ObjectToArray |
    Expression.SetField |
    Expression.UnsetField;

  export type ObjectExpressionOperatorReturningArray =
    Expression.ObjectToArray;

  export type ObjectExpressionOperatorReturningObject =
    Expression.MergeObjects |
    Expression.SetField |
    Expression.UnsetField;

  export type VariableExpressionOperator =
    Expression.Let;

  export type VariableExpressionOperatorReturningAny =
    Expression.Let;

  export type SetExpressionOperator =
    Expression.AllElementsTrue |
    Expression.AnyElementsTrue |
    Expression.SetDifference |
    Expression.SetEquals |
    Expression.SetIntersection |
    Expression.SetIsSubset |
    Expression.SetUnion;

  export type SetExpressionOperatorReturningBoolean =
    Expression.AllElementsTrue |
    Expression.AnyElementsTrue |
    Expression.SetEquals |
    Expression.SetIsSubset;

  export type SetExpressionOperatorReturningArray =
    Expression.SetDifference |
    Expression.SetIntersection |
    Expression.SetUnion;

  /**
   * Trigonometry expressions perform trigonometric operations on numbers.
   * Values that represent angles are always input or output in radians.
   * Use $degreesToRadians and $radiansToDegrees to convert between degree
   * and radian measurements.
   */
  export type TrigonometryExpressionOperator =
    Expression.Sin |
    Expression.Cos |
    Expression.Tan |
    Expression.Asin |
    Expression.Acos |
    Expression.Atan |
    Expression.Atan2 |
    Expression.Asinh |
    Expression.Acosh |
    Expression.Atanh |
    Expression.Sinh |
    Expression.Cosh |
    Expression.Tanh |
    Expression.DegreesToRadians |
    Expression.RadiansToDegrees;

  export type TextExpressionOperator =
    Expression.Meta;

  export type WindowOperator =
    Expression.AddToSet |
    Expression.Avg |
    Expression.Count |
    Expression.CovariancePop |
    Expression.CovarianceSamp |
    Expression.DenseRank |
    Expression.Derivative |
    Expression.DocumentNumber |
    Expression.ExpMovingAvg |
    Expression.First |
    Expression.Integral |
    Expression.Last |
    Expression.LinearFill |
    Expression.Locf |
    Expression.Max |
    Expression.Min |
    Expression.Push |
    Expression.Rank |
    Expression.Shift |
    Expression.StdDevPop |
    Expression.StdDevSamp |
    Expression.Sum;

  export type WindowOperatorReturningAny =
    Expression.First |
    Expression.Last |
    Expression.Shift;

  export type WindowOperatorReturningArray =
    Expression.AddToSet |
    Expression.Push;

  export type WindowOperatorReturningNumber =
    Expression.Avg |
    Expression.Count |
    Expression.CovariancePop |
    Expression.CovarianceSamp |
    Expression.DenseRank |
    Expression.DocumentNumber |
    Expression.ExpMovingAvg |
    Expression.Integral |
    Expression.Max |
    Expression.Min |
    Expression.StdDevPop |
    Expression.StdDevSamp |
    Expression.Sum;

  export type TypeExpressionOperator =
    Expression.Convert |
    Expression.IsNumber |
    Expression.ToBool |
    Expression.ToDate |
    Expression.ToDecimal |
    Expression.ToDouble |
    Expression.ToInt |
    Expression.ToLong |
    Expression.ToObjectId |
    Expression.ToString |
    Expression.Type;

  export type TypeExpressionOperatorReturningNumber =
    Expression.Convert<'double' | 1 | 'int' | 16 | 'long' | 18 | 'decimal' | 19> |
    Expression.ToDecimal |
    Expression.ToDouble |
    Expression.ToInt |
    Expression.ToLong;

  export type TypeExpressionOperatorReturningBoolean =
    Expression.Convert<'bool' | 8> |
    Expression.IsNumber |
    Expression.ToBool;


  export type TypeExpressionOperatorReturningString =
    Expression.Convert<'string' | 2> |
    Expression.ToString |
    Expression.Type;

  export type TypeExpressionOperatorReturningObjectId =
    Expression.Convert<'objectId' | 7> |
    Expression.ToObjectId;

  export type TypeExpressionOperatorReturningDate =
    Expression.Convert<'date' | 9> |
    Expression.ToDate;

  export type DataSizeOperator =
    Expression.BinarySize |
    Expression.BsonSize;

  export type DataSizeOperatorReturningNumber =
    Expression.BinarySize |
    Expression.BsonSize;

  export type CustomAggregationExpressionOperator =
    Expression.Accumulator |
    Expression.Function;

  export type CustomAggregationExpressionOperatorReturningAny =
    Expression.Function;

  export type AccumulatorOperator =
    Expression.Accumulator |
    Expression.AddToSet |
    Expression.Avg |
    Expression.Count |
    Expression.First |
    Expression.Last |
    Expression.Max |
    Expression.MergeObjects |
    Expression.Min |
    Expression.Push |
    Expression.StdDevPop |
    Expression.StdDevSamp |
    Expression.Sum |
    Expression.Top |
    Expression.TopN;

  export type tzExpression = UTCOffset | StringExpressionOperatorReturningBoolean | string;

  type hh = '-00' | '-01' | '-02' | '-03' | '-04' | '-05' | '-06' | '-07' | '-08' | '-09' | '-10' | '-11' | '-12' |
  '+00' | '+01' | '+02' | '+03' | '+04' | '+05' | '+06' | '+07' | '+08' | '+09' | '+10' | '+11' | '+12' | '+13' | '+14';
  type mm = '00' | '30' | '45';

  type UTCOffset = `${hh}` | `${hh}${mm}` | `${hh}:${mm}`;

  type RegexOptions =
    'i' | 'm' | 's' | 'x' |
    'is' | 'im' | 'ix' | 'si' | 'sm' | 'sx' | 'mi' | 'ms' | 'mx' | 'xi' | 'xs' | 'xm' |
    'ism' | 'isx' | 'ims' | 'imx' | 'ixs' | 'ixm' | 'sim' | 'six' | 'smi' | 'smx' | 'sxi' | 'sxm' | 'mis' | 'mix' | 'msi' | 'msx' | 'mxi' | 'mxs' | 'xis' | 'xim' | 'xsi' | 'xsm' | 'xmi' | 'xms' |
    'ismx' | 'isxm' | 'imsx' | 'imxs' | 'ixsm' | 'ixms' | 'simx' | 'sixm' | 'smix' | 'smxi' | 'sxim' | 'sxmi' | 'misx' | 'mixs' | 'msix' | 'msxi' | 'mxis' | 'mxsi' | 'xism' | 'xims' | 'xsim' | 'xsmi' | 'xmis' | 'xmsi';

  type StartOfWeek =
    'monday' | 'mon' |
    'tuesday' | 'tue' |
    'wednesday' | 'wed' |
    'thursday' | 'thu' |
    'friday' | 'fri' |
    'saturday' | 'sat' |
    'sunday' | 'sun';

  type DateUnit = 'year' | 'quarter' | 'week' | 'month' | 'day' | 'hour' | 'minute' | 'second' | 'millisecond';

  type FormatString = string;

  export type DateExpressionOperator =
    DateExpressionOperatorReturningDate |
    DateExpressionOperatorReturningNumber |
    DateExpressionOperatorReturningString |
    DateExpressionOperatorReturningObject;

  export type DateExpressionOperatorReturningObject =
    Expression.DateToParts;

  export type DateExpressionOperatorReturningNumber =
    Expression.DateDiff |
    Expression.DayOfMonth |
    Expression.DayOfWeek |
    Expression.DayOfYear |
    Expression.IsoDayOfWeek |
    Expression.IsoWeek |
    Expression.IsoWeekYear |
    Expression.Millisecond |
    Expression.Second |
    Expression.Minute |
    Expression.Hour |
    Expression.Month |
    Expression.Year;

  export type DateExpressionOperatorReturningDate =
    Expression.DateAdd |
    Expression.DateFromParts |
    Expression.DateFromString |
    Expression.DateSubtract |
    Expression.DateTrunc |
    Expression.ToDate;

  export type DateExpressionOperatorReturningString =
    Expression.DateToString;

}

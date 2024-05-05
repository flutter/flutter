import * as defaultOperations from "./operations";
import {
  Query,
  QueryOperators,
  BasicValueQuery,
  ArrayValueQuery,
  ValueQuery,
  NestedQuery,
  ShapeQuery,
  Options,
  createQueryTester,
  EqualsOperation,
  createQueryOperation,
  createEqualsOperation,
  createOperationTester
} from "./core";

const createDefaultQueryOperation = <TItem, TSchema extends TItem = TItem>(
  query: Query<TSchema>,
  ownerQuery: any,
  { compare, operations }: Partial<Options> = {}
) => {
  return createQueryOperation(query, ownerQuery, {
    compare,
    operations: Object.assign({}, defaultOperations, operations || {})
  });
};

const createDefaultQueryTester = <TItem, TSchema extends TItem = TItem>(
  query: Query<TSchema>,
  options: Partial<Options> = {}
) => {
  const op = createDefaultQueryOperation(query, null, options);
  return createOperationTester(op);
};

export {
  Query,
  QueryOperators,
  BasicValueQuery,
  ArrayValueQuery,
  ValueQuery,
  NestedQuery,
  ShapeQuery,
  EqualsOperation,
  createQueryTester,
  createOperationTester,
  createDefaultQueryOperation,
  createEqualsOperation,
  createQueryOperation
};
export * from "./operations";

export default createDefaultQueryTester;

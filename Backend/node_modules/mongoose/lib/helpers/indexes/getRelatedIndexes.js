'use strict';

const hasDollarKeys = require('../query/hasDollarKeys');

function getRelatedSchemaIndexes(model, schemaIndexes) {
  return getRelatedIndexes({
    baseModelName: model.baseModelName,
    discriminatorMapping: model.schema.discriminatorMapping,
    indexes: schemaIndexes,
    indexesType: 'schema'
  });
}

function getRelatedDBIndexes(model, dbIndexes) {
  return getRelatedIndexes({
    baseModelName: model.baseModelName,
    discriminatorMapping: model.schema.discriminatorMapping,
    indexes: dbIndexes,
    indexesType: 'db'
  });
}

module.exports = {
  getRelatedSchemaIndexes,
  getRelatedDBIndexes
};

function getRelatedIndexes({
  baseModelName,
  discriminatorMapping,
  indexes,
  indexesType
}) {
  const discriminatorKey = discriminatorMapping && discriminatorMapping.key;
  const discriminatorValue = discriminatorMapping && discriminatorMapping.value;

  if (!discriminatorKey) {
    return indexes;
  }

  const isChildDiscriminatorModel = Boolean(baseModelName);
  if (isChildDiscriminatorModel) {
    return indexes.filter(index => {
      const partialFilterExpression = getPartialFilterExpression(index, indexesType);
      return partialFilterExpression && partialFilterExpression[discriminatorKey] === discriminatorValue;
    });
  }

  return indexes.filter(index => {
    const partialFilterExpression = getPartialFilterExpression(index, indexesType);
    return !partialFilterExpression
      || !partialFilterExpression[discriminatorKey]
      || (hasDollarKeys(partialFilterExpression[discriminatorKey]) && !('$eq' in partialFilterExpression[discriminatorKey]));
  });
}

function getPartialFilterExpression(index, indexesType) {
  if (indexesType === 'schema') {
    const options = index[1];
    return options && options.partialFilterExpression;
  }
  return index.partialFilterExpression;
}

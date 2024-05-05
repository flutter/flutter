'use strict';

module.exports = function setDocumentTimestamps(doc, timestampOption, currentTime, createdAt, updatedAt) {
  const skipUpdatedAt = timestampOption != null && timestampOption.updatedAt === false;
  const skipCreatedAt = timestampOption != null && timestampOption.createdAt === false;

  const defaultTimestamp = currentTime != null ?
    currentTime() :
    doc.ownerDocument().constructor.base.now();

  if (!skipCreatedAt &&
      (doc.isNew || doc.$isSubdocument) &&
      createdAt &&
      !doc.$__getValue(createdAt) &&
      doc.$__isSelected(createdAt)) {
    doc.$set(createdAt, defaultTimestamp, undefined, { overwriteImmutable: true });
  }

  if (!skipUpdatedAt && updatedAt && (doc.isNew || doc.$isModified())) {
    let ts = defaultTimestamp;
    if (doc.isNew && createdAt != null) {
      ts = doc.$__getValue(createdAt);
    }
    doc.$set(updatedAt, ts);
  }
};

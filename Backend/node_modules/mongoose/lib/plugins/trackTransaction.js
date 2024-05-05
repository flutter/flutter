'use strict';

const arrayAtomicsSymbol = require('../helpers/symbols').arrayAtomicsSymbol;
const sessionNewDocuments = require('../helpers/symbols').sessionNewDocuments;
const utils = require('../utils');

module.exports = function trackTransaction(schema) {
  schema.pre('save', function trackTransactionPreSave() {
    const session = this.$session();
    if (session == null) {
      return;
    }
    if (session.transaction == null || session[sessionNewDocuments] == null) {
      return;
    }

    if (!session[sessionNewDocuments].has(this)) {
      const initialState = {};
      if (this.isNew) {
        initialState.isNew = true;
      }
      if (this.$__schema.options.versionKey) {
        initialState.versionKey = this.get(this.$__schema.options.versionKey);
      }

      initialState.modifiedPaths = new Set(Object.keys(this.$__.activePaths.getStatePaths('modify')));
      initialState.atomics = _getAtomics(this);

      session[sessionNewDocuments].set(this, initialState);
    } else {
      const state = session[sessionNewDocuments].get(this);

      for (const path of Object.keys(this.$__.activePaths.getStatePaths('modify'))) {
        state.modifiedPaths.add(path);
      }
      state.atomics = _getAtomics(this, state.atomics);
    }
  });
};

function _getAtomics(doc, previous) {
  const pathToAtomics = new Map();
  previous = previous || new Map();

  const pathsToCheck = Object.keys(doc.$__.activePaths.init).concat(Object.keys(doc.$__.activePaths.modify));

  for (const path of pathsToCheck) {
    const val = doc.$__getValue(path);
    if (val != null &&
        Array.isArray(val) &&
        utils.isMongooseDocumentArray(val) &&
        val.length &&
        val[arrayAtomicsSymbol] != null &&
        Object.keys(val[arrayAtomicsSymbol]).length !== 0) {
      const existing = previous.get(path) || {};
      pathToAtomics.set(path, mergeAtomics(existing, val[arrayAtomicsSymbol]));
    }
  }

  const dirty = doc.$__dirty();
  for (const dirt of dirty) {
    const path = dirt.path;

    const val = dirt.value;
    if (val != null && val[arrayAtomicsSymbol] != null && Object.keys(val[arrayAtomicsSymbol]).length !== 0) {
      const existing = previous.get(path) || {};
      pathToAtomics.set(path, mergeAtomics(existing, val[arrayAtomicsSymbol]));
    }
  }

  return pathToAtomics;
}

function mergeAtomics(destination, source) {
  destination = destination || {};

  if (source.$pullAll != null) {
    destination.$pullAll = (destination.$pullAll || []).concat(source.$pullAll);
  }
  if (source.$push != null) {
    destination.$push = destination.$push || {};
    destination.$push.$each = (destination.$push.$each || []).concat(source.$push.$each);
  }
  if (source.$addToSet != null) {
    destination.$addToSet = (destination.$addToSet || []).concat(source.$addToSet);
  }
  if (source.$set != null) {
    destination.$set = Array.isArray(source.$set) ? [...source.$set] : Object.assign({}, source.$set);
  }

  return destination;
}

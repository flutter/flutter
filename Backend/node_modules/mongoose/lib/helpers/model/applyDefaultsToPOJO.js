'use strict';

module.exports = function applyDefaultsToPOJO(doc, schema) {
  const paths = Object.keys(schema.paths);
  const plen = paths.length;

  for (let i = 0; i < plen; ++i) {
    let curPath = '';
    const p = paths[i];

    const type = schema.paths[p];
    const path = type.splitPath();
    const len = path.length;
    let doc_ = doc;
    for (let j = 0; j < len; ++j) {
      if (doc_ == null) {
        break;
      }

      const piece = path[j];
      curPath += (!curPath.length ? '' : '.') + piece;

      if (j === len - 1) {
        if (typeof doc_[piece] !== 'undefined') {
          if (type.$isSingleNested) {
            applyDefaultsToPOJO(doc_[piece], type.caster.schema);
          } else if (type.$isMongooseDocumentArray && Array.isArray(doc_[piece])) {
            doc_[piece].forEach(el => applyDefaultsToPOJO(el, type.schema));
          }

          break;
        }

        const def = type.getDefault(doc, false, { skipCast: true });
        if (typeof def !== 'undefined') {
          doc_[piece] = def;

          if (type.$isSingleNested) {
            applyDefaultsToPOJO(def, type.caster.schema);
          } else if (type.$isMongooseDocumentArray && Array.isArray(def)) {
            def.forEach(el => applyDefaultsToPOJO(el, type.schema));
          }
        }
      } else {
        if (doc_[piece] == null) {
          doc_[piece] = {};
        }
        doc_ = doc_[piece];
      }
    }
  }
};

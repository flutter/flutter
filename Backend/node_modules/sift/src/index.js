"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createQueryOperation = exports.createEqualsOperation = exports.createDefaultQueryOperation = exports.createOperationTester = exports.createQueryTester = exports.EqualsOperation = void 0;
const defaultOperations = require("./operations");
const core_1 = require("./core");
Object.defineProperty(exports, "createQueryTester", { enumerable: true, get: function () { return core_1.createQueryTester; } });
Object.defineProperty(exports, "EqualsOperation", { enumerable: true, get: function () { return core_1.EqualsOperation; } });
Object.defineProperty(exports, "createQueryOperation", { enumerable: true, get: function () { return core_1.createQueryOperation; } });
Object.defineProperty(exports, "createEqualsOperation", { enumerable: true, get: function () { return core_1.createEqualsOperation; } });
Object.defineProperty(exports, "createOperationTester", { enumerable: true, get: function () { return core_1.createOperationTester; } });
const createDefaultQueryOperation = (query, ownerQuery, { compare, operations } = {}) => {
    return (0, core_1.createQueryOperation)(query, ownerQuery, {
        compare,
        operations: Object.assign({}, defaultOperations, operations || {})
    });
};
exports.createDefaultQueryOperation = createDefaultQueryOperation;
const createDefaultQueryTester = (query, options = {}) => {
    const op = createDefaultQueryOperation(query, null, options);
    return (0, core_1.createOperationTester)(op);
};
__exportStar(require("./operations"), exports);
exports.default = createDefaultQueryTester;
//# sourceMappingURL=index.js.map
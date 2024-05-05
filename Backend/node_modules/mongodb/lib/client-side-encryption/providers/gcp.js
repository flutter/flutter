"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadGCPCredentials = void 0;
const deps_1 = require("../../deps");
/** @internal */
async function loadGCPCredentials(kmsProviders) {
    const gcpMetadata = (0, deps_1.getGcpMetadata)();
    if ('kModuleError' in gcpMetadata) {
        return kmsProviders;
    }
    const { access_token: accessToken } = await gcpMetadata.instance({
        property: 'service-accounts/default/token'
    });
    return { ...kmsProviders, gcp: { accessToken } };
}
exports.loadGCPCredentials = loadGCPCredentials;
//# sourceMappingURL=gcp.js.map
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadAWSCredentials = void 0;
const deps_1 = require("../../deps");
/**
 * @internal
 */
async function loadAWSCredentials(kmsProviders) {
    const credentialProvider = (0, deps_1.getAwsCredentialProvider)();
    if ('kModuleError' in credentialProvider) {
        return kmsProviders;
    }
    const { fromNodeProviderChain } = credentialProvider;
    const provider = fromNodeProviderChain();
    // The state machine is the only place calling this so it will
    // catch if there is a rejection here.
    const aws = await provider();
    return { ...kmsProviders, aws };
}
exports.loadAWSCredentials = loadAWSCredentials;
//# sourceMappingURL=aws.js.map
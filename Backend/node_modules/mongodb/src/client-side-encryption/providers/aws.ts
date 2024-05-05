import { getAwsCredentialProvider } from '../../deps';
import { type KMSProviders } from '.';

/**
 * @internal
 */
export async function loadAWSCredentials(kmsProviders: KMSProviders): Promise<KMSProviders> {
  const credentialProvider = getAwsCredentialProvider();

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

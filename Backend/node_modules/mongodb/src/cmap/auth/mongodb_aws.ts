import * as process from 'process';

import type { Binary, BSONSerializeOptions } from '../../bson';
import * as BSON from '../../bson';
import { aws4, type AWSCredentials, getAwsCredentialProvider } from '../../deps';
import {
  MongoAWSError,
  MongoCompatibilityError,
  MongoMissingCredentialsError,
  MongoRuntimeError
} from '../../error';
import { ByteUtils, maxWireVersion, ns, randomBytes, request } from '../../utils';
import { type AuthContext, AuthProvider } from './auth_provider';
import { MongoCredentials } from './mongo_credentials';
import { AuthMechanism } from './providers';

/**
 * The following regions use the global AWS STS endpoint, sts.amazonaws.com, by default
 * https://docs.aws.amazon.com/sdkref/latest/guide/feature-sts-regionalized-endpoints.html
 */
const LEGACY_REGIONS = new Set([
  'ap-northeast-1',
  'ap-south-1',
  'ap-southeast-1',
  'ap-southeast-2',
  'aws-global',
  'ca-central-1',
  'eu-central-1',
  'eu-north-1',
  'eu-west-1',
  'eu-west-2',
  'eu-west-3',
  'sa-east-1',
  'us-east-1',
  'us-east-2',
  'us-west-1',
  'us-west-2'
]);
const ASCII_N = 110;
const AWS_RELATIVE_URI = 'http://169.254.170.2';
const AWS_EC2_URI = 'http://169.254.169.254';
const AWS_EC2_PATH = '/latest/meta-data/iam/security-credentials';
const bsonOptions: BSONSerializeOptions = {
  useBigInt64: false,
  promoteLongs: true,
  promoteValues: true,
  promoteBuffers: false,
  bsonRegExp: false
};

interface AWSSaslContinuePayload {
  a: string;
  d: string;
  t?: string;
}

export class MongoDBAWS extends AuthProvider {
  static credentialProvider: ReturnType<typeof getAwsCredentialProvider>;
  provider?: () => Promise<AWSCredentials>;

  constructor() {
    super();
    MongoDBAWS.credentialProvider ??= getAwsCredentialProvider();

    let { AWS_STS_REGIONAL_ENDPOINTS = '', AWS_REGION = '' } = process.env;
    AWS_STS_REGIONAL_ENDPOINTS = AWS_STS_REGIONAL_ENDPOINTS.toLowerCase();
    AWS_REGION = AWS_REGION.toLowerCase();

    /** The option setting should work only for users who have explicit settings in their environment, the driver should not encode "defaults" */
    const awsRegionSettingsExist =
      AWS_REGION.length !== 0 && AWS_STS_REGIONAL_ENDPOINTS.length !== 0;

    /**
     * If AWS_STS_REGIONAL_ENDPOINTS is set to regional, users are opting into the new behavior of respecting the region settings
     *
     * If AWS_STS_REGIONAL_ENDPOINTS is set to legacy, then "old" regions need to keep using the global setting.
     * Technically the SDK gets this wrong, it reaches out to 'sts.us-east-1.amazonaws.com' when it should be 'sts.amazonaws.com'.
     * That is not our bug to fix here. We leave that up to the SDK.
     */
    const useRegionalSts =
      AWS_STS_REGIONAL_ENDPOINTS === 'regional' ||
      (AWS_STS_REGIONAL_ENDPOINTS === 'legacy' && !LEGACY_REGIONS.has(AWS_REGION));

    if ('fromNodeProviderChain' in MongoDBAWS.credentialProvider) {
      this.provider =
        awsRegionSettingsExist && useRegionalSts
          ? MongoDBAWS.credentialProvider.fromNodeProviderChain({
              clientConfig: { region: AWS_REGION }
            })
          : MongoDBAWS.credentialProvider.fromNodeProviderChain();
    }
  }

  override async auth(authContext: AuthContext): Promise<void> {
    const { connection } = authContext;
    if (!authContext.credentials) {
      throw new MongoMissingCredentialsError('AuthContext must provide credentials.');
    }

    if ('kModuleError' in aws4) {
      throw aws4['kModuleError'];
    }
    const { sign } = aws4;

    if (maxWireVersion(connection) < 9) {
      throw new MongoCompatibilityError(
        'MONGODB-AWS authentication requires MongoDB version 4.4 or later'
      );
    }

    if (!authContext.credentials.username) {
      authContext.credentials = await makeTempCredentials(authContext.credentials, this.provider);
    }

    const { credentials } = authContext;

    const accessKeyId = credentials.username;
    const secretAccessKey = credentials.password;
    // Allow the user to specify an AWS session token for authentication with temporary credentials.
    const sessionToken = credentials.mechanismProperties.AWS_SESSION_TOKEN;

    // If all three defined, include sessionToken, else include username and pass, else no credentials
    const awsCredentials =
      accessKeyId && secretAccessKey && sessionToken
        ? { accessKeyId, secretAccessKey, sessionToken }
        : accessKeyId && secretAccessKey
        ? { accessKeyId, secretAccessKey }
        : undefined;

    const db = credentials.source;
    const nonce = await randomBytes(32);

    // All messages between MongoDB clients and servers are sent as BSON objects
    // in the payload field of saslStart and saslContinue.
    const saslStart = {
      saslStart: 1,
      mechanism: 'MONGODB-AWS',
      payload: BSON.serialize({ r: nonce, p: ASCII_N }, bsonOptions)
    };

    const saslStartResponse = await connection.command(ns(`${db}.$cmd`), saslStart, undefined);

    const serverResponse = BSON.deserialize(saslStartResponse.payload.buffer, bsonOptions) as {
      s: Binary;
      h: string;
    };
    const host = serverResponse.h;
    const serverNonce = serverResponse.s.buffer;
    if (serverNonce.length !== 64) {
      // TODO(NODE-3483)
      throw new MongoRuntimeError(`Invalid server nonce length ${serverNonce.length}, expected 64`);
    }

    if (!ByteUtils.equals(serverNonce.subarray(0, nonce.byteLength), nonce)) {
      // throw because the serverNonce's leading 32 bytes must equal the client nonce's 32 bytes
      // https://github.com/mongodb/specifications/blob/875446db44aade414011731840831f38a6c668df/source/auth/auth.rst#id11

      // TODO(NODE-3483)
      throw new MongoRuntimeError('Server nonce does not begin with client nonce');
    }

    if (host.length < 1 || host.length > 255 || host.indexOf('..') !== -1) {
      // TODO(NODE-3483)
      throw new MongoRuntimeError(`Server returned an invalid host: "${host}"`);
    }

    const body = 'Action=GetCallerIdentity&Version=2011-06-15';
    const options = sign(
      {
        method: 'POST',
        host,
        region: deriveRegion(serverResponse.h),
        service: 'sts',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Content-Length': body.length,
          'X-MongoDB-Server-Nonce': ByteUtils.toBase64(serverNonce),
          'X-MongoDB-GS2-CB-Flag': 'n'
        },
        path: '/',
        body
      },
      awsCredentials
    );

    const payload: AWSSaslContinuePayload = {
      a: options.headers.Authorization,
      d: options.headers['X-Amz-Date']
    };

    if (sessionToken) {
      payload.t = sessionToken;
    }

    const saslContinue = {
      saslContinue: 1,
      conversationId: 1,
      payload: BSON.serialize(payload, bsonOptions)
    };

    await connection.command(ns(`${db}.$cmd`), saslContinue, undefined);
  }
}

interface AWSTempCredentials {
  AccessKeyId?: string;
  SecretAccessKey?: string;
  Token?: string;
  RoleArn?: string;
  Expiration?: Date;
}

async function makeTempCredentials(
  credentials: MongoCredentials,
  provider?: () => Promise<AWSCredentials>
): Promise<MongoCredentials> {
  function makeMongoCredentialsFromAWSTemp(creds: AWSTempCredentials) {
    // The AWS session token (creds.Token) may or may not be set.
    if (!creds.AccessKeyId || !creds.SecretAccessKey) {
      throw new MongoMissingCredentialsError('Could not obtain temporary MONGODB-AWS credentials');
    }

    return new MongoCredentials({
      username: creds.AccessKeyId,
      password: creds.SecretAccessKey,
      source: credentials.source,
      mechanism: AuthMechanism.MONGODB_AWS,
      mechanismProperties: {
        AWS_SESSION_TOKEN: creds.Token
      }
    });
  }

  // Check if the AWS credential provider from the SDK is present. If not,
  // use the old method.
  if (provider && !('kModuleError' in MongoDBAWS.credentialProvider)) {
    /*
     * Creates a credential provider that will attempt to find credentials from the
     * following sources (listed in order of precedence):
     *
     * - Environment variables exposed via process.env
     * - SSO credentials from token cache
     * - Web identity token credentials
     * - Shared credentials and config ini files
     * - The EC2/ECS Instance Metadata Service
     */
    try {
      const creds = await provider();
      return makeMongoCredentialsFromAWSTemp({
        AccessKeyId: creds.accessKeyId,
        SecretAccessKey: creds.secretAccessKey,
        Token: creds.sessionToken,
        Expiration: creds.expiration
      });
    } catch (error) {
      throw new MongoAWSError(error.message);
    }
  } else {
    // If the environment variable AWS_CONTAINER_CREDENTIALS_RELATIVE_URI
    // is set then drivers MUST assume that it was set by an AWS ECS agent
    if (process.env.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI) {
      return makeMongoCredentialsFromAWSTemp(
        await request(`${AWS_RELATIVE_URI}${process.env.AWS_CONTAINER_CREDENTIALS_RELATIVE_URI}`)
      );
    }

    // Otherwise assume we are on an EC2 instance

    // get a token
    const token = await request(`${AWS_EC2_URI}/latest/api/token`, {
      method: 'PUT',
      json: false,
      headers: { 'X-aws-ec2-metadata-token-ttl-seconds': 30 }
    });

    // get role name
    const roleName = await request(`${AWS_EC2_URI}/${AWS_EC2_PATH}`, {
      json: false,
      headers: { 'X-aws-ec2-metadata-token': token }
    });

    // get temp credentials
    const creds = await request(`${AWS_EC2_URI}/${AWS_EC2_PATH}/${roleName}`, {
      headers: { 'X-aws-ec2-metadata-token': token }
    });

    return makeMongoCredentialsFromAWSTemp(creds);
  }
}

function deriveRegion(host: string) {
  const parts = host.split('.');
  if (parts.length === 1 || parts[1] === 'amazonaws') {
    return 'us-east-1';
  }

  return parts[1];
}

declare class NativeError extends global.Error { }

declare module 'mongoose' {
  import mongodb = require('mongodb');

  type CastError = Error.CastError;
  type SyncIndexesError = Error.SyncIndexesError;

  export class MongooseError extends global.Error {
    constructor(msg: string);

    /** The type of error. "MongooseError" for generic errors. */
    name: string;

    static messages: any;

    static Messages: any;
  }

  class Error extends MongooseError { }

  namespace Error {

    export class CastError extends MongooseError {
      name: 'CastError';
      stringValue: string;
      kind: string;
      value: any;
      path: string;
      reason?: NativeError | null;
      model?: any;

      constructor(type: string, value: any, path: string, reason?: NativeError, schemaType?: SchemaType);
    }
    export class SyncIndexesError extends MongooseError {
      name: 'SyncIndexesError';
      errors?: Record<string, mongodb.MongoServerError>;

      constructor(type: string, value: any, path: string, reason?: NativeError, schemaType?: SchemaType);
    }

    export class DivergentArrayError extends MongooseError {
      name: 'DivergentArrayError';
    }

    export class MissingSchemaError extends MongooseError {
      name: 'MissingSchemaError';
    }

    export class DocumentNotFoundError extends MongooseError {
      name: 'DocumentNotFoundError';
      result: any;
      numAffected: number;
      filter: any;
      query: any;
    }

    export class ObjectExpectedError extends MongooseError {
      name: 'ObjectExpectedError';
      path: string;
    }

    export class ObjectParameterError extends MongooseError {
      name: 'ObjectParameterError';
    }

    export class OverwriteModelError extends MongooseError {
      name: 'OverwriteModelError';
    }

    export class ParallelSaveError extends MongooseError {
      name: 'ParallelSaveError';
    }

    export class ParallelValidateError extends MongooseError {
      name: 'ParallelValidateError';
    }

    export class MongooseServerSelectionError extends MongooseError {
      name: 'MongooseServerSelectionError';
    }

    export class StrictModeError extends MongooseError {
      name: 'StrictModeError';
      isImmutableError: boolean;
      path: string;
    }

    export class ValidationError extends MongooseError {
      name: 'ValidationError';

      errors: { [path: string]: ValidatorError | CastError };
      addError: (path: string, error: ValidatorError | CastError) => void;

      constructor(instance?: MongooseError);
    }

    export class ValidatorError extends MongooseError {
      name: 'ValidatorError';
      properties: {
        message: string,
        type?: string,
        path?: string,
        value?: any,
        reason?: any
      };
      kind: string;
      path: string;
      value: any;
      reason?: MongooseError | null;

      constructor(properties: {
        message?: string,
        type?: string,
        path?: string,
        value?: any,
        reason?: any
      });
    }

    export class VersionError extends MongooseError {
      name: 'VersionError';
      version: number;
      modifiedPaths: Array<string>;

      constructor(doc: Document, currentVersion: number, modifiedPaths: Array<string>);
    }

    export class StrictPopulateError extends MongooseError {
      name: 'StrictPopulateError';
      path: string;
    }
  }
}

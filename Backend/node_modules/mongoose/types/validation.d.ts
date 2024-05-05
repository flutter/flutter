declare module 'mongoose' {

  type SchemaValidator<T> = RegExp | [RegExp, string] | Function | [Function, string] | ValidateOpts<T> | ValidateOpts<T>[];

  interface ValidatorProps {
    path: string;
    fullPath: string;
    value: any;
    reason?: Error;
  }

  interface ValidatorMessageFn {
    (props: ValidatorProps): string;
  }

  interface ValidateFn<T> {
    (value: T, props?: ValidatorProps & Record<string, any>): boolean;
  }

  interface LegacyAsyncValidateFn<T> {
    (value: T, done: (result: boolean) => void): void;
  }

  interface AsyncValidateFn<T> {
    (value: T, props?: ValidatorProps & Record<string, any>): Promise<boolean>;
  }

  interface ValidateOpts<T> {
    msg?: string;
    message?: string | ValidatorMessageFn;
    type?: string;
    validator: ValidateFn<T> | LegacyAsyncValidateFn<T> | AsyncValidateFn<T>;
    propsParameter?: boolean;
  }
}

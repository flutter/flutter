declare module "kareem" {
  export default class Kareem {
    static skipWrappedFunction(): SkipWrappedFunction;
    static overwriteMiddlewareResult(): OverwriteMiddlewareResult;

    pre(name: string | RegExp, fn: Function): this;
    pre(name: string | RegExp, options: Record<string, any>, fn: Function, error?: any, unshift?: boolean): this;
    post(name: string | RegExp, fn: Function): this;
    post(name: string | RegExp, options: Record<string, any>, fn: Function, unshift?: boolean): this;

    clone(): Kareem;
    merge(other: Kareem, clone?: boolean): this;

    createWrapper(name: string, fn: Function, context?: any, options?: Record<string, any>): Function;
    createWrapperSync(name: string, fn: Function): Function;
    hasHooks(name: string): boolean;
    filter(fn: Function): Kareem;

    wrap(name: string, fn: Function, context: any, args: any[], options?: Record<string, any>): Function;

    execPostSync(name: string, context: any, args: any[]): any;
    execPost(name: string, context: any, args: any[], options?: Record<string, any>, callback?: Function): void;
    execPreSync(name: string, context: any, args: any[]): any;
    execPre(name: string, context: any, args: any[], callback?: Function): void;
  }

  class SkipWrappedFunction {}
  class OverwriteMiddlewareResult {}
}

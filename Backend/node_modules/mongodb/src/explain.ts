import { MongoInvalidArgumentError } from './error';

/** @public */
export const ExplainVerbosity = Object.freeze({
  queryPlanner: 'queryPlanner',
  queryPlannerExtended: 'queryPlannerExtended',
  executionStats: 'executionStats',
  allPlansExecution: 'allPlansExecution'
} as const);

/** @public */
export type ExplainVerbosity = string;

/**
 * For backwards compatibility, true is interpreted as "allPlansExecution"
 * and false as "queryPlanner". Prior to server version 3.6, aggregate()
 * ignores the verbosity parameter and executes in "queryPlanner".
 * @public
 */
export type ExplainVerbosityLike = ExplainVerbosity | boolean;

/** @public */
export interface ExplainOptions {
  /** Specifies the verbosity mode for the explain output. */
  explain?: ExplainVerbosityLike;
}

/** @internal */
export class Explain {
  verbosity: ExplainVerbosity;

  constructor(verbosity: ExplainVerbosityLike) {
    if (typeof verbosity === 'boolean') {
      this.verbosity = verbosity
        ? ExplainVerbosity.allPlansExecution
        : ExplainVerbosity.queryPlanner;
    } else {
      this.verbosity = verbosity;
    }
  }

  static fromOptions(options?: ExplainOptions): Explain | undefined {
    if (options?.explain == null) return;

    const explain = options.explain;
    if (typeof explain === 'boolean' || typeof explain === 'string') {
      return new Explain(explain);
    }

    throw new MongoInvalidArgumentError('Field "explain" must be a string or a boolean');
  }
}

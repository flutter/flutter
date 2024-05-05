declare module 'mongoose' {
  /**
     * [Stages reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation-pipeline/#aggregation-pipeline-stages)
     */
  export type PipelineStage =
    | PipelineStage.AddFields
    | PipelineStage.Bucket
    | PipelineStage.BucketAuto
    | PipelineStage.CollStats
    | PipelineStage.Count
    | PipelineStage.Densify
    | PipelineStage.Facet
    | PipelineStage.Fill
    | PipelineStage.GeoNear
    | PipelineStage.GraphLookup
    | PipelineStage.Group
    | PipelineStage.IndexStats
    | PipelineStage.Limit
    | PipelineStage.ListSessions
    | PipelineStage.Lookup
    | PipelineStage.Match
    | PipelineStage.Merge
    | PipelineStage.Out
    | PipelineStage.PlanCacheStats
    | PipelineStage.Project
    | PipelineStage.Redact
    | PipelineStage.ReplaceRoot
    | PipelineStage.ReplaceWith
    | PipelineStage.Sample
    | PipelineStage.Search
    | PipelineStage.SearchMeta
    | PipelineStage.Set
    | PipelineStage.SetWindowFields
    | PipelineStage.Skip
    | PipelineStage.Sort
    | PipelineStage.SortByCount
    | PipelineStage.UnionWith
    | PipelineStage.Unset
    | PipelineStage.Unwind
    | PipelineStage.VectorSearch;

  export namespace PipelineStage {
    export interface AddFields {
      /** [`$addFields` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/addFields/) */
      $addFields: Record<string, AnyExpression>
    }

    export interface Bucket {
      /** [`$bucket` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/bucket/) */
      $bucket: {
        groupBy: Expression;
        boundaries: any[];
        default?: any
        output?: Record<string, AccumulatorOperator>
      }
    }

    export interface BucketAuto {
      /** [`$bucketAuto` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/bucketAuto/) */
      $bucketAuto: {
        groupBy: Expression | Record<string, Expression>;
        buckets: number;
        output?: Record<string, AccumulatorOperator>;
        granularity?: 'R5' | 'R10' | 'R20' | 'R40' | 'R80' | '1-2-5' | 'E6' | 'E12' | 'E24' | 'E48' | 'E96' | 'E192' | 'POWERSOF2';
      }
    }

    export interface CollStats {
      /** [`$collStats` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/collStats/) */
      $collStats: {
        latencyStats?: { histograms?: boolean };
        storageStats?: { scale?: number };
        count?: Record<string | number | symbol, never>;
        queryExecStats?: Record<string | number | symbol, never>;
      }
    }

    export interface Count {
      /** [`$count` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/count/) */
      $count: string;
    }

    export interface Densify{
      /** [`$densify` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/densify/) */
      $densify: {
        field: string,
        partitionByFields?: string[],
        range: {
          step: number,
          unit?: 'millisecond' | 'second' | 'minute' | 'hour' | 'day' | 'week' | 'month' | 'quarter' | 'year',
          bounds: number[] | globalThis.Date[] | 'full' | 'partition'
        }
      }
    }

    export interface Fill {
      /** [`$fill` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/fill/) */
      $fill: {
        partitionBy?: Expression,
        partitionByFields?: string[],
        sortBy?: Record<string, 1 | -1>,
        output: Record<string, { value: Expression } | { method: 'linear' | 'locf' }>
      }
    }

    export interface Facet {
      /** [`$facet` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/facet/) */
      $facet: Record<string, FacetPipelineStage[]>;
    }

    export type FacetPipelineStage = Exclude<PipelineStage, PipelineStage.CollStats | PipelineStage.Facet | PipelineStage.GeoNear | PipelineStage.IndexStats | PipelineStage.Out | PipelineStage.Merge | PipelineStage.PlanCacheStats>;

    export interface GeoNear {
      /** [`$geoNear` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/geoNear/) */
      $geoNear: {
        near: { type: 'Point'; coordinates: [number, number] } | [number, number];
        distanceField: string;
        distanceMultiplier?: number;
        includeLocs?: string;
        key?: string;
        maxDistance?: number;
        minDistance?: number;
        query?: AnyObject;
        spherical?: boolean;
        /**
         * Deprecated. Use only with MondoDB below 4.2 (removed in 4.2)
         * @deprecated
         */
        num?: number;
      }
    }

    export interface GraphLookup {
      /** [`$graphLookup` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/graphLookup/) */
      $graphLookup: {
        from: string;
        startWith: any
        connectFromField: string;
        connectToField: string;
        as: string;
        maxDepth?: number;
        depthField?: string;
        restrictSearchWithMatch?: AnyObject;
      }
    }

    export interface Group {
      /** [`$group` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/group) */
      $group: { _id: any } | { [key: string]: AccumulatorOperator }
    }

    export interface IndexStats {
      /** [`$indexStats` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/indexStats/) */
      $indexStats: Record<string | number | symbol, never>;
    }

    export interface Limit {
      /** [`$limit` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/limit/) */
      $limit: number
    }

    export interface ListSessions {
      /** [`$listSessions` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/listSessions/) */
      $listSessions: { users?: { user: string; db: string }[] } | { allUsers?: true }
    }

    export interface Lookup {
      /** [`$lookup` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/lookup/) */
      $lookup: {
        from: string
        as: string
        localField?: string
        foreignField?: string
        let?: Record<string, any>
        pipeline?: Exclude<PipelineStage, PipelineStage.Merge | PipelineStage.Out>[]
      }
    }

    export interface Match {
      /** [`$match` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/match/) */
      $match: FilterQuery<any>;
    }

    export interface Merge {
      /** [`$merge` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/merge/) */
      $merge: {
        into: string | { db: string; coll: string }
        on?: string | string[]
        let?: Record<string, Expression>
        whenMatched?: 'replace' | 'keepExisting' | 'merge' | 'fail' | Extract<PipelineStage, PipelineStage.AddFields | PipelineStage.Set | PipelineStage.Project | PipelineStage.Unset | PipelineStage.ReplaceRoot | PipelineStage.ReplaceWith>[]
        whenNotMatched?: 'insert' | 'discard' | 'fail'
      }
    }

    export interface Out {
      /** [`$out` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/out/) */
      $out: string | { db: string; coll: string }
    }

    export interface PlanCacheStats {
      /** [`$planCacheStats` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/planCacheStats/) */
      $planCacheStats: Record<string | number | symbol, never>
    }

    export interface Project {
      /** [`$project` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/project/) */
      $project: { [field: string]: AnyExpression | Expression | Project['$project'] }
    }

    export interface Redact {
      /** [`$redact` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/redact/) */
      $redact: Expression;
    }

    export interface ReplaceRoot {
      /** [`$replaceRoot` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/replaceRoot/) */
      $replaceRoot: { newRoot: AnyExpression }
    }

    export interface ReplaceWith {
      /** [`$replaceWith` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/replaceWith/) */
      $replaceWith: ObjectExpressionOperator | { [field: string]: Expression } | `$${string}`;
    }

    export interface Sample {
      /** [`$sample` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/sample/) */
      $sample: { size: number }
    }

    export interface Search {
      /** [`$search` reference](https://www.mongodb.com/docs/atlas/atlas-search/query-syntax/) */
      $search: {
        index?: string;
        highlight?: {
          /** [`highlightPath` reference](https://docs.atlas.mongodb.com/atlas-search/path-construction/#multiple-field-search) */
          path: string | string[] | { value: string, multi: string };
          maxCharsToExamine?: number;
          maxNumPassages?: number;
        };
        [operator: string]: any;
      }
    }

    export interface SearchMeta {
      /** [`$searchMeta` reference](https://www.mongodb.com/docs/atlas/atlas-search/query-syntax/#mongodb-pipeline-pipe.-searchMeta) */
      $searchMeta: {
        index?: string;
        highlight?: {
          /** [`highlightPath` reference](https://docs.atlas.mongodb.com/atlas-search/path-construction/#multiple-field-search) */
          path: string | string[] | { value: string, multi: string };
          maxCharsToExamine?: number;
          maxNumPassages?: number;
        };
        [operator: string]: any;
      }
    }

    export interface Set {
      /** [`$set` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/set/) */
      $set: Record<string, AnyExpression | any>
    }

    export interface SetWindowFields {
      /** [`$setWindowFields` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/setWindowFields/) */
      $setWindowFields: {
        partitionBy?: any
        sortBy?: Record<string, 1 | -1>
        output: Record<
        string,
        WindowOperator & {
          window?: {
            documents?: [string | number, string | number]
            range?: [string | number, string | number]
            unit?: 'year' | 'quarter' | 'month' | 'week' | 'day' | 'hour' | 'minute' | 'second' | 'millisecond'
          }
        }
        >
      }
    }

    export interface Skip {
      /** [`$skip` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/skip/) */
      $skip: number
    }

    export interface Sort {
      /** [`$sort` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/sort/) */
      $sort: Record<string, 1 | -1 | Expression.Meta>
    }

    export interface SortByCount {
      /** [`$sortByCount` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/sortByCount/) */
      $sortByCount: Expression;
    }

    export interface UnionWith {
      /** [`$unionWith` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/unionWith/) */
      $unionWith:
      | string
      | { coll: string; pipeline?: Exclude<PipelineStage, PipelineStage.Out | PipelineStage.Merge>[] }
    }

    export interface Unset {
      /** [`$unset` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/unset/) */
      $unset: string | string[]
    }

    export interface Unwind {
      /** [`$unwind` reference](https://www.mongodb.com/docs/manual/reference/operator/aggregation/unwind/) */
      $unwind: string | { path: string; includeArrayIndex?: string; preserveNullAndEmptyArrays?: boolean }
    }
    export interface VectorSearch {
      /** [`$vectorSearch` reference](https://www.mongodb.com/docs/atlas/atlas-vector-search/vector-search-stage/) */
      $vectorSearch: {
        index: string,
        path: string,
        queryVector: number[],
        numCandidates: number,
        limit: number,
        filter?: Expression,
      }
    }

  }
}

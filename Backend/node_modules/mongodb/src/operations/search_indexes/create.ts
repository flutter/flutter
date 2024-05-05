import type { Document } from 'bson';

import type { Collection } from '../../collection';
import type { Server } from '../../sdam/server';
import type { ClientSession } from '../../sessions';
import { AbstractOperation } from '../operation';

/**
 * @public
 */
export interface SearchIndexDescription {
  /** The name of the index. */
  name?: string;

  /** The index definition. */
  definition: Document;
}

/** @internal */
export class CreateSearchIndexesOperation extends AbstractOperation<string[]> {
  constructor(
    private readonly collection: Collection,
    private readonly descriptions: ReadonlyArray<SearchIndexDescription>
  ) {
    super();
  }

  override get commandName() {
    return 'createSearchIndexes' as const;
  }

  override async execute(server: Server, session: ClientSession | undefined): Promise<string[]> {
    const namespace = this.collection.fullNamespace;
    const command = {
      createSearchIndexes: namespace.collection,
      indexes: this.descriptions
    };

    const res = await server.command(namespace, command, { session });

    const indexesCreated: Array<{ name: string }> = res?.indexesCreated ?? [];
    return indexesCreated.map(({ name }) => name);
  }
}

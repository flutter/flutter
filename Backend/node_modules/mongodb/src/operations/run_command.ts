import type { BSONSerializeOptions, Document } from '../bson';
import { type Db } from '../db';
import { type TODO_NODE_3286 } from '../mongo_types';
import type { ReadPreferenceLike } from '../read_preference';
import type { Server } from '../sdam/server';
import type { ClientSession } from '../sessions';
import { MongoDBNamespace } from '../utils';
import { AbstractOperation } from './operation';

/** @public */
export type RunCommandOptions = {
  /** Specify ClientSession for this command */
  session?: ClientSession;
  /** The read preference */
  readPreference?: ReadPreferenceLike;
} & BSONSerializeOptions;

/** @internal */
export class RunCommandOperation<T = Document> extends AbstractOperation<T> {
  constructor(parent: Db, public command: Document, public override options: RunCommandOptions) {
    super(options);
    this.ns = parent.s.namespace.withCollection('$cmd');
  }

  override get commandName() {
    return 'runCommand' as const;
  }

  override async execute(server: Server, session: ClientSession | undefined): Promise<T> {
    this.server = server;
    return server.command(this.ns, this.command, {
      ...this.options,
      readPreference: this.readPreference,
      session
    }) as TODO_NODE_3286;
  }
}

export class RunAdminCommandOperation<T = Document> extends AbstractOperation<T> {
  constructor(
    public command: Document,
    public override options: RunCommandOptions & {
      noResponse?: boolean;
      bypassPinningCheck?: boolean;
    }
  ) {
    super(options);
    this.ns = new MongoDBNamespace('admin', '$cmd');
  }

  override get commandName() {
    return 'runCommand' as const;
  }

  override async execute(server: Server, session: ClientSession | undefined): Promise<T> {
    this.server = server;
    return server.command(this.ns, this.command, {
      ...this.options,
      readPreference: this.readPreference,
      session
    }) as TODO_NODE_3286;
  }
}

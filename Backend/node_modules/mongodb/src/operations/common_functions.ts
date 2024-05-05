import type { Document } from '../bson';
import type { Collection } from '../collection';
import type { Db } from '../db';
import type { ReadPreference } from '../read_preference';
import type { ClientSession } from '../sessions';

/** @public */
export interface IndexInformationOptions {
  full?: boolean;
  readPreference?: ReadPreference;
  session?: ClientSession;
}
/**
 * Retrieves this collections index info.
 *
 * @param db - The Db instance on which to retrieve the index info.
 * @param name - The name of the collection.
 */
export async function indexInformation(db: Db, name: string): Promise<any>;
export async function indexInformation(
  db: Db,
  name: string,
  options?: IndexInformationOptions
): Promise<any>;
export async function indexInformation(
  db: Db,
  name: string,
  options?: IndexInformationOptions
): Promise<any> {
  if (options == null) {
    options = {};
  }
  // If we specified full information
  const full = options.full == null ? false : options.full;
  // Get the list of indexes of the specified collection
  const indexes = await db.collection(name).listIndexes(options).toArray();
  if (full) return indexes;

  const info: Record<string, Array<[string, unknown]>> = {};
  for (const index of indexes) {
    info[index.name] = Object.entries(index.key);
  }
  return info;
}

export function maybeAddIdToDocuments(
  coll: Collection,
  docs: Document[],
  options: { forceServerObjectId?: boolean }
): Document[];
export function maybeAddIdToDocuments(
  coll: Collection,
  docs: Document,
  options: { forceServerObjectId?: boolean }
): Document;
export function maybeAddIdToDocuments(
  coll: Collection,
  docOrDocs: Document[] | Document,
  options: { forceServerObjectId?: boolean }
): Document[] | Document {
  const forceServerObjectId =
    typeof options.forceServerObjectId === 'boolean'
      ? options.forceServerObjectId
      : coll.s.db.options?.forceServerObjectId;

  // no need to modify the docs if server sets the ObjectId
  if (forceServerObjectId === true) {
    return docOrDocs;
  }

  const transform = (doc: Document): Document => {
    if (doc._id == null) {
      doc._id = coll.s.pkFactory.createPk();
    }

    return doc;
  };
  return Array.isArray(docOrDocs) ? docOrDocs.map(transform) : transform(docOrDocs);
}

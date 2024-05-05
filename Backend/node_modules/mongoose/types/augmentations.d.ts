// this import is required so that types get merged instead of completely overwritten
import 'bson';

declare module 'bson' {
  interface ObjectId {
    /** Mongoose automatically adds a conveniency "_id" getter on the base ObjectId class */
    _id: this;
  }
}

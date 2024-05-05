import type { BSONSerializeOptions, Document, Long } from '../bson';
import * as BSON from '../bson';
import { MongoInvalidArgumentError, MongoRuntimeError } from '../error';
import { type ReadPreference } from '../read_preference';
import type { ClientSession } from '../sessions';
import type { CommandOptions } from './connection';
import {
  compress,
  Compressor,
  type CompressorName,
  uncompressibleCommands
} from './wire_protocol/compression';
import { OP_COMPRESSED, OP_MSG, OP_QUERY } from './wire_protocol/constants';

// Incrementing request id
let _requestId = 0;

// Query flags
const OPTS_TAILABLE_CURSOR = 2;
const OPTS_SECONDARY = 4;
const OPTS_OPLOG_REPLAY = 8;
const OPTS_NO_CURSOR_TIMEOUT = 16;
const OPTS_AWAIT_DATA = 32;
const OPTS_EXHAUST = 64;
const OPTS_PARTIAL = 128;

// Response flags
const CURSOR_NOT_FOUND = 1;
const QUERY_FAILURE = 2;
const SHARD_CONFIG_STALE = 4;
const AWAIT_CAPABLE = 8;

/** @internal */
export type WriteProtocolMessageType = OpQueryRequest | OpMsgRequest;

/** @internal */
export interface OpQueryOptions extends CommandOptions {
  socketTimeoutMS?: number;
  session?: ClientSession;
  documentsReturnedIn?: string;
  numberToSkip?: number;
  numberToReturn?: number;
  returnFieldSelector?: Document;
  pre32Limit?: number;
  serializeFunctions?: boolean;
  ignoreUndefined?: boolean;
  maxBsonSize?: number;
  checkKeys?: boolean;
  secondaryOk?: boolean;

  requestId?: number;
  moreToCome?: boolean;
  exhaustAllowed?: boolean;
}

/**************************************************************
 * QUERY
 **************************************************************/
/** @internal */
export class OpQueryRequest {
  ns: string;
  numberToSkip: number;
  numberToReturn: number;
  returnFieldSelector?: Document;
  requestId: number;
  pre32Limit?: number;
  serializeFunctions: boolean;
  ignoreUndefined: boolean;
  maxBsonSize: number;
  checkKeys: boolean;
  batchSize: number;
  tailable: boolean;
  secondaryOk: boolean;
  oplogReplay: boolean;
  noCursorTimeout: boolean;
  awaitData: boolean;
  exhaust: boolean;
  partial: boolean;

  constructor(public databaseName: string, public query: Document, options: OpQueryOptions) {
    // Basic options needed to be passed in
    // TODO(NODE-3483): Replace with MongoCommandError
    const ns = `${databaseName}.$cmd`;
    if (typeof databaseName !== 'string') {
      throw new MongoRuntimeError('Database name must be a string for a query');
    }
    // TODO(NODE-3483): Replace with MongoCommandError
    if (query == null) throw new MongoRuntimeError('A query document must be specified for query');

    // Validate that we are not passing 0x00 in the collection name
    if (ns.indexOf('\x00') !== -1) {
      // TODO(NODE-3483): Use MongoNamespace static method
      throw new MongoRuntimeError('Namespace cannot contain a null character');
    }

    // Basic options
    this.ns = ns;

    // Additional options
    this.numberToSkip = options.numberToSkip || 0;
    this.numberToReturn = options.numberToReturn || 0;
    this.returnFieldSelector = options.returnFieldSelector || undefined;
    this.requestId = options.requestId ?? OpQueryRequest.getRequestId();

    // special case for pre-3.2 find commands, delete ASAP
    this.pre32Limit = options.pre32Limit;

    // Serialization option
    this.serializeFunctions =
      typeof options.serializeFunctions === 'boolean' ? options.serializeFunctions : false;
    this.ignoreUndefined =
      typeof options.ignoreUndefined === 'boolean' ? options.ignoreUndefined : false;
    this.maxBsonSize = options.maxBsonSize || 1024 * 1024 * 16;
    this.checkKeys = typeof options.checkKeys === 'boolean' ? options.checkKeys : false;
    this.batchSize = this.numberToReturn;

    // Flags
    this.tailable = false;
    this.secondaryOk = typeof options.secondaryOk === 'boolean' ? options.secondaryOk : false;
    this.oplogReplay = false;
    this.noCursorTimeout = false;
    this.awaitData = false;
    this.exhaust = false;
    this.partial = false;
  }

  /** Assign next request Id. */
  incRequestId(): void {
    this.requestId = _requestId++;
  }

  /** Peek next request Id. */
  nextRequestId(): number {
    return _requestId + 1;
  }

  /** Increment then return next request Id. */
  static getRequestId(): number {
    return ++_requestId;
  }

  // Uses a single allocated buffer for the process, avoiding multiple memory allocations
  toBin(): Uint8Array[] {
    const buffers = [];
    let projection = null;

    // Set up the flags
    let flags = 0;
    if (this.tailable) {
      flags |= OPTS_TAILABLE_CURSOR;
    }

    if (this.secondaryOk) {
      flags |= OPTS_SECONDARY;
    }

    if (this.oplogReplay) {
      flags |= OPTS_OPLOG_REPLAY;
    }

    if (this.noCursorTimeout) {
      flags |= OPTS_NO_CURSOR_TIMEOUT;
    }

    if (this.awaitData) {
      flags |= OPTS_AWAIT_DATA;
    }

    if (this.exhaust) {
      flags |= OPTS_EXHAUST;
    }

    if (this.partial) {
      flags |= OPTS_PARTIAL;
    }

    // If batchSize is different to this.numberToReturn
    if (this.batchSize !== this.numberToReturn) this.numberToReturn = this.batchSize;

    // Allocate write protocol header buffer
    const header = Buffer.alloc(
      4 * 4 + // Header
        4 + // Flags
        Buffer.byteLength(this.ns) +
        1 + // namespace
        4 + // numberToSkip
        4 // numberToReturn
    );

    // Add header to buffers
    buffers.push(header);

    // Serialize the query
    const query = BSON.serialize(this.query, {
      checkKeys: this.checkKeys,
      serializeFunctions: this.serializeFunctions,
      ignoreUndefined: this.ignoreUndefined
    });

    // Add query document
    buffers.push(query);

    if (this.returnFieldSelector && Object.keys(this.returnFieldSelector).length > 0) {
      // Serialize the projection document
      projection = BSON.serialize(this.returnFieldSelector, {
        checkKeys: this.checkKeys,
        serializeFunctions: this.serializeFunctions,
        ignoreUndefined: this.ignoreUndefined
      });
      // Add projection document
      buffers.push(projection);
    }

    // Total message size
    const totalLength = header.length + query.length + (projection ? projection.length : 0);

    // Set up the index
    let index = 4;

    // Write total document length
    header[3] = (totalLength >> 24) & 0xff;
    header[2] = (totalLength >> 16) & 0xff;
    header[1] = (totalLength >> 8) & 0xff;
    header[0] = totalLength & 0xff;

    // Write header information requestId
    header[index + 3] = (this.requestId >> 24) & 0xff;
    header[index + 2] = (this.requestId >> 16) & 0xff;
    header[index + 1] = (this.requestId >> 8) & 0xff;
    header[index] = this.requestId & 0xff;
    index = index + 4;

    // Write header information responseTo
    header[index + 3] = (0 >> 24) & 0xff;
    header[index + 2] = (0 >> 16) & 0xff;
    header[index + 1] = (0 >> 8) & 0xff;
    header[index] = 0 & 0xff;
    index = index + 4;

    // Write header information OP_QUERY
    header[index + 3] = (OP_QUERY >> 24) & 0xff;
    header[index + 2] = (OP_QUERY >> 16) & 0xff;
    header[index + 1] = (OP_QUERY >> 8) & 0xff;
    header[index] = OP_QUERY & 0xff;
    index = index + 4;

    // Write header information flags
    header[index + 3] = (flags >> 24) & 0xff;
    header[index + 2] = (flags >> 16) & 0xff;
    header[index + 1] = (flags >> 8) & 0xff;
    header[index] = flags & 0xff;
    index = index + 4;

    // Write collection name
    index = index + header.write(this.ns, index, 'utf8') + 1;
    header[index - 1] = 0;

    // Write header information flags numberToSkip
    header[index + 3] = (this.numberToSkip >> 24) & 0xff;
    header[index + 2] = (this.numberToSkip >> 16) & 0xff;
    header[index + 1] = (this.numberToSkip >> 8) & 0xff;
    header[index] = this.numberToSkip & 0xff;
    index = index + 4;

    // Write header information flags numberToReturn
    header[index + 3] = (this.numberToReturn >> 24) & 0xff;
    header[index + 2] = (this.numberToReturn >> 16) & 0xff;
    header[index + 1] = (this.numberToReturn >> 8) & 0xff;
    header[index] = this.numberToReturn & 0xff;
    index = index + 4;

    // Return the buffers
    return buffers;
  }
}

/** @internal */
export interface MessageHeader {
  length: number;
  requestId: number;
  responseTo: number;
  opCode: number;
  fromCompressed?: boolean;
}

/** @internal */
export interface OpResponseOptions extends BSONSerializeOptions {
  documentsReturnedIn?: string | null;
}

/** @internal */
export class OpQueryResponse {
  parsed: boolean;
  raw: Buffer;
  data: Buffer;
  opts: OpResponseOptions;
  length: number;
  requestId: number;
  responseTo: number;
  opCode: number;
  fromCompressed?: boolean;
  responseFlags?: number;
  cursorId?: Long;
  startingFrom?: number;
  numberReturned?: number;
  documents: (Document | Buffer)[] = new Array(0);
  cursorNotFound?: boolean;
  queryFailure?: boolean;
  shardConfigStale?: boolean;
  awaitCapable?: boolean;
  useBigInt64: boolean;
  promoteLongs: boolean;
  promoteValues: boolean;
  promoteBuffers: boolean;
  bsonRegExp?: boolean;
  index?: number;

  /** moreToCome is an OP_MSG only concept */
  moreToCome = false;

  constructor(
    message: Buffer,
    msgHeader: MessageHeader,
    msgBody: Buffer,
    opts?: OpResponseOptions
  ) {
    this.parsed = false;
    this.raw = message;
    this.data = msgBody;
    this.opts = opts ?? {
      useBigInt64: false,
      promoteLongs: true,
      promoteValues: true,
      promoteBuffers: false,
      bsonRegExp: false
    };

    // Read the message header
    this.length = msgHeader.length;
    this.requestId = msgHeader.requestId;
    this.responseTo = msgHeader.responseTo;
    this.opCode = msgHeader.opCode;
    this.fromCompressed = msgHeader.fromCompressed;

    // Flag values
    this.useBigInt64 = typeof this.opts.useBigInt64 === 'boolean' ? this.opts.useBigInt64 : false;
    this.promoteLongs = typeof this.opts.promoteLongs === 'boolean' ? this.opts.promoteLongs : true;
    this.promoteValues =
      typeof this.opts.promoteValues === 'boolean' ? this.opts.promoteValues : true;
    this.promoteBuffers =
      typeof this.opts.promoteBuffers === 'boolean' ? this.opts.promoteBuffers : false;
    this.bsonRegExp = typeof this.opts.bsonRegExp === 'boolean' ? this.opts.bsonRegExp : false;
  }

  isParsed(): boolean {
    return this.parsed;
  }

  parse(options: OpResponseOptions): void {
    // Don't parse again if not needed
    if (this.parsed) return;
    options = options ?? {};

    // Allow the return of raw documents instead of parsing
    const raw = options.raw || false;
    const documentsReturnedIn = options.documentsReturnedIn || null;
    const useBigInt64 = options.useBigInt64 ?? this.opts.useBigInt64;
    const promoteLongs = options.promoteLongs ?? this.opts.promoteLongs;
    const promoteValues = options.promoteValues ?? this.opts.promoteValues;
    const promoteBuffers = options.promoteBuffers ?? this.opts.promoteBuffers;
    const bsonRegExp = options.bsonRegExp ?? this.opts.bsonRegExp;
    let bsonSize;

    // Set up the options
    const _options: BSONSerializeOptions = {
      useBigInt64,
      promoteLongs,
      promoteValues,
      promoteBuffers,
      bsonRegExp
    };

    // Position within OP_REPLY at which documents start
    // (See https://www.mongodb.com/docs/manual/reference/mongodb-wire-protocol/#wire-op-reply)
    this.index = 20;

    // Read the message body
    this.responseFlags = this.data.readInt32LE(0);
    this.cursorId = new BSON.Long(this.data.readInt32LE(4), this.data.readInt32LE(8));
    this.startingFrom = this.data.readInt32LE(12);
    this.numberReturned = this.data.readInt32LE(16);

    // Preallocate document array
    this.documents = new Array(this.numberReturned);

    this.cursorNotFound = (this.responseFlags & CURSOR_NOT_FOUND) !== 0;
    this.queryFailure = (this.responseFlags & QUERY_FAILURE) !== 0;
    this.shardConfigStale = (this.responseFlags & SHARD_CONFIG_STALE) !== 0;
    this.awaitCapable = (this.responseFlags & AWAIT_CAPABLE) !== 0;

    // Parse Body
    for (let i = 0; i < this.numberReturned; i++) {
      bsonSize =
        this.data[this.index] |
        (this.data[this.index + 1] << 8) |
        (this.data[this.index + 2] << 16) |
        (this.data[this.index + 3] << 24);

      // If we have raw results specified slice the return document
      if (raw) {
        this.documents[i] = this.data.slice(this.index, this.index + bsonSize);
      } else {
        this.documents[i] = BSON.deserialize(
          this.data.slice(this.index, this.index + bsonSize),
          _options
        );
      }

      // Adjust the index
      this.index = this.index + bsonSize;
    }

    if (this.documents.length === 1 && documentsReturnedIn != null && raw) {
      const fieldsAsRaw: Document = {};
      fieldsAsRaw[documentsReturnedIn] = true;
      _options.fieldsAsRaw = fieldsAsRaw;

      const doc = BSON.deserialize(this.documents[0] as Buffer, _options);
      this.documents = [doc];
    }

    // Set parsed
    this.parsed = true;
  }
}

// Implementation of OP_MSG spec:
// https://github.com/mongodb/specifications/blob/master/source/message/OP_MSG.rst
//
// struct Section {
//   uint8 payloadType;
//   union payload {
//       document  document; // payloadType == 0
//       struct sequence { // payloadType == 1
//           int32      size;
//           cstring    identifier;
//           document*  documents;
//       };
//   };
// };

// struct OP_MSG {
//   struct MsgHeader {
//       int32  messageLength;
//       int32  requestID;
//       int32  responseTo;
//       int32  opCode = 2013;
//   };
//   uint32      flagBits;
//   Section+    sections;
//   [uint32     checksum;]
// };

// Msg Flags
const OPTS_CHECKSUM_PRESENT = 1;
const OPTS_MORE_TO_COME = 2;
const OPTS_EXHAUST_ALLOWED = 1 << 16;

/** @internal */
export interface OpMsgOptions {
  requestId: number;
  serializeFunctions: boolean;
  ignoreUndefined: boolean;
  checkKeys: boolean;
  maxBsonSize: number;
  moreToCome: boolean;
  exhaustAllowed: boolean;
  readPreference: ReadPreference;
}

/** @internal */
export class OpMsgRequest {
  requestId: number;
  serializeFunctions: boolean;
  ignoreUndefined: boolean;
  checkKeys: boolean;
  maxBsonSize: number;
  checksumPresent: boolean;
  moreToCome: boolean;
  exhaustAllowed: boolean;

  constructor(
    public databaseName: string,
    public command: Document,
    public options: OpQueryOptions
  ) {
    // Basic options needed to be passed in
    if (command == null)
      throw new MongoInvalidArgumentError('Query document must be specified for query');

    // Basic options
    this.command.$db = databaseName;

    // Ensure empty options
    this.options = options ?? {};

    // Additional options
    this.requestId = options.requestId ? options.requestId : OpMsgRequest.getRequestId();

    // Serialization option
    this.serializeFunctions =
      typeof options.serializeFunctions === 'boolean' ? options.serializeFunctions : false;
    this.ignoreUndefined =
      typeof options.ignoreUndefined === 'boolean' ? options.ignoreUndefined : false;
    this.checkKeys = typeof options.checkKeys === 'boolean' ? options.checkKeys : false;
    this.maxBsonSize = options.maxBsonSize || 1024 * 1024 * 16;

    // flags
    this.checksumPresent = false;
    this.moreToCome = options.moreToCome || false;
    this.exhaustAllowed =
      typeof options.exhaustAllowed === 'boolean' ? options.exhaustAllowed : false;
  }

  toBin(): Buffer[] {
    const buffers: Buffer[] = [];
    let flags = 0;

    if (this.checksumPresent) {
      flags |= OPTS_CHECKSUM_PRESENT;
    }

    if (this.moreToCome) {
      flags |= OPTS_MORE_TO_COME;
    }

    if (this.exhaustAllowed) {
      flags |= OPTS_EXHAUST_ALLOWED;
    }

    const header = Buffer.alloc(
      4 * 4 + // Header
        4 // Flags
    );

    buffers.push(header);

    let totalLength = header.length;
    const command = this.command;
    totalLength += this.makeDocumentSegment(buffers, command);

    header.writeInt32LE(totalLength, 0); // messageLength
    header.writeInt32LE(this.requestId, 4); // requestID
    header.writeInt32LE(0, 8); // responseTo
    header.writeInt32LE(OP_MSG, 12); // opCode
    header.writeUInt32LE(flags, 16); // flags
    return buffers;
  }

  makeDocumentSegment(buffers: Uint8Array[], document: Document): number {
    const payloadTypeBuffer = Buffer.alloc(1);
    payloadTypeBuffer[0] = 0;

    const documentBuffer = this.serializeBson(document);
    buffers.push(payloadTypeBuffer);
    buffers.push(documentBuffer);

    return payloadTypeBuffer.length + documentBuffer.length;
  }

  serializeBson(document: Document): Uint8Array {
    return BSON.serialize(document, {
      checkKeys: this.checkKeys,
      serializeFunctions: this.serializeFunctions,
      ignoreUndefined: this.ignoreUndefined
    });
  }

  static getRequestId(): number {
    _requestId = (_requestId + 1) & 0x7fffffff;
    return _requestId;
  }
}

/** @internal */
export class OpMsgResponse {
  parsed: boolean;
  raw: Buffer;
  data: Buffer;
  opts: OpResponseOptions;
  length: number;
  requestId: number;
  responseTo: number;
  opCode: number;
  fromCompressed?: boolean;
  responseFlags: number;
  checksumPresent: boolean;
  /** Indicates the server will be sending more responses on this connection */
  moreToCome: boolean;
  exhaustAllowed: boolean;
  useBigInt64: boolean;
  promoteLongs: boolean;
  promoteValues: boolean;
  promoteBuffers: boolean;
  bsonRegExp: boolean;
  documents: (Document | Buffer)[];
  index?: number;

  constructor(
    message: Buffer,
    msgHeader: MessageHeader,
    msgBody: Buffer,
    opts?: OpResponseOptions
  ) {
    this.parsed = false;
    this.raw = message;
    this.data = msgBody;
    this.opts = opts ?? {
      useBigInt64: false,
      promoteLongs: true,
      promoteValues: true,
      promoteBuffers: false,
      bsonRegExp: false
    };

    // Read the message header
    this.length = msgHeader.length;
    this.requestId = msgHeader.requestId;
    this.responseTo = msgHeader.responseTo;
    this.opCode = msgHeader.opCode;
    this.fromCompressed = msgHeader.fromCompressed;

    // Read response flags
    this.responseFlags = msgBody.readInt32LE(0);
    this.checksumPresent = (this.responseFlags & OPTS_CHECKSUM_PRESENT) !== 0;
    this.moreToCome = (this.responseFlags & OPTS_MORE_TO_COME) !== 0;
    this.exhaustAllowed = (this.responseFlags & OPTS_EXHAUST_ALLOWED) !== 0;
    this.useBigInt64 = typeof this.opts.useBigInt64 === 'boolean' ? this.opts.useBigInt64 : false;
    this.promoteLongs = typeof this.opts.promoteLongs === 'boolean' ? this.opts.promoteLongs : true;
    this.promoteValues =
      typeof this.opts.promoteValues === 'boolean' ? this.opts.promoteValues : true;
    this.promoteBuffers =
      typeof this.opts.promoteBuffers === 'boolean' ? this.opts.promoteBuffers : false;
    this.bsonRegExp = typeof this.opts.bsonRegExp === 'boolean' ? this.opts.bsonRegExp : false;

    this.documents = [];
  }

  isParsed(): boolean {
    return this.parsed;
  }

  parse(options: OpResponseOptions): void {
    // Don't parse again if not needed
    if (this.parsed) return;
    options = options ?? {};

    this.index = 4;
    // Allow the return of raw documents instead of parsing
    const raw = options.raw || false;
    const documentsReturnedIn = options.documentsReturnedIn || null;
    const useBigInt64 = options.useBigInt64 ?? this.opts.useBigInt64;
    const promoteLongs = options.promoteLongs ?? this.opts.promoteLongs;
    const promoteValues = options.promoteValues ?? this.opts.promoteValues;
    const promoteBuffers = options.promoteBuffers ?? this.opts.promoteBuffers;
    const bsonRegExp = options.bsonRegExp ?? this.opts.bsonRegExp;
    const validation = this.parseBsonSerializationOptions(options);

    // Set up the options
    const bsonOptions: BSONSerializeOptions = {
      useBigInt64,
      promoteLongs,
      promoteValues,
      promoteBuffers,
      bsonRegExp,
      validation
      // Due to the strictness of the BSON libraries validation option we need this cast
    } as BSONSerializeOptions & { validation: { utf8: { writeErrors: boolean } } };

    while (this.index < this.data.length) {
      const payloadType = this.data.readUInt8(this.index++);
      if (payloadType === 0) {
        const bsonSize = this.data.readUInt32LE(this.index);
        const bin = this.data.slice(this.index, this.index + bsonSize);
        this.documents.push(raw ? bin : BSON.deserialize(bin, bsonOptions));
        this.index += bsonSize;
      } else if (payloadType === 1) {
        // It was decided that no driver makes use of payload type 1

        // TODO(NODE-3483): Replace with MongoDeprecationError
        throw new MongoRuntimeError('OP_MSG Payload Type 1 detected unsupported protocol');
      }
    }

    if (this.documents.length === 1 && documentsReturnedIn != null && raw) {
      const fieldsAsRaw: Document = {};
      fieldsAsRaw[documentsReturnedIn] = true;
      bsonOptions.fieldsAsRaw = fieldsAsRaw;
      const doc = BSON.deserialize(this.documents[0] as Buffer, bsonOptions);
      this.documents = [doc];
    }

    this.parsed = true;
  }

  parseBsonSerializationOptions({ enableUtf8Validation }: BSONSerializeOptions): {
    utf8: { writeErrors: false } | false;
  } {
    if (enableUtf8Validation === false) {
      return { utf8: false };
    }

    return { utf8: { writeErrors: false } };
  }
}

const MESSAGE_HEADER_SIZE = 16;
const COMPRESSION_DETAILS_SIZE = 9; // originalOpcode + uncompressedSize, compressorID

/**
 * @internal
 *
 * An OP_COMPRESSED request wraps either an OP_QUERY or OP_MSG message.
 */
export class OpCompressedRequest {
  constructor(
    private command: WriteProtocolMessageType,
    private options: { zlibCompressionLevel: number; agreedCompressor: CompressorName }
  ) {}

  // Return whether a command contains an uncompressible command term
  // Will return true if command contains no uncompressible command terms
  static canCompress(command: WriteProtocolMessageType) {
    const commandDoc = command instanceof OpMsgRequest ? command.command : command.query;
    const commandName = Object.keys(commandDoc)[0];
    return !uncompressibleCommands.has(commandName);
  }

  async toBin(): Promise<Buffer[]> {
    const concatenatedOriginalCommandBuffer = Buffer.concat(this.command.toBin());
    // otherwise, compress the message
    const messageToBeCompressed = concatenatedOriginalCommandBuffer.slice(MESSAGE_HEADER_SIZE);

    // Extract information needed for OP_COMPRESSED from the uncompressed message
    const originalCommandOpCode = concatenatedOriginalCommandBuffer.readInt32LE(12);

    // Compress the message body
    const compressedMessage = await compress(this.options, messageToBeCompressed);
    // Create the msgHeader of OP_COMPRESSED
    const msgHeader = Buffer.alloc(MESSAGE_HEADER_SIZE);
    msgHeader.writeInt32LE(
      MESSAGE_HEADER_SIZE + COMPRESSION_DETAILS_SIZE + compressedMessage.length,
      0
    ); // messageLength
    msgHeader.writeInt32LE(this.command.requestId, 4); // requestID
    msgHeader.writeInt32LE(0, 8); // responseTo (zero)
    msgHeader.writeInt32LE(OP_COMPRESSED, 12); // opCode

    // Create the compression details of OP_COMPRESSED
    const compressionDetails = Buffer.alloc(COMPRESSION_DETAILS_SIZE);
    compressionDetails.writeInt32LE(originalCommandOpCode, 0); // originalOpcode
    compressionDetails.writeInt32LE(messageToBeCompressed.length, 4); // Size of the uncompressed compressedMessage, excluding the MsgHeader
    compressionDetails.writeUInt8(Compressor[this.options.agreedCompressor], 8); // compressorID
    return [msgHeader, compressionDetails, compressedMessage];
  }
}

import { type InspectFn, defaultInspect, isAnyArrayBuffer, isUint8Array } from './parser/utils';
import type { EJSONOptions } from './extended_json';
import { BSONError } from './error';
import { BSON_BINARY_SUBTYPE_UUID_NEW } from './constants';
import { ByteUtils } from './utils/byte_utils';
import { BSONValue } from './bson_value';

/** @public */
export type BinarySequence = Uint8Array | number[];

/** @public */
export interface BinaryExtendedLegacy {
  $type: string;
  $binary: string;
}

/** @public */
export interface BinaryExtended {
  $binary: {
    subType: string;
    base64: string;
  };
}

/**
 * A class representation of the BSON Binary type.
 * @public
 * @category BSONType
 */
export class Binary extends BSONValue {
  get _bsontype(): 'Binary' {
    return 'Binary';
  }

  /**
   * Binary default subtype
   * @internal
   */
  private static readonly BSON_BINARY_SUBTYPE_DEFAULT = 0;

  /** Initial buffer default size */
  static readonly BUFFER_SIZE = 256;
  /** Default BSON type */
  static readonly SUBTYPE_DEFAULT = 0;
  /** Function BSON type */
  static readonly SUBTYPE_FUNCTION = 1;
  /** Byte Array BSON type */
  static readonly SUBTYPE_BYTE_ARRAY = 2;
  /** Deprecated UUID BSON type @deprecated Please use SUBTYPE_UUID */
  static readonly SUBTYPE_UUID_OLD = 3;
  /** UUID BSON type */
  static readonly SUBTYPE_UUID = 4;
  /** MD5 BSON type */
  static readonly SUBTYPE_MD5 = 5;
  /** Encrypted BSON type */
  static readonly SUBTYPE_ENCRYPTED = 6;
  /** Column BSON type */
  static readonly SUBTYPE_COLUMN = 7;
  /** Sensitive BSON type */
  static readonly SUBTYPE_SENSITIVE = 8;
  /** User BSON type */
  static readonly SUBTYPE_USER_DEFINED = 128;

  buffer!: Uint8Array;
  sub_type!: number;
  position!: number;

  /**
   * Create a new Binary instance.
   * @param buffer - a buffer object containing the binary data.
   * @param subType - the option binary type.
   */
  constructor(buffer?: BinarySequence, subType?: number) {
    super();
    if (
      !(buffer == null) &&
      typeof buffer === 'string' &&
      !ArrayBuffer.isView(buffer) &&
      !isAnyArrayBuffer(buffer) &&
      !Array.isArray(buffer)
    ) {
      throw new BSONError('Binary can only be constructed from Uint8Array or number[]');
    }

    this.sub_type = subType ?? Binary.BSON_BINARY_SUBTYPE_DEFAULT;

    if (buffer == null) {
      // create an empty binary buffer
      this.buffer = ByteUtils.allocate(Binary.BUFFER_SIZE);
      this.position = 0;
    } else {
      this.buffer = Array.isArray(buffer)
        ? ByteUtils.fromNumberArray(buffer)
        : ByteUtils.toLocalBufferType(buffer);
      this.position = this.buffer.byteLength;
    }
  }

  /**
   * Updates this binary with byte_value.
   *
   * @param byteValue - a single byte we wish to write.
   */
  put(byteValue: string | number | Uint8Array | number[]): void {
    // If it's a string and a has more than one character throw an error
    if (typeof byteValue === 'string' && byteValue.length !== 1) {
      throw new BSONError('only accepts single character String');
    } else if (typeof byteValue !== 'number' && byteValue.length !== 1)
      throw new BSONError('only accepts single character Uint8Array or Array');

    // Decode the byte value once
    let decodedByte: number;
    if (typeof byteValue === 'string') {
      decodedByte = byteValue.charCodeAt(0);
    } else if (typeof byteValue === 'number') {
      decodedByte = byteValue;
    } else {
      decodedByte = byteValue[0];
    }

    if (decodedByte < 0 || decodedByte > 255) {
      throw new BSONError('only accepts number in a valid unsigned byte range 0-255');
    }

    if (this.buffer.byteLength > this.position) {
      this.buffer[this.position++] = decodedByte;
    } else {
      const newSpace = ByteUtils.allocate(Binary.BUFFER_SIZE + this.buffer.length);
      newSpace.set(this.buffer, 0);
      this.buffer = newSpace;
      this.buffer[this.position++] = decodedByte;
    }
  }

  /**
   * Writes a buffer to the binary.
   *
   * @param sequence - a string or buffer to be written to the Binary BSON object.
   * @param offset - specify the binary of where to write the content.
   */
  write(sequence: BinarySequence, offset: number): void {
    offset = typeof offset === 'number' ? offset : this.position;

    // If the buffer is to small let's extend the buffer
    if (this.buffer.byteLength < offset + sequence.length) {
      const newSpace = ByteUtils.allocate(this.buffer.byteLength + sequence.length);
      newSpace.set(this.buffer, 0);

      // Assign the new buffer
      this.buffer = newSpace;
    }

    if (ArrayBuffer.isView(sequence)) {
      this.buffer.set(ByteUtils.toLocalBufferType(sequence), offset);
      this.position =
        offset + sequence.byteLength > this.position ? offset + sequence.length : this.position;
    } else if (typeof sequence === 'string') {
      throw new BSONError('input cannot be string');
    }
  }

  /**
   * Reads **length** bytes starting at **position**.
   *
   * @param position - read from the given position in the Binary.
   * @param length - the number of bytes to read.
   */
  read(position: number, length: number): BinarySequence {
    length = length && length > 0 ? length : this.position;

    // Let's return the data based on the type we have
    return this.buffer.slice(position, position + length);
  }

  /** returns a view of the binary value as a Uint8Array */
  value(): Uint8Array {
    // Optimize to serialize for the situation where the data == size of buffer
    return this.buffer.length === this.position
      ? this.buffer
      : this.buffer.subarray(0, this.position);
  }

  /** the length of the binary sequence */
  length(): number {
    return this.position;
  }

  toJSON(): string {
    return ByteUtils.toBase64(this.buffer.subarray(0, this.position));
  }

  toString(encoding?: 'hex' | 'base64' | 'utf8' | 'utf-8'): string {
    if (encoding === 'hex') return ByteUtils.toHex(this.buffer.subarray(0, this.position));
    if (encoding === 'base64') return ByteUtils.toBase64(this.buffer.subarray(0, this.position));
    if (encoding === 'utf8' || encoding === 'utf-8')
      return ByteUtils.toUTF8(this.buffer, 0, this.position, false);
    return ByteUtils.toUTF8(this.buffer, 0, this.position, false);
  }

  /** @internal */
  toExtendedJSON(options?: EJSONOptions): BinaryExtendedLegacy | BinaryExtended {
    options = options || {};
    const base64String = ByteUtils.toBase64(this.buffer);

    const subType = Number(this.sub_type).toString(16);
    if (options.legacy) {
      return {
        $binary: base64String,
        $type: subType.length === 1 ? '0' + subType : subType
      };
    }
    return {
      $binary: {
        base64: base64String,
        subType: subType.length === 1 ? '0' + subType : subType
      }
    };
  }

  toUUID(): UUID {
    if (this.sub_type === Binary.SUBTYPE_UUID) {
      return new UUID(this.buffer.slice(0, this.position));
    }

    throw new BSONError(
      `Binary sub_type "${this.sub_type}" is not supported for converting to UUID. Only "${Binary.SUBTYPE_UUID}" is currently supported.`
    );
  }

  /** Creates an Binary instance from a hex digit string */
  static createFromHexString(hex: string, subType?: number): Binary {
    return new Binary(ByteUtils.fromHex(hex), subType);
  }

  /** Creates an Binary instance from a base64 string */
  static createFromBase64(base64: string, subType?: number): Binary {
    return new Binary(ByteUtils.fromBase64(base64), subType);
  }

  /** @internal */
  static fromExtendedJSON(
    doc: BinaryExtendedLegacy | BinaryExtended | UUIDExtended,
    options?: EJSONOptions
  ): Binary {
    options = options || {};
    let data: Uint8Array | undefined;
    let type;
    if ('$binary' in doc) {
      if (options.legacy && typeof doc.$binary === 'string' && '$type' in doc) {
        type = doc.$type ? parseInt(doc.$type, 16) : 0;
        data = ByteUtils.fromBase64(doc.$binary);
      } else {
        if (typeof doc.$binary !== 'string') {
          type = doc.$binary.subType ? parseInt(doc.$binary.subType, 16) : 0;
          data = ByteUtils.fromBase64(doc.$binary.base64);
        }
      }
    } else if ('$uuid' in doc) {
      type = 4;
      data = UUID.bytesFromString(doc.$uuid);
    }
    if (!data) {
      throw new BSONError(`Unexpected Binary Extended JSON format ${JSON.stringify(doc)}`);
    }
    return type === BSON_BINARY_SUBTYPE_UUID_NEW ? new UUID(data) : new Binary(data, type);
  }

  inspect(depth?: number, options?: unknown, inspect?: InspectFn): string {
    inspect ??= defaultInspect;
    const base64 = ByteUtils.toBase64(this.buffer.subarray(0, this.position));
    const base64Arg = inspect(base64, options);
    const subTypeArg = inspect(this.sub_type, options);
    return `Binary.createFromBase64(${base64Arg}, ${subTypeArg})`;
  }
}

/** @public */
export type UUIDExtended = {
  $uuid: string;
};

const UUID_BYTE_LENGTH = 16;
const UUID_WITHOUT_DASHES = /^[0-9A-F]{32}$/i;
const UUID_WITH_DASHES = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i;

/**
 * A class representation of the BSON UUID type.
 * @public
 */
export class UUID extends Binary {
  /**
   * Create a UUID type
   *
   * When the argument to the constructor is omitted a random v4 UUID will be generated.
   *
   * @param input - Can be a 32 or 36 character hex string (dashes excluded/included) or a 16 byte binary Buffer.
   */
  constructor(input?: string | Uint8Array | UUID) {
    let bytes: Uint8Array;
    if (input == null) {
      bytes = UUID.generate();
    } else if (input instanceof UUID) {
      bytes = ByteUtils.toLocalBufferType(new Uint8Array(input.buffer));
    } else if (ArrayBuffer.isView(input) && input.byteLength === UUID_BYTE_LENGTH) {
      bytes = ByteUtils.toLocalBufferType(input);
    } else if (typeof input === 'string') {
      bytes = UUID.bytesFromString(input);
    } else {
      throw new BSONError(
        'Argument passed in UUID constructor must be a UUID, a 16 byte Buffer or a 32/36 character hex string (dashes excluded/included, format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).'
      );
    }
    super(bytes, BSON_BINARY_SUBTYPE_UUID_NEW);
  }

  /**
   * The UUID bytes
   * @readonly
   */
  get id(): Uint8Array {
    return this.buffer;
  }

  set id(value: Uint8Array) {
    this.buffer = value;
  }

  /**
   * Returns the UUID id as a 32 or 36 character hex string representation, excluding/including dashes (defaults to 36 character dash separated)
   * @param includeDashes - should the string exclude dash-separators.
   */
  toHexString(includeDashes = true): string {
    if (includeDashes) {
      return [
        ByteUtils.toHex(this.buffer.subarray(0, 4)),
        ByteUtils.toHex(this.buffer.subarray(4, 6)),
        ByteUtils.toHex(this.buffer.subarray(6, 8)),
        ByteUtils.toHex(this.buffer.subarray(8, 10)),
        ByteUtils.toHex(this.buffer.subarray(10, 16))
      ].join('-');
    }
    return ByteUtils.toHex(this.buffer);
  }

  /**
   * Converts the id into a 36 character (dashes included) hex string, unless a encoding is specified.
   */
  toString(encoding?: 'hex' | 'base64'): string {
    if (encoding === 'hex') return ByteUtils.toHex(this.id);
    if (encoding === 'base64') return ByteUtils.toBase64(this.id);
    return this.toHexString();
  }

  /**
   * Converts the id into its JSON string representation.
   * A 36 character (dashes included) hex string in the format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   */
  toJSON(): string {
    return this.toHexString();
  }

  /**
   * Compares the equality of this UUID with `otherID`.
   *
   * @param otherId - UUID instance to compare against.
   */
  equals(otherId: string | Uint8Array | UUID): boolean {
    if (!otherId) {
      return false;
    }

    if (otherId instanceof UUID) {
      return ByteUtils.equals(otherId.id, this.id);
    }

    try {
      return ByteUtils.equals(new UUID(otherId).id, this.id);
    } catch {
      return false;
    }
  }

  /**
   * Creates a Binary instance from the current UUID.
   */
  toBinary(): Binary {
    return new Binary(this.id, Binary.SUBTYPE_UUID);
  }

  /**
   * Generates a populated buffer containing a v4 uuid
   */
  static generate(): Uint8Array {
    const bytes = ByteUtils.randomBytes(UUID_BYTE_LENGTH);

    // Per 4.4, set bits for version and `clock_seq_hi_and_reserved`
    // Kindly borrowed from https://github.com/uuidjs/uuid/blob/master/src/v4.js
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    return bytes;
  }

  /**
   * Checks if a value is a valid bson UUID
   * @param input - UUID, string or Buffer to validate.
   */
  static isValid(input: string | Uint8Array | UUID | Binary): boolean {
    if (!input) {
      return false;
    }

    if (typeof input === 'string') {
      return UUID.isValidUUIDString(input);
    }

    if (isUint8Array(input)) {
      return input.byteLength === UUID_BYTE_LENGTH;
    }

    return (
      input._bsontype === 'Binary' &&
      input.sub_type === this.SUBTYPE_UUID &&
      input.buffer.byteLength === 16
    );
  }

  /**
   * Creates an UUID from a hex string representation of an UUID.
   * @param hexString - 32 or 36 character hex string (dashes excluded/included).
   */
  static override createFromHexString(hexString: string): UUID {
    const buffer = UUID.bytesFromString(hexString);
    return new UUID(buffer);
  }

  /** Creates an UUID from a base64 string representation of an UUID. */
  static override createFromBase64(base64: string): UUID {
    return new UUID(ByteUtils.fromBase64(base64));
  }

  /** @internal */
  static bytesFromString(representation: string) {
    if (!UUID.isValidUUIDString(representation)) {
      throw new BSONError(
        'UUID string representation must be 32 hex digits or canonical hyphenated representation'
      );
    }
    return ByteUtils.fromHex(representation.replace(/-/g, ''));
  }

  /**
   * @internal
   *
   * Validates a string to be a hex digit sequence with or without dashes.
   * The canonical hyphenated representation of a uuid is hex in 8-4-4-4-12 groups.
   */
  static isValidUUIDString(representation: string) {
    return UUID_WITHOUT_DASHES.test(representation) || UUID_WITH_DASHES.test(representation);
  }

  /**
   * Converts to a string representation of this Id.
   *
   * @returns return the 36 character hex string representation.
   *
   */
  inspect(depth?: number, options?: unknown, inspect?: InspectFn): string {
    inspect ??= defaultInspect;
    return `new UUID(${inspect(this.toHexString(), options)})`;
  }
}

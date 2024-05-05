const bcrypt = require('../bcrypt')

test('salt_length', () => {
    const salt = bcrypt.genSaltSync(13);
    expect(salt).toHaveLength(29);
    const [_, version, rounds] = salt.split('$');
    expect(version).toStrictEqual('2b')
    expect(rounds).toStrictEqual('13')
})

test('salt_no_params', () => {
    const salt = bcrypt.genSaltSync();
    const [_, version, rounds] = salt.split('$');
    expect(version).toStrictEqual('2b')
    expect(rounds).toStrictEqual('10')
})

test('salt_rounds_is_string_number', () => {
    expect(() => bcrypt.genSaltSync('10')).toThrowError('rounds must be a number');
})

test('salt_rounds_is_NaN', () => {
    expect(() => bcrypt.genSaltSync('b')).toThrowError("rounds must be a number");
})

test('salt_minor_a', () => {
    const salt = bcrypt.genSaltSync(10, 'a');
    const [_, version, rounds] = salt.split('$');
    expect(version).toStrictEqual('2a')
    expect(rounds).toStrictEqual('10')
})

test('salt_minor_b', () => {
    const salt = bcrypt.genSaltSync(10, 'b');
    const [_, version, rounds] = salt.split('$');
    expect(version).toStrictEqual('2b')
    expect(rounds).toStrictEqual('10')
})

test('hash', () => {
    expect(() => bcrypt.hashSync('password', bcrypt.genSaltSync(10))).not.toThrow()
})

test('hash_rounds', () => {
    const hash = bcrypt.hashSync('password', 8);
    expect(bcrypt.getRounds(hash)).toStrictEqual(8)
})

test('hash_empty_string', () => {
    expect(() => bcrypt.hashSync('', bcrypt.genSaltSync(10))).not.toThrow();
    expect(() => bcrypt.hashSync('password', '')).toThrowError('Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue');
    expect(() => bcrypt.hashSync('', '')).toThrowError('Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue');
})

test('hash_pw_no_params', () => {
    expect(() => bcrypt.hashSync()).toThrow('data and salt arguments required');
})

test('hash_pw_one_param', () => {
    expect(() => bcrypt.hashSync('password')).toThrow('data and salt arguments required');
})

test('hash_pw_not_hash_str', () => {
    expect(() => bcrypt.hashSync('password', {})).toThrow("data must be a string or Buffer and salt must either be a salt string or a number of rounds")
})

test('hash_salt_validity', () => {
    expect(2);
    expect(bcrypt.hashSync('password', '$2a$10$somesaltyvaluertsetrse')).toBeDefined()
    expect(() => bcrypt.hashSync('password', 'some$value')).toThrow('Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue')
})

test('verify_salt', () => {
    const salt = bcrypt.genSaltSync(10);
    const split_salt = salt.split('$');
    expect(split_salt[1]).toStrictEqual('2b')
    expect(split_salt[2]).toStrictEqual('10')
})

test('verify_salt_min_rounds', () => {
    const salt = bcrypt.genSaltSync(1);
    const split_salt = salt.split('$');
    expect(split_salt[1]).toStrictEqual('2b')
    expect(split_salt[2]).toStrictEqual('04')
})

test('verify_salt_max_rounds', () => {
    const salt = bcrypt.genSaltSync(100);
    const split_salt = salt.split('$');
    expect(split_salt[1]).toStrictEqual('2b')
    expect(split_salt[2]).toStrictEqual('31')
})

test('hash_compare', () => {
    const salt = bcrypt.genSaltSync(10);
    expect(29).toStrictEqual(salt.length)
    const hash = bcrypt.hashSync("test", salt);
    expect(bcrypt.compareSync("test", hash)).toBeDefined()
    expect(!(bcrypt.compareSync("blah", hash))).toBeDefined()
})

test('hash_compare_empty_strings', () => {
    expect(!(bcrypt.compareSync("", "password"))).toBeDefined()
    expect(!(bcrypt.compareSync("", ""))).toBeDefined()
    expect(!(bcrypt.compareSync("password", ""))).toBeDefined()
})

test('hash_compare_invalid_strings', () => {
    const fullString = 'envy1362987212538';
    const hash = '$2a$10$XOPbrlUPQdwdJUpSrIF6X.LbE14qsMmKGhM1A8W9iqaG3vv1BD7WC';
    const wut = ':';
    expect(bcrypt.compareSync(fullString, hash)).toBe(true);
    expect(bcrypt.compareSync(fullString, wut)).toBe(false);
})

test('getRounds', () => {
    const hash = bcrypt.hashSync("test", bcrypt.genSaltSync(9));
    expect(9).toStrictEqual(bcrypt.getRounds(hash))
})

test('getRounds', () => {
    const hash = bcrypt.hashSync("test", bcrypt.genSaltSync(9));
    expect(9).toStrictEqual(bcrypt.getRounds(hash))
    expect(() => bcrypt.getRounds('')).toThrow("invalid hash provided");
});

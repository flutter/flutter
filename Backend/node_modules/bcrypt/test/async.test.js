const bcrypt = require('../bcrypt');

test('salt_length', done => {
    expect.assertions(1);
    bcrypt.genSalt(10, function (err, salt) {
        expect(salt).toHaveLength(29);
        done();
    });
})

test('salt_only_cb', () => {
    expect.assertions(1);
    expect(() => {
        bcrypt.genSalt((err, salt) => {
        });
    }).not.toThrow();
})

test('salt_rounds_is_string_number', done => {
    expect.assertions(2);
    bcrypt.genSalt('10', void 0, function (err, salt) {
        expect(err instanceof Error).toBe(true)
        expect(err.message).toBe('rounds must be a number')
        done();
    });
})

test('salt_rounds_is_string_non_number', done => {
    expect.assertions(2);
    bcrypt.genSalt('z', function (err, salt) {
        expect(err instanceof Error).toBe(true)
        expect(err.message).toBe('rounds must be a number')
        done();
    });
})

test('salt_minor', done => {
    expect.assertions(3);
    bcrypt.genSalt(10, 'a', function (err, value) {
        expect(value).toHaveLength(29);
        const [_, minor, salt] = value.split('$');
        expect(minor).toEqual('2a');
        expect(salt).toEqual('10');
        done();
    });
})

test('salt_minor_b', done => {
    expect.assertions(3);
    bcrypt.genSalt(10, 'b', function (err, value) {
        expect(value).toHaveLength(29);
        const [_, minor, salt] = value.split('$');
        expect(minor).toEqual('2b');
        expect(salt).toEqual('10');
        done();
    });
})

test('hash', done => {
    expect.assertions(2);
    bcrypt.genSalt(10, function (err, salt) {
        bcrypt.hash('password', salt, function (err, res) {
            expect(res).toBeDefined();
            expect(err).toBeUndefined();
            done();
        });
    });
})

test('hash_rounds', done => {
    expect.assertions(1);
    bcrypt.hash('bacon', 8, function (err, hash) {
        expect(bcrypt.getRounds(hash)).toEqual(8);
        done();
    });
})

test('hash_empty_strings', done => {
    expect.assertions(1);
    bcrypt.genSalt(10, function (err, salt) {
        bcrypt.hash('', salt, function (err, res) {
            expect(res).toBeDefined();
            done();
        });
    });
})

test('hash_fails_with_empty_salt', done => {
    expect.assertions(1);
    bcrypt.hash('', '', function (err, res) {
        expect(err.message).toBe('Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue')
        done();
    });
})

test('hash_no_params', done => {
    expect.assertions(1);
    bcrypt.hash(function (err, hash) {
        expect(err.message).toBe('data must be a string or Buffer and salt must either be a salt string or a number of rounds')
        done();
    });
})

test('hash_one_param', done => {
    expect.assertions(1);
    bcrypt.hash('password', function (err, hash) {
        expect(err.message).toBe('data must be a string or Buffer and salt must either be a salt string or a number of rounds');
        done();
    });
})

test('hash_salt_validity', done => {
    expect.assertions(2);
    bcrypt.hash('password', '$2a$10$somesaltyvaluertsetrse', function (err, enc) {
        expect(err).toBeUndefined();
        bcrypt.hash('password', 'some$value', function (err, enc) {
            expect(err.message).toBe("Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue");
            done();
        });
    });
})

test('verify_salt', done => {
    expect.assertions(2);
    bcrypt.genSalt(10, function (err, value) {
        const [_, version, rounds] = value.split('$');
        expect(version).toEqual('2b');
        expect(rounds).toEqual('10');
        done();
    });
})

test('verify_salt_min_rounds', done => {
    expect.assertions(2);
    bcrypt.genSalt(1, function (err, value) {
        const [_, version, rounds] = value.split('$');
        expect(version).toEqual('2b');
        expect(rounds).toEqual('04');
        done();
    });
})

test('verify_salt_max_rounds', done => {
    expect.assertions(2);
    bcrypt.genSalt(100, function (err, value) {
        const [_, version, rounds] = value.split('$');
        expect(version).toEqual('2b');
        expect(rounds).toEqual('31');
        done();
    });
})

test('hash_compare', done => {
    expect.assertions(2);
    bcrypt.genSalt(10, function (err, salt) {
        bcrypt.hash("test", salt, function (err, hash) {
            bcrypt.compare("test", hash, function (err, res) {
                expect(hash).toBeDefined();
                bcrypt.compare("blah", hash, function (err, res) {
                    expect(res).toBe(false);
                    done();
                });
            });
        });
    });
})

test('hash_compare_empty_strings', done => {
    expect.assertions(2);
    const hash = bcrypt.hashSync("test", bcrypt.genSaltSync(10));

    bcrypt.compare("", hash, function (err, res) {
        expect(res).toEqual(false)
        bcrypt.compare("", "", function (err, res) {
            expect(res).toEqual(false);
            done();
        });
    });
})

test('hash_compare_invalid_strings', done => {
    expect.assertions(2);
    const fullString = 'envy1362987212538';
    const hash = '$2a$10$XOPbrlUPQdwdJUpSrIF6X.LbE14qsMmKGhM1A8W9iqaG3vv1BD7WC';
    const wut = ':';
    bcrypt.compare(fullString, hash, function (err, res) {
        expect(res).toBe(true);
        bcrypt.compare(fullString, wut, function (err, res) {
            expect(res).toBe(false);
            done();
        });
    });
})

test('compare_no_params', done => {
    expect.assertions(1);
    bcrypt.compare(function (err, hash) {
        expect(err.message).toBe('data and hash arguments required');
        done();
    });
})

test('hash_compare_one_param', done => {
    expect.assertions(1);
    bcrypt.compare('password', function (err, hash) {
        expect(err.message).toBe('data and hash arguments required');
        done();
    });
})

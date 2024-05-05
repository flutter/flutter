const bcrypt = require('../bcrypt');
const promises = require('../promises');

test('salt_returns_promise_on_no_args', () => {
    // make sure test passes with non-native implementations such as bluebird
    // http://stackoverflow.com/questions/27746304/how-do-i-tell-if-an-object-is-a-promise
    expect(typeof bcrypt.genSalt().then).toEqual('function')
})

test('salt_returns_promise_on_null_callback', () => {
    expect(typeof bcrypt.genSalt(13, null, null).then).toEqual('function')
})

test('salt_length', () => {
    return expect(bcrypt.genSalt(10)).resolves.toHaveLength(29);
})

test('salt_rounds_is_string_number', () => {
    return expect(bcrypt.genSalt('10')).rejects.toThrow('rounds must be a number');
})

test('salt_rounds_is_string_non_number', () => {
    return expect(bcrypt.genSalt('b')).rejects.toThrow('rounds must be a number');
})

test('hash_returns_promise_on_null_callback', () => {
    expect(typeof bcrypt.hash('password', 10, null).then).toStrictEqual('function')
})

test('hash', () => {
    return expect(bcrypt.genSalt(10)
        .then(salt => bcrypt.hash('password', salt))).resolves.toBeDefined()
})

test('hash_rounds', () => {
    return bcrypt.hash('bacon', 8).then(hash => {
        expect(bcrypt.getRounds(hash)).toStrictEqual(8)
    });
})

test('hash_empty_strings', () => {
    expect.assertions(2);
    return Promise.all([
        expect(bcrypt.genSalt(10)
            .then(salt => bcrypt.hash('', salt)))
            .resolves.toBeDefined(),
        expect(bcrypt.hash('', '')).rejects.toThrow(''),
    ]);
})

test('hash_no_params', () => {
    expect.assertions(1);
    return expect(bcrypt.hash()).rejects.toThrow('data and salt arguments required');
})

test('hash_one_param', () => {
    return expect(bcrypt.hash('password')).rejects.toThrow('data and salt arguments required');
})

test('hash_salt_validity', () => {
    expect.assertions(2);
    return Promise.all(
        [
            expect(bcrypt.hash('password', '$2a$10$somesaltyvaluertsetrse')).resolves.toBeDefined(),
            expect(bcrypt.hash('password', 'some$value')).rejects.toThrow("Invalid salt. Salt must be in the form of: $Vers$log2(NumRounds)$saltvalue")
        ]);
})

test('verify_salt', () => {
    expect.assertions(2);
    return bcrypt.genSalt(10).then(result => {
        const [_, version, salt] = result.split('$');
        expect(version).toEqual('2b')
        expect(salt).toEqual('10')
    });
})

test('verify_salt_min_rounds', () => {
    expect.assertions(2);
    return bcrypt.genSalt(1).then(value => {
        const [_, version, rounds] = value.split('$');
        expect(version).toEqual('2b');
        expect(rounds).toEqual('04');
    });
})

test('verify_salt_max_rounds', () => {
    expect.assertions(2);
    return bcrypt.genSalt(100).then(value => {
        const [_, version, rounds] = value.split('$');
        expect(version).toEqual('2b');
        expect(rounds).toEqual('31');
    });
})

test('hash_compare_returns_promise_on_null_callback', () => {
    expect(typeof bcrypt.compare('password', 'something', null).then).toStrictEqual('function')
})

test('hash_compare', () => {
    expect.assertions(3);
    return bcrypt.genSalt(10).then(function (salt) {
        expect(salt).toHaveLength(29);
        return bcrypt.hash("test", salt);
    }).then(hash => Promise.all(
        [
            expect(bcrypt.compare("test", hash)).resolves.toEqual(true),
            expect(bcrypt.compare("blah", hash)).resolves.toEqual(false)
        ]));
})

test('hash_compare_empty_strings', () => {
    expect.assertions(2);
    const hash = bcrypt.hashSync("test", bcrypt.genSaltSync(10));
    return Promise.all([
        expect(bcrypt.compare("", hash)).resolves.toEqual(false),
        expect(bcrypt.compare("", "")).resolves.toEqual(false)
    ]);
})

test('hash_compare_invalid_strings', () => {
    const fullString = 'envy1362987212538';
    const hash = '$2a$10$XOPbrlUPQdwdJUpSrIF6X.LbE14qsMmKGhM1A8W9iqaG3vv1BD7WC';
    const wut = ':';
    return Promise.all([
        expect(bcrypt.compare(fullString, hash)).resolves.toEqual(true),
        expect(bcrypt.compare(fullString, wut)).resolves.toEqual(false),
    ]);
})

test('hash_compare_no_params', () => {
    expect.assertions(1);
    return expect(bcrypt.compare()).rejects.toThrow('data and hash arguments required')
})

test('hash_compare_one_param', () => {
    expect.assertions(1);
    return expect(bcrypt.compare('password')).rejects.toThrow('data and hash arguments required')
})

test('change_promise_impl_reject', () => {

    promises.use({
        reject: function () {
            return 'mock';
        }
    });

    expect(promises.reject()).toEqual('mock');

    // need to reset the promise implementation because of require cache
    promises.use(global.Promise);
})

test('change_promise_impl_promise', () => {

    promises.use({
        reject: function (err) {
            expect(err.message).toEqual('fn must be a function');
            return 'mock';
        }
    });

    expect(promises.promise('', '', '')).toEqual('mock');

    // need to reset the promise implementation because of require cache
    promises.use(global.Promise);
})

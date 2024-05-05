const bcrypt = require('../bcrypt');

const EXPECTED = 2500; //number of times to iterate these tests.)

test('salt_length', () => {
    expect.assertions(EXPECTED);

    return Promise.all(Array.from({length: EXPECTED},
        () => bcrypt.genSalt(10)
            .then(salt => expect(salt).toHaveLength(29))));
})

test('test_hash_length', () => {
    expect.assertions(EXPECTED);
    const SALT = '$2a$04$TnjywYklQbbZjdjBgBoA4e';
    return Promise.all(Array.from({length: EXPECTED},
        () => bcrypt.hash('test', SALT)
            .then(hash => expect(hash).toHaveLength(60))));
})

test('test_compare', () => {
    expect.assertions(EXPECTED);
    const HASH = '$2a$04$TnjywYklQbbZjdjBgBoA4e9G7RJt9blgMgsCvUvus4Iv4TENB5nHy';
    return Promise.all(Array.from({length: EXPECTED},
        () => bcrypt.compare('test', HASH)
            .then(match => expect(match).toEqual(true))));
})

test('test_hash_and_compare', () => {
    expect.assertions(EXPECTED * 3);
    const salt = bcrypt.genSaltSync(4)

    return Promise.all(Array.from({length: EXPECTED},
        () => {
            const password = 'secret' + Math.random();
            return bcrypt.hash(password, salt)
                .then(hash => {
                    expect(hash).toHaveLength(60);
                    const goodCompare = bcrypt.compare(password, hash).then(res => expect(res).toEqual(true));
                    const badCompare = bcrypt.compare('bad' + password, hash).then(res => expect(res).toEqual(false));

                    return Promise.all([goodCompare, badCompare]);
                });
        }));
}, 10000);


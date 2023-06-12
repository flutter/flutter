///
/// A list of object identifiers, holding the identifier and a readable name.
///
const oi = [
  {
    'identifierString': '1.2.840.113549.1.9.22.1',
    'readableName': 'x509Certificate',
    'identifier': [1, 2, 840, 113549, 1, 9, 22, 1]
  },
  {
    'identifierString': '1.2.840.113549.1.9.22.2',
    'readableName': 'sdsiCertificate',
    'identifier': [1, 2, 840, 113549, 1, 9, 22, 2]
  },
  {
    'identifierString': '1.2.840.113549.1.9.20',
    'readableName': 'friendlyName',
    'identifier': [1, 2, 840, 113549, 1, 9, 20]
  },
  {
    'identifierString': '1.2.840.113549.1.9.21',
    'readableName': 'localKeyID',
    'identifier': [1, 2, 840, 113549, 1, 9, 21]
  },
  {
    'identifierString': '1.2.840.113549.1.12.10.1.1',
    'readableName': 'keyBag',
    'identifier': [1, 2, 840, 113549, 1, 12, 10, 1, 1]
  },
  {
    'identifierString': '1.2.840.113549.1.12.10.1.2',
    'readableName': 'pkcs-8ShroudedKeyBag',
    'identifier': [1, 2, 840, 113549, 1, 12, 10, 1, 2]
  },
  {
    'identifierString': '1.2.840.113549.1.12.10.1.3',
    'readableName': 'certBag',
    'identifier': [1, 2, 840, 113549, 1, 12, 10, 1, 3]
  },
  {
    'identifierString': '1.2.840.113549.1.12.10.1.4',
    'readableName': 'crlBag',
    'identifier': [1, 2, 840, 113549, 1, 12, 10, 1, 4]
  },
  {
    'identifierString': '1.2.840.113549.1.12.10.1.5',
    'readableName': 'secretBag',
    'identifier': [1, 2, 840, 113549, 1, 12, 10, 1, 5]
  },
  {
    'identifierString': '1.2.840.113549.1.12.10.1.6',
    'readableName': 'safeContentsBag',
    'identifier': [1, 2, 840, 113549, 1, 12, 10, 1, 6]
  },
  {
    'identifierString': '1.2.840.113549.1.7.1',
    'readableName': 'data',
    'identifier': [1, 2, 840, 113549, 1, 7, 1]
  },
  {
    'identifierString': '1.2.840.113549.1.7.6',
    'readableName': 'encryptedData',
    'identifier': [1, 2, 840, 113549, 1, 7, 6]
  },
  {
    'identifierString': '1.2.840.113549.1.1.10',
    'readableName': 'rsaPSS',
    'identifier': [1, 2, 840, 113549, 1, 1, 10]
  },
  {
    'identifierString': '2.16.840.1.101.3.4.2.1',
    'readableName': 'SHA-256',
    'identifier': [2, 16, 840, 1, 101, 3, 4, 2, 1]
  },
  {
    'identifierString': '2.16.840.1.101.3.4.2.2',
    'readableName': 'SHA-384',
    'identifier': [2, 16, 840, 1, 101, 3, 4, 2, 2]
  },
  {
    'identifierString': '2.16.840.1.101.3.4.2.3',
    'readableName': 'SHA-512',
    'identifier': [2, 16, 840, 1, 101, 3, 4, 2, 3]
  },
  {
    'identifierString': '2.16.840.1.101.3.4.2.4',
    'readableName': 'SHA-224',
    'identifier': [2, 16, 840, 1, 101, 3, 4, 2, 4]
  },
  {
    'identifierString': '2.5.4.3',
    'readableName': 'commonName',
    'identifier': [2, 5, 4, 3]
  },
  {
    'identifierString': '2.5.4.6',
    'readableName': 'countryName',
    'identifier': [2, 5, 4, 6]
  },
  {
    'identifierString': '2.5.4.10',
    'readableName': 'organizationName',
    'identifier': [2, 5, 4, 10]
  },
  {
    'identifierString': '2.5.4.11',
    'readableName': 'organizationalUnitName',
    'identifier': [2, 5, 4, 11]
  },
  {
    'identifierString': '1.3.6.1.4.1.311.60.2.1.3',
    'readableName': 'jurisdictionOfIncorporationC',
    'identifier': [1, 3, 6, 1, 4, 1, 311, 60, 2, 1, 3]
  },
  {
    'identifierString': '1.3.6.1.4.1.311.60.2.1.2',
    'readableName': 'jurisdictionOfIncorporationSP',
    'identifier': [1, 3, 6, 1, 4, 1, 311, 60, 2, 1, 2]
  },
  {
    'identifierString': '1.3.6.1.4.1.311.60.2.1.1',
    'readableName': 'jurisdictionOfIncorporationL',
    'identifier': [1, 3, 6, 1, 4, 1, 311, 60, 2, 1, 1]
  },
  {
    'identifierString': '2.5.4.15',
    'readableName': 'businessCategory',
    'identifier': [2, 5, 4, 15]
  },
  {
    'identifierString': '2.5.4.5',
    'readableName': 'serialNumber',
    'identifier': [2, 5, 4, 5]
  },
  {
    'identifierString': '2.5.4.8',
    'readableName': 'stateOrProvinceName',
    'identifier': [2, 5, 4, 8]
  },
  {
    'identifierString': '2.5.4.7',
    'readableName': 'localityName',
    'identifier': [2, 5, 4, 7]
  },
  {
    'identifierString': '1.2.840.113549.1.1.1',
    'readableName': 'rsaEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 1]
  },
  {
    'identifierString': '2.5.29.17',
    'readableName': 'subjectAltName',
    'identifier': [2, 5, 29, 17]
  },
  {
    'identifierString': '2.5.29.32',
    'readableName': 'certificatePolicies',
    'identifier': [2, 5, 29, 32]
  },
  {
    'identifierString': '2.16.840.1.113733.1.7.23.6',
    'readableName': 'VeriSign EV policy',
    'identifier': [2, 16, 840, 1, 113733, 1, 7, 23, 6]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.2.1',
    'readableName': 'cps',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 2, 1]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.2.2',
    'readableName': 'unotice',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 2, 2]
  },
  {
    'identifierString': '2.5.29.31',
    'readableName': 'cRLDistributionPoints',
    'identifier': [2, 5, 29, 31]
  },
  {
    'identifierString': '2.5.29.37',
    'readableName': 'extKeyUsage',
    'identifier': [2, 5, 29, 37]
  },
  {
    'identifierString': '2.5.29.35',
    'readableName': 'authorityKeyIdentifier',
    'identifier': [2, 5, 29, 35]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.3.1',
    'readableName': 'serverAuth',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 3, 1]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.3.2',
    'readableName': 'clientAuth',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 3, 2]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.1.1',
    'readableName': 'authorityInfoAccess',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 1, 1]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.48.1',
    'readableName': 'ocsp',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 48, 1]
  },
  {
    'identifierString': '1.3.6.1.5.5.7.48.2',
    'readableName': 'caIssuers',
    'identifier': [1, 3, 6, 1, 5, 5, 7, 48, 2]
  },
  {
    'identifierString': '1.2.840.113549.1.1.11',
    'readableName': 'sha256WithRSAEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 11]
  },
  {
    'identifierString': '1.2.840.113549.1.1.4',
    'readableName': 'md5WithRSAEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 4]
  },
  {
    'identifierString': '1.3.6.1.4.1.11129.2.4.2',
    'readableName': '2',
    'identifier': [1, 3, 6, 1, 4, 1, 11129, 2, 4, 2]
  },
  {
    'identifierString': '2.23.140.1.1',
    'readableName': 'ev-guidelines',
    'identifier': [2, 23, 140, 1, 1]
  },
  {
    'identifierString': '1.2.840.113549.1.1.5',
    'readableName': 'sha1WithRSAEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 5]
  },
  {
    'identifierString': '1.2.840.10045.2.1',
    'readableName': 'ecPublicKey',
    'identifier': [1, 2, 840, 10045, 2, 1]
  },
  {
    'identifierString': '1.2.840.10045.3.1.7',
    'readableName': 'prime256v1',
    'identifier': [1, 2, 840, 10045, 3, 1, 7]
  },
  {
    'identifierString': '1.2.840.10045.3.1.6',
    'readableName': 'prime239v3',
    'identifier': [1, 2, 840, 10045, 3, 1, 6]
  },
  {
    'identifierString': '1.2.840.10045.3.1.5',
    'readableName': 'prime239v2',
    'identifier': [1, 2, 840, 10045, 3, 1, 5]
  },
  {
    'identifierString': '1.2.840.10045.3.1.4',
    'readableName': 'prime239v1',
    'identifier': [1, 2, 840, 10045, 3, 1, 4]
  },
  {
    'identifierString': '1.2.840.10045.3.1.3',
    'readableName': 'prime192v3',
    'identifier': [1, 2, 840, 10045, 3, 1, 3]
  },
  {
    'identifierString': '1.2.840.10045.3.1.2',
    'readableName': 'prime192v2',
    'identifier': [1, 2, 840, 10045, 3, 1, 2]
  },
  {
    'identifierString': '1.2.840.10045.3.1.1',
    'readableName': 'prime192v1',
    'identifier': [1, 2, 840, 10045, 3, 1, 1]
  },
  {
    'identifierString': '1.3.132.0.1',
    'readableName': 'ansit163k1',
    'identifier': [1, 3, 132, 0, 1]
  },
  {
    'identifierString': '1.3.132.0.2',
    'readableName': 'ansit163r1',
    'identifier': [1, 3, 132, 0, 2]
  },
  {
    'identifierString': '1.3.132.0.3',
    'readableName': 'ansit239k1',
    'identifier': [1, 3, 132, 0, 3]
  },
  {
    'identifierString': '1.3.132.0.4',
    'readableName': 'sect113r1',
    'identifier': [1, 3, 132, 0, 4]
  },
  {
    'identifierString': '1.3.132.0.5',
    'readableName': 'sect113r2',
    'identifier': [1, 3, 132, 0, 5]
  },
  {
    'identifierString': '1.3.132.0.6',
    'readableName': 'secp112r1',
    'identifier': [1, 3, 132, 0, 6]
  },
  {
    'identifierString': '1.3.132.0.7',
    'readableName': 'secp112r2',
    'identifier': [1, 3, 132, 0, 7]
  },
  {
    'identifierString': '1.3.132.0.8',
    'readableName': 'ansip160r1',
    'identifier': [1, 3, 132, 0, 8]
  },
  {
    'identifierString': '1.3.132.0.9',
    'readableName': 'ansip160k1',
    'identifier': [1, 3, 132, 0, 9]
  },
  {
    'identifierString': '1.3.132.0.15',
    'readableName': 'ansit163r2',
    'identifier': [1, 3, 132, 0, 15]
  },
  {
    'identifierString': '1.3.132.0.16',
    'readableName': 'ansit283k1',
    'identifier': [1, 3, 132, 0, 16]
  },
  {
    'identifierString': '1.3.132.0.17',
    'readableName': 'ansit283r1',
    'identifier': [1, 3, 132, 0, 17]
  },
  {
    'identifierString': '1.3.132.0.22',
    'readableName': 'sect131r1',
    'identifier': [1, 3, 132, 0, 22]
  },
  {
    'identifierString': '1.3.132.0.23',
    'readableName': '23',
    'identifier': [1, 3, 132, 0, 23]
  },
  {
    'identifierString': '1.3.132.0.24',
    'readableName': 'ansit193r1',
    'identifier': [1, 3, 132, 0, 24]
  },
  {
    'identifierString': '1.3.132.0.25',
    'readableName': 'ansit193r2',
    'identifier': [1, 3, 132, 0, 25]
  },
  {
    'identifierString': '1.3.132.0.26',
    'readableName': 'ansit233k1',
    'identifier': [1, 3, 132, 0, 26]
  },
  {
    'identifierString': '1.3.132.0.27',
    'readableName': 'ansit233r1',
    'identifier': [1, 3, 132, 0, 27]
  },
  {
    'identifierString': '1.3.132.0.28',
    'readableName': 'secp128r1',
    'identifier': [1, 3, 132, 0, 28]
  },
  {
    'identifierString': '1.3.132.0.29',
    'readableName': 'secp128r2',
    'identifier': [1, 3, 132, 0, 29]
  },
  {
    'identifierString': '1.3.132.0.30',
    'readableName': 'ansip160r2',
    'identifier': [1, 3, 132, 0, 30]
  },
  {
    'identifierString': '1.3.132.0.31',
    'readableName': 'ansip192k1',
    'identifier': [1, 3, 132, 0, 31]
  },
  {
    'identifierString': '1.3.132.0.32',
    'readableName': 'ansip224k1',
    'identifier': [1, 3, 132, 0, 32]
  },
  {
    'identifierString': '1.3.132.0.33',
    'readableName': 'ansip224r1',
    'identifier': [1, 3, 132, 0, 33]
  },
  {
    'identifierString': '1.3.132.0.36',
    'readableName': 'ansit409k1',
    'identifier': [1, 3, 132, 0, 36]
  },
  {
    'identifierString': '1.3.132.0.37',
    'readableName': 'ansit409r1',
    'identifier': [1, 3, 132, 0, 37]
  },
  {
    'identifierString': '1.3.132.0.38',
    'readableName': 'ansit571k1',
    'identifier': [1, 3, 132, 0, 38]
  },
  {
    'identifierString': '1.3.132.0.39',
    'readableName': 'ansit571r1',
    'identifier': [1, 3, 132, 0, 39]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.1',
    'readableName': 'brainpoolP160r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 1]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.2',
    'readableName': 'brainpoolP160t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 2]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.3',
    'readableName': 'brainpoolP192r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 3]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.4',
    'readableName': 'brainpoolP192t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 4]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.5',
    'readableName': 'brainpoolP224r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 5]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.6',
    'readableName': 'brainpoolP224t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 6]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.7',
    'readableName': 'brainpoolP256r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 7]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.8',
    'readableName': 'brainpoolP256t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 8]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.9',
    'readableName': 'brainpoolP320r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 9]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.10',
    'readableName': 'brainpoolP320t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 10]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.11',
    'readableName': 'brainpoolP384r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 11]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.12',
    'readableName': 'brainpoolP384t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 12]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.13',
    'readableName': 'brainpoolP512r1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 13]
  },
  {
    'identifierString': '1.3.36.3.3.2.8.1.1.14',
    'readableName': 'brainpoolP512t1',
    'identifier': [1, 3, 36, 3, 3, 2, 8, 1, 1, 14]
  },
  {
    'identifierString': '1.2.840.10045.4.3.2',
    'readableName': 'ecdsaWithSHA256',
    'identifier': [1, 2, 840, 10045, 4, 3, 2]
  },
  {
    'identifierString': '2.5.4.3',
    'readableName': 'CN',
    'identifier': [2, 5, 4, 3]
  },
  {
    'identifierString': '2.5.4.4',
    'readableName': 'SN',
    'identifier': [2, 5, 4, 4]
  },
  {
    'identifierString': '2.5.4.5',
    'readableName': 'SERIALNUMBER',
    'identifier': [2, 5, 4, 5]
  },
  {
    'identifierString': '2.5.4.6',
    'readableName': 'C',
    'identifier': [2, 5, 4, 6]
  },
  {
    'identifierString': '2.5.4.7',
    'readableName': 'L',
    'identifier': [2, 5, 4, 7]
  },
  {
    'identifierString': '2.5.4.8',
    'readableName': 'ST',
    'identifier': [2, 5, 4, 8]
  },
  {
    'identifierString': '2.5.4.8',
    'readableName': 'S',
    'identifier': [2, 5, 4, 8]
  },
  {
    'identifierString': '2.5.4.9',
    'readableName': 'streetAddress',
    'identifier': [2, 5, 4, 9]
  },
  {
    'identifierString': '2.5.4.9',
    'readableName': 'STREET',
    'identifier': [2, 5, 4, 9]
  },
  {
    'identifierString': '2.5.4.10',
    'readableName': 'O',
    'identifier': [2, 5, 4, 10]
  },
  {
    'identifierString': '2.5.4.11',
    'readableName': 'OU',
    'identifier': [2, 5, 4, 11]
  },
  {
    'identifierString': '2.5.4.12',
    'readableName': 'title',
    'identifier': [2, 5, 4, 12]
  },
  {
    'identifierString': '2.5.4.12',
    'readableName': 'T',
    'identifier': [2, 5, 4, 12]
  },
  {
    'identifierString': '2.5.4.12',
    'readableName': 'TITLE',
    'identifier': [2, 5, 4, 12]
  },
  {
    'identifierString': '2.5.4.42',
    'readableName': 'givenName',
    'identifier': [2, 5, 4, 42]
  },
  {
    'identifierString': '2.5.4.42',
    'readableName': 'G',
    'identifier': [2, 5, 4, 42]
  },
  {
    'identifierString': '2.5.4.42',
    'readableName': 'GN',
    'identifier': [2, 5, 4, 42]
  },
  {
    'identifierString': '1.3.132.0.35',
    'readableName': 'secp521r1',
    'identifier': [1, 3, 132, 0, 35]
  },
  {
    'identifierString': '1.3.132.0.34',
    'readableName': 'secp384r1',
    'identifier': [1, 3, 132, 0, 34]
  },
  {
    'identifierString': '1.3.132.0.10',
    'readableName': 'secp256k1',
    'identifier': [1, 3, 132, 0, 10]
  },
  {
    'identifierString': '2.5.29.15',
    'readableName': 'keyUsage',
    'identifier': [2, 5, 29, 15]
  },
  {
    'identifierString': '2.5.29.19',
    'readableName': 'basicConstraints',
    'identifier': [2, 5, 29, 19]
  },
  {
    'identifierString': '2.5.29.14',
    'readableName': 'subjectKeyIdentifier',
    'identifier': [2, 5, 29, 14]
  },
  {
    'identifierString': '1.3.14.3.2.26',
    'readableName': 'SHA1',
    'identifier': [1, 3, 14, 3, 2, 26]
  },
  {
    'identifierString': '1.2.840.113549.1.1.13',
    'readableName': 'sha512WithRSAEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 13]
  },
  {
    'identifierString': '1.2.840.113549.1.1.12',
    'readableName': 'sha384WithRSAEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 12]
  },
  {
    'identifierString': '1.2.840.113549.1.1.14',
    'readableName': 'sha224WithRSAEncryption',
    'identifier': [1, 2, 840, 113549, 1, 1, 14]
  },
  {
    'identifierString': '1.2.840.113549.1.9.14',
    'readableName': 'extensionRequest',
    'identifier': [1, 2, 840, 113549, 1, 9, 14]
  },
  {
    'identifierString': '1.2.840.10045.4.1',
    'readableName': 'ecdsaWithSHA1',
    'identifier': [1, 2, 840, 10045, 4, 1]
  },
  {
    'identifierString': '1.2.840.10045.4.3.1',
    'readableName': 'ecdsaWithSHA224',
    'identifier': [1, 2, 840, 10045, 4, 3, 1]
  },
  {
    'identifierString': '1.2.840.10045.4.3.3',
    'readableName': 'ecdsaWithSHA384',
    'identifier': [1, 2, 840, 10045, 4, 3, 3]
  },
  {
    'identifierString': '1.2.840.10045.4.3.4',
    'readableName': 'ecdsaWithSHA512',
    'identifier': [1, 2, 840, 10045, 4, 3, 4]
  },
  {
    'identifierString': '0.9.2342.19200300.100.1.1',
    'readableName': 'UID',
    'identifier': [0, 9, 2342, 19200300, 100, 1, 1]
  },
  {
    'identifierString': '1.2.840.113549.1.9.1',
    'readableName': 'emailAddress',
    'identifier': [1, 2, 840, 113549, 1, 9, 1]
  },
  {
    'identifierString': '2.5.4.26',
    'readableName': 'registeredAddress',
    'identifier': [2, 5, 4, 26]
  },
  {
    'identifierString': '2.16.840.1.114412.1.1',
    'readableName': 'digiCertOVCert (Digicert CA policy)',
    'identifier': [2, 16, 840, 1, 114412, 1, 1]
  },
  {
    'identifierString': '2.23.140.1.2.2',
    'readableName': 'organization-validated',
    'identifier': [2, 23, 140, 1, 2, 2]
  }
];

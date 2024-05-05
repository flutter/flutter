var bcrypt = require('../bcrypt');

(function printSalt() {
  bcrypt.genSalt(10, function(err, salt) {
    console.log('salt: ' + salt);
    printSalt();
  });
})()

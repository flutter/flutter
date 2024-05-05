const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// Routes for user-related endpoints
router.post('/', userController.createUser);
router.get('/', userController.getAllUsers);
router.get('/Authentication',userController.authenticateUser)
router.get('/:id', userController.getUserById);
router.put('/:id', userController.updateUserById);
router.delete('/:id', userController.deleteUserById);

module.exports = router;

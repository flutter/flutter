const express = require('express');
const router = express.Router();
const parkingController = require('../controllers/parkingController');

// Routes for parking-related endpoints
router.post('/parkings', parkingController.createParking);
router.get('/parkings', parkingController.getAllParkings);
router.get('/parkings/:id', parkingController.getParkingById);
router.put('/parkings/:id', parkingController.updateParkingById);
router.delete('/parkings/:id', parkingController.deleteParkingById);

module.exports = router;

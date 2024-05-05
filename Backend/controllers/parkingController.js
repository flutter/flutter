const Parking = require('../models/Parking');

// Controller for parking-related operations

// Create a new parking
exports.createParking = async (req, res) => {
    try {
        const parking = new Parking(req.body);
        await parking.save();
        res.status(201).json(parking);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// Get all parkings
exports.getAllParkings = async (req, res) => {
    try {
        const parkings = await Parking.find();
        res.json(parkings);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Get a single parking by ID
exports.getParkingById = async (req, res) => {
    try {
        const parking = await Parking.findById(req.params.id);
        if (!parking) {
            return res.status(404).json({ message: 'Parking not found' });
        }
        res.json(parking);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

// Update a parking by ID
exports.updateParkingById = async (req, res) => {
    try {
        const parking = await Parking.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!parking) {
            return res.status(404).json({ message: 'Parking not found' });
        }
        res.json(parking);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
};

// Delete a parking by ID
exports.deleteParkingById = async (req, res) => {
    try {
        const parking = await Parking.findByIdAndDelete(req.params.id);
        if (!parking) {
            return res.status(404).json({ message: 'Parking not found' });
        }
        res.json({ message: 'Parking deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

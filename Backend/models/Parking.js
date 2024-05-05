const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const parkingSchema = new Schema({
    location: {
        type: String,
        required: true
    },
    // Other parking fields as needed
}, { timestamps: true });

const Parking = mongoose.model('Parking', parkingSchema);

module.exports = Parking;

const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const paymentSchema = new Schema({
    reservation: {
        type: Schema.Types.ObjectId,
        ref: 'Reservation',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    // Other payment fields as needed
}, { timestamps: true });

const Payment = mongoose.model('Payment', paymentSchema);

module.exports = Payment;

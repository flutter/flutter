const express = require('express');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const parkingRoutes = require('./routes/parkingRoutes');
const userRoutes = require('./routes/userRoutes');
const reservationRoutes = require('./routes/reservationRoutes');
const paymentRoutes = require('./routes/paymentRoutes');


const app = express();
const port = process.env.PORT || 3000; // Set the port for your server

// Middleware to parse incoming request bodies as JSON
app.use(bodyParser.json());

// MongoDB Connection
const uri = "mongodb+srv://yasminebenslim:fEyCMcDOjibCVqgB@parkandgo.yhv055i.mongodb.net/?retryWrites=true&w=majority&appName=parkandgo";
mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => {
    console.log('Connected to MongoDB');
  })
  .catch((error) => {
    console.error('Error connecting to MongoDB:', error);
  });

// Routes for RecordedPath and Location models
app.use('/parking', parkingRoutes);
app.use('/user', userRoutes);
app.use('/reservation', reservationRoutes);
app.use('/payment', paymentRoutes);

// Error handling middleware (optional)
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});

// Start the server to listen on all network interfaces
app.listen(port, '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});



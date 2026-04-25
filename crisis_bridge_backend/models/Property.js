const mongoose = require('mongoose');

const propertySchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    city: { type: String },
    address: { type: String },
    qrCodeValue: { type: String, unique: true },
    maps: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Map' }],
    emergencyContacts: [{ type: mongoose.Schema.Types.ObjectId, ref: 'EmergencyContact' }]
  },
  { timestamps: true }
);

module.exports = mongoose.model('Property', propertySchema);
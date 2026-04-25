const mongoose = require('mongoose');

const emergencyContactSchema = new mongoose.Schema(
  {
    propertyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true },
    name: { type: String, required: true },
    phone: { type: String, required: true },
    label: { type: String, default: 'Emergency' }
  },
  { timestamps: true }
);

module.exports = mongoose.model('EmergencyContact', emergencyContactSchema);
const mongoose = require('mongoose');

const incidentSchema = new mongoose.Schema(
  {
    propertyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true },
    mapId: { type: mongoose.Schema.Types.ObjectId, ref: 'Map', required: true },
    areaId: { type: mongoose.Schema.Types.ObjectId, ref: 'Area', required: true },
    senderRole: { type: String, enum: ['user', 'staff'], required: true },
    message: { type: String, default: '' },
    status: { type: String, enum: ['open', 'acknowledged', 'resolved'], default: 'open' },
    acknowledgedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Staff', default: null }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Incident', incidentSchema);
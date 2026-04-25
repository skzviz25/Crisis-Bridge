const mongoose = require('mongoose');

const acknowledgmentSchema = new mongoose.Schema(
  {
    incidentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Incident', required: true },
    staffId: { type: mongoose.Schema.Types.ObjectId, ref: 'Staff', required: true },
    status: { type: String, default: 'acknowledged' }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Acknowledgment', acknowledgmentSchema);
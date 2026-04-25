const mongoose = require('mongoose');

const mapSchema = new mongoose.Schema(
  {
    propertyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Property', required: true },
    propertyName: { type: String, required: true },
    floor: { type: Number, default: 1 },
    areas: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Area' }],
    edges: [
      {
        from: { type: String, required: true },
        to: { type: String, required: true }
      }
    ]
  },
  { timestamps: true }
);

module.exports = mongoose.model('Map', mapSchema);
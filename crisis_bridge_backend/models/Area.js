const mongoose = require('mongoose');

const areaSchema = new mongoose.Schema(
  {
    mapId: { type: mongoose.Schema.Types.ObjectId, ref: 'Map', required: true },
    name: { type: String, required: true },
    x: { type: Number, required: true },
    y: { type: Number, required: true },
    isExit: { type: Boolean, default: false },
    isDanger: { type: Boolean, default: false }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Area', areaSchema);
const mongoose = require('mongoose');

const areaSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    floor: { type: Number, required: true },
    lat: { type: Number, required: true },
    lng: { type: Number, required: true },
    isDanger: { type: Boolean, default: false },
    isExit: { type: Boolean, default: false }
  },
  { _id: true, timestamps: true }
);

const floorMapSchema = new mongoose.Schema(
  {
    propertyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Property',
      required: true
    },
    floor: { type: Number, required: true },
    areas: [areaSchema],
    edges: [
      {
        from: String,
        to: String
      }
    ],
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Staff'
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('FloorMap', floorMapSchema);
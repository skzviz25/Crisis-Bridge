const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    role: { type: String, enum: ['user'], default: 'user' },
    phone: { type: String },
    recentMaps: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Property' }]
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);
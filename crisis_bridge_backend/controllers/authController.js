const jwt = require('jsonwebtoken');
const Staff = require('../models/Staff');

const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

const registerStaff = async (req, res) => {
  try {
    const { name, email, password, propertyId } = req.body;

    const existing = await Staff.findOne({ email });
    if (existing) {
      return res.status(400).json({ message: 'Staff already exists' });
    }

    const staff = await Staff.create({
      name,
      email,
      password,
      propertyId,
      role: 'staff'
    });

    return res.status(201).json({
      id: staff._id,
      name: staff.name,
      email: staff.email,
      role: staff.role,
      token: generateToken(staff._id)
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

const loginStaff = async (req, res) => {
  try {
    const { email, password } = req.body;
    const staff = await Staff.findOne({ email });

    if (!staff || staff.password !== password) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    return res.json({
      id: staff._id,
      name: staff.name,
      email: staff.email,
      role: staff.role,
      token: generateToken(staff._id)
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};

module.exports = {
  registerStaff,
  loginStaff
};
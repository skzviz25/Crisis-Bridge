const EmergencyContact = require('../models/EmergencyContact');

const getContacts = async (req, res) => {
  try {
    const contacts = await EmergencyContact.find({ propertyId: req.params.propertyId });
    res.json(contacts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createContact = async (req, res) => {
  try {
    const contact = await EmergencyContact.create(req.body);
    res.status(201).json(contact);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getContacts,
  createContact
};
const Property = require('../models/Property');
const Map = require('../models/Map');
const Area = require('../models/Area');
const EmergencyContact = require('../models/EmergencyContact');

const getProperties = async (req, res) => {
  try {
    const properties = await Property.find().populate('maps').populate('emergencyContacts');
    res.json(properties);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getPropertyMap = async (req, res) => {
  try {
    const property = await Property.findById(req.params.propertyId).populate('maps');
    if (!property) return res.status(404).json({ message: 'Property not found' });

    const map = await Map.findOne({ propertyId: property._id }).populate('areas');
    if (!map) return res.status(404).json({ message: 'Map not found' });

    res.json({
      id: map._id,
      propertyId: property._id,
      propertyName: property.name,
      areas: map.areas,
      edges: map.edges
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getPropertyResponders = async (req, res) => {
  try {
    const contacts = await EmergencyContact.find({ propertyId: req.params.propertyId });
    res.json(contacts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getProperties,
  getPropertyMap,
  getPropertyResponders
};
const Incident = require('../models/Incident');
const Acknowledgment = require('../models/Acknowledgment');

const getIncidents = async (req, res) => {
  try {
    const incidents = await Incident.find()
      .populate('propertyId')
      .populate('mapId')
      .populate('areaId')
      .populate('acknowledgedBy');
    res.json(incidents);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createIncident = async (req, res) => {
  try {
    const { propertyId, mapId, areaId, senderRole, message } = req.body;

    const incident = await Incident.create({
      propertyId,
      mapId,
      areaId,
      senderRole,
      message,
      status: 'open'
    });

    req.io.emit('incident:new', incident);

    res.status(201).json(incident);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const acknowledgeIncident = async (req, res) => {
  try {
    const { incidentId } = req.params;
    const { staffId } = req.body;

    const incident = await Incident.findById(incidentId);
    if (!incident) return res.status(404).json({ message: 'Incident not found' });

    incident.status = 'acknowledged';
    incident.acknowledgedBy = staffId;
    await incident.save();

    await Acknowledgment.create({
      incidentId,
      staffId,
      status: 'acknowledged'
    });

    req.io.emit('incident:updated', incident);

    res.json(incident);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const resolveIncident = async (req, res) => {
  try {
    const { incidentId } = req.params;

    const incident = await Incident.findById(incidentId);
    if (!incident) return res.status(404).json({ message: 'Incident not found' });

    incident.status = 'resolved';
    await incident.save();

    req.io.emit('incident:updated', incident);

    res.json(incident);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getIncidents,
  createIncident,
  acknowledgeIncident,
  resolveIncident
};
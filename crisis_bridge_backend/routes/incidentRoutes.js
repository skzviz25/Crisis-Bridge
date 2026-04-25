const express = require('express');
const router = express.Router();

const {
  getIncidents,
  createIncident,
  acknowledgeIncident,
  resolveIncident
} = require('../controllers/incidentController');

router.get('/', getIncidents);
router.post('/', createIncident);
router.patch('/:incidentId/acknowledge', acknowledgeIncident);
router.patch('/:incidentId/resolve', resolveIncident);

module.exports = router;
const express = require('express');
const router = express.Router();

const {
  createMap,
  updateMap,
  toggleDanger
} = require('../controllers/mapController');

router.post('/', createMap);
router.put('/:mapId', updateMap);
router.patch('/:mapId/danger/:areaId', toggleDanger);

module.exports = router;
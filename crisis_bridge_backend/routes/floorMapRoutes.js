const express = require('express');
const router = express.Router();

const {
  getFloorMaps,
  getFloorMapByFloor,
  createFloorMap,
  updateFloorMap,
  addArea,
  updateArea,
  deleteArea
} = require('../controllers/floorMapController');

router.get('/property/:propertyId', getFloorMaps);
router.get('/property/:propertyId/floor/:floor', getFloorMapByFloor);
router.post('/', createFloorMap);
router.put('/:mapId', updateFloorMap);
router.post('/:mapId/areas', addArea);
router.patch('/:mapId/areas/:areaId', updateArea);
router.delete('/:mapId/areas/:areaId', deleteArea);

module.exports = router;
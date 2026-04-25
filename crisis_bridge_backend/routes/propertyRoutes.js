const express = require('express');
const router = express.Router();

const {
  getProperties,
  getPropertyMap,
  getPropertyResponders
} = require('../controllers/propertyController');

router.get('/', getProperties);
router.get('/:propertyId/map', getPropertyMap);
router.get('/:propertyId/responders', getPropertyResponders);

module.exports = router;
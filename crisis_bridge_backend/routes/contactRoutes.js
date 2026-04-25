const express = require('express');
const router = express.Router();

const {
  getContacts,
  createContact
} = require('../controllers/contactController');

router.get('/:propertyId', getContacts);
router.post('/', createContact);

module.exports = router;
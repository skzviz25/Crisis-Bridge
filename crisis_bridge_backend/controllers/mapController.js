const Map = require('../models/Map');
const Area = require('../models/Area');
const Property = require('../models/Property');

const createMap = async (req, res) => {
  try {
    const { propertyId, propertyName, floor, areas, edges } = req.body;

    const map = await Map.create({
      propertyId,
      propertyName,
      floor,
      edges: edges || []
    });

    const createdAreas = await Area.insertMany(
      (areas || []).map((area) => ({
        ...area,
        mapId: map._id
      }))
    );

    map.areas = createdAreas.map((a) => a._id);
    await map.save();

    await Property.findByIdAndUpdate(propertyId, {
      $addToSet: { maps: map._id }
    });

    res.status(201).json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateMap = async (req, res) => {
  try {
    const { mapId } = req.params;
    const { propertyName, floor, edges } = req.body;

    const map = await Map.findByIdAndUpdate(
      mapId,
      { propertyName, floor, edges },
      { new: true }
    );

    if (!map) return res.status(404).json({ message: 'Map not found' });

    res.json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const toggleDanger = async (req, res) => {
  try {
    const { mapId, areaId } = req.params;
    const area = await Area.findById(areaId);
    if (!area) return res.status(404).json({ message: 'Area not found' });

    area.isDanger = !area.isDanger;
    await area.save();

    res.json(area);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  createMap,
  updateMap,
  toggleDanger
};
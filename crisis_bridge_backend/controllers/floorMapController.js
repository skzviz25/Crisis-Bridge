const FloorMap = require('../models/FloorMap');

const getFloorMaps = async (req, res) => {
  try {
    const { propertyId } = req.params;
    const maps = await FloorMap.find({ propertyId });
    res.json(maps);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const getFloorMapByFloor = async (req, res) => {
  try {
    const { propertyId, floor } = req.params;
    const map = await FloorMap.findOne({
      propertyId,
      floor: Number(floor)
    });

    if (!map) {
      return res.status(404).json({ message: 'Floor map not found' });
    }

    res.json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const createFloorMap = async (req, res) => {
  try {
    const { propertyId, floor, areas, edges, updatedBy } = req.body;

    const map = await FloorMap.create({
      propertyId,
      floor,
      areas: areas || [],
      edges: edges || [],
      updatedBy
    });

    res.status(201).json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateFloorMap = async (req, res) => {
  try {
    const { mapId } = req.params;
    const { floor, areas, edges, updatedBy } = req.body;

    const map = await FloorMap.findById(mapId);
    if (!map) {
      return res.status(404).json({ message: 'Floor map not found' });
    }

    if (floor !== undefined) map.floor = floor;
    if (areas) map.areas = areas;
    if (edges) map.edges = edges;
    if (updatedBy) map.updatedBy = updatedBy;

    await map.save();
    res.json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const addArea = async (req, res) => {
  try {
    const { mapId } = req.params;
    const { name, floor, lat, lng, isDanger = false, isExit = false } = req.body;

    const map = await FloorMap.findById(mapId);
    if (!map) {
      return res.status(404).json({ message: 'Floor map not found' });
    }

    map.areas.push({
      name,
      floor,
      lat,
      lng,
      isDanger,
      isExit
    });

    await map.save();
    res.status(201).json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const updateArea = async (req, res) => {
  try {
    const { mapId, areaId } = req.params;
    const map = await FloorMap.findById(mapId);

    if (!map) {
      return res.status(404).json({ message: 'Floor map not found' });
    }

    const area = map.areas.id(areaId);
    if (!area) {
      return res.status(404).json({ message: 'Area not found' });
    }

    Object.assign(area, req.body);
    await map.save();

    res.json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

const deleteArea = async (req, res) => {
  try {
    const { mapId, areaId } = req.params;
    const map = await FloorMap.findById(mapId);

    if (!map) {
      return res.status(404).json({ message: 'Floor map not found' });
    }

    const area = map.areas.id(areaId);
    if (!area) {
      return res.status(404).json({ message: 'Area not found' });
    }

    area.deleteOne();
    await map.save();

    res.json(map);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = {
  getFloorMaps,
  getFloorMapByFloor,
  createFloorMap,
  updateFloorMap,
  addArea,
  updateArea,
  deleteArea
};
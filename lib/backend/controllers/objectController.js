const { getObjectsService } = require('../services/objectsService');

exports.getObjects = async (req, res) => {
  try {
    const objects = await getObjectsService();
    res.json(objects);
  } catch (e) {
    console.error(e);
    res.status(500).json({ message: e.message });
  }
};
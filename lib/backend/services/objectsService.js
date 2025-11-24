const ObjectModel = require('../models/Object');

async function getObjectsService() {
  return await ObjectModel.find({});
}

module.exports = {
  getObjectsService
};

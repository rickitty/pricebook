const Task= require ('../models/Task');
const ObjectModel=require ('../models/Object');
const { distanceInMeters } = require('../services/geoService'); 

const MAX_DIST_METERS = 100;

async function getProductsForObject(req, res) {
  try {
    const { taskId, objectId } = req.params;
    const { lat, lng } = req.query;
    

    console.log('getProductsForObject', { taskId, objectId, lat, lng });

    if (!lat || !lng) {
      return res.status(400).json({ message: 'lat и lng обязательны' });
    }

    const task = await Task.findById(taskId);
    if (!task) {
      console.error('Task not found', taskId);
      return res.status(404).json({ message: 'Task not found' });
    }

    const objectPart = task.objects.find(
      (o) => o.objectId.toString() === objectId
    );
    if (!objectPart) {
      console.error('Object in task not found', objectId);
      return res.status(404).json({ message: 'Object in task not found' });
    }

    const object = await ObjectModel.findById(objectId);
    if (!object) {
      console.error('Object not found in DB', objectId);
      return res.status(404).json({ message: 'Object not found' });
    }

    if (
      !object.coords ||
      typeof object.coords.lat !== 'number' ||
      typeof object.coords.lng !== 'number'
    ) {
      console.error('Object has no coords', object);
      return res
        .status(400)
        .json({ message: 'У объекта не заданы координаты coords.lat/lng' });
    }

    const dist = distanceInMeters(
      Number(lat),
      Number(lng),
      object.coords.lat,
      object.coords.lng
    );

    console.log('distance =', dist);

    if (dist > MAX_DIST_METERS) {
      return res.status(403).json({
        message: 'Геолокация не совпадает с объектом',
        distance: dist,
      });
    }

    return res.json({
      objectId,
      products: objectPart.products,
    });
  } catch (e) {
    console.error('getProductsForObject error:', e);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function saveProductPhotoAndPrice(req, res) {
  try {
    const { taskId, objectId, productId } = req.params;
    const { price, lat, lng } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: 'photo is required' });
    }
    if (!price) {
      return res.status(400).json({ message: 'price is required' });
    }
    if (!lat || !lng) {
      return res.status(400).json({ message: 'lat и lng обязательны' });
    }

    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    const objectPart = task.objects.find(
      o => o.objectId.toString() === objectId
    );
    if (!objectPart) {
      return res.status(404).json({ message: 'Object in task not found' });
    }

    const object = await ObjectModel.findById(objectId);
    if (!object) {
      return res.status(404).json({ message: 'Object not found' });
    }

    const dist = distanceInMeters(
      Number(lat),
      Number(lng),
      object.coords.lat,
      object.coords.lng
    );

    if (dist > MAX_DIST_METERS) {
      return res.status(403).json({
        message: 'Геолокация не совпадает с объектом',
        distance: dist,
      });
    }

    const product = objectPart.products.find(
      p => p.productId.toString() === productId
    );
    if (!product) {
      return res.status(404).json({ message: 'Product in task not found' });
    }

    const photoUrl = `/uploads/${req.file.filename}`;

    product.photoUrl = photoUrl;
    product.price = Number(price);
    product.status = 'added';

    await task.save();

    return res.json({
      message: 'Saved',
      product,
    });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function startTask(req, res) {
  try {
    const { taskId } = req.params;
    const { lat, lng } = req.body;

    const task = await Task.findById(taskId);
    if (!task) return res.status(404).json({ message: 'Task not found' });

    task.status = 'in_progress';
    task.startedAt = new Date();
    if (lat && lng) {
      task.startLat = Number(lat);
      task.startLng = Number(lng);
    }

    await task.save();
    return res.json(task);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
}

async function completeTask(req, res) {
  try {
    const { taskId } = req.params;
    const { lat, lng } = req.body;

    const task = await Task.findById(taskId)
      .populate('objects.products.productId');

    if (!task) return res.status(404).json({ message: 'Task not found' });

    const missing = [];

    task.objects.forEach(obj => {
      obj.products.forEach(p => {
        if (p.status !== 'added' || !p.photoUrl || p.price == null) {
          missing.push({
            productId: p.productId._id,
            name: p.productId.name, 
          });
        }
      });
    });

    if (missing.length > 0) {
      return res.status(400).json({
        message: 'Не все продукты заполнены',
        missing,
      });
    }

    task.status = 'completed';
    task.finishedAt = new Date();
    if (lat && lng) {
      task.endLat = Number(lat);
      task.endLng = Number(lng);
    }

    await task.save();
    return res.json(task);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
}
async function getNearestObjectForTask(req, res) {
  try {
    const { taskId } = req.params;
    const { lat, lng } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ message: 'lat и lng обязательны' });
    }

    const task = await Task.findById(taskId);
    if (!task) {
      return res.status(404).json({ message: 'Task not found' });
    }

    if (!task.objects || task.objects.length === 0) {
      return res
        .status(404)
        .json({ message: 'У задачи нет привязанных объектов' });
    }

    const objectIds = task.objects.map((o) => o.objectId);

    const objects = await ObjectModel.find({
      _id: { $in: objectIds },
    }).lean();

    if (!objects.length) {
      return res
        .status(404)
        .json({ message: 'Объекты задачи не найдены в базе' });
    }

    let nearest = null;

    for (const objPart of task.objects) {
      const obj = objects.find(
        (o) => o._id.toString() === objPart.objectId.toString()
      );
      if (
        !obj ||
        !obj.coords ||
        typeof obj.coords.lat !== 'number' ||
        typeof obj.coords.lng !== 'number'
      ) {
        continue;
      }

      const dist = distanceInMeters(
        Number(lat),
        Number(lng),
        obj.coords.lat,
        obj.coords.lng
      );

      if (!nearest || dist < nearest.distance) {
        nearest = {
          objectId: obj._id,
          distance: dist,
          name: objPart.name || obj.name, // на случай, если имя хранится в task.objects
          address: objPart.address || obj.address,
        };
      }
    }

    if (!nearest) {
      return res.status(400).json({
        message: 'Ни у одного объекта не заданы координаты coords.lat/lng',
      });
    }

    return res.json({
      objectId: nearest.objectId,
      distance: nearest.distance,
      name: nearest.name,
      address: nearest.address,
    });
  } catch (e) {
    console.error('getNearestObjectForTask error:', e);
    return res.status(500).json({ message: 'Server error' });
  }
}


module.exports = {
  getProductsForObject,
  saveProductPhotoAndPrice,
  startTask,
  completeTask,
  getNearestObjectForTask,
};
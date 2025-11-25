const express = require('express');
const router = express.Router();
const Task = require('../models/Task');
const User = require('../models/User');
const ObjectModel = require('../models/Object');
const Product = require('../models/Product');

const upload = require('../middleware/upload');
const {
  getProductsForObject,
  saveProductPhotoAndPrice,
  startTask,
  completeTask,
  getNearestObjectForTask
} = require('../controllers/taskController');

router.post('/create-task', async (req, res) => {
  try {
    const { workerId, objects, date } = req.body;

    if (!workerId || !Array.isArray(objects) || !objects.length || !date) {
      return res.status(400).json({ message: 'Заполните все поля' });
    }

    const worker = await User.findById(workerId);
    if (!worker) {
      return res.status(404).json({ message: 'Работник не найден' });
    }

    for (const obj of objects) {
      const objectExists = await ObjectModel.findById(obj.objectId);
      if (!objectExists) {
        return res.status(400).json({ message: 'Объект не найден' });
      }

      for (const pr of obj.products) {
        const productExists = await Product.findById(pr.productId);
        if (!productExists) {
          return res.status(400).json({ message: 'Продукт не найден' });
        }
      }
    }

    const task = await Task.create({
      workerId,
      objects,
      date: new Date(date),
    });

    res.status(201).json({
      message: 'Задача создана',
      task,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка сервера', error });
  }
});

router.get('/all', async (req, res) => {
  try {
    let tasks = await Task.find()
      .populate('workerId', 'name phone')
      .populate('objects.objectId'); 

    tasks = await Task.populate(tasks, { path: 'objects.products.productId' }); 

    const tasksDTO = tasks.map(task => ({
      _id: task._id,
      worker: task.workerId,
      date: task.date,
      objects: task.objects.map(obj => ({
        _id: obj.objectId._id,
        name: obj.objectId.name, 
        address: obj.objectId.address,
        products: obj.products.map(pr => ({
          _id: pr.productId._id,
          name: pr.productId.name, 
          status: pr.status,
        })),
      })),
    }));

    res.json(tasksDTO);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка сервера', error });
  }
});

router.get('/by-phone/:phone', async (req, res) => {
  try {
    const worker = await User.findOne({
      phone: { $regex: req.params.phone, $options: 'i' }
    });

    if (!worker) return res.status(404).json({ message: 'Работник не найден' });

    let tasks = await Task.find({ workerId: worker._id })
      .populate('workerId', 'name phone')
      .populate('objects.objectId'); 

    tasks = await Task.populate(tasks, { path: 'objects.products.productId' }); 

    const tasksDTO = tasks.map(task => ({
      _id: task._id,
      worker: task.workerId,
      date: task.date,
      objects: task.objects.map(obj => ({
        _id: obj.objectId._id,
        name: obj.objectId.name, 
        address: obj.objectId.address,
        products: obj.products.map(pr => ({
          _id: pr.productId._id,
          name: pr.productId.name, 
          status: pr.status,
        })),
      })),
    }));

    res.json(tasksDTO);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Ошибка сервера', error });
  }
});


router.get(
  '/:taskId/objects/:objectId/products',
  auth,
  getProductsForObject,
);

router.get(
  '/:taskId/nearest-object',
  auth,
  getNearestObjectForTask,
);

router.post(
  '/:taskId/objects/:objectId/products/:productId',
  auth,
  upload.single('photo'),
  saveProductPhotoAndPrice,
);
router.get('/debug', (req, res) => {
  res.json({ ok: true });
});

router.post('/:taskId/start', auth, startTask);

router.post('/:taskId/complete', auth, completeTask);

module.exports = router;
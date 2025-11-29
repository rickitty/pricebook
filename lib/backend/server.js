const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');

const userRoutes = require('./routes/userRoutes');
const objectRoutes = require('./routes/objectRoutes');
const taskRoutes = require('./routes/taskRoutes');
const productRoutes = require('./routes/productRoutes');
const proxyRoutes = require('./routes/proxyRoutes');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

mongoose.connect('mongodb://localhost:27017/')
  .then(() => console.log('Mongo connected'))
  .catch(err => console.error('Mongo error', err));

app.use('/api/user', userRoutes);
app.use('/api/object', objectRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/products', productRoutes);
app.use('/api/proxy', proxyRoutes);

app.listen(3000, '0.0.0.0', () => console.log('Server started on port 3000'));

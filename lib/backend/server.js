const express = require('express');
const mongoose = require('mongoose');
const admin = require('firebase-admin');
const cors = require('cors');
const path = require('path');


const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const objectRoutes = require('./routes/objectRoutes');
const taskRoutes = require('./routes/taskRoutes');
const productRoutes = require('./routes/productRoutes');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

mongoose.connect('mongodb://localhost:27017/')
  .then(() => console.log('Mongo connected'))
  .catch(err => console.error('Mongo error', err));

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/object', objectRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/products', productRoutes);

app.listen(3000, '0.0.0.0', () => console.log('Server started on port 3000'));

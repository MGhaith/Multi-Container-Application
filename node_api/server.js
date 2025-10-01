const express = require('express');
const mongoose = require('mongoose');
const todoRoutes = require('./routes/todos');

const app = express();
app.use(express.json());

mongoose.connect(process.env.MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });

app.get('/', (req, res) => {
  res.send('Todo API is running. Use /todos to interact with the API.');
});

app.use('/todos', todoRoutes);

app.listen(3000, () => console.log('API running on port 3000'));

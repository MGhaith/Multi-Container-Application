const express = require('express');
const Todo = require('../models/todo');
const router = express.Router();

// GET all
router.get('/', async (req, res) => {
  res.json(await Todo.find());
});

// POST
router.post('/', async (req, res) => {
  const todo = new Todo(req.body);
  await todo.save();
  res.json(todo);
});

// GET by ID
router.get('/:id', async (req, res) => {
  res.json(await Todo.findById(req.params.id));
});

// PUT
router.put('/:id', async (req, res) => {
  res.json(await Todo.findByIdAndUpdate(req.params.id, req.body, { new: true }));
});

// DELETE
router.delete('/:id', async (req, res) => {
  await Todo.findByIdAndDelete(req.params.id);
  res.json({ message: 'Deleted' });
});

module.exports = router;

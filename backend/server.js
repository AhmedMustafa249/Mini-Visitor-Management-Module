const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3000;
const JWT_SECRET = 'visitor-mgmt-secret-key';

app.use(cors());
app.use(express.json());

// In-memory store
let visitors = [
  {
    id: uuidv4(),
    name: 'Alice Johnson',
    mobile: '0812345678',
    visitDate: '2026-06-01',
    createdAt: new Date().toISOString(),
  },
  {
    id: uuidv4(),
    name: 'Bob Smith',
    mobile: '0898765432',
    visitDate: '2026-06-02',
    createdAt: new Date().toISOString(),
  },
  {
    id: uuidv4(),
    name: 'Carol White',
    mobile: '0876543210',
    visitDate: '2026-06-03',
    createdAt: new Date().toISOString(),
  },
];

function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Missing or invalid authorization header' });
  }
  const token = authHeader.slice(7);
  try {
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ message: 'Invalid or expired token' });
  }
}

// POST /api/login
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  if (username !== 'admin' || password !== 'admin123') {
    return res.status(401).json({ message: 'Invalid credentials' });
  }
  const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '8h' });
  res.json({ token, username });
});

// GET /api/visitors
app.get('/api/visitors', authMiddleware, (req, res) => {
  res.json(visitors);
});

// POST /api/visitors
app.post('/api/visitors', authMiddleware, (req, res) => {
  const { name, mobile, visitDate } = req.body;
  if (!name || !mobile || !visitDate) {
    return res.status(400).json({ message: 'name, mobile, and visitDate are required' });
  }
  const visitor = {
    id: uuidv4(),
    name,
    mobile,
    visitDate,
    createdAt: new Date().toISOString(),
  };
  visitors.push(visitor);
  res.status(201).json(visitor);
});

// GET /api/visitors/:id
app.get('/api/visitors/:id', authMiddleware, (req, res) => {
  const visitor = visitors.find((v) => v.id === req.params.id);
  if (!visitor) {
    return res.status(404).json({ message: 'Visitor not found' });
  }
  res.json(visitor);
});

app.listen(PORT, () => {
  console.log(`Visitor Management API running on http://localhost:${PORT}`);
});

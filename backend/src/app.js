require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const connectDB = require('./config/database');
const { notFound, errorHandler } = require('./middlewares/error');

// Connect to database
connectDB();

const app = express();

// Middleware
app.use(cors({ origin: true, allowedHeaders: ['Content-Type', 'Authorization'] }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', require('./routes/auth'));
// Admin routes (users, merchants, products, etc.)
app.use('/api/admin', require('./routes/admin'));
// Public routes
app.use('/api/products', require('./routes/products'));
app.use('/api/categories', require('./routes/categories'));
// Orders routes
app.use('/api/orders', require('./routes/orders'));

// DEBUG: print registered routes for troubleshooting deployed routing
// (temporary - remove after debug)
const listRoutes = () => {
  try {
    const routes = [];
    app._router.stack.forEach((mw) => {
      if (mw.route && mw.route.path) {
        routes.push({ path: mw.route.path, methods: Object.keys(mw.route.methods) });
      } else if (mw.name === 'router' && mw.handle && mw.handle.stack) {
        mw.handle.stack.forEach((r) => {
          if (r.route && r.route.path) routes.push({ path: r.route.path, methods: Object.keys(r.route.methods) });
        });
      }
    });
    console.log('Registered routes:', JSON.stringify(routes, null, 2));
  } catch (err) {
    console.error('listRoutes error', err);
  }
};
listRoutes();

// Serve admin build in production
if (process.env.NODE_ENV === 'production') {
  const adminDist = path.join(__dirname, '..', '..', 'admin', 'dist');
  app.use(express.static(adminDist));

  app.get('*', (req, res) => {
    res.sendFile(path.join(adminDist, 'index.html'));
  });
}

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Favela Market API is running',
    timestamp: new Date().toISOString()
  });
});

// Error handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
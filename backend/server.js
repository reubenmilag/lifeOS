/**
 * LifeOS Backend Server
 * Entry point for the Fastify API server
 */

import Fastify from 'fastify';
import cors from '@fastify/cors';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import dashboardRoutes from './routes/dashboard.js';
import accountRoutes from './routes/accounts.js';
import budgetRoutes from './routes/budgets.js';
import goalRoutes from './routes/goals.js';
import categoryRoutes from './routes/categories.js';
import transactionRoutes from './routes/transactions.js';

dotenv.config();

const fastify = Fastify({
  logger: true
});

// Connect to MongoDB
try {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('📦 Connected to MongoDB');
} catch (err) {
  console.error('❌ MongoDB connection error:', err);
  process.exit(1);
}

// Register CORS plugin
await fastify.register(cors, {
  origin: '*', // Allow all origins for development
  credentials: true
});

// Register routes
await fastify.register(dashboardRoutes);
await fastify.register(accountRoutes);
await fastify.register(budgetRoutes);
await fastify.register(goalRoutes);
await fastify.register(categoryRoutes);
await fastify.register(transactionRoutes);

// Root route
fastify.get('/', async (request, reply) => {
  return { message: 'Welcome to LifeOS API', version: '1.0.0' };
});

// Start server
const start = async () => {
  try {
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
    console.log(`🚀 Server is running on http://localhost:3000`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

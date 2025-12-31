/**
 * LifeOS Backend Server
 * Entry point for the Fastify API server
 */

import Fastify from 'fastify';
import cors from '@fastify/cors';
import dashboardRoutes from './routes/dashboard.js';

const fastify = Fastify({
  logger: true
});

// Register CORS plugin
await fastify.register(cors, {
  origin: '*', // Allow all origins for development
  credentials: true
});

// Register routes
await fastify.register(dashboardRoutes);

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

/**
 * Dashboard Routes
 * Defines API endpoints for dashboard data
 */

import { getDashboardData } from '../controllers/dashboardController.js';

export default async function dashboardRoutes(fastify, options) {
  // GET /dashboard - Retrieve dashboard data
  fastify.get('/dashboard', getDashboardData);
}

import { getBudgets, createBudget } from '../controllers/budgetController.js';

async function budgetRoutes(fastify, options) {
  fastify.get('/api/budgets', getBudgets);
  fastify.post('/api/budgets', createBudget);
}

export default budgetRoutes;

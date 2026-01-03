import { getBudgets, createBudget, updateBudget, deleteBudget } from '../controllers/budgetController.js';

async function budgetRoutes(fastify, options) {
  fastify.get('/api/budgets', getBudgets);
  fastify.post('/api/budgets', createBudget);
  fastify.put('/api/budgets/:id', updateBudget);
  fastify.delete('/api/budgets/:id', deleteBudget);
}

export default budgetRoutes;

import { getGoals, createGoal, updateGoal, deleteGoal } from '../controllers/goalController.js';

async function goalRoutes(fastify, options) {
  fastify.get('/api/goals', getGoals);
  fastify.post('/api/goals', createGoal);
  fastify.put('/api/goals/:id', updateGoal);
  fastify.delete('/api/goals/:id', deleteGoal);
}

export default goalRoutes;

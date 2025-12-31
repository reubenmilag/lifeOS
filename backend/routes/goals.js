import { getGoals, createGoal } from '../controllers/goalController.js';

async function goalRoutes(fastify, options) {
  fastify.get('/api/goals', getGoals);
  fastify.post('/api/goals', createGoal);
}

export default goalRoutes;

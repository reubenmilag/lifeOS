import { getCategories } from '../controllers/categoryController.js';

async function categoryRoutes(fastify, options) {
  fastify.get('/api/categories', getCategories);
}

export default categoryRoutes;

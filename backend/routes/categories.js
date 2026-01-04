import { getCategories, getFlatCategories, resetCategories } from '../controllers/categoryController.js';

async function categoryRoutes(fastify, options) {
  fastify.get('/api/categories', getCategories);
  fastify.get('/api/categories/flat', getFlatCategories);
  fastify.post('/api/categories/reset', resetCategories);
}

export default categoryRoutes;

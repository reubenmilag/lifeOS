import { getTransactions, createTransaction } from '../controllers/transactionController.js';

async function transactionRoutes(fastify, options) {
  fastify.get('/api/transactions', getTransactions);
  fastify.post('/api/transactions', createTransaction);
}

export default transactionRoutes;

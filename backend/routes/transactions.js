import { getTransactions, createTransaction, deleteTransaction } from '../controllers/transactionController.js';

async function transactionRoutes(fastify, options) {
  fastify.get('/api/transactions', getTransactions);
  fastify.post('/api/transactions', createTransaction);
  fastify.delete('/api/transactions/:id', deleteTransaction);
}

export default transactionRoutes;

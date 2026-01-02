import { getTransactions, createTransaction, deleteTransaction, updateTransaction } from '../controllers/transactionController.js';

async function transactionRoutes(fastify, options) {
  fastify.get('/api/transactions', getTransactions);
  fastify.post('/api/transactions', createTransaction);
  fastify.put('/api/transactions/:id', updateTransaction);
  fastify.delete('/api/transactions/:id', deleteTransaction);
}

export default transactionRoutes;

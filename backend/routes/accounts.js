import { getAccounts, createAccount, updateAccount, deleteAccount } from '../controllers/accountController.js';

async function accountRoutes(fastify, options) {
  fastify.get('/api/accounts', getAccounts);
  fastify.post('/api/accounts', createAccount);
  fastify.put('/api/accounts/:id', updateAccount);
  fastify.delete('/api/accounts/:id', deleteAccount);
}

export default accountRoutes;

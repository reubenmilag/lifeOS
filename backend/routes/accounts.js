import { getAccounts, createAccount } from '../controllers/accountController.js';

async function accountRoutes(fastify, options) {
  fastify.get('/api/accounts', getAccounts);
  fastify.post('/api/accounts', createAccount);
}

export default accountRoutes;

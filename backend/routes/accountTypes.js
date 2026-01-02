import { getAccountTypes } from '../controllers/accountTypeController.js';

export default async function (fastify, opts) {
  fastify.get('/api/account-types', getAccountTypes);
}

import IdempotencyKey from '../models/IdempotencyKey.js';
import crypto from 'crypto';

/**
 * Idempotency Middleware
 * 
 * Ensures that duplicate requests with the same idempotency key
 * return the same response without reprocessing.
 * 
 * Clients should send: X-Idempotency-Key header
 */

/**
 * Generate hash from request body
 */
const generateRequestHash = (body) => {
  return crypto.createHash('sha256').update(JSON.stringify(body || {})).digest('hex');
};

/**
 * Idempotency check for Fastify
 * 
 * Usage in routes:
 *   fastify.post('/resource', { preHandler: idempotencyCheck }, handler)
 */
export const idempotencyCheck = async (request, reply) => {
  const idempotencyKey = request.headers['x-idempotency-key'];
  
  // Skip if no idempotency key provided
  if (!idempotencyKey) {
    return;
  }

  try {
    // Check for existing key
    const existingKey = await IdempotencyKey.findOne({ key: idempotencyKey });

    if (existingKey) {
      // Validate request hash matches (same request body)
      const currentHash = generateRequestHash(request.body);
      
      if (existingKey.requestHash !== currentHash) {
        return reply.code(422).send({
          error: 'Idempotency key conflict',
          message: 'Same idempotency key was used with different request body'
        });
      }

      // Return cached response
      reply.code(existingKey.statusCode || 200);
      return reply.send(existingKey.responsePayload || { success: true, isReplay: true });
    }

    // Store key temporarily to reserve it
    request.idempotencyKey = idempotencyKey;
    request.idempotencyRequestHash = generateRequestHash(request.body);
    
  } catch (error) {
    console.error('Idempotency check error:', error);
    // Continue processing even if check fails
  }
};

/**
 * Store idempotency result after successful response
 * Use as onSend hook
 */
export const storeIdempotencyResult = async (request, reply, payload) => {
  const idempotencyKey = request.idempotencyKey;
  
  if (!idempotencyKey) {
    return payload;
  }

  try {
    // Only store for successful responses
    if (reply.statusCode >= 200 && reply.statusCode < 300) {
      await IdempotencyKey.findOneAndUpdate(
        { key: idempotencyKey },
        {
          key: idempotencyKey,
          requestHash: request.idempotencyRequestHash,
          statusCode: reply.statusCode,
          responsePayload: typeof payload === 'string' ? JSON.parse(payload) : payload
        },
        { upsert: true, new: true }
      );
    }
  } catch (error) {
    console.error('Failed to store idempotency result:', error);
  }

  return payload;
};

/**
 * Fastify plugin for idempotency
 * 
 * Usage:
 *   fastify.register(idempotencyPlugin, { routes: ['/sync/push'] })
 */
export const idempotencyPlugin = async (fastify, options) => {
  const { routes = [] } = options;

  // Add hooks for specified routes
  fastify.addHook('preHandler', async (request, reply) => {
    const shouldCheck = routes.some(route => 
      request.url.startsWith(route) || 
      request.routerPath === route
    );

    if (shouldCheck && request.method === 'POST') {
      return idempotencyCheck(request, reply);
    }
  });

  fastify.addHook('onSend', async (request, reply, payload) => {
    const shouldStore = routes.some(route => 
      request.url.startsWith(route) || 
      request.routerPath === route
    );

    if (shouldStore && request.method === 'POST') {
      return storeIdempotencyResult(request, reply, payload);
    }
    return payload;
  });
};

export default {
  idempotencyCheck,
  storeIdempotencyResult,
  idempotencyPlugin
};

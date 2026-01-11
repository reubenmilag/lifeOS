import { 
  pushSync, 
  pullSync, 
  getSyncStatus, 
  getSyncMetrics 
} from '../controllers/syncController.js';
import { idempotencyCheck, storeIdempotencyResult } from '../middleware/idempotency.js';

/**
 * Sync Routes
 * 
 * Handles offline-first synchronization between client and server
 */

// Request/Response schemas for validation
const pushSyncSchema = {
  body: {
    type: 'object',
    required: ['operations'],
    properties: {
      operations: {
        type: 'array',
        items: {
          type: 'object',
          required: ['idempotencyKey', 'entityType', 'operationType', 'entityId'],
          properties: {
            idempotencyKey: { type: 'string' },
            entityType: { 
              type: 'string',
              enum: ['account', 'transaction', 'budget', 'goal', 'category', 'event']
            },
            operationType: { 
              type: 'string',
              enum: ['CREATE', 'UPDATE', 'DELETE']
            },
            entityId: { type: 'string' },
            data: { type: 'object' },
            version: { type: 'number' }
          }
        }
      },
      clientTimestamp: { type: 'string' }
    }
  },
  response: {
    200: {
      type: 'object',
      properties: {
        results: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              idempotencyKey: { type: 'string' },
              success: { type: 'boolean' },
              serverId: { type: 'string' },
              serverVersion: { type: 'number' },
              errorMessage: { type: 'string' },
              errorCode: { type: 'string' },
              isReplay: { type: 'boolean' },
              serverData: { type: 'object' }
            }
          }
        },
        serverTimestamp: { type: 'string' },
        summary: {
          type: 'object',
          properties: {
            successCount: { type: 'number' },
            failedCount: { type: 'number' },
            total: { type: 'number' }
          }
        }
      }
    }
  }
};

const pullSyncSchema = {
  querystring: {
    type: 'object',
    required: ['entityType'],
    properties: {
      entityType: { 
        type: 'string',
        enum: ['account', 'transaction', 'budget', 'goal', 'category', 'event']
      },
      since: { type: 'string' }
    }
  },
  response: {
    200: {
      type: 'object',
      properties: {
        items: { type: 'array' },
        serverTimestamp: { type: 'string' },
        hasMore: { type: 'boolean' }
      }
    }
  }
};

const syncStatusSchema = {
  response: {
    200: {
      type: 'object',
      properties: {
        entities: { type: 'object' },
        recentActivity: { type: 'array' },
        serverTime: { type: 'string' }
      }
    }
  }
};

const syncMetricsSchema = {
  response: {
    200: {
      type: 'object',
      properties: {
        period: { type: 'object' },
        metrics: { type: 'object' },
        hourlyActivity: { type: 'array' },
        dailyBreakdown: { type: 'array' }
      }
    }
  }
};

/**
 * Register sync routes
 * @param {FastifyInstance} fastify 
 */
async function syncRoutes(fastify) {
  /**
   * POST /sync/push
   * 
   * Push batched client changes to server
   * 
   * Headers:
   *   X-Sync-Session-Id: optional session tracking
   * 
   * Body:
   *   operations: Array of sync operations
   *   clientTimestamp: ISO timestamp
   */
  fastify.post('/push', {
    schema: pushSyncSchema,
    preHandler: idempotencyCheck,
    onSend: storeIdempotencyResult,
    handler: pushSync
  });

  /**
   * GET /sync/pull
   * 
   * Pull server changes since last sync
   * 
   * Query Params:
   *   entityType: required - type of entity to pull
   *   since: optional - ISO timestamp to filter changes
   */
  fastify.get('/pull', {
    schema: pullSyncSchema,
    handler: pullSync
  });

  /**
   * GET /sync/status
   * 
   * Get overall sync status and entity counts
   */
  fastify.get('/status', {
    schema: syncStatusSchema,
    handler: getSyncStatus
  });

  /**
   * GET /sync/metrics
   * 
   * Get sync metrics for observability
   * Returns statistics about sync operations over the past 24 hours
   */
  fastify.get('/metrics', {
    schema: syncMetricsSchema,
    handler: getSyncMetrics
  });

  /**
   * Health check endpoint
   */
  fastify.get('/health', async (request, reply) => {
    return {
      status: 'healthy',
      timestamp: new Date().toISOString()
    };
  });
}

export default syncRoutes;

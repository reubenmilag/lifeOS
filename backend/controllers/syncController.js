import crypto from 'crypto';
import Account from '../models/Account.js';
import Transaction from '../models/Transaction.js';
import Budget from '../models/Budget.js';
import Goal from '../models/Goal.js';
import Category from '../models/Category.js';
import Event from '../models/Event.js';
import IdempotencyKey from '../models/IdempotencyKey.js';
import SyncLog from '../models/SyncLog.js';

/**
 * Sync Controller
 * 
 * Handles all sync operations including:
 * - Batch push (client -> server)
 * - Incremental pull (server -> client)
 * - Idempotency handling
 * - Conflict detection and resolution
 */

// Model mapping for entity types
const models = {
  account: Account,
  transaction: Transaction,
  budget: Budget,
  goal: Goal,
  category: Category,
  event: Event
};

/**
 * Generate hash of request for idempotency validation
 */
const generateRequestHash = (data) => {
  return crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
};

/**
 * Log sync operation
 */
const logSyncOperation = async (logData) => {
  try {
    await SyncLog.create(logData);
  } catch (error) {
    console.error('Failed to log sync operation:', error);
  }
};

/**
 * Push sync endpoint - receives batched changes from client
 * 
 * POST /sync/push
 * Body: {
 *   operations: [{
 *     idempotencyKey: string,
 *     entityType: string,
 *     operationType: 'CREATE' | 'UPDATE' | 'DELETE',
 *     entityId: string,
 *     data: object,
 *     version: number
 *   }],
 *   clientTimestamp: string
 * }
 */
export const pushSync = async (request, reply) => {
  const startTime = Date.now();
  const { operations, clientTimestamp } = request.body;
  const sessionId = request.headers['x-sync-session-id'] || crypto.randomUUID();

  await logSyncOperation({
    sessionId,
    logType: 'BATCH_START',
    operationType: 'PUSH',
    clientTimestamp: new Date(clientTimestamp),
    metadata: { operationCount: operations?.length || 0 }
  });

  if (!operations || !Array.isArray(operations)) {
    return reply.code(400).send({
      error: 'Invalid request: operations array required'
    });
  }

  const results = [];

  for (const operation of operations) {
    try {
      const result = await processOperation(operation, sessionId);
      results.push(result);
    } catch (error) {
      console.error('Operation error:', error);
      results.push({
        idempotencyKey: operation.idempotencyKey,
        success: false,
        errorMessage: error.message,
        errorCode: 'OPERATION_ERROR'
      });
    }
  }

  const successCount = results.filter(r => r.success).length;
  const failedCount = results.filter(r => !r.success).length;

  await logSyncOperation({
    sessionId,
    logType: 'BATCH_COMPLETE',
    operationType: 'PUSH',
    success: failedCount === 0,
    durationMs: Date.now() - startTime,
    metadata: { successCount, failedCount }
  });

  return {
    results,
    serverTimestamp: new Date().toISOString(),
    summary: { successCount, failedCount, total: operations.length }
  };
};

/**
 * Process a single sync operation
 */
const processOperation = async (operation, sessionId) => {
  const { idempotencyKey, entityType, operationType, entityId, data, version } = operation;

  // Validate entity type
  const Model = models[entityType];
  if (!Model) {
    return {
      idempotencyKey,
      success: false,
      errorMessage: `Unknown entity type: ${entityType}`,
      errorCode: 'INVALID_ENTITY_TYPE'
    };
  }

  // Check for existing idempotency key
  const existingKey = await IdempotencyKey.findOne({ key: idempotencyKey });
  if (existingKey) {
    // Idempotent replay - return cached response
    await logSyncOperation({
      sessionId,
      logType: 'IDEMPOTENT_REPLAY',
      entityType,
      entityId,
      operationType,
      idempotencyKey,
      success: true
    });

    return {
      idempotencyKey,
      success: true,
      serverId: existingKey.serverId,
      serverVersion: existingKey.serverVersion,
      isReplay: true,
      errorCode: 'IDEMPOTENT_REPLAY'
    };
  }

  // Process based on operation type
  let result;
  switch (operationType) {
    case 'CREATE':
      result = await processCreate(Model, entityType, entityId, data, version);
      break;
    case 'UPDATE':
      result = await processUpdate(Model, entityType, entityId, data, version, sessionId);
      break;
    case 'DELETE':
      result = await processDelete(Model, entityType, entityId, version, sessionId);
      break;
    default:
      return {
        idempotencyKey,
        success: false,
        errorMessage: `Unknown operation type: ${operationType}`,
        errorCode: 'INVALID_OPERATION_TYPE'
      };
  }

  // Store idempotency key for successful operations
  if (result.success) {
    await IdempotencyKey.create({
      key: idempotencyKey,
      requestHash: generateRequestHash(operation),
      statusCode: 200,
      responsePayload: result,
      entityType,
      entityId,
      operationType,
      serverId: result.serverId,
      serverVersion: result.serverVersion
    });
  }

  // Log the operation
  await logSyncOperation({
    sessionId,
    logType: result.success ? 'OPERATION_SUCCESS' : 'OPERATION_FAILURE',
    entityType,
    entityId,
    operationType,
    idempotencyKey,
    success: result.success,
    errorMessage: result.errorMessage,
    errorCode: result.errorCode,
    clientVersion: version,
    serverVersion: result.serverVersion
  });

  return {
    idempotencyKey,
    ...result
  };
};

/**
 * Process CREATE operation
 */
const processCreate = async (Model, entityType, clientId, data, version) => {
  try {
    // Check if entity already exists with this clientId
    const existing = await Model.findOne({ clientId });
    if (existing) {
      return {
        success: true,
        serverId: existing._id.toString(),
        serverVersion: existing.version,
        message: 'Entity already exists'
      };
    }

    // Create new entity
    const entity = new Model({
      ...data,
      clientId,
      version: 1,
      isDeleted: false,
      updatedAt: new Date()
    });

    await entity.save();

    return {
      success: true,
      serverId: entity._id.toString(),
      serverVersion: entity.version
    };
  } catch (error) {
    return {
      success: false,
      errorMessage: error.message,
      errorCode: 'CREATE_FAILED'
    };
  }
};

/**
 * Process UPDATE operation with conflict detection
 */
const processUpdate = async (Model, entityType, clientId, data, clientVersion, sessionId) => {
  try {
    // Find by clientId first, then by _id
    let entity = await Model.findOne({ clientId });
    if (!entity) {
      entity = await Model.findById(clientId);
    }

    if (!entity) {
      return {
        success: false,
        errorMessage: 'Entity not found',
        errorCode: 'NOT_FOUND'
      };
    }

    // Conflict detection: check if server version is newer
    if (entity.version > clientVersion) {
      await logSyncOperation({
        sessionId,
        logType: 'CONFLICT',
        entityType,
        entityId: clientId,
        operationType: 'UPDATE',
        clientVersion,
        serverVersion: entity.version,
        metadata: { serverData: entity.toObject() }
      });

      // Return server data for conflict resolution
      return {
        success: false,
        errorCode: 'CONFLICT',
        errorMessage: 'Server has newer version',
        serverVersion: entity.version,
        serverData: entity.toObject()
      };
    }

    // Apply update
    Object.assign(entity, data);
    entity.version = (entity.version || 1) + 1;
    entity.updatedAt = new Date();

    await entity.save();

    return {
      success: true,
      serverId: entity._id.toString(),
      serverVersion: entity.version
    };
  } catch (error) {
    return {
      success: false,
      errorMessage: error.message,
      errorCode: 'UPDATE_FAILED'
    };
  }
};

/**
 * Process DELETE operation (soft delete)
 */
const processDelete = async (Model, entityType, clientId, clientVersion, sessionId) => {
  try {
    // Find by clientId first, then by _id
    let entity = await Model.findOne({ clientId });
    if (!entity) {
      entity = await Model.findById(clientId);
    }

    if (!entity) {
      // Entity doesn't exist, consider delete successful
      return {
        success: true,
        message: 'Entity already deleted or not found'
      };
    }

    // Conflict detection
    if (entity.version > clientVersion) {
      await logSyncOperation({
        sessionId,
        logType: 'CONFLICT',
        entityType,
        entityId: clientId,
        operationType: 'DELETE',
        clientVersion,
        serverVersion: entity.version
      });

      return {
        success: false,
        errorCode: 'CONFLICT',
        errorMessage: 'Server has newer version',
        serverVersion: entity.version,
        serverData: entity.toObject()
      };
    }

    // Soft delete
    entity.isDeleted = true;
    entity.version = (entity.version || 1) + 1;
    entity.updatedAt = new Date();

    await entity.save();

    return {
      success: true,
      serverId: entity._id.toString(),
      serverVersion: entity.version
    };
  } catch (error) {
    return {
      success: false,
      errorMessage: error.message,
      errorCode: 'DELETE_FAILED'
    };
  }
};

/**
 * Pull sync endpoint - returns changes since last sync
 * 
 * GET /sync/pull?entityType=account&since=2024-01-01T00:00:00Z
 */
export const pullSync = async (request, reply) => {
  const startTime = Date.now();
  const { entityType, since } = request.query;
  const sessionId = request.headers['x-sync-session-id'] || crypto.randomUUID();

  await logSyncOperation({
    sessionId,
    logType: 'SYNC_START',
    operationType: 'PULL',
    entityType,
    metadata: { since }
  });

  // Validate entity type
  const Model = models[entityType];
  if (!Model) {
    return reply.code(400).send({
      error: `Unknown entity type: ${entityType}`
    });
  }

  try {
    // Build query
    const query = {};
    if (since) {
      query.updatedAt = { $gt: new Date(since) };
    }

    // Fetch changed items (including soft-deleted for sync)
    const items = await Model.find(query)
      .sort({ updatedAt: 1 })
      .limit(1000) // Limit batch size
      .lean();

    const serverTimestamp = new Date().toISOString();

    await logSyncOperation({
      sessionId,
      logType: 'SYNC_COMPLETE',
      operationType: 'PULL',
      entityType,
      success: true,
      durationMs: Date.now() - startTime,
      metadata: { itemCount: items.length, since, serverTimestamp }
    });

    return {
      items,
      serverTimestamp,
      hasMore: items.length === 1000 // Indicate if there might be more
    };
  } catch (error) {
    await logSyncOperation({
      sessionId,
      logType: 'SYNC_COMPLETE',
      operationType: 'PULL',
      entityType,
      success: false,
      errorMessage: error.message,
      durationMs: Date.now() - startTime
    });

    return reply.code(500).send({
      error: 'Failed to pull changes',
      message: error.message
    });
  }
};

/**
 * Get sync status - returns pending operations count and last sync times
 * 
 * GET /sync/status
 */
export const getSyncStatus = async (request, reply) => {
  try {
    const status = {};

    for (const [entityType, Model] of Object.entries(models)) {
      const total = await Model.countDocuments({ isDeleted: { $ne: true } });
      const lastUpdated = await Model.findOne()
        .sort({ updatedAt: -1 })
        .select('updatedAt')
        .lean();

      status[entityType] = {
        total,
        lastUpdated: lastUpdated?.updatedAt || null
      };
    }

    // Get recent sync logs summary
    const recentLogs = await SyncLog.aggregate([
      { $match: { serverTimestamp: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) } } },
      { $group: {
        _id: '$logType',
        count: { $sum: 1 },
        lastOccurrence: { $max: '$serverTimestamp' }
      }}
    ]);

    return {
      entities: status,
      recentActivity: recentLogs,
      serverTime: new Date().toISOString()
    };
  } catch (error) {
    return reply.code(500).send({
      error: 'Failed to get sync status',
      message: error.message
    });
  }
};

/**
 * Get sync metrics for observability
 * 
 * GET /sync/metrics
 */
export const getSyncMetrics = async (request, reply) => {
  try {
    const now = new Date();
    const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000);
    const oneHourAgo = new Date(now - 60 * 60 * 1000);

    // Aggregate metrics from sync logs
    const [dailyMetrics, hourlyMetrics, conflictCount, replayCount] = await Promise.all([
      // Daily operation counts
      SyncLog.aggregate([
        { $match: { serverTimestamp: { $gte: oneDayAgo } } },
        { $group: {
          _id: { logType: '$logType', success: '$success' },
          count: { $sum: 1 }
        }}
      ]),

      // Hourly operation counts
      SyncLog.aggregate([
        { $match: { serverTimestamp: { $gte: oneHourAgo } } },
        { $group: {
          _id: { logType: '$logType', success: '$success' },
          count: { $sum: 1 },
          avgDuration: { $avg: '$durationMs' }
        }}
      ]),

      // Conflict count
      SyncLog.countDocuments({
        logType: 'CONFLICT',
        serverTimestamp: { $gte: oneDayAgo }
      }),

      // Idempotent replay count
      SyncLog.countDocuments({
        logType: 'IDEMPOTENT_REPLAY',
        serverTimestamp: { $gte: oneDayAgo }
      })
    ]);

    // Calculate success rates
    const pushOps = dailyMetrics.filter(m => m._id.logType === 'OPERATION_SUCCESS' || m._id.logType === 'OPERATION_FAILURE');
    const successfulPush = pushOps.filter(m => m._id.success).reduce((sum, m) => sum + m.count, 0);
    const failedPush = pushOps.filter(m => !m._id.success).reduce((sum, m) => sum + m.count, 0);
    const pushSuccessRate = successfulPush + failedPush > 0 
      ? (successfulPush / (successfulPush + failedPush) * 100).toFixed(2)
      : 100;

    return {
      period: {
        start: oneDayAgo.toISOString(),
        end: now.toISOString()
      },
      metrics: {
        pushSuccessRate: `${pushSuccessRate}%`,
        totalOperations: successfulPush + failedPush,
        successfulOperations: successfulPush,
        failedOperations: failedPush,
        conflicts: conflictCount,
        idempotentReplays: replayCount
      },
      hourlyActivity: hourlyMetrics,
      dailyBreakdown: dailyMetrics
    };
  } catch (error) {
    return reply.code(500).send({
      error: 'Failed to get sync metrics',
      message: error.message
    });
  }
};

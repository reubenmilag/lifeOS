import mongoose from 'mongoose';

/**
 * SyncLog Schema
 * 
 * Stores sync operation logs for observability and debugging.
 * Tracks all sync operations including successes, failures, conflicts, and replays.
 */
const syncLogSchema = new mongoose.Schema({
  // Session ID for grouping related operations
  sessionId: {
    type: String,
    index: true
  },
  
  // Type of log entry
  logType: {
    type: String,
    required: true,
    enum: ['SYNC_START', 'SYNC_COMPLETE', 'OPERATION_SUCCESS', 'OPERATION_FAILURE', 
           'CONFLICT', 'IDEMPOTENT_REPLAY', 'BATCH_START', 'BATCH_COMPLETE']
  },
  
  // Entity type involved
  entityType: {
    type: String,
    enum: ['account', 'transaction', 'budget', 'goal', 'category', 'event']
  },
  
  // Entity ID involved
  entityId: {
    type: String
  },
  
  // Operation type
  operationType: {
    type: String,
    enum: ['CREATE', 'UPDATE', 'DELETE', 'PUSH', 'PULL']
  },
  
  // Idempotency key if applicable
  idempotencyKey: {
    type: String
  },
  
  // Success status
  success: {
    type: Boolean,
    default: true
  },
  
  // Error message if failed
  errorMessage: {
    type: String
  },
  
  // Error code for categorization
  errorCode: {
    type: String
  },
  
  // Additional metadata
  metadata: {
    type: mongoose.Schema.Types.Mixed
  },
  
  // Client timestamp when operation was initiated
  clientTimestamp: {
    type: Date
  },
  
  // Server timestamp when operation was processed
  serverTimestamp: {
    type: Date,
    default: Date.now
  },
  
  // Duration of operation in milliseconds
  durationMs: {
    type: Number
  },
  
  // Client version info for conflict detection
  clientVersion: {
    type: Number
  },
  
  // Server version after operation
  serverVersion: {
    type: Number
  }
}, {
  timestamps: true
});

// Indexes for efficient querying
syncLogSchema.index({ serverTimestamp: -1 });
syncLogSchema.index({ logType: 1, serverTimestamp: -1 });
syncLogSchema.index({ entityType: 1, entityId: 1, serverTimestamp: -1 });

// TTL index - keep logs for 30 days
syncLogSchema.index({ serverTimestamp: 1 }, { expireAfterSeconds: 2592000 });

const SyncLog = mongoose.model('SyncLog', syncLogSchema);

export default SyncLog;

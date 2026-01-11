import mongoose from 'mongoose';

/**
 * IdempotencyKey Schema
 * 
 * Stores idempotency keys to ensure that repeated requests with the same key
 * produce the same result without executing the operation multiple times.
 * 
 * Key features:
 * - Unique key constraint to prevent duplicate processing
 * - TTL index for automatic cleanup of old records
 * - Stores response payload for replay
 */
const idempotencyKeySchema = new mongoose.Schema({
  // The unique idempotency key from the client
  key: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  
  // Hash of the request to detect conflicting requests with same key
  requestHash: {
    type: String,
    required: true
  },
  
  // The HTTP status code of the original response
  statusCode: {
    type: Number,
    required: true
  },
  
  // The response payload to replay for duplicate requests
  responsePayload: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  
  // Entity type this key relates to
  entityType: {
    type: String,
    required: true,
    enum: ['account', 'transaction', 'budget', 'goal', 'category', 'event']
  },
  
  // Entity ID affected by this operation
  entityId: {
    type: String,
    required: true
  },
  
  // Operation type
  operationType: {
    type: String,
    required: true,
    enum: ['CREATE', 'UPDATE', 'DELETE']
  },
  
  // Timestamp when this key was created
  createdAt: {
    type: Date,
    default: Date.now,
    // Automatically expire after 24 hours
    expires: 86400
  },
  
  // Server ID of the created/updated entity
  serverId: {
    type: String
  },
  
  // Version of the entity after the operation
  serverVersion: {
    type: Number
  }
}, {
  timestamps: true
});

// Compound index for efficient lookups
idempotencyKeySchema.index({ entityType: 1, entityId: 1 });

// TTL index for automatic cleanup (24 hours)
idempotencyKeySchema.index({ createdAt: 1 }, { expireAfterSeconds: 86400 });

const IdempotencyKey = mongoose.model('IdempotencyKey', idempotencyKeySchema);

export default IdempotencyKey;

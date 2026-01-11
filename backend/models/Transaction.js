import mongoose from 'mongoose';

const transactionSchema = new mongoose.Schema({
  // Client-generated UUID for offline-first sync
  clientId: {
    type: String,
    index: true,
    sparse: true
  },
  amount: { type: Number, required: true },
  type: { type: String, enum: ['income', 'expense', 'transfer'], required: true },
  accountId: { type: mongoose.Schema.Types.ObjectId, ref: 'Account', required: true },
  toAccountId: { type: mongoose.Schema.Types.ObjectId, ref: 'Account' }, // For transfers
  categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' }, // For income/expense
  description: { type: String },
  tags: [{ type: String }],
  date: { type: Date, default: Date.now },
  // Version for optimistic concurrency control
  version: {
    type: Number,
    default: 1
  },
  // Soft delete flag for sync
  isDeleted: {
    type: Boolean,
    default: false
  },
  // Timestamp of last modification (for sync)
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Pre-save middleware to increment version
transactionSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  this.updatedAt = new Date();
  next();
});

// Indexes for sync queries
transactionSchema.index({ updatedAt: 1 });
transactionSchema.index({ clientId: 1 }, { sparse: true });
transactionSchema.index({ date: -1 });

export default mongoose.model('Transaction', transactionSchema);

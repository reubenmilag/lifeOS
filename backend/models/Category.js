import mongoose from 'mongoose';

const categorySchema = new mongoose.Schema({
  // Client-generated UUID for offline-first sync
  clientId: {
    type: String,
    index: true,
    sparse: true
  },
  name: { type: String, required: true },
  icon: { type: String, required: true },
  color: { type: String, required: true },
  type: { type: String, enum: ['income', 'expense'], required: true },
  parentId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', default: null },
  order: { type: Number, default: 0 },
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

// Virtual to get children
categorySchema.virtual('children', {
  ref: 'Category',
  localField: '_id',
  foreignField: 'parentId'
});

categorySchema.set('toJSON', { virtuals: true });
categorySchema.set('toObject', { virtuals: true });

// Pre-save middleware to increment version
categorySchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  this.updatedAt = new Date();
  next();
});

// Indexes for sync queries
categorySchema.index({ updatedAt: 1 });
categorySchema.index({ clientId: 1 }, { sparse: true });

export default mongoose.model('Category', categorySchema);

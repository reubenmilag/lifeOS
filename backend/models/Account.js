import mongoose from 'mongoose';

const accountSchema = new mongoose.Schema({
  // Client-generated UUID for offline-first sync
  clientId: {
    type: String,
    index: true,
    sparse: true
  },
  name: {
    type: String,
    required: false
  },
  balance: {
    type: Number,
    required: true,
    default: 0.0
  },
  color: {
    type: String,
    default: '#0099EE'
  },
  isLocked: {
    type: Boolean,
    default: false
  },
  accountType: {
    type: String,
    default: 'General'
  },
  type: {
    type: String,
    enum: ['standard', 'add'],
    default: 'standard'
  },
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
  timestamps: true,
  toJSON: {
    virtuals: true,
    versionKey: false,
    transform: function (doc, ret) {
      ret.id = ret._id;
      delete ret._id;
    }
  }
});

// Pre-save middleware to increment version
accountSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  this.updatedAt = new Date();
  next();
});

// Index for sync queries
accountSchema.index({ updatedAt: 1 });
accountSchema.index({ clientId: 1 }, { sparse: true });

const Account = mongoose.model('Account', accountSchema);

export default Account;

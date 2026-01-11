import mongoose from 'mongoose';

const goalSchema = new mongoose.Schema({
  // Client-generated UUID for offline-first sync
  clientId: {
    type: String,
    index: true,
    sparse: true
  },
  name: {
    type: String,
    required: true
  },
  saved: {
    type: Number,
    required: true,
    default: 0
  },
  target: {
    type: Number,
    required: true
  },
  color: {
    type: String,
    default: '#4B0082' // Indigo default
  },
  icon: {
    type: String,
    default: 'star'
  },
  deadline: {
    type: Date,
    required: true
  },
  note: {
    type: String
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
goalSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  this.updatedAt = new Date();
  next();
});

// Indexes for sync queries
goalSchema.index({ updatedAt: 1 });
goalSchema.index({ clientId: 1 }, { sparse: true });

const Goal = mongoose.model('Goal', goalSchema);

export default Goal;

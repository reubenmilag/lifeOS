import mongoose from 'mongoose';

const eventSchema = new mongoose.Schema({
  // Client-generated UUID for offline-first sync
  clientId: {
    type: String,
    index: true,
    sparse: true
  },
  title: {
    type: String,
    required: true
  },
  startTime: {
    type: Date,
    required: true
  },
  endTime: {
    type: Date,
    required: true
  },
  notes: {
    type: String
  },
  color: {
    type: String,
    default: '#18181B' // Zinc-900 like default
  },
  isAllDay: {
    type: Boolean,
    default: false
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
eventSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  this.updatedAt = new Date();
  next();
});

// Indexes for sync queries
eventSchema.index({ updatedAt: 1 });
eventSchema.index({ clientId: 1 }, { sparse: true });
eventSchema.index({ startTime: 1, endTime: 1 });

const Event = mongoose.model('Event', eventSchema);

export default Event;

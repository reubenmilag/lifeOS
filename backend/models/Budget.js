import mongoose from 'mongoose';

const budgetSchema = new mongoose.Schema({
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
  spent: {
    type: Number,
    required: true,
    default: 0
  },
  limit: {
    type: Number,
    required: true
  },
  color: {
    type: String,
    default: '#FFA500' // Orange default
  },
  icon: {
    type: String,
    default: 'shoppingCart' // Default icon name
  },
  period: {
    type: String,
    enum: ['Week', 'Month', 'Year', 'One Time'],
    required: true,
    default: 'Month'
  },
  startDate: {
    type: Date
  },
  endDate: {
    type: Date
  },
  categories: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category'
  }],
  account: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Account'
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
budgetSchema.pre('save', function(next) {
  if (this.isModified() && !this.isNew) {
    this.version += 1;
  }
  this.updatedAt = new Date();
  next();
});

// Indexes for sync queries
budgetSchema.index({ updatedAt: 1 });
budgetSchema.index({ clientId: 1 }, { sparse: true });

const Budget = mongoose.model('Budget', budgetSchema);

export default Budget;

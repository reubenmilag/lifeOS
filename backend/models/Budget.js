import mongoose from 'mongoose';

const budgetSchema = new mongoose.Schema({
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

const Budget = mongoose.model('Budget', budgetSchema);

export default Budget;

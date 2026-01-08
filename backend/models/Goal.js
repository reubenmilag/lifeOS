import mongoose from 'mongoose';

const goalSchema = new mongoose.Schema({
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

const Goal = mongoose.model('Goal', goalSchema);

export default Goal;

import mongoose from 'mongoose';

const accountSchema = new mongoose.Schema({
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
  type: {
    type: String,
    enum: ['standard', 'add'],
    default: 'standard'
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

const Account = mongoose.model('Account', accountSchema);

export default Account;

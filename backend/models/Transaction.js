import mongoose from 'mongoose';

const transactionSchema = new mongoose.Schema({
  amount: { type: Number, required: true },
  type: { type: String, enum: ['income', 'expense', 'transfer'], required: true },
  accountId: { type: mongoose.Schema.Types.ObjectId, ref: 'Account', required: true },
  toAccountId: { type: mongoose.Schema.Types.ObjectId, ref: 'Account' }, // For transfers
  categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' }, // For income/expense
  description: { type: String },
  tags: [{ type: String }],
  date: { type: Date, default: Date.now }
});

export default mongoose.model('Transaction', transactionSchema);

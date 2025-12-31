import mongoose from 'mongoose';

const categorySchema = new mongoose.Schema({
  name: { type: String, required: true },
  icon: { type: String, required: true }, // Store icon name or code
  color: { type: String, required: true },
  type: { type: String, enum: ['income', 'expense'], required: true }
});

export default mongoose.model('Category', categorySchema);

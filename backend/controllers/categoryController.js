import Category from '../models/Category.js';

export const getCategories = async (request, reply) => {
  try {
    const categories = await Category.find();
    
    // Seed default categories if empty
    if (categories.length === 0) {
      const defaultCategories = [
        // Expenses
        { name: 'Food & Drink', icon: 'fastfood', color: '#FF5722', type: 'expense' },
        { name: 'Shopping', icon: 'shopping_bag', color: '#E91E63', type: 'expense' },
        { name: 'Transport', icon: 'directions_car', color: '#2196F3', type: 'expense' },
        { name: 'Bills', icon: 'receipt', color: '#F44336', type: 'expense' },
        { name: 'Entertainment', icon: 'movie', color: '#9C27B0', type: 'expense' },
        { name: 'Health', icon: 'medical_services', color: '#4CAF50', type: 'expense' },
        // Income
        { name: 'Salary', icon: 'payments', color: '#4CAF50', type: 'income' },
        { name: 'Freelance', icon: 'work', color: '#FFC107', type: 'income' },
        { name: 'Gift', icon: 'card_giftcard', color: '#E91E63', type: 'income' },
        { name: 'Investment', icon: 'trending_up', color: '#2196F3', type: 'income' },
      ];
      
      const created = await Category.insertMany(defaultCategories);
      return created;
    }
    
    return categories;
  } catch (error) {
    reply.code(500).send({ error: 'Failed to fetch categories' });
  }
};

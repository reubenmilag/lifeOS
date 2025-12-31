import Budget from '../models/Budget.js';

export const getBudgets = async (request, reply) => {
  try {
    const budgets = await Budget.find();
    
    if (budgets.length === 0) {
      const sampleBudgets = [
        { name: "Groceries", spent: 450, limit: 600, color: "#FFA500", icon: "shoppingCart" },
        { name: "Transport", spent: 120, limit: 200, color: "#2196F3", icon: "bus" },
        { name: "Entertainment", spent: 280, limit: 300, color: "#F44336", icon: "popcorn" }
      ];
      
      const createdBudgets = await Budget.insertMany(sampleBudgets);
      return createdBudgets;
    }
    
    return budgets;
  } catch (error) {
    console.error('Error fetching budgets:', error);
    reply.code(500).send({ error: 'Failed to fetch budgets' });
  }
};

export const createBudget = async (request, reply) => {
  try {
    const budget = new Budget(request.body);
    await budget.save();
    return budget;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to create budget' });
  }
};

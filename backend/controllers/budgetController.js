import Budget from '../models/Budget.js';
import Transaction from '../models/Transaction.js';

const calculateSpent = async (budget) => {
  const now = new Date();
  let startDate, endDate;

  if (budget.period === 'One Time') {
    startDate = budget.startDate ? new Date(budget.startDate) : now;
    endDate = budget.endDate ? new Date(budget.endDate) : now;
  } else if (budget.period === 'Year') {
    startDate = new Date(now.getFullYear(), 0, 1);
    endDate = new Date(now.getFullYear(), 11, 31, 23, 59, 59, 999);
  } else if (budget.period === 'Week') {
    const currentDay = now.getDay(); // 0=Sun, 1=Mon
    const distanceToMonday = currentDay === 0 ? 6 : currentDay - 1;
    startDate = new Date(now);
    startDate.setDate(now.getDate() - distanceToMonday);
    startDate.setHours(0, 0, 0, 0);
    
    endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + 6);
    endDate.setHours(23, 59, 59, 999);
  } else {
    // Month (Default)
    startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
  }

  const query = {
    type: 'expense',
    date: { $gte: startDate, $lte: endDate }
  };

  if (budget.category) {
    query.categoryId = budget.category;
  }
  
  if (budget.account) {
    query.accountId = budget.account;
  }

  const result = await Transaction.aggregate([
    { $match: query },
    { $group: { _id: null, total: { $sum: '$amount' } } }
  ]);

  return result.length > 0 ? result[0].total : 0;
};

export const getBudgets = async (request, reply) => {
  try {
    let budgets = await Budget.find().lean();
    
    if (budgets.length === 0) {
      const sampleBudgets = [
        { name: "Groceries", spent: 0, limit: 600, color: "#FFA500", icon: "shoppingCart" },
        { name: "Transport", spent: 0, limit: 200, color: "#2196F3", icon: "bus" },
        { name: "Entertainment", spent: 0, limit: 300, color: "#F44336", icon: "popcorn" }
      ];
      
      await Budget.insertMany(sampleBudgets);
      budgets = await Budget.find().lean();
    }
    
    const budgetsWithSpent = await Promise.all(budgets.map(async (b) => {
      const spent = await calculateSpent(b);
      return {
        ...b,
        id: b._id,
        spent
      };
    }));

    return budgetsWithSpent;
  } catch (error) {
    console.error('Error fetching budgets:', error);
    reply.code(500).send({ error: 'Failed to fetch budgets' });
  }
};

export const createBudget = async (request, reply) => {
  try {
    const budget = new Budget(request.body);
    await budget.save();
    
    // Calculate spent (likely 0, but good to be consistent if backdated)
    const spent = await calculateSpent(budget.toObject());
    const result = budget.toObject();
    result.id = result._id;
    result.spent = spent;
    
    return result;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to create budget' });
  }
};

export const updateBudget = async (request, reply) => {
  try {
    const { id } = request.params;
    const budget = await Budget.findByIdAndUpdate(id, request.body, { new: true });
    if (!budget) {
      return reply.code(404).send({ error: 'Budget not found' });
    }
    
    const spent = await calculateSpent(budget.toObject());
    const result = budget.toObject();
    result.id = result._id;
    result.spent = spent;
    
    return result;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to update budget' });
  }
};

export const deleteBudget = async (request, reply) => {
  try {
    const { id } = request.params;
    await Budget.findByIdAndDelete(id);
    reply.code(204).send();
  } catch (error) {
    reply.code(500).send({ error: 'Failed to delete budget' });
  }
};

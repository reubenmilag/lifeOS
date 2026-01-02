import AccountType from '../models/AccountType.js';

export const getAccountTypes = async (request, reply) => {
  try {
    const types = await AccountType.find();
    
    if (types.length === 0) {
      const sampleTypes = [
        { name: "General", code: "general" },
        { name: "Cash", code: "cash" },
        { name: "Current Account", code: "current_account" },
        { name: "Credit Card", code: "credit_card" },
        { name: "Saving Account", code: "saving_account" },
        { name: "Bonus", code: "bonus" },
        { name: "Insurance", code: "insurance" },
        { name: "Investment", code: "investment" },
        { name: "Loan", code: "loan" },
        { name: "Mortgage", code: "mortgage" },
        { name: "Account with overdraft", code: "overdraft_account" }
      ];
      
      const createdTypes = await AccountType.insertMany(sampleTypes);
      return createdTypes;
    }
    
    return types;
  } catch (error) {
    console.error('Error fetching account types:', error);
    reply.code(500).send({ error: 'Failed to fetch account types' });
  }
};

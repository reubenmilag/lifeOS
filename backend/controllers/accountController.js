import Account from '../models/Account.js';

export const getAccounts = async (request, reply) => {
  try {
    const accounts = await Account.find();
    
    // If no accounts exist, seed some sample data
    if (accounts.length === 0) {
      const sampleAccounts = [
        { name: "Cash", balance: 22.00, color: "#0099EE", isLocked: false, type: "standard" },
        { name: "Bank", balance: 2832.91, color: "#AA66CC", isLocked: false, type: "standard" },
        { name: "Cash Reserve", balance: 12200.00, color: "#333333", isLocked: false, type: "standard" },
        { name: "Chalo", balance: 293.00, color: "#FF8800", isLocked: true, type: "standard" },
        { type: "add", color: "#0099EE" }
      ];
      
      const createdAccounts = await Account.insertMany(sampleAccounts);
      return createdAccounts;
    }
    
    return accounts;
  } catch (error) {
    console.error('Error fetching accounts:', error);
    reply.code(500).send({ error: 'Failed to fetch accounts' });
  }
};

export const createAccount = async (request, reply) => {
  try {
    const account = new Account(request.body);
    await account.save();
    return account;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to create account' });
  }
};

export const updateAccount = async (request, reply) => {
  try {
    const { id } = request.params;
    const account = await Account.findByIdAndUpdate(id, request.body, { new: true });
    if (!account) {
      return reply.code(404).send({ error: 'Account not found' });
    }
    return account;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to update account' });
  }
};

export const deleteAccount = async (request, reply) => {
  try {
    const { id } = request.params;
    const account = await Account.findByIdAndDelete(id);
    if (!account) {
      return reply.code(404).send({ error: 'Account not found' });
    }
    return { message: 'Account deleted successfully' };
  } catch (error) {
    reply.code(400).send({ error: 'Failed to delete account' });
  }
};

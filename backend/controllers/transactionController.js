import Transaction from '../models/Transaction.js';
import Account from '../models/Account.js';

export const getTransactions = async (request, reply) => {
  try {
    const transactions = await Transaction.find()
      .sort({ date: -1 })
      .populate('categoryId')
      .populate('accountId')
      .populate('toAccountId');
    return transactions;
  } catch (error) {
    reply.code(500).send({ error: 'Failed to fetch transactions' });
  }
};

export const createTransaction = async (request, reply) => {
  const session = await Transaction.startSession();
  session.startTransaction();

  try {
    const { amount, type, accountId, toAccountId, categoryId, description, tags, date } = request.body;
    
    const transaction = new Transaction({
      amount,
      type,
      accountId,
      toAccountId,
      categoryId,
      description,
      tags,
      date
    });

    await transaction.save({ session });

    // Update Account Balances
    if (type === 'expense') {
      await Account.findByIdAndUpdate(accountId, { $inc: { balance: -amount } }, { session });
    } else if (type === 'income') {
      await Account.findByIdAndUpdate(accountId, { $inc: { balance: amount } }, { session });
    } else if (type === 'transfer') {
      if (!toAccountId) {
        throw new Error('To Account is required for transfer');
      }
      await Account.findByIdAndUpdate(accountId, { $inc: { balance: -amount } }, { session });
      await Account.findByIdAndUpdate(toAccountId, { $inc: { balance: amount } }, { session });
    }

    await session.commitTransaction();
    return transaction;
  } catch (error) {
    await session.abortTransaction();
    reply.code(400).send({ error: error.message || 'Failed to create transaction' });
  } finally {
    session.endSession();
  }
};

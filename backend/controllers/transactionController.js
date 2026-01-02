import Transaction from '../models/Transaction.js';
import Account from '../models/Account.js';

export const getTransactions = async (request, reply) => {
  try {
    const { page, limit = 10, search, type, categoryId, accountId, startDate, endDate } = request.query;
    
    const query = {};

    if (search) {
      query.description = { $regex: search, $options: 'i' };
    }
    if (type) {
      query.type = type;
    }
    if (categoryId) {
      query.categoryId = categoryId;
    }
    if (accountId) {
      query.$or = [{ accountId: accountId }, { toAccountId: accountId }];
    }
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = new Date(startDate);
      if (endDate) query.date.$lte = new Date(endDate);
    }

    let transactionsQuery = Transaction.find(query)
      .sort({ date: -1 })
      .populate('categoryId')
      .populate('accountId')
      .populate('toAccountId');

    if (page) {
      const pageNum = parseInt(page);
      const limitNum = parseInt(limit);
      
      const transactions = await transactionsQuery
        .skip((pageNum - 1) * limitNum)
        .limit(limitNum);
        
      const total = await Transaction.countDocuments(query);

      return {
        data: transactions,
        meta: {
          total,
          page: pageNum,
          limit: limitNum,
          totalPages: Math.ceil(total / limitNum)
        }
      };
    } else {
      return await transactionsQuery;
    }
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

export const deleteTransaction = async (request, reply) => {
  const session = await Transaction.startSession();
  session.startTransaction();

  try {
    const { id } = request.params;
    const transaction = await Transaction.findById(id);

    if (!transaction) {
      throw new Error('Transaction not found');
    }

    const { amount, type, accountId, toAccountId } = transaction;

    // Revert Account Balances
    if (type === 'expense') {
      await Account.findByIdAndUpdate(accountId, { $inc: { balance: amount } }, { session });
    } else if (type === 'income') {
      await Account.findByIdAndUpdate(accountId, { $inc: { balance: -amount } }, { session });
    } else if (type === 'transfer') {
      await Account.findByIdAndUpdate(accountId, { $inc: { balance: amount } }, { session });
      await Account.findByIdAndUpdate(toAccountId, { $inc: { balance: -amount } }, { session });
    }

    await Transaction.findByIdAndDelete(id, { session });

    await session.commitTransaction();
    return { message: 'Transaction deleted successfully' };
  } catch (error) {
    await session.abortTransaction();
    reply.code(400).send({ error: error.message || 'Failed to delete transaction' });
  } finally {
    session.endSession();
  }
};

export const updateTransaction = async (request, reply) => {
  const session = await Transaction.startSession();
  session.startTransaction();

  try {
    const { id } = request.params;
    const updates = request.body;
    
    const oldTransaction = await Transaction.findById(id);
    if (!oldTransaction) {
      throw new Error('Transaction not found');
    }

    // 1. Revert old transaction effects
    const { amount: oldAmount, type: oldType, accountId: oldAccountId, toAccountId: oldToAccountId } = oldTransaction;

    if (oldType === 'expense') {
      await Account.findByIdAndUpdate(oldAccountId, { $inc: { balance: oldAmount } }, { session });
    } else if (oldType === 'income') {
      await Account.findByIdAndUpdate(oldAccountId, { $inc: { balance: -oldAmount } }, { session });
    } else if (oldType === 'transfer') {
      await Account.findByIdAndUpdate(oldAccountId, { $inc: { balance: oldAmount } }, { session });
      if (oldToAccountId) {
        await Account.findByIdAndUpdate(oldToAccountId, { $inc: { balance: -oldAmount } }, { session });
      }
    }

    // 2. Update the transaction document
    const updatedTransaction = await Transaction.findByIdAndUpdate(id, updates, { new: true, session });

    // 3. Apply new transaction effects
    const { amount: newAmount, type: newType, accountId: newAccountId, toAccountId: newToAccountId } = updatedTransaction;

    if (newType === 'expense') {
      await Account.findByIdAndUpdate(newAccountId, { $inc: { balance: -newAmount } }, { session });
    } else if (newType === 'income') {
      await Account.findByIdAndUpdate(newAccountId, { $inc: { balance: newAmount } }, { session });
    } else if (newType === 'transfer') {
      if (!newToAccountId) {
        throw new Error('To Account is required for transfer');
      }
      await Account.findByIdAndUpdate(newAccountId, { $inc: { balance: -newAmount } }, { session });
      await Account.findByIdAndUpdate(newToAccountId, { $inc: { balance: newAmount } }, { session });
    }

    await session.commitTransaction();
    return updatedTransaction;
  } catch (error) {
    await session.abortTransaction();
    reply.code(400).send({ error: error.message || 'Failed to update transaction' });
  } finally {
    session.endSession();
  }
};

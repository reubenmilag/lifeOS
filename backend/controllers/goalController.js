import Goal from '../models/Goal.js';

export const getGoals = async (request, reply) => {
  try {
    const goals = await Goal.find();
    
    if (goals.length === 0) {
      const sampleGoals = [
        { 
          name: "New Car", 
          saved: 15000, 
          target: 25000, 
          color: "#3F51B5",
          deadline: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
          icon: 'directions_car'
        },
        { 
          name: "Vacation", 
          saved: 2000, 
          target: 5000, 
          color: "#009688",
          deadline: new Date(new Date().setMonth(new Date().getMonth() + 6)),
          icon: 'flight'
        }
      ];
      
      const createdGoals = await Goal.insertMany(sampleGoals);
      return createdGoals;
    }
    
    return goals;
  } catch (error) {
    console.error('Error fetching goals:', error);
    reply.code(500).send({ error: 'Failed to fetch goals' });
  }
};

export const createGoal = async (request, reply) => {
  try {
    const goal = new Goal(request.body);
    await goal.save();
    return goal;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to create goal' });
  }
};

export const updateGoal = async (request, reply) => {
  try {
    const { id } = request.params;
    const goal = await Goal.findByIdAndUpdate(id, request.body, { new: true });
    if (!goal) {
      return reply.code(404).send({ error: 'Goal not found' });
    }
    return goal;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to update goal' });
  }
};

export const deleteGoal = async (request, reply) => {
  try {
    const { id } = request.params;
    const goal = await Goal.findByIdAndDelete(id);
    if (!goal) {
      return reply.code(404).send({ error: 'Goal not found' });
    }
    return { message: 'Goal deleted successfully' };
  } catch (error) {
    reply.code(400).send({ error: 'Failed to delete goal' });
  }
};

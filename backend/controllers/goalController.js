import Goal from '../models/Goal.js';

export const getGoals = async (request, reply) => {
  try {
    const goals = await Goal.find();
    
    if (goals.length === 0) {
      const sampleGoals = [
        { name: "New Car", saved: 15000, target: 25000, color: "#3F51B5" },
        { name: "Vacation", saved: 2000, target: 5000, color: "#009688" }
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

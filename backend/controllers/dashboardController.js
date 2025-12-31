/**
 * Dashboard Controller
 * Handles business logic for dashboard data
 */

export const getDashboardData = async (request, reply) => {
  try {
    // Hardcoded dummy data for the homepage dashboard
    const dashboardData = {
      user: {
        name: "Alex",
        greeting: "Good Morning"
      },
      finance: {
        totalAssets: 1450200,
        currency: "INR",
        dailyChange: 1200
      },
      focus: [
        {
          type: "reminder",
          title: "Dentist Appt",
          time: "2:00 PM",
          completed: false
        },
        {
          type: "habit",
          title: "Drink Water",
          current: 3,
          target: 8,
          unit: "glasses"
        },
        {
          type: "pomodoro",
          title: "Pomodoro",
          status: "ready",
          duration: 25
        }
      ],
      health: {
        caloriesConsumed: 1200,
        caloriesTarget: 2500
      }
    };

    reply.send(dashboardData);
  } catch (error) {
    reply.status(500).send({ error: 'Failed to fetch dashboard data' });
  }
};

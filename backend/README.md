# LifeOS Backend

Node.js backend API using Fastify for the LifeOS mobile application.

## Setup

```bash
npm install
```

## Run

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

## API Endpoints

### GET /dashboard
Returns aggregated dashboard data for the homepage.

**Response:**
```json
{
  "user": { "name": "Reuben", "greeting": "Good Morning" },
  "finance": {
    "totalAssets": 1450200,
    "currency": "INR",
    "dailyChange": 1200
  },
  "focus": [...],
  "health": {
    "caloriesConsumed": 1200,
    "caloriesTarget": 2500
  }
}
```

Server runs on: `http://localhost:3000`

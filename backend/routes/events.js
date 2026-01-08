import { getEvents, createEvent, updateEvent, deleteEvent } from '../controllers/eventController.js';

async function eventRoutes(fastify, options) {
  fastify.get('/api/events', getEvents);
  fastify.post('/api/events', createEvent);
  fastify.put('/api/events/:id', updateEvent);
  fastify.delete('/api/events/:id', deleteEvent);
}

export default eventRoutes;

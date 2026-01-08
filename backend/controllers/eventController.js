import Event from '../models/Event.js';

export const getEvents = async (request, reply) => {
  try {
    const { startDate, endDate } = request.query;
    const query = {};
    
    if (startDate && endDate) {
      query.startTime = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    const events = await Event.find(query).sort({ startTime: 1 });
    return events;
  } catch (error) {
    console.error('Error fetching events:', error);
    reply.code(500).send({ error: 'Failed to fetch events' });
  }
};

export const createEvent = async (request, reply) => {
  try {
    const event = new Event(request.body);
    await event.save();
    return event;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to create event' });
  }
};

export const updateEvent = async (request, reply) => {
  try {
    const { id } = request.params;
    const event = await Event.findByIdAndUpdate(id, request.body, { new: true });
    if (!event) {
      return reply.code(404).send({ error: 'Event not found' });
    }
    return event;
  } catch (error) {
    reply.code(400).send({ error: 'Failed to update event' });
  }
};

export const deleteEvent = async (request, reply) => {
  try {
    const { id } = request.params;
    const event = await Event.findByIdAndDelete(id);
    if (!event) {
      return reply.code(404).send({ error: 'Event not found' });
    }
    return { message: 'Event deleted successfully' };
  } catch (error) {
    reply.code(400).send({ error: 'Failed to delete event' });
  }
};

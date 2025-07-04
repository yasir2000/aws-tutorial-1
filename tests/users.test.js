
jest.mock('../utils/dynamodb', () => ({
  putItem: jest.fn().mockResolvedValue({}),
  getItem: jest.fn(),
  updateItem: jest.fn(),
  deleteItem: jest.fn()
}));
jest.mock('../utils/messaging', () => ({
  publishEvent: jest.fn().mockResolvedValue({}),
  sendNotification: jest.fn()
}));

const { create, get, update, delete: deleteUser } = require('../handlers/users');

describe('User Handlers', () => {
  const mockUser = {
    name: 'John Doe',
    email: 'john@example.com',
    age: 30,
    phone: '+1234567890'
  };

  test('create user should validate input', async () => {
    const event = {
      body: JSON.stringify({
        name: 'J', // Too short
        email: 'invalid-email'
      })
    };

    const result = await create(event);
    expect(result.statusCode).toBe(400);
  });

  test('create user should succeed with valid data', async () => {
    const event = {
      body: JSON.stringify(mockUser)
    };

    // Mock DynamoDB and SNS
    jest.mock('../utils/dynamodb');
    jest.mock('../utils/messaging');

    const result = await create(event);
    expect(result.statusCode).toBe(201);
  });
});

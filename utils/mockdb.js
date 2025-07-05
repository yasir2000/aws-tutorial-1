// Simple in-memory mock for DynamoDB operations for local testing
// Use a global variable to persist data across Lambda invocations
if (!global.mockData) {
  global.mockData = {
    users: new Map(),
    products: new Map(),
    orders: new Map()
  };
}

const mockData = global.mockData;

const getTableName = (tableName) => {
  if (tableName.includes('users')) return 'users';
  if (tableName.includes('products')) return 'products';
  if (tableName.includes('orders')) return 'orders';
  return 'unknown';
};

const getItem = async (tableName, key) => {
  const table = getTableName(tableName);
  const item = mockData[table].get(key.id);
  return item || null;
};

const put = async (tableName, item) => {
  const table = getTableName(tableName);
  mockData[table].set(item.id, item);
  console.log(`MOCK DB: Stored ${table} item with id ${item.id}`);
  return item;
};

const updateItem = async (tableName, key, updateExpression, expressionAttributeValues, expressionAttributeNames) => {
  const table = getTableName(tableName);
  const existingItem = mockData[table].get(key.id);
  if (!existingItem) {
    throw new Error('Item not found');
  }
  
  // Simple update logic - merge values
  const updatedItem = { ...existingItem, ...expressionAttributeValues };
  
  // Process update expression values (remove : prefix)
  Object.keys(expressionAttributeValues).forEach(key => {
    const cleanKey = key.replace(':', '');
    updatedItem[cleanKey] = expressionAttributeValues[key];
  });
  
  mockData[table].set(key.id, updatedItem);
  return updatedItem;
};

const deleteItem = async (tableName, key) => {
  const table = getTableName(tableName);
  mockData[table].delete(key.id);
};

// For debugging - list all items
const scan = async (tableName) => {
  const table = getTableName(tableName);
  const items = Array.from(mockData[table].values());
  console.log(`MOCK DB: Scanning ${table}, found ${items.length} items`);
  return items;
};

module.exports = {
  getItem,
  put,
  updateItem,
  deleteItem,
  scan
};

// Global mock storage for local development
// This persists across Lambda invocations in serverless offline

if (!global.mockAuthData) {
  global.mockAuthData = {
    users: new Map(),
    tokens: new Map()
  };
}

module.exports = global.mockAuthData;

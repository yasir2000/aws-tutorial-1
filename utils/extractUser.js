// Extracts user info from event (dummy implementation, adjust as needed)
function extractUserFromEvent(event) {
  // Example: extract userId from event.requestContext.authorizer.claims
  // Adjust this logic based on your actual event structure
  if (event && event.requestContext && event.requestContext.authorizer && event.requestContext.authorizer.claims) {
    return {
      userId: event.requestContext.authorizer.claims.sub
    };
  }
  // fallback for tests or missing context
  return { userId: (event && event.userId) || 'test-user-id' };
}

module.exports = { extractUserFromEvent };

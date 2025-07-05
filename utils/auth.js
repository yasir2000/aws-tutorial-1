const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';

// Configure JWKS client for production
let client;
if (!isOffline && process.env.COGNITO_USER_POOL_ID) {
  client = jwksClient({
    jwksUri: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.COGNITO_USER_POOL_ID}/.well-known/jwks.json`,
  });
}

const getKey = (header, callback) => {
  if (isOffline) {
    // For local development, we don't use JWKS
    return callback(null, process.env.JWT_SECRET || 'local-development-secret');
  }

  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      return callback(err);
    }
    const signingKey = key.getPublicKey();
    key.rsaPublicKey = signingKey;
    callback(null, signingKey);
  });
};

const verifyToken = (token) => {
  return new Promise((resolve, reject) => {
    if (isOffline) {
      // For local development, use simple JWT verification
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'local-development-secret');
        resolve(decoded);
      } catch (error) {
        reject(error);
      }
      return;
    }

    // Production Cognito verification
    jwt.verify(token, getKey, {
      algorithms: ['RS256'],
      issuer: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.COGNITO_USER_POOL_ID}`
    }, (err, decoded) => {
      if (err) {
        return reject(err);
      }
      resolve(decoded);
    });
  });
};

const extractUserFromEvent = (event) => {
  if (isOffline) {
    // For local development, try to extract from Authorization header
    const authHeader = event.headers?.Authorization || event.headers?.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'local-development-secret');
        return {
          userId: decoded.sub,
          email: decoded.email,
          name: decoded.name,
          username: decoded['cognito:username'] || decoded.email
        };
      } catch (error) {
        console.warn('Invalid JWT token:', error.message);
      }
    }
    
    // Fallback for local development without authentication
    return {
      userId: 'local-user-id',
      email: 'local@example.com',
      name: 'Local User',
      username: 'local@example.com'
    };
  }

  // Production: Extract from Cognito authorizer context
  if (event.requestContext && event.requestContext.authorizer) {
    const claims = event.requestContext.authorizer.claims;
    return {
      userId: claims.sub,
      email: claims.email,
      name: claims.name,
      username: claims['cognito:username']
    };
  }
  
  throw new Error('User not authenticated');
};

const requireAuth = (handler) => {
  return async (event, context) => {
    try {
      if (isOffline) {
        // For local development, check Authorization header
        const authHeader = event.headers?.Authorization || event.headers?.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
          return {
            statusCode: 401,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Headers': 'Content-Type,Authorization',
              'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
            },
            body: JSON.stringify({
              success: false,
              message: 'Authorization header required'
            })
          };
        }

        const token = authHeader.substring(7);
        try {
          await verifyToken(token);
        } catch (error) {
          return {
            statusCode: 401,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
              success: false,
              message: 'Invalid token'
            })
          };
        }
      }

      // If we reach here, the user is authenticated
      return await handler(event, context);
      
    } catch (error) {
      return {
        statusCode: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
          success: false,
          message: error.message
        })
      };
    }
  };
};

module.exports = {
  verifyToken,
  extractUserFromEvent,
  requireAuth
};
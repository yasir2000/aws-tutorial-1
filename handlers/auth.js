const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');
const { successResponse, errorResponse, createdResponse } = require('../utils/response');
const { getItem, put } = require('../utils/dynamodb');
const { v4: uuidv4 } = require('uuid');
const mockAuthData = require('../utils/mockAuth');

// Configure Cognito for local development
const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';

let cognito;
if (!isOffline) {
  cognito = new AWS.CognitoIdentityServiceProvider();
}

const generateMockToken = (user) => {
  const payload = {
    sub: user.id,
    email: user.email,
    name: user.name,
    'cognito:username': user.email,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24 hours
  };
  
  return jwt.sign(payload, process.env.JWT_SECRET || 'local-development-secret');
};

module.exports.signup = async (event) => {
  try {
    const { email, password, name } = JSON.parse(event.body);

    if (!email || !password || !name) {
      return errorResponse('Email, password, and name are required', 400);
    }

    if (isOffline) {
      // Mock signup for local development
      if (mockAuthData.users.has(email)) {
        return errorResponse('User already exists', 400);
      }

      const user = {
        id: uuidv4(),
        email,
        name,
        confirmed: true,
        createdAt: new Date().toISOString()
      };

      mockAuthData.users.set(email, { ...user, password });
      
      // Store user in DynamoDB
      await put(process.env.USERS_TABLE, user);

      const token = generateMockToken(user);
      mockAuthData.tokens.set(token, user);

      return createdResponse({
        message: 'User created successfully',
        user: { id: user.id, email: user.email, name: user.name },
        token,
        needsConfirmation: false
      });
    }

    // Real Cognito signup
    const params = {
      ClientId: process.env.COGNITO_CLIENT_ID,
      Username: email,
      Password: password,
      UserAttributes: [
        {
          Name: 'email',
          Value: email
        },
        {
          Name: 'name',
          Value: name
        }
      ]
    };

    const result = await cognito.signUp(params).promise();

    // Store user in DynamoDB
    const user = {
      id: result.UserSub,
      email,
      name,
      confirmed: false,
      createdAt: new Date().toISOString()
    };

    await put(process.env.USERS_TABLE, user);

    return createdResponse({
      message: 'User created successfully. Please check your email for verification.',
      userId: result.UserSub,
      needsConfirmation: true
    });

  } catch (error) {
    console.error('Signup error:', error);
    return errorResponse(error.message || 'Failed to create user', 400);
  }
};

module.exports.signin = async (event) => {
  try {
    const { email, password } = JSON.parse(event.body);

    if (!email || !password) {
      return errorResponse('Email and password are required', 400);
    }

    if (isOffline) {
      // Mock signin for local development
      const user = mockAuthData.users.get(email);
      if (!user || user.password !== password) {
        return errorResponse('Invalid credentials', 401);
      }

      const token = generateMockToken(user);
      mockAuthData.tokens.set(token, user);

      return successResponse({
        message: 'Sign in successful',
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name
        }
      });
    }

    // Real Cognito signin
    const params = {
      AuthFlow: 'USER_PASSWORD_AUTH',
      ClientId: process.env.COGNITO_CLIENT_ID,
      AuthParameters: {
        USERNAME: email,
        PASSWORD: password
      }
    };

    const result = await cognito.initiateAuth(params).promise();

    if (result.ChallengeName) {
      return errorResponse('Authentication challenge required', 400);
    }

    return successResponse({
      message: 'Sign in successful',
      accessToken: result.AuthenticationResult.AccessToken,
      idToken: result.AuthenticationResult.IdToken,
      refreshToken: result.AuthenticationResult.RefreshToken
    });

  } catch (error) {
    console.error('Signin error:', error);
    return errorResponse('Invalid credentials', 401);
  }
};

module.exports.confirmSignup = async (event) => {
  try {
    const { email, confirmationCode } = JSON.parse(event.body);

    if (!email || !confirmationCode) {
      return errorResponse('Email and confirmation code are required', 400);
    }

    if (isOffline) {
      // Mock confirmation for local development
      return successResponse({
        message: 'Email confirmation successful (mock)'
      });
    }

    // Real Cognito confirmation
    const params = {
      ClientId: process.env.COGNITO_CLIENT_ID,
      Username: email,
      ConfirmationCode: confirmationCode
    };

    await cognito.confirmSignUp(params).promise();

    // Update user confirmation status in DynamoDB
    const user = await getItem(process.env.USERS_TABLE, { email });
    if (user) {
      user.confirmed = true;
      await put(process.env.USERS_TABLE, user);
    }

    return successResponse({
      message: 'Email confirmation successful'
    });

  } catch (error) {
    console.error('Confirm signup error:', error);
    return errorResponse(error.message || 'Failed to confirm signup', 400);
  }
};

module.exports.getProfile = async (event) => {
  try {
    const userId = event.requestContext?.authorizer?.claims?.sub;
    
    if (!userId) {
      return errorResponse('User not authenticated', 401);
    }

    const user = await getItem(process.env.USERS_TABLE, { id: userId });
    
    if (!user) {
      return errorResponse('User not found', 404);
    }

    return successResponse({
      id: user.id,
      email: user.email,
      name: user.name,
      createdAt: user.createdAt
    });

  } catch (error) {
    console.error('Get profile error:', error);
    return errorResponse('Failed to get user profile', 500);
  }
};

// Export mock storage for testing
module.exports.mockAuthData = mockAuthData;

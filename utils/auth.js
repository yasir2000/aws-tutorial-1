const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');

const client = jwksClient({
    jwksUri: `https://cognito-idp.${process.env.AWS_REGION}.amazonaws.com/${process.env.COGNITO_USER_POOL_ID}/.well-known/jwks.json`,
});

const getKey = (header, callback) => {
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
    if (event.requestContext && event.requestContext.authorizer) {
        return 
        return {
            userid: event.requestContext.authorizer.claims.sub,
            email: event.requestContext.authorizer.claims.email,
            username: event.requestContext.authorizer.claims['cognito:username']
        };
    }
    return null;
};

module.exports = {
    verifyToken,
    extractUserFromEvent
};
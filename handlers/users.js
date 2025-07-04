const { v4: uuidv4} = require('uuid');
const { successResponse, createdResponse, errorResponse } = require('../utils/response');
const { userSchema, validateInput } = require('../utils/validation');
const { extractUserFromEvent } = require('../utils/extractUser');
const { getItem, putItem, updateItem, deleteItem } = require('../utils/dynamodb');
const { publishEvent} = require('../utils/messaging');

module.exports.create = async(event) => {
    try {
        const data = JSON.parse (event.body);
        const validateData = validateInput(userSchema, data);
        const user = {
            id: uuidv4(),
            ...validateData,
            createdAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
        };
        await putItem(process.env.USERS_TABLE, user);
        await publishEvent('UserCreated', user);
        return createdResponse(user);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.get = async(event) => {
    try {
        const {id} = event.pathParameters;
        const currentuser = extractUserFromEvent(event);
        if (currentuser.userId !== id) {
            return errorResponse('Unauthorized access', 404);
        }
        return successResponse(user);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.update = async(event) => {
    try {
        const {id} = event.pathParameters;
        const data = JSON.parse (event.body);
        const currentuser = extractUserFromEvent(event);
        if (currentuser.userId !== id) {
            return errorResponse('Unauthorized access', 403);
        }
        const validateData = validateInput(userSchema, data);
        const updateExpression = 'SET #name = :name, email = :email, age = :age, phone = :phone, updateAt = :updateAt';
        const expressionAttributeNames = {
            ':name': validateData.name,
            ':email': validateData.email,
            ':age': validateData.age,
            ':phone': validateData.phone,
            ':updateAt': new Date().toISOString(),
        };
        const updateUser = await updateItem(
            process.env.USER_TABLE,
            {id},
            updateExpression,
            expressionAttributevalues
        );
        
        await publishEvent('USER_UPDATED', updateUser);
        return successResponse(updateUser);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.delete = async(event) => {
    try {
        const {id} = event.pathParameters;
        const currentuser = extractUserFromEvent(event);
        if (currentuser.userId !== id) {
            return errorResponse('Unauthorized access', 403);
        }
        const user = await getItem(process.env.USER_TABLE, {id});
        if (!user){
            return errorResponse('User not found', 404);
        }
        await deleteItem(process.env.USER_TABLE, {id});
        await publishEvent('USER_DELETED', user);
        return successResponse({ message: 'user deleted successfully' });

        
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

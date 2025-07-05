const { v4: uuidv4 } = require('uuid');
const { successResponse, errorResponse } = require('../utils/response');
const { productSchema, validateInput } = require('../utils/validation');
const { getItem, put, updateItem, deleteItem, scan } = require('../utils/dynamodb');
const { publishEvent } = require('../utils/messaging');
const { extractUserFromEvent } = require('../utils/extractUser');

module.exports.create = async (event) => {
    try {
        const data = JSON.parse(event.body);
        const validateData = validateInput(productSchema, data);
        const product = {
            id: uuidv4(),
            ...validateData,
            createdAt: new Date().toISOString(),
            createdBy: 'system', // For local development
            updatedAt: new Date().toISOString(),
        };
        await put(process.env.PRODUCTS_TABLE, product);
        await publishEvent('PRODUCT_CREATED', product);
        return successResponse(product);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.get = async (event) => {
    try {
        const { id } = event.pathParameters;
        const product = await getItem(process.env.PRODUCTS_TABLE, { id });
        if (!product) {
            return errorResponse('Product not found', 404);
        }
        return successResponse(product);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.update = async (event) => {
    try {
        const { id } = event.pathParameters;
        const data = JSON.parse(event.body);
        const currentUser = extractUserFromEvent(event);
        const existingProduct = await getItem(process.env.PRODUCTS_TABLE, { id });
        if (!existingProduct) {
            return errorResponse('Product not found', 404);
        }
        // Skip authorization check for local development
        const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';
        if (!isOffline && existingProduct.createdBy !== currentUser.userId) {
            return errorResponse('Unauthorized access', 403);
        }
        const validateData = validateInput(productSchema, data);
        const updateExpression = 'SET #name = :name, price = :price, description = :description, updatedAt = :updatedAt';
        const expressionAttributeValues = {
            ':name': validateData.name,
            ':price': validateData.price,
            ':description': validateData.description,
            ':category': validateData.category,
            ':stock' : validateData.stock,
            ':updatedAt': new Date().toISOString(),
        };
        const updatedProduct = await updateItem(
            process.env.PRODUCTS_TABLE,
            { id },
            updateExpression,
            expressionAttributeValues
        );
        await publishEvent('PRODUCT_UPDATED', updatedProduct);
        return successResponse(updatedProduct);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.delete = async (event) => {
    try {
        const { id } = event.pathParameters;
        const currentUser = extractUserFromEvent(event);
        const product = await getItem(process.env.PRODUCTS_TABLE, { id });
        if (!product) {
            return errorResponse('Product not found', 404);
        }
        // Skip authorization check for local development
        const isOffline = process.env.IS_OFFLINE || process.env.NODE_ENV === 'development';
        if (!isOffline && product.createdBy !== currentUser.userId) {
            return errorResponse('Unauthorized access', 403);
        }
        await deleteItem(process.env.PRODUCTS_TABLE, { id });
        await publishEvent('PRODUCT_DELETED', { id });
        return successResponse({ message: 'Product deleted successfully' });
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};

module.exports.getAll = async (event) => {
    try {
        const products = await scan(process.env.PRODUCTS_TABLE);
        return successResponse(products || []);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};
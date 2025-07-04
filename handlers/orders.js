const { v4: uuidv4 } = require('uuid');
const { successResponse, errorResponse } = require('../utils/response');
const { orderSchema, validateInput } = require('../utils/validation');
const { extractUserFromEvent } = require('../utils/extractUser');
const { getItem, putItem,} = require('../utils/dynamodb');
const { publishEvent } = require('../utils/messaging');


module.exports.create = async (event) => {
    try {
        const data = JSON.parse(event.body);
        const currentUser = extractUserFromEvent(event);
        const validateData = validateInput(orderSchema, data);
        // Users can only create orders for themselves
        if (validatedData.userId !== currentuser.userId) {
            return errorResponse('Unauthorized access', 403);
        }
        // Validate products exist and calculate total price
        let totalAmount =0;
        const orderProducts = [];
        for (const orderProduct of validatedData.products){
            const product = await getItem(process.env.PRODUCTS_TABLE, { id: orderProduct.productId });
            if (!product) {
                return errorResponse(`Product with ID ${orderProduct.productId} not found`, 404);
            }
            if (product.stock < orderProduct.quantity){
                return errorResponse(`Insufficient stock for product ${product.name}`, 400);
            }

        }
        const itemTotal = product.price * orderProduct.quantity;
        orderProduct.quantity;
        totalAmount += itemTotal;
        orderProducts.push({
            productId: orderProduct.productId,
            productName: product.name,
            quantity: orderProduct.quantity,
            unitPrice: product.price,
            totalPrice: itemTotal
        });
    

    const order = {
        id: uuidv4(),
        userId: currentUser.userId,
        products: orderProducts,
        shippingAddress: validateData.shippingAddress,
        totalAmount,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
    };
    await putItem(process.env.ORDERS_TABLE, order);
    await publishEvent('ORDER_CREATED', order);
    return successResponse(order);
    } catch (error) {
    return errorResponse(error.message, 400);
    }
};

module.exports.get = async (event) => {
    try {
        const { id } = event.pathParameters;
        const currentUser = extractUserFromEvent(event);
        const order = await getItem(process.env.ORDERS_TABLE, { id });
        if (!order) {
            return errorResponse('Order not found', 404);
        }
        // Users can only access their own orders
        if (order.userId !== currentUser.userId) {
            return errorResponse('Unauthorized access', 403);
        }
        return successResponse(order);
    } catch (error) {
        return errorResponse(error.message, 400);
    }
};
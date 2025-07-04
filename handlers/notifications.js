const { sendNotification } = require('../services/notificationService');

module.exports.process = async (event) => {
    try {
        for (const record of event.Records) {
            const snsMessage = JSON.parse(record.Sns.Message);
            const message = JSON.parse(snsMessage.Message);
            console.log('Processing event:', message.eventType);

            switch (message.eventType) {
                case 'USER_CREATED':
                    await handleUserCreated(message.data);
                break;
                case 'ORDER_CREATED':
                    await handleOrderCreated(message.data);
                break;
                case 'PRODUCT_CREATED':
                    await handleProductCreated(message.data);
                break;
                default:
                    console.log('Unknown event type:', message.eventType);
                }
            }
            
            return { statusCode: 200, body: 'Events processed successfully'};
        } catch (error) {
            console.error('Error processing events:', error);
            return { statusCode: 500, body: 'Error processing events' };
        }
        
        };

        const handleUserCreated = async (userData) => 
        {
            const notifications = {
                type: 'USER_WELCOME',
                userId: userData.id,
                message: `Welcome ${userData.name} ! Your account has been created successfully.`, 
                timestamp: new Date().toISOString()
            };
        await sendNotification(notifications);
            console.log('Welcome notification sent for user:', userData.id);
    };

    const handleOrderCreated = async (orderData) => {
        const notifications = {
            type: 'ORDER_CONFIRMATION',
            userId: orderData.userId,
            orderId: orderData.id,
            message: `Order ${orderData.id} has been placed successfully. Total: $${orderData.totalAmount}`,
            timestamp: new Date().toISOString()
        };
            
        await sendNotification(notifications);
        console.log('Order placed notification sent for order:', orderData.id);
    };

    const handleProductCreated = async (productData) => {
        const notifications = {
            type: 'PRODUCT_NOTIFICATION',
            productId: productData.id,
            message: `New product added to the catalog in ${productData.category}: ${productData.name} category`,
            timestamp: new Date().toISOString()
        };
            
        await sendNotification(notifications);
        console.log('Product added notification sent for product:', productData.id);
    };


    
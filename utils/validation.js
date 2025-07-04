const Joi = require('joi');
const userSchema = Joi.object({
  name: Joi.string().min(2).max(50).required(),
  email: Joi.string().email().required(),
  age: Joi.number().integer().min(18).max(120).optional(),
  phone: Joi.string().pattern(/[+]?[1-9]\d{1,14}$/).optional()
});

const productSchema = Joi.object({
  name: Joi.string().min(2).max(100).required(),
  description: Joi.string().min(10).max(500).optional(),
  price: Joi.number().positive().required(),
  category: Joi.string().min(2).max(50).required(),
  stock: Joi.number().integer().min(0).optional(),
});

const orderSchema = Joi.object({
  userId: Joi.string().required(),
  productId: Joi.array().items(
    Joi.object({
        productId: Joi.string().required(),
        quantity: Joi.number().integer().min(1).required()
        })
  ).min(1).required(),
  shippingAddress: Joi.object(
    {street: Joi.string().required(), 
    city: Joi.string().required(), 
    zipCode: Joi.string().required(),
    country: Joi.string().required()}).required(),
});

const validateInput = (schema, data) => {
    const { error, value} = schema.validate(data);
    if (error) {
        throw new Error(error.details[0].message);
        Error(error.details[0].message);    
    }
    return value;
  };

module.exports = {
  userSchema,
  productSchema,
  orderSchema,
  validateInput,
};
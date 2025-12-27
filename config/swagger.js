const swaggerJsdoc = require('swagger-jsdoc');
const yaml = require('yamljs');
const path = require('path');

// Load YAML file
const swaggerSpec = yaml.load(path.join(__dirname, '../swagger.yaml'));

module.exports = swaggerSpec;


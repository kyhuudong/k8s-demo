
export const environment = {
  production: false,

  LOG_LEVEL: 'debug',

  server: {
    host: process.env.HOST || '0.0.0.0',
    domainUrl: process.env.DOMAIN_URL || 'http://localhost:3000',
    port: process.env.PORT ? Number(process.env.PORT) : 3000,
  },

  database: {
    type: 'mysql',
    host: process.env.TYPEORM_HOST || '127.0.0.1',
    port: process.env.TYPEORM_PORT ? Number(process.env.TYPEORM_PORT) : 3306,
    database: process.env.TYPEORM_DATABASE || 'testdb',
    username: process.env.TYPEORM_USERNAME || 'userdb',
    password: process.env.TYPEORM_PASSWORD || 'password',
    keepConnectionAlive: true,
    logging: process.env.TYPEORM_LOGGING ? JSON.parse(process.env.TYPEORM_LOGGING) : true,
    synchronize: process.env.TYPEORM_SYNCHRONIZE ? JSON.parse(process.env.TYPEORM_SYNCHRONIZE) : true,
  },

};
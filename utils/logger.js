const logLevels = {
  ERROR: 0,
  WARN: 1,
  INFO: 2,
  DEBUG: 3
};

const currentLogLevel = logLevels[process.env.LOG_LEVEL] || logLevels.INFO;

const log = (level, message, meta = {}) => {
  if (logLevels[level] <= currentLogLevel) {
    const logEntry = {
      timestamp: new Date().toISOString(),
      level,
      message,
      ...meta
    };
    console.log(JSON.stringify(logEntry));
  }
};

const logger = {
  error: (message, meta) => log('ERROR', message, meta),
  warn: (message, meta) => log('WARN', message, meta),
  info: (message, meta) => log('INFO', message, meta),
  debug: (message, meta) => log('DEBUG', message, meta)
};

module.exports = logger;
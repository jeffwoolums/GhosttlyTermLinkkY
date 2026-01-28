/**
 * Simple Logger
 */

const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

function timestamp() {
  return new Date().toISOString().slice(11, 19);
}

export const logger = {
  info(message) {
    console.log(`${colors.dim}[${timestamp()}]${colors.reset} ${colors.green}INFO${colors.reset}  ${message}`);
  },
  
  warn(message) {
    console.log(`${colors.dim}[${timestamp()}]${colors.reset} ${colors.yellow}WARN${colors.reset}  ${message}`);
  },
  
  error(message) {
    console.log(`${colors.dim}[${timestamp()}]${colors.reset} ${colors.red}ERROR${colors.reset} ${message}`);
  },
  
  debug(message) {
    if (process.env.DEBUG) {
      console.log(`${colors.dim}[${timestamp()}]${colors.reset} ${colors.cyan}DEBUG${colors.reset} ${message}`);
    }
  }
};

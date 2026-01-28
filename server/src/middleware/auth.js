/**
 * Authentication Middleware
 */

import jwt from 'jsonwebtoken';
import { config } from '../config.js';
import { logger } from '../utils/logger.js';

/**
 * Generate a session token
 */
export function generateToken(payload = {}) {
  return jwt.sign(
    {
      ...payload,
      iat: Date.now()
    },
    config.jwtSecret,
    { expiresIn: '24h' }
  );
}

/**
 * Verify a session token
 */
export function verifyToken(token) {
  try {
    const decoded = jwt.verify(token, config.jwtSecret);
    return decoded;
  } catch (error) {
    logger.warn(`Token verification failed: ${error.message}`);
    return null;
  }
}

/**
 * Express middleware for authenticated routes
 */
export function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  const token = authHeader.slice(7);
  const decoded = verifyToken(token);
  
  if (!decoded) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
  
  req.user = decoded;
  next();
}

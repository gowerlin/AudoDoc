/**
 * Express API Server
 */

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { WebSocketServer } from 'ws';
import { createServer } from 'http';
import { IncomingMessage } from 'http';
import jwt from 'jsonwebtoken';
import logger from './utils/logger';
import { AutoDocError } from './error/error_types';

const app = express();
const server = createServer(app);
const wss = new WebSocketServer({ server, path: '/ws', noServer: true });

// JWT secret from environment variable
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
if (JWT_SECRET === 'your-secret-key-change-in-production') {
  logger.warn('⚠️  Using default JWT_SECRET. Please set JWT_SECRET environment variable in production!');
}

// Rate limiting for WebSocket connections
interface RateLimitEntry {
  count: number;
  resetTime: number;
}
const wsRateLimiter = new Map<string, RateLimitEntry>();

function checkWsRateLimit(clientId: string, maxRequests: number = 60, windowMs: number = 60000): boolean {
  const now = Date.now();
  const limit = wsRateLimiter.get(clientId);

  if (!limit || now > limit.resetTime) {
    wsRateLimiter.set(clientId, { count: 1, resetTime: now + windowMs });
    return true;
  }

  if (limit.count >= maxRequests) {
    return false;
  }

  limit.count++;
  return true;
}

// Verify JWT token from WebSocket connection
function verifyWsToken(req: IncomingMessage): { valid: boolean; clientId?: string; error?: string } {
  try {
    // Extract token from query parameter or Authorization header
    const url = new URL(req.url!, `http://${req.headers.host}`);
    let token = url.searchParams.get('token');

    if (!token && req.headers.authorization) {
      const authHeader = req.headers.authorization;
      if (authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
      }
    }

    if (!token) {
      return { valid: false, error: 'No token provided' };
    }

    const decoded = jwt.verify(token, JWT_SECRET) as { clientId: string; exp: number };
    return { valid: true, clientId: decoded.clientId };
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return { valid: false, error: 'Token expired' };
    }
    if (error instanceof jwt.JsonWebTokenError) {
      return { valid: false, error: 'Invalid token' };
    }
    return { valid: false, error: 'Authentication failed' };
  }
}

// Middleware
app.use(helmet());

// Configure CORS with allowed origins
const allowedOrigins = [
  'http://localhost:5173',  // Vite dev server
  'http://localhost:3000',   // Desktop app proxy
  'tauri://localhost',       // Tauri protocol
  process.env.FRONTEND_URL,  // Production frontend URL
].filter(Boolean); // Remove undefined values

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) {
      return callback(null, true);
    }

    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`Origin ${origin} not allowed by CORS policy`));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 86400, // 24 hours
}));

app.use(express.json({ limit: '10mb' })); // Add request size limit
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use((req: Request, res: Response, next: NextFunction) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('user-agent'),
  });
  next();
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// API routes placeholder
app.get('/api', (req: Request, res: Response) => {
  res.json({
    name: 'AutoDoc Agent API',
    version: '1.0.0',
    description: 'AI-powered User Manual Generator',
  });
});

// Generate WebSocket authentication token
app.post('/api/auth/ws-token', (req: Request, res: Response) => {
  try {
    // In a production environment, you would validate user credentials here
    // For now, we generate a token for any request (suitable for desktop app)
    const clientId = `client-${Date.now()}-${Math.random().toString(36).substring(7)}`;

    const token = jwt.sign(
      { clientId },
      JWT_SECRET,
      { expiresIn: '24h' } // Token expires in 24 hours
    );

    logger.info('Generated WebSocket token', { clientId });

    res.json({
      token,
      clientId,
      expiresIn: '24h',
    });
  } catch (error) {
    logger.error('Failed to generate WebSocket token', { error });
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

// WebSocket upgrade handling with authentication
server.on('upgrade', (request, socket, head) => {
  // Verify the URL path
  const url = new URL(request.url!, `http://${request.headers.host}`);
  if (url.pathname !== '/ws') {
    socket.destroy();
    return;
  }

  // Verify authentication token
  const authResult = verifyWsToken(request);

  if (!authResult.valid) {
    logger.warn('WebSocket authentication failed', {
      ip: request.socket.remoteAddress,
      error: authResult.error
    });
    socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
    socket.destroy();
    return;
  }

  // Authenticate WebSocket upgrade
  wss.handleUpgrade(request, socket, head, (ws) => {
    wss.emit('connection', ws, request, authResult.clientId);
  });
});

// WebSocket connection handling (after authentication)
wss.on('connection', (ws, req, clientId: string) => {
  logger.info('WebSocket client connected', {
    ip: req.socket.remoteAddress,
    clientId
  });

  // Message handler with rate limiting
  ws.on('message', (message) => {
    try {
      // Check rate limit
      if (!checkWsRateLimit(clientId)) {
        logger.warn('Rate limit exceeded', { clientId });
        ws.send(JSON.stringify({
          type: 'error',
          message: 'Rate limit exceeded. Please slow down.',
        }));
        return;
      }

      const data = JSON.parse(message.toString());
      logger.debug('WebSocket message received', { clientId, data });

      // Handle different message types
      // TODO: Implement message handlers
    } catch (error) {
      logger.error('WebSocket message parse error', { error, clientId });
      ws.send(JSON.stringify({
        type: 'error',
        message: 'Invalid message format',
      }));
    }
  });

  ws.on('close', () => {
    logger.info('WebSocket client disconnected', { clientId });
    wsRateLimiter.delete(clientId);
  });

  ws.on('error', (error) => {
    logger.error('WebSocket error', { error, clientId });
  });

  // Send welcome message
  ws.send(JSON.stringify({
    type: 'connection',
    message: 'Connected to AutoDoc Agent',
    clientId,
    timestamp: new Date().toISOString(),
  }));
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AutoDocError) {
    logger.error(err.message, {
      code: err.code,
      statusCode: err.statusCode,
      details: err.details,
      stack: err.stack,
    });

    res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
  } else {
    logger.error('Unhandled error', { error: err.message, stack: err.stack });

    res.status(500).json({
      error: {
        code: 'INTERNAL_SERVER_ERROR',
        message: 'An unexpected error occurred',
      },
    });
  }
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    error: {
      code: 'NOT_FOUND',
      message: 'The requested resource was not found',
    },
  });
});

export { app, server, wss };
export default server;

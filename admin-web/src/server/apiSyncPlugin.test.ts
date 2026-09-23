import { describe, it, expect, vi, beforeEach } from 'vitest';
import { apiSyncPlugin } from './apiSyncPlugin';

// Mock fs and path so we don't actually write to files during tests
vi.mock('node:fs', () => ({
  default: {
    existsSync: vi.fn().mockReturnValue(true),
    readFileSync: vi.fn().mockReturnValue(JSON.stringify({ courts: [], venues: [], bookings: [] })),
    writeFileSync: vi.fn(),
    mkdirSync: vi.fn()
  }
}));

describe('apiSyncPlugin - Chatbot Endpoints', () => {
  let plugin: any;
  let middleware: (req: any, res: any, next: any) => Promise<void>;
  
  beforeEach(() => {
    plugin = apiSyncPlugin();
    
    // Extract middleware
    const mockServer = {
      middlewares: {
        use: (fn: any) => {
          middleware = fn;
        }
      }
    };
    plugin.configureServer(mockServer as any);
  });

  const createMockReqRes = (method: string, url: string, body?: any) => {
    let bodyStr = body ? JSON.stringify(body) : '';
    const req = {
      method,
      url,
      on: (event: string, callback: any) => {
        if (event === 'data' && bodyStr) {
          callback(Buffer.from(bodyStr));
        }
        if (event === 'end') {
          callback();
        }
      }
    } as any;

    let responseData = '';
    const res = {
      statusCode: 200,
      headers: {},
      setHeader: function(name: string, value: string) {
        this.headers[name] = value;
      },
      end: function(data: string) {
        responseData = data;
      }
    } as any;

    return { req, res, getResponse: () => responseData ? JSON.parse(responseData) : null };
  };

  it('GET /api/chatbot/config should return default config if not set', async () => {
    const { req, res, getResponse } = createMockReqRes('GET', '/api/chatbot/config');
    const next = vi.fn();
    
    await middleware(req, res, next);
    
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(200);
    expect(getResponse()).toHaveProperty('provider');
  });

  it('POST /api/chatbot/config should update config', async () => {
    const newConfig = { provider: 'openai', apiKey: 'sk-123', model: 'gpt-4o', systemPrompt: 'Test', temperature: 0.5, isActive: true };
    const { req, res, getResponse } = createMockReqRes('POST', '/api/chatbot/config', newConfig);
    const next = vi.fn();
    
    await middleware(req, res, next);
    
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(200);
    const response = getResponse();
    expect(response.success).toBe(true);
    expect(response.config.provider).toBe('openai');
  });

  it('GET /api/chatbot/faqs should return list of faqs', async () => {
    const { req, res, getResponse } = createMockReqRes('GET', '/api/chatbot/faqs');
    const next = vi.fn();
    
    await middleware(req, res, next);
    
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(getResponse())).toBe(true);
  });

  it('POST /api/chatbot/faqs should add a new faq', async () => {
    const newFaq = { question: 'Test?', answer: 'Yes', category: 'General', isActive: true };
    const { req, res, getResponse } = createMockReqRes('POST', '/api/chatbot/faqs', newFaq);
    const next = vi.fn();
    
    await middleware(req, res, next);
    
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(201);
    expect(getResponse().success).toBe(true);
  });

  it('GET /api/chatbot/conversations should return conversations list', async () => {
    const { req, res, getResponse } = createMockReqRes('GET', '/api/chatbot/conversations');
    const next = vi.fn();
    
    await middleware(req, res, next);
    
    expect(next).not.toHaveBeenCalled();
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(getResponse())).toBe(true);
  });
});

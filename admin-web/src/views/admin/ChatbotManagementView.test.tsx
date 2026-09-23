import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import ChatbotManagementView from './ChatbotManagementView';
import { useChatbotStore } from '../../store/chatbotStore';

vi.mock('../../store/chatbotStore', () => ({
  useChatbotStore: vi.fn(),
}));

describe('ChatbotManagementView', () => {
  const mockUpdateConfig = vi.fn();
  const mockAddFaq = vi.fn();
  const mockUpdateFaq = vi.fn();
  const mockDeleteFaq = vi.fn();
  
  beforeEach(() => {
    vi.clearAllMocks();
    (useChatbotStore as any).mockReturnValue({
      config: {
        provider: 'gemini',
        apiKey: 'test-api-key',
        model: 'gemini-1.5-flash',
        systemPrompt: 'Test prompt',
        temperature: 0.7,
        isActive: true,
      },
      faqs: [
        {
          id: 'faq_1',
          question: 'Test Question',
          answer: 'Test Answer',
          category: 'Chung',
          isActive: true,
        }
      ],
      conversations: [
        {
          id: 'conv_1',
          userName: 'User A',
          messages: [
            { sender: 'user', text: 'hello', timestamp: '2023-10-10' },
            { sender: 'assistant', text: 'hi there', timestamp: '2023-10-10' }
          ],
          bookingCreated: true,
          createdAt: '2023-10-10'
        }
      ],
      updateConfig: mockUpdateConfig,
      addFaq: mockAddFaq,
      updateFaq: mockUpdateFaq,
      deleteFaq: mockDeleteFaq,
    });
  });

  it('renders tabs and AI config by default', () => {
    render(<ChatbotManagementView />);
    expect(screen.getByText('Cấu hình AI & API Key')).toBeInTheDocument();
    expect(screen.getByText('Kiến thức & FAQ')).toBeInTheDocument();
    expect(screen.getByText('Lịch sử & Phân tích')).toBeInTheDocument();

    // Check config inputs
    expect(screen.getByDisplayValue('test-api-key')).toBeInTheDocument();
    expect(screen.getByDisplayValue('Test prompt')).toBeInTheDocument();
  });

  it('submits API key & prompt form', () => {
    render(<ChatbotManagementView />);
    
    // Change api key
    const apiKeyInput = screen.getByTestId('api-key-input');
    fireEvent.change(apiKeyInput, { target: { value: 'new-api-key' } });
    
    // Change prompt
    const promptInput = screen.getByTestId('system-prompt-textarea');
    fireEvent.change(promptInput, { target: { value: 'New prompt' } });

    // Submit
    const saveBtn = screen.getByTestId('save-config-btn');
    fireEvent.click(saveBtn);

    expect(mockUpdateConfig).toHaveBeenCalledWith(expect.objectContaining({
      apiKey: 'new-api-key',
      systemPrompt: 'New prompt'
    }));
  });

  it('opens FAQ modal and submits a new FAQ', async () => {
    render(<ChatbotManagementView />);
    
    // Go to FAQ tab
    fireEvent.click(screen.getByText('Kiến thức & FAQ'));
    
    // Open modal
    fireEvent.click(screen.getByText('Thêm câu hỏi mới'));
    
    // Fill in new FAQ
    const questionInput = screen.getByTestId('faq-question-input');
    const answerInput = screen.getByTestId('faq-answer-textarea');
    
    fireEvent.change(questionInput, { target: { value: 'New test question?' } });
    fireEvent.change(answerInput, { target: { value: 'New test answer.' } });
    
    // Save
    const saveBtn = screen.getByTestId('save-faq-btn');
    fireEvent.click(saveBtn);
    
    expect(mockAddFaq).toHaveBeenCalledWith(expect.objectContaining({
      question: 'New test question?',
      answer: 'New test answer.'
    }));
  });

  it('clicks a conversation to open and view the transcript modal', () => {
    render(<ChatbotManagementView />);
    
    // Go to Analytics tab
    fireEvent.click(screen.getByText('Lịch sử & Phân tích'));
    
    // Click conversation
    const convRow = screen.getByTestId('conversation-row');
    fireEvent.click(convRow);
    
    // Expect transcript modal to show messages
    expect(screen.getByText('Đoạn chat với User A')).toBeInTheDocument();
    expect(screen.getByText('hello')).toBeInTheDocument();
    expect(screen.getByText('hi there')).toBeInTheDocument();
    
    // Close modal
    fireEvent.click(screen.getByText('Đóng'));
    expect(screen.queryByText('Đoạn chat với User A')).not.toBeInTheDocument();
  });
});

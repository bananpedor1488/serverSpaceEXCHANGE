import { io, Socket } from 'socket.io-client';

const WS_URL = 'http://178.104.40.37:25593';

class SocketService {
  private socket: Socket | null = null;

  connect(userId: string) {
    if (this.socket?.connected) return;

    this.socket = io(WS_URL);
    
    this.socket.on('connect', () => {
      console.log('✅ WebSocket connected');
      this.socket?.emit('register', { user_id: userId });
    });

    this.socket.on('disconnect', () => {
      console.log('❌ WebSocket disconnected');
    });
  }

  disconnect() {
    this.socket?.disconnect();
    this.socket = null;
  }

  joinChat(chatId: string) {
    this.socket?.emit('join_chat', { chat_id: chatId });
  }

  sendMessage(chatId: string, senderIdentityId: string, encryptedContent: string, type = 'text') {
    this.socket?.emit('send_message', {
      chat_id: chatId,
      sender_identity_id: senderIdentityId,
      encrypted_content: encryptedContent,
      type,
    });
  }

  onMessage(callback: (message: any) => void) {
    this.socket?.on('receive_message', callback);
  }

  onIdentityUpdate(callback: (identity: any) => void) {
    this.socket?.on('identity_updated', callback);
  }

  onTyping(callback: (data: any) => void) {
    this.socket?.on('typing', callback);
  }

  sendTyping(chatId: string, identityId: string) {
    this.socket?.emit('typing', { chat_id: chatId, identity_id: identityId });
  }
}

export const socketService = new SocketService();

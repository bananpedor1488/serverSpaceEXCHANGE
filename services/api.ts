const API_URL = 'http://localhost:3000';

export const api = {
  async register(deviceId: string, publicKey: string) {
    const res = await fetch(`${API_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ device_id: deviceId, public_key: publicKey }),
    });
    return res.json();
  },

  async toggleEphemeral(deviceId: string, enabled: boolean) {
    const res = await fetch(`${API_URL}/auth/toggle-ephemeral`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ device_id: deviceId, enabled }),
    });
    return res.json();
  },

  async createChat(identityIds: string[], isGroup = false) {
    const res = await fetch(`${API_URL}/chat/create`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ identity_ids: identityIds, is_group: isGroup }),
    });
    return res.json();
  },

  async getUserChats(identityId: string) {
    const res = await fetch(`${API_URL}/chat/user/${identityId}`);
    return res.json();
  },
};

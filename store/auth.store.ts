import { create } from 'zustand';

interface Identity {
  _id: string;
  username: string;
  avatar_seed: string;
  expires_at: string | null;
}

interface AuthState {
  deviceId: string | null;
  userId: string | null;
  identity: Identity | null;
  ephemeralEnabled: boolean;
  setAuth: (userId: string, identity: Identity) => void;
  setDeviceId: (deviceId: string) => void;
  setIdentity: (identity: Identity) => void;
  setEphemeralEnabled: (enabled: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  deviceId: null,
  userId: null,
  identity: null,
  ephemeralEnabled: false,
  setAuth: (userId, identity) => set({ userId, identity }),
  setDeviceId: (deviceId) => set({ deviceId }),
  setIdentity: (identity) => set({ identity }),
  setEphemeralEnabled: (enabled) => set({ ephemeralEnabled: enabled }),
  logout: () => set({ deviceId: null, userId: null, identity: null, ephemeralEnabled: false }),
}));

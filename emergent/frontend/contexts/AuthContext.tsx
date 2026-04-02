import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { apiCall } from '../utils/api';

type User = {
  id: string;
  email: string;
  name: string;
  role: string;
  token: string;
  metro_card_balance?: number;
} | null;

type AuthContextType = {
  user: User;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  updateUser: (data: Partial<NonNullable<User>>) => void;
};

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  login: async () => {},
  register: async () => {},
  logout: async () => {},
  updateUser: () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadUser();
  }, []);

  async function loadUser() {
    try {
      const stored = await AsyncStorage.getItem('user');
      if (stored) {
        const parsed = JSON.parse(stored);
        setUser(parsed);
      }
    } catch (e) {
      // ignore
    } finally {
      setLoading(false);
    }
  }

  async function login(email: string, password: string) {
    const data = await apiCall('/auth/login', {
      method: 'POST',
      body: { email, password },
    });
    const userData = { ...data };
    setUser(userData);
    await AsyncStorage.setItem('user', JSON.stringify(userData));
  }

  async function register(name: string, email: string, password: string) {
    const data = await apiCall('/auth/register', {
      method: 'POST',
      body: { name, email, password },
    });
    const userData = { ...data };
    setUser(userData);
    await AsyncStorage.setItem('user', JSON.stringify(userData));
  }

  async function logout() {
    try {
      if (user?.token) {
        await apiCall('/auth/logout', { method: 'POST', token: user.token });
      }
    } catch (e) {}
    setUser(null);
    await AsyncStorage.removeItem('user');
  }

  function updateUser(data: Partial<NonNullable<User>>) {
    if (user) {
      const updated = { ...user, ...data };
      setUser(updated);
      AsyncStorage.setItem('user', JSON.stringify(updated));
    }
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, updateUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}

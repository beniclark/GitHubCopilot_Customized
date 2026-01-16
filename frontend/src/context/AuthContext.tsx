import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface AuthContextType {
  isLoggedIn: boolean;
  isAdmin: boolean;
  userEmail: string | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isLoggedIn, setIsLoggedIn] = useState(() => {
    return localStorage.getItem('isLoggedIn') === 'true';
  });
  const [isAdmin, setIsAdmin] = useState(() => {
    return localStorage.getItem('isAdmin') === 'true';
  });
  const [userEmail, setUserEmail] = useState<string | null>(() => {
    return localStorage.getItem('userEmail');
  });

  // Persist auth state to localStorage
  useEffect(() => {
    if (isLoggedIn) {
      localStorage.setItem('isLoggedIn', 'true');
      localStorage.setItem('isAdmin', isAdmin.toString());
      if (userEmail) {
        localStorage.setItem('userEmail', userEmail);
      }
    } else {
      localStorage.removeItem('isLoggedIn');
      localStorage.removeItem('isAdmin');
      localStorage.removeItem('userEmail');
    }
  }, [isLoggedIn, isAdmin, userEmail]);

  const login = async (email: string, password: string) => {
    // In a real app, you would validate credentials with an API
    // For now, we'll just check the email domain
    if (email && password) {
      setIsLoggedIn(true);
      setIsAdmin(email.endsWith('@github.com'));
      setUserEmail(email);
    }
  };

  const logout = () => {
    setIsLoggedIn(false);
    setIsAdmin(false);
    setUserEmail(null);
  };

  return (
    <AuthContext.Provider value={{ isLoggedIn, isAdmin, userEmail, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
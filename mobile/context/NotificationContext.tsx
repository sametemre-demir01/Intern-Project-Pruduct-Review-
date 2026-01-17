// Notification Context for local notification state management
import React, { createContext, useContext, useState, useCallback, ReactNode, useEffect } from 'react';
import { getPriceDrops, PriceDrop } from '../services/api';

export type NotificationType = 'review' | 'order' | 'system' | 'price_drop';

export interface Notification {
  id: string;
  type: NotificationType;
  title: string;
  body: string;
  timestamp: Date;
  isRead: boolean;
  data?: {
    productId?: string;
    productName?: string;
  };
}

interface NotificationContextType {
  notifications: Notification[];
  unreadCount: number;
  addNotification: (notification: Omit<Notification, 'id' | 'timestamp' | 'isRead'>) => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
  clearNotification: (id: string) => void;
  clearAll: () => void;
}

const NotificationContext = createContext<NotificationContextType | undefined>(undefined);

export const NotificationProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [notifications, setNotifications] = useState<Notification[]>([
    // Demo notifications
    {
      id: '1',
      type: 'system',
      title: 'Welcome to ProductReview!',
      body: 'Start exploring products and leave your first review.',
      timestamp: new Date(Date.now() - 1000 * 60 * 30), // 30 mins ago
      isRead: false,
    },
    {
      id: '2',
      type: 'order',
      title: 'Your order is on its way',
      body: 'Order #12345 has been shipped and will arrive in 2-3 days.',
      timestamp: new Date(Date.now() - 1000 * 60 * 60 * 2), // 2 hours ago
      isRead: true,
    },
  ]);

  // Fetch price drops from API on mount
  useEffect(() => {
    const fetchPriceDrops = async () => {
      try {
        const priceDrops = await getPriceDrops();
        const priceDropNotifications: Notification[] = priceDrops.map((drop: PriceDrop) => ({
          id: `price-drop-${drop.productId}-${drop.changedAt}`,
          type: 'price_drop',
          title: 'Price Drop Alert! 📉',
          body: `${drop.productName} is now $${drop.newPrice.toFixed(2)} (was $${drop.oldPrice.toFixed(2)}, ${drop.changePercent.toFixed(1)}% off)`,
          timestamp: new Date(drop.changedAt),
          isRead: false,
          data: {
            productId: drop.productId.toString(),
            productName: drop.productName,
          },
        }));
        
        // Add new price drop notifications (avoid duplicates)
        setNotifications(prev => {
          const existingIds = new Set(prev.map(n => n.id));
          const newNotifications = priceDropNotifications.filter(n => !existingIds.has(n.id));
          return [...newNotifications, ...prev];
        });
      } catch (error) {
        console.warn('Failed to fetch price drops:', error);
      }
    };

    fetchPriceDrops();
  }, []);

  const unreadCount = notifications.filter((n) => !n.isRead).length;

  const addNotification = useCallback(
    (notification: Omit<Notification, 'id' | 'timestamp' | 'isRead'>) => {
      const newNotification: Notification = {
        ...notification,
        id: `notif-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        timestamp: new Date(),
        isRead: false,
      };
      setNotifications((prev) => [newNotification, ...prev]);
    },
    []
  );

  const markAsRead = useCallback((id: string) => {
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
    );
  }, []);

  const markAllAsRead = useCallback(() => {
    setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
  }, []);

  const clearNotification = useCallback((id: string) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id));
  }, []);

  const clearAll = useCallback(() => {
    setNotifications([]);
  }, []);

  return (
    <NotificationContext.Provider
      value={{
        notifications,
        unreadCount,
        addNotification,
        markAsRead,
        markAllAsRead,
        clearNotification,
        clearAll,
      }}
    >
      {children}
    </NotificationContext.Provider>
  );
};

export const useNotifications = () => {
  const context = useContext(NotificationContext);
  if (!context) {
    throw new Error('useNotifications must be used within a NotificationProvider');
  }
  return context;
};

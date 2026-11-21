import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../services/api';
import { ENDPOINTS, NOTIFICATION_POLL_MS } from '../config';
import { useToast } from './Toast';
import { Bell, CheckCheck } from 'lucide-react';

// Where clicking a notification takes the admin
const targetFor = (n) => {
  if (n.type === 'account_pending') return '/dashboard/users?filter=pending';
  if (n.order) return `/dashboard/orders?order=${n.order}`;
  if (n.type === 'product_pending') return '/dashboard/products?filter=pending';
  if (n.product) return '/dashboard/products';
  return null;
};

const timeAgo = (date) => {
  const minutes = Math.floor((Date.now() - new Date(date).getTime()) / 60000);
  if (minutes < 1) return 'à l\'instant';
  if (minutes < 60) return `il y a ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `il y a ${hours} h`;
  return new Date(date).toLocaleDateString('fr-FR');
};

export default function NotificationBell() {
  const [notifications, setNotifications] = useState([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [open, setOpen] = useState(false);
  const seenIds = useRef(null); // null until the first load, so old notifications don't pop up
  const panelRef = useRef(null);
  const navigate = useNavigate();
  const toast = useToast();

  const fetchNotifications = async () => {
    try {
      const response = await api.get(ENDPOINTS.NOTIFICATIONS, { params: { limit: 30 } });
      if (!response.success) return;
      const list = response.data.notifications;

      if (seenIds.current) {
        list
          .filter((n) => !n.isRead && !seenIds.current.has(n._id))
          .reverse()
          .forEach((n) => toast.info(`${n.title} — ${n.message}`, 8000));
      }
      seenIds.current = new Set(list.map((n) => n._id));

      setNotifications(list);
      setUnreadCount(response.data.unreadCount);
    } catch {
      // Network hiccup: try again on the next tick
    }
  };

  useEffect(() => {
    fetchNotifications();
    const timer = setInterval(fetchNotifications, NOTIFICATION_POLL_MS);
    return () => clearInterval(timer);
  }, []);

  // Close the panel when clicking outside
  useEffect(() => {
    const onClick = (e) => {
      if (panelRef.current && !panelRef.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('mousedown', onClick);
    return () => document.removeEventListener('mousedown', onClick);
  }, []);

  const openNotification = async (n) => {
    setOpen(false);
    if (!n.isRead) {
      setNotifications((list) => list.map((x) => (x._id === n._id ? { ...x, isRead: true } : x)));
      setUnreadCount((c) => Math.max(0, c - 1));
      api.put(ENDPOINTS.NOTIFICATION_READ(n._id)).catch(() => {});
    }
    const target = targetFor(n);
    if (target) navigate(target);
  };

  const markAllAsRead = async () => {
    try {
      await api.put(ENDPOINTS.NOTIFICATIONS_READ_ALL);
      setNotifications((list) => list.map((x) => ({ ...x, isRead: true })));
      setUnreadCount(0);
    } catch {
      toast.error('Erreur lors de la mise à jour');
    }
  };

  return (
    <div className="relative" ref={panelRef}>
      <button
        onClick={() => setOpen(!open)}
        className="p-2 rounded-lg hover:bg-gray-100 transition-colors relative"
        title="Notifications"
      >
        <Bell className="w-6 h-6 text-gray-600" />
        {unreadCount > 0 && (
          <span className="absolute -top-0.5 -right-0.5 min-w-[1.25rem] h-5 px-1 bg-red-500 text-white text-xs font-bold rounded-full flex items-center justify-center">
            {unreadCount > 99 ? '99+' : unreadCount}
          </span>
        )}
      </button>

      {open && (
        <div className="absolute right-0 mt-2 w-[22rem] max-w-[calc(100vw-2rem)] bg-white rounded-xl shadow-2xl border border-gray-200 z-50">
          <div className="flex items-center justify-between px-4 py-3 border-b">
            <p className="font-semibold">Notifications</p>
            {unreadCount > 0 && (
              <button onClick={markAllAsRead} className="text-sm text-primary-600 hover:underline flex items-center gap-1">
                <CheckCheck className="w-4 h-4" /> Tout lire
              </button>
            )}
          </div>
          <div className="max-h-[28rem] overflow-y-auto divide-y">
            {notifications.length === 0 ? (
              <p className="text-sm text-gray-500 text-center py-8">Aucune notification</p>
            ) : (
              notifications.map((n) => (
                <button
                  key={n._id}
                  onClick={() => openNotification(n)}
                  className={`w-full text-left px-4 py-3 hover:bg-gray-50 ${n.isRead ? '' : 'bg-primary-50/60'}`}
                >
                  <div className="flex items-start gap-2">
                    {!n.isRead && <span className="mt-1.5 w-2 h-2 rounded-full bg-primary-500 shrink-0" />}
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-gray-900">{n.title}</p>
                      <p className="text-sm text-gray-600">{n.message}</p>
                      <p className="text-xs text-gray-400 mt-1">{timeAgo(n.createdAt)}</p>
                    </div>
                  </div>
                </button>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

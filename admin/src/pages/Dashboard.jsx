import React, { useState, useEffect } from 'react';
import { Routes, Route, Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import api from '../services/api';
import { ENDPOINTS } from '../config';
import {
  LayoutDashboard, Users, Package, ShoppingCart, FolderTree,
  LogOut, Menu, X, User
} from 'lucide-react';

const isDesktop = () => window.matchMedia('(min-width: 768px)').matches;

// Import management pages (we'll create these)
import DashboardHome from '../components/DashboardHome';
import UsersPage from '../components/UsersPage';
import ProductsPage from '../components/ProductsPage';
import OrdersPage from '../components/OrdersPage';
import CategoriesPage from '../components/CategoriesPage';
import NotificationBell from '../components/NotificationBell';

export default function Dashboard() {
  // Closed by default on phones, where it covers the page
  const [sidebarOpen, setSidebarOpen] = useState(isDesktop);
  const [counts, setCounts] = useState({});
  const { user, logout } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  // Pending work shown as badges in the menu, refreshed on each page change
  useEffect(() => {
    api.get(ENDPOINTS.STATS)
      .then((res) => {
        if (!res.success) return;
        const s = res.data;
        setCounts({
          users: (s.pendingMerchants || 0) + (s.pendingDelivery || 0),
          products: s.pendingProducts || 0,
          orders: s.unassignedOrders || 0,
        });
      })
      .catch(() => {}); // badges are optional
  }, [location.pathname]);

  // On phones the menu covers the page: close it once a page is picked
  const closeOnMobile = () => {
    if (!isDesktop()) setSidebarOpen(false);
  };

  const menuItems = [
    { icon: LayoutDashboard, label: 'Tableau de bord', path: '' },
    { icon: Users, label: 'Utilisateurs', path: 'users', badge: counts.users, hint: 'compte(s) à vérifier' },
    { icon: Package, label: 'Produits', path: 'products', badge: counts.products, hint: 'produit(s) à approuver' },
    { icon: ShoppingCart, label: 'Commandes', path: 'orders', badge: counts.orders, hint: 'commande(s) à assigner' },
    { icon: FolderTree, label: 'Catégories', path: 'categories' },
  ];

  const handleLogout = () => {
    if (window.confirm('Êtes-vous sûr de vouloir vous déconnecter?')) {
      logout();
      navigate('/');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-64 transform overflow-y-auto transition-transform duration-300 bg-white border-r border-gray-200 shadow-xl
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} md:translate-x-0`}
      >
        <div className="h-full flex flex-col">
          {/* Logo */}
          <div className="p-6 border-b border-gray-200">
            <div className="flex items-center space-x-3">
              <img src="/logo-192.png" alt="Tumaï Market" className="w-10 h-10 rounded-xl shadow-sm" />
              <div>
                <p className="font-bold text-lg">Tumaï Market</p>
                <p className="text-xs text-gray-500">Administration</p>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav className="flex-1 p-4 overflow-y-auto">
            <ul className="space-y-2">
              {menuItems.map((item) => {
                const Icon = item.icon;
                const fullPath = item.path === '' ? '/dashboard' : `/dashboard/${item.path}`;
                const isActive = location.pathname === fullPath;

                return (
                  <li key={item.path}>
                    <Link
                      to={fullPath}
                      onClick={closeOnMobile}
                      className={`flex items-center space-x-3 px-4 py-3 rounded-lg transition-colors ${
                        isActive
                          ? 'bg-primary-50 text-primary-600 font-medium'
                          : 'text-gray-700 hover:bg-gray-100'
                      }`}
                    >
                      <Icon className="w-5 h-5" />
                      <span className="flex-1">{item.label}</span>
                      {item.badge > 0 && (
                        <span
                          title={`${item.badge} ${item.hint}`}
                          className="min-w-[1.5rem] px-1.5 py-0.5 rounded-full bg-yellow-400 text-yellow-900 text-xs font-bold text-center"
                        >
                          {item.badge}
                        </span>
                      )}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </nav>

          {/* User Section */}
          <div className="p-4 border-t border-gray-200">
            <div className="flex items-center space-x-3 mb-3">
              <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                <User className="w-6 h-6 text-primary-600" />
              </div>
              <div className="flex-1">
                <p className="font-medium text-sm">{user?.name}</p>
                <p className="text-xs text-gray-500">{user?.phone}</p>
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="flex items-center space-x-2 text-red-600 hover:bg-red-50 px-4 py-2 rounded-lg transition-colors w-full"
            >
              <LogOut className="w-5 h-5" />
              <span>Déconnexion</span>
            </button>
          </div>
        </div>
      </aside>

      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 z-30 bg-black/40 md:hidden"
        />
      )}

      {/* Main Content */}
      <div className="min-h-screen transition-all duration-300 md:ml-64">
        {/* Top Bar */}
        <header className="bg-white border-b border-gray-200 sticky top-0 z-30">
          <div className="flex flex-col gap-4 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6 lg:px-8">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="p-2 rounded-lg hover:bg-gray-100 transition-colors md:hidden"
            >
              {sidebarOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>

            <div className="flex items-center justify-between w-full sm:justify-end sm:space-x-4">
              <NotificationBell />
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="p-6">
          <Routes>
            <Route index element={<DashboardHome />} />
            <Route path="users" element={<UsersPage />} />
            <Route path="products" element={<ProductsPage />} />
            <Route path="orders" element={<OrdersPage />} />
            <Route path="categories" element={<CategoriesPage />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}
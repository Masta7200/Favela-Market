import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../services/api';
import { ENDPOINTS, CURRENCY, ROLE_LABELS, getOrderStatus, BADGE_CLASSES } from '../config';
import { Users, Package, ShoppingCart, DollarSign, Store, Truck, PackageSearch, AlertTriangle, RefreshCw } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function DashboardHome() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await api.get(ENDPOINTS.STATS);
      if (response.success) {
        setStats(response.data);
      }
    } catch (err) {
      console.error('Error fetching stats:', err);
      setError(err?.message || 'Impossible de charger les statistiques');
    } finally {
      setLoading(false);
    }
  };

  if (loading && !stats) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      </div>
    );
  }

  const statCards = [
    {
      title: 'Total Utilisateurs',
      value: stats?.totalUsers || 0,
      hint: ['client', 'merchant', 'delivery']
        .map((role) => `${stats?.usersByRole?.[role] || 0} ${ROLE_LABELS[role].toLowerCase()}(s)`)
        .join(' · '),
      icon: Users,
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-600',
    },
    {
      title: 'Produits',
      value: stats?.totalProducts || 0,
      hint: `${stats?.totalCategories || 0} catégorie(s)`,
      icon: Package,
      bgColor: 'bg-green-50',
      textColor: 'text-green-600',
    },
    {
      title: 'Commandes',
      value: stats?.totalOrders || 0,
      icon: ShoppingCart,
      bgColor: 'bg-purple-50',
      textColor: 'text-purple-600',
    },
    {
      title: 'Revenus (commandes livrées)',
      value: `${(stats?.totalRevenue || 0).toLocaleString()} ${CURRENCY}`,
      icon: DollarSign,
      bgColor: 'bg-orange-50',
      textColor: 'text-orange-600',
    },
  ];

  // Work waiting for the admin
  const todoCards = [
    { title: 'Marchands à vérifier', value: stats?.pendingMerchants || 0, icon: Store, to: '/dashboard/users?filter=pending' },
    { title: 'Livreurs à vérifier', value: stats?.pendingDelivery || 0, icon: Truck, to: '/dashboard/users?filter=pending' },
    { title: 'Produits à approuver', value: stats?.pendingProducts || 0, icon: PackageSearch, to: '/dashboard/products?filter=pending' },
    { title: 'Commandes à assigner', value: stats?.unassignedOrders || 0, icon: AlertTriangle, to: '/dashboard/orders?filter=unassigned',
      hint: `${stats?.availableDelivery || 0} livreur(s) en ligne` },
  ];

  const chartData = stats?.monthlyRevenue || [];
  const recentOrders = stats?.recentOrders || [];
  const hasChartData = chartData.some((m) => m.revenue > 0 || m.orders > 0);

  return (
    <div className="space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Tableau de bord</h1>
          <p className="text-gray-600">Bienvenue sur votre panneau d'administration</p>
        </div>
        <button onClick={fetchStats} disabled={loading} className="btn btn-secondary flex items-center gap-2">
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          Actualiser
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">{error}</div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.title} className="card">
              <div className="flex items-center justify-between mb-4">
                <div className={`w-12 h-12 ${stat.bgColor} rounded-xl flex items-center justify-center`}>
                  <Icon className={`w-6 h-6 ${stat.textColor}`} />
                </div>
              </div>
              <h3 className="text-gray-600 text-sm mb-1">{stat.title}</h3>
              <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
              {stat.hint && <p className="text-xs text-gray-400 mt-1">{stat.hint}</p>}
            </div>
          );
        })}
      </div>

      <div>
        <h2 className="text-lg font-bold mb-3">À traiter</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {todoCards.map((card) => {
            const Icon = card.icon;
            const urgent = card.value > 0;
            return (
              <Link
                key={card.title}
                to={card.to}
                className={`card flex items-center gap-4 transition hover:shadow-md ${urgent ? 'ring-2 ring-yellow-300' : ''}`}
              >
                <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${urgent ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-500'}`}>
                  <Icon className="w-6 h-6" />
                </div>
                <div>
                  <p className="text-2xl font-bold text-gray-900">{card.value}</p>
                  <p className="text-sm text-gray-600">{card.title}</p>
                  {card.hint && <p className="text-xs text-gray-400">{card.hint}</p>}
                </div>
              </Link>
            );
          })}
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        <div className="card">
          <h3 className="text-lg font-bold mb-1">Revenus mensuels</h3>
          <p className="text-sm text-gray-500 mb-4">6 derniers mois · commandes livrées</p>
          {hasChartData ? (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" />
                <YAxis tickFormatter={(v) => (v >= 1000 ? `${Math.round(v / 1000)}k` : v)} />
                <Tooltip
                  formatter={(value, key) =>
                    key === 'revenue' ? [`${value.toLocaleString()} ${CURRENCY}`, 'Revenus'] : [value, 'Commandes']
                  }
                />
                <Area type="monotone" dataKey="revenue" stroke="#2E7D32" fill="#C8E6C9" />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[300px] flex items-center justify-center text-gray-400 text-sm">
              Aucune commande sur les 6 derniers mois
            </div>
          )}
        </div>

        <div className="card">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold">Commandes récentes</h3>
            <Link to="/dashboard/orders" className="text-sm text-primary-600 hover:underline">Tout voir</Link>
          </div>
          {recentOrders.length === 0 ? (
            <p className="text-gray-400 text-sm py-8 text-center">Aucune commande pour le moment</p>
          ) : (
            <div className="space-y-3">
              {recentOrders.map((order) => {
                const status = getOrderStatus(order.status);
                return (
                  <Link
                    key={order._id}
                    to={`/dashboard/orders?order=${order._id}`}
                    className="flex items-center justify-between gap-3 p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
                  >
                    <div className="min-w-0">
                      <p className="font-medium truncate">
                        {order.orderNumber || `#${order._id.slice(-6)}`} · {order.customerName}
                      </p>
                      <p className="text-sm text-gray-500">
                        {timeAgo(order.createdAt)} · {(order.total || 0).toLocaleString()} {CURRENCY}
                      </p>
                    </div>
                    <span className={`badge shrink-0 ${BADGE_CLASSES[status.color] || BADGE_CLASSES.gray}`}>
                      {status.label}
                    </span>
                  </Link>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function timeAgo(date) {
  const minutes = Math.floor((Date.now() - new Date(date).getTime()) / 60000);
  if (minutes < 1) return "À l'instant";
  if (minutes < 60) return `Il y a ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `Il y a ${hours} h`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `Il y a ${days} j`;
  return new Date(date).toLocaleDateString('fr-FR');
}

import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import api from '../services/api';
import { ENDPOINTS, CURRENCY } from '../config';
import { Users, Package, ShoppingCart, DollarSign, Store, Truck, PackageSearch, AlertTriangle } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function DashboardHome() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await api.get(ENDPOINTS.STATS);
      if (response.success) {
        setStats(response.data);
      }
    } catch (error) {
      console.error('Error fetching stats:', error);
      // Set default stats on error
      setStats({
        totalUsers: 0,
        totalProducts: 0,
        totalOrders: 0,
        totalRevenue: 0
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
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
      icon: Users,
      color: 'blue',
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-600',
    },
    {
      title: 'Produits',
      value: stats?.totalProducts || 0,
      icon: Package,
      color: 'green',
      bgColor: 'bg-green-50',
      textColor: 'text-green-600',
    },
    {
      title: 'Commandes',
      value: stats?.totalOrders || 0,
      icon: ShoppingCart,
      color: 'purple',
      bgColor: 'bg-purple-50',
      textColor: 'text-purple-600',
    },
    {
      title: 'Revenus',
      value: `${(stats?.totalRevenue || 0).toLocaleString()} ${CURRENCY}`,
      icon: DollarSign,
      color: 'orange',
      bgColor: 'bg-orange-50',
      textColor: 'text-orange-600',
    },
  ];

  // Work waiting for the admin
  const todoCards = [
    { title: 'Marchands à vérifier', value: stats?.pendingMerchants || 0, icon: Store, to: '/dashboard/users?filter=pending' },
    { title: 'Livreurs à vérifier', value: stats?.pendingDelivery || 0, icon: Truck, to: '/dashboard/users?filter=pending' },
    { title: 'Produits à approuver', value: stats?.pendingProducts || 0, icon: PackageSearch, to: '/dashboard/products' },
    { title: 'Commandes à assigner', value: stats?.unassignedOrders || 0, icon: AlertTriangle, to: '/dashboard/orders?filter=unassigned',
      hint: `${stats?.availableDelivery || 0} livreur(s) en ligne` },
  ];

  const chartData = [
    { name: 'Jan', value: 4000 },
    { name: 'Fév', value: 3000 },
    { name: 'Mar', value: 5000 },
    { name: 'Avr', value: 4500 },
    { name: 'Mai', value: 6000 },
    { name: 'Juin', value: 5500 },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Tableau de bord</h1>
        <p className="text-gray-600">Bienvenue sur votre panneau d'administration</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {statCards.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={index} className="card">
              <div className="flex items-center justify-between mb-4">
                <div className={`w-12 h-12 ${stat.bgColor} rounded-xl flex items-center justify-center`}>
                  <Icon className={`w-6 h-6 ${stat.textColor}`} />
                </div>
              </div>
              <h3 className="text-gray-600 text-sm mb-1">{stat.title}</h3>
              <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
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
          <h3 className="text-lg font-bold mb-4">Revenus Mensuels</h3>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" />
              <YAxis />
              <Tooltip />
              <Area type="monotone" dataKey="value" stroke="#2E7D32" fill="#C8E6C9" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <h3 className="text-lg font-bold mb-4">Activité Récente</h3>
          <div className="space-y-3">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="font-medium">Commande #{1000 + i}</p>
                  <p className="text-sm text-gray-500">Il y a {i} heure(s)</p>
                </div>
                <span className="badge bg-green-100 text-green-700">Confirmé</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
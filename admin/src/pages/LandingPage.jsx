import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { ShoppingBag, TrendingUp, Users, Package, BarChart3, Shield, Zap, Globe } from 'lucide-react';

export default function LandingPage() {
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const result = await login(phone, password);
    
    if (result.success) {
      navigate('/dashboard');
    } else {
      setError(result.message);
    }
    
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 via-white to-secondary-50">
      {/* Navbar */}
      <nav className="bg-white/80 backdrop-blur-md shadow-sm sticky top-0 z-50">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-xl flex items-center justify-center">
                <ShoppingBag className="w-6 h-6 text-white" />
              </div>
              <span className="text-2xl font-bold bg-gradient-to-r from-primary-600 to-secondary-600 bg-clip-text text-transparent">
                Favela Market
              </span>
            </div>
            <a href="#login" className="btn btn-primary">
              Connexion Admin
            </a>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-6 py-20">
        <div className="grid lg:grid-cols-2 gap-12 items-center">
          <div>
            <h1 className="text-5xl lg:text-6xl font-bold mb-6 leading-tight">
              <span className="bg-gradient-to-r from-primary-600 to-secondary-600 bg-clip-text text-transparent">
                Gérez Votre
              </span>
              <br />
              Marketplace en Toute Simplicité
            </h1>
            <p className="text-xl text-gray-600 mb-8">
              Tableau de bord administrateur complet pour Favela Market. 
              Gérez les vendeurs, produits, commandes et bien plus encore.
            </p>
            <div className="flex flex-wrap gap-4">
              <a href="#login" className="btn btn-primary text-lg px-8 py-3">
                Commencer
              </a>
              <a href="#features" className="btn btn-secondary text-lg px-8 py-3">
                En savoir plus
              </a>
            </div>
          </div>
          
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-br from-primary-500/20 to-secondary-500/20 rounded-3xl blur-3xl"></div>
            <div className="relative bg-white rounded-3xl shadow-2xl p-8">
              <div className="grid grid-cols-2 gap-4">
                <StatCard icon={Users} label="Utilisateurs" value="1,234" color="blue" />
                <StatCard icon={Package} label="Produits" value="856" color="green" />
                <StatCard icon={ShoppingBag} label="Commandes" value="432" color="purple" />
                <StatCard icon={TrendingUp} label="Revenus" value="2.4M" color="orange" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="bg-white py-20">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold mb-4">Fonctionnalités Puissantes</h2>
            <p className="text-xl text-gray-600">
              Tout ce dont vous avez besoin pour gérer votre marketplace
            </p>
          </div>
          
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            <FeatureCard
              icon={Users}
              title="Gestion Utilisateurs"
              description="Gérez clients, vendeurs et livreurs depuis un seul endroit"
            />
            <FeatureCard
              icon={Package}
              title="Produits & Catalogues"
              description="Approuvez, modifiez et organisez les produits facilement"
            />
            <FeatureCard
              icon={BarChart3}
              title="Analytics Avancées"
              description="Suivez les ventes, revenus et performances en temps réel"
            />
            <FeatureCard
              icon={Shield}
              title="Sécurité Renforcée"
              description="Protection des données et contrôle d'accès avancé"
            />
            <FeatureCard
              icon={ShoppingBag}
              title="Gestion Commandes"
              description="Suivez et gérez toutes les commandes de la plateforme"
            />
            <FeatureCard
              icon={Zap}
              title="Rapide & Réactif"
              description="Interface moderne et ultra-rapide pour une productivité maximale"
            />
            <FeatureCard
              icon={Globe}
              title="Multi-Devises"
              description="Support de plusieurs devises et langues"
            />
            <FeatureCard
              icon={TrendingUp}
              title="Rapports Détaillés"
              description="Exportez et analysez vos données business"
            />
          </div>
        </div>
      </section>

      {/* Login Section */}
      <section id="login" className="py-20">
        <div className="container mx-auto px-6">
          <div className="max-w-md mx-auto">
            <div className="card">
              <div className="text-center mb-8">
                <div className="w-16 h-16 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <Shield className="w-8 h-8 text-white" />
                </div>
                <h2 className="text-3xl font-bold mb-2">Connexion Admin</h2>
                <p className="text-gray-600">
                  Accédez au tableau de bord administrateur
                </p>
              </div>

              <form onSubmit={handleLogin} className="space-y-4">
                {error && (
                  <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded-lg">
                    {error}
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Numéro de téléphone
                  </label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+235600000000"
                    className="input"
                    required
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Mot de passe
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="input"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="btn btn-primary w-full text-lg py-3"
                >
                  {loading ? 'Connexion...' : 'Se connecter'}
                </button>
              </form>

              <div className="mt-6 pt-6 border-t border-gray-200">
                <p className="text-sm text-gray-500 text-center">
                  Compte de test: <br />
                  <span className="font-mono text-gray-700">+237600000000 / admin123</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="container mx-auto px-6">
          <div className="grid md:grid-cols-3 gap-8">
            <div>
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-10 h-10 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-xl flex items-center justify-center">
                  <ShoppingBag className="w-6 h-6 text-white" />
                </div>
                <span className="text-xl font-bold">Favela Market</span>
              </div>
              <p className="text-gray-400">
                Votre marketplace de confiance pour tous vos achats au Tchad.
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Liens Rapides</h3>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white transition">À propos</a></li>
                <li><a href="#" className="hover:text-white transition">Contact</a></li>
                <li><a href="#" className="hover:text-white transition">Conditions</a></li>
                <li><a href="#" className="hover:text-white transition">Confidentialité</a></li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold mb-4">Contact</h3>
              <ul className="space-y-2 text-gray-400">
                <li>Email: contact@favelamarket.cm</li>
                <li>Tél: +235 99507200</li>
                <li>N'Djamena, Tchad</li>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
            <p>&copy; 2024 Favela Market. Tous droits réservés.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}

function StatCard({ icon: Icon, label, value, color }) {
  const colorClasses = {
    blue: 'from-blue-500 to-blue-600',
    green: 'from-green-500 to-green-600',
    purple: 'from-purple-500 to-purple-600',
    orange: 'from-orange-500 to-orange-600',
  };

  return (
    <div className="bg-gradient-to-br from-gray-50 to-white p-6 rounded-2xl border border-gray-100">
      <div className={`w-12 h-12 bg-gradient-to-br ${colorClasses[color]} rounded-xl flex items-center justify-center mb-3`}>
        <Icon className="w-6 h-6 text-white" />
      </div>
      <p className="text-gray-600 text-sm mb-1">{label}</p>
      <p className="text-2xl font-bold text-gray-900">{value}</p>
    </div>
  );
}

function FeatureCard({ icon: Icon, title, description }) {
  return (
    <div className="bg-gradient-to-br from-white to-gray-50 p-6 rounded-2xl border border-gray-100 hover:shadow-lg transition-shadow">
      <div className="w-12 h-12 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-xl flex items-center justify-center mb-4">
        <Icon className="w-6 h-6 text-white" />
      </div>
      <h3 className="text-xl font-bold mb-2">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </div>
  );
}
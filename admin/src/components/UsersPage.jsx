import { useState, useEffect } from 'react';
import api from '../services/api';
import { ENDPOINTS } from '../config';
import { useToast } from './Toast';
import { Search, Edit, Trash2, Eye, X, UserPlus, Check, ChevronLeft, ChevronRight } from 'lucide-react';

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [modalMode, setModalMode] = useState('create'); // 'create', 'edit', 'view'
  const [selectedUser, setSelectedUser] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;
  const toast = useToast();

  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    password: '',
    role: 'client',
    isActive: true,
    // Merchant fields
    shopName: '',
    shopDescription: '',
    shopAddress: '',
    shopPhone: '',
    isApproved: false,
    // Delivery fields
    vehicleType: 'moto',
    vehicleNumber: '',
  });

  useEffect(() => {
    fetchUsers();
  }, [filter]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await api.get(ENDPOINTS.USERS, {
        params: { role: filter !== 'all' ? filter : undefined }
      });
      if (response.success) {
        setUsers(response.data.users);
      }
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (mode, user = null) => {
    setModalMode(mode);
    setSelectedUser(user);
    if (user) {
      setFormData({
        name: user.name || '',
        phone: user.phone || '',
        email: user.email || '',
        password: '',
        role: user.role || 'client',
        isActive: user.isActive !== undefined ? user.isActive : true,
        shopName: user.shopName || '',
        shopDescription: user.shopDescription || '',
        shopAddress: user.shopAddress || '',
        shopPhone: user.shopPhone || '',
        isApproved: user.isApproved || false,
        vehicleType: user.vehicleType || 'moto',
        vehicleNumber: user.vehicleNumber || '',
      });
    } else {
      setFormData({
        name: '',
        phone: '',
        email: '',
        password: '',
        role: 'client',
        isActive: true,
        shopName: '',
        shopDescription: '',
        shopAddress: '',
        shopPhone: '',
        isApproved: false,
        vehicleType: 'moto',
        vehicleNumber: '',
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedUser(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      const payload = {
        name: formData.name,
        phone: formData.phone,
        email: formData.email,
        role: formData.role,
        isActive: formData.isActive,
      };

      // Add password only for create or if provided for edit
      if (modalMode === 'create' || formData.password) {
        payload.password = formData.password;
      }

      // Add role-specific fields
      if (formData.role === 'merchant') {
        payload.shopName = formData.shopName;
        payload.shopDescription = formData.shopDescription;
        payload.shopAddress = formData.shopAddress;
        payload.shopPhone = formData.shopPhone;
        payload.isApproved = formData.isApproved;
      } else if (formData.role === 'delivery') {
        payload.vehicleType = formData.vehicleType;
        payload.vehicleNumber = formData.vehicleNumber;
        payload.isApproved = formData.isApproved;
      }

      if (modalMode === 'create') {
        await api.post(ENDPOINTS.USERS, payload);
        toast.success('Utilisateur créé avec succès');
      } else {
        await api.put(`${ENDPOINTS.USERS}/${selectedUser._id}`, payload);
        toast.success('Utilisateur mis à jour avec succès');
      }

      handleCloseModal();
      fetchUsers();
    } catch (error) {
      toast.error(error.message || 'Erreur lors de l\'opération');
    }
  };

  const handleDelete = async (userId, userName) => {
    if (!window.confirm(`Êtes-vous sûr de vouloir supprimer l'utilisateur "${userName}" ?`)) {
      return;
    }

    try {
      await api.delete(`${ENDPOINTS.USERS}/${userId}`);
      toast.success('Utilisateur supprimé avec succès');
      fetchUsers();
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la suppression');
    }
  };

  const toggleUserStatus = async (userId, isActive) => {
    try {
      await api.put(`${ENDPOINTS.USERS}/${userId}/toggle-status`, { isActive: !isActive });
      toast.success('Statut mis à jour');
      fetchUsers();
    } catch (error) {
      toast.error('Erreur lors de la mise à jour');
    }
  };

  const filteredUsers = users.filter(user =>
    user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    user.phone.includes(searchQuery)
  );

  // Pagination
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedUsers = filteredUsers.slice(startIndex, startIndex + itemsPerPage);

  // Reset to page 1 when search or filter changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, filter]);

  const getRoleBadge = (role) => {
    const badges = {
      client: 'bg-blue-100 text-blue-700',
      merchant: 'bg-purple-100 text-purple-700',
      delivery: 'bg-orange-100 text-orange-700',
      admin: 'bg-red-100 text-red-700',
    };
    return badges[role] || 'bg-gray-100 text-gray-700';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Utilisateurs</h1>
          <p className="text-gray-600 mt-1">Gérez tous les utilisateurs de la plateforme ({users.length} total)</p>
        </div>
        <button
          onClick={() => handleOpenModal('create')}
          className="btn btn-primary flex items-center space-x-2"
        >
          <UserPlus className="w-5 h-5" />
          <span>Nouvel utilisateur</span>
        </button>
      </div>

      {/* Filters & Search */}
      <div className="card">
        <div className="flex flex-col md:flex-row gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
              <input
                type="text"
                aria-label="Chercher des utilisateurs"
                placeholder="Rechercher par nom ou téléphone..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full border rounded-lg pl-10 pr-4 py-2 text-sm placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
            </div>
          <div className="flex gap-2 flex-wrap">
            {['all', 'client', 'merchant', 'delivery', 'admin'].map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  filter === f
                    ? 'bg-primary-500 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {f === 'all' ? 'Tous' : f.charAt(0).toUpperCase() + f.slice(1)}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="card overflow-hidden p-0">
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
          </div>
        ) : filteredUsers.length === 0 ? (
          <div className="text-center py-12">
            <p className="text-gray-500">Aucun utilisateur trouvé</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Utilisateur</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Téléphone</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Rôle</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {paginatedUsers.map((user) => (
                  <tr key={user._id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="flex items-center">
                        <div className="w-10 h-10 bg-primary-100 rounded-full flex items-center justify-center">
                          <span className="font-semibold text-primary-600">
                            {user.name.charAt(0).toUpperCase()}
                          </span>
                        </div>
                        <div className="ml-3">
                          <p className="font-medium text-gray-900">{user.name}</p>
                          {user.email && (
                            <p className="text-sm text-gray-500">{user.email}</p>
                          )}
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-900">{user.phone}</td>
                    <td className="px-6 py-4">
                      <span className={`badge ${getRoleBadge(user.role)}`}>
                        {user.role}
                      </span>
                      {(user.role === 'merchant' || user.role === 'delivery') && (
                        <span className={`ml-2 badge ${user.isApproved ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'}`}>
                          {user.isApproved ? 'Approuvé' : 'En attente'}
                        </span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`badge ${user.isActive ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                        {user.isActive ? 'Actif' : 'Inactif'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(user.createdAt).toLocaleDateString('fr-FR')}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end space-x-2">
                        <button
                          onClick={() => handleOpenModal('view', user)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition"
                          title="Voir les détails"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal('edit', user)}
                          className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition"
                          title="Modifier"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        {user.role !== 'admin' && (
                          <button
                            onClick={() => handleDelete(user._id, user.name)}
                            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        {!loading && totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200">
            <p className="text-sm text-gray-600">
              Affichage de {startIndex + 1} à {Math.min(startIndex + itemsPerPage, filteredUsers.length)} sur {filteredUsers.length}
            </p>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage === 1}
                className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
              {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
                let page;
                if (totalPages <= 5) {
                  page = i + 1;
                } else if (currentPage <= 3) {
                  page = i + 1;
                } else if (currentPage >= totalPages - 2) {
                  page = totalPages - 4 + i;
                } else {
                  page = currentPage - 2 + i;
                }
                return (
                  <button
                    key={page}
                    onClick={() => setCurrentPage(page)}
                    className={`px-4 py-2 rounded-lg font-medium transition-all ${
                      currentPage === page
                        ? 'bg-primary-500 text-white'
                        : 'border border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    {page}
                  </button>
                );
              })}
              <button
                onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                disabled={currentPage === totalPages}
                className="p-2 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Modal for Create/Edit/View */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-2xl font-bold">
                {modalMode === 'create' && 'Créer un utilisateur'}
                {modalMode === 'edit' && 'Modifier l\'utilisateur'}
                {modalMode === 'view' && 'Détails de l\'utilisateur'}
              </h2>
              <button
                onClick={handleCloseModal}
                className="p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-6" autoComplete="off" noValidate>
              {/* Hidden dummy fields to reduce browser autofill */}
              <input type="text" name="no_autofill_username" autoComplete="off" style={{ display: 'none' }} />
              <input type="password" name="no_autofill_password" autoComplete="new-password" style={{ display: 'none' }} />
              {/* Basic Information */}
              <div className="space-y-4">
                <h3 className="font-semibold text-lg border-b pb-2">Informations de base</h3>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nom complet *
                  </label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({...formData, name: e.target.value})}
                    className="input"
                    required
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Numéro de téléphone *
                  </label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({...formData, phone: e.target.value})}
                    className="input"
                    placeholder="+237600000000"
                    required
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email *
                  </label>
                  <input
                    type="email"
                    name="user_email"
                    autoComplete="off"
                    value={formData.email}
                    onChange={(e) => setFormData({...formData, email: e.target.value})}
                    className="input"
                    required
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Mot de passe {modalMode === 'create' ? '*' : '(laisser vide pour ne pas changer)'}
                  </label>
                  <input
                    type="password"
                    name="user_password"
                    autoComplete="new-password"
                    value={formData.password}
                    onChange={(e) => setFormData({...formData, password: e.target.value})}
                    className="input"
                    minLength={6}
                    required={modalMode === 'create'}
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Rôle *
                  </label>
                  <select
                    value={formData.role}
                    onChange={(e) => setFormData({...formData, role: e.target.value})}
                    className="input"
                    required
                    disabled={modalMode === 'view'}
                  >
                    <option value="client">Client</option>
                    <option value="merchant">Marchand</option>
                    <option value="admin">Admin</option>
                    <option value="delivery">Livreur</option>
                  </select>
                </div>

                <div className="flex items-center space-x-3">
                  <input
                    type="checkbox"
                    id="isActive"
                    checked={formData.isActive}
                    onChange={(e) => setFormData({...formData, isActive: e.target.checked})}
                    className="w-4 h-4 text-primary-600"
                    disabled={modalMode === 'view'}
                  />
                  <label htmlFor="isActive" className="text-sm font-medium text-gray-700">
                    Compte actif
                  </label>
                </div>
              </div>

              {/* Merchant-specific fields */}
              {formData.role === 'merchant' && (
                <div className="space-y-4">
                  <h3 className="font-semibold text-lg border-b pb-2">Informations Boutique</h3>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nom de la boutique *
                    </label>
                    <input
                      type="text"
                      value={formData.shopName}
                      onChange={(e) => setFormData({...formData, shopName: e.target.value})}
                      className="input"
                      required
                      disabled={modalMode === 'view'}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Description
                    </label>
                    <textarea
                      value={formData.shopDescription}
                      onChange={(e) => setFormData({...formData, shopDescription: e.target.value})}
                      className="input"
                      rows={3}
                      disabled={modalMode === 'view'}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Adresse de la boutique
                    </label>
                    <input
                      type="text"
                      value={formData.shopAddress}
                      onChange={(e) => setFormData({...formData, shopAddress: e.target.value})}
                      className="input"
                      disabled={modalMode === 'view'}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Téléphone de la boutique
                    </label>
                    <input
                      type="tel"
                      value={formData.shopPhone}
                      onChange={(e) => setFormData({...formData, shopPhone: e.target.value})}
                      className="input"
                      disabled={modalMode === 'view'}
                    />
                  </div>

                  <div className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      id="isApproved"
                      checked={formData.isApproved}
                      onChange={(e) => setFormData({...formData, isApproved: e.target.checked})}
                      className="w-4 h-4 text-primary-600"
                      disabled={modalMode === 'view'}
                    />
                    <label htmlFor="isApproved" className="text-sm font-medium text-gray-700">
                      Marchand approuvé
                    </label>
                  </div>
                </div>
              )}

              {/* Delivery-specific fields */}
              {formData.role === 'delivery' && (
                <div className="space-y-4">
                  <h3 className="font-semibold text-lg border-b pb-2">Informations Véhicule</h3>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Type de véhicule *
                    </label>
                    <select
                      value={formData.vehicleType}
                      onChange={(e) => setFormData({...formData, vehicleType: e.target.value})}
                      className="input"
                      required
                      disabled={modalMode === 'view'}
                    >
                      <option value="moto">Moto</option>
                      <option value="velo">Vélo</option>
                      <option value="voiture">Voiture</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Numéro de plaque *
                    </label>
                    <input
                      type="text"
                      value={formData.vehicleNumber}
                      onChange={(e) => setFormData({...formData, vehicleNumber: e.target.value})}
                      className="input"
                      required
                      disabled={modalMode === 'view'}
                    />
                  </div>

                  <div className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      id="isApprovedDelivery"
                      checked={formData.isApproved}
                      onChange={(e) => setFormData({...formData, isApproved: e.target.checked})}
                      className="w-4 h-4 text-primary-600"
                      disabled={modalMode === 'view'}
                    />
                    <label htmlFor="isApprovedDelivery" className="text-sm font-medium text-gray-700">
                      Livreur approuvé
                    </label>
                  </div>
                </div>
              )}

              {/* Action Buttons */}
              {modalMode !== 'view' && (
                <div className="flex justify-end space-x-3 pt-4 border-t">
                  <button
                    type="button"
                    onClick={handleCloseModal}
                    className="btn bg-gray-100 text-gray-700 hover:bg-gray-200"
                  >
                    Annuler
                  </button>
                  <button
                    type="submit"
                    className="btn btn-primary flex items-center space-x-2"
                  >
                    <Check className="w-5 h-5" />
                    <span>{modalMode === 'create' ? 'Créer' : 'Mettre à jour'}</span>
                  </button>
                </div>
              )}
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
import { useState, useEffect } from 'react';
import api from '../services/api';
import { ENDPOINTS } from '../config';
import { useToast } from './Toast';
import { Plus, Edit, Trash2, FolderTree, X, Save, Search, ToggleLeft, ToggleRight, ChevronLeft, ChevronRight } from 'lucide-react';

export default function CategoriesPage() {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;
  const toast = useToast();

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    image: '',
    order: 0,
    isActive: true
  });

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      setLoading(true);
      const response = await api.get(ENDPOINTS.CATEGORIES);
      if (response.success) {
        setCategories(response.data.categories || []);
      }
    } catch (error) {
      console.error('Error fetching categories:', error);
      toast.error('Erreur lors du chargement des catégories');
    } finally {
      setLoading(false);
    }
  };

  const openCreateModal = () => {
    setEditingCategory(null);
    setFormData({ name: '', description: '', image: '', order: 0, isActive: true });
    setShowModal(true);
  };

  const openEditModal = (category) => {
    setEditingCategory(category);
    setFormData({
      name: category.name,
      description: category.description || '',
      image: category.image || '',
      order: category.order || 0,
      isActive: category.isActive !== undefined ? category.isActive : true
    });
    setShowModal(true);
  };

  const toggleCategoryStatus = async (categoryId) => {
    try {
      await api.put(`${ENDPOINTS.CATEGORIES}/${categoryId}/toggle-status`);
      fetchCategories();
      toast.success('Statut mis à jour');
    } catch (error) {
      toast.error('Erreur lors du changement de statut');
    }
  };

  const filteredCategories = categories.filter(cat =>
    cat.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    cat.description?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Pagination
  const totalPages = Math.ceil(filteredCategories.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedCategories = filteredCategories.slice(startIndex, startIndex + itemsPerPage);

  // Reset to page 1 when search changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery]);

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      if (editingCategory) {
        await api.put(ENDPOINTS.CATEGORY_BY_ID(editingCategory._id), formData);
        toast.success('Catégorie mise à jour avec succès');
      } else {
        await api.post(ENDPOINTS.CATEGORIES, formData);
        toast.success('Catégorie créée avec succès');
      }

      setShowModal(false);
      fetchCategories();
    } catch (error) {
      toast.error(error.message || 'Erreur lors de l\'opération');
    }
  };

  const deleteCategory = async (categoryId) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer cette catégorie?')) return;

    try {
      await api.delete(ENDPOINTS.CATEGORY_BY_ID(categoryId));
      fetchCategories();
      toast.success('Catégorie supprimée avec succès');
    } catch (error) {
      // Show the actual error message from backend
      const errorMessage = error.message || 'Erreur lors de la suppression';
      toast.error(errorMessage);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Catégories</h1>
          <p className="text-gray-600 mt-1">Organisez vos produits par catégorie ({categories.length} total)</p>
        </div>
        <button
          onClick={openCreateModal}
          className="btn btn-primary flex items-center space-x-2"
        >
          <Plus className="w-5 h-5" />
          <span>Nouvelle Catégorie</span>
        </button>
      </div>

      {/* Search Bar */}
      <div className="card">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Rechercher une catégorie..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all"
          />
        </div>
      </div>

      {/* Categories Grid */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
        </div>
      ) : filteredCategories.length === 0 ? (
        <div className="card text-center py-12">
          <FolderTree className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-500 mb-4">
            {searchQuery ? 'Aucune catégorie trouvée pour cette recherche' : 'Aucune catégorie créée'}
          </p>
          {!searchQuery && (
            <button
              onClick={openCreateModal}
              className="btn btn-primary"
            >
              Créer votre première catégorie
            </button>
          )}
        </div>
      ) : (
        <>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {paginatedCategories.map((category) => (
            <div key={category._id} className={`card hover:shadow-lg transition-all ${!category.isActive ? 'opacity-60' : ''}`}>
              <div className="flex items-start justify-between mb-4">
                <div className="w-14 h-14 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-xl flex items-center justify-center overflow-hidden">
                  {category.image ? (
                    <img src={category.image} alt={category.name} className="w-full h-full object-cover" />
                  ) : (
                    <FolderTree className="w-7 h-7 text-white" />
                  )}
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => toggleCategoryStatus(category._id)}
                    className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                    title={category.isActive ? 'Désactiver' : 'Activer'}
                  >
                    {category.isActive ? (
                      <ToggleRight className="w-5 h-5 text-green-600" />
                    ) : (
                      <ToggleLeft className="w-5 h-5 text-gray-400" />
                    )}
                  </button>
                  <button
                    onClick={() => openEditModal(category)}
                    className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                  >
                    <Edit className="w-4 h-4 text-gray-600" />
                  </button>
                  <button
                    onClick={() => deleteCategory(category._id)}
                    className="p-2 hover:bg-red-50 rounded-lg transition-colors"
                  >
                    <Trash2 className="w-4 h-4 text-red-600" />
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-2 mb-2">
                <h3 className="text-xl font-bold">{category.name}</h3>
                {!category.isActive && (
                  <span className="badge bg-gray-100 text-gray-600 text-xs">Inactif</span>
                )}
              </div>

              {category.description && (
                <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                  {category.description}
                </p>
              )}

              <div className="flex items-center justify-between pt-3 border-t border-gray-100">
                <span className="text-sm text-gray-500">
                  Ordre: {category.order || 0}
                </span>
                <button
                  onClick={() => openEditModal(category)}
                  className="text-primary-600 text-sm font-medium hover:text-primary-700"
                >
                  Modifier
                </button>
              </div>
            </div>
          ))}
        </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-6">
              <p className="text-sm text-gray-600">
                Affichage de {startIndex + 1} à {Math.min(startIndex + itemsPerPage, filteredCategories.length)} sur {filteredCategories.length}
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
        </>
      )}

      {/* Create/Edit Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-md w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <h2 className="text-2xl font-bold">
                {editingCategory ? 'Modifier la catégorie' : 'Nouvelle catégorie'}
              </h2>
              <button
                onClick={() => setShowModal(false)}
                className="p-2 hover:bg-gray-100 rounded-xl transition"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-5">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Nom de la catégorie *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="input"
                  placeholder="Ex: Électronique, Vêtements..."
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Description
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="input"
                  rows="3"
                  placeholder="Décrivez cette catégorie..."
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  URL de l'image
                </label>
                <input
                  type="url"
                  value={formData.image}
                  onChange={(e) => setFormData({ ...formData, image: e.target.value })}
                  className="input"
                  placeholder="https://..."
                />
              </div>

              {/* Image Preview */}
              {formData.image && (
                <div className="border rounded-xl p-4">
                  <p className="text-sm font-medium text-gray-700 mb-2">Aperçu:</p>
                  <div className="w-20 h-20 bg-gray-100 rounded-xl overflow-hidden">
                    <img
                      src={formData.image}
                      alt="Aperçu"
                      className="w-full h-full object-cover"
                      onError={(e) => e.target.style.display = 'none'}
                    />
                  </div>
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Ordre d'affichage
                </label>
                <input
                  type="number"
                  value={formData.order}
                  onChange={(e) => setFormData({ ...formData, order: parseInt(e.target.value) || 0 })}
                  className="input"
                  min="0"
                  placeholder="0"
                />
                <p className="text-xs text-gray-500 mt-1">Les catégories avec un ordre inférieur s'affichent en premier</p>
              </div>

              <div>
                <label className="flex items-center space-x-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={formData.isActive}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                    className="w-5 h-5 text-primary-600 rounded"
                  />
                  <span className="text-sm font-medium text-gray-700">Catégorie active</span>
                </label>
                <p className="text-xs text-gray-500 mt-1 ml-8">Les catégories inactives ne sont pas visibles sur le site</p>
              </div>

              <div className="flex gap-3 pt-4 border-t">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="flex-1 btn bg-gray-100 text-gray-700 hover:bg-gray-200"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="flex-1 btn btn-primary flex items-center justify-center space-x-2"
                >
                  <Save className="w-5 h-5" />
                  <span>{editingCategory ? 'Mettre à jour' : 'Créer'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
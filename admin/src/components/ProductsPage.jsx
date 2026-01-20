import { useState, useEffect } from 'react';
import api from '../services/api';
import { ENDPOINTS, CURRENCY } from '../config';
import { useToast } from './Toast';
import { Search, Check, X, Edit, Trash2, Plus, Package, Eye, Image, ChevronLeft, ChevronRight } from 'lucide-react';

export default function ProductsPage() {
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [merchants, setMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [modalMode, setModalMode] = useState('create');
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;
  const toast = useToast();

  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    comparePrice: '',
    stock: '',
    image: '',
    category: '',
    merchant: '',
    tags: '',
    isActive: true
  });

  useEffect(() => {
    fetchProducts();
    fetchCategories();
    fetchMerchants();
  }, [filter]);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const response = await api.get(ENDPOINTS.PRODUCTS, {
        params: { status: filter !== 'all' ? filter : undefined }
      });
      if (response.success) {
        setProducts(response.data.products || []);
      }
    } catch (error) {
      console.error('Error fetching products:', error);
      setProducts([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      const response = await api.get(ENDPOINTS.CATEGORIES);
      if (response.success) {
        setCategories(response.data.categories || []);
      }
    } catch (error) {
      console.error('Error fetching categories:', error);
    }
  };

  const fetchMerchants = async () => {
    try {
      const response = await api.get(ENDPOINTS.USERS, { params: { role: 'merchant' } });
      if (response.success) {
        setMerchants(response.data.users || []);
      }
    } catch (error) {
      console.error('Error fetching merchants:', error);
    }
  };

  const handleOpenModal = (mode, product = null) => {
    setModalMode(mode);
    setSelectedProduct(product);
    if (product) {
      setFormData({
        name: product.name || '',
        description: product.description || '',
        price: product.price || '',
        comparePrice: product.comparePrice || '',
        stock: product.stock || '',
        image: product.image || '',
        category: product.category?._id || product.category || '',
        merchant: product.merchant?._id || product.merchant || '',
        tags: product.tags?.join(', ') || '',
        isActive: product.isActive !== undefined ? product.isActive : true
      });
    } else {
      setFormData({
        name: '',
        description: '',
        price: '',
        comparePrice: '',
        stock: '',
        image: '',
        category: '',
        merchant: '',
        tags: '',
        isActive: true
      });
    }
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setSelectedProduct(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        name: formData.name,
        description: formData.description,
        price: Number(formData.price),
        comparePrice: formData.comparePrice ? Number(formData.comparePrice) : undefined,
        stock: Number(formData.stock) || 0,
        image: formData.image,
        category: formData.category,
        merchant: formData.merchant,
        tags: formData.tags ? formData.tags.split(',').map(t => t.trim()).filter(Boolean) : [],
        isActive: formData.isActive
      };

      if (modalMode === 'create') {
        await api.post(ENDPOINTS.PRODUCTS, payload);
        toast.success('Produit créé avec succès');
      } else if (modalMode === 'edit') {
        await api.put(ENDPOINTS.PRODUCT_BY_ID(selectedProduct._id), payload);
        toast.success('Produit mis à jour avec succès');
      }

      handleCloseModal();
      fetchProducts();
    } catch (error) {
      toast.error(error.message || 'Erreur lors de l\'opération');
    }
  };

  const approveProduct = async (productId) => {
    try {
      await api.put(ENDPOINTS.APPROVE_PRODUCT(productId));
      fetchProducts();
      toast.success('Produit approuvé avec succès');
    } catch (error) {
      toast.error('Erreur lors de l\'approbation');
    }
  };

  const rejectProduct = async (productId) => {
    if (!window.confirm('Êtes-vous sûr de vouloir rejeter ce produit?')) return;
    try {
      await api.put(ENDPOINTS.REJECT_PRODUCT(productId));
      fetchProducts();
      toast.success('Produit rejeté');
    } catch (error) {
      toast.error('Erreur lors du rejet');
    }
  };

  const deleteProduct = async (productId) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer ce produit?')) return;
    try {
      await api.delete(ENDPOINTS.PRODUCT_BY_ID(productId));
      fetchProducts();
      toast.success('Produit supprimé');
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la suppression');
    }
  };

  const filteredProducts = products.filter(product =>
    product.name?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.merchantName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
    product.categoryName?.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // Pagination
  const totalPages = Math.ceil(filteredProducts.length / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const paginatedProducts = filteredProducts.slice(startIndex, startIndex + itemsPerPage);

  // Reset to page 1 when search or filter changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, filter]);

  const getStatusBadge = (status, isApproved) => {
    if (status === 'rejected') return 'bg-red-100 text-red-700';
    if (!isApproved) return 'bg-yellow-100 text-yellow-700';
    return 'bg-green-100 text-green-700';
  };

  const getStatusText = (status, isApproved) => {
    if (status === 'rejected') return 'Rejeté';
    if (!isApproved) return 'En attente';
    return 'Approuvé';
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Produits</h1>
          <p className="text-gray-600 mt-1">Gérez tous les produits de la plateforme ({products.length} total)</p>
        </div>
        <button
          onClick={() => handleOpenModal('create')}
          className="btn btn-primary flex items-center space-x-2"
        >
          <Plus className="w-5 h-5" />
          <span>Nouveau produit</span>
        </button>
      </div>

      {/* Filters & Search */}
      <div className="card">
        <div className="flex flex-col lg:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher par nom, vendeur ou catégorie..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-12 pr-4 py-3 border border-gray-300 rounded-xl focus:ring-2 focus:ring-primary-500 focus:border-primary-500 transition-all"
            />
          </div>
          <div className="flex gap-2 flex-wrap">
            {[
              { key: 'all', label: 'Tous' },
              { key: 'pending', label: 'En attente' },
              { key: 'approved', label: 'Approuvés' },
              { key: 'rejected', label: 'Rejetés' }
            ].map((f) => (
              <button
                key={f.key}
                onClick={() => setFilter(f.key)}
                className={`px-4 py-2 rounded-xl font-medium transition-all ${
                  filter === f.key
                    ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
        </div>
      ) : filteredProducts.length === 0 ? (
        <div className="card text-center py-12">
          <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-500 text-lg">
            {searchQuery ? 'Aucun produit trouvé pour cette recherche' : 'Aucun produit trouvé'}
          </p>
          {!searchQuery && (
            <p className="text-gray-400 mt-2">Ajoutez un nouveau produit pour commencer</p>
          )}
        </div>
      ) : (
        <>
        <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {paginatedProducts.map((product) => (
            <div key={product._id} className="card p-0 overflow-hidden hover:shadow-xl transition-all duration-300 group">
              {/* Product Image */}
              <div className="h-48 bg-gradient-to-br from-gray-100 to-gray-200 relative overflow-hidden">
                {product.image ? (
                  <img
                    src={product.image}
                    alt={product.name}
                    className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center">
                    <Image className="w-16 h-16 text-gray-300" />
                  </div>
                )}
                <div className="absolute top-3 right-3">
                  <span className={`badge ${getStatusBadge(product.status, product.isApproved)}`}>
                    {getStatusText(product.status, product.isApproved)}
                  </span>
                </div>
                {/* Quick Actions Overlay */}
                <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center gap-2">
                  <button
                    onClick={() => handleOpenModal('view', product)}
                    className="p-2 bg-white rounded-full text-blue-600 hover:bg-blue-50 transition"
                    title="Voir"
                  >
                    <Eye className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => handleOpenModal('edit', product)}
                    className="p-2 bg-white rounded-full text-green-600 hover:bg-green-50 transition"
                    title="Modifier"
                  >
                    <Edit className="w-5 h-5" />
                  </button>
                  <button
                    onClick={() => deleteProduct(product._id)}
                    className="p-2 bg-white rounded-full text-red-600 hover:bg-red-50 transition"
                    title="Supprimer"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              </div>

              {/* Product Info */}
              <div className="p-4">
                <h3 className="font-bold text-lg mb-1 line-clamp-1">{product.name}</h3>
                <p className="text-sm text-gray-500 mb-3 line-clamp-2">{product.description}</p>

                <div className="flex items-center justify-between mb-3">
                  <div>
                    <span className="text-xl font-bold text-primary-600">
                      {product.price?.toLocaleString()} {CURRENCY}
                    </span>
                    {product.comparePrice > product.price && (
                      <span className="text-sm text-gray-400 line-through ml-2">
                        {product.comparePrice?.toLocaleString()}
                      </span>
                    )}
                  </div>
                  <span className={`text-sm font-medium ${product.stock > 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {product.stock > 0 ? `${product.stock} en stock` : 'Rupture'}
                  </span>
                </div>

                <div className="flex items-center justify-between text-sm text-gray-500 mb-3">
                  <span className="badge bg-gray-100 text-gray-600">
                    {product.categoryName || 'Non catégorisé'}
                  </span>
                  <span className="truncate max-w-[120px]" title={product.merchantName}>
                    {product.merchantName}
                  </span>
                </div>

                {/* Actions */}
                {!product.isApproved && product.status !== 'rejected' && (
                  <div className="flex gap-2 pt-3 border-t">
                    <button
                      onClick={() => approveProduct(product._id)}
                      className="flex-1 btn bg-green-500 text-white hover:bg-green-600 text-sm py-2 flex items-center justify-center"
                    >
                      <Check className="w-4 h-4 mr-1" />
                      Approuver
                    </button>
                    <button
                      onClick={() => rejectProduct(product._id)}
                      className="flex-1 btn bg-red-500 text-white hover:bg-red-600 text-sm py-2 flex items-center justify-center"
                    >
                      <X className="w-4 h-4 mr-1" />
                      Rejeter
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between mt-6">
              <p className="text-sm text-gray-600">
                Affichage de {startIndex + 1} à {Math.min(startIndex + itemsPerPage, filteredProducts.length)} sur {filteredProducts.length}
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

      {/* Modal for Create/Edit/View */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between rounded-t-2xl">
              <h2 className="text-2xl font-bold">
                {modalMode === 'create' && 'Nouveau produit'}
                {modalMode === 'edit' && 'Modifier le produit'}
                {modalMode === 'view' && 'Détails du produit'}
              </h2>
              <button
                onClick={handleCloseModal}
                className="p-2 hover:bg-gray-100 rounded-xl transition"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-5">
              <div className="grid md:grid-cols-2 gap-5">
                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nom du produit *
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

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Description *
                  </label>
                  <textarea
                    value={formData.description}
                    onChange={(e) => setFormData({...formData, description: e.target.value})}
                    className="input"
                    rows={3}
                    required
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Prix ({CURRENCY}) *
                  </label>
                  <input
                    type="number"
                    value={formData.price}
                    onChange={(e) => setFormData({...formData, price: e.target.value})}
                    className="input"
                    min="0"
                    required
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Prix barré ({CURRENCY})
                  </label>
                  <input
                    type="number"
                    value={formData.comparePrice}
                    onChange={(e) => setFormData({...formData, comparePrice: e.target.value})}
                    className="input"
                    min="0"
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Stock *
                  </label>
                  <input
                    type="number"
                    value={formData.stock}
                    onChange={(e) => setFormData({...formData, stock: e.target.value})}
                    className="input"
                    min="0"
                    required
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Catégorie *
                  </label>
                  <select
                    value={formData.category}
                    onChange={(e) => setFormData({...formData, category: e.target.value})}
                    className="input"
                    required
                    disabled={modalMode === 'view'}
                  >
                    <option value="">Sélectionner une catégorie</option>
                    {categories.map(cat => (
                      <option key={cat._id} value={cat._id}>{cat.name}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Marchand *
                  </label>
                  <select
                    value={formData.merchant}
                    onChange={(e) => setFormData({...formData, merchant: e.target.value})}
                    className="input"
                    required
                    disabled={modalMode === 'view'}
                  >
                    <option value="">Sélectionner un marchand</option>
                    {merchants.map(m => (
                      <option key={m._id} value={m._id}>{m.shopName || m.name}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    URL de l'image
                  </label>
                  <input
                    type="url"
                    value={formData.image}
                    onChange={(e) => setFormData({...formData, image: e.target.value})}
                    className="input"
                    placeholder="https://..."
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div className="md:col-span-2">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Tags (séparés par des virgules)
                  </label>
                  <input
                    type="text"
                    value={formData.tags}
                    onChange={(e) => setFormData({...formData, tags: e.target.value})}
                    className="input"
                    placeholder="tag1, tag2, tag3"
                    disabled={modalMode === 'view'}
                  />
                </div>

                <div className="md:col-span-2">
                  <label className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      checked={formData.isActive}
                      onChange={(e) => setFormData({...formData, isActive: e.target.checked})}
                      className="w-5 h-5 text-primary-600 rounded"
                      disabled={modalMode === 'view'}
                    />
                    <span className="text-sm font-medium text-gray-700">Produit actif</span>
                  </label>
                </div>
              </div>

              {/* Preview */}
              {formData.image && (
                <div className="border rounded-xl p-4">
                  <p className="text-sm font-medium text-gray-700 mb-2">Aperçu de l'image:</p>
                  <img
                    src={formData.image}
                    alt="Aperçu"
                    className="h-32 object-cover rounded-lg"
                    onError={(e) => e.target.style.display = 'none'}
                  />
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
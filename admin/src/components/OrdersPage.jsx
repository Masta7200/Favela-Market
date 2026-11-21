import React, { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import api from '../services/api';
import { ENDPOINTS, ORDER_STATUSES, FINAL_ORDER_STATUSES, CURRENCY, VEHICLE_TYPES, getOrderStatus, BADGE_CLASSES } from '../config';
import { useToast } from './Toast';
import { Search, Eye, Package, X, Truck, UserCheck, UserX, AlertTriangle } from 'lucide-react';

const needsDeliveryPerson = (order) =>
  !order.deliveryPerson && !FINAL_ORDER_STATUSES.includes(order.status) && order.status !== 'in_transit';

export default function OrdersPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchParams] = useSearchParams();
  const [filter, setFilter] = useState(searchParams.get('filter') || 'all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [showModal, setShowModal] = useState(false);
  const [deliveryPersons, setDeliveryPersons] = useState([]);
  const [selectedDeliveryPerson, setSelectedDeliveryPerson] = useState('');
  const [saving, setSaving] = useState(false);
  const toast = useToast();

  useEffect(() => {
    fetchOrders();
  }, [filter]);

  // Opening /dashboard/orders?order=<id> (from a notification) shows that order
  useEffect(() => {
    const orderId = searchParams.get('order');
    if (orderId) viewOrderDetails(orderId);
    const f = searchParams.get('filter');
    if (f) setFilter(f);
  }, [searchParams]);

  const fetchOrders = async () => {
    try {
      const params = filter === 'unassigned'
        ? { delivery: 'unassigned' }
        : { status: filter !== 'all' ? filter : undefined };
      const response = await api.get(ENDPOINTS.ORDERS, { params });
      if (response.success) {
        setOrders(response.data.orders);
      }
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchDeliveryPersons = async () => {
    try {
      const response = await api.get(ENDPOINTS.DELIVERY_PERSONS);
      if (response.success) setDeliveryPersons(response.data.deliveryPersons);
    } catch (error) {
      console.error('Error fetching delivery persons:', error);
    }
  };

  const updateOrderStatus = async (orderId, newStatus) => {
    try {
      const response = await api.put(ENDPOINTS.UPDATE_ORDER_STATUS(orderId), { status: newStatus });
      setSelectedOrder(response.data.order);
      fetchOrders();
      toast.success('Statut mis à jour avec succès');
    } catch (error) {
      toast.error(error.message || 'Erreur lors de la mise à jour');
    }
  };

  const viewOrderDetails = async (orderId) => {
    try {
      const response = await api.get(ENDPOINTS.ORDER_BY_ID(orderId));
      if (response.success) {
        setSelectedOrder(response.data.order);
        setSelectedDeliveryPerson('');
        setShowModal(true);
        fetchDeliveryPersons();
      }
    } catch (error) {
      toast.error('Erreur lors du chargement des détails');
    }
  };

  const assignDelivery = async () => {
    if (!selectedDeliveryPerson) return;
    setSaving(true);
    try {
      const response = await api.put(ENDPOINTS.ASSIGN_ORDER(selectedOrder._id), { deliveryPersonId: selectedDeliveryPerson });
      setSelectedOrder(response.data.order);
      setSelectedDeliveryPerson('');
      toast.success(response.message || 'Livreur assigné, il a été notifié');
      fetchOrders();
      fetchDeliveryPersons();
    } catch (error) {
      toast.error(error.message || 'Erreur lors de l\'assignation');
    } finally {
      setSaving(false);
    }
  };

  const unassignDelivery = async () => {
    if (!window.confirm('Retirer le livreur de cette commande ?')) return;
    setSaving(true);
    try {
      const response = await api.delete(ENDPOINTS.ASSIGN_ORDER(selectedOrder._id));
      setSelectedOrder(response.data.order);
      toast.success('Livreur retiré');
      fetchOrders();
      fetchDeliveryPersons();
    } catch (error) {
      toast.error(error.message || 'Erreur');
    } finally {
      setSaving(false);
    }
  };

  const deleteOrder = async (orderId) => {
    if (!window.confirm('Voulez-vous vraiment supprimer cette commande ?')) {
      return;
    }

    try {
      const response = await api.delete(ENDPOINTS.DELETE_ORDER(orderId));
      if (response.success) {
        await fetchOrders();
        toast.success('Commande supprimée avec succès');
      }
    } catch (error) {
      toast.error('Erreur lors de la suppression de la commande');
    }
  };

  const filteredOrders = orders.filter(order => {
    if (!searchQuery.trim()) return true;

    const query = searchQuery.toLowerCase();
    return (
      order.orderNumber.toLowerCase().includes(query) ||
      order.customerName?.toLowerCase().includes(query) ||
      order.customerPhone?.toLowerCase().includes(query) ||
      order.customerEmail?.toLowerCase().includes(query) ||
      order.merchantName?.toLowerCase().includes(query) ||
      order.deliveryPerson?.name?.toLowerCase().includes(query)
    );
  });

  const getStatusInfo = getOrderStatus;
  const getStatusColor = (color) => BADGE_CLASSES[color] || BADGE_CLASSES.gray;

  const addressText = (address) => {
    if (!address) return 'N/A';
    if (typeof address === 'string') return address;
    return address.label || [address.fullAddress, address.quarter, address.city].filter(Boolean).join(', ');
  };

  const orderSubtotal = (order) =>
    order.items?.reduce((sum, item) => sum + (item.subtotal || 0), 0) || 0;

  const unassignedCount = orders.filter(needsDeliveryPerson).length;

  const filterButtons = [
    { value: 'all', label: 'Tous' },
    { value: 'unassigned', label: 'À assigner' },
    ...ORDER_STATUSES.filter(s => ['pending', 'confirmed', 'preparing', 'ready', 'in_transit', 'delivered'].includes(s.value)),
  ];

  const renderDeliveryCell = (order) => {
    if (order.deliveryPerson) {
      return (
        <div>
          <p className="text-sm text-gray-900">{order.deliveryPerson.name}</p>
          <p className={`text-xs ${order.deliveryAcceptedAt ? 'text-green-600' : 'text-yellow-600'}`}>
            {order.deliveryAcceptedAt ? 'Acceptée' : 'En attente d\'acceptation'}
          </p>
        </div>
      );
    }
    if (needsDeliveryPerson(order)) {
      return <span className="badge bg-yellow-100 text-yellow-800">À assigner</span>;
    }
    return <span className="text-sm text-gray-400">—</span>;
  };

  const canChangeDelivery = selectedOrder &&
    !FINAL_ORDER_STATUSES.includes(selectedOrder.status) && selectedOrder.status !== 'in_transit';

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Commandes</h1>
          <p className="text-gray-600 mt-1">Gérez toutes les commandes et assignez les livreurs</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Total</p>
              <p className="text-2xl font-bold">{orders.length}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
              <Package className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </div>
        <button className="card text-left hover:ring-2 hover:ring-yellow-300 transition" onClick={() => setFilter('unassigned')}>
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">À assigner</p>
              <p className="text-2xl font-bold">{unassignedCount}</p>
            </div>
            <div className="w-12 h-12 bg-yellow-100 rounded-full flex items-center justify-center">
              <AlertTriangle className="w-6 h-6 text-yellow-600" />
            </div>
          </div>
        </button>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">En livraison</p>
              <p className="text-2xl font-bold">
                {orders.filter(o => o.status === 'in_transit').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-orange-100 rounded-full flex items-center justify-center">
              <Truck className="w-6 h-6 text-orange-600" />
            </div>
          </div>
        </div>
        <div className="card">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-600">Livrées</p>
              <p className="text-2xl font-bold">
                {orders.filter(o => o.status === 'delivered' || o.status === 'completed').length}
              </p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-full flex items-center justify-center">
              <Package className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </div>
      </div>

      {/* Filters & Search */}
      <div className="card">
        <div className="flex flex-col md:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher par numéro, client, marchand ou livreur..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="input pl-10 pr-10"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400 hover:text-gray-600"
                title="Effacer la recherche"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
          <div className="flex gap-2 flex-wrap">
            {filterButtons.map((status) => (
              <button
                key={status.value}
                onClick={() => setFilter(status.value)}
                className={`px-4 py-2 rounded-lg font-medium transition ${
                  filter === status.value
                    ? 'bg-primary-500 text-white'
                    : status.value === 'unassigned'
                      ? 'bg-yellow-100 text-yellow-800 hover:bg-yellow-200'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {status.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Orders Table */}
      <div className="card overflow-hidden p-0">
        {!loading && filteredOrders.length > 0 && (
          <div className="px-6 py-3 bg-gray-50 border-b border-gray-200">
            <p className="text-sm text-gray-600">
              {filteredOrders.length} commande{filteredOrders.length > 1 ? 's' : ''} trouvée{filteredOrders.length > 1 ? 's' : ''}
              {searchQuery && ` pour "${searchQuery}"`}
            </p>
          </div>
        )}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
          </div>
        ) : filteredOrders.length === 0 ? (
          <div className="text-center py-12">
            <Package className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-500">Aucune commande trouvée</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Commande</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Client</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Marchand</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Livreur</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Total</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Statut</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {filteredOrders.map((order) => {
                  const statusInfo = getStatusInfo(order.status);
                  return (
                    <tr key={order._id} className="hover:bg-gray-50">
                      <td className="px-6 py-4">
                        <p className="font-medium text-gray-900">#{order.orderNumber}</p>
                        <p className="text-xs text-gray-500">{order.items?.length || 0} article(s)</p>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm text-gray-900">{order.customerName || 'N/A'}</p>
                        <p className="text-xs text-gray-500">{order.customerPhone || ''}</p>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-sm text-gray-900">{order.merchantName || 'N/A'}</p>
                      </td>
                      <td className="px-6 py-4">{renderDeliveryCell(order)}</td>
                      <td className="px-6 py-4">
                        <p className="font-medium text-gray-900">
                          {order.total?.toLocaleString()} {CURRENCY}
                        </p>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`badge ${getStatusColor(statusInfo.color)}`}>
                          {statusInfo.label}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500">
                        {new Date(order.createdAt).toLocaleDateString('fr-FR')}
                      </td>
                      <td className="px-6 py-4 text-right space-x-2 whitespace-nowrap">
                        <button
                          onClick={() => viewOrderDetails(order._id)}
                          className="btn bg-primary-100 text-primary-700 hover:bg-primary-200 text-sm"
                        >
                          <Eye className="w-4 h-4 mr-1" />
                          {needsDeliveryPerson(order) ? 'Assigner' : 'Voir'}
                        </button>
                        <button
                          onClick={() => deleteOrder(order._id)}
                          className="btn bg-red-100 text-red-700 hover:bg-red-200 text-sm"
                        >
                          <X className="w-4 h-4 mr-1" />
                          Supprimer
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Order Details Modal */}
      {showModal && selectedOrder && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-2xl font-bold">Commande #{selectedOrder.orderNumber}</h2>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="p-6 space-y-6">
              {/* Status Update */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Statut de la commande
                </label>
                <select
                  value={selectedOrder.status}
                  onChange={(e) => updateOrderStatus(selectedOrder._id, e.target.value)}
                  className="input"
                >
                  {ORDER_STATUSES.map((status) => (
                    <option key={status.value} value={status.value}>
                      {status.label}
                    </option>
                  ))}
                </select>
              </div>

              {/* Delivery person */}
              <div>
                <h3 className="font-bold mb-3 flex items-center gap-2">
                  <Truck className="w-5 h-5" /> Livreur
                </h3>
                <div className="p-4 bg-gray-50 rounded-lg space-y-3">
                  {selectedOrder.deliveryPerson ? (
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <p className="font-medium">{selectedOrder.deliveryPerson.name}</p>
                        <p className="text-sm text-gray-600">{selectedOrder.deliveryPerson.phone}</p>
                        <p className="text-sm text-gray-600">
                          {VEHICLE_TYPES[selectedOrder.deliveryPerson.vehicleType] || ''}
                          {selectedOrder.deliveryPerson.vehicleNumber ? ` · ${selectedOrder.deliveryPerson.vehicleNumber}` : ''}
                        </p>
                        <p className={`text-sm mt-1 ${selectedOrder.deliveryAcceptedAt ? 'text-green-700' : 'text-yellow-700'}`}>
                          {selectedOrder.deliveredAt
                            ? `Livrée le ${new Date(selectedOrder.deliveredAt).toLocaleString('fr-FR')}`
                            : selectedOrder.pickedUpAt
                              ? `Récupérée le ${new Date(selectedOrder.pickedUpAt).toLocaleString('fr-FR')}`
                              : selectedOrder.deliveryAcceptedAt
                                ? 'A accepté la livraison'
                                : 'Notifié, en attente d\'acceptation'}
                        </p>
                      </div>
                      {canChangeDelivery && (
                        <button
                          onClick={unassignDelivery}
                          disabled={saving}
                          className="btn bg-red-100 text-red-700 hover:bg-red-200 text-sm flex items-center gap-1"
                        >
                          <UserX className="w-4 h-4" /> Retirer
                        </button>
                      )}
                    </div>
                  ) : (
                    <p className="text-sm text-yellow-700">Aucun livreur assigné.</p>
                  )}

                  {selectedOrder.deliveryDeclines?.length > 0 && (
                    <div className="text-sm text-gray-600 border-t pt-3">
                      <p className="font-medium mb-1">Refus précédents :</p>
                      {selectedOrder.deliveryDeclines.map((d, i) => (
                        <p key={i}>
                          {d.deliveryPerson?.name || 'Livreur'} — {d.reason} ({new Date(d.at).toLocaleString('fr-FR')})
                        </p>
                      ))}
                    </div>
                  )}

                  {canChangeDelivery && (
                    <div className="flex flex-col sm:flex-row gap-2 border-t pt-3">
                      <select
                        value={selectedDeliveryPerson}
                        onChange={(e) => setSelectedDeliveryPerson(e.target.value)}
                        className="input flex-1"
                      >
                        <option value="">
                          {deliveryPersons.length ? 'Choisir un livreur…' : 'Aucun livreur vérifié'}
                        </option>
                        {deliveryPersons
                          .filter((p) => p._id !== selectedOrder.deliveryPerson?._id)
                          .map((p) => (
                            <option key={p._id} value={p._id}>
                              {p.isAvailable ? '🟢' : '⚪'} {p.name} · {VEHICLE_TYPES[p.vehicleType] || '—'} · {p.activeOrders} en cours
                              {p.isAvailable ? '' : ' (hors ligne)'}
                            </option>
                          ))}
                      </select>
                      <button
                        onClick={assignDelivery}
                        disabled={!selectedDeliveryPerson || saving}
                        className="btn btn-primary flex items-center justify-center gap-2 disabled:opacity-50"
                      >
                        <UserCheck className="w-5 h-5" />
                        {selectedOrder.deliveryPerson ? 'Réassigner' : 'Assigner'}
                      </button>
                    </div>
                  )}
                </div>
              </div>

              {/* Client and Merchant Info */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h3 className="font-bold mb-3">Informations client</h3>
                  <div className="p-4 bg-gray-50 rounded-lg">
                    <p className="font-medium">{selectedOrder.client?.name || 'N/A'}</p>
                    <p className="text-sm text-gray-600">{selectedOrder.deliveryPhone || selectedOrder.client?.phone || ''}</p>
                    <p className="text-sm text-gray-600">{selectedOrder.client?.email || ''}</p>
                  </div>
                </div>
                <div>
                  <h3 className="font-bold mb-3">Récupération (marchand)</h3>
                  <div className="p-4 bg-gray-50 rounded-lg">
                    <p className="font-medium">{selectedOrder.merchant?.shopName || selectedOrder.merchant?.name || 'N/A'}</p>
                    <p className="text-sm text-gray-600">{selectedOrder.merchant?.shopPhone || selectedOrder.merchant?.phone || ''}</p>
                    <p className="text-sm text-gray-600">{selectedOrder.merchant?.shopAddress || ''}</p>
                  </div>
                </div>
              </div>

              {/* Order Items */}
              <div>
                <h3 className="font-bold mb-3">Articles commandés</h3>
                <div className="space-y-2">
                  {selectedOrder.items?.map((item, index) => (
                    <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                      <div>
                        <p className="font-medium">{item.product?.name || item.productName || 'Produit supprimé'}</p>
                        <p className="text-sm text-gray-600">
                          {item.price?.toLocaleString()} {CURRENCY} x {item.quantity}
                        </p>
                      </div>
                      <p className="font-bold">
                        {item.subtotal?.toLocaleString()} {CURRENCY}
                      </p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Delivery Address */}
              <div>
                <h3 className="font-bold mb-3">Adresse de livraison</h3>
                <div className="p-4 bg-gray-50 rounded-lg">
                  <p className="font-medium">{addressText(selectedOrder.deliveryAddress)}</p>
                  {selectedOrder.deliveryAddress?.details && (
                    <p className="text-sm text-gray-600 mt-1">{selectedOrder.deliveryAddress.details}</p>
                  )}
                  {selectedOrder.notes && (
                    <p className="text-sm text-gray-600 mt-1">Note : {selectedOrder.notes}</p>
                  )}
                </div>
              </div>

              {/* Order Summary */}
              <div className="border-t pt-4">
                <div className="space-y-2">
                  <div className="flex justify-between">
                    <span>Sous-total</span>
                    <span>{orderSubtotal(selectedOrder).toLocaleString()} {CURRENCY}</span>
                  </div>
                  <div className="flex justify-between text-sm text-gray-600">
                    <span>Paiement</span>
                    <span>
                      {selectedOrder.paymentMethod === 'cash' ? 'Espèces à la livraison' : selectedOrder.paymentMethod}
                      {' · '}
                      {selectedOrder.paymentStatus === 'paid' ? 'Payé' : 'Non payé'}
                    </span>
                  </div>
                  <div className="flex justify-between text-lg font-bold border-t pt-2">
                    <span>Total</span>
                    <span className="text-primary-600">
                      {selectedOrder.total?.toLocaleString()} {CURRENCY}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

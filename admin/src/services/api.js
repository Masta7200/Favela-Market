import axios from 'axios';
import { API_URL } from '../config';

const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('adminToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

api.interceptors.response.use(
  (response) => response.data,
        (error) => {
          // Don't auto-redirect on 401 here; let the UI decide how to handle auth errors.
          if (error.response?.status === 401) {
            // Clear stored auth locally so UI can react
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminUser');
          }
          return Promise.reject(error.response?.data || error.message);
        }
);

export default api;

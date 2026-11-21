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
          // Expired / invalid session (but not a wrong password on the login form)
          if (error.response?.status === 401 && localStorage.getItem('adminToken')) {
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminUser');
            // AuthContext listens to this and sends the admin back to the login page
            window.dispatchEvent(new Event('auth:expired'));
          }
          return Promise.reject(error.response?.data || error.message);
        }
);

export default api;

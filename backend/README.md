# Favela Market - Backend API

Backend API for Favela Market multi-vendor marketplace application.

## Tech Stack

- Node.js
- Express.js
- MongoDB
- JWT Authentication
- Bcrypt for password hashing

## Features

- ✅ User authentication (phone + password)
- ✅ Role-based access control (Client, Merchant, Delivery, Admin)
- ✅ JWT token authentication
- ✅ Profile management
- ✅ Address management for clients
- ✅ OTP support (ready for future implementation)

## Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Copy the example env file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and update the following:
- `MONGODB_URI`: Your MongoDB connection string
- `JWT_SECRET`: A strong random secret key
- `ADMIN_PHONE`: Default admin phone number
- `ADMIN_PASSWORD`: Default admin password

### 3. Start MongoDB

Make sure MongoDB is running on your machine:

```bash
# If using MongoDB locally
mongod
```

Or use MongoDB Atlas (cloud) and update MONGODB_URI accordingly.

### 4. Seed Admin User

Create the initial admin user:

```bash
npm run seed
```

This will create an admin account with:
- Phone: The one specified in .env (default: +237600000000)
- Password: The one specified in .env (default: admin123)

⚠️ **Change the admin password after first login!**

### 5. Start the Server

Development mode with auto-reload:

```bash
npm run dev
```

Production mode:

```bash
npm start
```

The server will run on `http://localhost:5000`

## API Endpoints

### Authentication

#### Register User
```http
POST /api/auth/register
Content-Type: application/json

{
  "phone": "+237612345678",
  "password": "password123",
  "name": "John Doe",
  "role": "client",
  "email": "john@example.com"
}
```

**Roles:** `client`, `merchant`, `delivery` (admin cannot register via API)

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "phone": "+237612345678",
  "password": "password123"
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer <token>
```

#### Update Profile
```http
PUT /api/auth/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Updated",
  "email": "johnupdated@example.com",
  "shopName": "My Shop" // for merchants
}
```

#### Update Password
```http
PUT /api/auth/password
Authorization: Bearer <token>
Content-Type: application/json

{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword"
}
```

#### Add Address (Clients only)
```http
POST /api/auth/addresses
Authorization: Bearer <token>
Content-Type: application/json

{
  "label": "Maison",
  "fullAddress": "123 Rue Example",
  "city": "Douala",
  "quarter": "Akwa",
  "details": "Près du marché",
  "isDefault": true
}
```

#### Update FCM Token (for push notifications)
```http
POST /api/auth/fcm-token
Authorization: Bearer <token>
Content-Type: application/json

{
  "fcmToken": "your-fcm-token-here"
}
```

#### Register a merchant / delivery person
Same endpoint. Extra fields:
- merchant: `shopName` (required), `shopDescription`, `shopAddress`, `shopPhone`
- delivery: `vehicleType` (`moto` | `velo` | `voiture`, required), `vehicleNumber` (required except for `velo`)

Both start with `isApproved: false`; every admin gets an `account_pending` notification.

#### Delivery availability (delivery, approved)
```http
PUT /api/auth/availability
{ "isAvailable": true }
```

### Account verification flow

```
Merchant / delivery registers ──► admins notified ("account_pending")
        │
Admin: PUT /api/admin/users/:id/approve      (or the "approuvé" checkbox, PUT /api/admin/users/:id)
       PUT /api/admin/users/:id/reject { reason }
        │
User notified ("account_approved" / "account_rejected" + reason)
```

Until approved, merchants and delivery persons cannot add products or work on orders (403).

### Orders & delivery

| Method | Path | Who | Notes |
|---|---|---|---|
| POST | `/api/orders` | client | One order **per shop** is created (`data.orders`; `data.order` = first). Merchant notified (`order_new`), admins asked to assign a delivery person. |
| GET | `/api/orders` | all | Client: own orders · merchant: own shop · delivery: assigned to them |
| GET | `/api/orders/:id` | client, merchant, assigned delivery person, admin | |
| PUT | `/api/orders/:id/status` | merchant | `confirmed` → `preparing` → `ready` (or `rejected`). `in_transit` / `delivered` only when no delivery person is assigned. |
| POST | `/api/orders/:id/cancel` | client | Not once `in_transit`. Stock is restored. |
| GET | `/api/orders/delivery/orders` | delivery | Orders assigned to me |
| PUT | `/api/orders/:id/delivery/accept` | delivery | Merchant & client notified |
| PUT | `/api/orders/:id/delivery/decline` | delivery | `{ reason }` — unassigns, admins notified |
| PUT | `/api/orders/:id/delivery/status` | delivery | `{ status: "in_transit" }` after accepting and once confirmed by the merchant, then `{ status: "delivered" }` (cash orders become `paid`) |

When a delivery person sells their own product, the order is automatically assigned to them (accepted, `confirmed`).

### Admin

| Method | Path | Notes |
|---|---|---|
| GET | `/api/admin/users?approval=pending` | Merchants + delivery persons waiting for verification |
| PUT | `/api/admin/users/:id/approve` · `/reject` | |
| GET | `/api/admin/delivery-persons?available=true` | Approved + active, with `activeOrders` count |
| GET | `/api/admin/orders?delivery=unassigned` | Open orders without a delivery person |
| PUT | `/api/admin/orders/:id/assign` | `{ deliveryPersonId }` — delivery person notified (`order_assigned`) |
| DELETE | `/api/admin/orders/:id/assign` | Remove the delivery person |
| GET | `/api/admin/stats` | Adds `pendingDelivery`, `availableDelivery`, `unassignedOrders` |

### Notifications (all roles)

Stored in MongoDB (kept 60 days). The apps check every 30 s and show new ones as a banner at the top.

| Method | Path |
|---|---|
| GET | `/api/notifications?unread=true&limit=50` → `{ notifications, unreadCount }` |
| PUT | `/api/notifications/:id/read` |
| PUT | `/api/notifications/read-all` |
| DELETE | `/api/notifications/:id` |

Types: `order_new`, `order_assigned`, `order_updated`, `order_cancelled`, `delivery_declined`, `account_pending`, `account_approved`, `account_rejected`, `product_approved`, `product_rejected`.

### Public figures (landing page, no login)

```http
GET /api/public/stats
→ { clients, merchants, deliveryPersons, products, categories, deliveredOrders }
```

Counts only (no revenue, no personal data), cached 5 minutes.
`GET /api/admin/stats` also returns `monthlyRevenue` (last 6 months), `recentOrders` and `usersByRole` for the dashboard.

### Security

- Login and password reset are limited to 8 failed attempts per account every 15 minutes (`429` after that); reset-code emails to 5 per hour.
- A reset code is cancelled after 5 wrong tries, and is never returned by the API (only `NODE_ENV=development` shows it, for local testing).
- Error responses include a stack trace only with `NODE_ENV=development`.
- Search terms are matched literally (special characters are escaped); `limit` is capped at 100.

### Health Check
```http
GET /health
```

## Response Format

All API responses follow this format:

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description in French"
}
```

## User Roles

1. **Client**: Regular customers who browse and buy products
2. **Merchant**: Shop owners who sell products
3. **Delivery**: Delivery personnel who handle deliveries
4. **Admin**: Platform administrators

## Next Steps

- [x] Product management
- [x] Category management
- [x] Order management
- [x] Delivery assignment
- [x] In-app notifications
- [x] Image upload (Cloudinary, from the apps)
- [ ] Push notifications when the apps are closed (Firebase Cloud Messaging — `fcmToken` is already stored)
- [ ] Analytics

## Security Notes

- All passwords are hashed using bcrypt
- JWT tokens expire after 7 days (configurable)
- Protected routes require valid JWT token
- Role-based authorization on sensitive endpoints
- Merchants require approval before performing certain actions

## Project Structure

```
backend/
├── src/
│   ├── config/          # Database and other configs
│   ├── constants/       # Application constants
│   ├── controllers/     # Route controllers
│   ├── middlewares/     # Express middlewares
│   ├── models/          # Mongoose models
│   ├── routes/          # API routes
│   ├── utils/           # Utility functions
│   └── app.js           # Express app setup
├── .env                 # Environment variables
├── .env.example         # Example environment file
└── package.json         # Dependencies
```

## Support

For issues or questions, please contact the development team.
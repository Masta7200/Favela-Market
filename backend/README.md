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

The following features will be added:
- [ ] Product management
- [ ] Category management
- [ ] Order management
- [ ] Delivery assignment
- [ ] Analytics
- [ ] Notifications
- [ ] Image upload

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
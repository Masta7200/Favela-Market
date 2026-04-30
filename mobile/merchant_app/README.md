# Tumai Market - Merchant App

Beautiful Flutter app for shop owners to manage their business on Tumai Market.

## 🏪 Features

### Authentication
- **Register as Merchant** - Create shop account
- **Login** - Secure access to your shop
- **Profile Management** - Update shop details

### Shop Management
- **Shop Profile** - Name, description, logo, banner
- **Business Hours** - Set opening/closing times
- **Contact Info** - Phone, email, address

### Product Management
- **Add Products** - Name, description, price, images, category
- **Edit Products** - Update product details
- **Delete Products** - Remove products
- **Stock Management** - Track inventory
- **Product Status** - Pending, Approved, Rejected by admin

### Order Management
- **New Orders** - Real-time notifications
- **Order Details** - View customer info, items, delivery address
- **Update Status** - Preparing, Ready for pickup, etc.
- **Order History** - Track all orders

### Analytics & Reports
- **Sales Dashboard** - Revenue, orders, products
- **Charts** - Daily, weekly, monthly sales
- **Top Products** - Best sellers
- **Revenue Tracking** - Earnings overview

### Notifications
- **New Orders** - Instant alerts
- **Product Approval** - Admin approvals
- **Order Updates** - Status changes

## 🎨 Design

- Material Design 3
- Custom green & orange theme (matching platform)
- Beautiful gradients
- Smooth animations
- Responsive layouts

## 📦 Tech Stack

- Flutter 3.16+
- Dart 3.0+
- Provider (State Management)
- HTTP (API calls)
- Cached Network Image
- Charts (fl_chart)
- Image Picker
- Push Notifications (Firebase)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.16 or higher
- Dart 3.0 or higher
- Android Studio / VS Code
- Physical device or emulator

### Installation

```bash
cd mobile/merchant_app
flutter pub get
flutter run
```

## 📱 Screens

### Authentication
1. **Splash Screen** - Animated logo
2. **Welcome Screen** - Intro to merchant app
3. **Register Screen** - Create merchant account
4. **Login Screen** - Sign in

### Main App
1. **Dashboard** - Sales overview, stats, charts
2. **Products** - Product list and management
3. **Add/Edit Product** - Product form
4. **Orders** - Order list with filters
5. **Order Detail** - Full order information
6. **Shop Profile** - Shop settings
7. **Profile** - Merchant profile settings

## 🔧 Configuration

### API Setup

Edit `lib/config/app_config.dart`:

```dart
static const String baseUrl = 'http://YOUR_IP:5000/api';
```

### Firebase (Optional - for push notifications)

1. Add `google-services.json` (Android)
2. Add `GoogleService-Info.plist` (iOS)
3. Enable Cloud Messaging

## 🏗️ Project Structure

```
lib/
├── config/
│   ├── app_config.dart       # API endpoints
│   ├── routes.dart           # Navigation
│   └── theme.dart            # App theme
├── models/
│   ├── merchant_model.dart   # Merchant data
│   ├── product_model.dart    # Product data
│   ├── order_model.dart      # Order data
│   └── shop_model.dart       # Shop data
├── providers/
│   ├── auth_provider.dart    # Authentication
│   ├── product_provider.dart # Products
│   ├── order_provider.dart   # Orders
│   └── shop_provider.dart    # Shop management
├── screens/
│   ├── auth/                 # Auth screens
│   ├── dashboard/            # Dashboard
│   ├── products/             # Product management
│   ├── orders/               # Order management
│   └── profile/              # Profile & settings
├── services/
│   ├── api_service.dart      # HTTP client
│   └── storage_service.dart  # Local storage
├── widgets/                  # Reusable widgets
└── main.dart                 # Entry point
```

## 🎯 User Flow

1. **New Merchant**:
   - Downloads app
   - Registers with shop details
   - Waits for admin approval
   - Receives approval notification
   - Logs in and starts selling

2. **Daily Operations**:
   - Checks dashboard for sales
   - Receives new order notification
   - Views order details
   - Updates order status
   - Manages products (add/edit)
   - Tracks revenue

## 🔐 Merchant Account States

- **Pending** - Waiting for admin approval
- **Approved** - Can sell products
- **Suspended** - Temporarily disabled
- **Rejected** - Application denied

## 📝 Notes

- Merchants need admin approval to start selling
- Products need admin approval before going live
- All transactions are Cash on Delivery (COD)
- Delivery is handled by platform delivery personnel

## 🤝 Support

For merchant support:
- Email: merchant@tumaimarket.cm
- Phone: +23599507200 
- WhatsApp: +23599507200 

---

Built with ❤️ for Tumai Market Shop Owners
EOF

echo "✅ Created README.md"
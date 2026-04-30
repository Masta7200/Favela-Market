# Tumai Market - Client App (Flutter)

Application mobile client pour Tumai Market - Marketplace multi-vendeurs

## 📱 Features (MVP)

✅ **Authentication**
- Login with phone + password
- Register new account
- Beautiful splash screen with animations
- Secure token storage

🏠 **Home & Shopping** (Coming next)
- Browse products
- Search functionality
- Categories browsing
- Product details

🛒 **Cart & Checkout**
- Add/remove items
- Cash on delivery (COD)
- Address management

📦 **Orders**
- View order history
- Track order status

👤 **Profile**
- Edit profile
- Manage addresses
- Change password

## 🚀 Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android Emulator or iOS Simulator

### 2. Install Dependencies

```bash
cd mobile/client_app
flutter pub get
```

### 3. Configure API Base URL

Edit `lib/config/app_config.dart`:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:5000';

// For iOS Simulator
// static const String baseUrl = 'http://localhost:5000';

// For Real Device (use your computer's IP)
// static const String baseUrl = 'http://192.168.1.X:5000';
```

### 4. Run the App

```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or just run (Flutter will prompt you to choose)
flutter run
```

## 📂 Project Structure

```
lib/
├── config/
│   ├── app_config.dart        # API URLs, constants
│   ├── routes.dart            # Navigation routes
│   └── theme.dart             # App theme & colors
│
├── models/
│   └── user_model.dart        # User data model
│
├── providers/
│   ├── auth_provider.dart     # Authentication state
│   ├── cart_provider.dart     # Shopping cart state
│   └── product_provider.dart  # Products state
│
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   ├── products/
│   ├── cart/
│   ├── checkout/
│   ├── orders/
│   └── profile/
│
├── services/
│   ├── api_service.dart       # HTTP requests handler
│   └── storage_service.dart   # Local storage
│
├── widgets/
│   └── custom_button.dart     # Reusable button widget
│
└── main.dart                  # App entry point
```

## 🎨 Design Features

### Beautiful UI
- Google Fonts (Poppins + Inter)
- Modern gradient buttons
- Smooth animations
- Card-based layouts
- Consistent spacing

### Colors
- **Primary**: Green (#2E7D32) - Fresh market feel
- **Secondary**: Orange (#FF6F00) - Energy
- **Accent**: Amber (#FFC107)
- **Background**: Light gray (#F5F5F5)

### User-Friendly Features
- Clear error messages in French
- Loading indicators
- Form validation
- Password visibility toggle
- International phone input

## 🔐 Authentication Flow

1. **Splash Screen** (2 seconds)
   - Animated logo
   - Checks authentication status
   - Routes to login or home

2. **Login Screen**
   - Phone number input (Cameroon +237)
   - Password input with toggle
   - Form validation
   - Error handling

3. **Register Screen**
   - Full name
   - Phone number
   - Email (optional)
   - Password + confirmation
   - Auto-login after registration

## 📦 Dependencies

### Core
- `provider` - State management
- `go_router` - Navigation
- `http` - API requests

### UI/UX
- `google_fonts` - Beautiful typography
- `flutter_spinkit` - Loading animations
- `shimmer` - Skeleton loading
- `intl_phone_field` - Phone input

### Storage
- `shared_preferences` - Simple data
- `flutter_secure_storage` - Tokens

## 🔧 Development Tips

### Hot Reload
```bash
# Press 'r' for hot reload
# Press 'R' for hot restart
```

### Build APK
```bash
flutter build apk --release
```

### Debug Mode
```bash
flutter run --debug
```

### Check for Issues
```bash
flutter doctor
flutter analyze
```

## 🌐 API Integration

### Base URL Configuration
The app communicates with the backend API. Make sure:
1. Backend is running on port 5000
2. Correct IP address is set in `app_config.dart`
3. Network permissions are enabled

### Test Accounts
Use the backend's admin seeder or create new accounts:
- Phone: +237600000000
- Password: admin123

## 📱 Testing

### Android Emulator
1. Create AVD in Android Studio
2. Start emulator
3. Run `flutter run`

### iOS Simulator (Mac only)
1. Open Xcode
2. Start simulator
3. Run `flutter run`

### Real Device
1. Enable USB debugging (Android)
2. Connect device
3. Run `flutter devices`
4. Run `flutter run -d <device-id>`

## 🐛 Troubleshooting

### "No devices found"
```bash
flutter doctor
```

### Gradle build failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Package conflicts
```bash
flutter pub cache repair
flutter pub get
```

### Cannot connect to API
- Check backend is running
- Verify IP address in app_config.dart
- Disable firewall if testing locally
- Use `10.0.2.2` for Android emulator
- Use `localhost` for iOS simulator

## 🎯 Next Steps

### Immediate Tasks
1. ✅ Authentication screens - **DONE**
2. 🔄 Home screen with product grid
3. 🔄 Product listing & detail screens
4. 🔄 Shopping cart functionality
5. 🔄 Checkout & address management
6. 🔄 Orders history & tracking
7. 🔄 Profile & settings

### Future Features
- Push notifications (Firebase)
- Image caching
- Offline support
- Payment gateway integration
- Social login
- Product reviews
- Wishlist

## 📝 Notes

- All text is in **French** 🇫🇷
- MVP focuses on core shopping features
- COD (Cash on Delivery) is the only payment method
- No real-time GPS, manual address entry only

## 🤝 Contributing

This is a private project. For questions or issues, contact the development team.

## 📄 License

Private and proprietary.

---

**Tumai Market** - Votre marketplace de confiance
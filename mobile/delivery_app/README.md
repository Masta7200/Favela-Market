# Tumaï Market - Delivery App (Livreur)

Flutter app for delivery persons. Built on the same structure as `merchant_app`
(Provider + go_router + `ApiService`/`StorageService`, same theme and widgets).

## Features

- **Registration with verification**: name, phone, email, vehicle (moto / vélo / voiture)
  and plate number (optional for vélo). New accounts cannot access deliveries until an
  admin approves them — same process as merchants (admin panel → Utilisateurs → À vérifier).
- **Pending verification screen**: unapproved, refused or suspended accounts are locked to
  this screen (router guard). It switches to the dashboard by itself as soon as the admin
  approves the account, and shows the reason if it was refused.
- **Availability switch**: online / offline, so the admin knows who can take orders.
- **Delivery notifications**: the app checks `/notifications` every 30 s. While the app is
  open, each new one appears as a banner at the top of the screen (tap to open the order);
  in the background it becomes a system notification.
- **Deliveries**: tabs *Nouvelles* (accept / decline), *En cours*, *Terminées*.
- **Order detail**: pickup point (merchant), customer, call / SMS / Google Maps buttons,
  items, cash to collect, and the step actions *J'ai récupéré la commande* → *Confirmer la livraison*.
- **Products**: delivery persons can add / edit / delete items exactly like merchants
  (same screens, products go through admin approval). When a client orders one of these
  items, the order is assigned to the seller automatically and appears in *En cours*.
- **Profile**: personal + vehicle info, change password, logout.

## Run

```bash
cd mobile/delivery_app
flutter pub get
flutter run
# Local backend instead of the hosted one:
flutter run --dart-define=PRODUCTION_API_URL=http://10.0.2.2:5000
```

## Delivery flow

```
Admin assigns order ──► notification "order_assigned"
        │
        ▼
 Nouvelle affectation ──Refuser──► order unassigned, admin reassigns
        │ Accepter
        ▼
 Acceptée (status confirmed/preparing/ready)
        │ "J'ai récupéré la commande"   → status in_transit
        ▼
 En livraison
        │ "Confirmer la livraison"      → status delivered
        ▼
 Livrée
```

## Backend API

All endpoints used by this app are implemented in `backend/` (orders, delivery
accept / decline / status, availability, notifications, products). See the
"Orders & delivery", "Admin" and "Notifications" sections of `backend/README.md`.

The admin assigns orders from the panel: **Commandes → À assigner → Assigner**
(the list shows who is online and how many deliveries each person already has).

## Notifications: current limitation

Notifications are checked while the app is running (foreground, or recently
backgrounded). For alerts when the app is fully closed we need Firebase Cloud
Messaging: a Firebase project (`google-services.json` / `GoogleService-Info.plist`),
the `firebase_messaging` package, and the backend sending pushes to `user.fcmToken`
(the field and `POST /api/auth/fcm-token` already exist).

## Structure

```
lib/
├── main.dart
├── config/        app_config.dart, routes.dart, theme.dart
├── models/        delivery_user_model, order_model, notification_model, product_model, category_model, user_model (address)
├── providers/     auth_provider, order_provider, notification_provider, product_provider
├── services/      api_service, storage_service, notification_service, cloudinary_service
├── utils/         launcher.dart (call / SMS / maps)
├── widgets/       custom_button, order_card
└── screens/
    ├── auth/           splash, login, register, forgot/reset password, pending_approval
    ├── dashboard/      dashboard_screen (home + bottom navigation)
    ├── deliveries/     deliveries_screen, order_detail_screen
    ├── notifications/  notifications_screen
    ├── products/       products_screen, add_product_screen
    └── profile/        profile_screen
```

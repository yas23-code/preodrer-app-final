# Preorder App - Complete Project Description

This document provides a comprehensive overview of the `preorder_app` project, including its technology stack, architecture, database schema, environment variables, credentials, and feature set. It is designed to be provided to an AI model (like Claude) to generate or reconstruct the app in a single prompt.

## 1. Project Overview
**Name:** preorder_app
**Type:** Flutter Mobile Application
**SDK Version:** Dart SDK `^3.7.2`
**Purpose:** A mobile app for users to preorder food items from a canteen (specifically targeting "Acktron Canteen"), with a vendor dashboard for managing orders and menu items.

## 2. Technology Stack & Dependencies
*   **Framework:** Flutter
*   **State Management:** Riverpod (`flutter_riverpod`, `riverpod_annotation`)
*   **Routing:** GoRouter (`go_router`)
*   **Backend & Authentication:** Supabase (`supabase_flutter`)
*   **OAuth:** Google Sign-In (`google_sign_in`)
*   **Push Notifications:** Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`) & Local Notifications (`flutter_local_notifications`)
*   **Data Serialization / Models:** Freezed & JSON Serializable (`freezed_annotation`, `json_annotation`, `freezed`, `json_serializable`, `build_runner`)
*   **UI Components:** `cupertino_icons`, `fl_chart`, `cached_network_image`
*   **Payment Gateway Integration:** WebView based Cashfree implementation (`webview_flutter`) & Supabase Edge Functions.
*   **QR Code / Scanning:** `qr_flutter`, `mobile_scanner`
*   **Mapping:** `flutter_map`, `latlong2`
*   **Environment Management:** `flutter_dotenv`

## 3. Environment Variables & Credentials
The application relies on a `.env` file located at the root directory.

**`.env` Configuration:**
```env
SUPABASE_URL=https://erlsfpqmtzbcpcjhroop.supabase.co
SUPABASE_ANON_KEY=sb_publishable_aYYrWybtiEWvIXD-XyJrWQ_lv065Uu6
GOOGLE_WEB_CLIENT_ID=916332647336-en5tt6r33v14flnkhqg3i23nh2fd49km.apps.googleusercontent.com
```

**Supabase Storage Bucket:** `item-images`

**Important Hardcoded Constants (from `lib/core/constants.dart`):**
*   **Acktron Canteen ID:** `b4b45a67-1f47-4b40-91bd-16b0e36feab9`
*   **Acktron Vendor ID:** `252a9dc4-dfe7-4397-b4d1-f2ca65dced8d`
*   **Cashfree Edge Functions:**
    *   `create-cashfree-order`
    *   `verify-cashfree-payment`

## 4. Architecture & Directory Structure
The project follows a feature-first architecture using Riverpod for state management.

```text
lib/
├── core/                   # App-wide configurations (constants, router, theme, supabase_client, storage)
├── features/               # Feature-based modules
│   ├── auth/               # Login, Role gating, Landing screens
│   ├── canteen/            # Canteen models, providers, and screens
│   ├── cart/               # Persistent cart management (Supabase backed)
│   ├── menu/               # Menu listing, item details, category providers
│   ├── orders/             # Order history, order tracking, order details
│   ├── payment/            # Payment webview integration
│   ├── profile/            # User profile management
│   └── vendor/             # Vendor dashboard, manage menu, add/edit menu items
├── shared/                 # Reusable widgets (cards, navbars, badges) and formatters
└── main.dart               # App entry point, Firebase/Supabase init, Local Notifications setup
```

## 5. Database Schema (Supabase Tables)
The app interacts with the following Supabase tables:

1.  **`profiles`**: Stores user information.
2.  **`user_roles`**: Maps users to specific roles (e.g., 'customer', 'vendor').
3.  **`canteens`**: Information about different canteens (e.g., name, location, `is_open` status).
4.  **`categories`**: Food categories for menu items.
5.  **`menu_items`**: Food items available for order (linked to categories and canteens, includes prep_time).
6.  **`cart_items`**: A persistent cart backed by Supabase.
    *   Fields: `id`, `user_id`, `item_id`, `quantity`, `created_at`, `updated_at`.
    *   Constraints: Unique `(user_id, item_id)`.
    *   RLS Policies: Users can only select/insert/update/delete their own cart rows.
7.  **`orders`**: Header table for placed orders. Includes order status, total amount, payment status, push notification tokens.
8.  **`order_items`**: Line items for each order.

## 6. Key Features & Workflows
*   **Authentication:** Users authenticate via Google Sign-In using Supabase Auth. Role-based routing directs users to either the Customer App or Vendor Dashboard based on the `user_roles` table.
*   **Push Notifications:** Integrated with Firebase Cloud Messaging (FCM). The app requests permissions natively on startup. `firebaseMessagingBackgroundHandler` handles background alerts, and `flutter_local_notifications` displays foreground notifications. Uses an Edge RPC function `register_device_token_rpc` to register tokens.
*   **Cart Management:** The cart is synchronized with the Supabase `cart_items` table in real-time or via API calls, allowing for cross-device persistence.
*   **Payment Flow:** Initiates via Supabase Edge Function (`create-cashfree-order`), opens a Cashfree checkout page in an in-app WebView (`payment_webview_screen.dart`), and verifies success using `verify-cashfree-payment`.
*   **Vendor Dashboard:** Vendors can manage menu items (CRUD operations with image uploads to `item-images` bucket), view real-time orders, and toggle canteen availability (`is_open`).
*   **Customer Flow:** Customers can browse menu items, add them to cart, proceed to checkout via Cashfree, track order status in real-time, and view their profile.

## 7. App Initialization Sequence (`main.dart`)
1.  Ensures widgets are initialized.
2.  Initializes `intl` date formatting.
3.  Loads `.env` file via `flutter_dotenv`.
4.  Initializes `flutter_local_notifications` (Android/iOS specific channels).
5.  Initializes Firebase and requests messaging permissions.
6.  Initializes Supabase using `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
7.  Runs the app using `ProviderScope` for Riverpod state management.
8.  Sets up deep linking / route handling from Firebase Messaging notifications.

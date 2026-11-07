const kSupabaseUrlEnvKey = 'SUPABASE_URL';
const kSupabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';
const kGoogleWebClientIdEnvKey = 'GOOGLE_WEB_CLIENT_ID';

// Supabase Storage
const kFoodImagesBucketName = 'item-images'; // TODO: replace with actual bucket name

// Supabase table names
const kOrdersTableName = 'orders';
const kOrderItemsTableName = 'order_items';
const kProfilesTableName = 'profiles';
const kMenuItemsTableName = 'menu_items';
const kCanteensTableName = 'canteens';
const kCategoriesTableName = 'categories';
const kUserRolesTableName = 'user_roles';
const kCartItemsTableName = 'cart_items';
const kCanteensTable = kCanteensTableName;

// ── Acktron Canteen (confirmed in DB) ─────────────────────────────
/// The single active canteen in the Acktron deployment.
const kAcktronCanteenId = 'b4b45a67-1f47-4b40-91bd-16b0e36feab9';
const kAcktronVendorId  = '252a9dc4-dfe7-4397-b4d1-f2ca65dced8d';

// Edge Function names
const kCreateRazorpayOrderFunction = 'create-razorpay-order';
const kVerifyRazorpayPaymentFunction = 'verify-razorpay-payment';

// Razorpay
const kRazorpayKeyIdEnvKey = 'RAZORPAY_KEY_ID';


const kSupabaseUrlEnvKey = 'SUPABASE_URL';
const kSupabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

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
const kCanteensTable = kCanteensTableName;

// Edge Function names
const kCreateCashfreeOrderFunction = 'create-cashfree-order';
const kVerifyCashfreePaymentFunction = 'verify-cashfree-payment';


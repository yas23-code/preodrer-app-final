import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

final profileProvider = Provider<AsyncValue<Map<String, dynamic>?>>(
  (ref) => ref.watch(currentUserProfileProvider),
);




import 'package:riverpod/riverpod.dart';
import '../services/storage_services.dart';


final userInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await StorageServices.read("userInfo");
});
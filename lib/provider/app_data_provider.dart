import 'package:riverpod/riverpod.dart';
import '../services/storage_services.dart';

final appStateNotifierProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

final userInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(appStateNotifierProvider).userInfo;
});

final settingsProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(appStateNotifierProvider).settings;
});

final userNameProvider = Provider<String>((ref) {
  final userInfo = ref.watch(userInfoProvider);
  return userInfo?['name'] ?? 'Guest';
});

// app_state.dart
class AppState {
  final Map<String, dynamic>? userInfo;
  final Map<String, dynamic>? profileInfo;
  final Map<String, dynamic>? settings;
  final bool isLoading;

  const AppState({
    this.userInfo,
    this.profileInfo,
    this.settings,
    this.isLoading = false,
  });

  AppState copyWith({
    Map<String, dynamic>? userInfo,
    Map<String, dynamic>? profileInfo,
    Map<String, dynamic>? settings,
    bool? isLoading,
  }) {
    return AppState(
      userInfo: userInfo ?? this.userInfo,
      profileInfo: profileInfo ?? this.profileInfo,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// app_state_notifier.dart
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  Future<void> initializeAppData() async {
    state = state.copyWith(isLoading: true);

    try {
      final userdata = await StorageServices.read("userInfo");
      // final profileInfo = await StorageServices.read("profileInfo");
      // final settings = await StorageServices.read("settings");

      state = state.copyWith(
        userInfo: userdata,
        // profileInfo: profileInfo,
        // settings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateUserInfo(Map<String, dynamic> newInfo) async {
    await StorageServices.write("userInfo", newInfo);
    state = state.copyWith(userInfo: newInfo);
  }

  Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    await StorageServices.write("settings", newSettings);
    state = state.copyWith(settings: newSettings);
  }
}

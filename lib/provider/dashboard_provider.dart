import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final dashboardProvider = StateNotifierProvider<DashBoardNotifier, DashBoardState>((ref) => DashBoardNotifier());

class DashBoardState {

  final bool isLoading;
  List<dynamic>?  dashboardList;
  List<dynamic>?  userList;
      DashBoardState({
    this.isLoading = false,
    this.dashboardList = const [],
    this.userList = const []
  });

  DashBoardState copyWith({
    bool? isLoading,
    List<dynamic>?  dashboardList,
    List<dynamic>?  userList,
  }) {
    return DashBoardState(
      isLoading: isLoading ?? this.isLoading,
      dashboardList: dashboardList ?? this.dashboardList,
        userList: userList ?? this.userList
    );
  }
}

class DashBoardNotifier extends StateNotifier<DashBoardState> {
  DashBoardNotifier() : super(DashBoardState());


  Future<void> refreshDashboard({
    String? userId,
    String? frDate,
    String? enDate,
    String? type,
    String? accId,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isLoading: true);

      // Request body with defaults
      final body = {
        "UserId": userId ?? 'All',
        "AccountId": accId ?? '0b71fa30-173f-4552-90c3-e62fcf7e3b00',
        "FromDate": frDate ?? '2025-08-31T18:30:00.000Z',
        "EndDate": enDate ?? '2025-09-30T06:46:26.456Z',
        "Type": type ?? 'All',
      };

      // API call
      final response = await ApiService().post('/dashboard/user/view', body);

      if (response.data == null ||
          response.data['encryptedData'] == null ||
          response.data['iv'] == null) {
        throw Exception("Invalid response format");
      }

      // Decrypt response
      final res = ApiService().decryptData(
        response.data['encryptedData'],
        response.data['iv'],
      );

      // Update state safely
      state = state.copyWith(
        dashboardList: res['patientSummary'] ?? [],
        isLoading: false,
      );
    } catch (e, stackTrace) {
      state = state.copyWith(isLoading: false);
    }
  }


  Future<void>  userList() async{
    final response = await ApiService().get('/user/list',{});
    final result=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
    print("result${result}");
      state=state.copyWith(userList: result['UserList']);
  }


}


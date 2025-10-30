import 'package:ebv/provider/patient_provider.dart';
import 'package:ebv/services/storage_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../services/api_service.dart';

final timeProvider = StreamProvider.autoDispose<String>((ref) async* {
  while (true) {
    yield DateFormat('HH:mm:ss').format(DateTime.now());
    await Future.delayed(const Duration(seconds: 1));
  }
});


class HomeState {
  final List<dynamic>? menus;
  UserModel? userInfo;
  bool isLoading;
  bool signInStatus;
  String signInOutStatus;
  final List<dynamic>? appointmentList;
  final List<dynamic>? todaysappointmentList;

  HomeState(
      {this.menus,
      this.userInfo,
      this.isLoading = false,
      this.signInStatus = false,
      this.signInOutStatus = "",
      this.appointmentList= const [],
      this.todaysappointmentList= const [],

      });

  HomeState copyWith(
      {List<dynamic>? menus,
      UserModel? userInfo,
      bool isLoading = false,
      bool? signInStatus,
        final List<dynamic>? appointmentList,
        final List<dynamic>? todaysappointmentList,
      String? signInOutStatus}) {
    return HomeState(
      menus: menus ?? this.menus,
      userInfo: userInfo ?? this.userInfo,
      appointmentList: appointmentList ?? this.appointmentList,
      todaysappointmentList: todaysappointmentList ?? this.todaysappointmentList,
      isLoading: isLoading,
      signInStatus: signInStatus ?? this.signInStatus,
      signInOutStatus: signInOutStatus ?? this.signInOutStatus,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(HomeState(menus: []));

  getMenuList(var role) {
    List<dynamic> menuList = [];
    switch (role) {
      case "Admin":
        menuList = [
          {
            "icon": 59573,
            "menu": "Patient",
            "routeName": "Patient",
            "color": 0xFFEFF1F5,
            "iconClr": 0xFF5D6B98
          },
          {
            "icon": 58880,
            "menu": "Appointment",
            "routeName": "Appointment",
            "color":0xFFE0EAFF,
            "iconClr": 0xFF6172F3
          },
          {
            "icon": 58880,
            "menu": "Ebv",
            "routeName": "EBV",
            "color":0xFFCCFBEF,
            "iconClr": 0xFF15B79E
          },

          {
            "icon": 58880,
            "menu": "Authenticator",
            "routeName": "Authenticator",
            "color": 0xFFD1E9FF,
            "iconClr": 0xFF2E90FA
          },
          {
            "icon":58880,
            "menu": "VOIP",
            "routeName": "VOIP",
            "color": 0xFFD3F8DF,
            "iconClr": 0xFF16B364
          },
          {
            "icon": 58880,
            "menu": "CallHistory",
            "routeName": "CallHistory",
            "color": 0xFFDDD6FE,
            "iconClr": 0xFF875BF7
          },
          {
            "icon": 58880,
            "menu": "Reports",
            "routeName": "Reports",
            "color": 0xFFE0EAFF,
            "iconClr": 0xFF6172F3
          },
          {
            "icon": 58880,
            "menu": "Dashboard",
            "routeName": "Dashboard",
            "color":0xFFEAECF5,
            "iconClr": 0xFF4E5BA6
          },
        ];
        break;

      case "patient":
        menuList = [
          {
            "icon": "assets/home.png",
            "menu": "MyProfile",
            "routeName": "MyProfile",
            "color": 0xFFEFF1F5,
            "iconClr": 0xFF5D6B98
          },
          {
            "icon": "assets/home.png",
            "menu": "Leave",
            "routeName": "Leave",
            "color": 0xFFCCFBEF,
            "iconClr": 0xFF15B79E
          },
          {
            "icon": "assets/images/users.png",
            "menu": "Patients",
            "routeName": "Patients",
            "color": 0xFFEFF1F5,
            "iconClr": 0xFF5D6B98
          },
        ];
        break;
    }
    state = state.copyWith(menus: menuList);
  }

  Future<void> readUser() async {
    state = state.copyWith(isLoading: true);
    var result = await getSavedUser();
    if (result != null) {
      state = state.copyWith(userInfo: result);
      getMenuList("Admin");
      state = state.copyWith(isLoading: false);
    }
  }


  void filterCall(int index) {
    state = state.copyWith(isLoading: true);

    Future.microtask(() {
      try {
        final filteredList = state.appointmentList?.where((appointment) {
          final dateString = appointment['AppointmentDateTime']?.toString();
          if (dateString == null || dateString.isEmpty) {
            return false;
          }

          try {
            final appointmentDate = DateTime.parse(dateString);

            switch (index) {
              case 0: // Today
                return appointmentDate.isSameDay(DateTime.now());

              default:
                return false;
            }
          } catch (e) {
            return false;
          }
        }).toList() ?? [];

        // Update state immediately after filtering
        state = state.copyWith(
          appointmentList: filteredList,
          todaysappointmentList: filteredList,
          isLoading: false,
        );

      } catch (e) {
        // Handle any unexpected errors
        state = state.copyWith(
          appointmentList: [],
          todaysappointmentList:[],
          isLoading: false,
        );
      }
    });
  }


  Future<void> getFilterAppointments() async {
    state=state.copyWith(isLoading: true);
    try {
      final response = await  ApiService().get('/pms/get/allappointments', {});
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      if(res !=null){
        state=state.copyWith(appointmentList: res['data']);
        filterCall(0);
      }else if(response.statusCode==401){
      }
    } catch (e) {
      print(e);
    }
  }

  Future<UserModel?> getSavedUser() async {
    try {
      final userString = await StorageServices.read('userInfo');
      if (userString != null) {
        return UserModel.fromJson(userString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}





final homeProvider =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) => HomeNotifier());

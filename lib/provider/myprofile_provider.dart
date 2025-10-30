import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/storage_services.dart';

class MyProfileState {
  final Map<String, dynamic> userInfo;
  final bool isLoading;

  MyProfileState({required this.userInfo,required this.isLoading});

  MyProfileState copyWith({
    Map<String, dynamic>? userInfo,
    bool? isLoading,
  }) {
    return MyProfileState(
      userInfo: userInfo ?? this.userInfo,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MyProfileNotifier extends StateNotifier<MyProfileState> {
  MyProfileNotifier() : super(MyProfileState(userInfo: {},isLoading: false)) {}

  Future<void> readUser() async {
    var storedUserInfo = await StorageServices.read('userInfo');
    if (storedUserInfo != null) {
      state = state.copyWith(userInfo: storedUserInfo);
    }
  }



  Future<void> updateRole(dynamic role) async {
    state = state.copyWith(isLoading: true);
    var defaultRole = {"role": role['RoleName'], "roleId": role['RoleId']};
    await StorageServices.delete('DefaultRole');
    await StorageServices.write('DefaultRole', defaultRole);
    state = state.copyWith(isLoading: false);
    Fluttertoast.showToast(
      msg: "Role has been Changed",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}


final myProfileProvider = StateNotifierProvider<MyProfileNotifier, MyProfileState>((ref) {
  return MyProfileNotifier();
});

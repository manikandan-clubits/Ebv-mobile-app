class UserModel {
  final int? userID;
  final String? userGuid;
  final String? userName;
  final String? email;
  final String? roleName;
  final String? twoFactorAuth;
  final int? roleId;
  final String? accountGuid;
  final int? locationId;
  final String? locationName;

  UserModel({
    this.userID,
    this.userGuid,
    this.userName,
    this.email,
    this.roleName,
    this.twoFactorAuth,
    this.roleId,
    this.accountGuid,
    this.locationId,
    this.locationName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userID: json['UserId'] as int?,
    userGuid: json['UserGuid'] as String?,
    userName: json['UserName'] as String?,
    email: json['Email'] as String?,
    roleName: json['RoleName'] as String?,
    twoFactorAuth: null,
    roleId: json['RoleId'] as int?,
    accountGuid: json['AccountGuid'] as String?,
    locationId: json['LocationId'] as int?,
    locationName: json['LocationName'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'UserId': userID,
    'UserGuid': userGuid,
    'UserName': userName,
    'Email': email,
    'RoleName': roleName,
    'TwoFactorAuth': null,
    'RoleId': roleId,
    'AccountGuid': accountGuid,
    'LocationId': locationId,
    'LocationName': locationName,
  };

  UserModel copyWith({
    int? userID,
    String? userGuid,
    String? userName,
    String? email,
    String? roleName,
    String? twoFactorAuth,
    int? roleId,
    String? accountGuid,
    int? locationId,
    String? locationName,
  }) {
    return UserModel(
      userID: userID ?? this.userID,
      userGuid: userGuid ?? this.userGuid,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      roleName: roleName ?? this.roleName,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      roleId: roleId ?? this.roleId,
      accountGuid: accountGuid ?? this.accountGuid,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
    );
  }
}
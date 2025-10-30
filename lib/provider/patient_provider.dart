import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/user_model.dart';
import '../screens/auth/email_login.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../services/storage_services.dart';


extension DateTimeExtensions on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  bool isToday() {
    final now = DateTime.now();
    return isSameDay(now);
  }

  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(tomorrow);
  }
}

class PatientState {
  final List<dynamic>? ebvPatientList;
  final List<dynamic>? appointmentList;
  final List<dynamic>? filterappointments;
  final List<dynamic>? contactInfo;
  final List<dynamic>? insuranceInfo;
  final List<dynamic>? pmsPatientList;
  final List<dynamic>? searchList;
  final List<dynamic>? pmsSearchList;
  final List<dynamic>? patientCallHistory;
  final List<dynamic>? basicInfo;
  final dynamic patientReportData;
  bool isLoading;
  bool contactLoading;
  final String? pdfUrl;
  bool isDownloadLoading = false;
  UserModel? userInfo;
  PatientState(
      {
        this.ebvPatientList,
        this.filterappointments,
        this.appointmentList,
        this.insuranceInfo,
        this.basicInfo,
        this.contactInfo,
        this.pmsPatientList,
        this.searchList,
        this.pmsSearchList,
      this.userInfo,
      this.pdfUrl,
      this.isLoading = false,
      this.contactLoading = false,
      this.isDownloadLoading = false,
      this.patientReportData,
      this.patientCallHistory});

  PatientState copyWith(
      {List<dynamic>? ebvPatientList,
      List<dynamic>? filterappointments,
      List<dynamic>? insuranceInfo,
      List<dynamic>? appointmentList,
      List<dynamic>? pmsPatientList,
      List<dynamic>? contactInfo,
        final List<dynamic>? basicInfo,
      List<dynamic>? pmsSearchList,
      List<dynamic>? searchList,
      List<dynamic>? patientCallHistory,
      bool isLoading = false,
      String? pdfUrl,
      bool isDownloadLoading = false,
      bool contactLoading = false,
      dynamic patientReportData,
      UserModel? userInfo
      }) {
    return PatientState(
        ebvPatientList: ebvPatientList ?? this.ebvPatientList,
        appointmentList: appointmentList ?? this.appointmentList,
        filterappointments: filterappointments ?? this.filterappointments,
        insuranceInfo: insuranceInfo ?? this.insuranceInfo,
        contactInfo: contactInfo ?? this.contactInfo,
        basicInfo: basicInfo ?? this.basicInfo,
        pmsPatientList: pmsPatientList ?? this.pmsPatientList,
        searchList: searchList ?? this.searchList,
        pmsSearchList: searchList ?? this.pmsSearchList,
        patientCallHistory: patientCallHistory ?? this.patientCallHistory,
        patientReportData: patientReportData ?? this.patientReportData,
        isLoading: isLoading,
        contactLoading: contactLoading,
        isDownloadLoading: isDownloadLoading,
        userInfo: this.userInfo,
        pdfUrl: this.pdfUrl
    );
  }
}

class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier() : super(PatientState(ebvPatientList: [], patientCallHistory: [],appointmentList:[],filterappointments:[]));


  void navigateToLogin(BuildContext context) async {
    await StorageServices.delete("userInfo");
    await StorageServices.delete('accessToken');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => SignIn()),
      (route) => false,
    );

    Fluttertoast.showToast(
      msg: "Sorry Your Token has been expired",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.SNACKBAR,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }


  Future<void> getBasicInfo(patientID) async {
    Map<String, dynamic> params = {"PatientId":patientID.toString()};
    try {
      final response = await ApiService().post('/pms/patient/basicinfo', params);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      state=state.copyWith(basicInfo: res['data']);
    }finally{
      getFamilyInfo(patientID);
    }
  }

  Future<void> getFamilyInfo(patientID) async {
    Map<String, dynamic> params = {"PatientId":patientID.toString()};
    state= state.copyWith(contactLoading: true);
      final response = await  ApiService().post('/pms/get/patientcontactinfo',params);
    final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
    state = state.copyWith(contactInfo: res['data']);
      state= state.copyWith(contactLoading: false);
      getInsuranceInfo(patientID);
    }

  Future<void> getInsuranceInfo(patientID) async {
    Map<String, dynamic> params = {"PatientId":patientID.toString()};
    state= state.copyWith(contactLoading: true);
    final response = await  ApiService().post('/pms/get/insuranceinfo',params);
    final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
    state = state.copyWith(insuranceInfo: res['data']);
    state= state.copyWith(contactLoading: false);
  }


  Future<String?> getBasicPdf(BuildContext context, String patientID, String type) async {
    try {
      Map<String, dynamic> params = {
        "patientId": patientID, // Use the passed patientID
        "eligibilityId": "d836c5b0-5175-4acb-849c-d2584ff1d641",
        "basicReport": true
      };

      state = state.copyWith(isLoading: true);

      final response = await ApiService().post('/eligibility/getreport', params);

      // Decrypt the response
      final res = ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      log("Decrypted response: $res");

      String? pdfUrl;

      // Extract PDF URL from response
      if (res is Map<String, dynamic>) {
        if (res.containsKey('pdfUrl')) {
          pdfUrl = res['pdfUrl'] as String?;
        } else if (res.containsKey('url')) {
          pdfUrl = res['url'] as String?;
        } else if (res.containsKey('data') && res['data'] is Map) {
          pdfUrl = res['data']['pdfUrl'] as String?;
        }
      }

      // Validate and construct full URL if needed
      if (pdfUrl == null || pdfUrl.isEmpty) {
        state = state.copyWith(isLoading: false);
        return null;
      }

      // If the URL is relative, construct the full URL
      if (!pdfUrl.startsWith('http')) {
        pdfUrl = 'https://dev-ebv-backend-ffafgsdhg8chbvcy.southindia-01.azurewebsites.net$pdfUrl';
      }

      log("Final PDF URL: $pdfUrl");
      state = state.copyWith(isLoading: false);
      return pdfUrl;

    } catch (e) {
      state = state.copyWith(isLoading: false);
      log("Error in getBasicPdf: $e");
      return null;
    }
  }

  void showPdfViewer(BuildContext context, String pdfUrl, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SfPdfViewer.network(
            pdfUrl,
            canShowHyperlinkDialog: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              log("PDF loaded successfully");
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              log("PDF load failed: ${details.error}");
            },
          ),
        ),
      ),
    );
  }


  Future<void> getPracticePdf(context,patientID) async {
    Map<String, dynamic> params =
    {
      "patientId": "M4102",
      "eligibilityId": "d836c5b0-5175-4acb-849c-d2584ff1d641",
      "basicReport": true
    };
    state= state.copyWith(isLoading: true);
    final response = await  ApiService().post('/eligibility/getreport',params);
    final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
    showPdfViewer(context,res['pdfUrl'],'basicReport');
    state= state.copyWith(isLoading: false);
  }


  Future<void> getDetailedPdf(context,patientID,Type) async {
    Map<String, dynamic> params =
    {
      "patientId": "M4102",
      "eligibilityId": "d836c5b0-5175-4acb-849c-d2584ff1d641",
      "basicReport": true
    };
    state= state.copyWith(isLoading: true);
    final response = await  ApiService().post('/eligibility/getreport',params);
    final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
    showPdfViewer(context,res['pdfUrl'],Type);
    state= state.copyWith(isLoading: false);
  }


  getPmsPatients(context) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ApiService().get('/pms/get/patients', {});
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      if (res != null) {
        state = state.copyWith(pmsPatientList: res['data'],pmsSearchList:res['data'] );
      }
      else if (response.statusCode == 401) {
        navigateToLogin(context);
        log("Unauthorized access:${response.statusCode}");
      }
      else {
        log("Unexpected response: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      log('Error fetching patients: $e', error: e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }


  getEbvPatients(context) async {
    state = state.copyWith(isLoading: true);
    Map<String, dynamic> params = {
      "Status": "",
      "addedFrom": "Auto",
      "LocationId": null
    };
    try {

      final response = await ApiService().post('/patients/getallpatients2', params);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      if (res != null) {
        state = state.copyWith(ebvPatientList: res['data'],searchList:res['data'] );
      }
      else if (response.statusCode == 401) {
        navigateToLogin(context);
      }
      else {
        log("Unexpected response: ${response.statusCode} - ${response.data}");
      }
    } catch (e) {
      log('Error fetching patients: $e', error: e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> getPatientsCallHistory(context) async {
    state = state.copyWith(isLoading: true);
    final Map<String, dynamic> params = {"CallType": "All"};
    try {
      final response = await ApiService().post('/patients/allcall/history', params);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      if (res != null) {
        final List<dynamic> callHistory = res['data'];
        state = state.copyWith(patientCallHistory: callHistory.toList());
      }
      else if (response.statusCode == 401) {
        navigateToLogin(context);
      }
    } catch (e) {
      state = state.copyWith(patientCallHistory: []);
      log('Error fetching call history: $e', error: e);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  getPatientById(var ID,context) async {
    state = state.copyWith(isLoading: true);
    Map<String, dynamic> params = {
      "PatientId": ID,
      "ADACode": "",
      "CoveragePer": "",
      "Comments": "",
      "Network": "Out-Of-Network",
      "EligibilityId": ""
    };
    try {
      final response = await ApiService().post('/eligibility/getreportdata', params);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      state = state.copyWith(patientReportData: res['Result']);
      // getReportPdf(ID,context);
    } catch (e) {
      print('Error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  getReportPdf(var ID,context) async {
    state=state.copyWith(isDownloadLoading: true);

    Map<String, dynamic> basicParams ={
      "patientId": "M246",
    "eligibilityId": "97d32070-c40b-49cc-b500-052aabab627b",
    "basicReport": true
  };

    Map<String, dynamic> params = {
        "PatientId": ID,
        "ADACode": "",
        "CoveragePer": "",
        "Comments": "",
        "Network": "",
        "EligibilityId": ""
    };


    Map<String, dynamic> detailedParams ={
      "patientId": "M246",
      "eligibilityId": "97d32070-c40b-49cc-b500-052aabab627b",
      "basicReport": false
    };





    try {
      final response = await ApiService().post('/eligibility/getreportPdf', params);
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);
      state = state.copyWith(pdfUrl: res['pdfUrl'],isDownloadLoading: false);
    } catch (e) {
      print('Error: $e');
    } finally {
      state=state.copyWith(isDownloadLoading: true);
    }
  }


  Future<void> getAppointments(context) async {
    state=state.copyWith(isLoading: true);
    try {
      final response = await  ApiService().get('/pms/get/allappointments', {});
      final res=  ApiService().decryptData(response.data['encryptedData']!, response.data['iv']);

      if(res !=null){
        state = state.copyWith(appointmentList: res['data'],filterappointments: res['data']);
        filterCall(3);
      }else if(response.statusCode==401){
        navigateToLogin(context);
      }
    } catch (e, stackTrace) {
      debugPrint(stackTrace.toString());
    }
  }


  void filterDay(DateTime selectedDate) {
    if (state.isLoading || state.appointmentList == null) {
      return;
    }

    state = state.copyWith(isLoading: true);
    Future<void>.microtask(() async {
      try {
        final List<dynamic> filteredList = [];

        for (final appointment in state.appointmentList!) {
          final dateString = appointment['AppointmentDateTime']?.toString();

          if (dateString == null || dateString.isEmpty) {
            continue;
          }

          final appointmentDate = DateTime.parse(dateString);

          // Compare only the date part (ignore time)
          final isSameDay = appointmentDate.year == selectedDate.year && appointmentDate.month == selectedDate.month && appointmentDate.day == selectedDate.day;

          if (isSameDay) {
            filteredList.add(appointment);
          }
        }

        // Update state with filtered results
        state = state.copyWith(
          filterappointments: filteredList,
          isLoading: false,
        );

      } catch (e) {
        debugPrint('Filter error: $e');
        state = state.copyWith(
          isLoading: false,
        );
      }
    });
  }




  void filterCall(int index) {
    final currentDate = DateTime.now();
    state = state.copyWith(isLoading: true);

    // Use microtask for immediate execution in the next event loop
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

              case 1: // Tomorrow
                final tomorrow = DateTime.now().add(const Duration(days: 1));
                return appointmentDate.isSameDay(tomorrow);

              case 2: // Upcoming (after today, excluding today)
                final now = DateTime.now();
                return appointmentDate.isAfter(now) &&
                    !appointmentDate.isSameDay(now);

              case 3: // All appointments
                return true;

              default:
                return false;
            }
          } catch (e) {
            debugPrint('Error parsing date "$dateString": $e');
            return false;
          }
        }).toList() ?? [];

        // Update state immediately after filtering
        state = state.copyWith(
          filterappointments: filteredList,
          isLoading: false,
        );

      } catch (e) {
        // Handle any unexpected errors
        debugPrint('Error in filterCall: $e');
        state = state.copyWith(
          filterappointments: [],
          isLoading: false,
        );
      }
    });
  }



  Widget _buildPdfViewer(String? pdfUrl) {
    if (state.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (pdfUrl == null || pdfUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              "PDF not available",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "The PDF file could not be loaded",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SfPdfViewer.network(
      pdfUrl,
      canShowHyperlinkDialog: true,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        log("PDF loaded successfully");
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        log("PDF load failed: ${details.error}");
      },
    );
  }



  Future<void> _downloadPdf(BuildContext context, String url) async {
    final fileName = "patientpdf";

    // Request permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required',selectionColor: Colors.blue,)),
      );
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory('/storage/emulated/0/Download');
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to $filePath')),
        );
      } else {
        throw Exception('Failed to download');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }


  fetchWebViewDialog() {
    WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.blue)
      ..loadRequest(Uri.parse(
          'https://calldesk.pulsework360.com/Dialer/3996c82aa955ab45fcc76f39d217f371/clicktocallpage.php?userID=2711001&secret=Clubuser@1001&authID=3996c82aa955ab45fcc76f39d217f371&data=M3015_bab44c3f-495e-4e7f-b5e0-dc6fa3c57eeb'));
  }

  Future<bool> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> fetchVOIP(patientID, phoneNumber, selectedCountry) async {
    final String url;
    if (selectedCountry.toString() == "US") {
      url =
          "https://jgtwbdemr2.execute-api.ap-south-1.amazonaws.com/V1/NumberPushApi?agentID=2711002&dstNum=$phoneNumber&authId=3996c82aa955ab45fcc76f39d217f371&data=${patientID ?? state.userInfo?.userGuid}";
    } else {
      print("IN");
      url =
          "https://jgtwbdemr2.execute-api.ap-south-1.amazonaws.com/V1/NumberPushApi?agentID=2711001&dstNum=$phoneNumber&authId=3996c82aa955ab45fcc76f39d217f371&data=${patientID ?? state.userInfo?.userGuid}";
    }

    if (!await _requestMicrophonePermission()) {
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {}
    } catch (e) {
      print('Error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void searchCallPatient(String search) {
    var filteredList = state.searchList?.where((e) => e['PatientName'].toString().toLowerCase().contains(search.toLowerCase()) ||
        e['patientId'].toString().toLowerCase().contains(search.toLowerCase())).toList();
    state = state.copyWith(ebvPatientList: filteredList);
  }

  void searchCallPmsPatient(String search) {
    var filteredList = state.pmsSearchList?.where((e) => e['PatientName'].toString().toLowerCase().contains(search.toLowerCase()) ||
        e['patientId'].toString().toLowerCase().contains(search.toLowerCase())).toList();
    state = state.copyWith(pmsPatientList: filteredList);
  }

  Future<void> readUser() async {
    var result = await getSavedUser();
    if (result != null) {
      state = state.copyWith(userInfo: result);
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

final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>((ref) {
  return PatientNotifier();
});

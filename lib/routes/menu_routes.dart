import 'package:ebv/screens/appointments/appointments.dart';
import 'package:ebv/screens/auth/authenticator.dart';
import 'package:ebv/screens/callhistory/call_history.dart';
import 'package:ebv/screens/dashboard/dashboard.dart';
import 'package:ebv/screens/voip/dial_pad.dart';
import 'package:ebv/screens/patient/eligibility_patients.dart';
import 'package:ebv/screens/patient/patients.dart';
import 'package:flutter/material.dart';
import '../screens/home/home.dart';



class MenuRoutes {


  static goRoute(var route,context) async{
    switch (route) {

      case 'Home':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> Home()));
        break;

      case 'EBV':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> PatientsEligibility()));
        break;
        case 'Appointment':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> Appointments()));
        break;
        case 'Patient':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> PmsPatients()));
        break;
      case 'VOIP':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> DialPadScreen()));
        break;
        case 'DialPad':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> DialPadScreen()));
        break;

      case 'CallHistory':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> CallHistory()));
        break;
        case 'Dashboard':
        Navigator.push(context, MaterialPageRoute(builder: (context)=>  Dashboard(),));
        break;

        case 'Authenticator':
        Navigator.push(context, MaterialPageRoute(builder: (context)=> Authenticator()));
        break;

    }
  }
}
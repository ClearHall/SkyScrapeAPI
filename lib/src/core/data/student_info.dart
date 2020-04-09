part of '../data_types.dart';

class StudentInfo {
  String name;
  Map<String, String> studentAttributes;
  List<EmergencyContact> emergencyContacts;
  SchoolInfo currentSchool;
  List<Family> family;

  StudentInfo() {
    studentAttributes = Map();
    emergencyContacts = List();
    currentSchool = SchoolInfo();
    family = List();
  }

  @override
  String toString() {
    return 'StudentInfo{name: $name, studentAttributes: $studentAttributes, emergencyContacts: $emergencyContacts, currentSchool: $currentSchool, family: $family}';
  }
}

class SchoolInfo {
  String schoolName;
  Map<String, String> attributes;

  SchoolInfo() {
    attributes = Map();
  }

  @override
  String toString() {
    return 'SchoolInfo{schoolName: $schoolName, attributes: $attributes}';
  }
}

class EmergencyContact {
  String name;
  Map<String, String> attributes;

  EmergencyContact() {
    attributes = Map();
  }

  @override
  String toString() {
    return 'EmergencyContacts{name: $name, attributes: $attributes}';
  }
}

class Family {
  List<Guardian> guardians;
  Map<String, String> extraInfo;

  Family() {
    guardians = List();
    extraInfo = Map();
  }

  @override
  String toString() {
    return 'Family{guardians: $guardians, extraInfo: $extraInfo}';
  }
}

class Guardian {
  String guardianName;
  Map<String, String> extraInfo;

  Guardian() {
    extraInfo = Map();
  }

  @override
  String toString() {
    return 'Guardian{guardianName: $guardianName, extraInfo: $extraInfo}';
  }
}

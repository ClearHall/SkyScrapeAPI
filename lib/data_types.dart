library sky_types;

/// [Term] allow for the scrapers to sort through the grades and retrieve grades for certain terms.
///
/// [Term] is JSON compatible and can be converted to a JSON if needed.
class Term {
  /// TermCode is the identifier used to identify the term.
  String termCode;

  /// TermName is the name of the term used if needed for extra identification or display
  String termName;

  // Simple constructor to initialize the termCode and termName
  Term(this.termCode, this.termName);

  @override
  String toString() {
    return "$termCode : $termName";
  }

  Term.fromJson(Map<String, dynamic> json)
      : termCode = json['termCode'],
        termName = json['termName'];

  Map<String, dynamic> toJson() => {
        'termCode': termCode,
        'termName': termName,
      };

  /// Compares the term codes only
  @override
  bool operator ==(other) {
    if (other is Term) {
      return (other).termCode == this.termCode;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => termCode.hashCode;
}

class Gradebook {
  List<Class> classes;
  List<Term> terms;
  List<Assignment> quickAssignments;

  /// This compares assignment's assignment ID!
  /// This is useful if you are trying to find the term of an assignment in semesters.
  String getAssignmentTerm(Assignment a) {
    for (Assignment b in quickAssignments) {
      if (a.assignmentID == b.assignmentID)
        return b.attributes['term'].substring(1);
    }
    return null;
  }

  @override
  String toString() {
    return 'Gradebook{terms: $terms, classes: $classes, quickAssignments: $quickAssignments}';
  }
}

class Class {
  String teacherName;
  String timePeriod;
  String courseName;

  List<GradebookNode> grades;

  Class(this.teacherName, this.courseName, this.timePeriod, {this.grades}) {
    grades = List<GradebookNode>();
  }

  GradebookNode retrieveNodeByTerm(Term term) {
    for (GradebookNode node in grades) {
      if (node.term == term) return node;
    }
    return null;
  }

  @override
  String toString() {
    return 'Class{teacherName: $teacherName, timePeriod: $timePeriod, courseName: $courseName, grades: $grades}';
  }
}

/// [GradebookNode] is a root that helps distinguish the difference between grades and teacher information
///
/// There are only two children of [GradebookNode]
/// * [Behavior]
/// * [Grade]
abstract class GradebookNode {
  Term term;

  GradebookNode(this.term);
}

/// [Behavior] is an un-clickable behavior or letter grade.
class Behavior extends GradebookNode {
  String behavior;

  /// Identification for which term [Behavior] is in.
  Behavior(this.behavior, Term term) : super(term);

  @override
  String toString() {
    return term.toString() + ":" + behavior;
  }
}

/// [Grade] is most likely a clickable numbered grade part of a specific term
class Grade extends GradebookNode {
  String courseNumber;
  String grade;
  String studentID;

  /// Identification for which term [Grade] is in.
  Grade(this.courseNumber, Term term, this.grade, this.studentID) : super(term);

  //For debugging only.
  @override
  String toString() {
    return "${this.term.toString()} for ${this.grade} for course # ${this.courseNumber} for student ${this.studentID}";
  }
}

/// [AssignmentNode] is the parent of multiple child types that allow for more categorization
abstract class AssignmentNode {
  String name;

  /// All the attributes like grades, post values, and more.
  /// **NOTE: THIS MAP IS NOT SAFE TO MODIFY IN YOUR CODE. DO IT WITH CAUTION**
  Map<String, String> attributes;

  AssignmentNode(this.name, this.attributes);

  @override
  String toString() {
    return "";
  }

  bool operator ==(other) {
    if (this is Assignment && other is Assignment) {
      return (this as Assignment).assignmentID == other.assignmentID;
    } else if (other is AssignmentNode) {
      return name == other.name;
    } else {
      return false;
    }
  }

  /// Attempts to get the assignment name
  String getAssignment() {
    return attributes[attributes.keys.toList()[1]];
  }

  /// Attempts to get a decimal grade if there is one.
  /// If there is no decimal grade in the map, then it'll attempt to find and return the integer grade by calling [getIntGrade()]
  /// Read [getIntGrade()] documentation to see what it returns.
  String getDecimal() {
    for (String a in attributes.values) {
      if (double.tryParse(a) != null && a.contains('.')) {
        return a;
      }
    }
    return getIntGrade();
  }

  /// Attempts to find an integer grade in the map.
  /// If one is not found, it'll return null.
  /// **NOTE: REMEMBER TO CHECK FOR THIS NULL IN YOUR CODE**
  String getIntGrade() {
    for (String val in attributes.values) {
      if (int.tryParse(val) != null) {
        return val;
      }
    }
    return null;
  }
}

class DetailedGradingPeriod {
  Map<List<CategoryHeader>, List<Assignment>> assignments = Map();
  Map<String, String> attributes = Map();

  DetailedGradingPeriod();
  DetailedGradingPeriod.define(this.assignments, this.attributes);

  @override
  String toString() {
    return 'DetailedGradingPeriod{assignments: $assignments, attributes: $attributes}';
  }
}

/// [Assignment] is an assignment scraped from the API
///
/// [Assignment] is really hard to make, so custom declarations of Assignments is highly discouraged.
class Assignment extends AssignmentNode {
  /// Post required attributes. Do not worry about this value if you do not plan to modify [Assignment]
  String studentID;
  String assignmentID;
  String gbID;

  Assignment(this.studentID, this.assignmentID, this.gbID, String name,
      Map<String, String> attributes)
      : super(name, attributes);

  @override
  bool operator ==(other) {
    if (other is Assignment) return assignmentID == other.assignmentID;
    return false;
  }

  @override
  String toString() {
    return 'Assignment{studentID: $studentID, assignmentID: $assignmentID,gbID: $gbID, assignmentName: $name, attributes: $attributes}';
  }
}

/// [CategoryHeader] is an category scraped from the API
///
/// [CategoryHeader] marks the beginning of a new Category, so it contains weight information and juicy stuff that allows you to distinguish assignments from categories
class CategoryHeader extends AssignmentNode {
  String weight;

  CategoryHeader(String name, this.weight, Map<String, String> attributes)
      : super(name, attributes);

  @override
  String toString() {
    return 'CategoryHeader{catName: $name,weight: $weight}';
  }
}

/// [AssignmentProperty] contains the attribute name and the value that the attribute holds
/// [infoName] and [info] are both paired together to declare a specific value. For example, "Due Date" and "9/3/19"
class AssignmentProperty {
  String infoName;
  String info;

  AssignmentProperty(this.infoName, this.info);

  String getDebug() {
    return infoName + ':' + info;
  }

  @override
  String toString() {
    return infoName +
        (!infoName.endsWith(":") ? ":" : "") +
        ' ' +
        (info != null ? info : "");
  }
}

/// [SkywardSearchState] is a US State, except for "International" that has an ID to input into the District Searcher
class SkywardSearchState {
  String stateName;
  String stateID;

  SkywardSearchState(this.stateName, this.stateID);

  @override
  String toString() {
    return 'State{stateName: $stateName, stateID: $stateID}';
  }
}

/// [SkywardDistrict] are usually returned a list and contains results taken from searching for districts.
///
/// [SkywardDistrict] is JSON compatible and can be used to store SkywardDistricts or use it in a server to return as a json file.
class SkywardDistrict {
  String districtName;
  String districtLink;

  SkywardDistrict(this.districtName, this.districtLink);

  SkywardDistrict.fromJson(Map<String, dynamic> json)
      : districtName = json['districtName'],
        districtLink = json['districtLink'];

  Map<String, dynamic> toJson() => {
        'districtName': districtName,
        'districtLink': districtLink,
      };

  @override
  bool operator ==(other) {
    if (other is SkywardDistrict)
      return districtLink == other.districtLink;
    else
      return false;
  }

  @override
  int get hashCode => districtLink.hashCode;

  @override
  String toString() {
    return 'SkywardDistrict{districtName: $districtName, districtLink: $districtLink}';
  }
}

/// [SchoolYear] is usually returned in a List from [SkywardAPICore.getHistory()]
///
/// SchoolYear provides information about the school year and is JSON Compatible so it can be saved or returned from a server
/// The [description] of the [SchoolYear] is just the name of the [SchoolYear] under Skyward. [terms] are also taken just in case your district has changed terms in its skyward history.
/// [classes] is a list of [HistoricalClass], for more information, read up on [HistoricalClass] documentation.
class SchoolYear {
  String description;
  List<Term> terms;
  //First String represents class, in each class theres a map of the term and then the grade of that term.
  List<HistoricalClass> classes;

  /// This is an extra attribute you can use in your application just in case you need it.
  bool isEnabled = true;

  SchoolYear();

  SchoolYear.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        terms = getTermsFromEncodedTermsList(json['terms']),
        classes = getClassesFromEncodedClassesList(json['classes']),
        isEnabled = json['isEnabled'];

  /// Function to convert encoded terms to a list of terms. Be careful while using this because this should only be used by the API and not the user. Unless the user is trying to make a custom JSON Manager.
  static List<Term> getTermsFromEncodedTermsList(List terms) {
    List<Term> fin = [];
    for (var x in terms) {
      fin.add(Term.fromJson(x));
    }
    return fin;
  }

  /// Classes retrieved. **MAY CAUSE ERRORS IF YOU ATTEMPT TO USE THIS FUNCTION**
  static List<HistoricalClass> getClassesFromEncodedClassesList(List classes) {
    List<HistoricalClass> fin = [];
    for (var x in classes) {
      fin.add(HistoricalClass.fromJson(x));
    }
    return fin;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'terms': terms,
        'classes': classes,
        'isEnabled': isEnabled
      };

  @override
  String toString() {
    return 'SchoolYear{description: $description, classes: $classes}';
  }

  @override
  bool operator ==(other) {
    return classes.length == other.classes.length;
  }

  @override
  int get hashCode => description.hashCode;
}

/// [HistoricalClass] is a rich information class that holds settings and information about your classes.
///
/// **Some Things to Note**
/// * [classLevel] is set by the developer or user, not automatically retrieved.
/// * [credits] is set by the developer or user, not automatically retrieved.
class HistoricalClass {
  String name;
  List<String> grades;
  double credits;
  ClassLevel classLevel;

  HistoricalClass(this.name);

  HistoricalClass.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        grades = getGradesFromEncodedGradesList(json['grades']),
        credits = json['credits'],
        classLevel = getClassLevelFromText(json['classLevel']);

  Map<String, dynamic> toJson() => {
        'name': name,
        'grades': grades,
        'credits': credits,
        'classLevel': classLevel.toString(),
      };

  static ClassLevel getClassLevelFromText(String txt) {
    try {
      return ClassLevel.values.firstWhere((e) => e.toString() == txt);
    } catch (e) {
      return ClassLevel.Regular;
    }
  }

  static List<String> getGradesFromEncodedGradesList(List grades) {
    List<String> fin = [];
    for (var x in grades) {
      fin.add(x);
    }
    return fin;
  }

  @override
  String toString() {
    return 'GPACalculatorClass{name: $name, grades: $grades, credits: $credits, classLevel: $classLevel}';
  }

  @override
  bool operator ==(other) {
    return name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Account returned for internal API use when a parent account is parsed
class Child {
  final String dataID, name;
  Child(this.dataID, this.name);

  @override
  String toString() {
    return 'SkywardAccount{dataID: $dataID, name: $name}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Child &&
          runtimeType == other.runtimeType &&
          dataID == other.dataID;

  @override
  int get hashCode => dataID.hashCode;
}

class Message {
  String date, header, dataId;
  MessageBody body;
  MessageTitle title;

  Message(this.dataId, this.date, this.header, this.title, this.body);

  @override
  bool operator ==(other) {
    return other is Message && other.title == this.title;
  }

  @override
  String toString() {
    return 'Message{date: $date, title: $title, header: $header, dataId: $dataId, body: $body}';
  }

  @override
  int get hashCode => title.hashCode;
}

class MessageTitle {
  String title;
  Link attachment;

  MessageTitle(this.title, this.attachment);

  @override
  String toString() {
    return 'MessageTitle{title: $title, attachment: $attachment}';
  }
}

class MessageBody {
  List _arr = [];

  void addTextSection(String txt) {
    _arr.add(txt);
  }

  void addLinkSection(String link, String txt) {
    if (_arr.last == link) _arr.removeLast();
    _arr.add(Link(link, txt));
  }

  List getArr() => _arr;

  @override
  String toString() {
    return 'MessageBody{_arr: $_arr}';
  }
}

class Link {
  final String link, text;

  Link(this.link, this.text);

  @override
  String toString() {
    return 'Link{link: $link, text: $text}';
  }
}

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

enum ErrorCode {
  LoginError,
  RefreshTimeLessThanOne,
  UnderMaintenance,
  ExceededRefreshTimeLimit
}

/// Just ClassLevels, nothing special.
enum ClassLevel { Regular, PreAP, AP, None }

/// SkyScrapeAPI Custom errors to locate errors and give proper causes.
///
/// **NOTE: THE WHOLE API WILL USE THIS EXCEPTION**
class SkywardError implements Exception {
  String cause;
  ErrorCode errorCode;

  SkywardError(this.cause);
  SkywardError.usingErrorCode(this.errorCode);

  String getErrorCode() {
    return errorCode.toString().split('.')[1];
  }

  String getErrorCodeMessage() {
    if (errorCode != null) {
      switch (errorCode) {
        case ErrorCode.LoginError:
          return 'An fatal unexpected error has occured while logging in!';
          break;
        case ErrorCode.RefreshTimeLessThanOne:
          return 'Refresh times cannot be set to a value less than 1!';
          break;
        case ErrorCode.UnderMaintenance:
          return 'Your district\'s Skyward seems like it\'s on maintenance';
          break;
        case ErrorCode.ExceededRefreshTimeLimit:
          return 'Refresh times were exceeded. An unexpected error has occured. Please report this to the developer!';
          break;
        default:
          return 'Could not retrieve an error message!';
      }
    } else {
      return null;
    }
  }

  @override
  String toString() {
    if (cause != null)
      return cause;
    else
      return getErrorCode();
  }
}

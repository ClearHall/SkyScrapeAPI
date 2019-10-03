class Term {
  String termCode;
  String termName;

  Term(this.termCode, this.termName);

  //For debugging only.
  @override
  String toString() {
    return "$termCode : $termName";
  }

  Term.fromJson(Map<String, dynamic> json)
      : termCode = json['termCode'],
        termName = json['termName'];

  Map<String, dynamic> toJson() =>
      {
        'termCode': termCode,
        'termName': termName,
      };

  @override
  bool operator ==(other) {
    if(other is Term){
      return (other).termCode == this.termCode;
    }else{
      return false;
    }
  }

  @override
  int get hashCode => termCode.hashCode;
}

class GridBox{
  bool clickable = false;
}

class TeacherIDBox extends GridBox{
  String teacherName;
  String timePeriod;
  String courseName;

  TeacherIDBox(this.teacherName, this.courseName, this.timePeriod);

  @override
  String toString() {
    return teacherName + ":" + courseName + ":" + timePeriod;
  }
}

class GradeTextBox extends GridBox{
  Term term;

  GradeTextBox(this.term);
}

class LessInfoBox extends GradeTextBox{
  String behavior;

  LessInfoBox(this.behavior, Term term):super(term);

  @override
  String toString() {
    return term.toString() + ":" + behavior;
  }
}

class GradeBox extends GradeTextBox{
  String courseNumber;
  String grade;
  String studentID;

  GradeBox(this.courseNumber, Term term, this.grade, this.studentID):super(term);

  //For debugging only.
  @override
  String toString() {
    return "${this.term.toString()} for ${this.grade} for course # ${this.courseNumber} for student ${this.studentID}";
  }
}

class AssignmentsGridBox extends GridBox{
  Map<String, String> attributes;

  AssignmentsGridBox(this.attributes);

  @override
  String toString() {
    return "";
  }

  String getAssignment(){
    return attributes[attributes.keys.toList()[1]];
  }

  String getDecimal(){
      for(String a in attributes.values){
        if(double.tryParse(a) != null && a.contains('.')){
          return a;
        }
      }
      return getIntGrade();
  }

  String getIntGrade(){
    for(String val in attributes.values){
      if(int.tryParse(val) != null){
        return val;
      }
    }
    return null;
  }
}

class Assignment extends AssignmentsGridBox{
  String studentID;
  String assignmentID;
  String gbID;
  String assignmentName;

  Assignment(this.studentID, this.assignmentID, this.gbID, this.assignmentName,Map<String, String> attributes):super(attributes);

  @override
  String toString() {
    return 'Assignment{studentID: $studentID, assignmentID: $assignmentID,gbID: $gbID, assignmentName: $assignmentName}';
  }
}

class CategoryHeader extends AssignmentsGridBox{
  String catName;
  String weight;

  CategoryHeader(this.catName, this.weight,Map<String, String> attributes):super(attributes);

  @override
  String toString() {
    return 'CategoryHeader{catName: $catName,weight: $weight}';
  }
}

class AssignmentInfoBox{
  String infoName;
  String info;

  String getUIMessage(){
    return infoName + ' ' + (info != null ? info : "");
  }

  AssignmentInfoBox(this.infoName, this.info);

  @override
  String toString() {
    return 'AssignmentInfoBox{infoName: $infoName, info: $info}';
  }
}

class SkywardSearchState{
  String stateName;
  String stateID;

  SkywardSearchState(this.stateName, this.stateID);

  @override
  String toString() {
    return 'State{stateName: $stateName, stateID: $stateID}';
  }
}

class SkywardDistrict{
  String districtName;
  String districtLink;

  SkywardDistrict(this.districtName, this.districtLink);

  SkywardDistrict.fromJson(Map<String, dynamic> json)
      : districtName = json['districtName'],
        districtLink = json['districtLink'];

  Map<String, dynamic> toJson() =>
      {
        'districtName': districtName,
        'districtLink': districtLink,
      };

  @override
  bool operator ==(other) {
    if(other is SkywardDistrict)
      return districtLink == other.districtLink;
    else
      return false;
  }

  @override
  String toString() {
    return 'SkywardDistrict{districtName: $districtName, districtLink: $districtLink}';
  }
}

class SchoolYear{
  String description;
  List<Term> terms;
  //First String represents class, in each class theres a map of the term and then the grade of that term.
  List<Class> classes;
  //SKYMOBILE SPECIFIC ATTRIBUTE
  bool isEnabled = true;

  SchoolYear();

  SchoolYear.fromJson(Map<String, dynamic> json)
      : description = json['description'],
        terms = getTermsFromEncodedTermsList(json['terms']),
        classes = getClassesFromEncodedClassesList(json['classes']),
        isEnabled = json['isEnabled'];

  static List<Term> getTermsFromEncodedTermsList(List terms){
    List<Term> fin = [];
    for(var x in terms){
      fin.add(Term.fromJson(x));
    }
    return fin;
  }

  static List<Class> getClassesFromEncodedClassesList(List classes){
    List<Class> fin = [];
    for(var x in classes){
      fin.add(Class.fromJson(x));
    }
    return fin;
  }

  Map<String, dynamic> toJson() =>
      {
        'description': description,
        'terms': terms,
        'classes': classes,
        'isEnabled': isEnabled
      };

  @override
  String toString() {
    return 'SchoolYear{description: $description, classes: $classes}';
  }
}

class Class{
  String name;
  List<String> grades; //Assumed all terms in parent terms are correct
  double credits;
  ClassLevel classLevel;

  Class(this.name);

  Class.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        grades = getGradesFromEncodedGradesList(json['grades']),
        credits = json['credits'],
        classLevel = getClassLevelFromText(json['classLevel']);

  Map<String, dynamic> toJson() =>
      {
        'name': name,
        'grades': grades,
        'credits': credits,
        'classLevel': classLevel.toString(),
      };

  static ClassLevel getClassLevelFromText(String txt){
    try{
      return ClassLevel.values.firstWhere((e) => e.toString() == txt);
    }catch(e, s){
      return ClassLevel.Regular;
    }
  }

  static List<String> getGradesFromEncodedGradesList(List grades){
    List<String> fin = [];
    for(var x in grades){
      fin.add(x);
    }
    return fin;
  }

  @override
  String toString() {
    return 'GPACalculatorClass{name: $name, grades: $grades, credits: $credits, classLevel: $classLevel}';
  }
}

enum ClassLevel{
  Regular,
  PreAP,
  AP,
  None
}
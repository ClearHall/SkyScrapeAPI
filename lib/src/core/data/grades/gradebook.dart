part of '../../data_types.dart';

class Gradebook {
  final List<GradebookSector> gradebookSectors;

  Gradebook(this.gradebookSectors);

  List<Class> getAllClasses() {
    return gradebookSectors.expand((element) => element.classes).toList();
  }

  List<Assignment> getAllAssignments() {
    return gradebookSectors
        .expand((element) => element.quickAssignments)
        .toList();
  }

  List<Term> getAllTerms() {
    return gradebookSectors.expand((element) => element.terms).toList();
  }

  @override
  String toString() {
    return 'Gradebook{gradebookSectors: $gradebookSectors}';
  }

  Gradebook.fromJson(Map<String, dynamic> json)
      : gradebookSectors =
            (json['c'] == null ? _getSectorList(json) : _fromCompressed(json));

  static List<GradebookSector> _getSectorList(Map<String, dynamic> json) {
    return json['g']
        .map((value) => GradebookSector.fromJson(value))
        .toList()
        .cast<GradebookSector>();
  }

  static List<GradebookSector> _fromCompressed(Map<String, dynamic> json) {
    for (Map sec in json['g']) {
      for (int i = 0; i < sec['t'].length; i++)
        sec['t'][i] = json['c'][sec['t'][i]];
      for (Map classes in sec['c']) {
        for (Map grades in classes['g']) {
          grades['t'] = json['c'][grades['t']];
          if (grades.containsKey('cN') && grades.containsKey('sID')) {
            grades['cN'] = json['cID'][grades['cN']];
            grades['sID'] = json['s'][grades['sID']];
          }
        }
      }
      for (Map qAssign in sec['qA']) {
        if (qAssign.containsKey('cID') && qAssign.containsKey('sID')) {
          qAssign['cID'] = json['cID'][qAssign['cID']];
          qAssign['sID'] = json['s'][qAssign['sID']];
        }
      }
    }
    json.remove('c');
    json.remove('cID');
    json.remove('s');
    return _getSectorList(json);
  }

  Map<String, dynamic> toJson() => {'g': gradebookSectors};

  Map<String, dynamic> toCompressedJson() {
    Map<String, dynamic> json = jsonDecode(jsonEncode(toJson()));
    List<Map> termCache = List<Map>();
    Set<String> studentID = Set();
    Set<String> courseID = Set();

    for (Map sec in json['g']) {
      for (int i = 0; i < sec['t'].length; i++)
        sec['t'][i] = _checkTermElems(sec['t'][i], termCache);
      for (Map classes in sec['c']) {
        for (Map grades in classes['g']) {
          grades['t'] = _checkTermElems(grades['t'], termCache);
          if (grades.containsKey('cN') && grades.containsKey('sID')) {
            _singleSetAdd(courseID, grades, 'cN');
            _singleSetAdd(studentID, grades, 'sID');
          }
        }
      }
      for (Map qAssign in sec['qA']) {
        if (qAssign.containsKey('cID') && qAssign.containsKey('sID')) {
          _singleSetAdd(courseID, qAssign, 'cID');
          _singleSetAdd(studentID, qAssign, 'sID');
        }
      }
    }

    json['s'] = studentID.toList();
    json['cID'] = courseID.toList();
    json['c'] = termCache;
    return json;
  }

  void _singleSetAdd(Set<String> set, Map grades, String id) {
    set.add(grades[id]);
    grades[id] = set.toList().indexOf(grades[id]);
  }

  int _checkTermElems(var grades, List<Map> termCache) {
    bool Function(Map) functionCheck = (element) =>
        element['tC'] == grades['tC'] && element['tN'] == grades['tN'];
    if (termCache.where(functionCheck).length == 0) termCache.add(grades);
    return termCache.indexWhere(functionCheck);
  }
}

class GradebookSector {
  List<Class> classes;
  List<Term> terms;
  List<Assignment> quickAssignments;

  GradebookSector() {
    classes = List();
    terms = List();
    quickAssignments = List();
  }

  /// This compares assignment's assignment ID!
  /// This is useful if you are trying to find the term of an assignment in semesters.
  String getAssignmentTerm(Assignment a) {
    for (Assignment b in quickAssignments) {
      if (a.assignmentID == b.assignmentID) return b.attributes['term'];
    }
    return null;
  }

  @override
  String toString() {
    return 'Gradebook{terms: $terms, classes: $classes, quickAssignments: $quickAssignments}';
  }

  GradebookSector.fromJson(Map<String, dynamic> json)
      : classes = json['c']
            .map((value) => Class.fromJson(value))
            .toList()
            .cast<Class>(),
        terms = json['t']
            .map((value) => Term.fromJson(value))
            .toList()
            .cast<Term>(),
        quickAssignments = json['qA']
            .map((value) => Assignment.fromJson(value))
            .toList()
            .cast<Assignment>();

  Map<String, dynamic> toJson() =>
      {'t': terms, 'c': classes, 'qA': quickAssignments};
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

  Class.fromJson(Map<String, dynamic> json)
      : teacherName = json['tN'],
        timePeriod = json['tP'],
        courseName = json['cN'],
        grades = json['g']
            .map((value) => value.length == 2
                ? FixedGrade.fromJson(value)
                : Grade.fromJson(value))
            .toList()
            .cast<GradebookNode>();

  Map<String, dynamic> toJson() =>
      {'tN': teacherName, 'tP': timePeriod, 'cN': courseName, 'g': grades};
}

/// [GradebookNode] is a root that helps distinguish the difference between grades and teacher information
///
/// There are only two children of [GradebookNode]
/// * [FixedGrade]
/// * [Grade]
abstract class GradebookNode {
  Term term;
  String grade;
  bool containsMoreData;

  GradebookNode(this.term, this.grade, this.containsMoreData);

  GradebookNode.fromJson(Map<String, dynamic> json, this.containsMoreData)
      : term = Term.fromJson(json['t']),
        grade = json['g'];

  Map<String, dynamic> toJson() => {'g': grade, 't': term.toJson()};
}

class FixedGrade extends GradebookNode {
  FixedGrade(String grade, Term term) : super(term, grade, false);

  bool isGradeBehavior() {
    return int.tryParse(grade) == null;
  }

  @override
  String toString() {
    return 'FixedGrade{grade: $grade}';
  }

  FixedGrade.fromJson(Map<String, dynamic> json) : super.fromJson(json, false);
}

/// [Grade] is most likely a clickable numbered grade part of a specific term
class Grade extends GradebookNode {
  String courseNumber;
  String studentID;

  /// Identification for which term [Grade] is in.
  Grade(this.courseNumber, Term term, String grade, this.studentID)
      : super(term, grade, true);

  @override
  String toString() {
    return 'Grade{courseNumber: $courseNumber, grade: $grade, studentID: $studentID}';
  }

  Grade.fromJson(Map<String, dynamic> json)
      : courseNumber = json['cN'],
        studentID = json['sID'],
        super.fromJson(json, true);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'cN': courseNumber,
      'sID': studentID,
    });
}

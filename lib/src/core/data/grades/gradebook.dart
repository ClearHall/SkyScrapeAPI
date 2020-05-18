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
    return (json['gradebookSectors'] ?? json['gS'])
        .map((value) => GradebookSector.fromJson(value))
        .toList()
        .cast<GradebookSector>();
  }

  /// 其实挺简单的！
  /// It loops through the encoded map and finds things such as student ID, course ID, and terms. The three most commonly repeated variables.
  /// By taking those variables out and associating a specific index of a separate designated set for them, we can eliminate many duplicates and save a lot of space.
  /// For example, compressing can turn {sID: 30012} into {sID: 0}, while in another location {0: 30012} is stored. If we have multiple elements with that same sID, it'll save a lot of space by eliminating the need to have 30012 over and over again.
  static List<GradebookSector> _fromCompressed(Map<String, dynamic> json) {
    for (Map sec in json['gS']) {
      for (int i = 0; i < sec['t'].length; i++)
        sec['t'][i] = json['c'][sec['t'][i]];
      for (Map classes in sec['c']) {
        classes['cID'] = json['cID'][classes['cID']];
        for (Map grades in classes['g']) {
          grades['t'] = json['c'][grades['t']];
          if (grades.containsKey('cID')) {
            grades['cID'] = json['cID'][grades['cID']];
            grades['cIDS'] = json['cID'][grades['cIDS']];
            if (grades.containsKey('sID'))
              grades['sID'] = json['s'][grades['sID']];
            else
              grades['sID'] = json['s'][0];
          }
        }
      }

      int tmp;
      for (Map qAssign in sec['qA']) {
        if (qAssign.containsKey('cID')) {
          tmp = qAssign['cID'];
        }
        qAssign['cID'] = json['cID'][tmp];
        if (qAssign.containsKey('sID'))
          qAssign['sID'] = json['s'][qAssign['sID']];
        else
          qAssign['sID'] = json['s'][0];
      }
    }
    json.remove('c');
    json.remove('cID');
    json.remove('s');
    return _getSectorList(json);
  }

  Map<String, dynamic> toJson() => {'gradebookSectors': gradebookSectors};

  Map<String, dynamic> toCompressedJson() {
    // Is there a better way to improve this statement here?
    Map<String, dynamic> json = jsonDecode(jsonEncode(toJson()));
    List<Map> termCache = List<Map>();
    Set<String> studentID = Set();
    Set<String> courseID = Set();

    _simplifyMap(json);

    for (Map sec in json['gS']) {
      for (int i = 0; i < sec['t'].length; i++)
        sec['t'][i] = _checkTermElems(sec['t'][i], termCache);
      for (Map classes in sec['c']) {
        courseID.add(classes['cID']);
        classes['cID'] = courseID.toList().indexOf(classes['cID']);
        for (Map grades in classes['g']) {
          grades['t'] = _checkTermElems(grades['t'], termCache);
          if (grades.containsKey('cID') && grades.containsKey('sID')) {
            _singleSetAdd(courseID, grades, 'cID');
            _singleSetAdd(courseID, grades, 'cIDS');
            _singleSetAdd(studentID, grades, 'sID');
            if (grades['sID'] == 0) grades.remove('sID');
          }
        }
      }

      int tmp;
      for (Map qAssign in sec['qA']) {
        if (qAssign.containsKey('cID') && qAssign.containsKey('sID')) {
          _singleSetAdd(courseID, qAssign, 'cID');
          if (tmp != qAssign['cID']) {
            tmp = qAssign['cID'];
          } else {
            qAssign.remove('cID');
          }
          _singleSetAdd(studentID, qAssign, 'sID');
          if (qAssign['sID'] == 0) qAssign.remove('sID');
        }
      }
    }

    json['s'] = studentID.toList();
    json['cID'] = courseID.toList();
    json['c'] = termCache;
    return json;
  }

  void _simplifyMap(Map<String, dynamic> a) {
    List<String> keys = a.keys.toList();
    for (int i = keys.length - 1; i >= 0; i--) {
      String simplified = simplify(keys[i]);
      a[simplified] = a[keys[i]];
      a.remove(keys[i]);
      _checkValue(a[simplified]);
    }
  }

  void _checkValue(x) {
    if (x is Map)
      _simplifyMap(x);
    else if (x is List)
      for (var v in x) {
        _checkValue(v);
      }
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
  String name;
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
    return 'Gradebook{terms: $terms, classes: $classes, quickAssignments: $quickAssignments, name: $name}';
  }

  GradebookSector.fromJson(Map<String, dynamic> json)
      : classes = (json['c'] ?? json['classes'])
      .map((value) => Class.fromJson(value))
      .toList()
      .cast<Class>(),
        terms = (json['t'] ?? json['terms'])
            .map((value) => Term.fromJson(value))
            .toList()
            .cast<Term>(),
        quickAssignments = (json['qA'] ?? json['quickAssignments'])
            .map((value) => Assignment.fromJson(value))
            .toList()
            .cast<Assignment>(),
        name = json['n'] ?? json['name'];

  Map<String, dynamic> toJson() =>
      {
        'terms': terms,
        'classes': classes,
        'quickAssignments': quickAssignments,
        'name': name
      };
}

class Class {
  String teacherName;
  String timePeriod;
  String courseName;

  String courseID;

  List<GradebookNode> grades;

  Class(this.teacherName, this.courseName, this.timePeriod, this.courseID,
      {this.grades}) {
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
    return 'Class{teacherName: $teacherName, timePeriod: $timePeriod, courseName: $courseName, courseID: $courseID, grades: $grades}';
  }

  Class.fromJson(Map<String, dynamic> json)
      : teacherName = (json['tN'] ?? json['teacherName']),
        timePeriod = (json['tP'] ?? json['timePeriod']),
        courseName = (json['cN'] ?? json['courseName']),
        courseID = (json['cID'] ?? json['courseID']),
        grades = (json['g'] ?? json['grades'])
            .map((value) => value.length == 2
                ? FixedGrade.fromJson(value)
                : Grade.fromJson(value))
            .toList()
            .cast<GradebookNode>();

  Map<String, dynamic> toJson() =>
      {
        'teacherName': teacherName,
        'timePeriod': timePeriod,
        'courseName': courseName,
        'grades': grades,
        'courseID': courseID
      };
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
      : term = Term.fromJson((json['t'] ?? json['term'])),
        grade = (json['g'] ?? json['grade']);

  Map<String, dynamic> toJson() => {'grade': grade, 'term': term.toJson()};
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
  User _user;

  String courseID;
  String studentID;

  String courseIDSecondary;

  void storeUserObject(User u) {
    _user = u;
  }

  /// Identification for which term [Grade] is in.
  Grade(this.courseID, Term term, String grade, this.studentID,
      this.courseIDSecondary)
      : super(term, grade, true);

  @override
  String toString() {
    return 'Grade{courseNumber: $courseID, courseNumberSecondary: $courseIDSecondary, grade: $grade, studentID: $studentID}';
  }

  Grade.fromJson(Map<String, dynamic> json)
      : courseID = (json['cID'] ?? json['courseID']),
        studentID = (json['sID'] ?? json['studentID']),
        courseIDSecondary = (json['cIDS'] ?? json['courseIDSecondary']),
        super.fromJson(json, true);

  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'courseID': courseID,
      'studentID': studentID,
      'courseIDSecondary': courseIDSecondary,
    });

  Future<DetailedGradingPeriod> getAssignments() async {
    DetailedGradingPeriod gradingPeriod = await _user.getAssignmentsFrom(this);
    gradingPeriod.assignments.forEach((key, value) {
      for (Assignment a in value) {
        a.storeUserObject(_user);
      }
    });
    return gradingPeriod;
  }
}

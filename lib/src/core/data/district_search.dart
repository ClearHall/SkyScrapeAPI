part of '../data_types.dart';

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

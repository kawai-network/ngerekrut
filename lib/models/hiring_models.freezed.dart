// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hiring_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobDescription {

 String get roleTitle; String get team; String get aboutRole; List<String> get responsibilities; List<String> get mustHave; List<String> get niceToHave; List<String> get interviewSteps; String get expectedTimeline; List<String> get benefits; String? get compensationRange;
/// Create a copy of JobDescription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobDescriptionCopyWith<JobDescription> get copyWith => _$JobDescriptionCopyWithImpl<JobDescription>(this as JobDescription, _$identity);

  /// Serializes this JobDescription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobDescription&&(identical(other.roleTitle, roleTitle) || other.roleTitle == roleTitle)&&(identical(other.team, team) || other.team == team)&&(identical(other.aboutRole, aboutRole) || other.aboutRole == aboutRole)&&const DeepCollectionEquality().equals(other.responsibilities, responsibilities)&&const DeepCollectionEquality().equals(other.mustHave, mustHave)&&const DeepCollectionEquality().equals(other.niceToHave, niceToHave)&&const DeepCollectionEquality().equals(other.interviewSteps, interviewSteps)&&(identical(other.expectedTimeline, expectedTimeline) || other.expectedTimeline == expectedTimeline)&&const DeepCollectionEquality().equals(other.benefits, benefits)&&(identical(other.compensationRange, compensationRange) || other.compensationRange == compensationRange));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roleTitle,team,aboutRole,const DeepCollectionEquality().hash(responsibilities),const DeepCollectionEquality().hash(mustHave),const DeepCollectionEquality().hash(niceToHave),const DeepCollectionEquality().hash(interviewSteps),expectedTimeline,const DeepCollectionEquality().hash(benefits),compensationRange);

@override
String toString() {
  return 'JobDescription(roleTitle: $roleTitle, team: $team, aboutRole: $aboutRole, responsibilities: $responsibilities, mustHave: $mustHave, niceToHave: $niceToHave, interviewSteps: $interviewSteps, expectedTimeline: $expectedTimeline, benefits: $benefits, compensationRange: $compensationRange)';
}


}

/// @nodoc
abstract mixin class $JobDescriptionCopyWith<$Res>  {
  factory $JobDescriptionCopyWith(JobDescription value, $Res Function(JobDescription) _then) = _$JobDescriptionCopyWithImpl;
@useResult
$Res call({
 String roleTitle, String team, String aboutRole, List<String> responsibilities, List<String> mustHave, List<String> niceToHave, List<String> interviewSteps, String expectedTimeline, List<String> benefits, String? compensationRange
});




}
/// @nodoc
class _$JobDescriptionCopyWithImpl<$Res>
    implements $JobDescriptionCopyWith<$Res> {
  _$JobDescriptionCopyWithImpl(this._self, this._then);

  final JobDescription _self;
  final $Res Function(JobDescription) _then;

/// Create a copy of JobDescription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roleTitle = null,Object? team = null,Object? aboutRole = null,Object? responsibilities = null,Object? mustHave = null,Object? niceToHave = null,Object? interviewSteps = null,Object? expectedTimeline = null,Object? benefits = null,Object? compensationRange = freezed,}) {
  return _then(_self.copyWith(
roleTitle: null == roleTitle ? _self.roleTitle : roleTitle // ignore: cast_nullable_to_non_nullable
as String,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as String,aboutRole: null == aboutRole ? _self.aboutRole : aboutRole // ignore: cast_nullable_to_non_nullable
as String,responsibilities: null == responsibilities ? _self.responsibilities : responsibilities // ignore: cast_nullable_to_non_nullable
as List<String>,mustHave: null == mustHave ? _self.mustHave : mustHave // ignore: cast_nullable_to_non_nullable
as List<String>,niceToHave: null == niceToHave ? _self.niceToHave : niceToHave // ignore: cast_nullable_to_non_nullable
as List<String>,interviewSteps: null == interviewSteps ? _self.interviewSteps : interviewSteps // ignore: cast_nullable_to_non_nullable
as List<String>,expectedTimeline: null == expectedTimeline ? _self.expectedTimeline : expectedTimeline // ignore: cast_nullable_to_non_nullable
as String,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,compensationRange: freezed == compensationRange ? _self.compensationRange : compensationRange // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobDescription].
extension JobDescriptionPatterns on JobDescription {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobDescription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobDescription() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobDescription value)  $default,){
final _that = this;
switch (_that) {
case _JobDescription():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobDescription value)?  $default,){
final _that = this;
switch (_that) {
case _JobDescription() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roleTitle,  String team,  String aboutRole,  List<String> responsibilities,  List<String> mustHave,  List<String> niceToHave,  List<String> interviewSteps,  String expectedTimeline,  List<String> benefits,  String? compensationRange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobDescription() when $default != null:
return $default(_that.roleTitle,_that.team,_that.aboutRole,_that.responsibilities,_that.mustHave,_that.niceToHave,_that.interviewSteps,_that.expectedTimeline,_that.benefits,_that.compensationRange);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roleTitle,  String team,  String aboutRole,  List<String> responsibilities,  List<String> mustHave,  List<String> niceToHave,  List<String> interviewSteps,  String expectedTimeline,  List<String> benefits,  String? compensationRange)  $default,) {final _that = this;
switch (_that) {
case _JobDescription():
return $default(_that.roleTitle,_that.team,_that.aboutRole,_that.responsibilities,_that.mustHave,_that.niceToHave,_that.interviewSteps,_that.expectedTimeline,_that.benefits,_that.compensationRange);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roleTitle,  String team,  String aboutRole,  List<String> responsibilities,  List<String> mustHave,  List<String> niceToHave,  List<String> interviewSteps,  String expectedTimeline,  List<String> benefits,  String? compensationRange)?  $default,) {final _that = this;
switch (_that) {
case _JobDescription() when $default != null:
return $default(_that.roleTitle,_that.team,_that.aboutRole,_that.responsibilities,_that.mustHave,_that.niceToHave,_that.interviewSteps,_that.expectedTimeline,_that.benefits,_that.compensationRange);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobDescription implements JobDescription {
  const _JobDescription({required this.roleTitle, required this.team, required this.aboutRole, required final  List<String> responsibilities, required final  List<String> mustHave, required final  List<String> niceToHave, required final  List<String> interviewSteps, required this.expectedTimeline, required final  List<String> benefits, this.compensationRange}): _responsibilities = responsibilities,_mustHave = mustHave,_niceToHave = niceToHave,_interviewSteps = interviewSteps,_benefits = benefits;
  factory _JobDescription.fromJson(Map<String, dynamic> json) => _$JobDescriptionFromJson(json);

@override final  String roleTitle;
@override final  String team;
@override final  String aboutRole;
 final  List<String> _responsibilities;
@override List<String> get responsibilities {
  if (_responsibilities is EqualUnmodifiableListView) return _responsibilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_responsibilities);
}

 final  List<String> _mustHave;
@override List<String> get mustHave {
  if (_mustHave is EqualUnmodifiableListView) return _mustHave;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mustHave);
}

 final  List<String> _niceToHave;
@override List<String> get niceToHave {
  if (_niceToHave is EqualUnmodifiableListView) return _niceToHave;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_niceToHave);
}

 final  List<String> _interviewSteps;
@override List<String> get interviewSteps {
  if (_interviewSteps is EqualUnmodifiableListView) return _interviewSteps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_interviewSteps);
}

@override final  String expectedTimeline;
 final  List<String> _benefits;
@override List<String> get benefits {
  if (_benefits is EqualUnmodifiableListView) return _benefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_benefits);
}

@override final  String? compensationRange;

/// Create a copy of JobDescription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobDescriptionCopyWith<_JobDescription> get copyWith => __$JobDescriptionCopyWithImpl<_JobDescription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobDescriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobDescription&&(identical(other.roleTitle, roleTitle) || other.roleTitle == roleTitle)&&(identical(other.team, team) || other.team == team)&&(identical(other.aboutRole, aboutRole) || other.aboutRole == aboutRole)&&const DeepCollectionEquality().equals(other._responsibilities, _responsibilities)&&const DeepCollectionEquality().equals(other._mustHave, _mustHave)&&const DeepCollectionEquality().equals(other._niceToHave, _niceToHave)&&const DeepCollectionEquality().equals(other._interviewSteps, _interviewSteps)&&(identical(other.expectedTimeline, expectedTimeline) || other.expectedTimeline == expectedTimeline)&&const DeepCollectionEquality().equals(other._benefits, _benefits)&&(identical(other.compensationRange, compensationRange) || other.compensationRange == compensationRange));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roleTitle,team,aboutRole,const DeepCollectionEquality().hash(_responsibilities),const DeepCollectionEquality().hash(_mustHave),const DeepCollectionEquality().hash(_niceToHave),const DeepCollectionEquality().hash(_interviewSteps),expectedTimeline,const DeepCollectionEquality().hash(_benefits),compensationRange);

@override
String toString() {
  return 'JobDescription(roleTitle: $roleTitle, team: $team, aboutRole: $aboutRole, responsibilities: $responsibilities, mustHave: $mustHave, niceToHave: $niceToHave, interviewSteps: $interviewSteps, expectedTimeline: $expectedTimeline, benefits: $benefits, compensationRange: $compensationRange)';
}


}

/// @nodoc
abstract mixin class _$JobDescriptionCopyWith<$Res> implements $JobDescriptionCopyWith<$Res> {
  factory _$JobDescriptionCopyWith(_JobDescription value, $Res Function(_JobDescription) _then) = __$JobDescriptionCopyWithImpl;
@override @useResult
$Res call({
 String roleTitle, String team, String aboutRole, List<String> responsibilities, List<String> mustHave, List<String> niceToHave, List<String> interviewSteps, String expectedTimeline, List<String> benefits, String? compensationRange
});




}
/// @nodoc
class __$JobDescriptionCopyWithImpl<$Res>
    implements _$JobDescriptionCopyWith<$Res> {
  __$JobDescriptionCopyWithImpl(this._self, this._then);

  final _JobDescription _self;
  final $Res Function(_JobDescription) _then;

/// Create a copy of JobDescription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roleTitle = null,Object? team = null,Object? aboutRole = null,Object? responsibilities = null,Object? mustHave = null,Object? niceToHave = null,Object? interviewSteps = null,Object? expectedTimeline = null,Object? benefits = null,Object? compensationRange = freezed,}) {
  return _then(_JobDescription(
roleTitle: null == roleTitle ? _self.roleTitle : roleTitle // ignore: cast_nullable_to_non_nullable
as String,team: null == team ? _self.team : team // ignore: cast_nullable_to_non_nullable
as String,aboutRole: null == aboutRole ? _self.aboutRole : aboutRole // ignore: cast_nullable_to_non_nullable
as String,responsibilities: null == responsibilities ? _self._responsibilities : responsibilities // ignore: cast_nullable_to_non_nullable
as List<String>,mustHave: null == mustHave ? _self._mustHave : mustHave // ignore: cast_nullable_to_non_nullable
as List<String>,niceToHave: null == niceToHave ? _self._niceToHave : niceToHave // ignore: cast_nullable_to_non_nullable
as List<String>,interviewSteps: null == interviewSteps ? _self._interviewSteps : interviewSteps // ignore: cast_nullable_to_non_nullable
as List<String>,expectedTimeline: null == expectedTimeline ? _self.expectedTimeline : expectedTimeline // ignore: cast_nullable_to_non_nullable
as String,benefits: null == benefits ? _self._benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,compensationRange: freezed == compensationRange ? _self.compensationRange : compensationRange // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ScorecardEntry {

 Competency get competency; int get weight;// Percentage
 int? get score;// 1-5
 String? get evidence; List<String> get strongSignals; List<String> get concerns;
/// Create a copy of ScorecardEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScorecardEntryCopyWith<ScorecardEntry> get copyWith => _$ScorecardEntryCopyWithImpl<ScorecardEntry>(this as ScorecardEntry, _$identity);

  /// Serializes this ScorecardEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScorecardEntry&&(identical(other.competency, competency) || other.competency == competency)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.score, score) || other.score == score)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&const DeepCollectionEquality().equals(other.strongSignals, strongSignals)&&const DeepCollectionEquality().equals(other.concerns, concerns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competency,weight,score,evidence,const DeepCollectionEquality().hash(strongSignals),const DeepCollectionEquality().hash(concerns));

@override
String toString() {
  return 'ScorecardEntry(competency: $competency, weight: $weight, score: $score, evidence: $evidence, strongSignals: $strongSignals, concerns: $concerns)';
}


}

/// @nodoc
abstract mixin class $ScorecardEntryCopyWith<$Res>  {
  factory $ScorecardEntryCopyWith(ScorecardEntry value, $Res Function(ScorecardEntry) _then) = _$ScorecardEntryCopyWithImpl;
@useResult
$Res call({
 Competency competency, int weight, int? score, String? evidence, List<String> strongSignals, List<String> concerns
});




}
/// @nodoc
class _$ScorecardEntryCopyWithImpl<$Res>
    implements $ScorecardEntryCopyWith<$Res> {
  _$ScorecardEntryCopyWithImpl(this._self, this._then);

  final ScorecardEntry _self;
  final $Res Function(ScorecardEntry) _then;

/// Create a copy of ScorecardEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competency = null,Object? weight = null,Object? score = freezed,Object? evidence = freezed,Object? strongSignals = null,Object? concerns = null,}) {
  return _then(_self.copyWith(
competency: null == competency ? _self.competency : competency // ignore: cast_nullable_to_non_nullable
as Competency,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,evidence: freezed == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as String?,strongSignals: null == strongSignals ? _self.strongSignals : strongSignals // ignore: cast_nullable_to_non_nullable
as List<String>,concerns: null == concerns ? _self.concerns : concerns // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScorecardEntry].
extension ScorecardEntryPatterns on ScorecardEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScorecardEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScorecardEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScorecardEntry value)  $default,){
final _that = this;
switch (_that) {
case _ScorecardEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScorecardEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ScorecardEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Competency competency,  int weight,  int? score,  String? evidence,  List<String> strongSignals,  List<String> concerns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScorecardEntry() when $default != null:
return $default(_that.competency,_that.weight,_that.score,_that.evidence,_that.strongSignals,_that.concerns);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Competency competency,  int weight,  int? score,  String? evidence,  List<String> strongSignals,  List<String> concerns)  $default,) {final _that = this;
switch (_that) {
case _ScorecardEntry():
return $default(_that.competency,_that.weight,_that.score,_that.evidence,_that.strongSignals,_that.concerns);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Competency competency,  int weight,  int? score,  String? evidence,  List<String> strongSignals,  List<String> concerns)?  $default,) {final _that = this;
switch (_that) {
case _ScorecardEntry() when $default != null:
return $default(_that.competency,_that.weight,_that.score,_that.evidence,_that.strongSignals,_that.concerns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScorecardEntry implements ScorecardEntry {
  const _ScorecardEntry({required this.competency, required this.weight, this.score, this.evidence, required final  List<String> strongSignals, required final  List<String> concerns}): _strongSignals = strongSignals,_concerns = concerns;
  factory _ScorecardEntry.fromJson(Map<String, dynamic> json) => _$ScorecardEntryFromJson(json);

@override final  Competency competency;
@override final  int weight;
// Percentage
@override final  int? score;
// 1-5
@override final  String? evidence;
 final  List<String> _strongSignals;
@override List<String> get strongSignals {
  if (_strongSignals is EqualUnmodifiableListView) return _strongSignals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_strongSignals);
}

 final  List<String> _concerns;
@override List<String> get concerns {
  if (_concerns is EqualUnmodifiableListView) return _concerns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_concerns);
}


/// Create a copy of ScorecardEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScorecardEntryCopyWith<_ScorecardEntry> get copyWith => __$ScorecardEntryCopyWithImpl<_ScorecardEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScorecardEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScorecardEntry&&(identical(other.competency, competency) || other.competency == competency)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.score, score) || other.score == score)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&const DeepCollectionEquality().equals(other._strongSignals, _strongSignals)&&const DeepCollectionEquality().equals(other._concerns, _concerns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competency,weight,score,evidence,const DeepCollectionEquality().hash(_strongSignals),const DeepCollectionEquality().hash(_concerns));

@override
String toString() {
  return 'ScorecardEntry(competency: $competency, weight: $weight, score: $score, evidence: $evidence, strongSignals: $strongSignals, concerns: $concerns)';
}


}

/// @nodoc
abstract mixin class _$ScorecardEntryCopyWith<$Res> implements $ScorecardEntryCopyWith<$Res> {
  factory _$ScorecardEntryCopyWith(_ScorecardEntry value, $Res Function(_ScorecardEntry) _then) = __$ScorecardEntryCopyWithImpl;
@override @useResult
$Res call({
 Competency competency, int weight, int? score, String? evidence, List<String> strongSignals, List<String> concerns
});




}
/// @nodoc
class __$ScorecardEntryCopyWithImpl<$Res>
    implements _$ScorecardEntryCopyWith<$Res> {
  __$ScorecardEntryCopyWithImpl(this._self, this._then);

  final _ScorecardEntry _self;
  final $Res Function(_ScorecardEntry) _then;

/// Create a copy of ScorecardEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competency = null,Object? weight = null,Object? score = freezed,Object? evidence = freezed,Object? strongSignals = null,Object? concerns = null,}) {
  return _then(_ScorecardEntry(
competency: null == competency ? _self.competency : competency // ignore: cast_nullable_to_non_nullable
as Competency,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int?,evidence: freezed == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as String?,strongSignals: null == strongSignals ? _self._strongSignals : strongSignals // ignore: cast_nullable_to_non_nullable
as List<String>,concerns: null == concerns ? _self._concerns : concerns // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$InterviewScorecard {

 String get candidate; String get role; String get interviewer; DateTime get date; InterviewType get interviewType; List<ScorecardEntry> get competencies; double? get weightedScore; HiringRecommendation? get recommendation; String? get summary; String? get nextSteps;
/// Create a copy of InterviewScorecard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InterviewScorecardCopyWith<InterviewScorecard> get copyWith => _$InterviewScorecardCopyWithImpl<InterviewScorecard>(this as InterviewScorecard, _$identity);

  /// Serializes this InterviewScorecard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InterviewScorecard&&(identical(other.candidate, candidate) || other.candidate == candidate)&&(identical(other.role, role) || other.role == role)&&(identical(other.interviewer, interviewer) || other.interviewer == interviewer)&&(identical(other.date, date) || other.date == date)&&(identical(other.interviewType, interviewType) || other.interviewType == interviewType)&&const DeepCollectionEquality().equals(other.competencies, competencies)&&(identical(other.weightedScore, weightedScore) || other.weightedScore == weightedScore)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.nextSteps, nextSteps) || other.nextSteps == nextSteps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,candidate,role,interviewer,date,interviewType,const DeepCollectionEquality().hash(competencies),weightedScore,recommendation,summary,nextSteps);

@override
String toString() {
  return 'InterviewScorecard(candidate: $candidate, role: $role, interviewer: $interviewer, date: $date, interviewType: $interviewType, competencies: $competencies, weightedScore: $weightedScore, recommendation: $recommendation, summary: $summary, nextSteps: $nextSteps)';
}


}

/// @nodoc
abstract mixin class $InterviewScorecardCopyWith<$Res>  {
  factory $InterviewScorecardCopyWith(InterviewScorecard value, $Res Function(InterviewScorecard) _then) = _$InterviewScorecardCopyWithImpl;
@useResult
$Res call({
 String candidate, String role, String interviewer, DateTime date, InterviewType interviewType, List<ScorecardEntry> competencies, double? weightedScore, HiringRecommendation? recommendation, String? summary, String? nextSteps
});




}
/// @nodoc
class _$InterviewScorecardCopyWithImpl<$Res>
    implements $InterviewScorecardCopyWith<$Res> {
  _$InterviewScorecardCopyWithImpl(this._self, this._then);

  final InterviewScorecard _self;
  final $Res Function(InterviewScorecard) _then;

/// Create a copy of InterviewScorecard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? candidate = null,Object? role = null,Object? interviewer = null,Object? date = null,Object? interviewType = null,Object? competencies = null,Object? weightedScore = freezed,Object? recommendation = freezed,Object? summary = freezed,Object? nextSteps = freezed,}) {
  return _then(_self.copyWith(
candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,interviewer: null == interviewer ? _self.interviewer : interviewer // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,interviewType: null == interviewType ? _self.interviewType : interviewType // ignore: cast_nullable_to_non_nullable
as InterviewType,competencies: null == competencies ? _self.competencies : competencies // ignore: cast_nullable_to_non_nullable
as List<ScorecardEntry>,weightedScore: freezed == weightedScore ? _self.weightedScore : weightedScore // ignore: cast_nullable_to_non_nullable
as double?,recommendation: freezed == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as HiringRecommendation?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,nextSteps: freezed == nextSteps ? _self.nextSteps : nextSteps // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InterviewScorecard].
extension InterviewScorecardPatterns on InterviewScorecard {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InterviewScorecard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InterviewScorecard() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InterviewScorecard value)  $default,){
final _that = this;
switch (_that) {
case _InterviewScorecard():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InterviewScorecard value)?  $default,){
final _that = this;
switch (_that) {
case _InterviewScorecard() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String candidate,  String role,  String interviewer,  DateTime date,  InterviewType interviewType,  List<ScorecardEntry> competencies,  double? weightedScore,  HiringRecommendation? recommendation,  String? summary,  String? nextSteps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InterviewScorecard() when $default != null:
return $default(_that.candidate,_that.role,_that.interviewer,_that.date,_that.interviewType,_that.competencies,_that.weightedScore,_that.recommendation,_that.summary,_that.nextSteps);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String candidate,  String role,  String interviewer,  DateTime date,  InterviewType interviewType,  List<ScorecardEntry> competencies,  double? weightedScore,  HiringRecommendation? recommendation,  String? summary,  String? nextSteps)  $default,) {final _that = this;
switch (_that) {
case _InterviewScorecard():
return $default(_that.candidate,_that.role,_that.interviewer,_that.date,_that.interviewType,_that.competencies,_that.weightedScore,_that.recommendation,_that.summary,_that.nextSteps);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String candidate,  String role,  String interviewer,  DateTime date,  InterviewType interviewType,  List<ScorecardEntry> competencies,  double? weightedScore,  HiringRecommendation? recommendation,  String? summary,  String? nextSteps)?  $default,) {final _that = this;
switch (_that) {
case _InterviewScorecard() when $default != null:
return $default(_that.candidate,_that.role,_that.interviewer,_that.date,_that.interviewType,_that.competencies,_that.weightedScore,_that.recommendation,_that.summary,_that.nextSteps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InterviewScorecard implements InterviewScorecard {
  const _InterviewScorecard({required this.candidate, required this.role, required this.interviewer, required this.date, required this.interviewType, required final  List<ScorecardEntry> competencies, this.weightedScore, this.recommendation, this.summary, this.nextSteps}): _competencies = competencies;
  factory _InterviewScorecard.fromJson(Map<String, dynamic> json) => _$InterviewScorecardFromJson(json);

@override final  String candidate;
@override final  String role;
@override final  String interviewer;
@override final  DateTime date;
@override final  InterviewType interviewType;
 final  List<ScorecardEntry> _competencies;
@override List<ScorecardEntry> get competencies {
  if (_competencies is EqualUnmodifiableListView) return _competencies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_competencies);
}

@override final  double? weightedScore;
@override final  HiringRecommendation? recommendation;
@override final  String? summary;
@override final  String? nextSteps;

/// Create a copy of InterviewScorecard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InterviewScorecardCopyWith<_InterviewScorecard> get copyWith => __$InterviewScorecardCopyWithImpl<_InterviewScorecard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InterviewScorecardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InterviewScorecard&&(identical(other.candidate, candidate) || other.candidate == candidate)&&(identical(other.role, role) || other.role == role)&&(identical(other.interviewer, interviewer) || other.interviewer == interviewer)&&(identical(other.date, date) || other.date == date)&&(identical(other.interviewType, interviewType) || other.interviewType == interviewType)&&const DeepCollectionEquality().equals(other._competencies, _competencies)&&(identical(other.weightedScore, weightedScore) || other.weightedScore == weightedScore)&&(identical(other.recommendation, recommendation) || other.recommendation == recommendation)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.nextSteps, nextSteps) || other.nextSteps == nextSteps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,candidate,role,interviewer,date,interviewType,const DeepCollectionEquality().hash(_competencies),weightedScore,recommendation,summary,nextSteps);

@override
String toString() {
  return 'InterviewScorecard(candidate: $candidate, role: $role, interviewer: $interviewer, date: $date, interviewType: $interviewType, competencies: $competencies, weightedScore: $weightedScore, recommendation: $recommendation, summary: $summary, nextSteps: $nextSteps)';
}


}

/// @nodoc
abstract mixin class _$InterviewScorecardCopyWith<$Res> implements $InterviewScorecardCopyWith<$Res> {
  factory _$InterviewScorecardCopyWith(_InterviewScorecard value, $Res Function(_InterviewScorecard) _then) = __$InterviewScorecardCopyWithImpl;
@override @useResult
$Res call({
 String candidate, String role, String interviewer, DateTime date, InterviewType interviewType, List<ScorecardEntry> competencies, double? weightedScore, HiringRecommendation? recommendation, String? summary, String? nextSteps
});




}
/// @nodoc
class __$InterviewScorecardCopyWithImpl<$Res>
    implements _$InterviewScorecardCopyWith<$Res> {
  __$InterviewScorecardCopyWithImpl(this._self, this._then);

  final _InterviewScorecard _self;
  final $Res Function(_InterviewScorecard) _then;

/// Create a copy of InterviewScorecard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? candidate = null,Object? role = null,Object? interviewer = null,Object? date = null,Object? interviewType = null,Object? competencies = null,Object? weightedScore = freezed,Object? recommendation = freezed,Object? summary = freezed,Object? nextSteps = freezed,}) {
  return _then(_InterviewScorecard(
candidate: null == candidate ? _self.candidate : candidate // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,interviewer: null == interviewer ? _self.interviewer : interviewer // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,interviewType: null == interviewType ? _self.interviewType : interviewType // ignore: cast_nullable_to_non_nullable
as InterviewType,competencies: null == competencies ? _self._competencies : competencies // ignore: cast_nullable_to_non_nullable
as List<ScorecardEntry>,weightedScore: freezed == weightedScore ? _self.weightedScore : weightedScore // ignore: cast_nullable_to_non_nullable
as double?,recommendation: freezed == recommendation ? _self.recommendation : recommendation // ignore: cast_nullable_to_non_nullable
as HiringRecommendation?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,nextSteps: freezed == nextSteps ? _self.nextSteps : nextSteps // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$STARQuestion {

 String get competency; String get question; List<String> get lookFor;
/// Create a copy of STARQuestion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$STARQuestionCopyWith<STARQuestion> get copyWith => _$STARQuestionCopyWithImpl<STARQuestion>(this as STARQuestion, _$identity);

  /// Serializes this STARQuestion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is STARQuestion&&(identical(other.competency, competency) || other.competency == competency)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other.lookFor, lookFor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competency,question,const DeepCollectionEquality().hash(lookFor));

@override
String toString() {
  return 'STARQuestion(competency: $competency, question: $question, lookFor: $lookFor)';
}


}

/// @nodoc
abstract mixin class $STARQuestionCopyWith<$Res>  {
  factory $STARQuestionCopyWith(STARQuestion value, $Res Function(STARQuestion) _then) = _$STARQuestionCopyWithImpl;
@useResult
$Res call({
 String competency, String question, List<String> lookFor
});




}
/// @nodoc
class _$STARQuestionCopyWithImpl<$Res>
    implements $STARQuestionCopyWith<$Res> {
  _$STARQuestionCopyWithImpl(this._self, this._then);

  final STARQuestion _self;
  final $Res Function(STARQuestion) _then;

/// Create a copy of STARQuestion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? competency = null,Object? question = null,Object? lookFor = null,}) {
  return _then(_self.copyWith(
competency: null == competency ? _self.competency : competency // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,lookFor: null == lookFor ? _self.lookFor : lookFor // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [STARQuestion].
extension STARQuestionPatterns on STARQuestion {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _STARQuestion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _STARQuestion() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _STARQuestion value)  $default,){
final _that = this;
switch (_that) {
case _STARQuestion():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _STARQuestion value)?  $default,){
final _that = this;
switch (_that) {
case _STARQuestion() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String competency,  String question,  List<String> lookFor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _STARQuestion() when $default != null:
return $default(_that.competency,_that.question,_that.lookFor);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String competency,  String question,  List<String> lookFor)  $default,) {final _that = this;
switch (_that) {
case _STARQuestion():
return $default(_that.competency,_that.question,_that.lookFor);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String competency,  String question,  List<String> lookFor)?  $default,) {final _that = this;
switch (_that) {
case _STARQuestion() when $default != null:
return $default(_that.competency,_that.question,_that.lookFor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _STARQuestion implements STARQuestion {
  const _STARQuestion({required this.competency, required this.question, required final  List<String> lookFor}): _lookFor = lookFor;
  factory _STARQuestion.fromJson(Map<String, dynamic> json) => _$STARQuestionFromJson(json);

@override final  String competency;
@override final  String question;
 final  List<String> _lookFor;
@override List<String> get lookFor {
  if (_lookFor is EqualUnmodifiableListView) return _lookFor;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lookFor);
}


/// Create a copy of STARQuestion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$STARQuestionCopyWith<_STARQuestion> get copyWith => __$STARQuestionCopyWithImpl<_STARQuestion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$STARQuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _STARQuestion&&(identical(other.competency, competency) || other.competency == competency)&&(identical(other.question, question) || other.question == question)&&const DeepCollectionEquality().equals(other._lookFor, _lookFor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,competency,question,const DeepCollectionEquality().hash(_lookFor));

@override
String toString() {
  return 'STARQuestion(competency: $competency, question: $question, lookFor: $lookFor)';
}


}

/// @nodoc
abstract mixin class _$STARQuestionCopyWith<$Res> implements $STARQuestionCopyWith<$Res> {
  factory _$STARQuestionCopyWith(_STARQuestion value, $Res Function(_STARQuestion) _then) = __$STARQuestionCopyWithImpl;
@override @useResult
$Res call({
 String competency, String question, List<String> lookFor
});




}
/// @nodoc
class __$STARQuestionCopyWithImpl<$Res>
    implements _$STARQuestionCopyWith<$Res> {
  __$STARQuestionCopyWithImpl(this._self, this._then);

  final _STARQuestion _self;
  final $Res Function(_STARQuestion) _then;

/// Create a copy of STARQuestion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? competency = null,Object? question = null,Object? lookFor = null,}) {
  return _then(_STARQuestion(
competency: null == competency ? _self.competency : competency // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,lookFor: null == lookFor ? _self._lookFor : lookFor // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$STARInterviewGuide {

 String get role; List<STARQuestion> get questions; String get scoringGuide;
/// Create a copy of STARInterviewGuide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$STARInterviewGuideCopyWith<STARInterviewGuide> get copyWith => _$STARInterviewGuideCopyWithImpl<STARInterviewGuide>(this as STARInterviewGuide, _$identity);

  /// Serializes this STARInterviewGuide to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is STARInterviewGuide&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other.questions, questions)&&(identical(other.scoringGuide, scoringGuide) || other.scoringGuide == scoringGuide));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(questions),scoringGuide);

@override
String toString() {
  return 'STARInterviewGuide(role: $role, questions: $questions, scoringGuide: $scoringGuide)';
}


}

/// @nodoc
abstract mixin class $STARInterviewGuideCopyWith<$Res>  {
  factory $STARInterviewGuideCopyWith(STARInterviewGuide value, $Res Function(STARInterviewGuide) _then) = _$STARInterviewGuideCopyWithImpl;
@useResult
$Res call({
 String role, List<STARQuestion> questions, String scoringGuide
});




}
/// @nodoc
class _$STARInterviewGuideCopyWithImpl<$Res>
    implements $STARInterviewGuideCopyWith<$Res> {
  _$STARInterviewGuideCopyWithImpl(this._self, this._then);

  final STARInterviewGuide _self;
  final $Res Function(STARInterviewGuide) _then;

/// Create a copy of STARInterviewGuide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? questions = null,Object? scoringGuide = null,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self.questions : questions // ignore: cast_nullable_to_non_nullable
as List<STARQuestion>,scoringGuide: null == scoringGuide ? _self.scoringGuide : scoringGuide // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [STARInterviewGuide].
extension STARInterviewGuidePatterns on STARInterviewGuide {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _STARInterviewGuide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _STARInterviewGuide() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _STARInterviewGuide value)  $default,){
final _that = this;
switch (_that) {
case _STARInterviewGuide():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _STARInterviewGuide value)?  $default,){
final _that = this;
switch (_that) {
case _STARInterviewGuide() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role,  List<STARQuestion> questions,  String scoringGuide)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _STARInterviewGuide() when $default != null:
return $default(_that.role,_that.questions,_that.scoringGuide);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role,  List<STARQuestion> questions,  String scoringGuide)  $default,) {final _that = this;
switch (_that) {
case _STARInterviewGuide():
return $default(_that.role,_that.questions,_that.scoringGuide);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role,  List<STARQuestion> questions,  String scoringGuide)?  $default,) {final _that = this;
switch (_that) {
case _STARInterviewGuide() when $default != null:
return $default(_that.role,_that.questions,_that.scoringGuide);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _STARInterviewGuide implements STARInterviewGuide {
  const _STARInterviewGuide({required this.role, required final  List<STARQuestion> questions, required this.scoringGuide}): _questions = questions;
  factory _STARInterviewGuide.fromJson(Map<String, dynamic> json) => _$STARInterviewGuideFromJson(json);

@override final  String role;
 final  List<STARQuestion> _questions;
@override List<STARQuestion> get questions {
  if (_questions is EqualUnmodifiableListView) return _questions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_questions);
}

@override final  String scoringGuide;

/// Create a copy of STARInterviewGuide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$STARInterviewGuideCopyWith<_STARInterviewGuide> get copyWith => __$STARInterviewGuideCopyWithImpl<_STARInterviewGuide>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$STARInterviewGuideToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _STARInterviewGuide&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._questions, _questions)&&(identical(other.scoringGuide, scoringGuide) || other.scoringGuide == scoringGuide));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(_questions),scoringGuide);

@override
String toString() {
  return 'STARInterviewGuide(role: $role, questions: $questions, scoringGuide: $scoringGuide)';
}


}

/// @nodoc
abstract mixin class _$STARInterviewGuideCopyWith<$Res> implements $STARInterviewGuideCopyWith<$Res> {
  factory _$STARInterviewGuideCopyWith(_STARInterviewGuide value, $Res Function(_STARInterviewGuide) _then) = __$STARInterviewGuideCopyWithImpl;
@override @useResult
$Res call({
 String role, List<STARQuestion> questions, String scoringGuide
});




}
/// @nodoc
class __$STARInterviewGuideCopyWithImpl<$Res>
    implements _$STARInterviewGuideCopyWith<$Res> {
  __$STARInterviewGuideCopyWithImpl(this._self, this._then);

  final _STARInterviewGuide _self;
  final $Res Function(_STARInterviewGuide) _then;

/// Create a copy of STARInterviewGuide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? questions = null,Object? scoringGuide = null,}) {
  return _then(_STARInterviewGuide(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,questions: null == questions ? _self._questions : questions // ignore: cast_nullable_to_non_nullable
as List<STARQuestion>,scoringGuide: null == scoringGuide ? _self.scoringGuide : scoringGuide // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$HiringMetrics {

 Map<String, double> get funnelMetrics; Map<String, String> get timeMetrics; Map<String, double> get qualityMetrics; Map<String, String> get targets; List<String> get redFlags;
/// Create a copy of HiringMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HiringMetricsCopyWith<HiringMetrics> get copyWith => _$HiringMetricsCopyWithImpl<HiringMetrics>(this as HiringMetrics, _$identity);

  /// Serializes this HiringMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HiringMetrics&&const DeepCollectionEquality().equals(other.funnelMetrics, funnelMetrics)&&const DeepCollectionEquality().equals(other.timeMetrics, timeMetrics)&&const DeepCollectionEquality().equals(other.qualityMetrics, qualityMetrics)&&const DeepCollectionEquality().equals(other.targets, targets)&&const DeepCollectionEquality().equals(other.redFlags, redFlags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(funnelMetrics),const DeepCollectionEquality().hash(timeMetrics),const DeepCollectionEquality().hash(qualityMetrics),const DeepCollectionEquality().hash(targets),const DeepCollectionEquality().hash(redFlags));

@override
String toString() {
  return 'HiringMetrics(funnelMetrics: $funnelMetrics, timeMetrics: $timeMetrics, qualityMetrics: $qualityMetrics, targets: $targets, redFlags: $redFlags)';
}


}

/// @nodoc
abstract mixin class $HiringMetricsCopyWith<$Res>  {
  factory $HiringMetricsCopyWith(HiringMetrics value, $Res Function(HiringMetrics) _then) = _$HiringMetricsCopyWithImpl;
@useResult
$Res call({
 Map<String, double> funnelMetrics, Map<String, String> timeMetrics, Map<String, double> qualityMetrics, Map<String, String> targets, List<String> redFlags
});




}
/// @nodoc
class _$HiringMetricsCopyWithImpl<$Res>
    implements $HiringMetricsCopyWith<$Res> {
  _$HiringMetricsCopyWithImpl(this._self, this._then);

  final HiringMetrics _self;
  final $Res Function(HiringMetrics) _then;

/// Create a copy of HiringMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? funnelMetrics = null,Object? timeMetrics = null,Object? qualityMetrics = null,Object? targets = null,Object? redFlags = null,}) {
  return _then(_self.copyWith(
funnelMetrics: null == funnelMetrics ? _self.funnelMetrics : funnelMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,timeMetrics: null == timeMetrics ? _self.timeMetrics : timeMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, String>,qualityMetrics: null == qualityMetrics ? _self.qualityMetrics : qualityMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as Map<String, String>,redFlags: null == redFlags ? _self.redFlags : redFlags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [HiringMetrics].
extension HiringMetricsPatterns on HiringMetrics {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HiringMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HiringMetrics() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HiringMetrics value)  $default,){
final _that = this;
switch (_that) {
case _HiringMetrics():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HiringMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _HiringMetrics() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, double> funnelMetrics,  Map<String, String> timeMetrics,  Map<String, double> qualityMetrics,  Map<String, String> targets,  List<String> redFlags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HiringMetrics() when $default != null:
return $default(_that.funnelMetrics,_that.timeMetrics,_that.qualityMetrics,_that.targets,_that.redFlags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, double> funnelMetrics,  Map<String, String> timeMetrics,  Map<String, double> qualityMetrics,  Map<String, String> targets,  List<String> redFlags)  $default,) {final _that = this;
switch (_that) {
case _HiringMetrics():
return $default(_that.funnelMetrics,_that.timeMetrics,_that.qualityMetrics,_that.targets,_that.redFlags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, double> funnelMetrics,  Map<String, String> timeMetrics,  Map<String, double> qualityMetrics,  Map<String, String> targets,  List<String> redFlags)?  $default,) {final _that = this;
switch (_that) {
case _HiringMetrics() when $default != null:
return $default(_that.funnelMetrics,_that.timeMetrics,_that.qualityMetrics,_that.targets,_that.redFlags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HiringMetrics implements HiringMetrics {
  const _HiringMetrics({required final  Map<String, double> funnelMetrics, required final  Map<String, String> timeMetrics, required final  Map<String, double> qualityMetrics, required final  Map<String, String> targets, required final  List<String> redFlags}): _funnelMetrics = funnelMetrics,_timeMetrics = timeMetrics,_qualityMetrics = qualityMetrics,_targets = targets,_redFlags = redFlags;
  factory _HiringMetrics.fromJson(Map<String, dynamic> json) => _$HiringMetricsFromJson(json);

 final  Map<String, double> _funnelMetrics;
@override Map<String, double> get funnelMetrics {
  if (_funnelMetrics is EqualUnmodifiableMapView) return _funnelMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_funnelMetrics);
}

 final  Map<String, String> _timeMetrics;
@override Map<String, String> get timeMetrics {
  if (_timeMetrics is EqualUnmodifiableMapView) return _timeMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_timeMetrics);
}

 final  Map<String, double> _qualityMetrics;
@override Map<String, double> get qualityMetrics {
  if (_qualityMetrics is EqualUnmodifiableMapView) return _qualityMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_qualityMetrics);
}

 final  Map<String, String> _targets;
@override Map<String, String> get targets {
  if (_targets is EqualUnmodifiableMapView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_targets);
}

 final  List<String> _redFlags;
@override List<String> get redFlags {
  if (_redFlags is EqualUnmodifiableListView) return _redFlags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redFlags);
}


/// Create a copy of HiringMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HiringMetricsCopyWith<_HiringMetrics> get copyWith => __$HiringMetricsCopyWithImpl<_HiringMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HiringMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HiringMetrics&&const DeepCollectionEquality().equals(other._funnelMetrics, _funnelMetrics)&&const DeepCollectionEquality().equals(other._timeMetrics, _timeMetrics)&&const DeepCollectionEquality().equals(other._qualityMetrics, _qualityMetrics)&&const DeepCollectionEquality().equals(other._targets, _targets)&&const DeepCollectionEquality().equals(other._redFlags, _redFlags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_funnelMetrics),const DeepCollectionEquality().hash(_timeMetrics),const DeepCollectionEquality().hash(_qualityMetrics),const DeepCollectionEquality().hash(_targets),const DeepCollectionEquality().hash(_redFlags));

@override
String toString() {
  return 'HiringMetrics(funnelMetrics: $funnelMetrics, timeMetrics: $timeMetrics, qualityMetrics: $qualityMetrics, targets: $targets, redFlags: $redFlags)';
}


}

/// @nodoc
abstract mixin class _$HiringMetricsCopyWith<$Res> implements $HiringMetricsCopyWith<$Res> {
  factory _$HiringMetricsCopyWith(_HiringMetrics value, $Res Function(_HiringMetrics) _then) = __$HiringMetricsCopyWithImpl;
@override @useResult
$Res call({
 Map<String, double> funnelMetrics, Map<String, String> timeMetrics, Map<String, double> qualityMetrics, Map<String, String> targets, List<String> redFlags
});




}
/// @nodoc
class __$HiringMetricsCopyWithImpl<$Res>
    implements _$HiringMetricsCopyWith<$Res> {
  __$HiringMetricsCopyWithImpl(this._self, this._then);

  final _HiringMetrics _self;
  final $Res Function(_HiringMetrics) _then;

/// Create a copy of HiringMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? funnelMetrics = null,Object? timeMetrics = null,Object? qualityMetrics = null,Object? targets = null,Object? redFlags = null,}) {
  return _then(_HiringMetrics(
funnelMetrics: null == funnelMetrics ? _self._funnelMetrics : funnelMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,timeMetrics: null == timeMetrics ? _self._timeMetrics : timeMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, String>,qualityMetrics: null == qualityMetrics ? _self._qualityMetrics : qualityMetrics // ignore: cast_nullable_to_non_nullable
as Map<String, double>,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as Map<String, String>,redFlags: null == redFlags ? _self._redFlags : redFlags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$HiringPipeline {

 String get role; RoleLevel get roleLevel; Urgency get urgency; DateTime get postedDate; int? get applicantsCount; int? get screenedCount; int? get interviewCount; int? get offerCount; int? get hiredCount; HiringMetrics? get metrics;
/// Create a copy of HiringPipeline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HiringPipelineCopyWith<HiringPipeline> get copyWith => _$HiringPipelineCopyWithImpl<HiringPipeline>(this as HiringPipeline, _$identity);

  /// Serializes this HiringPipeline to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HiringPipeline&&(identical(other.role, role) || other.role == role)&&(identical(other.roleLevel, roleLevel) || other.roleLevel == roleLevel)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.postedDate, postedDate) || other.postedDate == postedDate)&&(identical(other.applicantsCount, applicantsCount) || other.applicantsCount == applicantsCount)&&(identical(other.screenedCount, screenedCount) || other.screenedCount == screenedCount)&&(identical(other.interviewCount, interviewCount) || other.interviewCount == interviewCount)&&(identical(other.offerCount, offerCount) || other.offerCount == offerCount)&&(identical(other.hiredCount, hiredCount) || other.hiredCount == hiredCount)&&(identical(other.metrics, metrics) || other.metrics == metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,roleLevel,urgency,postedDate,applicantsCount,screenedCount,interviewCount,offerCount,hiredCount,metrics);

@override
String toString() {
  return 'HiringPipeline(role: $role, roleLevel: $roleLevel, urgency: $urgency, postedDate: $postedDate, applicantsCount: $applicantsCount, screenedCount: $screenedCount, interviewCount: $interviewCount, offerCount: $offerCount, hiredCount: $hiredCount, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class $HiringPipelineCopyWith<$Res>  {
  factory $HiringPipelineCopyWith(HiringPipeline value, $Res Function(HiringPipeline) _then) = _$HiringPipelineCopyWithImpl;
@useResult
$Res call({
 String role, RoleLevel roleLevel, Urgency urgency, DateTime postedDate, int? applicantsCount, int? screenedCount, int? interviewCount, int? offerCount, int? hiredCount, HiringMetrics? metrics
});


$HiringMetricsCopyWith<$Res>? get metrics;

}
/// @nodoc
class _$HiringPipelineCopyWithImpl<$Res>
    implements $HiringPipelineCopyWith<$Res> {
  _$HiringPipelineCopyWithImpl(this._self, this._then);

  final HiringPipeline _self;
  final $Res Function(HiringPipeline) _then;

/// Create a copy of HiringPipeline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? roleLevel = null,Object? urgency = null,Object? postedDate = null,Object? applicantsCount = freezed,Object? screenedCount = freezed,Object? interviewCount = freezed,Object? offerCount = freezed,Object? hiredCount = freezed,Object? metrics = freezed,}) {
  return _then(_self.copyWith(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,roleLevel: null == roleLevel ? _self.roleLevel : roleLevel // ignore: cast_nullable_to_non_nullable
as RoleLevel,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as Urgency,postedDate: null == postedDate ? _self.postedDate : postedDate // ignore: cast_nullable_to_non_nullable
as DateTime,applicantsCount: freezed == applicantsCount ? _self.applicantsCount : applicantsCount // ignore: cast_nullable_to_non_nullable
as int?,screenedCount: freezed == screenedCount ? _self.screenedCount : screenedCount // ignore: cast_nullable_to_non_nullable
as int?,interviewCount: freezed == interviewCount ? _self.interviewCount : interviewCount // ignore: cast_nullable_to_non_nullable
as int?,offerCount: freezed == offerCount ? _self.offerCount : offerCount // ignore: cast_nullable_to_non_nullable
as int?,hiredCount: freezed == hiredCount ? _self.hiredCount : hiredCount // ignore: cast_nullable_to_non_nullable
as int?,metrics: freezed == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as HiringMetrics?,
  ));
}
/// Create a copy of HiringPipeline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HiringMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
    return null;
  }

  return $HiringMetricsCopyWith<$Res>(_self.metrics!, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}
}


/// Adds pattern-matching-related methods to [HiringPipeline].
extension HiringPipelinePatterns on HiringPipeline {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HiringPipeline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HiringPipeline() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HiringPipeline value)  $default,){
final _that = this;
switch (_that) {
case _HiringPipeline():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HiringPipeline value)?  $default,){
final _that = this;
switch (_that) {
case _HiringPipeline() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String role,  RoleLevel roleLevel,  Urgency urgency,  DateTime postedDate,  int? applicantsCount,  int? screenedCount,  int? interviewCount,  int? offerCount,  int? hiredCount,  HiringMetrics? metrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HiringPipeline() when $default != null:
return $default(_that.role,_that.roleLevel,_that.urgency,_that.postedDate,_that.applicantsCount,_that.screenedCount,_that.interviewCount,_that.offerCount,_that.hiredCount,_that.metrics);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String role,  RoleLevel roleLevel,  Urgency urgency,  DateTime postedDate,  int? applicantsCount,  int? screenedCount,  int? interviewCount,  int? offerCount,  int? hiredCount,  HiringMetrics? metrics)  $default,) {final _that = this;
switch (_that) {
case _HiringPipeline():
return $default(_that.role,_that.roleLevel,_that.urgency,_that.postedDate,_that.applicantsCount,_that.screenedCount,_that.interviewCount,_that.offerCount,_that.hiredCount,_that.metrics);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String role,  RoleLevel roleLevel,  Urgency urgency,  DateTime postedDate,  int? applicantsCount,  int? screenedCount,  int? interviewCount,  int? offerCount,  int? hiredCount,  HiringMetrics? metrics)?  $default,) {final _that = this;
switch (_that) {
case _HiringPipeline() when $default != null:
return $default(_that.role,_that.roleLevel,_that.urgency,_that.postedDate,_that.applicantsCount,_that.screenedCount,_that.interviewCount,_that.offerCount,_that.hiredCount,_that.metrics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HiringPipeline implements HiringPipeline {
  const _HiringPipeline({required this.role, required this.roleLevel, required this.urgency, required this.postedDate, this.applicantsCount, this.screenedCount, this.interviewCount, this.offerCount, this.hiredCount, this.metrics});
  factory _HiringPipeline.fromJson(Map<String, dynamic> json) => _$HiringPipelineFromJson(json);

@override final  String role;
@override final  RoleLevel roleLevel;
@override final  Urgency urgency;
@override final  DateTime postedDate;
@override final  int? applicantsCount;
@override final  int? screenedCount;
@override final  int? interviewCount;
@override final  int? offerCount;
@override final  int? hiredCount;
@override final  HiringMetrics? metrics;

/// Create a copy of HiringPipeline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HiringPipelineCopyWith<_HiringPipeline> get copyWith => __$HiringPipelineCopyWithImpl<_HiringPipeline>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HiringPipelineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HiringPipeline&&(identical(other.role, role) || other.role == role)&&(identical(other.roleLevel, roleLevel) || other.roleLevel == roleLevel)&&(identical(other.urgency, urgency) || other.urgency == urgency)&&(identical(other.postedDate, postedDate) || other.postedDate == postedDate)&&(identical(other.applicantsCount, applicantsCount) || other.applicantsCount == applicantsCount)&&(identical(other.screenedCount, screenedCount) || other.screenedCount == screenedCount)&&(identical(other.interviewCount, interviewCount) || other.interviewCount == interviewCount)&&(identical(other.offerCount, offerCount) || other.offerCount == offerCount)&&(identical(other.hiredCount, hiredCount) || other.hiredCount == hiredCount)&&(identical(other.metrics, metrics) || other.metrics == metrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,role,roleLevel,urgency,postedDate,applicantsCount,screenedCount,interviewCount,offerCount,hiredCount,metrics);

@override
String toString() {
  return 'HiringPipeline(role: $role, roleLevel: $roleLevel, urgency: $urgency, postedDate: $postedDate, applicantsCount: $applicantsCount, screenedCount: $screenedCount, interviewCount: $interviewCount, offerCount: $offerCount, hiredCount: $hiredCount, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class _$HiringPipelineCopyWith<$Res> implements $HiringPipelineCopyWith<$Res> {
  factory _$HiringPipelineCopyWith(_HiringPipeline value, $Res Function(_HiringPipeline) _then) = __$HiringPipelineCopyWithImpl;
@override @useResult
$Res call({
 String role, RoleLevel roleLevel, Urgency urgency, DateTime postedDate, int? applicantsCount, int? screenedCount, int? interviewCount, int? offerCount, int? hiredCount, HiringMetrics? metrics
});


@override $HiringMetricsCopyWith<$Res>? get metrics;

}
/// @nodoc
class __$HiringPipelineCopyWithImpl<$Res>
    implements _$HiringPipelineCopyWith<$Res> {
  __$HiringPipelineCopyWithImpl(this._self, this._then);

  final _HiringPipeline _self;
  final $Res Function(_HiringPipeline) _then;

/// Create a copy of HiringPipeline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? roleLevel = null,Object? urgency = null,Object? postedDate = null,Object? applicantsCount = freezed,Object? screenedCount = freezed,Object? interviewCount = freezed,Object? offerCount = freezed,Object? hiredCount = freezed,Object? metrics = freezed,}) {
  return _then(_HiringPipeline(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,roleLevel: null == roleLevel ? _self.roleLevel : roleLevel // ignore: cast_nullable_to_non_nullable
as RoleLevel,urgency: null == urgency ? _self.urgency : urgency // ignore: cast_nullable_to_non_nullable
as Urgency,postedDate: null == postedDate ? _self.postedDate : postedDate // ignore: cast_nullable_to_non_nullable
as DateTime,applicantsCount: freezed == applicantsCount ? _self.applicantsCount : applicantsCount // ignore: cast_nullable_to_non_nullable
as int?,screenedCount: freezed == screenedCount ? _self.screenedCount : screenedCount // ignore: cast_nullable_to_non_nullable
as int?,interviewCount: freezed == interviewCount ? _self.interviewCount : interviewCount // ignore: cast_nullable_to_non_nullable
as int?,offerCount: freezed == offerCount ? _self.offerCount : offerCount // ignore: cast_nullable_to_non_nullable
as int?,hiredCount: freezed == hiredCount ? _self.hiredCount : hiredCount // ignore: cast_nullable_to_non_nullable
as int?,metrics: freezed == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as HiringMetrics?,
  ));
}

/// Create a copy of HiringPipeline
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HiringMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
    return null;
  }

  return $HiringMetricsCopyWith<$Res>(_self.metrics!, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}
}


/// @nodoc
mixin _$HiringSkillRequest {

 String get skill;// 'job_description', 'scorecard', 'star_questions', 'metrics'
 Map<String, dynamic> get parameters;
/// Create a copy of HiringSkillRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HiringSkillRequestCopyWith<HiringSkillRequest> get copyWith => _$HiringSkillRequestCopyWithImpl<HiringSkillRequest>(this as HiringSkillRequest, _$identity);

  /// Serializes this HiringSkillRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HiringSkillRequest&&(identical(other.skill, skill) || other.skill == skill)&&const DeepCollectionEquality().equals(other.parameters, parameters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skill,const DeepCollectionEquality().hash(parameters));

@override
String toString() {
  return 'HiringSkillRequest(skill: $skill, parameters: $parameters)';
}


}

/// @nodoc
abstract mixin class $HiringSkillRequestCopyWith<$Res>  {
  factory $HiringSkillRequestCopyWith(HiringSkillRequest value, $Res Function(HiringSkillRequest) _then) = _$HiringSkillRequestCopyWithImpl;
@useResult
$Res call({
 String skill, Map<String, dynamic> parameters
});




}
/// @nodoc
class _$HiringSkillRequestCopyWithImpl<$Res>
    implements $HiringSkillRequestCopyWith<$Res> {
  _$HiringSkillRequestCopyWithImpl(this._self, this._then);

  final HiringSkillRequest _self;
  final $Res Function(HiringSkillRequest) _then;

/// Create a copy of HiringSkillRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skill = null,Object? parameters = null,}) {
  return _then(_self.copyWith(
skill: null == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as String,parameters: null == parameters ? _self.parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [HiringSkillRequest].
extension HiringSkillRequestPatterns on HiringSkillRequest {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HiringSkillRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HiringSkillRequest() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HiringSkillRequest value)  $default,){
final _that = this;
switch (_that) {
case _HiringSkillRequest():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HiringSkillRequest value)?  $default,){
final _that = this;
switch (_that) {
case _HiringSkillRequest() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String skill,  Map<String, dynamic> parameters)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HiringSkillRequest() when $default != null:
return $default(_that.skill,_that.parameters);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String skill,  Map<String, dynamic> parameters)  $default,) {final _that = this;
switch (_that) {
case _HiringSkillRequest():
return $default(_that.skill,_that.parameters);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String skill,  Map<String, dynamic> parameters)?  $default,) {final _that = this;
switch (_that) {
case _HiringSkillRequest() when $default != null:
return $default(_that.skill,_that.parameters);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HiringSkillRequest implements HiringSkillRequest {
  const _HiringSkillRequest({required this.skill, required final  Map<String, dynamic> parameters}): _parameters = parameters;
  factory _HiringSkillRequest.fromJson(Map<String, dynamic> json) => _$HiringSkillRequestFromJson(json);

@override final  String skill;
// 'job_description', 'scorecard', 'star_questions', 'metrics'
 final  Map<String, dynamic> _parameters;
// 'job_description', 'scorecard', 'star_questions', 'metrics'
@override Map<String, dynamic> get parameters {
  if (_parameters is EqualUnmodifiableMapView) return _parameters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_parameters);
}


/// Create a copy of HiringSkillRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HiringSkillRequestCopyWith<_HiringSkillRequest> get copyWith => __$HiringSkillRequestCopyWithImpl<_HiringSkillRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HiringSkillRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HiringSkillRequest&&(identical(other.skill, skill) || other.skill == skill)&&const DeepCollectionEquality().equals(other._parameters, _parameters));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skill,const DeepCollectionEquality().hash(_parameters));

@override
String toString() {
  return 'HiringSkillRequest(skill: $skill, parameters: $parameters)';
}


}

/// @nodoc
abstract mixin class _$HiringSkillRequestCopyWith<$Res> implements $HiringSkillRequestCopyWith<$Res> {
  factory _$HiringSkillRequestCopyWith(_HiringSkillRequest value, $Res Function(_HiringSkillRequest) _then) = __$HiringSkillRequestCopyWithImpl;
@override @useResult
$Res call({
 String skill, Map<String, dynamic> parameters
});




}
/// @nodoc
class __$HiringSkillRequestCopyWithImpl<$Res>
    implements _$HiringSkillRequestCopyWith<$Res> {
  __$HiringSkillRequestCopyWithImpl(this._self, this._then);

  final _HiringSkillRequest _self;
  final $Res Function(_HiringSkillRequest) _then;

/// Create a copy of HiringSkillRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skill = null,Object? parameters = null,}) {
  return _then(_HiringSkillRequest(
skill: null == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as String,parameters: null == parameters ? _self._parameters : parameters // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}


/// @nodoc
mixin _$HiringSkillResponse {

 String get skill; Map<String, dynamic> get data; String? get textResponse;
/// Create a copy of HiringSkillResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HiringSkillResponseCopyWith<HiringSkillResponse> get copyWith => _$HiringSkillResponseCopyWithImpl<HiringSkillResponse>(this as HiringSkillResponse, _$identity);

  /// Serializes this HiringSkillResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HiringSkillResponse&&(identical(other.skill, skill) || other.skill == skill)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.textResponse, textResponse) || other.textResponse == textResponse));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skill,const DeepCollectionEquality().hash(data),textResponse);

@override
String toString() {
  return 'HiringSkillResponse(skill: $skill, data: $data, textResponse: $textResponse)';
}


}

/// @nodoc
abstract mixin class $HiringSkillResponseCopyWith<$Res>  {
  factory $HiringSkillResponseCopyWith(HiringSkillResponse value, $Res Function(HiringSkillResponse) _then) = _$HiringSkillResponseCopyWithImpl;
@useResult
$Res call({
 String skill, Map<String, dynamic> data, String? textResponse
});




}
/// @nodoc
class _$HiringSkillResponseCopyWithImpl<$Res>
    implements $HiringSkillResponseCopyWith<$Res> {
  _$HiringSkillResponseCopyWithImpl(this._self, this._then);

  final HiringSkillResponse _self;
  final $Res Function(HiringSkillResponse) _then;

/// Create a copy of HiringSkillResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? skill = null,Object? data = null,Object? textResponse = freezed,}) {
  return _then(_self.copyWith(
skill: null == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,textResponse: freezed == textResponse ? _self.textResponse : textResponse // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HiringSkillResponse].
extension HiringSkillResponsePatterns on HiringSkillResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HiringSkillResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HiringSkillResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HiringSkillResponse value)  $default,){
final _that = this;
switch (_that) {
case _HiringSkillResponse():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HiringSkillResponse value)?  $default,){
final _that = this;
switch (_that) {
case _HiringSkillResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String skill,  Map<String, dynamic> data,  String? textResponse)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HiringSkillResponse() when $default != null:
return $default(_that.skill,_that.data,_that.textResponse);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String skill,  Map<String, dynamic> data,  String? textResponse)  $default,) {final _that = this;
switch (_that) {
case _HiringSkillResponse():
return $default(_that.skill,_that.data,_that.textResponse);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String skill,  Map<String, dynamic> data,  String? textResponse)?  $default,) {final _that = this;
switch (_that) {
case _HiringSkillResponse() when $default != null:
return $default(_that.skill,_that.data,_that.textResponse);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HiringSkillResponse implements HiringSkillResponse {
  const _HiringSkillResponse({required this.skill, required final  Map<String, dynamic> data, this.textResponse}): _data = data;
  factory _HiringSkillResponse.fromJson(Map<String, dynamic> json) => _$HiringSkillResponseFromJson(json);

@override final  String skill;
 final  Map<String, dynamic> _data;
@override Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

@override final  String? textResponse;

/// Create a copy of HiringSkillResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HiringSkillResponseCopyWith<_HiringSkillResponse> get copyWith => __$HiringSkillResponseCopyWithImpl<_HiringSkillResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HiringSkillResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HiringSkillResponse&&(identical(other.skill, skill) || other.skill == skill)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.textResponse, textResponse) || other.textResponse == textResponse));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,skill,const DeepCollectionEquality().hash(_data),textResponse);

@override
String toString() {
  return 'HiringSkillResponse(skill: $skill, data: $data, textResponse: $textResponse)';
}


}

/// @nodoc
abstract mixin class _$HiringSkillResponseCopyWith<$Res> implements $HiringSkillResponseCopyWith<$Res> {
  factory _$HiringSkillResponseCopyWith(_HiringSkillResponse value, $Res Function(_HiringSkillResponse) _then) = __$HiringSkillResponseCopyWithImpl;
@override @useResult
$Res call({
 String skill, Map<String, dynamic> data, String? textResponse
});




}
/// @nodoc
class __$HiringSkillResponseCopyWithImpl<$Res>
    implements _$HiringSkillResponseCopyWith<$Res> {
  __$HiringSkillResponseCopyWithImpl(this._self, this._then);

  final _HiringSkillResponse _self;
  final $Res Function(_HiringSkillResponse) _then;

/// Create a copy of HiringSkillResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? skill = null,Object? data = null,Object? textResponse = freezed,}) {
  return _then(_HiringSkillResponse(
skill: null == skill ? _self.skill : skill // ignore: cast_nullable_to_non_nullable
as String,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,textResponse: freezed == textResponse ? _self.textResponse : textResponse // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

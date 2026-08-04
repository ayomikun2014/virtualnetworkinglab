// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseModelImpl _$$ExerciseModelImplFromJson(
  Map<String, dynamic> json,
) => _$ExerciseModelImpl(
  exerciseId: json['exerciseId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  categoryId: json['categoryId'] as String,
  exerciseType: $enumDecode(
    _$ExerciseTypeEnumMap,
    json['exerciseType'],
    unknownValue: ExerciseType.unknown,
  ),
  difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
  authorUid: json['authorUid'] as String,
  initialTopologyId: json['initialTopologyId'] as String,
  maxScore: (json['maxScore'] as num?)?.toInt() ?? 100,
  isPublished: json['isPublished'] as bool? ?? true,
  practiceLevel: (json['practiceLevel'] as num?)?.toInt(),
  securityConfig: json['securityConfig'] as Map<String, dynamic>?,
  createdAt: const TimestampConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const TimestampConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$$ExerciseModelImplToJson(_$ExerciseModelImpl instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'title': instance.title,
      'description': instance.description,
      'categoryId': instance.categoryId,
      'exerciseType': _$ExerciseTypeEnumMap[instance.exerciseType]!,
      'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
      'authorUid': instance.authorUid,
      'initialTopologyId': instance.initialTopologyId,
      'maxScore': instance.maxScore,
      'isPublished': instance.isPublished,
      'practiceLevel': instance.practiceLevel,
      'securityConfig': instance.securityConfig,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$ExerciseTypeEnumMap = {
  ExerciseType.routing: 'routing',
  ExerciseType.switching: 'switching',
  ExerciseType.subnetting: 'subnetting',
  ExerciseType.security: 'security',
  ExerciseType.wireless: 'wireless',
  ExerciseType.troubleshooting: 'troubleshooting',
  ExerciseType.unknown: 'unknown',
};

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
};

class CloudSave {
  final String playerId;
  final String slot;
  final Map<String, dynamic> data;
  final int version;
  final String updatedAt;

  CloudSave({
    required this.playerId,
    required this.slot,
    required this.data,
    required this.version,
    required this.updatedAt,
  });

  factory CloudSave.fromJson(Map<String, dynamic> json) => CloudSave(
        playerId: json['player_id'] as String,
        slot: json['slot'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        version: json['version'] as int,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'player_id': playerId,
        'slot': slot,
        'data': data,
        'version': version,
        'updated_at': updatedAt,
      };
}

class CloudSaveSummary {
  final String slot;
  final int version;
  final String updatedAt;

  CloudSaveSummary({required this.slot, required this.version, required this.updatedAt});

  factory CloudSaveSummary.fromJson(Map<String, dynamic> json) => CloudSaveSummary(
        slot: json['slot'] as String,
        version: json['version'] as int,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'slot': slot,
        'version': version,
        'updated_at': updatedAt,
      };
}

class StorageObject {
  final String collection;
  final String key;
  final String playerId;
  final Map<String, dynamic> value;
  final int version;
  final String readPerm;
  final String writePerm;
  final String updatedAt;

  StorageObject({
    required this.collection,
    required this.key,
    required this.playerId,
    required this.value,
    required this.version,
    required this.readPerm,
    required this.writePerm,
    required this.updatedAt,
  });

  factory StorageObject.fromJson(Map<String, dynamic> json) => StorageObject(
        collection: json['collection'] as String,
        key: json['key'] as String,
        playerId: json['player_id'] as String,
        value: Map<String, dynamic>.from(json['value'] as Map),
        version: json['version'] as int,
        readPerm: json['read_perm'] as String,
        writePerm: json['write_perm'] as String,
        updatedAt: json['updated_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'collection': collection,
        'key': key,
        'player_id': playerId,
        'value': value,
        'version': version,
        'read_perm': readPerm,
        'write_perm': writePerm,
        'updated_at': updatedAt,
      };
}

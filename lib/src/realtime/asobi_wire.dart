import 'dart:convert';
import 'dart:typed_data';

/// Decoder for asobi's binary `world.tick` frame.
///
/// Same information as the JSON frame in about a quarter of the bytes, and
/// cheaper to decode: `ByteData` reads are single instructions where the JSON
/// parser has to chew nearly four kilobytes of text including forty UUID strings
/// and a hundred and sixty float literals.
///
/// **The output is the JSON payload, field for field.** Records arrive on the
/// wire as 2-byte slots, and this decoder maps them back to entity ids before it
/// returns, so the map it produces goes straight into `WorldTick.fromJson` and
/// nothing downstream learns which wire delivered the frame.
///
/// Layout, every multi-byte value **little-endian** - not the usual choice, and
/// deliberate: Godot's byte readers have no big-endian counterpart, so the wire
/// follows the runtime with the least room to spare.
///
/// ```
/// frame    Kind:8, ZX:32, ZY:32, FrameSeq:64, Kf:8, Tick:64,
///          DictLen:8, Dict, RecCount:16, Records
/// dict     for each name: Len:8, Name/utf8            (at most 32 names)
/// record   Op:8, Slot:16, Gen:8, [IdLen:8, Id/utf8]?, FieldCount:8, Fields
/// field    Type:3, Idx:5, Value                       (one header byte)
/// ```
class AsobiWire {
  static const int _kindSequenced = 1;
  static const int _kindUngated = 2;

  static const List<String> _ops = ['a', 'u', 'r'];

  static const int _tF32 = 0;
  static const int _tI32 = 1;
  static const int _tTrue = 2;
  static const int _tFalse = 3;
  static const int _tStr = 4;
  static const int _tNull = 5;

  /// The header alone, before any dictionary or record.
  static const int _minFrame = 27;

  /// Slot -> entity id, one map per zone. Slot 5 in one zone has nothing to do
  /// with slot 5 in another, so a single flat map would alias entities across
  /// zones - the same corruption that keying entities by zone exists to prevent.
  final Map<String, Map<int, String>> _slots = {};

  /// Forgets every binding, for a reconnect.
  ///
  /// Bindings are established by the adds THIS connection received, so carrying
  /// them over would attach stale ids to slots the server has since handed to
  /// different entities. The keyframe that follows a reconnect rebuilds the whole
  /// table anyway.
  void reset() => _slots.clear();

  /// Decodes one frame into the payload map the JSON wire would have sent.
  ///
  /// Returns null on malformed bytes rather than throwing. These come off the
  /// network and this runs inside a stream handler, where an uncaught throw takes
  /// the whole subscription down with it.
  Map<String, dynamic>? decode(List<int> bytes) {
    try {
      return _decode(Uint8List.fromList(bytes));
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _decode(Uint8List bytes) {
    if (bytes.length < _minFrame) return null;
    final view = ByteData.view(bytes.buffer, bytes.offsetInBytes);

    final kind = view.getUint8(0);
    if (kind != _kindSequenced && kind != _kindUngated) return null;

    final zx = view.getInt32(1, Endian.little);
    final zy = view.getInt32(5, Endian.little);
    final frameSeq = view.getInt64(9, Endian.little);
    final kf = view.getUint8(17) != 0;
    final tick = view.getInt64(18, Endian.little);

    var pos = 26;
    final dictLen = view.getUint8(pos);
    pos += 1;
    final names = <String>[];
    for (var i = 0; i < dictLen; i++) {
      if (pos >= bytes.length) return null;
      final nameLen = view.getUint8(pos);
      pos += 1;
      if (pos + nameLen > bytes.length) return null;
      names.add(utf8.decode(bytes.sublist(pos, pos + nameLen)));
      pos += nameLen;
    }

    if (pos + 2 > bytes.length) return null;
    final recCount = view.getUint16(pos, Endian.little);
    pos += 2;

    final zoneKey = '$zx:$zy';
    final table = _slots.putIfAbsent(zoneKey, () => {});
    final updates = <Map<String, dynamic>>[];

    for (var r = 0; r < recCount; r++) {
      if (pos + 4 > bytes.length) return null;
      final opByte = view.getUint8(pos);
      if (opByte >= _ops.length) return null;
      final op = _ops[opByte];
      final slot = view.getUint16(pos + 1, Endian.little);
      // The slot's generation, advancing every time it is rebound to a different
      // entity. Redundant on this ordered, reliable wire and carried anyway, so a
      // client also running the datagram plane keeps ONE slot table for both.
      final gen = view.getUint8(pos + 3);
      pos += 4;

      final record = <String, dynamic>{'op': op, 'gen': gen};
      if (op == 'a') {
        if (pos >= bytes.length) return null;
        final idLen = view.getUint8(pos);
        pos += 1;
        if (pos + idLen > bytes.length) return null;
        final id = utf8.decode(bytes.sublist(pos, pos + idLen));
        pos += idLen;
        // An add ESTABLISHES the binding and replaces whatever was there. Slots
        // are reused once freed, so a stale binding surviving an add would attach
        // the wrong entity to every later update on that slot.
        table[slot] = id;
        record['id'] = id;
      } else {
        // Absent when the slot has no binding, which means the add that would
        // have established it was lost. The record is still reported: the frame
        // genuinely says this slot changed, and shortening the update list would
        // hide the fact. EntityDelta reads an absent id as '', and the frame_seq
        // gap that caused it drives the resync that repairs the mapping.
        final bound = table[slot];
        if (bound != null) record['id'] = bound;
      }

      if (pos >= bytes.length) return null;
      final fieldCount = view.getUint8(pos);
      pos += 1;
      for (var f = 0; f < fieldCount; f++) {
        if (pos >= bytes.length) return null;
        final header = view.getUint8(pos);
        pos += 1;
        final type = header >> 5;
        final idx = header & 0x1F;
        if (idx >= names.length) return null;
        final key = names[idx];
        switch (type) {
          case _tF32:
            if (pos + 4 > bytes.length) return null;
            record[key] = view.getFloat32(pos, Endian.little);
            pos += 4;
          case _tI32:
            if (pos + 4 > bytes.length) return null;
            record[key] = view.getInt32(pos, Endian.little);
            pos += 4;
          case _tTrue:
            record[key] = true;
          case _tFalse:
            record[key] = false;
          case _tStr:
            if (pos + 2 > bytes.length) return null;
            final len = view.getUint16(pos, Endian.little);
            pos += 2;
            if (pos + len > bytes.length) return null;
            record[key] = utf8.decode(bytes.sublist(pos, pos + len));
            pos += len;
          case _tNull:
            record[key] = null;
          default:
            return null;
        }
      }

      // Released only AFTER the record is built, so the frame that announces an
      // entity's departure still carries its id.
      if (op == 'r') table.remove(slot);

      updates.add(record);
    }

    if (pos != bytes.length) {
      // Trailing bytes mean the frame and this decoder disagree about the layout,
      // and accepting it would hand the game a half-read frame.
      return null;
    }

    final payload = <String, dynamic>{
      'zone': [zx, zy],
      'tick': tick,
      'updates': updates,
    };
    // A sequenced frame holds a position in the zone's stream; an ungated one
    // does not, and says so on the text wire by omitting frame_seq. Leave it out
    // here too, so gap detection treats both wires identically.
    if (kind == _kindSequenced) {
      payload['frame_seq'] = frameSeq;
      payload['kf'] = kf;
    }
    return payload;
  }
}

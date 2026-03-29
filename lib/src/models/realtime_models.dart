class WsMessage {
  final String type;
  final Map<String, dynamic> payload;
  final String? cid;

  WsMessage({required this.type, required this.payload, this.cid});

  factory WsMessage.fromJson(Map<String, dynamic> json) => WsMessage(
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>? ?? {},
        cid: json['cid'] as String?,
      );
}

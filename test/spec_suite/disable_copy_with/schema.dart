import 'package:shazam/spec_suite/scalars/date_time.dart'; // Generated schema types

typedef GqlDataQueryInput = ({
  Date? time,
});
GqlDataQueryInput deserializeGqlDataQueryInput(Map<String, dynamic> json) {
  return (
    time:
        json['time'] == null ? null : Date.deserialize(json['time'] as String),
  );
}

Map<String, dynamic> serializeGqlDataQueryInput(GqlDataQueryInput data) {
  return {
    'time': data.time?.serialize(),
  };
}

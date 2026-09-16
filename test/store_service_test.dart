import 'package:budgetbite_app/services/store_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test(
    'nearby store search falls back when the primary provider fails',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        if (request.url.host == 'overpass-api.de') {
          return http.Response('temporarily unavailable', 503);
        }
        return http.Response(
          '''{"elements":[{"type":"node","id":1,"lat":34.1478,"lon":-118.1445,"tags":{"name":"Test Market","shop":"supermarket","addr:city":"Pasadena","addr:state":"CA"}}]}''',
          200,
        );
      });

      final stores = await StoreService(
        client: client,
      ).searchNearby(const LatLng(34.1478, -118.1445));

      expect(requests, 2);
      expect(stores, hasLength(1));
      expect(stores.single.name, 'Test Market');
    },
  );
}

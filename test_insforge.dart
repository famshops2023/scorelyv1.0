import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://ip53vj9s.ap-southeast.insforge.app/rest/v1/';
  final headers = {
    'apikey': 'ik_d23aa9a406864853f254a0722fc1e56b',
    'Authorization': 'Bearer ik_d23aa9a406864853f254a0722fc1e56b',
  };

  try {
    var res = await http.get(Uri.parse(url + 'teams?select=*'), headers: headers);
    print('Teams: ${res.statusCode}');
    print(res.body);

    res = await http.get(Uri.parse(url + 'players?select=*'), headers: headers);
    print('Players: ${res.statusCode}');
    print(res.body);
  } catch (e) {
    print('Error: $e');
  }
}

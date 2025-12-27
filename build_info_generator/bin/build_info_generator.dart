import 'dart:convert';
import 'dart:io';

int main(List<String> arguments) {
  try {
    Map<String, String> map = {};
    map['build_date'] = DateTime.now().toIso8601String();
    map['build_head'] = File("../.git/HEAD").readAsStringSync().trim();
    map['commit_hash'] = File("../.git/ORIG_HEAD").readAsStringSync().trim();
    String s = JsonEncoder.withIndent("  ").convert(map);
    File("../assets/buildinfo.json").writeAsStringSync(s);
    stdout.writeln("Wrote buildinfo.json");
    return 0;
  } catch (e) {
    stderr.writeln("Error during build info generation: $e");
    return 1;
  }
}

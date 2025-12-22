import 'package:accessiblecity/view/rides_pane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Differ should track diffs', () {
    List<int>from = [1,2,3,4];
    List<int>to = [3,4,5,6];
    List<int> removed = [];
    List<int> inserted = [];

    ListDiffer<int> differ = ListDiffer();
    differ.current = from;
    differ.update(to,
        onRemove: (idx, elem) { removed.add(idx);  },
        onInsert: (idx, elem) { inserted.add(idx); }
    );
    expect(removed.length, 2, reason: "removed length");
    expect(removed[0], 1, reason: "removed idx 0");
    expect(removed[1], 0, reason: "removed idx 1");
    expect(inserted.length, 2, reason: "inserted length");
    expect(inserted[0], 2, reason: "inserted idx 0");
    expect(inserted[1], 3, reason: "inserted idx 1");
  });
}
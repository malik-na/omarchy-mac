#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const bar = requireFromRoot('shell/plugins/bar/BarModel.js')
const barSource = fs.readFileSync(root + '/shell/plugins/bar/Bar.qml', 'utf8')

// The strip is the leftover above the 16:10 area, in logical pixels. The
// display scale applies to both axes, so the same panel yields its strip at
// any scale without knowing the scale.
assertEqual(bar.notchStripHeight('eDP-1', 1512, 982), 37, 'MacBook Pro 14"/16" at scale 2 has a 37px notch strip')
assertEqual(bar.notchStripHeight('eDP-1', 1280, 832), 32, 'MacBook Air 13.6" at scale 2 has a 32px notch strip')
assertEqual(bar.notchStripHeight('eDP-1', 1600, 1040), 40, 'MacBook Air 13.6" at scale 1.6 has a 40px notch strip')

assertEqual(bar.notchStripHeight('eDP-1', 1280, 800), 0, 'an exactly 16:10 panel (M1 Air) has no notch strip')
assertEqual(bar.notchStripHeight('DP-1', 1512, 982), 0, 'external monitors never report a notch strip')
assertEqual(bar.notchStripHeight('eDP-1', 982, 1512), 0, 'a rotated panel is not mistaken for a notch strip')
assertEqual(bar.notchStripHeight('eDP-1', 1128, 752), 0, 'a 3:2 panel is not mistaken for a notch strip')
assertEqual(bar.notchStripHeight('eDP-1', 0, 0), 0, 'degenerate screen sizes report no notch strip')
assertEqual(bar.notchStripHeight('', 1512, 982), 0, 'a missing screen name reports no notch strip')

// The bar must gate the floor on Apple Silicon and only floor top bars —
// the strip formula alone would also match some non-Apple panels, and a
// bar on any other edge does not cover the notch.
assert(
  /notchFloor: root\.appleSiliconHost && root\.position === "top"/.test(barSource),
  'bar floors only top bars on Apple Silicon machines'
)
assert(
  /BarModel\.notchStripHeight\(screen\.name, screen\.width, screen\.height\)/.test(barSource),
  'bar derives the floor from its own screen geometry'
)
assert(
  /implicitHeight: root\.vertical \? 0 : Math\.max\(root\.barSize, notchFloor\)/.test(barSource),
  'bar height is floored at the notch strip, never shrunk to it'
)
JS

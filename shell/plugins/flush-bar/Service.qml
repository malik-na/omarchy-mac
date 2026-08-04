import Quickshell
import Quickshell.Hyprland
import QtQuick

// Keeps the window gap on the bar's edge in step with the bar: 0 when the bar
// is transparent (windows sit flush under it) or the same as the other edges
// when opaque. The shell persists every bar change — edge moves and the
// transparency toggle — into shell.json, which surfaces here as
// shell.barConfig, so binding to it sees the same state the bar itself sees.
Item {
  id: root

  // Injected by the shell's service loader.
  property var shell
  property var manifest

  // The state we last handed to gaps.sh, so a bar move can restore the edge
  // it came from and unchanged applies are skipped.
  property bool applied: false
  property string appliedPosition: ""
  property bool appliedTransparent: false

  readonly property var barConfig: shell ? shell.barConfig : null
  readonly property string position: normalizePosition(barConfig && barConfig.position)
  readonly property bool transparent: !!(barConfig && barConfig.transparent === true)

  readonly property string gapsScript: decodeURIComponent(
    Qt.resolvedUrl("gaps.sh").toString().replace(/^file:\/\//, ""))

  // Same normalization the bar applies to its own config (BarModel.js).
  function normalizePosition(value) {
    var next = String(value || "").trim()
    return /^(top|bottom|left|right)$/.test(next) ? next : "top"
  }

  // Hand the bar's edge and transparency to gaps.sh, which sets Hyprland's
  // gaps_out: 0 under a transparent bar (windows flush) or the window gap when
  // opaque. Passing the edge the bar just moved off of lets the script restore
  // exactly that edge, so a hand-set zero elsewhere survives.
  function applyGaps(previousPosition) {
    var movedFrom = previousPosition === undefined ? position : previousPosition
    Quickshell.execDetached(["bash", gapsScript, position, transparent ? "true" : "false", movedFrom])
  }

  function syncGaps() {
    if (!shell) return
    if (applied && position === appliedPosition && transparent === appliedTransparent) return
    var previous = applied ? appliedPosition : position
    applied = true
    appliedPosition = position
    appliedTransparent = transparent
    applyGaps(previous)
  }

  // The shell injects `shell` right after creating the service, so the
  // onShellChanged handler doubles as the once-at-startup apply.
  onShellChanged: syncGaps()
  onPositionChanged: syncGaps()
  onTransparentChanged: syncGaps()

  // Hyprland resets gaps_out to its config default on reload, so re-assert
  // the bar's gap whenever that happens.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && event.name === "configreloaded" && root.applied) root.applyGaps()
    }
  }
}

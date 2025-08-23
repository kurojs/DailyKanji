import QtQuick
import org.kde.plasma.components
import org.kde.ksvg as KSVG

Rectangle {
  color: "transparent"
  border.width: 0

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    onClicked:  (mouse) => {
      root.expanded = !root.expanded
    }
  }
}
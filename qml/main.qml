import QtQuick 2.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15

ApplicationWindow {
  visible: true
  width: 1000
  height: 750
  title: "Monitoria"

  Rectangle {
    id: topBar
    height: 50
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    color:"grey"

    RoundButton {
      id: createPolygon
      width: 100
      height: 40
      anchors {
        left: parent.left
        leftMargin: 5
        verticalCenter: parent.verticalCenter
      }
      text: "Create Polygon"
      radius: 5

      onClicked: {
        //disable ui elements here
      }
    }

    RoundButton {
      id: okPolygon
      width: 40
      height: 40
      anchors {
        left: createPolygon.right
        leftMargin: 5
        verticalCenter: parent.verticalCenter
      }
      text: "\u2713"

      onClicked: {
        MonitoringAreasModel.insert_monitoring_areas('A02', newPolygon.path)
      }
    }
  }

  Map {
    id: map
    anchors {
      top: topBar.bottom
      left: parent.left
      right: parent.right
      bottom: parent.bottom
    }
    plugin: Plugin {id: mapPlugin; name: "esri"}
    activeMapType: supportedMapTypes[1]
    center: QtPositioning.coordinate(-22.785610, 119.148699)
    zoomLevel: zoomSlider.value
    copyrightsVisible: false

    MapPolygon {
      id: newPolygon
      border {width: 3; color: "black"}
      color: Qt.rgba(55, 210, 109, 0.5)
      path: []
    }

    MouseArea {
      id: mapMouseArea
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton

      onClicked: {
        if (mouse.button == Qt.LeftButton) {
          var point = Qt.point(mouse.x, mouse.y);
          var coord = map.toCoordinate(point);
          newPolygon.addCoordinate(coord)
        }
        else if (mouse.button == Qt.RightButton) {
          var path = myPolygonNew.path
          var latestCoord = path[path.length - 1]
          newPolygon.removeCoordinate(latestCoord)
        }
      }
    }

    MapItemView {
      model: MonitoringAreasModel
      delegate:

      MapPolygon {
        id: monitoringArea
        border {width: 3; color: "green"}
        color: Qt.rgba(55, 210, 109, 0.5)
        path: geometry

        MouseArea {
          id: test
          anchors.fill: parent
          onClicked: {
            MonitoringAreasModel.log(index)

            MonitoringAreasModel.log('out')
          }
        }
      }


    }

    Slider {
      id: zoomSlider
      from: 20
      to: 1
      value: 17
      anchors {
        top: parent.top
        right: parent.right
        margins: 25
      }
      orientation: Qt.Vertical
    }
  }
}

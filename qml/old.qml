import QtQuick 2.4
import QtQuick.Controls 2.4
import QtLocation 5.12
import QtPositioning 5.12

ApplicationWindow {
  visible: true
  width: 1250
  height: 750
  title: "Monitoria"

  property bool editActive: false

  // top bar
  Rectangle {
    id: topBar
    height: 40
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
    }
    color: "#2c3e50"

    // app logo
    Text {
      id: appLogo
      width: leftBar.width
      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
        leftMargin: 5

      }
      verticalAlignment: Text.AlignVCenter
      text: "Monitoria"
      font {
        pointSize: 12
        weight: Font.DemiBold
      }
      color: "white"

    }

    // create polygon button
    RoundButton {
      id: createPolygon
      width: 30
      height: 30
      anchors {
        left: appLogo.right
        leftMargin: 5
        verticalCenter: parent.verticalCenter
      }
      icon {
        source: "file:icons/edit-polygon.png"
        color: "transparent"
      }
      enabled: true

      onClicked: {
        // reset temp polygon
        newPolygon.path = [];

        // enable/disable relevant edit buttons
        createPolygon.enabled = false;
        insertPolygon.enabled = false;
        cancelPolygon.enabled = true;

        // begin edit session
        editActive = true;
      }
    }

    // insert current created polygon button
    RoundButton {
      id: insertPolygon
      width: 30
      height: 30
      anchors {
        left: createPolygon.right
        leftMargin: 5
        verticalCenter: parent.verticalCenter
      }
      icon {
        source: "file:icons/edit-done.png"
        color: "transparent"
      }
      enabled: false

      onClicked: {

        // insert new polygon into database
        MonitoringAreasModel.log(newPolygon)
        MonitoringAreasModel.insert_monitoring_area('A02', newPolygon.path);

        // reset temp polygon
        newPolygon.path = [];

        // reset model !TODO! make this only refresh new polygons
        MonitoringAreasModel.get_monitoring_areas();

        // enable createPolygon, disable insertPolygon buttons
        createPolygon.enabled = true;
        insertPolygon.enabled = false;
        cancelPolygon.enabled = false;

        // end edit session
        editActive = false;
      }
    }

    // cancel current created polygon button
    RoundButton {
      id: cancelPolygon
      width: 30
      height: 30
      anchors {
        left: insertPolygon.right
        leftMargin: 5
        verticalCenter: parent.verticalCenter
      }
      icon {
        source: "file:icons/edit-cancel.png"
        color: "transparent"
      }
      enabled: false

      onClicked: {

        // reset temp polygon
        newPolygon.path = [];

        // enable createPolygon, disable insertPolygon buttons
        createPolygon.enabled = true;
        insertPolygon.enabled = false;
        cancelPolygon.enabled = false;

        // end edit session
        editActive = false;
      }
    }

    // delete current selected polygon button
    RoundButton {
      id: deletePolygon
      width: 30
      height: 30
      anchors {
        right: parent.right
        rightMargin: 5
        verticalCenter: parent.verticalCenter
      }
      icon {
        source: "file:icons/delete-polygon.png"
        color: "transparent"
      }
      enabled: false

      onClicked: {

        // clear all selections
        for (var i in polygonsModel.children) {
          if (polygonsModel.children[i]['isSelected'] == true) {
            var selected_id = polygonsModel.children[i]['areaId']

            // delete selected polygon into database
            MonitoringAreasModel.delete_monitoring_area(selected_id);
          }
        }

        // reset model !TODO! make this only refresh new polygons
        MonitoringAreasModel.get_monitoring_areas();

        // reset temp polygon
        newPolygon.path = [];

        // disable deletePolygon button
        deletePolygon.enabled = false;

        // end edit session
        editActive = false;
      }
    }

    // !TODO! temp perform analysis
    RoundButton {
      id: performAnalysis
      width: 30
      height: 30
      anchors {
        right: deletePolygon.left
        rightMargin: 5
        verticalCenter: parent.verticalCenter
      }
      icon {
        source: "file:icons/perform-analysis.png"
        color: "transparent"
      }
      enabled: true

      onClicked: {

        // clear all selections
        for (var i in polygonsModel.children) {
          if (polygonsModel.children[i]['isSelected'] == true) {
            var area_id = polygonsModel.children[i]['areaId'];
            MonitoringAreasModel.perform_analysis(area_id);
          }
        }
      }
    }
  }

  // left bar
  Rectangle {
    id: leftBar
    width: 175
    anchors {
      top: topBar.bottom
      bottom: parent.bottom
      left: parent.left
    }
    color: "#34495e"
  }

  // bottom bar
  Rectangle {
    id: bottomBar
    height: 40
    anchors {
      bottom: parent.bottom
      left: leftBar.right
      right: parent.right
    }
    color: "#7f8c8d"

    // header subbar
    Rectangle {

      id: bottomHeaderBar
      height: 40
      anchors {
        top: parent.top
        left: parent.left
        right: parent.right
      }
      color: "#2c3e50"

      // expand graph button
      RoundButton {
        id: expandGraph
        width: 30
        height: 30
        anchors {
          right: parent.right
          rightMargin: 5
          verticalCenter: parent.verticalCenter
        }
        icon {
          source: "file:icons/expand-down.png"
          color: "transparent"
        }
        enabled: true

        onClicked: {
          if (bottomBar.height > bottomHeaderBar.height) {
            bottomBar.height = bottomHeaderBar.height
          }
          else {
            bottomBar.height = 350
          }

          // reset model !TODO! only refresh map render?
          MonitoringAreasModel.get_monitoring_areas();
        }
      }
    }
  }

  // map area
  Map {
    id: map
    anchors {
      top: topBar.bottom
      left: leftBar.right
      right: parent.right
      bottom: bottomBar.top
    }
    plugin: Plugin {id: mapPlugin; name: "esri"}
    activeMapType: supportedMapTypes[1]
    center: QtPositioning.coordinate(-22.785610, 119.148699)
    zoomLevel: 16
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
        if (editActive == true) {
          if (mouse.button == Qt.LeftButton) {
            var point = Qt.point(mouse.x, mouse.y);
            var coord = map.toCoordinate(point);
            newPolygon.addCoordinate(coord)

            // if 3 vertices detected, enable insert button
            if (newPolygon.path.length >= 3) {
              insertPolygon.enabled = true;
            }
            else {
              insertPolygon.enabled = false;
            }
          }

          //else if (mouse.button == Qt.RightButton) {
            //var path = newPolygon.path
            //var latestCoord = path[path.length - 1]
            //newPolygon.removeCoordinate(latestCoord)
          //}
        }
      }
    }

    MapItemView {
      id: polygonsModel
      model: MonitoringAreasModel
      delegate:

      MapPolygon {
        property int areaId: id
        property string areaCode: code
        property bool isSelected: false

        id: monitoringArea
        border {width: 3; color: isSelected ? "red" : "green"}
        color: Qt.rgba(55, 210, 109, 0.5)
        path: geometry

        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (editActive == false) {
              if (mouse.button == Qt.LeftButton) {

                // clear all selections
                for (var i in polygonsModel.children) {
                  polygonsModel.children[i]['isSelected'] = false

                  // disable delete button
                  deletePolygon.enabled = false
                }

                // set current clicked polygon to selected
                monitoringArea.isSelected = true

                // enable delete button
                deletePolygon.enabled = true
              }
            }
          }
        }
      }
    }
  }
}

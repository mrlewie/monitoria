import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.15
import QtLocation 5.12
import QtPositioning 5.12
import QtCharts 2.13

ApplicationWindow {
  id: appWindow
  width: 1200
  height: 800
  title: "MONITORIA"
  visible: true

  // custom parameters
  property bool inEditSession: false         // global edit session tracker

  // popup window for edit
  Popup {
    id: editPopup
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: parent.width / 1.5
    height: parent.height / 1.5
    padding: 5
    modal: true
    background:
    Rectangle {
      anchors.fill: parent
      color: "#262626"
      radius: 3
    }

    Rectangle {
      anchors.fill: parent
      color: "#404040"
      radius: 3

      // header
      Rectangle {
        id: popupHeader
        height: 50
        anchors {
          top: parent.top
          left: parent.left
          right: parent.right
        }
        color: "#595959"

        // header text
        Text {
          anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: 10

          }
          verticalAlignment: Text.AlignVCenter
          text: "Create monitoring site"
          color: "white"
          font {
            family: "Arial"
            pixelSize: 16
            weight: Font.Medium
          }
        }
      }

      //code header
      Text {
        id: codeHeader
        width: 200
        anchors {
          top: popupHeader.bottom
          left: parent.left
          topMargin: 20
          leftMargin: 20
        }
        text: "Site Code"
        color: "white"
      }

      // code text field
      TextField {
        id: codeValue
        width: 200
        height: 25
        anchors {
          top: codeHeader.bottom
          left: codeHeader.left
          topMargin: 10
        }
        verticalAlignment: Text.AlignVCenter
        color: "white"
        font {
          family: "Arial"
          pixelSize: 12
        }
        placeholderText: "Enter a unique site code"
        //placeholderTextColor: "red"
        //textColor: "red"
        maximumLength: 100
        background: Rectangle {color: "#262626"; radius: 3}
        //style: TextFieldStyle {textColor: "red"}
        //background: Rectangle {radius:3; color: "#262626"}
      }

    }
    //onAccepted: console.log("Ok clicked")
    //onRejected: console.log("Cancel clicked")
  }

  // window background color
  Rectangle {
    anchors.fill: parent
    color: "#262626"
  }

  // top topbar
  Rectangle {
    id: topBar
    height: 50
    anchors {
      top: parent.top
      left: parent.left
      right: parent.right
      topMargin: 5
      leftMargin: 5
      rightMargin: 4
    }
    color: "#404040"
    radius: 3

    // monitoria logo
    Text {
      id: logo
      anchors {
        top: parent.top
        bottom: parent.bottom
        left: parent.left
        leftMargin: 10
      }
      verticalAlignment: Text.AlignVCenter
      text: "MONITORIA"
      font {
        pointSize: 14
        weight: Font.DemiBold
      }
      color: "white"
    }
  }

  // grid layout
  GridLayout {
    id: grid
    anchors {
      top: topBar.bottom
      bottom: parent.bottom
      left: parent.left
      right: parent.right
      topMargin: 5
      bottomMargin: 5
      leftMargin: 5
      rightMargin: 5
    }
    columns: 5
    rows: 3
    columnSpacing: 5
    rowSpacing: 5

    // left panel with area list
    Rectangle {
      id: leftPanel
      Layout.rowSpan: 2
      Layout.minimumWidth: 150
      Layout.maximumWidth: 250
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "#404040"
      radius: 3

      // header area text
      Text {
        id: leftPanelHeader
        height: 40
        anchors {
          top: parent.top
          left: parent.left
          leftMargin: 10
        }
        verticalAlignment: Text.AlignVCenter
        text: "Monitoring Areas"
        font {
          pointSize: 10
          weight: Font.DemiBold
        }
        color: "white"
      }

      // list of all monitoring areas
      ListView {
        id: sitesList
        anchors {
          top: leftPanelHeader.bottom
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        spacing: 3
        model: SitesModel
        delegate:

        // monitoring area list delegate
        Item {
          id: sitesDelegate
          width: parent.width
          height: 40

          // alt row background color
          Rectangle {
            anchors.fill: parent
            color: "#737373"
            opacity: index % 2 == 0 ? 0.05 : 0.0
          }

          // monitoring area code
          Text {
            id: sitesCode
            width: 50
            anchors {
              top: parent.top
              bottom: parent.bottom
              left: parent.left
              topMargin: 5
              bottomMargin: 5
              leftMargin: 10
            }
            verticalAlignment: Text.AlignVCenter
            text: code
            font {
              pointSize: 8
              weight: Font.DemiBold
            }
            color: "white"
          }
        }
      }
    }

    // center panel with map
    Rectangle {
      id: centerPanel
      Layout.columnSpan: 3
      Layout.rowSpan: 2
      Layout.minimumWidth: 300
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "#404040"
      radius: 3

      // interactive map area
      Map {
        id: map
        anchors.fill: parent
        center: QtPositioning.coordinate(-22.785610, 119.148699)
        zoomLevel: 16
        plugin: Plugin {id: mapPlugin; name: "esri"}
        activeMapType: supportedMapTypes[1]
        copyrightsVisible: false

        // non-polygon mouse interactions
        MouseArea {
          id: mapMouseArea
          anchors.fill: parent

          onClicked: {
            if (mouse.button == Qt.LeftButton) {
              SitesModel.deselectAreas();  // deselect polygons

              // move this to a mappolygon class in python
              if (inEditSession == true) {
                var point = Qt.point(mouseX, mouseY);
                var coord = map.toCoordinate(point);
                tempPolygon.addCoordinate(coord)

                // // if 3 vertices detected, enable insert button
                // if (newPolygon.path.length >= 3) {
                //   insertPolygon.enabled = true;
                // }
                // else {
                //   insertPolygon.enabled = false;
                // }
                //else if (mouse.button == Qt.RightButton) {
                //var path = newPolygon.path
                //var latestCoord = path[path.length - 1]
                //newPolygon.removeCoordinate(latestCoord)
                //}
              }
              //else if (mouse.button == Qt.RightButton) {
              //var path = newPolygon.path
              //var latestCoord = path[path.length - 1]
              //newPolygon.removeCoordinate(latestCoord)
              //}
            }
          }
        }

        // temporary polygon for edit session only
        MapPolygon {
          id: tempPolygon
          border {
            width: 2
            color: "#fbff00"
          }
          color: "#1Afbff00"
          path: []
          antialiasing: true
          layer {
            enabled: true
            samples: 2
          }
        }

        // map polygon view
        MapItemView {
          id: mapPolygonsView
          model: SitesModel
          delegate:

          // map polygon delegate
          MapPolygon {
            id: mapPolygon
            border {
              width: 2
              color: selected ? "#ff0000" : "#24ff00"
            }
            color: selected ? "#1Aff0000" : "#1A24ff00"
            path: geometry
            antialiasing: true
            layer {
              enabled: true
              samples: 2
            }

            // map mouse interactivity for local polygons
            MouseArea {
              id: mapPolygonMouseArea
              anchors.fill: parent
              enabled: inEditSession ? false : true

              onClicked: {
                if (mouse.button == Qt.LeftButton) {
                  SitesModel.selectArea(index);
                }
              }
            }
          }
        }

        // container to hold overlay buttons
        Item {
          id: mapButtonOverlay
          anchors.fill: parent
          enabled: true
          visible: true

          // button to add feature
          RoundButton {
            id: buttonAddFeature
            width: 30
            height: 30
            anchors {
              top: parent.top
              left: parent.left
              topMargin: 5
              leftMargin: 5
            }
            icon {
              source: "file:icons/map-add-feature.svg"
              color: "white"
            }
            enabled: true
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            onClicked: {
              inEditSession = true;  // begin edit session
            }
          }

          // button to create polygon
          RoundButton {
            id: buttonCreatePolygon
            width: 30
            height: 30
            anchors {
              top: parent.top
              left: buttonAddFeature.right
              topMargin: 5
              leftMargin: 5
            }
            icon {
              source: "file:icons/map-create-polygon.svg"
              color: "white"
            }
            enabled: inEditSession ? true : false
            visible: inEditSession ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            // button to create polygon
            onClicked: {
              tempPolygon.path = [];  // clear existing coords
            }
          }

          // button to create rectangle
          RoundButton {
            id: buttonCreateRectangle
            width: 30
            height: 30
            anchors {
              top: parent.top
              left: buttonCreatePolygon.right
              topMargin: 5
              leftMargin: 5
            }
            icon {
              source: "file:icons/map-create-rectangle.svg"
              color: "white"
            }
            enabled: inEditSession ? true : false
            visible: inEditSession ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            // button to create rectangle
            //onReleased: {}
          }

          // button to create circle
          RoundButton {
            id: buttonCreateCircle
            width: 30
            height: 30
            anchors {
              top: parent.top
              left: buttonCreateRectangle.right
              topMargin: 5
              leftMargin: 5
            }
            icon {
              source: "file:icons/map-create-circle.svg"
              color: "white"
            }
            enabled: inEditSession ? true : false
            visible: inEditSession ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            // button to create circle
            //onReleased: {}
          }

          // button to accept feature
          RoundButton {
            id: buttonAcceptFeature
            width: 30
            height: 30
            anchors {
              top: buttonAddFeature.bottom
              left: parent.left
              topMargin: 5
              leftMargin: 5
            }
            icon {
              source: "file:icons/map-accept-feature.svg"
              color: "white"
            }
            enabled: inEditSession ? true : false
            visible: inEditSession ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            onClicked: {
              editPopup.open()                         // open popup
              SitesModel.insertArea(tempPolygon.path)  // insert row
              tempPolygon.path = []                    // reset temp geom to empty list



              inEditSession = false;                   // end edit session
            }
          }

          // button to cancel feature
          RoundButton {
            id: buttonCancelFeature
            width: 30
            height: 30
            anchors {
              top: buttonAddFeature.bottom
              left: buttonAcceptFeature.right
              topMargin: 5
              leftMargin: 5
            }
            icon {
              source: "file:icons/map-cancel-feature.svg"
              color: "white"
            }
            enabled: inEditSession ? true : false
            visible: inEditSession ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            onClicked: {
              tempPolygon.path = [];  // clear temp polygon
              inEditSession = false;  // end edit session
            }
          }

          // button to zoom in once
          RoundButton {
            id: buttonZoomIn
            width: 30
            height: 30
            anchors {
              top: parent.top
              right: parent.right
              topMargin: 5
              rightMargin: 5
            }
            icon {
              source: "file:icons/map-zoom-in.svg"
              color: "white"
            }
            enabled: true
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            // zoom in by one level
            onReleased: {
              if (map.zoomLevel < 18) {
                map.zoomLevel += 1
              }
            }
          }

          // button to zoom out once
          RoundButton {
            id: buttonZoomOut
            width: 30
            height: 30
            anchors {
              top: buttonZoomIn.bottom
              right: parent.right
              topMargin: 5
              rightMargin: 5
            }
            icon {
              source: "file:icons/map-zoom-out.svg"
              color: "white"
            }
            enabled: true
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            // zoom out by one level
            onReleased: {
              if (map.zoomLevel > 2) {
                map.zoomLevel -= 1
              }
            }
          }

          // button to delete feature
          RoundButton {
            id: buttonDeleteFeature
            width: 30
            height: 30
            anchors {
              bottom: parent.bottom
              right: parent.right
              bottomMargin: 5
              rightMargin: 5
            }
            icon {
              source: "file:icons/map-delete-feature.svg"
              color: "white"
            }
            enabled: true //isAPolygonSelected ? true : false
            visible: true //isAPolygonSelected ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            onClicked: {
              SitesModel.deleteArea(-1)  // -1 uses pyside index tracker
            }
          }

          // button to undo change
          RoundButton {
            id: buttonUndoChange
            width: 30
            height: 30
            anchors {
              bottom: parent.bottom
              right: buttonDeleteFeature.left
              bottomMargin: 5
              rightMargin: 5
            }
            icon {
              source: "file:icons/map-create-undo.svg"
              color: "white"
            }
            enabled: inEditSession ? true : false
            visible: inEditSession ? true : false
            background: Rectangle {
              border {
                width: 2
                color: "#262626"
              }
              color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
              radius: parent.radius
            }

            // undo change
            //onReleased: {}
          }
        }
      }
    }

    // right top panel
    Rectangle {
      id: rightTopPanel
      Layout.minimumWidth: 150
      Layout.maximumWidth: 250
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "#404040"
      radius: 3

      // button to add feature
      RoundButton {
        id: buttonPerformAnalysis
        width: 30
        height: 30
        anchors {
          verticalCenter: parent.verticalCenter
          horizontalCenter: parent.horizontalCenter
        }
        icon {
          source: "file:icons/perform-analysis.svg"
          color: "white"
        }
        enabled: true
        background: Rectangle {
          border {
            width: 2
            color: "#262626"
          }
          color: parent.down ? "#A6A6A6" : (parent.hovered ? "#737373" : "#404040")
          radius: parent.radius
        }

        // begin edit session
        onClicked: {
          MonitoringAreasModel.perform_analysis()
        }
      }
    }

    // right bottom panel
    Rectangle {
      id: rightBottomPanel
      Layout.minimumWidth: 150
      Layout.maximumWidth: 250
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "#404040"
      radius: 3
    }

    // bottom panel for graphing
    Rectangle {
      id: bottomPanel
      Layout.columnSpan: 5
      Layout.rowSpan: 1
      Layout.fillWidth: true
      Layout.fillHeight: true
      color: "#404040"
      radius: 3

      ChartView {
        id: chart
        anchors.fill: parent
        backgroundColor: "transparent"
        antialiasing: true
        legend {
          visible: false
        }

        ValueAxis{
          id: xAxis
          labelsColor: "white"
        }

        ValueAxis{
          id: yAxis
          labelsColor: "white"
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.AllButtons

          onClicked: {
            chart.removeAllSeries()

            xAxis.min = 0
            xAxis.max = MonitoringAreasModel.count_dates()
            yAxis.min = MonitoringAreasModel.get_min_veg_value()
            yAxis.max = MonitoringAreasModel.get_max_veg_value()

            var series = chart.createSeries(ChartView.SeriesTypeLine, "A", xAxis, yAxis);
            MonitoringAreasModel.graph(series)


            //if (mouse.button == Qt.LeftButton) {
            // do stuff
            //}
            //else if (mouse.button == Qt.RightButton) {
            //chart.zoomIn()
            //}

            // series.pointsVisible = true;
            // series.color = "green";
            //
            // //const indexes = [0, 1, 2, 3]
            // //const dates = [10, 20, 30, 40];
            // const values = [0.4, 0.3, 0.1, 0.7];
            // //const values = MonitoringAreasModel.get_y_graph_data(1);
            // //const count = 10;
            //
            // for (var i = 0; i < count; i++) {
            //     series.append(i, values[i]);
            // }
          }
        }
      }
    }
  }
}

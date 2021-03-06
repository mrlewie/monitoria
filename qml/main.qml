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
  property bool inEditSession: false       // global edit session tracker

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
        id: monitoringAreasList
        anchors {
          top: leftPanelHeader.bottom
          bottom: parent.bottom
          left: parent.left
          right: parent.right
        }
        spacing: 3
        model: MonitoringAreasModel
        delegate:

        // monitoring area list delegate
        Item {
          id: monitoringAreaListDelegate
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
            id: monitoringAreaListCode
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
              MonitoringAreasModel.deselect_polys();  // deselect all polys

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
          model: MonitoringAreasModel
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
                  MonitoringAreasModel.select_poly(index)         // select clicked poly
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
              MonitoringAreasModel.insert_monitoring_area(tempPolygon.path)  // insert row
              tempPolygon.path = []   // reset temp geom to empty list
              inEditSession = false;  // end edit session
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
              MonitoringAreasModel.delete_monitoring_area()  // delete selected polygon(s)
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
          //min: 0
          //max: 477
          //   //tickCount: 9
          //   //labelFormat: "%.0f"
          //   titleVisible: true
          //   gridVisible: true
          //   labelsVisible: true
          labelsColor: "white"
        }

        ValueAxis{
          id: yAxis
          //min: MonitoringAreasModel.get_min_veg_value(0)
          //max: MonitoringAreasModel.get_max_veg_value(0)
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

        // Component.onCompleted: {
        //   var series = chart.createSeries(ChartView.SeriesTypeLine, "A", xAxis, yAxis);
        //   series.pointsVisible = true;
        //   series.color = "green"
        //
        //   //var count = list.count;
        //   //for (var i = 0; i < count; i++) {
        //       //series.append(list.get(i).x, list.get(i).y);
        //   //}
        //
        //   //const indexes = [0, 1, 2, 3]
        //   //const dates = [10, 20, 30, 40];
        //   //const values = [0.4, 0.3, 0.1, 0.7];
        //
        //   const values = MonitoringAreasModel.get_y_graph_data(0);
        //   var count = 80;
        //
        //   MonitoringAreasModel.log('hi')
        //
        //   for (var i = 0; i < count; i++) {
        //     series.append(i, bottomPanel.values[i]);
        //       //series.append(indexes[i], values[i]);
        //   }
        // }

        // Component.onCompleted: {
        //   var series = chart.createSeries(ChartView.SeriesTypeLine, "A", xAxis, yAxis);
        //
        //   series.pointsVisible = true;
        //   series.color = "green"
        //   series.hovered.connect(
        //     function(point, state) {
        //       console.log(point);  // connect onHovered signal to a function
        //     });
        //
        //   //const count = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].length;
        //   const dates = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];
        //   const values = [0.4, 0.3, 0.1, 0.7, 0.9, 0.7, 0.6, 0.4, 0.3, 0.5];
        //
        //   //var x = 10; //0.0;
        //   var pointsCount = indices.length;
        //
        //   for (var i = 0; i < 10; i++) {
        //     //x += 1;
        //     //var y = (Math.random() * 10.0);
        //     //var x = dates[i]
        //     //var y = values[i
        //     var x = 1
        //     var y = 2
        //     series.append(x, y);
        //     //x += 1;
        //   }
        //   }
      }
    }
  }

  // // top bar
  // Rectangle {
  //   id: topBar
  //   height: 40
  //   anchors {
  //     top: parent.top
  //     left: parent.left
  //     right: parent.right
  //   }
  //   color: "#2c3e50"
  //
  //   // app logo
  //   Text {
  //     id: appLogo
  //     width: leftBar.width
  //     anchors {
  //       top: parent.top
  //       bottom: parent.bottom
  //       left: parent.left
  //       leftMargin: 5
  //
  //     }
  //     verticalAlignment: Text.AlignVCenter
  //     text: "Monitoria"
  //     font {
  //       pointSize: 12
  //       weight: Font.DemiBold
  //     }
  //     color: "white"
  //
  //   }
  //
  //   // create polygon button
  //   RoundButton {
  //     id: createPolygon
  //     width: 30
  //     height: 30
  //     anchors {
  //       left: appLogo.right
  //       leftMargin: 5
  //       verticalCenter: parent.verticalCenter
  //     }
  //     icon {
  //       source: "file:icons/edit-polygon.png"
  //       color: "transparent"
  //     }
  //     enabled: true
  //
  //     onClicked: {
  //       // reset temp polygon
  //       newPolygon.path = [];
  //
  //       // enable/disable relevant edit buttons
  //       createPolygon.enabled = false;
  //       insertPolygon.enabled = false;
  //       cancelPolygon.enabled = true;
  //
  //       // begin edit session
  //       editActive = true;
  //     }
  //   }
  //
  //   // insert current created polygon button
  //   RoundButton {
  //     id: insertPolygon
  //     width: 30
  //     height: 30
  //     anchors {
  //       left: createPolygon.right
  //       leftMargin: 5
  //       verticalCenter: parent.verticalCenter
  //     }
  //     icon {
  //       source: "file:icons/edit-done.png"
  //       color: "transparent"
  //     }
  //     enabled: false
  //
  //     onClicked: {
  //
  //       // insert new polygon into database
  //       MonitoringAreasModel.insert_monitoring_area('A02', newPolygon.path);
  //
  //       // reset temp polygon
  //       newPolygon.path = [];
  //
  //       // reset model !TODO! make this only refresh new polygons
  //       MonitoringAreasModel.get_monitoring_areas();
  //
  //       // enable createPolygon, disable insertPolygon buttons
  //       createPolygon.enabled = true;
  //       insertPolygon.enabled = false;
  //       cancelPolygon.enabled = false;
  //
  //       // end edit session
  //       editActive = false;
  //     }
  //   }
  //
  //   // cancel current created polygon button
  //   RoundButton {
  //     id: cancelPolygon
  //     width: 30
  //     height: 30
  //     anchors {
  //       left: insertPolygon.right
  //       leftMargin: 5
  //       verticalCenter: parent.verticalCenter
  //     }
  //     icon {
  //       source: "file:icons/edit-cancel.png"
  //       color: "transparent"
  //     }
  //     enabled: false
  //
  //     onClicked: {
  //
  //       // reset temp polygon
  //       newPolygon.path = [];
  //
  //       // enable createPolygon, disable insertPolygon buttons
  //       createPolygon.enabled = true;
  //       insertPolygon.enabled = false;
  //       cancelPolygon.enabled = false;
  //
  //       // end edit session
  //       editActive = false;
  //     }
  //   }
  //
  //   // delete current selected polygon button
  //   RoundButton {
  //     id: deletePolygon
  //     width: 30
  //     height: 30
  //     anchors {
  //       right: parent.right
  //       rightMargin: 5
  //       verticalCenter: parent.verticalCenter
  //     }
  //     icon {
  //       source: "file:icons/delete-polygon.png"
  //       color: "transparent"
  //     }
  //     enabled: false
  //
  //     onClicked: {
  //
  //       // clear all selections
  //       for (var i in polygonsModel.children) {
  //         if (polygonsModel.children[i]['isSelected'] == true) {
  //           var selected_id = polygonsModel.children[i]['areaId']
  //
  //           // delete selected polygon into database
  //           MonitoringAreasModel.delete_monitoring_area(selected_id);
  //         }
  //       }
  //
  //       // reset model !TODO! make this only refresh new polygons
  //       MonitoringAreasModel.get_monitoring_areas();
  //
  //       // reset temp polygon
  //       newPolygon.path = [];
  //
  //       // disable deletePolygon button
  //       deletePolygon.enabled = false;
  //
  //       // end edit session
  //       editActive = false;
  //     }
  //   }
  //
  //   // !TODO! temp perform analysis
  //   RoundButton {
  //     id: performAnalysis
  //     width: 30
  //     height: 30
  //     anchors {
  //       right: deletePolygon.left
  //       rightMargin: 5
  //       verticalCenter: parent.verticalCenter
  //     }
  //     icon {
  //       source: "file:icons/perform-analysis.png"
  //       color: "transparent"
  //     }
  //     enabled: true
  //
  //     onClicked: {
  //
  //       // clear all selections
  //       for (var i in polygonsModel.children) {
  //         if (polygonsModel.children[i]['isSelected'] == true) {
  //           var area_id = polygonsModel.children[i]['areaId'];
  //           MonitoringAreasModel.perform_analysis(area_id);
  //         }
  //       }
  //     }
  //   }
  // }
  //
  // // left bar
  // Rectangle {
  //   id: leftBar
  //   width: 175
  //   anchors {
  //     top: topBar.bottom
  //     bottom: parent.bottom
  //     left: parent.left
  //   }
  //   color: "#34495e"
  // }
  //
  // // bottom bar
  // Rectangle {
  //   id: bottomBar
  //   height: 40
  //   anchors {
  //     bottom: parent.bottom
  //     left: leftBar.right
  //     right: parent.right
  //   }
  //   color: "#7f8c8d"
  //
  //   // header subbar
  //   Rectangle {
  //
  //     id: bottomHeaderBar
  //     height: 40
  //     anchors {
  //       top: parent.top
  //       left: parent.left
  //       right: parent.right
  //     }
  //     color: "#2c3e50"
  //
  //     // expand graph button
  //     RoundButton {
  //       id: expandGraph
  //       width: 30
  //       height: 30
  //       anchors {
  //         right: parent.right
  //         rightMargin: 5
  //         verticalCenter: parent.verticalCenter
  //       }
  //       icon {
  //         source: "file:icons/expand-down.png"
  //         color: "transparent"
  //       }
  //       enabled: true
  //
  //       onClicked: {
  //         if (bottomBar.height > bottomHeaderBar.height) {
  //           bottomBar.height = bottomHeaderBar.height
  //         }
  //         else {
  //           bottomBar.height = 350
  //         }
  //
  //         // reset model !TODO! only refresh map render?
  //         MonitoringAreasModel.get_monitoring_areas();
  //       }
  //     }
  //   }
  // }
  //
  // // map area
  // Map {
  //   id: map
  //   anchors {
  //     top: topBar.bottom
  //     left: leftBar.right
  //     right: parent.right
  //     bottom: bottomBar.top
  //   }
  //   plugin: Plugin {id: mapPlugin; name: "esri"}
  //   activeMapType: supportedMapTypes[1]
  //   center: QtPositioning.coordinate(-22.785610, 119.148699)
  //   zoomLevel: 16
  //   copyrightsVisible: false
  //
  //   MapPolygon {
  //     id: newPolygon
  //     border {width: 3; color: "black"}
  //     color: Qt.rgba(55, 210, 109, 0.5)
  //     path: []
  //   }
  //
  //   MouseArea {
  //     id: mapMouseArea
  //     anchors.fill: parent
  //     acceptedButtons: Qt.LeftButton | Qt.RightButton
  //
  //     onClicked: {
  //       if (editActive == true) {
  //         if (mouse.button == Qt.LeftButton) {
  //           var point = Qt.point(mouse.x, mouse.y);
  //           var coord = map.toCoordinate(point);
  //           newPolygon.addCoordinate(coord)
  //
  //           // if 3 vertices detected, enable insert button
  //           if (newPolygon.path.length >= 3) {
  //             insertPolygon.enabled = true;
  //           }
  //           else {
  //             insertPolygon.enabled = false;
  //           }
  //         }
  //
  //         //else if (mouse.button == Qt.RightButton) {
  //           //var path = newPolygon.path
  //           //var latestCoord = path[path.length - 1]
  //           //newPolygon.removeCoordinate(latestCoord)
  //         //}
  //       }
  //     }
  //   }
  //
  //   MapItemView {
  //     id: polygonsModel
  //     model: MonitoringAreasModel
  //     delegate:
  //
  //     MapPolygon {
  //       property int areaId: id
  //       property string areaCode: code
  //       property bool isSelected: false
  //
  //       id: monitoringArea
  //       border {width: 3; color: isSelected ? "red" : "green"}
  //       color: Qt.rgba(55, 210, 109, 0.5)
  //       path: geometry
  //
  //       MouseArea {
  //         anchors.fill: parent
  //         onClicked: {
  //           if (editActive == false) {
  //             if (mouse.button == Qt.LeftButton) {
  //
  //               // clear all selections
  //               for (var i in polygonsModel.children) {
  //                 polygonsModel.children[i]['isSelected'] = false
  //
  //                 // disable delete button
  //                 deletePolygon.enabled = false
  //               }
  //
  //               // set current clicked polygon to selected
  //               monitoringArea.isSelected = true
  //
  //               // enable delete button
  //               deletePolygon.enabled = true
  //             }
  //           }
  //         }
  //       }
  //     }
  //   }
  // }
}

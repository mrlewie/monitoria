# general imports
# import random
# import sys
# import time
# import uuid
import json
# import numpy as np

# pyside imports
from PySide2.QtCore import Qt, QAbstractListModel, QModelIndex, Slot

# Qt, Slot, QAbstractListModel, QModelIndex, QThreadPool, QRunnable, QPoint, QObject
# from PySide2.QtGui import QGuiApplication
# from PySide2.QtPositioning import QGeoPolygon
# from PySide2.QtQml import QQmlApplicationEngine
# from PySide2.QtSql import QSqlDatabase, QSqlQuery
# from PySide2.QtCharts import QtCharts

# from PySide2.QtWidgets import QApplication

# external scripts imports
# from scripts import analyses
# from scripts import data
# from scripts import spatial

# globals
DATASTORE = r"C:\Users\Lewis\PycharmProjects\monitoria\data\data.json"  # r"..\data\data.json"


class SitesModel(QAbstractListModel):

    def __init__(self, parent=None):
        super(SitesModel, self).__init__(parent)
        self.selected_index = -1
        self.sites = []
        self.load()

    def rowCount(self, parent=QModelIndex()):
        return len(self.sites)

    def roleNames(self):
        roles = {
            hash(Qt.UserRole): 'id'.encode(),
            hash(Qt.UserRole + 1): 'code'.encode(),
            hash(Qt.UserRole + 2): 'dates'.encode(),
            hash(Qt.UserRole + 3): 'veg_raw'.encode(),
            hash(Qt.UserRole + 4): 'veg_smooth'.encode(),
            hash(Qt.UserRole + 5): 'geometry'.encode(),
            hash(Qt.UserRole + 6): 'selected'.encode(),
        }
        return roles

    def data(self, index=QModelIndex(), role=Qt.DisplayRole):
        if index.isValid():
            site = self.sites[index.row()]
            return site.get(list(site)[role - Qt.UserRole])

    def load(self):
        try:
            with open(DATASTORE, 'r') as f:
                self.sites = json.load(f)
        except Exception as e:
            print(e)
            pass

    def save(self):
        try:
            with open(DATASTORE, 'w') as f:
                json.dump(self.sites, f)
        except Exception as e:
            print(e)
            pass

    @Slot(list)
    def insertArea(self, vertices):

        # convert qml points to raw qml, also close poly via first vert
        vertices = [{'latitude': v.latitude(), 'longitude': v.longitude()} for v in vertices]

        # prepare row item
        row = {'id': None,
               'code': None,
               'dates': None,
               'veg_raw': None,
               'veg_smooth': None,
               'geometry': vertices,
               'selected': False}

        # perform safe insert
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())
        self.sites.insert(self.rowCount(), row)
        self.endInsertRows()

        # save json
        self.save()

        # reset selected index
        self.selected_index = -1

    @Slot(int)
    def deleteArea(self, index):

        # use index provided, else use current selected
        index = index if index != -1 else self.selected_index

        # perform safe delete
        self.beginRemoveRows(QModelIndex(), index, index)
        self.sites.remove(self.sites[index])
        self.endRemoveRows()

        # save json
        self.save()

        # reset selected index
        self.selected_index = -1

    @Slot(int)
    def selectArea(self, index):

        # iter rows and select clicked polygon
        for i in range(self.rowCount()):
            selected = True if i == index else False
            self.sites[i].update({'selected': selected})
            self.dataChanged.emit(self.index(i), self.index(i), self.roleNames())

        # reset selected index
        self.selected_index = index

    @Slot()
    def deselectAreas(self):

        # iter rows and deselect all polygons
        for i in range(self.rowCount()):
            self.sites[i].update({'selected': False})
            self.dataChanged.emit(self.index(i), self.index(i), self.roleNames())

        # reset selected index
        self.selected_index = -1

    @Slot(str)
    def log(self, msg):
        print(msg)


if __name__ == "__main__":
    # model = SitesModel()

    # model.load()
    # model.save()

    # print(model)
    ...

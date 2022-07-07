# general imports
import random
import sys
import time
import uuid
import json
import numpy as np

# pyside imports
from PySide2.QtWidgets import QApplication
from PySide2.QtCore import Qt, Slot, QAbstractListModel, QModelIndex, QThreadPool, QRunnable, QPoint, QObject
from PySide2.QtGui import QGuiApplication
from PySide2.QtPositioning import QGeoPolygon
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtSql import QSqlDatabase, QSqlQuery
from PySide2.QtCharts import QtCharts

# external scripts imports
from scripts import classes
from scripts import analyses
from scripts import data
from scripts import spatial


# to install odc-stac with pip
# first go to https://rasterio.readthedocs.io/en/latest/installation.html
# follow windows instructions and use pip here to install BOTH .whl files
# then pip install odc-stac


class MonitoringAreasModel(QAbstractListModel):
    def __init__(self):
        super(MonitoringAreasModel, self).__init__()
        self.monitoring_areas = []

        # get all existing monitoring areas in db
        self.get_monitoring_areas()

    def data(self, index=QModelIndex(), role=Qt.DisplayRole):
        monitoring_area = self.monitoring_areas[index.row()]
        value = monitoring_area.get(list(monitoring_area)[role - Qt.UserRole])

        return value

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

    def rowCount(self, parent=QModelIndex()):
        num_rows = len(self.monitoring_areas)

        return num_rows

    @Slot()
    def get_monitoring_areas(self):
        """
        Queries Sql database and returns every monitoring area
        currently within. Resets existing items in qml
        view.

        :return: None.
        """

        # notify
        print('Getting all existing monitoring areas.')

        # begin the reset model
        self.beginResetModel()

        # open db
        db = data.connect_to_db('monitoring_areas_get')

        # get monitoring areas data
        query = QSqlQuery(query='SELECT * FROM MONITORING_AREAS', db=db)
        query.exec_()

        # iter each monitoring area
        self.monitoring_areas = []
        while query.next():

            # convert wkt to qml polygon
            qml_polygon = spatial.wkt_to_qml_polygon(wkt_polygon=query.value(5))

            # convert date data into lists
            if query.value(2) != '':
                dates = [str(dt) for dt in list(query.value(2).split(','))]

            # convert veg raw data into lists
            if query.value(3) != '':
                values = [float(val) for val in list(query.value(3).split(','))]

            # add monitoring area and vertices to model list
            self.monitoring_areas.append({
                'id': query.value(0),
                'code': query.value(1),
                'dates': dates,
                'veg_raw': values,
                'veg_smooth': query.value(4),
                'geometry': qml_polygon,
                'selected': False
            })

        # end and emit the reset
        self.endResetModel()

        # close db
        db.close()

    @Slot(list)
    def insert_monitoring_area(self, qml_polygon):
        """

        :param code:
        :param qml_polygon:
        :return:
        """

        # notify
        print('Inserting monitoring area into MONITORING_AREA table.')

        # convert from qml polygon to wkt polygon
        wkt_polygon = spatial.qml_polygon_to_wkt(qml_polygon=qml_polygon)

        # begin insert row model operation
        self.beginInsertRows(QModelIndex(), self.rowCount(), self.rowCount())

        # insert item into list  todo can i use rolenames?
        row = {'id': None,
               'code': None,
               'dates': None,
               'veg_raw': None,
               'veg_smooth': None,
               'geometry': qml_polygon,
               'selected': False
               }
        self.monitoring_areas.insert(self.rowCount(), row)

        # open db
        db_conn = uuid.uuid4().hex
        db = data.connect_to_db('monitoring_area_insert_{}'.format(db_conn))

        # add new area into monitoring area table
        query = QSqlQuery(db=db)
        query.prepare('INSERT OR IGNORE INTO MONITORING_AREAS (geometry) '
                      'VALUES (:geometry)')
        query.bindValue(':geometry', wkt_polygon)
        query.exec_()

        # close db
        db.close()

        # end insert row model operation
        self.endInsertRows()

    @Slot()
    def delete_monitoring_area(self):
        """

        :return:
        """

        # notify
        print('Deleting area from MONITORING_AREA table.')

        # set all selected values to false (reset selection)
        for idx, row in enumerate(self.monitoring_areas):
            if row['selected']:

                # start begin remove rows
                self.beginRemoveRows(QModelIndex(), idx, idx)  # todo check last idx is correct

                # remove list item
                self.monitoring_areas.remove(row)

                # open db
                db_conn = uuid.uuid4().hex
                db = data.connect_to_db('monitoring_area_delete_{}'.format(db_conn))

                # drop existing area from monitoring area table
                query = QSqlQuery(db=db)
                query.prepare('DELETE FROM MONITORING_AREAS WHERE id = :id')
                query.bindValue(':id', row['id'])
                query.exec_()

                # close db
                db.close()

                # end remove rows session
                self.endRemoveRows()

    @Slot()
    def perform_analysis(self):
        """

        :param geometry:
        :return:
        """

        # notify
        print('Performing analysis.')

        # from multiprocessing.pool import ThreadPool
        # import dask
        # dask.config.set(pool=ThreadPool(2))

        # find selected row
        for idx, row in enumerate(self.monitoring_areas):
            if row['selected']:
                geometry = row['geometry']

                # check if geometry exists and proceed
                if geometry is not None or len(geometry) > 0:

                    # get bounding box
                    xs = [coord.get('longitude') for coord in geometry]
                    ys = [coord.get('latitude') for coord in geometry]
                    bbox = [min(xs), min(ys), max(xs), max(ys)]

                    collections = ['ga_ls5t_ard_3', 'ga_ls7e_ard_3', 'ga_ls8c_ard_3']
                    from_date, to_date = '1990-01-01',  '2021-12-31' #'1995-12-31'

                    # query aws stac for available collection items
                    items = analyses.query_stac(collections=collections,
                                                from_date=from_date,
                                                to_date=to_date,
                                                bbox=bbox)

                    # now build a dataset using all available items
                    ds = analyses.build_dataset(items=items,
                                                bbox=bbox,
                                                crs='EPSG:4326',
                                                resolution=10 / 111000,
                                                like=None,
                                                ignore_warnings=True)

                    # mask out (remove) any invalid scenes
                    ds = analyses.mask_invalid_scenes(ds=ds,
                                                      mask_var='mask',
                                                      valid=[1, 4, 5],
                                                      min_pct=1.0,
                                                      drop_mask=True)

                    # calculate ndvi index
                    ds = analyses.calculate_index(ds=ds,
                                                  index='NDVI',
                                                  drop_bands=True)

                    # load the dataset all at same time (we only have one band)
                    ds = analyses.load_dataset(ds=ds, logic='all')

                    # remove edge pixels
                    # todo remove edge pixels

                    # reduce down to one mean value per scene
                    ds = analyses.get_temporal_means(ds)

                    # remove spike outliers
                    ds = analyses.remove_outliers(ds, user_factor=2)

                    # prepare dates
                    dts = ds['time'].dt.strftime('%Y-%m-%d').values
                    dts = ','.join([str(dt) for dt in dts])

                    # prepare veg values
                    vals = ds['veg_idx'].values
                    vals = ','.join([str(val) for val in vals])

                    # update row
                    self.monitoring_areas[idx].update({'dates': dts, 'veg_raw': vals})
                    self.dataChanged.emit(self.index(idx), self.index(idx), self.roleNames())

                    # open db
                    db_conn = uuid.uuid4().hex
                    db = data.connect_to_db('monitoring_area_update_{}'.format(db_conn))

                    # add new area into monitoring area table
                    query = QSqlQuery(db=db)
                    query.prepare('UPDATE MONITORING_AREAS '
                                  'SET dates = :dates, veg_raw = :veg_raw '
                                  'WHERE id = :id')
                    query.bindValue(':id', row['id'])
                    query.bindValue(':dates', dts)
                    query.bindValue(':veg_raw', vals)
                    query.exec_()

                    # close db
                    db.close()

                    print(ds)

    @Slot(int)
    def select_poly(self, index):
        """
        For clicked polygon on map, set to selected. All others
        get set to not selected.
        :param index:
        :return:
        """

        # set all selected values to false (reset selection)
        for idx, row in enumerate(self.monitoring_areas):
            self.monitoring_areas[idx].update({'selected': False})
            self.dataChanged.emit(self.index(idx), self.index(idx), self.roleNames())

        # now, update selected polygon row via input index and emit
        self.monitoring_areas[index].update({'selected': True})
        self.dataChanged.emit(self.index(index), self.index(index), self.roleNames())

    @Slot()
    def deselect_polys(self):
        """

        :return:
        """

        # set all selected values to false (reset selection)
        for idx, row in enumerate(self.monitoring_areas):
            self.monitoring_areas[idx].update({'selected': False})
            self.dataChanged.emit(self.index(idx), self.index(idx), self.roleNames())

    @Slot(result=int)
    def count_dates(self):
        for idx, row in enumerate(self.monitoring_areas):
            if row['selected']:
                if row['dates'] is None:
                    return 0
                else:
                    return len(row['dates'])

    @Slot(result=float)
    def get_min_veg_value(self):
        for idx, row in enumerate(self.monitoring_areas):
            if row['selected']:
                if row['veg_raw'] is None:
                    return 0
                else:
                    return min(row['veg_raw'])
                    #return np.percentile(row['veg_raw'], 0.25)

    @Slot(result=float)
    def get_max_veg_value(self):
        for idx, row in enumerate(self.monitoring_areas):
            if row['selected']:
                if row['veg_raw'] is None:
                    return 0
                else:
                    return max(row['veg_raw'])
                    #return np.percentile(row['veg_raw'], 99.75)

    @Slot(QtCharts.QAbstractSeries)
    def graph(self, series):

        series.setPointsVisible(True)
        series.setColor('red')

        for idx, row in enumerate(self.monitoring_areas):
            if row['selected']:
                for i, v in enumerate(row['veg_raw']):
                    series.append(i, v)

    @Slot(str)
    def log(self, msg):
        print(msg)

    @Slot(int)
    def runTasks(self, id):

        # notify
        print('Downloading available satellite data.')

        # todo implement threading like here
        #threadCount = QThreadPool.globalInstance().maxThreadCount()
        #print(f"Running {threadCount} Threads")
        #pool = QThreadPool.globalInstance()
        #runnable = Runnable(id=id, monitoring_areas=self.monitoring_areas)
        #pool.start(runnable)
        ...


class Runnable(QRunnable):
    def __init__(self, id, monitoring_areas):
        super().__init__()
        self.id = id
        self.monitoring_areas = monitoring_areas

    def run(self):

        # notify
        print('Performing analysis.')

        # todo temp
        # from multiprocessing.pool import ThreadPool
        # import dask
        # dask.config.set(pool=ThreadPool(2))

        # # get geometry for selected polygon
        # for monitoring_area in self.monitoring_areas:
        #     if self.id == monitoring_area.get('id'):
        #         geometry = monitoring_area.get('geometry')
        #
        # # check if geometry exists and proceed
        # if geometry is not None or len(geometry) > 0:
        #     xs = [coord.get('longitude') for coord in geometry]
        #     ys = [coord.get('latitude') for coord in geometry]
        #     bbox = [min(xs), min(ys), max(xs), max(ys)]
        #
        #     collections = ['ga_ls5t_ard_3', 'ga_ls7e_ard_3', 'ga_ls8c_ard_3']
        #     from_date, to_date = '1990-01-01', '2004-06-15'  # '2021-12-31'
        #
        #     # query aws stac for available collection items
        #     items = analyses.query_stac(collections=collections,
        #                                 from_date=from_date,
        #                                 to_date=to_date,
        #                                 bbox=bbox)
        #
        #     # now build a dataset using all available items
        #     ds = analyses.build_dataset(items=items,
        #                                 bbox=bbox,
        #                                 crs='EPSG:4326',
        #                                 resolution=10 / 111000,
        #                                 like=None,
        #                                 ignore_warnings=True)
        #
        #     # mask out (remove) any invalid scenes
        #     ds = analyses.mask_invalid_scenes(ds=ds,
        #                                       mask_var='mask',
        #                                       valid=[1, 4, 5],
        #                                       min_pct=1.0,
        #                                       drop_mask=True)
        #
        #     # calculate ndvi index
        #     ds = analyses.calculate_index(ds=ds,
        #                                   index='NDVI',
        #                                   drop_bands=True)
        #
        #     # load the dataset all at same time (we only have one band)
        #     ds = analyses.load_dataset(ds=ds, logic='all')
        #
        #     # reduce down to one mean value per scene
        #     ds = analyses.get_temporal_means(ds)
        #
        #     print(ds)


if __name__ == "__main__":

    # init app, db
    #app = QGuiApplication(sys.argv)  # this doesnt work with charts, use below
    app = QApplication(sys.argv)

    # init engine and load qml
    engine = QQmlApplicationEngine()
    engine.load("qml/main2.qml")  # todo change

    # init models
    #monitoring_areas = MonitoringAreasModel()
    sites = classes.SitesModel()

    # set model to qml app
    #engine.rootContext().setContextProperty('MonitoringAreasModel', monitoring_areas)
    engine.rootContext().setContextProperty('SitesModel', sites)

    # quit if nada...
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec_())

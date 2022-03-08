import sys
import uuid

from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine
from PySide2.QtCore import Qt, Slot, QAbstractListModel, QModelIndex
from PySide2.QtSql import QSqlDatabase, QSqlQuery

from PySide2.QtPositioning import QGeoCoordinate

# globals
DATABASE = r'.\data\monitoria.db'


class MonitoringAreasModel(QAbstractListModel):
    def __init__(self, parent=None):
        super(MonitoringAreasModel, self).__init__(parent)
        self.monitoring_areas = []

        # get all existing monitoring areas in db
        self.get_monitoring_areas()

    def data(self, index=QModelIndex(), role=Qt.DisplayRole):
        monitoring_area = self.monitoring_areas[index.row()]
        value = monitoring_area.get(list(monitoring_area)[role - Qt.UserRole])

        return value

    def roleNames(self):
        roles = {
            hash(Qt.UserRole):      'id'.encode(),
            hash(Qt.UserRole + 1):  'code'.encode(),
            hash(Qt.UserRole + 2):  'geometry'.encode(),
        }

        return roles

    def rowCount(self, parent=QModelIndex()):
        num_rows = len(self.monitoring_areas)

        return num_rows

    @Slot()
    def get_monitoring_areas(self):
        """
        Queries Sql daatabase and returns every monitoring area
        currently within. Resets existing items in qml
        view.

        :return: None.
        """

        # notify
        print('Getting all existing monitoring areas')

        # begin the reset model
        self.beginResetModel()

        # open db
        db = connect_to_db('monitoring_areas_get')

        # get monitoring areas data
        query = QSqlQuery(query='SELECT * FROM MONITORING_AREAS ORDER BY id', db=db)
        query.exec_()

        # iter each monitoring area
        self.monitoring_areas = []
        while query.next():

            # get row id and monitoring area code
            id = query.value(0)
            code = query.value(1)

            # get associated vertices in appropriate format
            query_verts = QSqlQuery(db=db)
            query_verts.prepare('SELECT latitude, longitude '
                                'FROM VERTICES '
                                'WHERE monitoring_area_id = :monitoring_area_id '
                                'ORDER BY id')
            query_verts.bindValue(':monitoring_area_id', query.value(0))
            query_verts.exec_()

            # iter each vertex and prepare into compatible list
            vertices = []
            while query_verts.next():
                vertices.append({
                    'latitude': query_verts.value(0),
                    'longitude': query_verts.value(1),
                })

            # add monitoring area and vertices to model list
            if len(vertices) >= 3:
                self.monitoring_areas.append({
                    'id': id,
                    'code': code,
                    'geometry': vertices,
                })

        # end and emit the reset
        self.endResetModel()

        # close db
        db.close()

    @Slot(str, list)
    def insert_monitoring_areas(self, code, geometry):
        """

        :param id:
        :param code:
        :param geometry:
        :return:
        """

        # notify
        print('Inserting code: {} and geometry: {} into MONITORING_AREA table.'.format(code, geometry))

        # open db
        db_conn = uuid.uuid4().hex
        db = connect_to_db('monitoring_areas_insert_{}'.format(db_conn))

        # add new area into monitoring area table
        query = QSqlQuery(db=db)
        query.prepare('INSERT OR IGNORE INTO MONITORING_AREAS (code) VALUES (:code)')
        query.bindValue(':code', code)
        query.exec_()

        # get id of above insert
        last_id = query.lastInsertId()

        # loop each vertex in geometry, get lat/lon, insert
        for vertex in geometry:
            query = QSqlQuery(db=db)
            query.prepare('INSERT OR IGNORE INTO VERTICES (latitude, longitude, monitoring_area_id) '
                          'VALUES (:latitude, :longitude, :monitoring_area_id)')
            query.bindValue(':latitude', vertex.latitude())
            query.bindValue(':longitude', vertex.longitude())
            query.bindValue(':monitoring_area_id', last_id)
            query.exec_()

        # close db
        db.close()

    @Slot(str)
    def log(self, msg):
        print(msg)



def connect_to_db(connection_name=None):
    """
    Connect to database, accepts custom connection name
    for threading, if required.

    :param connection_name: Custom name of connection.
    :return: QSqlDatabase file.
    """

    # create db
    db = QSqlDatabase.addDatabase('QSQLITE', connection_name)
    db.setDatabaseName(DATABASE)

    if db.open():
        return db
    else:
        raise ValueError('Cannot initialise database.')


def create_monitoring_areas_table(db=None):
    """
    Check if MONITORING_AREAS table exists in db, else create one.
    """

    sql = """
        CREATE TABLE IF NOT EXISTS MONITORING_AREAS (
            id INTEGER NOT NULL,
            code TEXT NOT NULL,
            PRIMARY KEY (id)
        )
        """

    # ok if table exists, if not create it
    if 'MONITORING_AREAS' in db.tables():
        return

    # if not, attempt to create it
    query = QSqlQuery(db=db)
    if not query.exec_(sql):
        print('Failed to create MONITORING_AREAS table.')


def create_vertices_table(db=None):
    """
    Check if VERTICES table exists in db, else create one.
    """

    sql = """
        CREATE TABLE IF NOT EXISTS VERTICES (
            id INTEGER NOT NULL,
            latitude DOUBLE NOT NULL, 
            longitude DOUBLE NOT NULL, 
            monitoring_area_id INTEGER NOT NULL,
            PRIMARY KEY (id), 
            FOREIGN KEY (id) REFERENCES MONITORING_AREAS(id)
        )
        """

    # ok if table exists, if not create it
    if 'VERTICES' in db.tables():
        return

    # if not, attempt to create it
    query = QSqlQuery(db=db)
    if not query.exec_(sql):
        print('Failed to create VERTICES table.')

if __name__ == "__main__":

    # init app, db
    app = QGuiApplication(sys.argv)

    # init engine and load qml
    engine = QQmlApplicationEngine()
    engine.load("qml/main.qml")

    # connect to db, open, check, sync, close
    db = connect_to_db('init')
    create_monitoring_areas_table(db=db)
    create_vertices_table(db=db)
    db.close()

    # init models
    monitoring_areas = MonitoringAreasModel()

    # set model to qml app
    engine.rootContext().setContextProperty('MonitoringAreasModel', monitoring_areas)

    # quit if nada...
    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec_())

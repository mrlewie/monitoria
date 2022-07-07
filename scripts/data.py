# pyside imports
from PySide2.QtSql import QSqlDatabase, QSqlQuery

# globals
DATABASE = r'.\data\monitoria.db'


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
            code TEXT,
            dates TEXT,
            veg_raw TEXT,
            veg_smooth TEXT,
            geometry TEXT NOT NULL,
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



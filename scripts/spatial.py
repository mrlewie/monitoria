# shapely imports
from shapely.geometry import Polygon
from shapely.wkt import loads


# deprecated
def qml_polygon_to_wkt(qml_polygon):
    """
    Helper function to convert qml polygon (an array of
    point types) to wkt for storage in sqlite database.

    :param polygon:
    :return:
    """

    # todo checks
    # type

    # convert qml polygon to wkt
    polygon = Polygon([[v.longitude(), v.latitude()] for v in qml_polygon])
    wkt_polygon = polygon.wkt

    return wkt_polygon


# deprecated
def wkt_to_qml_polygon(wkt_polygon):
    """

    :param wkt_polygon:
    :return:
    """

    # todo checks
    #

    # load the wky polygon into shapely type
    polygon = loads(wkt_polygon)

    # get pairs of coordinates and convert to qml type
    coords = list(polygon.exterior.coords)
    coords = [{'latitude': c[1], 'longitude': c[0]} for c in coords]

    return coords

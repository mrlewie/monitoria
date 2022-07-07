# general imports
import time
import warnings
import numpy as np
import xarray as xr

# odc imports
from pystac_client import Client
from odc import stac

# globals
AWS_S3_ENDPOINT = 's3.ap-southeast-2.amazonaws.com'
STAC_ENDPOINT = 'https://explorer.sandbox.dea.ga.gov.au/stac/'

# configure rasterio for dea aws
stac.configure_rio(cloud_defaults=True,
                   aws={"aws_unsigned": True},
                   AWS_S3_ENDPOINT=AWS_S3_ENDPOINT)


def query_stac(collections, from_date, to_date, bbox):
    """

    :param collections:
    :param from_date:
    :param to_date:
    :param bbox:
    :return:
    """

    # notify
    print('Beginning STAC query.')

    # todo checks
    #

    # iter through collections and build queries
    items = None
    for collection in collections:
        print('Checking for collection: {}.'.format(collection))

        # get range of dates
        date_range = '{}/{}'.format(from_date, to_date)

        # fix landsat 7 end date for slc-off
        if collection == 'ga_ls7e_ard_3' and to_date > '2003-05-31':
            date_range = '{}/{}'.format(from_date, '2003-05-31')

        # perform query
        catalog = Client.open(STAC_ENDPOINT)
        query = catalog.search(collections=collection,
                               datetime=date_range,
                               bbox=bbox,
                               limit=250)

        # create items if new, else append
        if items is None:
            items = query.get_all_items()
        else:
            items = items + query.get_all_items()

    # notify and return
    print('Found {} items in total.'.format(len(items)))
    return items


def build_dataset(items, bbox, crs, resolution, like, ignore_warnings):
    """

    :param ignore_warnings:
    :param items:
    :param bands:
    :param bbox:
    :param crs:
    :param resolution:
    :param like:
    :return:
    """

    # set config for band renames todo add s2 c3 non-prov when avail
    config = {
        'ga_ls5t_ard_3': {
            'assets': {
                '*': {
                    'data_type': 'uint16',
                    'nodata': 0,
                    'unit': '1'
                }
            },
            'aliases': {
                'blue': 'nbart_blue',
                'green': 'nbart_green',
                'red': 'nbart_red',
                'nir': 'nbart_nir',
                'swir_1': 'nbart_swir_1',
                'swir_2': 'nbart_swir_2',
                'mask': 'oa_fmask',
            }
        },
        'ga_ls7e_ard_3': {
            'assets': {
                '*': {
                    'data_type': 'uint16',
                    'nodata': 0,
                    'unit': '1'
                }
            },
            'aliases': {
                'blue': 'nbart_blue',
                'green': 'nbart_green',
                'red': 'nbart_red',
                'nir': 'nbart_nir',
                'swir_1': 'nbart_swir_1',
                'swir_2': 'nbart_swir_2',
                'mask': 'oa_fmask'
            }
        },
        'ga_ls8c_ard_3': {
            'assets': {
                '*': {
                    'data_type': 'uint16',
                    'nodata': 0,
                    'unit': '1'
                }
            },
            'aliases': {
                'blue': 'nbart_blue',
                'green': 'nbart_green',
                'red': 'nbart_red',
                'nir': 'nbart_nir',
                'swir_1': 'nbart_swir_1',
                'swir_2': 'nbart_swir_2',
                'mask': 'oa_fmask'
            }
        },
        'ga_ls8c_ard_provisional_3': {
            'assets': {
                '*': {
                    'data_type': 'uint16',
                    'nodata': 0,
                    'unit': '1'
                }
            },
            'aliases': {
                'blue': 'nbart_blue',
                'green': 'nbart_green',
                'red': 'nbart_red',
                'nir': 'nbart_nir',
                'swir_1': 'nbart_swir_1',
                'swir_2': 'nbart_swir_2',
                'mask': 'oa_fmask'
            }
        },
        'ga_s2am_ard_provisional_3': {
            'assets': {
                '*': {
                    'data_type': 'uint16',
                    'nodata': 0,
                    'unit': '1'
                }
            },
            'aliases': {
                'blue': 'nbart_blue',
                'green': 'nbart_green',
                'red': 'nbart_red',
                'nir': 'nbart_nir_1',
                'swir_1': 'nbart_swir_2',
                'swir_2': 'nbart_swir_3',
                'mask': 'oa_fmask'
            },
        },
        'ga_s2bm_ard_provisional_3': {
            'assets': {
                '*': {
                    'data_type': 'uint16',
                    'nodata': 0,
                    'unit': '1'
                }
            },
            'aliases': {
                'blue': 'nbart_blue',
                'green': 'nbart_green',
                'red': 'nbart_red',
                'nir': 'nbart_nir_1',
                'swir_1': 'nbart_swir_2',
                'swir_2': 'nbart_swir_3',
                'mask': 'oa_fmask'
            },
        },
    }

    # notify
    print('Building dataset.')

    # todo checks
    #

    # silence warnings if requested
    if ignore_warnings is True:
        warnings.filterwarnings('ignore')

    # always set same names as config conforms ls, s2
    bands = ['blue', 'green', 'red', 'nir', 'swir_1', 'swir_2', 'mask']

    # build xr dataset
    ds = stac.stac_load(items,
                        bands=bands,
                        bbox=bbox,
                        crs=crs,
                        resolution=resolution,
                        groupby="solar_day",
                        stac_cfg=config,
                        skip_broken_datasets=True,
                        like=like,
                        chunks={})

    # rename latitude,longitude to y, x if exist
    if 'latitude' in ds and 'longitude' in ds:
        ds = ds.rename({'latitude': 'y', 'longitude': 'x'})

    # turn warnings back on if disabled prior
    if ignore_warnings is True:
        warnings.filterwarnings('default')

    # notify and return
    print('Created dataset with {} scenes.'.format(len(ds['time'])))
    return ds


def mask_invalid_scenes(ds, mask_var, valid, min_pct, drop_mask):
    """
    Uses the QA mask to remove whole scenes if above
    the allowed minimum percentage threshold. Value of
    1.0 is 100% valid, 0.5 is 50% valid, etc. Invalid
    scenes are removed entirely.

    :param ds:
    :param mask_var:
    :param valid:
    :param min_pct:
    :param drop_mask:
    :return:
    """

    # notify
    print('Masking and removing invalid scenes via QA mask. This can take awhile...')

    # todo checks
    #

    # subset and download mask variable
    mask = ds[mask_var]
    mask = mask.load()

    # get total number of cells for a scene (i.e. raster)
    total = mask.sizes['x'] * mask.sizes['y']

    # convert valid/invalid to binary, sum and make a mask
    mask = xr.where(mask.isin(valid), 1, 0)
    mask = mask.sum(['x', 'y']) / total
    mask = xr.where(mask == min_pct, True, False)

    # obtain valid date and times, subset valid only
    valid_dts = mask['time'].where(mask, drop=True)
    ds = ds.sel(time=valid_dts)

    # drop mask variable
    if drop_mask is True:
        ds = ds.drop_vars('mask')

    # notify and return
    print('Retained {} valid scenes following mask.'.format(len(valid_dts)))
    return ds


def calculate_index(ds, index, drop_bands):
    """
    Calculates a index (e.g., NDVI) from a dataset
    of bands.

    :param ds:
    :param index:
    :param drop_bands:
    :return:
    """

    # notify
    print('Calculating index: {}.'.format(index))

    # todo checks
    #

    # calculate ndvi
    if index.lower() == 'ndvi':
        ds['veg_idx'] = ((ds['nir'] - ds['red']) /
                         (ds['nir'] + ds['red']))

        # calculate mavi todo add more indices
    # ...

    # drop all bands except index if requested
    if drop_bands is True:
        drop_vars = [v for v in ds.data_vars if v != 'veg_idx']
        ds = ds.drop_vars(drop_vars)

    # force type to float32 to be safe
    ds = ds.astype('float32')

    # todo check if band attributes lost
    #

    # notify and return
    print('Index was calculated.')
    return ds


def load_dataset(ds, logic):
    """

    :param ds:
    :param logic:
    :param warnings:
    :return:
    """

    # notify
    print('Downloading and loading dataset.')

    # todo checks
    if logic.lower() not in ['all', 'band']:
        print('Logic only supports All or Band. Using default (All).')
        logic = 'All'

    # load dataset depending on logic requested
    if logic.lower() == 'all':
        print('Downloading all data at once. Please wait...')

        # download all at once and time it
        s = time.time()
        ds = ds.load()
        e = time.time()

        # format duration and notify
        duration = round((e - s) / 60, 2)
        print('Downloaded and loaded in {} mins.'.format(duration))

    elif logic.lower() == 'band':
        for var in ds.data_vars:
            print('Downloading and loading band: {}.'.format(var))

            # download band and time it
            s = time.time()
            ds[var] = ds[var].load()
            e = time.time()

            # format duration and notify
            duration = round((e - s) / 60, 2)
            print('Downloaded and loaded band {} in {} mins.'.format(var, duration))

    # notify and return
    print('Dataset downloaded and loaded.')
    return ds


def get_temporal_means(ds):
    """

    :param ds:
    :return:
    """

    # notify
    print('Reducing dataset scenes to temporal means.')

    # reduce via mean
    ds = ds.mean(['x', 'y'])

    # todo check if need attrs back on
    #

    # notify and return
    print('Reduced dataset scenes to temporal means.')
    return ds


def remove_outliers(ds, user_factor=2):
    """
    """

    # notify user
    print('Removing outliers via median spike.')

    # check if user factor provided
    if user_factor <= 0:
        raise TypeError('User factor is less than 0, must be above 0.')

    # calc cutoff val per pixel i.e. stdv of pixel multiply by user-factor
    cutoffs = ds.std('time') * user_factor

    # calc mask of existing nan values (nan = True) in orig ds
    ds_mask = xr.where(ds.isnull(), True, False)

    # calc win size via num of dates in dataset
    win_size = int(len(ds['time']) / 7)
    win_size = int(win_size / int(len(ds.resample(time='1Y'))))

    if win_size < 3:
        win_size = 3
        print('Generated roll window size less than 3, setting to default (3).')
    elif win_size % 2 == 0:
        win_size = win_size + 1
        print('Generated roll window size is an even number, added 1 to make it odd ({0}).'.format(win_size))
    else:
        print('Generated roll window size is: {0}'.format(win_size))

    # temp - bug in rolling, need to rechunk
    #ds = ds.chunk(-1)

    # calc rolling median for whole dataset
    #ds_med = ds.rolling(time=win_size, center=True, keep_attrs=True).median()
    ds_med = ds.rolling(time=win_size, center=True).median()

    # calc nan mask of start/end nans from roll, replace them with orig vals
    med_mask = xr.where(ds_med.isnull(), True, False)
    med_mask = xr.where(ds_mask != med_mask, True, False)
    ds_med = xr.where(med_mask, ds, ds_med)

    # calc abs diff between orig ds and med ds vals at each pixel
    ds_diffs = abs(ds - ds_med)

    # calc mask of outliers (outlier = True) where absolute diffs exceed cutoff
    outlier_mask = xr.where(ds_diffs > cutoffs, True, False)

    # shift values left and right one time index and combine, get mean and max for each window
    lefts = ds.shift(time=1).where(outlier_mask)
    rights = ds.shift(time=-1).where(outlier_mask)
    nbr_means = (lefts + rights) / 2
    nbr_maxs = xr.ufuncs.fmax(lefts, rights)

    # keep nan only if middle val < mean of neighbours - cutoff or middle val > max val + cutoffs
    outlier_mask = xr.where((ds.where(outlier_mask) < (nbr_means - cutoffs)) |
                            (ds.where(outlier_mask) > (nbr_maxs + cutoffs)), True, False)

    # flag outliers as nan in original da
    # ds = xr.where(outlier_mask, np.nan, ds)
    ds = ds.where(~outlier_mask)

    # notify user and return
    print('Outlier removal successful.')
    return ds

# working
def _():

    # get all available landsat ard items via stac query
    collections = ['ga_ls5t_ard_3', 'ga_ls7e_ard_3', 'ga_ls8c_ard_3', 'ga_ls8c_ard_provisional_3']
    # ['ga_s2am_ard_provisional_3', 'ga_s2bm_ard_provisional_3']
    from_date, to_date = '1990-01-01', '2021-12-31'                                                 # todo take this from ui
    bbox = [119.14814174547365, -22.787660685029387, 119.15026915790975, -22.786180542390234]       # todo take this from ui

    # query aws stac for available collection items
    items = query_stac(collections=collections,
                       from_date=from_date,
                       to_date=to_date,
                       bbox=bbox)

    # now build a dataset using all available items
    ds = build_dataset(items=items,
                       bbox=bbox,
                       crs='EPSG:4326',
                       resolution=10/111000,  # todo think bout this
                       like=None,
                       ignore_warnings=True)

    # mask out (remove) any invalid scenes
    ds = mask_invalid_scenes(ds=ds,
                             mask_var='mask',
                             valid=[1, 4, 5],
                             min_pct=1.0,
                             drop_mask=True)

    # calculate ndvi index
    ds = calculate_index(ds=ds,
                         index='NDVI',
                         drop_bands=True)

    # load the dataset all at same time (we only have one band)
    ds = load_dataset(ds=ds,
                      logic='all')


    # todo remove edge pixels via mask
    #

    # reduce down to one mean value per scene
    ds = get_temporal_means(ds)

    # todo perform ewmacd
    #

    # todo extract values from veg, change, conseqs, etc.
    #

    print(1)

    # convert to monitoria format
    #def extract_formatted_data():

        # reduce down to median of every datetime
        #ds = ds.mean(['latitude', 'longitude'])

        # get array of datetimes and associated vege mean values
        #arr_datetimes = np.array(ds['time'].dt.strftime('%Y-%m-%dT%H:%M:%S'))
        #arr_vege_means = ds['veg_idx'].data








    # convert datetime into non-tz & ms format, add back onto dataset
    #dts = ds['time'].dt.strftime('%Y-%m-%dT%H:%M:%S')



    # if we want to add back on to ds use this
    #dts = ds['time'].dt.strftime('%Y-%m-%dT%H:%M:%S')
    #ds['time'] = dts.astype('datetime64[ns]')






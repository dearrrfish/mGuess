# trendulate.py - Python wrapper for Trendulate REST API

import types
import requests
import json
import sys

trendulate_url = 'http://alpha.trendulate.com'

class TrendulateError(Exception):

    def __init__(self, error, message):
        self.error = error
        self.message = message

    def __str__(self):
        return "%s: %s" % (self.error, self.message)


class Trend(object):
    """Trendulate Trend object"""
    
    def __init__(self, tx, trend_path):
        self.tx = tx
        self.trend_path = trend_path
        self.trend = self.tx.get_helper('/api/2/trends' + trend_path)['trend']
        
    def properties(self):
        '''Return trend as a Python dictionary.'''
        return self.trend
        
    def count(self):
        '''Number of points in trend.'''
        return self.trend['total_points']

    def add_point(self, value, note=None, date=None):
        '''Add a new point to a trend.
        
        Simple form:
        
        t.add_point(9)
        
        This will add a single numeric value to the trend. This assumes
        that there is only one numeric value in the trend schema.  It uses
        the trend schema to determine the proper label value.  
        
        You can also add a note and give a specific date:
        
        t.add_point(11, note="Your note here", date="2011-12-01")
        
        The date must be a properly formatted ISO date string:
        
        Date only    : YYYY-MM-DD
        Date and time: YYYY-MM-DDTHH:MM:SS.mmmmmm 
        
        Multi-value points:
        
        t.add_point({"count": 9, "name": "Bob"})

        Note that the 
        '''
        
        id = self.trend['_id']

        if type(value) == types.DictType:
            payload = {'data': value}
        else:
            label = self.trend['schema'][0]['label']
            payload = {'data': { label: value} }

        if date:
            payload['date'] = date

        if note:
            payload['note'] = note

        self.tx.post_helper('/api/2/trends' + self.trend_path + '/points', payload)

    def add_points(self, points):
        '''Add a list of points to a Trend'''

        id = self.trend['_id']
        payload = points
        self.tx.post_helper('/api/2/trends' + self.trend_path + '/points', payload)

    def get_points(self, count=1, date=None):
        url = '/api/2/trends' + self.trend_path + '/points'
        params = { 'count': count }
        if date:
            params['date'] = date
        return self.tx.get_helper(url, params=params)['points']

    def get_points_all(self, count=1000):
        # Get first set
        all = []
        all.append(self.get_points(1))
        if not all[-1]:
            return []
        date = all[-1][0]['time_created']
        print date
        
        # Get chunks of points
        while True:
            points = self.get_points(1, date)
            if not points:
                break
            date = points[0]['time_created']
            all.append(points)

        # Combine all points in to single list
        points_all = []
        for i in range(len(all)-1, -1, -1):
            points_all.extend(all[i])
        return points_all
            

class Trendulate(object):
    """Trendulate connection object"""

    def __init__(self, username, password, url=None):
        self.username = username
        self.password = password
        
        if not url:
            self.url = trendulate_url
        else:
            self.url = url

        if self.url.endswith('/'):
            self.url = self.url[:-1]

        self.auth = (self.username, self.password)
        
        # Issue a profile access to make sure we can connect to the
        # Trendulate server.
        # p = self.get_profile()
        

    def get_helper(self, path, params=None):
        if not params:
            params = {}

        r = requests.get(self.url + path, params=params, auth=self.auth)

        if r.status_code is not requests.codes.ok:
            json_data = json.loads(r.content)
            if json_data.has_key('error'):
                message = json_data.get('message', '')
                raise TrendulateError(json_data['error'] + ' FROM TORNADO', message)
            r.raise_for_status()
        
        json_data = json.loads(r.content)
        return json_data

    def post_helper(self, path, payload):
        r = requests.post(self.url + path, auth=self.auth, data=json.dumps(payload))
        if r.status_code is not requests.codes.ok:
            # raise Exception(r.content)
            try:
                json_data = json.loads(r.content)
            except Exception, e:
                raise Exception(r.content)
                return
                
            if json_data.has_key('error'):
                message = json_data.get('message', '')
                raise TrendulateError(json_data['error'], message)
            r.raise_for_status()

        json_data = json.loads(r.content)
        return json_data

    def get_profile(self):
        return self.get_helper('/api/2/account/profile')['profile']

    def get_following(self):
        return self.get_helper('/api/2/following')['following']

    def get_trend(self, trend_path):
        return Trend(self, trend_path)

    def create_trend(self, trend_path, schema, description='', note='', privacy='private'):
        trend_name = trend_path.replace('-', ' ')
        
        payload = { 'schema': schema, 'description': description, 'note': note, 'privacy': privacy }
        
        r = self.post_helper('/api/2/trends' + trend_path, payload)
        return r
    
    def add_point(self, trend_path, value, note=None, date=None):
        '''Add a new point to a trend directly.'''
    
        payload = {'data': value}

        if date:
            payload['date'] = date

        if note:
            payload['note'] = note

        self.post_helper('/api/2/trends' + trend_path + '/points', payload)


def test_api(username, password):
    tx = Trendulate(username, password)

    # Get your user profile
    profile = tx.get_profile()
    print '=== Trendulate User Profile'
    print profile
    print

    # Get the trends you are following
    print '=== Trends you are following'
    following = tx.get_following()
    for trend in following:
        print trend
    print

    # Get trendpoint counts from all trends
    print '=== Trendpoint counts'
    for trend in following:
        t = tx.get_trend(trend)
        print "%s (%d)" % (trend, t.count())
    print
    
    # See if TestTrend exist
    trend_path = '/u/' + username + '/TestTrend'
    try:
        t = tx.get_trend(trend_path)
        print t.properties()
    except TrendulateError:
        print 'CREATE'
        t = tx.create_trend(trend_path, [{ 'label' : 'time', 'unit' : 'seconds', 'type' : 'numeric'}])
            
    # Get a trend
    t = tx.get_trend(trend_path)
    print t.properties()
    print


    points = t.get_points()
    print len(points)
    if len(points) == 0:
        last_value = 0
    else:
        last = points[-1]
        last_value = last['data']['time']

    print last_value
    
    t.add_point(last_value + 1)
    
    points = t.get_points()
    last = points[-1]
    print last
    print len(points)


def test_multi(username, password):
    tx = Trendulate(username, password)
    # Get trendpoint counts from all trends
    
    # See if TestMulti exist
    trend_path = '/u/' + username + '/TestMulti'
    try:
        t = tx.get_trend(trend_path)
        print t.properties()
    except TrendulateError:
        print 'CREATE'
        t = tx.create_trend(trend_path, [{ 'label': 'event', 'unit': 'count', 'type': 'numeric'},
                                        { 'label': 'desc', 'unit': 'none', 'type': 'string'}])
            
    # Get a trend
    t = tx.get_trend(trend_path)
    print t.properties()
    print
    
    points = t.get_points()
    print len(points)
    if len(points) == 0:
        last_value = 0
    else:
        last = points[-1]
        last_value = last['data']['event']

    print last_value
    
    t.add_point({'event': last_value + 1, 'desc': 'item %d' % (last_value + 1)})
    
    points = t.get_points()
    last = points[-1]
    print last
    print len(points)


def test_multi_list(username, password):
    tx = Trendulate(username, password)
    # Get trendpoint counts from all trends
    
    # See if TestMulti exist
    trend_path = '/u/' + username + '/TestMultiList'
    try:
        t = tx.get_trend(trend_path)
        print t.properties()
    except TrendulateError, e:
        print 'CREATE'
        t = tx.create_trend(trend_path, [{ 'label': 'event', 'unit': 'count', 'type': 'numeric'},
                                        { 'label': 'mylist', 'unit': 'none', 'type': 'list'}])
            
    # Get a trend
    t = tx.get_trend(trend_path)
    print t.properties()
    print
    
    points = t.get_points()
    print len(points)
    if len(points) == 0:
        last_value = 0
    else:
        last = points[-1]
        last_value = last['data']['event']

    print last_value
    
    t.add_point({'event': last_value + 1, 'mylist': ['item %d' % (last_value + 1), 'foo', 'bar']})
    
    points = t.get_points()
    last = points[-1]
    print last
    print len(points)
    

def test_bulk_upload(username, password):
    tx = Trendulate(username, password)

    # See if TestTrend exist
    trend_path = '/u/' + username + '/TestBulk'
    try:
        t = tx.get_trend(trend_path)
        print t.properties()
    except TrendulateError:
        print 'CREATE'
        t = tx.create_trend(trend_path, [{ 'label' : 'time', 'unit' : 'seconds', 'type' : 'numeric'}])
            
    # Get a trend
    t = tx.get_trend(trend_path)
    print t.properties()
    print

    points = [{'data':{'time': 1}, 'date': '2012-01-01'},
              {'data':{'time': 2}, 'date': '2012-01-02'},
              {'data':{'time': 3}, 'date': '2012-01-03'}]

    t.add_points(points)
    
    points = t.get_points()
    print len(points)
    if len(points) == 0:
        last_value = 0
    else:
        last = points[-1]
        last_value = last['data']['time']
    
    
def test_error(username, password):
    tx = Trendulate(username, password)

    # See if TestTrend exist
    trend_path = '/u/' + username + '/FooBar'
    tx.add_point(trend_path, {'time': 1.0})



def test_get_count(username, password):
    tx = Trendulate(username, password)

    # See if TestMulti exist
    trend_path = '/u/' + username + '/TestMulti'
    try:
        t = tx.get_trend(trend_path)
        #print t.properties()
    except TrendulateError:
        print 'Need to create %s' % (trend_path)
        sys.exit(1)


    # Get a trend
    t = tx.get_trend(trend_path)
    print t.properties()
    print

    points = t.get_points(count=10)
    print points

def test_get_all(username, password):
    tx = Trendulate(username, password)

    trend_path = '/u/' + username + '/TestTrend'
    try:
        t = tx.get_trend(trend_path)
    except TrendulateError:
        print 'Need to create %s' % (trend_path)
        sys.exit(1)

    # Get a trend
    t = tx.get_trend(trend_path)

    points = t.get_points_all()
    print points
    points2 = t.get_points_all(count=1)
    print points == points2
    
if __name__ == '__main__':
    username = 'dearrrfish'
    password = 'momo88415'
    test_api(username, password)
    #test_multi(username, password)
    #test_multi_list(username, password)
    #test_bulk_upload(username, password)
    #test_error(username, password)
    #test_get_count(username, password)
    #test_get_all(username, password)

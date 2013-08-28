#!/usr/bin/env python
#
# Copyright 2007 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
import webapp2
import urllib2
import json
from google.appengine.api import urlfetch
from collections import defaultdict
#from trendulate import Trend,Trendulate


class MainHandler(webapp2.RequestHandler):


	def get(self):
		#'2012-04-19 19:08:33'
		#2012-04-20 14:07:12 drive
		timestamp = self.request.get('timestamp', 'null')
		if timestamp == 'null':
			self.response.out.write('ERROR - No tiemstamp received.')
			return

		# 'Using urllib2'
		# req = urllib2.Request(TREND_URL)
		# respon = urllib2.urlopen(req)
		# jsonstr = respon.read()

		# 'Using URLFetch'
		respon = urlfetch.fetch(TREND_URL, method=urlfetch.GET, deadline=120)
		if respon.status_code == 200:
			jsonstr = respon.content
		else:
			responsestr = 'ERROR - Fetch points error.'
			self.response.out.write(responsestr)
			return


		allpoints = json.loads(jsonstr)
		points = filterPoints(allpoints, timestamp)


		responsestr = ''
		## test print output
		# responsestr += '<html><body>'
		# responsestr += '<p>mGuess Timestamp: %s</p>' % timestamp
		# responsestr += '<table>'

		# if len(points) <= 0:
		# 	responsestr += '<tr><td>No available points found.</td></tr>'
		# else:
		# 	responsestr += '<tr align="center"><td>POINT</td><td>ORIENTATION</td><td>LOCATION</td><td>SPEED</td>'
		# 	responsestr += '<td>NETWORK</td><td>SOUND</td><td>PROXIMITY</td></tr>'


		# for point in points:
		# 	cnt = point['CountIndex']
		# 	orient = point['DeviceOrientation']
		# 	lng = point['Longitude']
		# 	lat = point['Latitude']
		# 	spd = point['Speed']
		# 	network = point['Network']
		# 	sndavg = point['SoundAveragePower']
		# 	sndpeak = point['SoundPeakPower']
		# 	proximity = point['Proximity']

		# 	responsestr += '<tr align="center">'
		# 	responsestr += '<td>%d</td>' % cnt
		# 	responsestr += '<td>%s</td>' % orient
		# 	responsestr += '<td>(%f,%f)</td>' % (lng, lat)
		# 	responsestr += '<td>%f</td>' % spd
		# 	responsestr += '<td>%s</td>' % network
		# 	responsestr += '<td>(%f,%f)</td>' % (sndavg, sndpeak)
		# 	responsestr += '<td>%d</td>' % proximity
		# 	responsestr += '</tr>'

		# responsestr+= '</table>'

		# data analysis start
		thresholds = initThresholds()
		movements = checkMovement(points, thresholds)
		inouts = checkInout(points, movements)
		callevent = checkCallEvent(points, thresholds)

		# init result format
		result = {'REST':0, 'WALK':0, 'RUN':0, 'DRIVE':0, 'INTERIOR':0, 'OUTDOOR':0, 'CALL':0}
		
		lastptr = -1
		for m in movements:
			result[m[0]] += (m[1] - lastptr)
			lastptr = m[1]

		lastptr = -1
		for io in inouts:
			result[io[0]] += (io[1] - lastptr)
			lastptr = io[1]

		result['CALL'] = callevent


		# responsestr += '<p>Movement Guess</p>'
		# lastptr = 0
		# for m in movements:
		# 	responsestr += '<p>' + m[0] + ' from %d to %d</p>' % (lastptr, m[1])
		# 	lastptr = m[1] + 1

		# responsestr += '<p>Interior Guess</p>'
		# lastptr = 0
		# for io in inouts:
		# 	responsestr += '<p>' + io[0] + ' from %d to %d</p>' % (lastptr, io[1])
		# 	lastptr = io[1] + 1

		# responsestr += '<p>Call Event Guess: '
		# if callevent == 0 :
		# 	responsestr += 'NONCALL'
		# elif callevent == 1 :
		# 	responsestr += 'NORMAL'
		# elif callevent == 2 :
		# 	responsestr += 'SPEAKER'
		# responsestr += '</p>'

		trest = float(result['REST']) / 2.0
		twalk = float(result['WALK']) / 2.0
		trun = float(result['RUN']) / 2.0
		tdrive = float(result['DRIVE']) / 2.0
		tinterior = float(result['INTERIOR']) / 2.0
		toutdoor = float(result['OUTDOOR']) / 2.0

		responsestr += 'REST:%.1fs WALK:%.1fs RUN:%.1fs DRIVE:%.1fs ' % (trest, twalk, trun, tdrive)
		responsestr += 'INTERIOR:%.1fs OUTDOOR:%.1fs ' % (tinterior, toutdoor)
		
		responsestr += 'CALL:'
		if callevent == 0 :
			responsestr += 'None'
		elif callevent == 1 :
			responsestr += 'Normal'
		elif callevent == 2 :
			responsestr += 'Speaker'


		self.response.out.write(responsestr)


def filterPoints(jsonstr, timestamp):
	points = list()
	mark = False
	for p in jsonstr:
		data = p['data']
		if data['Timestamp'] == timestamp:
			mark = True
			points.append(data)
		elif mark :
			break

	sorted_points = sorted(points, key=lambda k: k['CountIndex'])
	return sorted_points

# check movement state

def classifySpeed(speed):
	if speed < 0.5:
		return 'REST'
	elif speed < 2:
		return 'WALK'
	elif speed < 7:
		return 'RUN'
	elif speed >= 7:
		return 'DRIVE'

def preCheckMovement(points, start, state, acc, oor):
	if start + acc > len(points):
		return False

	oor_v = 0
	for x in xrange(0,acc-1):
		point = points[start+x]
		state_v = classifySpeed(point['Speed'])
		if state_v != state:
			oor_v += 1
			if oor_v > oor:
				return False
	return True


def checkMovement(points, thresholds):
	move_states = []
	ptr = 0
	state = classifySpeed(points[ptr]['Speed'])
	# init state
	pair = (state, ptr)
	move_states.append(pair)

	while ptr<len(points):
		new_state = classifySpeed(points[ptr]['Speed'])
		if  new_state != state:
			state_change = state + '_' + new_state
			try:
				acc = thresholds[state_change + '_ACC']
				oor = thresholds[state_change + '_OOR']
			except:
				ptr += 1
				# print state_change + ' at %d failed.\n' % ptr

				continue
			# true, state change
			if preCheckMovement(points, ptr, new_state, acc, oor):
				ptr += acc - 1
				state = new_state
				pair = (state, ptr)
				if ptr == 0:
					move_states[0] = pair
				else:
					move_states.append(pair)		
		
		# move_states[len(move_states)-1][1] = ptr
		pair = (state, ptr)
		move_states[len(move_states)-1] = pair
		ptr += 1
	# fix end out-of-range situation
	# pair = (state, len(points)-1)
	# move_states[len(move_states)-1] = pair

	return move_states


# check interior/outdoor
def pickPoints(points, start, end):
	picked = []
	for x in xrange(start, end):
		picked.append(points[x])
	return picked

def queryLocInfo(point):
	locs = defaultdict(list)

	lat = point['Latitude']
	lng = point['Longitude']
	# plist = set()
	gurl = GMAP_API_URL + 'location=%d,%d&radius=50&sensor=false&key=%s' % (lat,lng,GMAP_API_KEY)
	placesrespon = urlfetch.fetch(gurl, method=urlfetch.GET, deadline=30)
	if placesrespon.status_code == 200:
		placesjson = placesrespon.content
		presults = json.loads(placesjson)['results']
		for r in presults:
			# plist.add(r['name'])
			locs[r['name']] = r['types']

	return locs


def classifyPointsConnLoc(points):
	conns = defaultdict(int)
	for p in points:
		conns[p['Network']] += 1

	stable_conn = '<UNKNOWN>'
	for c in conns:
		if conns[c] > (len(points)/2):
			stable_conn = c
	
	#locations
	locs1 = queryLocInfo(points[0])
	locs2 = queryLocInfo(points[len(points)-1])

	locsall = dict(locs1, **locs2)
	locssame = []
	differlocs = 0
	loctypes = []
	for l in locsall:
		if (l not in locs1) | (l not in locs2):
			differlocs += 1
		else:
			locssame.append(l)

		print l


	in_cnt = 1
	out_cnt = 1
	inout_rate = 1.0
	if (float(differlocs)/float(len(locsall)) < 0.5):
		for s in locssame:
			types = locsall[s]
			for t in types:
				ikey_mark = False
				okey_mark = False
				for ikey in INTERIOR_KEYWORDS:
					if ikey in t:
						in_cnt += 1
						ikey_mark = True
						break
				for okey in OUTDOOR_KEYWORDS:
					if okey in t:
						out_cnt += 1
						okey_mark = True
						break
				if ikey_mark | okey_mark:
					break
		inout_rate = float(in_cnt) / float(out_cnt)

	pair = (stable_conn, inout_rate)

	return pair


def checkInout(points, move_states):
	inout_states = []
	connset = set(['<UNKNOWN>', '<3G>', '<NA>'])
	start = 0
	for m in move_states:
		end = m[1]
		if (m[0] == 'DRIVE') | (m[0] == 'RUN'):
			state = 'OUTDOOR'
		else:
			picked = pickPoints(points, start, end)
			connloc = classifyPointsConnLoc(picked)
			conn_score = 0.0
			if connloc[0] not in connset:
				conn_score = 2.0
			else:
				conn_score = 0.1
			final_score = conn_score * connloc[1]
			if final_score > 0.5:
				state = 'INTERIOR'
			else:
				state = 'OUTDOOR'
		pair = (state, end)
		inout_states.append(pair)
		start = end+1
	return inout_states


# check calling event. 0 - NONCALL, 1 - NORMAL, 2 - SPEAKER
def checkCallEvent(points, thresholds):
	call = False
	cntPeak = 0
	cntZero = 0
	cntCollection = 0
	cntNormal = 0
	cntSpeaker = 0
	lastavailable = 0
	# check through all points
	for p in points:
		if p['SoundPeakPower'] > thresholds['SOUND_VALUE_BOARD']:
			cntPeak += 1
			if p['SoundPeakPower'] > -1: # use -1 instead of 0 to give more tolerant result
				cntZero += 1

			if p['Proximity'] == 1 & p['DeviceOrientation'] == 1:
				cntNormal += 1
			else:
				cntSpeaker += 1

			if lastavailable == 0:
				lastavailable = 1
				cntCollection += 1
		else:
			lastavailable = 0

	if ((float(cntPeak)/float(len(points))) >= thresholds['SOUND_PEAK_PERCENT']) \
			& ((float(cntZero)/float(cntPeak)) < thresholds['SOUND_ZERO_PERCENT']) \
			& (cntCollection >= thresholds['SOUND_COLLECTION_NUM']):
		if cntNormal >= cntSpeaker :
			return 1
		else :
			return 2
	else :
		return 0



def initThresholds():
	thresholds = {'REST_WALK_ACC' : 10, 'REST_WALK_OOR' : 2, \
		'REST_RUN_ACC' : 10, 'REST_RUN_OOR' : 2, \
		'REST_DRIVE_ACC' : 20, 'REST_DRIVE_OOR' : 10, \
		'WALK_REST_ACC' : 10, 'WALK_REST_OOR' : 4, \
		'WALK_RUN_ACC' : 10, 'WALK_RUN_OOR' : 2, \
		'RUN_REST_ACC' : 10, 'RUN_REST_OOR' : 4, \
		'RUN_WALK_ACC' : 10, 'RUN_WALK_OOR' : 4, \
		'DRIVE_REST_ACC' : 20, 'DRIVE_REST_OOR' : 6, \
		'DRIVE_WALK_ACC' : 20, 'DRIVE_WALK_OOR' : 6, \
		'SOUND_VALUE_BOARD' : -10, 'SOUND_PEAK_PERCENT' : 0.25, \
		'SOUND_ZERO_PERCENT' : 0.25, 'SOUND_COLLECTION_NUM' : 3 \
		}
	return thresholds

TREND_URL = 'http://alpha.trendulate.com/u/dearrrfish/mGuess/points'
GMAP_API_URL = 'https://maps.googleapis.com/maps/api/place/search/json?'
GMAP_API_KEY = 'AIzaSyCuZk9xHF0ecFWYauCfXE0d_Jnx0pq-Nyg'
INTERIOR_KEYWORDS = set(['bank', 'bar', 'cafe', 'church', 'store', 'university', 'library', 'room'])
OUTDOOR_KEYWORDS = set(['atm', 'park', 'station', 'zoo', 'route', 'street', 'bus'])

app = webapp2.WSGIApplication([('/', MainHandler)],
                              debug=True)

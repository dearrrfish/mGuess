mGuess
======

Track phone status to guess user's activities. (CS685@USF Project)


Project Proposal
-----------------
Simple Activity Recognition Project
Project: mGuess
Developer: Yu Jin

Description:
For this project, I will build a simple phone-web interactive system to recognize user’s activities. The system divided into two parts. 
Phone as the sensor mote, when the app is on an active state, keep tracking user’s information, such as movement, location, internet connection, and interactive state with phone itself, which would be collected and sent to trendulate. 
Cloud processing partition will be built on GAE app engine. A simple python program will fetch data from trendulate when it received a signal and timestamps from phone-app. After analyze sensing data by a predefined algorithm, conclusion will be sent back to phone.
As long as received analysis feedback, phone app will activate a notification to user to ask if the guess is correct. The ground truth record will be also send to trendulate.

Aimed activities:
Walking/Running/Driving/Rest
Interior/(maybe)Outside
Phone Context

Platforms/Devices:
iPhone 4S (iOS 5.01) - Xcode - Objective-C
Google App Engine - Python

Functions and schedule:
(See schedule sheet)

Algorithms/Considerations:
Movement and Location:
These two sensing data are used to determine user’s movement status. The reason I add accelerometer sensor is concerned for power saving. Only if accelerometer detect great change in speed, comparing with certain thresholds, the GPS will be turned on and watch the location change, get speed to determine status (also need thresholds for distinction).
Reminder: for each piece of accelerometer data set, only two larger ones of x-y-z three axes is meaningful.

Connection:
Firstly connection check is necessary base requirements for sending and fetching data for phone app. Secondly, stability of a same WiFi connection is also an important evidence of being interior.

Sound and Light:
If light sensor detects a proximity behavior, it will start to watch sound powers(average and peak) in following time interval, for guessing if user is making a phone call, or not, that is for instance the phone is inside a pocket. However, obviously, this mechanism can do nothing with speaking mode.

Power saving considerations:
As a test project, I would not implement long time background running. I plan to use background task where necessary, which has up to 10 minutes life time that is enough for data collecting goals.
Accelerometer and light sensor are two base starting sensors to detect events. If neither of them detect valuable changes in certain interval, connection check will be on to provide evidence of whether is interior. And at any time if either of them detects an event, all other sensor will be activated to do their own stuff.

Lifetime and intervals:
Data collect lifetime: 30 sec 2 min
Accelerometer: detect per 0.1 sec
Location: store every location change and speed under a high accuracy mode.
Connection: per 5  3 sec
Sound: per 0.5 sec
Light: every proximity state change

Trends:
All trends are MultiSchemeTrends, contains an Index number and data set.
Index number is used as what timestamp do to determine which point among all is the one request need. This number will be also sent to cloud server when phone app start a request.
(v2) Index Number: Easiest way is just use an start Timestamp

(v2)Sensing:
Accelerometer: two main detecting factors.
Moving: when a movement event is detected, activate GPS sensor.  (it seems to complicate the problem. As short as 2 min of total record time and manually controlled steps, so energy efficiency is not a big problem in fact. Location update will stop if recording process is finished.)
Device orientation: record current device orientation (for phone context guessing).
Location(GPS):
	When app start, GPS will be turned on to record current location information(lng and lat), in variables, and then be turned off, and wait for accelerometer to wake it up. Every time a location change is detected, it update new location information(lng, lat and speed) information in variables. When REST event lasts more than time threshold, it goes to sleep and wait next movement event from accelerometer.
Connection:
	Simply record current connection information, 3G or WiFi(SSID) or Non-connection.
Sound:
	Record average and peak powers. If powers reach some threshold, a calling event activated, then check proximity to determine whether speaker mode or not.
Proximity:
	On/Off. Serving sound events.

(v2)Trend details:
Single trend: After cost time experiments during test code development, it is more helpful to easier data fetching and processing to using single trend for all sensor data than separate trends for different sensors.
Data points interval: Every 0.5 second.
Data structure: [Index] [Device orientation] [Latitude, Longitude] [Speed] [Connection] [Avg, peak sound power] [Proximity] (see trend point data detail sheet)



Cloud process algorithms:
Walking/Running/Driving/Rest: mainly determined by speed
Rest < 0.5 meters/sec(m/s)
Walking < 3 2 m/s
Running < 10 7 m/s
Driving > 10 7 m/s
Interior/(maybe)Outside: this is a very rough estimation with limitations of networks.
speed < 3 2 m/s && stable WiFi connection
Phone Context：
Calling: proximity state is yes and jitter of sound peak and average power larger than thresholds(need to be determined while developing) 
InPocket: proximity state is yes and jitter of sound peak and average power less than thresholds (need to be determined while developing)

(v2)Apple public API of iOS does not allow background microphone utilization. Another way to utilize microphone sensor is need to be figured out. As a result my app cannot do some real-calling event detection using microphone sensor in background. Being a pure foreground app, my temporary decision for simulating implementation of this feature is to pretend fake calling action manually.

(v2)Accumulative value of sensor data:
I decided to choose an accumulative value to determine if an event is activated. If data collected by sensors meet all required thresholds for an event, the value++; when value reaches an determined size, it is considered as a reasonable evidence for the event.

(v2)Algorithms in details:
To simplify data sending process and avoiding potential network connection problem, data is collected into an array structure and sent together at one time after recording step. 
Also, to reduce sending time, all N points are sent concurrently, so points might be appeared disorderly on trend. Web server will read all points within requested timestamp, and start a sorting process before data analysis by key of “CountIndex”.
Time interval between two neighbouring points is 0.5 sec.

1. Movement:
Current state: REST/WALK/RUN/DRIVE
Start state: REST
State change: if new speed is in range of another state, the changing of Current state -> Another State process is on.
State change condition:
 (How many accumlative count need from one state to another / Acceptable out-of-range times)
	REST->WALK: 10/2
	REST->RUN: 10/2
	REST->DRIVE: 20/10
	WALK->REST: 10/4
WALK->RUN: 10/2
	RUN->REST: 10/4
	RUN->WALK: 10/4
	DRIVE->REST: 20/6
	DRIVE->WALK:20/6

2. Interior:
Current state: INTERIOR/OUTDOOR/UNKNOWN
Start state: UNKNOWN
State change: Check state of movement & connection (Caution: connection check interval is 3 secs, that means data of 6 neighbour points will be the same.)
	INTERIOR: REST/WALK + Stable Wi-Fi
	OUTDOOR: 3G/NoConnection/DRIVE/RUN
State change conditions:
	INTERIOR->OUTDOOR: (4/1) * 6
OUTDOOR->INTERIOR: (4/1) * 6
Google Places API: TODO using Latitude and Longitude data to get places information frome Google Places API, to help to better interior/outdoor recognition.
BAD NEWS: Google Map API have limited query times per day at 1000 for free account.

3. Calling:
Current state: NONCALL/NORMAL/SPEAKER
Start state: NONCALL
State change: check sound power peaks, if peak > -5dB (seems reasonable in experiment, might be adjusted in future development) , accumulative value++
Sound powers will confuse when user is on street with busy traffic. Some filter schemas needed. eg. If continuously has peak powers value 0(max), it is more likely on a street or other situations than speaking a phone call.

To filter useless situations, final mechanism is:
p = (peak>-10dB)%
p0 = (peak == 0dB in p)%
n = number of collections of continuous evident peaks

if p > 25% && p0 < 50% && n > 3 (simplest conversion: “Hello.” “OK.” “Bye.”)
CALL
if Proximity ==1 && Portrait = 1
NORMAL
else
SPEAKER
else
	NONCALL

State change conditions:
	NONCALL->NORMAL/SPEAKER: 10/5
	NORMAL/SPEAKER->NONCALL: 10/2
	NORMAL: Proximity = 1 & Portrait = 1
	SPEAKER: Proximity = 0
	

Possible learning mechanisms:
(Consider in future)


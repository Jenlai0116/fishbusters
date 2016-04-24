local composer = require( "composer" )
local sqlite3 = require( "sqlite3" )

--開啟資料庫"data.db"，若未存在則新建一個
local path = system.pathForFile( "data.db", system.DocumentsDirectory )
local db = sqlite3.open( path )

--若資料表不存在則新建一個-公用變數表
local tablesetup = [[CREATE TABLE IF NOT EXISTS keyTable (id INTEGER PRIMARY KEY, key, val INTEGER);]]
db:exec( tablesetup )
--若資料表不存在則新建一個-記時記錄表
local tablesetup = [[CREATE TABLE IF NOT EXISTS timeTable (id INTEGER PRIMARY KEY, time, date2 DATETIME, group1 INT, group2 INT, money INT, ps, gpslat, gpslong, good, bed);]]
db:exec( tablesetup )
--若資料表不存在則新建一個-記時分類表
local tablesetup = [[CREATE TABLE IF NOT EXISTS timeGroupTable (id INTEGER PRIMARY KEY, g1, g2, name);]]
db:exec( tablesetup )
if db:errcode() ~= 0 then
	print(db:errcode(), db:errmsg())
end
--關閉程式時關閉資料庫
local function onSystemEvent( event )
	if ( event.type == "applicationExit" ) then
		db:close()
	end
end
Runtime:addEventListener( "system", onSystemEvent )

--隱藏系統狀態列
display.setStatusBar( display.HiddenStatusBar )

--取得系統日期
local date = os.date('*t')

--公用變數:全部
allTable = {}
allTable.viewNo = 0

--公用變數:漁具
timeTable = {}
timeTable.year = date.year
timeTable.month = date.month
timeTable.day = date.day

timeTable.money = 0
timeTable.moreTime = 0
timeTable.group1Array = {}
timeTable.group1 = 0 --初始值
timeTable.group1Colors = {{1,0.7,0.7},{1,1,0.5},{0.7,1,0.7},{0.5,1,1},{0.7,0.7,1},{1,0.5,1},{0.9,0.8,0.7},{0.8,0.9,0.7},{0.7,0.8,0.9},{0.9,0.7,0.8}} --10組
timeTable.group2Array = {{},{},{},{},{},{},{},{},{},{}} --10組
timeTable.group2 = 0
timeTable.timeText = ""
timeTable.latitudeText = ""
timeTable.longitudeText = ""

timeTable.recordShowTime = 0
timeTable.recordID = 0
timeTable.recordMoney = 0
timeTable.recordGroup1 = 0
timeTable.recordGroup2 = 0
timeTable.recordPs = ""
timeTable.recordGpsLat = ""
timeTable.recordGpsLong = ""
timeTable.recordGood = 0
timeTable.recordBed = 0

--漁具:更新群組表
function  updateTimeGroupArray()
	--取出資料表
	local ig1 = 1
	local ig2 = 1
	local i = 0
	for row in db:nrows("SELECT * FROM timeGroupTable ORDER BY g1 ASC, g2 ASC") do
		--print(row.id..",g1="..row.g1..",g2="..row.g2..",name="..row.name)
		ig1 = tonumber(row.g1)
		ig2 = tonumber(row.g2)
		if ig1 == 0 then --群組1
			timeTable.group1Array[ig2] = row.name
		else
			timeTable.group2Array[ig1][ig2] = row.name
		end
		i = i+1
	end
	--若為空白表格，新增預設分類
	if i == 0 then
		--寫入分類至資料表 g1=0
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,0,1,'曳網'),(NULL,0,2,'定置網'),(NULL,0,3,'刺網'),(NULL,0,4,'籠子'),(NULL,0,5,'自訂'),(NULL,0,6,'自訂'),(NULL,0,7,'自訂'),(NULL,0,8,'自訂'),(NULL,0,9,'自訂'),(NULL,0,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=1
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,1,1,'單船拖網'),(NULL,1,2,'雙船拖網'),(NULL,1,3,'衍拖網'),(NULL,1,4,'扒網'),(NULL,1,5,'搖鐘網'),(NULL,1,6,'地曳網'),(NULL,1,7,'自訂'),(NULL,1,8,'自訂'),(NULL,1,9,'自訂'),(NULL,1,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=2
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,2,1,'待網'),(NULL,2,2,'大敷網'),(NULL,2,3,'大謀網'),(NULL,2,4,'落網'),(NULL,2,5,'張網'),(NULL,2,6,'自訂'),(NULL,2,7,'自訂'),(NULL,2,8,'自訂'),(NULL,2,9,'自訂'),(NULL,2,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=3
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,3,1,'浮刺網'),(NULL,3,2,'底刺網'),(NULL,3,3,'流刺網'),(NULL,3,4,'圍刺網'),(NULL,3,5,'三重刺網'),(NULL,3,6,'自訂'),(NULL,3,7,'自訂'),(NULL,3,8,'自訂'),(NULL,3,9,'自訂'),(NULL,3,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=4
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,4,1,'龍蝦籠'),(NULL,4,2,'補魚籠'),(NULL,4,3,'自訂'),(NULL,4,4,'自訂'),(NULL,4,5,'自訂'),(NULL,4,6,'自訂'),(NULL,4,7,'自訂'),(NULL,4,8,'自訂'),(NULL,4,9,'自訂'),(NULL,4,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=5
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,5,1,'自訂'),(NULL,5,2,'自訂'),(NULL,5,3,'自訂'),(NULL,5,4,'自訂'),(NULL,5,5,'自訂'),(NULL,5,6,'自訂'),(NULL,5,7,'自訂'),(NULL,5,8,'自訂'),(NULL,5,9,'自訂'),(NULL,5,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=6
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,6,1,'自訂'),(NULL,6,2,'自訂'),(NULL,6,3,'自訂'),(NULL,6,4,'自訂'),(NULL,6,5,'自訂'),(NULL,6,6,'自訂'),(NULL,6,7,'自訂'),(NULL,6,8,'自訂'),(NULL,6,9,'自訂'),(NULL,6,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=7
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,7,1,'自訂'),(NULL,7,2,'自訂'),(NULL,7,3,'自訂'),(NULL,7,4,'自訂'),(NULL,7,5,'自訂'),(NULL,7,6,'自訂'),(NULL,7,7,'自訂'),(NULL,7,8,'自訂'),(NULL,7,9,'自訂'),(NULL,7,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=8
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,8,1,'自訂'),(NULL,8,2,'自訂'),(NULL,8,3,'自訂'),(NULL,8,4,'自訂'),(NULL,8,5,'自訂'),(NULL,8,6,'自訂'),(NULL,8,7,'自訂'),(NULL,8,8,'自訂'),(NULL,8,9,'自訂'),(NULL,8,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=9
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,9,1,'自訂'),(NULL,9,2,'自訂'),(NULL,9,3,'自訂'),(NULL,9,4,'自訂'),(NULL,9,5,'自訂'),(NULL,9,6,'自訂'),(NULL,9,7,'自訂'),(NULL,9,8,'自訂'),(NULL,9,9,'自訂'),(NULL,9,10,'自訂'); ]]
		db:exec( sql )
		--寫入分類至資料表 g1=10
		local sql = [[INSERT INTO timeGroupTable VALUES (NULL,10,1,'自訂'),(NULL,10,2,'自訂'),(NULL,10,3,'自訂'),(NULL,10,4,'自訂'),(NULL,10,5,'自訂'),(NULL,10,6,'自訂'),(NULL,10,7,'自訂'),(NULL,10,8,'自訂'),(NULL,10,9,'自訂'),(NULL,10,10,'自訂'); ]]
		db:exec( sql )
		updateTimeGroupArray()
	end
end

composer.gotoScene( "sceneCalendarTime" ) --漁具畫面

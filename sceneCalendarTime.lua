local widget = require( "widget" )
local composer = require( "composer" )
local sqlite3 = require( "sqlite3" )
local scene = composer.newScene()

--開啟資料庫"data.db"，若未存在則新建一個
local path = system.pathForFile( "data.db", system.DocumentsDirectory )
local db = sqlite3.open( path )
---------------------------------------------------------------------------------

local calendarView
local dayMoneyListView
local moreTimeText
local groupSelectbtn
local moneyInputbtn

--選擇分類:按下返回按鈕
function closeSelectGroupBtnPress2 ( event )
	composer.hideOverlay( "zoomOutIn", 100 )

	if timeTable.group2 ~= 0 then

		groupSelectbtn:setLabel( timeTable.group1Array[timeTable.group1].." / "..timeTable.group2Array[timeTable.group1][timeTable.group2] )
	else
		timeTable.group1 = 0
		timeTable.group2 = 0
		groupSelectbtn:setLabel( "✍選擇分類.." )
	end
end

--花費時間:按下返回按鈕
function closeSelectTimeBtnPress ( event )
	composer.hideOverlay( "zoomOutIn", 100 )
	if timeTable.money > 0 then
		moneyInputbtn:setLabel( math.floor(timeTable.money/60).."時"..math.fmod(timeTable.money,60).."分" )
	else
		moneyInputbtn:setLabel( "花費時間" )
	end
end

function scene:create( event )
    local sceneGroup = self.view
	
	
end

function scene:show( event )
    local sceneGroup = self.view
    local phase = event.phase

	if phase == "will" then
		updateTimeGroupArray() --更新日記群組表
		
		--定位資料讀取
		local locationHandler = function( event )
			-- Check for error (user may have turned off Location Services)
			if event.errorCode then
				native.showAlert( "GPS Location Error", event.errorMessage, {"OK"} )
				print( "Location error: " .. tostring( event.errorMessage ) )
			else
				--更新記錄時間
				--local date = os.date( "*t" )
				--dataTable.timeText = date.year.."-"..string.format('%02d',date.month).."-"..string.format('%02d',date.day).." "..string.format('%02d',date.hour)..":"..string.format('%02d',date.min)..":"..string.format('%02d',date.sec)
				--更新記錄經度
				if event.latitude == nil then
					timeTable.latitudeText = ""
				else
					timeTable.latitudeText = string.format( '%.6f', event.latitude )
				end
				--更新記錄緯度
				if event.longitude == nil then
					timeTable.longitudeText = ""
				else
					timeTable.longitudeText = string.format( '%.6f', event.longitude )
				end
			end
		end
		--執行定位資料讀取
		Runtime:addEventListener( "location", locationHandler )
		
		--建立滑動畫面
		local scrollView = widget.newScrollView( { top = 0, left = 0, horizontalScrollDisabled = true,
				isBounceEnabled = false, listener = scrollListener } )
		
		local overlayOptions1 = {
			isModal = true,
			effect = "zoomOutIn",
			time = 100,
		}
		--按下選擇分類按鈕
		local groupSelectbtnPress = function( event )
			composer.showOverlay( "selectGroup", overlayOptions1 )
		end
		
		--按下花費時間按鈕
		local moneyInputbtnPress = function( event )
			composer.showOverlay( "selectTime", overlayOptions1 )
		end
		
		--按下加入按鈕
		local saveTimeBtnPress = function( event )
			local i = 0
			local newMoney = 0
			local rowid = 0
			if timeTable.group1 ~= 0 and timeTable.group2 ~= 0 and itemNameField.text ~= "" then
				--更新記錄時間
				local date = os.date( "*t" )
				timeTable.timeText = date.year.."-"..string.format('%02d',date.month).."-"..string.format('%02d',date.day).." "..string.format('%02d',date.hour)..":"..string.format('%02d',date.min)..":"..string.format('%02d',date.sec)
				local selectDateStr = timeTable.year.."-"..string.format('%02d',timeTable.month).."-"..string.format('%02d',timeTable.day)

				local sql = [[INSERT INTO timeTable VALUES (NULL, ']]..timeTable.timeText..[[',']]..""..[[',']]..timeTable.group1..[[',']]..timeTable.group2..[[',']]..itemNameField.text..[[',']].."0"..[[',']]..""..[[',']]..""..[[',']]..""..[[',']]..""..[['); ]]
				db:exec( sql )
				if db:errcode() ~= 0 then
					print(db:errcode(), db:errmsg())
				end
			end
			print("g1="..timeTable.group1..",g2="..timeTable.group2..",t="..itemNameField.text)
			--清空暫存數字
			timeTable.money = 0
			timeTable.group1 = 0
			timeTable.group2 = 0
			--更新日曆
			dayTouch()
		end
		
		--按下投下按鈕
		local itemDownBtnPress = function( event )
			print("down id="..event.target.id)
			local date = os.date( "*t" )
			timeTable.timeText = date.year.."-"..string.format('%02d',date.month).."-"..string.format('%02d',date.day).." "..string.format('%02d',date.hour)..":"..string.format('%02d',date.min)..":"..string.format('%02d',date.sec)
			local sql = [[UPDATE timeTable SET date2 = ']]..timeTable.timeText..[[', ps = '1', gpslat = ']]..timeTable.latitudeText..[[', gpslong = ']]..timeTable.longitudeText..[[' WHERE id = ']]..event.target.id..[[' ; ]]
			db:exec( sql )
			if db:errcode() then
				print(db:errcode(), db:errmsg())
			end
			--清空暫存數字
			timeTable.money = 0
			timeTable.group1 = 0
			timeTable.group2 = 0
			--更新日曆
			dayTouch()
		end
		
		--按下地圖按鈕
		local mapItemBtnPress = function( event )
			currentLatitude = ""
			currentLongitude = ""
			for row in db:nrows("SELECT * FROM timeTable WHERE id = "..event.target.id.." LIMIT 1 ") do
				currentLatitude = row.gpslat
				currentLongitude = row.gpslong
			end
			mapURL = "https://maps.google.com/maps?q=Here,+Here!@"..currentLatitude..","..currentLongitude
			print("mapURL="..mapURL)
			system.openURL( mapURL )
		end
		
		--按下遺失按鈕
		local lostItemBtnPress = function( event )
			print("lost id="..event.target.id)
			local sql = [[UPDATE timeTable SET ps = '2' WHERE id = ']]..event.target.id..[[' ; ]]
			db:exec( sql )
			if db:errcode() then
				print(db:errcode(), db:errmsg())
			end
			--清空暫存數字
			timeTable.money = 0
			timeTable.group1 = 0
			timeTable.group2 = 0
			--更新日曆
			dayTouch()
		end
		
		--按下回收按鈕
		local recoverItemBtnPress = function( event )
			print("re id="..event.target.id)
			local sql = [[UPDATE timeTable SET date2 = '', ps = '0', gpslat = '', gpslong = '' WHERE id = ']]..event.target.id..[[' ; ]]
			db:exec( sql )
			if db:errcode() then
				print(db:errcode(), db:errmsg())
			end
			--清空暫存數字
			timeTable.money = 0
			timeTable.group1 = 0
			timeTable.group2 = 0
			--更新日曆
			dayTouch()
		end
		
		--按下刪除按鈕
		local deleteItemBtnPress = function( event )
			print("del id="..event.target.id)
			local sql = [[DELETE FROM timetable WHERE id = ']]..event.target.id..[['; ]]
			db:exec( sql )
			if db:errcode() then
				print(db:errcode(), db:errmsg())
			end
			--清空暫存數字
			timeTable.money = 0
			timeTable.group1 = 0
			timeTable.group2 = 0
			--更新日曆
			dayTouch()
		end
		
		--收支明細查詢
		function dayTouch( event )
			local selectDateStr = ""
			local allItemSum = 0 --總計
			local downItemSum = 0 --投下
			local lostItemSum = 0 --遺失
			
			--移除原本的收支明細列表
			if dayMoneyListView ~= nil then
				dayMoneyListView:removeSelf()
			end
			
			--建立收支明細
			dayMoneyListView = display.newGroup()
			--顯示"記時明細"文字
			local listTextbg = display.newRect( 0, 0, display.contentWidth, 20 )
			listTextbg.x, listTextbg.y = display.contentWidth*0.5, 10
			listTextbg:setFillColor( 0.6,0.6,0.6 )
			dayMoneyListView:insert( listTextbg )
			local listText = display.newText( "漁具清單"..selectDateStr, 0, 0, native.systemFont, 14 )
			listText.anchorX = 0
			listText.x, listText.y = 10, listTextbg.y
			dayMoneyListView:insert( listText )
			--清單空白背景
			local listNullbg = display.newRect( 0, 0, display.contentWidth, 200 )
			listNullbg.anchorY = 0
			listNullbg.x, listNullbg.y = display.contentWidth*0.5, listTextbg.y+10
			listNullbg:setFillColor( 1 )
			dayMoneyListView:insert( listNullbg )
			--顯示日記清單方格
			local i = 0
			local rowHeight = 29
			local groupView = 1 --1:群組1檢視，2:清單檢視
			local moneySum = 0
			local showTime = 0
			--依時間軸顯示記錄
			for row in db:nrows("SELECT * FROM timeTable ORDER BY money") do
				if row.ps == "0" then
					--背景底色
					local dayListbg = display.newRect( 0, 0, display.contentWidth, 38 )
					dayListbg.x, dayListbg.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i
					dayListbg:setFillColor( 1 )
					dayMoneyListView:insert( dayListbg )
					--分隔線
					local dayListLine = display.newRect( 0, 0, display.contentWidth, 2 )
					dayListLine.x, dayListLine.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i+18
					dayListLine:setFillColor( 0.8,0.8,0.8 )
					dayMoneyListView:insert( dayListLine )
					--顯示群組文字
					local dayRecordGroupbg = display.newRect( 2, 0, 80, 34 )
					dayRecordGroupbg.x, dayRecordGroupbg.y = 40, listTextbg.y+rowHeight+38*i-1
					dayRecordGroupbg:setFillColor( timeTable.group1Colors[row.group1][1],timeTable.group1Colors[row.group1][2],timeTable.group1Colors[row.group1][3] )
					dayMoneyListView:insert( dayRecordGroupbg )
					local dayRecordGroupText = display.newText( timeTable.group2Array[row.group1][row.group2], 0, 0, native.systemFont, 16 )
					dayRecordGroupText.x, dayRecordGroupText.y = dayRecordGroupbg.x+1, dayRecordGroupbg.y
					dayRecordGroupText:setFillColor( 0 )
					dayMoneyListView:insert( dayRecordGroupText )
					--顯示漁具編號money
					local showIdText = display.newText( row.money, 0, 0, native.systemFont, 14 )
					showIdText.anchorY = 0
					showIdText.x, showIdText.y = 95+16, listTextbg.y+38*i+22
					showIdText:setFillColor( 0 )
					dayMoneyListView:insert( showIdText )
					--顯示投下按鈕
					local itemDownBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "投下",
						onPress = itemDownBtnPress
					}
					itemDownBtn.anchorX = 0
					itemDownBtn.x, itemDownBtn.y = 138, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( itemDownBtn )
					--顯示刪除按鈕
					local deleteItemBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "刪除",
						onPress = deleteItemBtnPress
					}
					deleteItemBtn.anchorX = 0
					deleteItemBtn.x, deleteItemBtn.y = 266, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( deleteItemBtn )
					allItemSum = allItemSum+1
					i = i+1
				elseif row.ps == "1" then
					--背景底色
					local dayListbg = display.newRect( 0, 0, display.contentWidth, 38 )
					dayListbg.x, dayListbg.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i
					dayListbg:setFillColor( 1 )
					dayMoneyListView:insert( dayListbg )
					--顯示群組文字
					local dayRecordGroupbg = display.newRect( 2, 0, 80, 34 )
					dayRecordGroupbg.x, dayRecordGroupbg.y = 40, listTextbg.y+rowHeight+38*i-1
					dayRecordGroupbg:setFillColor( timeTable.group1Colors[row.group1][1],timeTable.group1Colors[row.group1][2],timeTable.group1Colors[row.group1][3] )
					dayMoneyListView:insert( dayRecordGroupbg )
					local dayRecordGroupText = display.newText( timeTable.group2Array[row.group1][row.group2], 0, 0, native.systemFont, 16 )
					dayRecordGroupText.x, dayRecordGroupText.y = dayRecordGroupbg.x+1, dayRecordGroupbg.y
					dayRecordGroupText:setFillColor( 0 )
					dayMoneyListView:insert( dayRecordGroupText )
					--顯示漁具編號money
					local showIdText = display.newText( row.money, 0, 0, native.systemFont, 14 )
					showIdText.anchorY = 0
					showIdText.x, showIdText.y = 95+16, listTextbg.y+38*i+22
					showIdText:setFillColor( 0 )
					dayMoneyListView:insert( showIdText )
					--顯示投下時間
					local dayRecordDate2Text = display.newText( { text = "T="..row.date2, x = 0, y = 0,
								width = display.contentWidth*0.7, height = 16,
								font = native.systemFont, fontSize = 12, align = "left" } )
					dayRecordDate2Text.x, dayRecordDate2Text.y = dayRecordGroupbg.x+225, dayRecordGroupbg.y-5
					dayRecordDate2Text:setFillColor( 0 ) --黑字
					dayMoneyListView:insert( dayRecordDate2Text )
					--顯示投下地點
					local dayRecordGpsText = display.newText( { text = "GPS="..row.gpslat..","..row.gpslong, x = 0, y = 0,
								width = display.contentWidth*0.7, height = 16,
								font = native.systemFont, fontSize = 12, align = "left" } )
					dayRecordGpsText.x, dayRecordGpsText.y = dayRecordGroupbg.x+225, dayRecordGroupbg.y+10
					dayRecordGpsText:setFillColor( 0 ) --黑字
					dayMoneyListView:insert( dayRecordGpsText )
					i = i+1
					-------------------------------------------------------
					--背景底色
					local dayListbg = display.newRect( 0, 0, display.contentWidth, 38 )
					dayListbg.x, dayListbg.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i
					dayListbg:setFillColor( 1 )
					dayMoneyListView:insert( dayListbg )
					--分隔線
					local dayListLine = display.newRect( 0, 0, display.contentWidth, 2 )
					dayListLine.x, dayListLine.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i+18
					dayListLine:setFillColor( 0.8,0.8,0.8 )
					dayMoneyListView:insert( dayListLine )
					--顯示已投下文字
					local lostingText = display.newText( "已投下...", 0, 0, native.systemFont, 16 )
					lostingText.x, lostingText.y = 40, listTextbg.y+rowHeight+38*i-1
					lostingText:setFillColor( 1,0,0 )
					dayMoneyListView:insert( lostingText )
					--顯示地圖按鈕
					local mapItemBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "地圖",
						onPress = mapItemBtnPress
					}
					mapItemBtn.anchorX = 0
					mapItemBtn.x, mapItemBtn.y = 138, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( mapItemBtn )
					--顯示遺失按鈕
					local lostItemBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "遺失",
						onPress = lostItemBtnPress
					}
					lostItemBtn.anchorX = 0
					lostItemBtn.x, lostItemBtn.y = 202, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( lostItemBtn )
					--顯示回收按鈕
					local recoverItemBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "回收",
						onPress = recoverItemBtnPress
					}
					recoverItemBtn.anchorX = 0
					recoverItemBtn.x, recoverItemBtn.y = 266, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( recoverItemBtn )
					allItemSum = allItemSum+1
					downItemSum = downItemSum+1
					i = i+1
				elseif row.ps == "2" then
					--背景底色
					local dayListbg = display.newRect( 0, 0, display.contentWidth, 38 )
					dayListbg.x, dayListbg.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i
					dayListbg:setFillColor( 1 )
					dayMoneyListView:insert( dayListbg )
					--顯示群組文字
					local dayRecordGroupbg = display.newRect( 2, 0, 80, 34 )
					dayRecordGroupbg.x, dayRecordGroupbg.y = 40, listTextbg.y+rowHeight+38*i-1
					dayRecordGroupbg:setFillColor( timeTable.group1Colors[row.group1][1],timeTable.group1Colors[row.group1][2],timeTable.group1Colors[row.group1][3] )
					dayMoneyListView:insert( dayRecordGroupbg )
					local dayRecordGroupText = display.newText( timeTable.group2Array[row.group1][row.group2], 0, 0, native.systemFont, 16 )
					dayRecordGroupText.x, dayRecordGroupText.y = dayRecordGroupbg.x+1, dayRecordGroupbg.y
					dayRecordGroupText:setFillColor( 0 )
					dayMoneyListView:insert( dayRecordGroupText )
					--顯示漁具編號money
					local showIdText = display.newText( row.money, 0, 0, native.systemFont, 14 )
					showIdText.anchorY = 0
					showIdText.x, showIdText.y = 95+16, listTextbg.y+38*i+22
					showIdText:setFillColor( 0 )
					dayMoneyListView:insert( showIdText )
					--顯示投下時間
					local dayRecordDate2Text = display.newText( { text = "T="..row.date2, x = 0, y = 0,
								width = display.contentWidth*0.7, height = 16,
								font = native.systemFont, fontSize = 12, align = "left" } )
					dayRecordDate2Text.x, dayRecordDate2Text.y = dayRecordGroupbg.x+225, dayRecordGroupbg.y-5
					dayRecordDate2Text:setFillColor( 0 ) --黑字
					dayMoneyListView:insert( dayRecordDate2Text )
					--顯示投下地點
					local dayRecordGpsText = display.newText( { text = "GPS="..row.gpslat..","..row.gpslong, x = 0, y = 0,
								width = display.contentWidth*0.7, height = 16,
								font = native.systemFont, fontSize = 12, align = "left" } )
					dayRecordGpsText.x, dayRecordGpsText.y = dayRecordGroupbg.x+225, dayRecordGroupbg.y+10
					dayRecordGpsText:setFillColor( 0 ) --黑字
					dayMoneyListView:insert( dayRecordGpsText )
					i = i+1
					-------------------------------------------------------
					--背景底色
					local dayListbg = display.newRect( 0, 0, display.contentWidth, 38 )
					dayListbg.x, dayListbg.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i
					dayListbg:setFillColor( 1 )
					dayMoneyListView:insert( dayListbg )
					--分隔線
					local dayListLine = display.newRect( 0, 0, display.contentWidth, 2 )
					dayListLine.x, dayListLine.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i+18
					dayListLine:setFillColor( 0.8,0.8,0.8 )
					dayMoneyListView:insert( dayListLine )
					--顯示地圖按鈕
					local mapItemBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "地圖",
						onPress = mapItemBtnPress
					}
					mapItemBtn.anchorX = 0
					mapItemBtn.x, mapItemBtn.y = 138, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( mapItemBtn )
					--顯示已掛失文字
					local lostingText = display.newText( "掛失中...", 0, 0, native.systemFont, 16 )
					lostingText.x, lostingText.y = 40, listTextbg.y+rowHeight+38*i-1
					lostingText:setFillColor( 1,0,0 )
					dayMoneyListView:insert( lostingText )
					--顯示回收按鈕
					local recoverItemBtn = widget.newButton
					{
						shape = "roundedRect",
						width = 50,
						height = 30,
						cornerRadius = 2,
						fillColor = { default={1,0.8,0.8,1}, over={1,0.8,0.8,0.4} }, --土黃
						strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
						strokeWidth = 2,
						labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
						font = native.systemFont, 
						fontSize = 16,
						emboss = true,
						id = row.id,
						label = "回收",
						onPress = recoverItemBtnPress
					}
					recoverItemBtn.anchorX = 0
					recoverItemBtn.x, recoverItemBtn.y = 266, listTextbg.y+rowHeight+38*i-1
					dayMoneyListView:insert( recoverItemBtn )
					allItemSum = allItemSum+1
					lostItemSum = lostItemSum+1
					i = i+1
				end
			end
			scrollView:insert( dayMoneyListView )
			--顯示統計數量
			moreTimeText = display.newText( "總計："..allItemSum.." / 投下："..downItemSum.." / 遺失："..lostItemSum, 0, 0, native.systemFont, 12 )
			moreTimeText:setFillColor( 0.5,1,1,1 )
			moreTimeText.anchorX = 0
			moreTimeText.x, moreTimeText.y = 120, listTextbg.y
			dayMoneyListView:insert( moreTimeText )
			--背景底色
			local dayListbg = display.newRect( 0, 0, display.contentWidth, 38 )
			dayListbg.x, dayListbg.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i
			dayListbg:setFillColor( 1 )
			dayMoneyListView:insert( dayListbg )
			--分隔線
			local dayListLine = display.newRect( 0, 0, display.contentWidth, 2 )
			dayListLine.x, dayListLine.y = display.contentWidth*0.5, listTextbg.y+rowHeight+38*i+18
			dayListLine:setFillColor( 0.8,0.8,0.8 )
			dayMoneyListView:insert( dayListLine )
			--顯示群組按鈕
			groupSelectbtn = widget.newButton
			{
				shape = "roundedRect",
				width = 158,
				height = 30,
				cornerRadius = 2,
				fillColor = { default={0.5,1,0.5,1}, over={0.5,1,0.5,0.4} }, --綠
				strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
				strokeWidth = 2,
				labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
				font = native.systemFont, 
				fontSize = 16,
				emboss = true,
				id = 0,
				label = "✍選擇分類..",
				onPress = groupSelectbtnPress
			}
			groupSelectbtn.anchorX = 0
			groupSelectbtn.x, groupSelectbtn.y = 1, listTextbg.y+rowHeight+38*i-1
			dayMoneyListView:insert( groupSelectbtn )
			--顯示選項文字輸入欄
			itemNameField = native.newTextField( 0, 0, 100, 28 )
			itemNameField.inputType = "default"
			itemNameField.text = ""
			itemNameField.x, itemNameField.y = 213, listTextbg.y+rowHeight+38*i-1
			dayMoneyListView:insert( itemNameField )
			
			--顯示加入按鈕
			local saveTimeBtn = widget.newButton
			{
				shape = "roundedRect",
				width = 50,
				height = 30,
				cornerRadius = 2,
				fillColor = { default={0.8,0.8,0,1}, over={0.8,0.8,0,0.4} }, --土黃
				strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
				strokeWidth = 2,
				labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
				font = native.systemFont, 
				fontSize = 16,
				emboss = true,
				id = 0,
				label = "加入",
				onPress = saveTimeBtnPress
			}
			saveTimeBtn.anchorX = 0
			saveTimeBtn.x, saveTimeBtn.y = 266, listTextbg.y+rowHeight+38*i-1
			dayMoneyListView:insert( saveTimeBtn )
			i = i+1
		
			
			--調整程式長度
			if i < 4 then
				scrollView:setScrollHeight( 480 )
				if event ~= nil then --自動捲到畫面頂端
					scrollView:scrollToPosition{ y = -0, time = 200 }
				end
			else
				scrollView:setScrollHeight( 346+38*(i-1)+18 )
				if event ~= nil then --自動捲到畫面底部
					scrollView:scrollToPosition{ y = -1*((346+38*(i-1)+18)-480), time = 200 }
				end
			end
		end
		
		--按下日曆檢視按鈕
		--local goAddMoneyBtnPress = function( event )
		--	composer.gotoScene( "sceneAddMoney", { effect = "fromTop", time = 300 } )
		--end

		--背景底色
		local bg = display.newRect( 0, 0, display.contentWidth, display.contentHeight )
		bg.x, bg.y = display.contentWidth*0.5, display.contentHeight*0.5
		bg:setFillColor( 1 ) --白
		scrollView:insert( bg )
		--顯示"日記本"文字
		--local calendarTextbg = display.newRect( 0, 0, display.contentWidth, 20 )
		--calendarTextbg.x, calendarTextbg.y = display.contentWidth*0.5, 10
		--calendarTextbg:setFillColor( 0.6,0.6,0.6 )
		--scrollView:insert( calendarTextbg )
		--local calendarText = display.newText( "日記本(左右滑動換月)", 0, 0, native.systemFont, 14 )
		--calendarText.anchorX = 0
		--calendarText.x, calendarText.y = 10, calendarTextbg.y
		--scrollView:insert( calendarText )
		--顯示日曆
		dayTouch()
		
		sceneGroup:insert( scrollView )
	elseif phase == "did" then
		
	end
end

function scene:hide( event )
    local sceneGroup = self.view
    local phase = event.phase

    if event.phase == "will" then
        -- Called when the scene is on screen and is about to move off screen
        --
        -- INSERT code here to pause the scene
        -- e.g. stop timers, stop animation, unload sounds, etc.)
    elseif phase == "did" then
		
    end 
end


function scene:destroy( event )
    local sceneGroup = self.view

    -- Called prior to the removal of scene's "view" (sceneGroup)
    -- 
    -- INSERT code here to cleanup the scene
    -- e.g. remove display objects, remove touch listeners, save state, etc
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

---------------------------------------------------------------------------------

return scene

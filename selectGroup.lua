local widget = require( "widget" )
local composer = require( "composer" )
local sqlite3 = require( "sqlite3" )
local scene = composer.newScene()

--開啟資料庫"data.db"，若未存在則新建一個
local path = system.pathForFile( "data.db", system.DocumentsDirectory )
local db = sqlite3.open( path )

function scene:create( event )
    local sceneGroup = self.view

	local scrollView1
	local scrollView2    
	
	--設定顯示元件外觀
	widget.setTheme( "widget_theme_android_holo_light" )

	
	
	--顯示群組2選項
	local function showGroup2( group1 )
		if scrollView2 ~= nil then
			scrollView2:removeSelf()
			scrollView2 = nil
		end
		--建立滑動畫面2
		scrollView2 = widget.newScrollView( { top = display.contentHeight*0.1, left = display.contentWidth*0.5, width = display.contentWidth*0.45, height = display.contentHeight*0.8, horizontalScrollDisabled = true,
			isBounceEnabled = false, listener = scrollListener } )
		local i = 1
		scrollView2:setScrollHeight( display.contentHeight*0.8 ) --重置高度
		--顯示背景
		local group2Nullbg = display.newRect( 0, 0, display.contentWidth*0.45, display.contentHeight*0.8 )
		group2Nullbg.anchorX, group2Nullbg.anchorY = 0, 0
		group2Nullbg:setFillColor( 1 )
		scrollView2:insert( group2Nullbg )
		for row in db:nrows("SELECT * FROM timeGroupTable WHERE g1 = "..group1.." ORDER BY g1 ASC, g2 ASC") do
			--顯示背景
			local group2bg = display.newRect( 0, 0, 144, 36 )
			group2bg.anchorX, group2bg.anchorY = 0, 0
			group2bg.x, group2bg.y = 0, 36*(i-1)
			group2bg:setFillColor( timeTable.group1Colors[group1][1],timeTable.group1Colors[group1][2],timeTable.group1Colors[group1][3] ) --淺紅
			scrollView2:insert( group2bg )
			--按下群組1選項
			local function radioGroup2Listener( event )
				timeTable.group1 = group1
				timeTable.group2 = event.target.id
				groupNameField.text = timeTable.group2Array[timeTable.group1][timeTable.group2]
			end
			--顯示選項圈圈
			local group2Switch = widget.newSwitch {
				style = "radio",
				id = i,
				onPress = radioGroup2Listener,
			}
			group2Switch.x, group2Switch.y = group2bg.x+18, group2bg.y+18
			scrollView2:insert( group2Switch )
			--顯示選項文字
			local group2Text = display.newText( { text = "", x = 0, y = 0,
									width = 108, height = 36,
									font = native.systemFont, fontSize = 20, align = "left" } )
			group2Text.text = row.name
			group2Text:setFillColor( 0 ) --黑
			group2Text.x, group2Text.y = group2bg.x+88, group2bg.y+24
			scrollView2:insert( group2Text )
			i = i+1
		end
	end
	
	--顯示群組1選項
	local function showGroup1()
		if scrollView1 ~= nil then
			scrollView1:removeSelf()
			scrollView1 = nil
		end
		--建立滑動畫面1
		scrollView1 = widget.newScrollView( { top = display.contentHeight*0.1, left = display.contentWidth*0.05, width = display.contentWidth*0.45, height = display.contentHeight*0.8, horizontalScrollDisabled = true,
			isBounceEnabled = false, listener = scrollListener } )
		for i = 1,10 do
			--顯示背景
			local group1bg = display.newRect( 0, 0, 144, 36 )
			group1bg.anchorX, group1bg.anchorY = 0, 0
			group1bg.x, group1bg.y = 0, 36*(i-1)
			group1bg:setFillColor( timeTable.group1Colors[i][1],timeTable.group1Colors[i][2],timeTable.group1Colors[i][3] )
			scrollView1:insert( group1bg )
			--按下群組1選項
			local function radioGroup1Listener( event )
				timeTable.group1 = event.target.id
				timeTable.group2 = 0
				groupNameField.text = timeTable.group1Array[timeTable.group1]
				showGroup2(timeTable.group1)
			end
			--顯示選項圈圈
			local group1Switch = widget.newSwitch {
				style = "radio",
				id = i,
				onPress = radioGroup1Listener,
			}
			group1Switch.x, group1Switch.y = group1bg.x+18, group1bg.y+18
			scrollView1:insert( group1Switch )
			--顯示選項文字
			local group1Text = display.newText( { text = "", x = 0, y = 0,
									width = 108, height = 36,
									font = native.systemFont, fontSize = 20, align = "left" } )
			group1Text.text = timeTable.group1Array[i]
			group1Text:setFillColor( 0 ) --黑
			group1Text.x, group1Text.y = group1bg.x+88, group1bg.y+24
			scrollView1:insert( group1Text )
		end
	end
	
	--背景底色
	local bg = display.newRect( sceneGroup, 0, 0, display.contentWidth, display.contentHeight )
	bg.x, bg.y = display.contentWidth*0.5, display.contentHeight*0.5
	bg:setFillColor( 0,0,0,0.7 ) --半透明灰黑
	--背景底色2
	local bg2 = display.newRect( sceneGroup, 0, 0, display.contentWidth*0.9, display.contentHeight*0.8 )
	bg2.x, bg2.y = display.contentWidth*0.5, display.contentHeight*0.5
	bg2:setFillColor( 1 ) --半透明灰黑
	
	--顯示群組1選項
	showGroup1()
	
	--顯示選項文字輸入欄
	groupNameField = native.newTextField( 0, 0, 112, 28 )
	groupNameField.inputType = "default"
	groupNameField.text = ""
	groupNameField.x, groupNameField.y = 70, 25
	
	--按下更名按鈕
	function renameBtnPress ( event )
		if timeTable.group1 ~= 0 and timeTable.group2 == 0 then --群組1
			local sql = [[UPDATE timeGroupTable SET name = ']]..groupNameField.text..[[' WHERE g1 = 0 AND g2 = ]]..timeTable.group1..[[; ]]
			db:exec( sql )
		elseif timeTable.group1 ~= 0 and timeTable.group2 ~= 0 then --群組2
			local sql = [[UPDATE timeGroupTable SET name = ']]..groupNameField.text..[[' WHERE g1 = ]]..timeTable.group1..[[ AND g2 = ]]..timeTable.group2..[[; ]]
			db:exec( sql )
		end
		--更新群組表
		updateTimeGroupArray()
		if scrollView1 ~= nil then
			scrollView1:removeSelf()
			scrollView1 = nil
		end
		if scrollView2 ~= nil then
			scrollView2:removeSelf()
			scrollView2 = nil
		end
		showGroup1()
	end
	--顯示更名按鈕
	local renamebtn = widget.newButton
	{
		shape = "roundedRect",
		width = display.contentWidth*0.2,
		height = 30,
		cornerRadius = 2,
		fillColor = { default={0,1,1,1}, over={0,1,1,0.4} },
		strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
		strokeWidth = 2,
		labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
		font = native.systemFontBold, 
		fontSize = 16,
		emboss = true, 
		label = "更名",
		onPress = renameBtnPress
	}
	renamebtn.x, renamebtn.y = display.contentWidth*4/8, 25
	sceneGroup:insert( renamebtn )
	
	--按下返回按鈕
	function closeSelectGroupBtnPress ( event )
		if scrollView1 ~= nil then
			scrollView1:removeSelf()
			scrollView1 = nil
		end
		if scrollView2 ~= nil then
			scrollView2:removeSelf()
			scrollView2 = nil
		end
		if groupNameField ~= nil then
			groupNameField:removeSelf()
			groupNameField = nil
		end
		closeSelectGroupBtnPress2()
	end
	--顯示返回按鈕
	local closeWindowbtn = widget.newButton
	{
		shape = "roundedRect",
		width = display.contentWidth*0.3,
		height = 40,
		cornerRadius = 2,
		fillColor = { default={0,1,1,1}, over={0,1,1,0.4} },
		strokeColor = { default={0.2,0.4,0.8,1}, over={0.8,0.8,1,1} },
		strokeWidth = 2,
		labelColor = { default = { 0, 0, 0, 1 }, over = { 0, 0, 0, 0.5 } },
		font = native.systemFontBold, 
		fontSize = 26,
		emboss = true, 
		label = "返回",
		onPress = closeSelectGroupBtnPress
	}
	closeWindowbtn.x, closeWindowbtn.y = display.contentWidth*7/9, 455
	sceneGroup:insert( closeWindowbtn )
end
scene:addEventListener( "create", scene )
return scene
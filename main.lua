local ui = require("ui")

display.setStatusBar( display.HiddenStatusBar )

local screenW, screenH = display.contentWidth, display.contentHeight
local viewableScreenW, viewableScreenH = display.viewableContentWidth, display.viewableContentHeight
local screenOffsetW, screenOffsetH = display.contentWidth - display.viewableContentWidth, display.contentHeight - display.viewableContentHeight
local toolMode = "lineTool"
local firstRun = true
local userPhoto, imgBtn, cameraBtn, infoBtn, defaultField, photoScreen, toolBar, startScreen, background, aboutScreen

function showAboutScreen()
	aboutScreen.y = screenH
	aboutScreen.isVisible = true
	photoScreen.isVisible = false
	transition.to(aboutScreen, {time=400, y=0, transition=easing.outQuad})
	
	aboutScreen:addEventListener("touch", backToMain)
	return true
end

function hideRevealTools(event)
	local phase
	if event then 
		if event.phase ~= nil then 
			phase = event.phase
		else 
			phase = "ended"
		end
	else
		phase = "ended"
	end

	if phase == "ended" then
		local yValue = photoScreenInitY - 56

		if photoScreen.y ~= photoScreenInitY then
			yValue = photoScreenInitY
		end
	
		transition.to(photoScreen, {time=300, y=yValue, transition=easing.outQuad})
	end

	return true
end

function backToMain(event)
	local t = event.target
	local phase = event.phase

	if "began" == phase then
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		
	elseif t.isFocus then
		if "moved" == phase then
			
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false

			if photoScreen.isVisible then
				saveImage(true)
			else						
				transition.to(aboutScreen, {time=400, y=screenH, transition=easing.outQuad})
			end
		end
	end

	-- Stop further propagation of touch event
	return true
end

-- Handler that gets notified when the alert closes
local function onCompleteSave( event )
        if "clicked" == event.action then
                local i = event.index
                if i == 1 then
                	--Don't save and go back to start screen
					background:removeEventListener( "touch", startDraw )
					startScreen.isVisible = true
					startScreen.y = screenH
					transition.to(startScreen, {time=400, y=screenH*0.5, transition=easing.outQuad, onComplete=function() photoScreen.isVisible = false end})
                elseif i == 2 then
                    -- Do nothing; dialog will simply dismiss
                    	hideRevealTools()
                elseif i == 3 then
                	--Save the image and show the start screen
                	saveImage()
					background:removeEventListener( "touch", startDraw )
					startScreen.isVisible = true
					startScreen.y = screenH
					transition.to(startScreen, {time=400, y=screenH*0.5, transition=easing.outQuad, onComplete=function() photoScreen.isVisible = false end})
                end
        end
end

function saveImage(options)	
	if options == true then
		local alert = native.showAlert( "Save Image", "Do you want to save your changes?", { "Don't Save", "Cancel", "Save" }, onCompleteSave )
	else 
		photoScreen.y = photoScreenInitY	
		local savedPhoto = display.captureScreen( true )
		local alert = native.showAlert( "Success", "Image Saved to Library", { "OK" } )
		savedPhoto.isVisible = false
	end
		
	return true
end

function fieldHandler( event )
	if ( "submitted" == event.phase  or "ended" == event.phase ) then
		-- This event occurs when the user presses the "return" key on the keyboard
		
		local photoText = display.newText(defaultField.text, 0, 0, "MarkerFelt-Wide", 24)
		photoText:setTextColor( 0, 183, 235 )
		photoScreen:insert(photoText)
				
		photoText.x = defaultField.ex
		photoText.y = defaultField.ey

		defaultField:removeSelf()
		transition.to(photoScreen.textPanel, { time = 400, y = -photoScreen.textPanel.height*0.5 })	

		-- Hide keyboard
		native.setKeyboardFocus( nil )
	end
	
	return true
end

function startDraw( event )	
	local t = event.target
	local phase = event.phase
	print("startDraw phase: ".. phase)
	print("startDraw toolMode: ".. toolMode)
	
	if "began" == phase then
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
			
		t.x0 = event.x
		t.y0 = event.y

		myLine = nil
	elseif t.isFocus then
		if "moved" == phase then
			
			if toolMode == "lineTool" then			

				if ( myLine ) then
					myLine.parent:remove( myLine ) -- erase previous line, if any
				end
				
				myLine = display.newLine( t.x0,t.y0, event.x,event.y )
 				
				myLine:setColor( 0, 183, 235 )
				myLine.width = 3 
				photoScreen:insert(myLine)
			end

		elseif "ended" == phase or "cancelled" == phase then		
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false

			if toolMode == "textTool" then
				local textPanel = display.newGroup()
				local bg = display.newRect( 0, 0, screenW, 150 )
				bg:setFillColor(255,255,255)
				bg:setStrokeColor(0, 183, 235 )
				bg.strokeWidth = 1
				textPanel:insert(bg)
				local label = display.newText("Enter text", 18, 12, "MarkerFelt-Wide", 18)
				label:setTextColor(0,0,0)
				textPanel:insert(label)
							
				textPanel.y = -textPanel.height*0.5

				transition.to(textPanel, { time = 400, y = 0, onComplete = function() 
					defaultField = native.newTextField( 0, 0, screenW-24, 30, fieldHandler )
					defaultField.font = native.newFont( "MarkerFelt-Wide", 18 )
					defaultField:setReferencePoint(display.CenterReferencePoint)
					textPanel:insert(defaultField)
								
					defaultField.x = screenW*0.5
					defaultField.y = 63
					
					defaultField.ex = event.x
					defaultField.ey = event.y
					--place the cursor in the text field to cause the keyboard to come up				
					native.setKeyboardFocus( defaultField )
				end })

				photoScreen.textPanel = textPanel				
			end
									
		end
	end

	-- Stop further propagation of touch event
	return true
end

function showTextAlert(event)
	if firstRun == true then
		firstRun = false
		local alert = native.showAlert( "Text Tool", "Tap screen to add text", { "OK" } )
	end
end

function showToolBar() 
	local toolBg = display.newRect(0,0, screenW, 60)
	toolBg:setFillColor(140,140,140)
	toolBg.y = viewableScreenH - toolBg.height*0.5
	toolBar:insert(toolBg)	
	toolBg:addEventListener("touch", hideRevealTools)

	local textBtn = ui.newButton{
		default = "textBtn.png",
		over = "textBtn_over.png",
		onRelease = function() 
						toolMode="textTool" 
						showTextAlert()
						hideRevealTools()
					end
	}
	toolBar:insert(textBtn)
	textBtn.x = viewableScreenW - textBtn.width*0.5 - 6
	textBtn.y = viewableScreenH - textBtn.height*0.5 - 4 

	local lineBtn = ui.newButton{
		default = "lineBtn.png",
		over = "lineBtn_over.png",
		onRelease = function() 
						toolMode="lineTool";
						hideRevealTools(); 
					end
	}
	toolBar:insert(lineBtn)
	lineBtn.x = textBtn.x - lineBtn.width - 6
	lineBtn.y = textBtn.y 
		
	local saveBtn = ui.newButton{
		default = "buttonBlueSmall.png",
		over = "buttonBlueSmallOver.png",
		onRelease = saveImage,
		text = "Save",
		emboss = true,
		size = 16
	}
	toolBar:insert(saveBtn)
	saveBtn.x = math.floor(saveBtn.width*0.5 + 12)
	saveBtn.y = textBtn.y 

	local doneBtn = ui.newButton{
		default = "buttonBlueSmall.png",
		over = "buttonBlueSmallOver.png",
		onRelease = backToMain,
		text = "Done",
		emboss = true,
		size = 16
	}
	toolBar:insert(doneBtn)
	doneBtn.x = math.floor(saveBtn.x + saveBtn.width + 12)
	doneBtn.y = textBtn.y 

	local photoBgDropShadow = display.newImage("dropShadowHoriz480.png")
	photoBgDropShadow.x = screenW*0.5 
	photoBgDropShadow.y = viewableScreenH + photoBgDropShadow.height*0.5 
	photoScreen:insert(photoBgDropShadow)
		
	return true
end

function onComplete( event )
	local photo = event.target	
	photoIsLandscape = false

	if photo then
		startScreen.isVisible = false

		local w = photo.width
		local h = photo.height
	
		if photo.width > photo.height then 
			photoIsLandscape = true
			photo.rotation = 90
			photo.xScale = viewableScreenH/photo.width
			photo.yScale = viewableScreenH/photo.width
		else 
			photo.xScale = viewableScreenH/photo.height
			photo.yScale = viewableScreenH/photo.height
		end
				
		photo.x = display.contentWidth*0.5
		photo.y = display.contentHeight*0.5
		photo:setReferencePoint(display.CenterReferencePoint)

		userPhoto = photo
		photoScreen:insert(userPhoto)

		local toolBgHitArea = display.newRect(0,0, screenW, 35)
		toolBgHitArea:setFillColor(0,0,0,0)
		photoScreen:insert(toolBgHitArea)
		toolBgHitArea.x = screenW*0.5
		toolBgHitArea.y = photoScreen.y + photoScreen.height*0.5 - toolBgHitArea.height*0.5
		toolBgHitArea:addEventListener("touch", hideRevealTools)
							
		photoScreen.y = photoScreenInitY - 56
		
		showToolBar()
		timer.performWithDelay( 700, hideRevealTools )
				
		background:addEventListener( "touch", startDraw )
	else
		background:removeEventListener( "touch", startDraw )
		startScreen.isVisible = true
	end
	
end

function onReleaseBtn( event )	
	local phase = event.phase

	if phase == "ended" then
		if event.target == imgBtn then 
			photoScreen.isVisible = true
			toolBar.isVisible = true
			media.show( media.PhotoLibrary, onComplete )	
		elseif event.target == cameraBtn then 
			photoScreen.isVisible = true
			toolBar.isVisible = true
			media.show( media.Camera, onComplete )
		end
	end

	return true
end

local function setupStartScreen()
	background = display.newRect( 0, 0, screenH, screenH )
	background:setFillColor( 255, 255, 255 )

	toolBar = display.newGroup()
	photoScreen = display.newGroup()
	startScreen = display.newGroup()
	aboutScreen = display.newGroup()

	toolBar.isVisible = false
	photoScreen.isVisible = false
	aboutScreen.isVisible = false

	local photoBg = display.newRect( 0, 0, screenW, screenH )
	photoBg:setFillColor( 0, 0, 0 )
	photoScreen:insert(photoBg)

	photoScreen:setReferencePoint(display.CenterReferencePoint)
	photoScreenInitY = photoScreen.y

	local aboutScreenBg = display.newImage("about.png")
	aboutScreenBg.x = screenW*0.5 
	aboutScreenBg.y = screenH*0.5
	aboutScreen:insert(aboutScreenBg)

	local startScreenBg = display.newImage("start.png")
	startScreenBg.x = screenW*0.5 
	startScreenBg.y = screenH*0.5
	startScreen:insert(startScreenBg)
	startScreen:setReferencePoint(display.CenterReferencePoint)

	imgBtn = ui.newButton{
		default = "buttonBlue.png",
		over = "buttonBlueOver.png",
		onRelease = onReleaseBtn,
		text = "Choose a Photo",
		emboss = true,
		size = 18
	}
	startScreen:insert(imgBtn)
	imgBtn.x = screenW*0.5
	imgBtn.y = math.floor(viewableScreenH - 180)

	cameraBtn = ui.newButton{
		default = "buttonBlue.png",
		over = "buttonBlueOver.png",
		onRelease = onReleaseBtn,
		text = "Take a New Photo",
		emboss = true,
		size = 18
	}
	startScreen:insert(cameraBtn)
	cameraBtn.x = screenW*0.5
	cameraBtn.y = imgBtn.y + imgBtn.height + 12

	infoBtn = ui.newButton{
		default = "buttonBlue.png",
		over = "buttonBlueOver.png",
		onRelease = showAboutScreen,
		text = "About DIY BUDDY",
		emboss = true,
		size = 18
	}
	startScreen:insert(infoBtn)
	infoBtn.x = screenW*0.5
	infoBtn.y = cameraBtn.y + cameraBtn.height + 12
end

function init()	
	setupStartScreen()	
end

--start the program!
init()
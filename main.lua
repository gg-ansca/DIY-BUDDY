local ui = require("ui")

display.setStatusBar( display.HiddenStatusBar )

local screenW, screenH = display.contentWidth, display.contentHeight
local viewableScreenW, viewableScreenH = display.viewableContentWidth, display.viewableContentHeight
local screenOffsetW, screenOffsetH = display.contentWidth -  display.viewableContentWidth, display.contentHeight - display.viewableContentHeight
local toolMode = "lineTool"
local firstRun = true
local userPhoto, imgBtn, cameraBtn, infoBtn, defaultField

local background = display.newRect( 0, 0, screenH, screenH )
background:setFillColor( 255, 255, 255 )

local blackBg = display.newRect( 0, 0, screenH, screenH )
blackBg:setFillColor( 0, 0, 0 )

local toolBar = display.newGroup()
local photoScreen = display.newGroup()
local startScreen = display.newGroup()
local aboutScreen = display.newGroup()

toolBar.isVisible = false
photoScreen.isVisible = false
aboutScreen.isVisible = false
blackBg.alpha = 0

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

function showAboutScreen()
	aboutScreen.y = screenH
	aboutScreen.isVisible = true
	transition.to(aboutScreen, {time=400, y=0, transition=easing.outQuad})
	
	aboutScreen:addEventListener("touch", backToMain)
	return true
end

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

function hideRevealTools()
	local yValue = photoScreenInitY - 56

	if photoScreen.y ~= photoScreenInitY then
		yValue = photoScreenInitY
	end
	
	transition.to(photoScreen, {time=300, y=yValue, transition=easing.outQuad})
	
	return true
end

function backToMain(event)
	local t = event.target
	local phase = event.phase

	if "began" == phase then
		display.getCurrentStage():setFocus( t )
		t.isFocus = true
		
		if defaultField then defaultField:removeSelf() end

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
                if 1 == i then
                	--Don't save and go back to start screen
					blackBg:removeEventListener( "touch", startDraw )
					startScreen.isVisible = true
					blackBg.alpha = 0 
					background.alpha = 1
					startScreen.y = screenH
					transition.to(startScreen, {time=400, y=screenH*0.5, transition=easing.outQuad, onComplete=function() photoScreen.isVisible = false end})
                elseif 2 == i then
                    -- Do nothing; dialog will simply dismiss
                    	hideRevealTools()
                elseif 3 == i then
                	--Save the image and show the start screen
                	saveImage()
					blackBg:removeEventListener( "touch", startDraw )
					startScreen.isVisible = true
					blackBg.alpha = 0 
					background.alpha = 1
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

	if ( "began" == event.phase ) then
		-- This is the "keyboard has appeared" event
		-- In some cases you may want to adjust the interface when the keyboard appears.
	
	elseif ( "ended" == event.phase ) then
		-- This event is called when the user stops editing a field: for example, when they touch a different field
	
	elseif ( "submitted" == event.phase ) then
		-- This event occurs when the user presses the "return" key (if available) on the onscreen keyboard

		-- Hide keyboard
		native.setKeyboardFocus( nil )
		
		local photoText = display.newText(defaultField.text, 0, 0, "MarkerFelt-Wide", 24)
		photoText:setTextColor( 0, 183, 235 )
		photoScreen:insert(photoText)
				
		photoText.x = defaultField.ex
		photoText.y = defaultField.ey

		defaultField.isVisible = false
	end
	
	return true

end

function startDraw( event )	
	local t = event.target
	local phase = event.phase

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
				defaultField = native.newTextField( 0, 0, 180, 30, fieldHandler )
				defaultField.font = native.newFont( "MarkerFelt-Wide", 18 )
				defaultField:setReferencePoint(display.CenterReferencePoint)
				
				native.setKeyboardFocus( defaultField )
				
				defaultField.x = screenW*0.5
				defaultField.y = 50
				
				defaultField.isVisible = true
	
				defaultField.ex = event.x
				defaultField.ey = event.y
	
				display.getCurrentStage():setFocus( nil )
				t.isFocus = false
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
	local toolBgHit = ui.newButton{
		default = "toolHit.png",
		onRelease = hideRevealTools
	}
	toolBar:insert(toolBgHit)
	toolBgHit.x = screenW*0.5
	toolBgHit.y = viewableScreenH - toolBgHit.height*0.5

	local toolBg = display.newRect(0,0, screenW, 60)
	toolBg:setFillColor(140,140,140)
	toolBg.y = viewableScreenH - toolBg.height*0.5
	toolBar:insert(toolBg)	

	local textBtn = ui.newButton{
		default = "textBtn.png",
		over = "textBtn_over.png",
		onRelease = function() 
						toolMode="textTool"; 
						if defaultField then defaultField:removeSelf() end; 
						showTextAlert(); hideRevealTools(); 
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
						if defaultField then defaultField:removeSelf() end; 
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

	timer.performWithDelay(700, hideRevealTools )
		
	return true
end

function onComplete( event )
	local photo = event.target	
	photoIsLandscape = false

	if photo then
		startScreen.isVisible = false
		blackBg.alpha =1 
		background.alpha = 0

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
						
		local toolHit = ui.newButton{
			default = "toolHit.png",
			onRelease = hideRevealTools
		}
		photoScreen:insert(toolHit)
		toolHit.x = screenW*0.5
		toolHit.y = viewableScreenH - toolHit.height*0.5
	
		showToolBar()
		
		photoScreen.y = photoScreenInitY - 56
		
		blackBg:addEventListener( "touch", startDraw )
	else
		blackBg:removeEventListener( "touch", startDraw )
		startScreen.isVisible = true
		blackBg.alpha = 0 
		background.alpha = 1
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


imgBtn:addEventListener( "touch", onReleaseBtn )
cameraBtn:addEventListener( "touch", onReleaseBtn )

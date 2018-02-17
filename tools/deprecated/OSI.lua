OSI = {};
OSI.TriggerTable = {};
OSI.TNumber = 0;
function OSI.AddDrawTrigger(_callback)
	if OSI.TNumber == 0 then
		S5Hook.OSISetDrawTrigger(OSI.DrawTrigger);
	end
	table.insert(OSI.TriggerTable, _callback);
	OSI.TNumber = OSI.TNumber + 1;
	return OSI.TNumber; -- index
end

function OSI.RemoveDrawTrigger(_callbackIndex)
	table.remove(OSI.TriggerTable, _callbackIndex);
	OSI.TNumber = OSI.TNumber - 1;
	if OSI.TNumber == 0 then
		S5Hook.OSIRemoveDrawTrigger()
	end
end

function OSI.DrawTrigger(_eID, _active, _x, _y)
	for i = 1, OSI.TNumber do
		OSI.TriggerTable[i](_eID, _active, _x, _y);
	end
end

--[[ From S5Hook: 
OnScreenInformation (OSI): 
        Draw additional info near entities into the 3D-View (like healthbar, etc).
        You have to set a trigger function, which will be responsible for drawing 
        all info EVERY frame, so try to write efficient code ;)
        
            S5Hook.OSILoadImage(string path)                            Loads a image and returns an image object
                                                                         - Images have to be reloaded after a savegame load
                                                                         - ex: imgObj = S5Hook.OSILoadImage("graphics\\textures\\gui\\onscreen_emotion_good")

            S5Hook.OSIGetImageSize(imgObj)                              Returns sizeX and sizeY of the given image
                                                                         - ex: sizeX, sizeY = S5Hook.OSIGetImageSize(imgObj)

            S5Hook.OSISetDrawTrigger(func callbackFn)                   callbackFn(eID, bool active, posX, posY) will be called EVERY frame for every 
                                                                           currently visible entity with overhead display, the active parameter become true
                                                                           
            S5Hook.OSIRemoveDrawTrigger()                               Stop delivering events

        Only call from the DrawTrigger callback:
            S5Hook.OSIDrawImage(imgObj, posX, posY, sizeX, sizeY)       Draw the image on the screen. Stretching is allowed.
            
            S5Hook.OSIDrawText(text, font, posX, posY, r, g, b, a)      Draw the string on the screen. Valid values for font range from 1-10.
                                                                        The color is specified by the r,g,b,a values (0-255).
                                                                        a = 255 is maximum visibility
                                                                        Standard S5 modifiers are allowed inside text (@center, etc...)
        Example:
        function SetupOSI()
            myImg = S5Hook.OSILoadImage("graphics\\textures\\gui\\onscreen_emotion_good")
            myImgW, myImgH = S5Hook.OSIGetImageSize(myImg)
            S5Hook.OSISetDrawTrigger(cbFn)
        end

        function cbFn(eID, active, x, y)
            if active then
                S5Hook.OSIDrawImage(myImg, x-myImgW/2, y-myImgH/2 - 40, myImgW, myImgH)
            else
                S5Hook.OSIDrawText("eID: " .. eID, 3, x+25, y, 255, 255, 128, 255)
            end
        end   
]]          
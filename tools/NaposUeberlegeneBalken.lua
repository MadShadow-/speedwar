QuestController = {}
function QuestController.Init()
	GUIUpdate_VCTechRaceColor = function() end
	GUIUpdate_VCTechRaceProgress = function() end
	GUIUpdate_GetTeamPoints = function() end
	QuestController.ApplyGUIChanges()
	QuestController.Data = {}
	--[[ Exampleentry:
	{
		id = 3, --UNIQUE ID
		desc = "Schafe geschoren",
		typee = "total", --possible: percent, total
		checkFunc = foobar,
		active = true,
		total = 5
	}
	]]
	QuestController.UniqueIDCounter = 0
	StartSimpleJob("QuestController_Manager")
end
function QuestController.ApplyGUIChanges()
	local barLength = 250
	local textBoxSize = 15
	local barHeight = 4
	local heightElement = 25
	XGUIEng.SetWidgetSize( "VCMP_Window", 252, 294)
	XGUIEng.ShowWidget( "VCMP_Window", 1)
	XGUIEng.ShowAllSubWidgets( "VCMP_Window",1)	
	for i = 1, 8 do
		for j = 1, 8 do
			XGUIEng.ShowWidget( "VCMP_Team"..i.."Player"..j, 0)
		end
		XGUIEng.SetWidgetSize( "VCMP_Team"..i, 252, 32)
		XGUIEng.SetWidgetSize( "VCMP_Team"..i.."Name", 252, 32)
		XGUIEng.ShowWidget( "VCMP_Team"..i.."_Shade", 0)
		XGUIEng.SetMaterialColor( "VCMP_Team"..i.."Name", 0, 0, 0, 0, 0) --hide BG by using alpha = 0
		
		-- use point menu to show numbers
		-- OR DONT.
		XGUIEng.ShowWidget( "VCMP_Team"..i.."PointGame", 0)
		--XGUIEng.ShowWidget( "VCMP_Team"..i.."Points", 1)
		--XGUIEng.SetText( "VCMP_Team"..i.."Points", i)
		--XGUIEng.ShowWidget( "VCMP_Team"..i.."PointBG", 0)
		
		-- manage progress bars
		XGUIEng.ShowWidget( "VCMP_Team"..i.."TechRace", 1)
		XGUIEng.ShowAllSubWidgets( "VCMP_Team"..i.."TechRace", 1)
		XGUIEng.SetWidgetSize( "VCMP_Team"..i.."TechRace", barLength, barHeight)
		XGUIEng.SetWidgetSize( "VCMP_Team"..i.."Progress", barLength, barHeight)
		XGUIEng.SetWidgetSize( "VCMP_Team"..i.."ProgressBG", barLength, barHeight)

		-- widget positions to set
		XGUIEng.SetWidgetPosition( "VCMP_Team"..i, 0, heightElement*(i-1))
		XGUIEng.SetWidgetPosition( "VCMP_Team"..i.."Name", 0, 0)
		XGUIEng.SetWidgetPosition( "VCMP_Team"..i.."TechRace", 0, textBoxSize)
	end
end
function QuestController.UpdateStatus( _id, _data)
	if _id > 8 then return end
	-- create string for stuff
	local myString = _data.desc..": "
	if _data.typee == "percent" then
		local retVal = math.floor(_data.checkFunc())
		if retVal >= 100 then
			myString = myString.." @color:30,150,0 "..retVal.."% @color:255,255,255 "
			XGUIEng.SetProgressBarValues( "VCMP_Team".._id.."Progress", 100, 100)
			XGUIEng.SetMaterialColor( "VCMP_Team".._id.."Progress", 0, 30, 150, 0, 255)
		else
			myString = myString..retVal.."% @color:255,255,255 "
			XGUIEng.SetProgressBarValues( "VCMP_Team".._id.."Progress", retVal, 100)
			QuestController.SetColor( "VCMP_Team".._id.."Progress", retVal/100)
		end
	else
		local retVal = _data.checkFunc()
		if retVal >= _data.total then
			myString = myString.."@color:30,150,0 "..retVal.." von ".._data.total
			XGUIEng.SetProgressBarValues( "VCMP_Team".._id.."Progress", 100, 100)
			XGUIEng.SetMaterialColor( "VCMP_Team".._id.."Progress", 0, 30, 150, 0, 255)
		else
			myString = myString..retVal.." von ".._data.total
			XGUIEng.SetProgressBarValues( "VCMP_Team".._id.."Progress", retVal, _data.total)
			QuestController.SetColor( "VCMP_Team".._id.."Progress", retVal/_data.total)
		end
	end
	XGUIEng.SetText( "VCMP_Team".._id.."Name", myString)
	XGUIEng.ShowWidget( "VCMP_Team".._id, 1)
end
function QuestController.SetColor( _wId, _progress)
	-- author isnt a smart man
	_progress = 1 - _progress
	-- gradient 30, 150 to 255,242 to 255,0
	local r = 0
	local g = 0
	if _progress < 0.5 then
		r = math.floor( 255*2*_progress + 30*(1-2*_progress))
		g = math.floor( 242*2*_progress + 150*(1-2*_progress))
	else
		_progress = _progress - 0.5
		r = 255
		g = math.floor(242*(1-2*_progress))
	end
	XGUIEng.SetMaterialColor( _wId, 0, r, g, 0, 255)
end
function QuestController_Manager()
	XGUIEng.ShowAllSubWidgets( "VCMP_Window", 0)
	local wId = 1
	for k,v in pairs(QuestController.Data) do
		if v.active then
			QuestController.UpdateStatus( wId, v)
			wId = wId + 1
		end
	end
end
function QuestController.Disable( _id)
	for k,v in pairs(QuestController.Data) do
		if v.id == _id then
			v.active = false
			break;
		end
	end
end
function QuestController.Add( _type, _countfunc, _desc, _total)
	if not (_type == "percent" or _type == "total") then
		assert(false, "QuestController.Add got wrong _type. _type has to be `percent` or `total`!")
	end
	local entry = {
		id = QuestController.GetUniqueID(),
		desc = _desc,
		typee = _type,
		active = true,
		checkFunc = _countfunc
	}
	if _total then
		entry.total = _total
	end
	table.insert( QuestController.Data, entry)
	return entry.id
end
function QuestController.GetUniqueID()
	QuestController.UniqueIDCounter = QuestController.UniqueIDCounter + 1
	return QuestController.UniqueIDCounter
end
--
-- rangeSystem for Multi Theft Auto: San Andreas
--
-- Contributors:
--   Rick (https://github.com/httpRick)
--   Nando (https://github.com/Fernando-A-Rocha)
--

--------------------------------------------------- CONFIG ----------------------------------------------------
local ENABLE_DEBUG = true
local COMMAND_DEBUG = "showranges"
local DETECT_ELEMENT_TYPES = {"player", "ped", "vehicle", "object", "pickup", "marker"}
---------------------------------------------------------------------------------------------------------------

local ranges = {}
local resources = {}
local isClientFile = isElement(localPlayer)
local _getElementsWithinRange = getElementsWithinRange

local syncRangesWithClients = function() end

math.randomseed(os.time())

addEvent(isClientFile and "onClientRangeHit" or "onRangeHit", true)
addEvent(isClientFile and "onClientRangeLeave" or "onRangeLeave", true)

if ENABLE_DEBUG then
	if not isClientFile then
		syncRangesWithClients = function()
			setElementData(resourceRoot, "serversideRanges", ranges)
		end
	else
		local syncedRanges = {}
		addEventHandler("onClientElementDataChange", resourceRoot, function(theKey, oldValue, newValue)
			if theKey == "serversideRanges" then
				syncedRanges = newValue or {}
			end
		end, false)

		local showRanges = false

		local function drawRange(rangeElement, v)
			local x,y,z = getElementPosition(rangeElement)
			if v.attach then
				local x2, y2, z2 = getElementPosition(v.attach.element)
				x, y, z = x2+v.attach.position.x, y2+v.attach.position.y, z2+v.attach.position.z
			end
			local radius = v.radius
			local color = v.color
			dxDrawWiredSphere(x, y, z, radius, color, 3.5, 1)
		end

		local function onClientRenderRange()
			local pdimension, pinterior = getElementDimension(localPlayer), getElementInterior(localPlayer)
			for rangeElement, v in pairs(ranges) do
				local dimension, interior = getElementDimension(rangeElement), getElementInterior(rangeElement)
				if pdimension == dimension and pinterior == interior then
					drawRange(rangeElement, v)
				end
			end
			for rangeElement, v in pairs(syncedRanges) do
				if not isElement(rangeElement) then
					syncedRanges[rangeElement] = nil
				else
					local dimension, interior = getElementDimension(rangeElement), getElementInterior(rangeElement)
					if pdimension == dimension and pinterior == interior then
						drawRange(rangeElement, v)
					end
				end
			end
		end

		local function togShowRanges()
			showRanges = not showRanges
			if showRanges then
				addEventHandler("onClientRender", root, onClientRenderRange)
			else
				removeEventHandler("onClientRender", root, onClientRenderRange)
			end
			outputChatBox("Ranges: "..(showRanges and "#00ff00on" or "#ffff00off"), 255, 194, 14, true)
		end
		addCommandHandler(COMMAND_DEBUG, togShowRanges)
	end
end

function setElementResource(element, theResource)
	if isElement(element) then
		theResource = theResource or resourceRoot
		if type(resources[theResource]) ~= "table" then
			resources[theResource] = {}
		end
		table.insert(resources[theResource], element)
		if theResource ~= resourceRoot then
			setElementParent(element, getResourceDynamicElementRoot(theResource) )
		end
	end
end

local function handleElementDestroyed()
	local elementType = getElementType(source)
	if elementType == "range" then
		if ranges[source] then
			ranges[source] = nil
			syncRangesWithClients()
		end
		return
	end
	local isDetected = false
	for _, name in ipairs(DETECT_ELEMENT_TYPES) do
		if name == elementType then
			isDetected = true
			break
		end
	end
	if isDetected then
		local rangeElement = getElementRange(source)
		if rangeElement then
			elementOutRange(rangeElement, source)
		end
	end
end
addEventHandler("onElementDestroy", root, handleElementDestroyed)

-- Exported
function createRange(x, y, z, radius, dimension, interior, data)
	local rangeElement = createElement("range")
	setElementPosition(rangeElement, x, y, z)
	if dimension then
		setElementDimension(rangeElement, dimension)
	end
	if interior then
		setElementInterior(rangeElement, interior)
	end
	ranges[rangeElement] = {data = data, radius = radius, elements = {}, color=tocolor(math.random(1,255)-1, math.random(1,255)-1, math.random(1,255)-1, 255)}
	setElementResource(rangeElement, sourceResource)
	syncRangesWithClients()
	return rangeElement
end

-- Exported
function getRangeRadius(rangeElement)
	local range = getRange(rangeElement)
	if range then
		return range.radius
	end
end

function getRangePosition(rangeElement)
	local range = getRange(rangeElement)
	if range then
		if range.attach then
			local x, y, z = getElementPosition(range.attach.element)
			x, y, z = x+range.attach.position.x, y+range.attach.position.y, z+range.attach.position.z
			return x, y, z
		else
			local x, y, z = getElementPosition(rangeElement)
			return x, y, z
		end
	end
end

-- Exported
function getElementRange(theElement)
	for rangeElement,v in pairs(ranges) do
		if v.elements[theElement] then
			return rangeElement
		end
	end
	return false
end

-- Exported
function getElementsWithinRange(rangeElement, elementType)
	local range = getRange(rangeElement)
	if range then
		local x, y, z = getRangePosition(rangeElement)
		local elements = _getElementsWithinRange(x, y, z, range.radius, elementType)
		return elements
	end
	return false
end

-- Exported
function attach(rangeElement, theElement, xPosOffset, yPosOffset, zPosOffset)
	if isElement(theElement) then
		if ranges[rangeElement] and not ranges[rangeElement].attach then
			ranges[rangeElement].attach = {element = theElement, position = {x = xPosOffset or 0, y = yPosOffset or 0, z = zPosOffset or 0} }
			syncRangesWithClients()
			return true
		end
	end
	return false
end

-- Exported
function detach(rangeElement, theElement)
	if isElement(theElement) then
		if ranges[rangeElement] and ranges[rangeElement].attach and ranges[rangeElement].attach.element == theElement then
			local x, y, z = getElementPosition(theElement)
			setElementPosition(rangeElement, x, y, z)
			ranges[rangeElement].attach = nil
			syncRangesWithClients()
		end
	end
end

function getRange(rangeElement)
	return ranges[rangeElement] or false
end

-- Exported
function isElementWithinRange(theElement, rangeElement)
	local range = getRange(rangeElement)
	if range then
		return range.elements[theElement] and range.elements[theElement].result or false
	end
	return nil
end

function elementInRange(rangeElement, theElement)
	local range = getRange(rangeElement)
	if range and not range.elements[theElement] then
		range.elements[theElement] = {result = true, element = theElement}
		syncRangesWithClients()
		triggerEvent(isClientFile and "onClientRangeHit" or "onRangeHit",
			rangeElement, theElement,
			getElementDimension(theElement) == getElementDimension(rangeElement),
			getElementInterior(theElement) == getElementInterior(rangeElement),
			range.data
		)
	end
end

function elementOutRange(rangeElement, theElement)
	local range = getRange(rangeElement)
	if range and range.elements[theElement] then
		range.elements[theElement] = nil
		syncRangesWithClients()
		triggerEvent(isClientFile and "onClientRangeLeave" or "onRangeLeave",
		rangeElement, theElement,
		getElementDimension(theElement) == getElementDimension(rangeElement),
		getElementInterior(theElement) == getElementInterior(rangeElement),
		range.data
	)
	end
end

function processingOutRange(rangeElement, inRange)
	local range = getRange(rangeElement)
	if range then
		for element in pairs(range.elements) do
			if not inRange[element] then
				elementOutRange(rangeElement, element)
			end 
		end
	end
end

local function between(a, b, c)
	return c >= a and c <= b
end

function processingRange()
	for rangeElement,v in pairs(ranges) do
		local inRange = {}
		for typeID = 1, #DETECT_ELEMENT_TYPES do
			local x, y, z = getRangePosition(rangeElement)
			local elements = _getElementsWithinRange(x, y, z, v.radius, DETECT_ELEMENT_TYPES[typeID] )
			if #elements ~= 0 then
				for elementID = 1, #elements do
					local element = elements[elementID]
					local _, _, elementZ = getElementPosition(element)
					if between(z-v.radius, z+v.radius, elementZ) then 
						elementInRange(rangeElement, element)
						inRange[element] = true
					end
				end
			end
		end
		processingOutRange(rangeElement, inRange)
	end
end
setTimer(processingRange, 50, 0)

function handleResourceStop(stoppedRes)
	if resources[stoppedRes] then
		for i=1,#resources[stoppedRes] do
			local element = resources[stoppedRes][i]
			if isElement(element) then
				destroyElement(element)
			end
			ranges[element] = nil
		end
	end
end

if isClientFile then
	addEventHandler("onClientResourceStop", root, handleResourceStop)
else
	addEventHandler("onResourceStop", root, handleResourceStop)
end

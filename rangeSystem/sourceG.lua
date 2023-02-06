local ranges = {}
local resources = {}
local collection = {}
local isClientFile = isElement(localPlayer)
_getElementsWithinRange = getElementsWithinRange

addEvent(isClientFile and "onClientRangeHit" or "onRangeHit", true)
addEvent(isClientFile and "onClientRangeLeave" or "onRangeLeave", true)

local function between(a, b, c)
	return c >= a and c <= b
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

function createRange(x, y, z, radius)
	local rangeElement = createElement("range")
	setElementPosition(rangeElement, x, y, z)
	setElementData(rangeElement, "radius", radius)
	ranges[rangeElement] = {x = x, y = y, z = z, radius = radius, this = rangeElement, elements = {}}
	setElementResource(rangeElement, sourceResource)
	return rangeElement
end

function getRangeRadius(rangeElement)
	local range = getRange(rangeElement)
	if range then
		setElementData(rangeElement, "radius", radius)
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

function getElementRange(theElement)
	return collection[theElement] or false
end

function getElementsWithinRange(rangeElement, elementType)
	local range = getRange(rangeElement)
	if range then
		local x, y, z = getRangePosition(rangeElement)
		local elements = _getElementsWithinRange(x, y, z, range.radius, elementType)
		return elements
	end
	return false
end

function attach(rangeElement, theElement, xPosOffset, yPosOffset, zPosOffset)
	if isElement(theElement) then
		if ranges[rangeElement] and not ranges[rangeElement].attach then
			ranges[rangeElement].attach = {element = theElement, position = {x = xPosOffset or 0, y = yPosOffset or 0, z = zPosOffset or 0} }
			setElementData(rangeElement, "attach", ranges[rangeElement].attach)
			return true
		end
	end
	return false
end

function detach(rangeElement, theElement)
	if isElement(theElement) then
		if ranges[rangeElement] and ranges[rangeElement].attach and ranges[rangeElement].attach.element == theElement then
			local x, y, z = getElementPosition(theElement)
			setElementPosition(rangeElement, x, y, z)
			setElementData(rangeElement, "attach", nil)
			ranges[rangeElement].attach = nil
		end
	end
end


function getRange(rangeElement)
	return ranges[rangeElement] or false
end

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
		collection[theElement] = range.this
		triggerEvent(isClientFile and "onClientRangeHit" or "onRangeHit", rangeElement, theElement, getElementDimension(theElement) == getElementDimension(rangeElement), getElementInterior(theElement) == getElementInterior(rangeElement) )
	end
end

function elementOutRange(rangeElement, theElement)
	local range = getRange(rangeElement)
	if range and range.elements[theElement] then
		range.elements[theElement] = nil
		collection[theElement] = nil
		triggerEvent(isClientFile and "onClientRangeLeave" or "onRangeLeave", rangeElement, theElement, getElementDimension(theElement) == getElementDimension(rangeElement), getElementInterior(theElement) == getElementInterior(rangeElement) )
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

function processingRange()
	local elementsType = {"player", "ped", "vehicle", "object", "pickup", "marker"}
	for i,v in pairs(ranges) do
		local inRange = {}
		for typeID = 1, #elementsType do
			local x, y, z = getRangePosition(v.this)
			local elements = _getElementsWithinRange(x, y, z, v.radius, elementsType[typeID] )
			if #elements ~= 0 then
				for elementID = 1, #elements do
					local element = elements[elementID]
					local _, _, elementZ = getElementPosition(element)
					if between(z-v.radius, z+v.radius, elementZ) then 
						elementInRange(v.this, element)
						inRange[element] = true
					end
				end
			end
		end
		processingOutRange(v.this, inRange)
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
		end
	end
end

if isClientFile then
	addEventHandler("onClientResourceStop", root, handleResourceStop)
else
	addEventHandler("onResourceStop", root, handleResourceStop)
end

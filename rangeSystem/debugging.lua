showRange = 1
onShowRange = false

local function getRangePosition(rangeElement)
	if isElement(rangeElement) then
		local attach = getElementData(rangeElement, "attach")
		if attach then
			local x, y, z = getElementPosition(attach.element)
			x, y, z = x+attach.position.x, y+attach.position.y, z+attach.position.z
			return x, y, z
		else
			local x, y, z = getElementPosition(rangeElement)
			return x, y, z
		end
	end
end

function showRange(cmd)
	showRange = showRange == 0 and 1 or 0
	outputConsole(cmd.." is now set to "..showRange)
	local boolean = getDevelopmentMode()
	if onShowRange and showRange == 0 then
		removeEventHandler("onClientRender", root, onClientRenderRange)
		onShowRange = false
	elseif not onShowRange and showRange == 1 then
		if not boolean then
			outputConsole(cmd.." will have no effect because development mode is off")
			return
		end
		addEventHandler("onClientRender", root, onClientRenderRange)
		onShowRange = true
	end
end
addCommandHandler("showrange", showRange)

function dxDrawRange(TheElement)
	local boolean = getDevelopmentMode()
	if boolean then
		local radius = getElementData(TheElement, "radius") or 0
		local x, y, z = getRangePosition(TheElement)
		dxDrawWiredSphere(x, y, z, radius, tocolor(255, 175, 0, 255), 3.5, 1)
	else
		onShowRange = false
		removeEventHandler("onClientRender", root, onClientRenderRange)
	end
end

function onClientRenderRange()
	local pool = getElementsByType("range")
	for i=1,#pool do
		local TheElement = pool[i]
		if isElement(TheElement) then
			local x, y, z = getRangePosition(TheElement)
			local x2, y2, z2 = getCameraMatrix()
			local radius = getElementData(TheElement, "radius") or 0
			dxDrawRange(TheElement)
		end
	end
end

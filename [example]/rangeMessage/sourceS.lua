local rangeZone = exports["rangeSystem"]:createRange(2488.00, -1664.32, 14.34, 1)

function example_enter(theElement, matchingDimension, matchingInterior)
    if getElementType(theElement) == "player" and matchingDimension and matchingInterior then
        outputChatBox("[Server] "..getPlayerName(theElement).." enter the range.")
    end
end
addEventHandler( "onRangeHit", rangeZone, example_enter)

function example_leave(theElement, matchingDimension, matchingInterior)
    if getElementType(theElement) == "player" then
        outputChatBox("[Server] "..getPlayerName(theElement).." leave the range.")
    end
end
addEventHandler("onRangeLeave", rangeZone, example_leave)

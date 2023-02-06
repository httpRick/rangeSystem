local rangeZone = exports["rangeSystem"]:createRange(2488.00, -1664.32, 13.34, 1)

function example_enter(theElement, matchingDimension, matchingInterior)
    if getElementType(theElement) == "player" and matchingDimension and matchingInterior then
        outputChatBox("[Client] "..getPlayerName(theElement).." enter the range.")
    end
end
addEventHandler( "onClientRangeHit", rangeZone, example_enter)

function example_leave(theElement, matchingDimension, matchingInterior)
    if getElementType(theElement) == "player" then
        outputChatBox("[Client] "..getPlayerName(theElement).." leave the range.")
    end
end
addEventHandler("onClientRangeLeave", rangeZone, example_leave)

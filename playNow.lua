-----------------------------------------------------------------------------------------
--
--                                  menu.lua
--
-----------------------------------------------------------------------------------------
local playNowCreateObjects = require("playNowCreateObjects")
local scene = composer.newScene()
local myUserArea, user2Area, user3Area, user4Area
local cards, backCards, playAreaGroup, cardWidth, cardHeight
local myCards, user2Cards, user3Cards, user4Cards, playAreaGroupCards = {}, {}, {}, {}, {}
user2Cards.name = "User 2"
user3Cards.name = "User 3"
user4Cards.name = "User 4"
myCards.name    = "You"
local playersInGame = {}
table.insert(playersInGame, myCards )
table.insert(playersInGame, user2Cards )
table.insert(playersInGame, user3Cards )
table.insert(playersInGame, user4Cards )

local user2backCards,user3backCards, user4backCards = {}, {}, {}
local handCardIndex = 1
local yourTurn      = false
local counter       = 1
local hand          = 1
local cutterSuit
local deckIsEmpty = false
local UserToAddIndex 
local UserToCutIndex
local myCardWasAdded = false
math.randomseed(os.time())

--------------------------------------------------------------------------------------------------
function cardTapped(event)
    if (hand == 4 ) then
        local validateResult = ValidateMyCut(event.target)
        if validateResult.canCut==true then
            AddMyCard(event.target, validateResult)
        else 
            UpdateStatusBar("You Cant Cut With That!..")
        end
    else
        if yourTurn then
            local added = AddMyCard(event.target)
            if added then 
                myCardWasAdded = true
                myUserArea.doneButton:setEnabled(true)
                myUserArea.doneButton:setFillColor(1)
            end
        end
    end
    return true
end
function cardDragged(event)
    local self = event.target
    if event.phase == "began" then
        -- first we set the focus on the object
        display.getCurrentStage():setFocus( self, event.id )
        self.isFocus = true

        -- then we store the original x and y position
        self.markX = self.x
        self.markY = self.y

    elseif self.isFocus then
        if event.phase == "moved" then
              -- then drag our object
              self.x = event.x - event.xStart + self.markX
              self.y = event.y - event.yStart + self.markY
              for i=1, table.maxn(playAreaGroupCards) do 
                if (hasCollided(playAreaGroupCards[i], self)) then
                    playAreaGroupCards[i].strokeWidth = 3
                    playAreaGroupCards[i]:setStrokeColor( 1, 0, 0, .4 )
                else
                    playAreaGroupCards[i].strokeWidth = 0
                end
              end
        elseif event.phase == "ended" or event.phase == "cancelled" then
            -- we end the movement by removing the focus from the object
            display.getCurrentStage():setFocus( self, nil )
            for i=1, table.maxn(playAreaGroupCards) do 
                if (hasCollided(playAreaGroupCards[i], self)) then
                    local validateResult = ValidatedDraggedCut(self, playAreaGroupCards[i])
                    if validateResult.canCut==true then
                        AddMyCard(self, validateResult)
                        return true
                    else 
                        UpdateStatusBar("You Cant Cut With That!..")
                        transition.moveTo(self, {x=self.markX, y=self.markY, time = 300})
                    end
                else 
                    transition.moveTo(self, {x=self.markX, y=self.markY, time = 300})
                end
            end
            self.isFocus = false
        end
    end
     return true
end

function doneButtonPressed (event)
    myUserArea.doneButton:setFillColor( 0 )

    if hand == 1 then
        hand1Helper()
    elseif hand == 2 then
        if isAllCardsCut() then
            print (json.prettify(playAreaGroupCards))
            ClearTheBoard(true)
            hand = hand + 1
            GamePlay()
        else
            hand2Helper()
        end
    elseif hand == 3 then
        hand3Helper()
    elseif hand == 4 then
        if isAllCardsCut() == false then
            ClearTheBoard(false, myCards)
            hand =  2
            GamePlay()
        else
            GamePlay()
        end
    end
end
function hand1Helper()
    print (tostring(myCardWasAdded))
        if myCardWasAdded then 
            local didCut = CutCards(getNextUserToCut())
            if didCut then 
                myCardWasAdded = false
                YourTurn("add")
            else
                ClearTheBoard(false,user2Cards)
                hand = hand + 2
                GamePlay()
            end
        else
            timer.performWithDelay(2000, function()
                AddCards(user3Cards)
                timer.performWithDelay(2000, function()
                    AddCards(user4Cards)
                    timer.performWithDelay(2000, function()
                        if isAllCardsCut() then
                            ClearTheBoard(true)
                            hand = hand + 1 
                            GamePlay()
                        else
                            if CutCards(user2Cards) then
                                GamePlay()
                            else
                                ClearTheBoard(false, user2Cards)
                                hand = hand + 2
                                GamePlay()
                            end
                        end
                    end)
                end)
            end)
        end
end
function hand2Helper()
    timer.performWithDelay(2000, function ()
        local didCut = CutCards(getNextUserToCut())
            if didCut then 
                GamePlay()
            else 
                timer.performWithDelay(2000, function()
                    ClearTheBoard(false, user3Cards)
                    hand = hand + 2
                    GamePlay()
                end)
            end
    end)
end
function hand3Helper()
    timer.performWithDelay(2000, function ()
        AddCards(user2Cards)
        timer.performWithDelay(2000, function()
            if isAllCardsCut() then
                ClearTheBoard(true)
                hand = hand + 1
                GamePlay()
            else 
                local didCut = CutCards(getNextUserToCut())
                if didCut then 
                    GamePlay()
                else 
                    timer.performWithDelay(2000, function()
                        ClearTheBoard(false, user4Cards)
                        hand = hand + 2
                        GamePlay()
                    end)
                end 
            end
        end)     
    end)
end
function hand4Helper()
    timer.performWithDelay(2000, function ()
        AddCards(user2Cards)
        timer.performWithDelay(2000, function () 
                AddCards(user3Cards) 
                timer.performWithDelay(2000, function () 
                    AddCards(user4Cards) 
                    timer.performWithDelay(2000, function()
                        local needsToBeCut = {}
                        for i=1, table.maxn(playAreaGroupCards) do 
                            if (playAreaGroupCards[i].hasBeenCut ~= true ) then
                                table.insert(needsToBeCut, playAreaGroupCards[i])
                            end
                        end
                        if table.maxn (needsToBeCut) == 0 then
                            ClearTheBoard(true)
                            hand = hand + 1
                            GamePlay()
                        else
                            YourTurn("cut")
                        end
                    end)
                end)
        end)
    end)
end
local del = 500;
function dealMe(numberOfCards)
      if (handCardIndex > 52) then 
            deckIsEmpty = true
            return 
      end
      local contentX,contentY = sceneGroup.myUserArea.myUserCards:localToContent( 0, 0 )
      myCards.x = contentX
      myCards.y = contentY
      table.insert(myCards, cards[handCardIndex])
      sceneGroup.cards[handCardIndex]:addEventListener( "tap", cardTapped )
      --sceneGroup.cards[handCardIndex]:addEventListener( "touch", cardDragged )
      local obj = sceneGroup.backCards[handCardIndex]
      local myCardObj = sceneGroup.cards[handCardIndex]
      sceneGroup.cards[handCardIndex].x = obj.x
      sceneGroup.cards[handCardIndex].y = obj.y
      
      local x = transition.moveTo(obj, {x=findEmptySpotInHolder(), y=contentY, time=50, 
                                    onComplete = function ( obj )
                                                    myCardObj.x = obj.x
                                                    myCardObj.y = obj.y
                                                    transition.dissolve( obj, myCardObj, 100 )
                                                    dealMeHelper(numberOfCards)
                                                end}) 
      handCardIndex = handCardIndex + 1       
end
function dealMeHelper(numberOfCards)
    if (numberOfCards <= 1 ) then
        return
    end
    numberOfCards  = numberOfCards - 1
    dealMe(numberOfCards)
end
function dealUser2(numberOfCards)
    for i=1, numberOfCards do
        if (handCardIndex > 52) then 
            deckIsEmpty = true
            return 
        end
          local contentX,contentY = user2Area.user2CardContainer:localToContent( 0, 0 )
          user2Cards.x = contentX
          user2Cards.y = contentY
          cards[handCardIndex].x = contentX
          cards[handCardIndex].y = contentY
          cards[handCardIndex].isVisible = false
          table.insert(user2Cards, cards[handCardIndex])
          sceneGroup.cards[handCardIndex]:addEventListener( "tap", cardTapped )

          transition.moveTo(backCards[handCardIndex], {delay = del, x = contentX, y = contentY, time=100})
          table.insert( user2backCards, backCards[handCardIndex] )
          del = del + 50
          handCardIndex = handCardIndex + 1 
    end
end
function dealUser3(numberOfCards)
    for i=1, numberOfCards do
        if (handCardIndex > 52) then 
            deckIsEmpty = true
            return 
        end
          local contentX,contentY = user3Area.user3CardContainer:localToContent( 0, 0 )
          user3Cards.x = contentX
          user3Cards.y = contentY
          cards[handCardIndex].x = contentX
          cards[handCardIndex].y = contentY
          cards[handCardIndex].isVisible = false
          table.insert(user3Cards, cards[handCardIndex])
          sceneGroup.cards[handCardIndex]:addEventListener( "tap", cardTapped )

          transition.moveTo(backCards[handCardIndex], {delay= del,x=contentX, y=contentY, time=100})
          table.insert( user3backCards, backCards[handCardIndex] )
          del = del + 50
          handCardIndex = handCardIndex + 1
    end
end
function dealUser4(numberOfCards)
    for i=1, numberOfCards do
          if (handCardIndex > 52) then 
            deckIsEmpty = true
            return 
        end
          local contentX,contentY = user4Area.user4CardContainer:localToContent( 0, 0 )
          user4Cards.x = contentX
          user4Cards.y = contentY
          cards[handCardIndex].x = contentX
          cards[handCardIndex].y = contentY
          cards[handCardIndex].isVisible = false
          table.insert(user4Cards, cards[handCardIndex])
          sceneGroup.cards[handCardIndex]:addEventListener( "tap", cardTapped )

          transition.moveTo(backCards[handCardIndex], {delay= del,x=contentX, y=contentY, time=100})
          table.insert( user4backCards, backCards[handCardIndex] )
          del = del + 50
          handCardIndex = handCardIndex + 1
     end
end
function dealCards(numberPerPerson)
    dealMe(12)
    dealUser2(12)
    dealUser3(12)
    dealUser4(12)
    timer.performWithDelay(4000, reArrangeMyCards)
    yourTurn = true
end

function GamePlay()
if hand > table.maxn(playAreaGroupCards) then hand = 1 end
    if UserInGameValidation() then
        if hand ==1 then
            timer.performWithDelay(2000, function()
                if table.maxn(playAreaGroupCards) == 0 then YourTurn("start")
                    else YourTurn("add") end
            end)
        elseif hand == 2 then
            print ("game play 2")
        timer.performWithDelay(2000, function() 
            if AddCards(user2Cards) then
                timer.performWithDelay(2000, function()
                    if CutCards(getNextUserToCut()) then
                        GamePlay()
                    else
                        timer.performWithDelay(2000, function()
                            ClearTheBoard(false, user3Cards)
                            hand = hand + 2
                            GamePlay()
                        end)
                    end
                end)
            else
                timer.performWithDelay(2000, function()
                    AddCards(user4Cards)
                    timer.performWithDelay(2000, function()
                        YourTurn("add")
                    end)
                end)
            end       
        end)
        elseif hand == 3 then
            timer.performWithDelay(2000, function()
                if AddCards(user3Cards) then
                    timer.performWithDelay(2000, function()
                        if CutCards(getNextUserToCut()) then
                            GamePlay()
                        else
                            timer.performWithDelay(2000, function()
                                ClearTheBoard(false, user4Cards)
                                hand = hand + 2
                                GamePlay()
                            end)
                        end
                    end)
                else
                    timer.performWithDelay(2000, function()
                        timer.performWithDelay(2000, function()
                            YourTurn("add")
                        end)
                    end)
                end       
            end)
        elseif hand == 4 then
            timer.performWithDelay(2000, function() 
                if AddCards(user4Cards) then
                    timer.performWithDelay(2000, function()
                        YourTurn("cut")
                    end)
                else
                    timer.performWithDelay(2000, function()
                        AddCards(user2Cards)
                        timer.performWithDelay(2000, function()
                            AddCards(user3Cards)
                            timer.performWithDelay(2000, function()
                                if isAllCardsCut() then 
                                    ClearTheBoard(true)
                                    hand = hand + 1
                                    GamePlay()
                                else
                                    YourTurn("cut")
                                end
                            end)
                        end)
                    end)
                end
            end)
        end
    else
        hand = hand + 1
        --print ("THIS USER IS OUT OF GAME")
        GamePlay()
    end
end
function YourTurn(request)
    myUserArea.doneButton:setFillColor( 1 )
    yourTurn = true
    if(request == "start") then
        UpdateStatusBar( "Your Turn To Start!")
    elseif request == "add" then
        UpdateStatusBar( "Would You Like To Add?")
    elseif request == "cut" then
        UpdateStatusBar(  "Your Turn To Cut!")
    end
end
function AddCards(userCards)
    if UserInGameValidation == false then return end
    UpdateStatusBar(userCards.name .. " is Adding a Card !")
    local totalCut = 0
    for i=1, table.maxn(playAreaGroupCards) do
        if playAreaGroupCards[i].hasBeenCut then 
            totalCut = totalCut +1
        end
    end
    if (totalCut <= 6) then 
        local added = false
        if (table.maxn(playAreaGroupCards) == 0) then
            local cardsList = {}
            for i=1, table.maxn(userCards) do
                local cardSuit = getCardSuit(userCards[i])
                if deckIsEmpty ~= true then
                    if cardSuit ~= cutterSuit then
                        local value = getCardValue (userCards[i])
                        table.insert(cardsList, tonumber(value))
                    end
                else
                    local value = getCardValue (userCards[i])
                    table.insert(cardsList, tonumber(value))
                end
            end
            table.sort(cardsList)
            local addCards = {}
            
            for i=1, table.maxn(userCards) do
                local cardSuit = getCardSuit(userCards[i])
                local carValue = tonumber(getCardValue(userCards[i]))
                if deckIsEmpty ~= true then
                    if (cardSuit ~= cutterSuit) then
                        if (carValue == cardsList[1]) then
                            table.insert(addCards, userCards[i] )
                            added = true
                        end
                    end
                else
                    if (carValue == cardsList[1]) then
                            table.insert(addCards, userCards[i] )
                            added = true
                    end
                end
            end
            AddCardsHelper(userCards, addCards)
            if added then return true end
        else
            local addCardsList = {}
            local canAdd = false
            local temp = {}
            for i=1, table.maxn(userCards) do
                table.insert(temp, userCards[i])
            end

            for x=1, table.maxn(playAreaGroupCards) do
                local size = table.maxn(temp)
                for i = 1, size do
                    if i >= size then break end
                    if getCardValue(temp[i]) == getCardValue(playAreaGroupCards[x]) then
                        if (getCardSuit(temp[i]) ~= cutterSuit) then
                            table.insert(addCardsList, temp[i])
                            table.remove(temp,i)
                            size = size - 1
                            added = true
                        end
                    end 
                end
            end
            AddCardsHelper(userCards, addCardsList)
            if added then return true end
        end
    end
end
function AddCardsHelper(usersCards, cardsList)
    if table.maxn(cardsList) == 0 then return end
    local card = cardsList[1]
    local emptySpot = findNextPlayAreaSpot()
    removedCardIndex = table.indexOf(usersCards, card)

    table.remove(usersCards, removedCardIndex)
    table.insert(playAreaGroupCards, card)
    table.remove(cardsList, 1)
    card.hasBeenCut = false
    

    local x = transition.moveTo(card, {x= emptySpot.moveToX, y=emptySpot.moveToY, time=400,
                                    onStart = function ()
                                        card.isVisible = true
                                    end,
                                    onComplete = function () AddCardsHelper(usersCards, cardsList) end})
end
function AddMyCard(card, validatedParam)
    local cardValue = getCardValue(card)
    local cardAdded = false
    if(yourTurn and hand ~= 4 ) then
        if (table.maxn(playAreaGroupCards) == 0) then
            local nextSpot = findNextPlayAreaSpot()
            nextSpot.x = nextSpot.moveToX
            nextSpot.y = nextSpot.moveToY
            addMyCardHelper(card, myCards,nextSpot)
            cardAdded = true
        else
            local canAdd = false
            for i=1, table.maxn(playAreaGroupCards) do
                local value = getCardValue(playAreaGroupCards[i])
                if (value == cardValue) then
                    canAdd = true
                end  
            end
            if (canAdd) then                
                local nextSpot = findNextPlayAreaSpot()
                nextSpot.x = nextSpot.moveToX
                nextSpot.y = nextSpot.moveToY
                addMyCardHelper(card, myCards,nextSpot) 
                myUserArea:localToContent( 0, 0 )
                cardIndex = table.indexOf(myCards, cards)
                cardAdded = true
            end
        end
    elseif hand == 4 then
        cardAdded = true
        local nextSpot = {}
        nextSpot.x, nextSpot.y = validatedParam.x, validatedParam.y
        addMyCardHelper(card, myCards, nextSpot)
    end
    return cardAdded
end
function addMyCardHelper (card, usersCards, spot)
        local removedCardIndex

        card.isVisible = true
        if hand ~= 4 then card.hasBeenCut = false end
        removedCardIndex = table.indexOf(usersCards, card)
        table.remove(usersCards, removedCardIndex)
        table.insert(playAreaGroupCards, card)

        transition.moveTo(card, {x=spot.x, y=spot.y, time=300,
                 onComplete = function ()
                        
                    end
                    })              
end
function CutCards(userCards)
    UpdateStatusBar(userCards.name .. " is Cutting The Cards !")
    local numberOfCuts = 0;
    for i=1, table.maxn(playAreaGroupCards) do
        if (playAreaGroupCards[i].hasBeenCut) then
            numberOfCuts = numberOfCuts + 1
        end
    end
    for i=1, table.maxn( playAreaGroupCards ) do
        if (playAreaGroupCards[i].hasBeenCut ~= true) then
            local cutCardVal  = getCardValue(playAreaGroupCards[i])
            local cutCardSuit = getCardSuit(playAreaGroupCards[i])
            for x=1, table.maxn(userCards) do
                local cardVal = getCardValue(userCards[x])
                local cardSuit = getCardSuit(userCards[x])
                if (cardSuit == cutCardSuit) then
                    cutCardVal = tonumber( cutCardVal )
                    cardVal = tonumber(cardVal)
                    if (cardVal > cutCardVal) then
                        playAreaGroupCards[i].hasBeenCut = true
                        local obj = userCards[x]
                        transition.moveTo(obj, {x=playAreaGroupCards[i].x+20, y=playAreaGroupCards[i].y, time=200, onStart = function (obj) 
                                                    obj.isVisible=true 
                                                end})
                        obj.hasBeenCut = true
                        table.insert(playAreaGroupCards, obj)
                        table.remove(userCards, x)
                        numberOfCuts = numberOfCuts + 2
                        counter = counter + 1;
                        break;
                    else
                    end
                end
            end
        end
    end
    if numberOfCuts ~= table.maxn( playAreaGroupCards ) then
        for i=1, table.maxn( playAreaGroupCards ) do
            if (playAreaGroupCards[i].hasBeenCut ~= true) then
                local cutCardVal  = getCardValue(playAreaGroupCards[i])
                local cutCardSuit = getCardSuit(playAreaGroupCards[i])
                for x=1, table.maxn(userCards) do
                    local cardVal = getCardValue(userCards[x])
                    local cardSuit = getCardSuit(userCards[x])
                    if (cardSuit == cutterSuit and cutCardSuit ~= cutterSuit) then
                        cutCardVal = tonumber( cutCardVal )
                        cardVal = tonumber(cardVal)
                        playAreaGroupCards[i].hasBeenCut = true
                        local obj = userCards[x]
                        transition.moveTo(obj, {x=playAreaGroupCards[i].x+20, y=playAreaGroupCards[i].y, time=200, onStart = function (obj) 
                                                    obj.isVisible=true 
                                                end})
                        obj.hasBeenCut = true
                        table.insert(playAreaGroupCards, obj)
                        table.remove(userCards, x)
                        numberOfCuts = numberOfCuts + 2
                        counter = counter + 1;
                        break;
                end
            end
        end
    end
    end
    if (numberOfCuts == table.maxn( playAreaGroupCards )) then
        UpdateStatusBar(userCards.name .. " Cut The Cards !")
        return true
    else
        UpdateStatusBar(userCards.name .. " Could Not Cut The Cards !")
        return false
    end
end
function ClearTheBoard(cut, userCards)
    
    UpdateStatusBar("Clearing The Board...")
    local delay = 200

    if (cut) then
        for i=1, table.maxn( playAreaGroupCards ) do
            transition.moveTo(playAreaGroupCards[i], {delay = delay, x = 500, y = -100, time = 100, 
                onComplete = function(obj) 
                            table.remove(playAreaGroupCards, table.indexOf(obj)) 
                            reArrangeMyCards()
                            end})

            delay = delay  + 50
        end
    else 
        for i=1, table.maxn( playAreaGroupCards ) do
            transition.moveTo(playAreaGroupCards[i], {delay = delay, x = userCards.x, y = userCards.y, time = 100, 
                onComplete = function(obj) 
                            obj.isVisible = false
                            table.insert(userCards, playAreaGroupCards[table.indexOf(playAreaGroupCards,obj)]) 
                            table.remove(playAreaGroupCards, table.indexOf(playAreaGroupCards, obj))
                            reArrangeMyCards()
                 end})
            delay = delay  + 50
        end
    end
    timer.performWithDelay(1000,function () fillUpUsers() end )
end
function ValidateMyCut(card)

    local result = {}
    local paired = false
    result.canCut = false
    for i=1, table.maxn(playAreaGroupCards) do
        if playAreaGroupCards[i].hasBeenCut == false then
            local myCardSuit = getCardSuit(card)
            local myCardValue = getCardValue(card)
            local cardSuit = getCardSuit(playAreaGroupCards[i])
            local cardValue = getCardValue(playAreaGroupCards[i])
            if (myCardSuit == cardSuit) then
                if ( tonumber(myCardValue) > tonumber(cardValue) ) then
                    playAreaGroupCards[i].hasBeenCut = true
                    result.canCut = true
                    paired = true
                    result.x = playAreaGroupCards[i].x + 20
                    result.y = playAreaGroupCards[i].y
                    break;
                end
            elseif (myCardSuit == cutterSuit) then
                    playAreaGroupCards[i].hasBeenCut = true
                    result.canCut = true
                    paired = true
                    result.x = playAreaGroupCards[i].x + 20
                    result.y = playAreaGroupCards[i].y
                    break;
            end
            if paired then return result end
        end
    end
    return result
end
function ValidatedDraggedCut(cutterCard,card)
    local result = {}
    result.canCut = false
    if card.hasBeenCut ~= true then
        local myCardSuit = getCardSuit(cutterCard)
        local myCardValue = getCardValue(cutterCard)

        local cardSuit = getCardSuit(card)
        local cardValue = getCardValue(card)
        if (myCardSuit == cardSuit) then
            if ( tonumber(myCardValue) > tonumber(cardValue) ) then
                card.hasBeenCut = true
                result.canCut = true
                result.x = card.x + 20
                result.y = card.y
                return result
            end
        elseif (myCardSuit == cutterSuit) then
                card.hasBeenCut = true
                result.canCut = true
                result.x = card.x + 20
                result.y = card.y
                return result
        end
    end
    return result
end
function AssignCutterSuit()
    cutterSuit = getCardSuit(cards[52])
end
function UserHasEndedGame(userArea, userBackCards, userCards)
    if deckIsEmpty then 
        userArea.alpha = .2
        for i=1,table.maxn(userBackCards) do 
            userBackCards[i].alpha = .1
        end
        userArea.place.text = "User Finished.."

        local ind = table.indexOf(playersInGame, userCards )
        table.remove(playersInGame, ind)
    end
end
function UserInGameValidation()
    local userInGame = false
    if hand == 1 then
        for i=1, table.maxn(playersInGame) do 
            if playersInGame[i].name == "You" then userInGame = true end
        end
    elseif hand == 2 then
        for i=1, table.maxn(playersInGame) do 
            if playersInGame[i].name == "User 2" then userInGame = true end
        end
    elseif hand == 3 then
        for i=1, table.maxn(playersInGame) do 
            if playersInGame[i].name == "User 3" then userInGame = true end
        end
    elseif hand == 4 then
        for i=1, table.maxn(playersInGame) do 
            print (playersInGame[i].name)
            if playersInGame[i].name == "User 4" then userInGame = true end
        end
    end
    return userInGame
end
---------------------------------------HELPERS--------------------------------------------------
function UpdateStatusBar(action)
    myUserArea.yourTurnText.text = action
end
function getNextUserToCut()
    local index = hand + 1
    if index > table.maxn(playersInGame) then index = 1 end

    if playersInGame[index].name == playersInGame[hand].name then
        --game over
        print ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
        print ("$$                                                                                   $$")
        print ("$$  AT THIS POINT GAME IS OVER AND USER ".. hand .. " LOST.. REROUTE TO GAME OVER..  $$")
        print ("$$                                                                                   $$")
        print ("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
    else
        return playersInGame[index]
    end    
end
function isAllCardsCut()
    for i=1, table.maxn(playAreaGroupCards) do 
        if (playAreaGroupCards[i].hasBeenCut == false ) then
            return false
        end
    end
    return true
end
function getCardValue (card)
    return card.value:sub(1, string.len(card.value) - 1)
end
function getCardSuit (card)
    return card.value:sub(string.len(card.value), string.len(card.value))
end 
function shuffleCards (t)
      local rand = math.random
      assert( t, "shuffleTable() expected a table, got nil" )
      local iterations = #t
      local j
      for i = iterations, 2, -1 do
          j = rand(i)
          t[i], t[j] = t[j], t[i]
      end
end
function fillUpUsers()
    del = 100
    if (table.maxn(myCards) < 6 ) then
        dealMe(6  - table.maxn(myCards))
    end

    if (table.maxn(user2Cards) < 6 ) then
        dealUser2(6  - table.maxn(user2Cards))
    end

    if (table.maxn(user3Cards) < 6) then
        dealUser3(6  - table.maxn(user3Cards))
    end

    if (table.maxn(user4Cards) < 6) then
        dealUser4(6  - table.maxn(user4Cards))
    end
end
function findEmptySpotInHolder()
    local nums = {}
    for i = 1, table.maxn( myCards ) do
        table.insert(nums, myCards[i].x)
    end
    table.sort(nums)
    if (table.maxn( myCards ) == 1 ) then
        local contentX,contentY = myUserArea.myUserCards:localToContent( - myUserArea.myUserCards.width * 1/2 + 1/2*cardWidth + 2, 0 )
        return contentX
    else
        return nums[table.maxn(nums)] + cardWidth
    end
end
function findNextPlayAreaSpot()
    local playAreaWidth = playAreaGroup.playArea.width
        local playAreaHeight = playAreaGroup.playArea.height
        local playAreaX = playAreaGroup.playArea.x
        local playAreaY = playAreaGroup.playArea.y
        local xMin  = playAreaGroup.playArea.contentBounds.xMin
        local xMax  = playAreaGroup.playArea.contentBounds.xMax
        local yMin  = playAreaGroup.playArea.contentBounds.yMin
        local yMax = playAreaGroup.playArea.contentBounds.yMax
        local openSpots = {}
        openSpots.one = true
        openSpots.two = true
        openSpots.three = true 
        openSpots.four = true
        openSpots.five = true
        openSpots.six = true

        if (table.maxn(playAreaGroupCards) == 0) then
            moveToX = playAreaX - 50
            moveToY = playAreaY - 100
        else
            for i=1, table.maxn(playAreaGroupCards) do
                
                if (playAreaGroupCards[i].x  == (playAreaX + 50) and playAreaGroupCards[i].y == (playAreaY - 100)) then
                    openSpots.two = false
                end
                if (playAreaGroupCards[i].x == (playAreaX - 50) and playAreaGroupCards[i].y ==  playAreaY) then
                    openSpots.three = false
                end
                if (playAreaGroupCards[i].x == (playAreaX + 50) and  playAreaGroupCards[i].y ==  playAreaY) then
                    openSpots.four = false
                end
                if (playAreaGroupCards[i].x == (playAreaX - 50) and  playAreaGroupCards[i].y ==  (playAreaY + 100)) then
                    openSpots.five = false
                end
                if (playAreaGroupCards[i].x == (playAreaX + 50) and playAreaGroupCards[i].y ==   (playAreaY + 100)) then
                    openSpots.six = false
                end
            end
            

                if (openSpots.two) then
                    moveToX = playAreaX + 50
                    moveToY = playAreaY - 100
                elseif (openSpots.three) then
                    moveToX = playAreaX - 50 
                    moveToY = playAreaY 
                elseif (openSpots.four) then
                    moveToX = playAreaX + 50 
                    moveToY = playAreaY
                elseif (openSpots.five) then
                    moveToX = playAreaX - 50
                    moveToY = playAreaY + 100
                elseif (openSpots.six) then
                    moveToX = playAreaX + 50
                    moveToY = playAreaY + 100
                end

        end
        local result = {}
        result.moveToX = moveToX
        result.moveToY = moveToY
        return result
end
function reArrangeMyCards()
    if (table.maxn( myCards ) <= 6 ) then
        local cx, cy = myUserArea.myUserCards:localToContent(0,0)
        local initialSpot = cx - 1/2*myUserArea.myUserCards.width + 1/2*cardWidth+2
        
        for i=1, table.maxn(myCards) do
            transition.moveTo(myCards[i], {x=initialSpot + (i-1)*cardWidth, y=cy, time = 1})
            myCards[i].parent:insert(myCards[i])
            myCards[i].contentBounds.xMax = myCards[i].contentBounds.xMin + cardWidth
            --myCards[i]:addEventListener( "tap", cardTapped )
        end
        
    else
        local containerWidth = myUserArea.myUserCards.width
        local spacePerCard = containerWidth/ (table.maxn( myCards ))
        local contentX,contentY = myUserArea.myUserCards:localToContent( - myUserArea.myUserCards.width * 1/2 + 1/2*spacePerCard + 2, 0 )
        
        local del = 100
        for i =1, table.maxn( myCards ) do
            myCards[i].parent:insert(myCards[i])
            myCards[i].contentBounds.xMax = myCards[i].contentBounds.xMin + spacePerCard
            myCards[i].isVisible = true
            --myCards[i]:addEventListener( "tap", cardTapped )
            transition.moveTo( myCards[i], {x = contentX + spacePerCard * (i-1), y= contentY, time = 1} )
            del = del + 200
        end
    end
end
function updateCardCounter(event)
        user2Area.numOfCardsUser2.text = table.maxn( user2Cards )
        if table.maxn( user2Cards ) == 0 then UserHasEndedGame(user2Area, user2backCards, user2Cards) end

        user3Area.numOfCardsUser3.text = table.maxn( user3Cards )
        if table.maxn( user3Cards ) == 0 then UserHasEndedGame(user3Area, user3backCards, user3Cards) end

        user4Area.numOfCardsUser4.text = table.maxn( user4Cards ) 
        if table.maxn( user4Cards ) == 0 then UserHasEndedGame(user4Area, user4backCards, user4Cards) end

        sceneGroup.numOfCardsDeck.text = table.maxn( cards ) - handCardIndex + 1 .. " /52"
        --if numOfCardsDeck.text == 0 then UserHasEndedGame(user2Area)  perhaps a table of game results???
end
timer.performWithDelay( 1000, updateCardCounter, 0 )
function printAllTheCards()
            print ("---------My Cards--------")
            for i=1, table.maxn(myCards) do
                print ("my cards: " .. myCards[i].value .. " @" ..myCards[i].x .." " .. myCards[i].y)
            end
            print ("-----------------") 

            print ("---------User2 Cards--------")
            for i=1, table.maxn(user2Cards) do
                print ("my cards: " .. user2Cards[i].value .. " @" ..user2Cards[i].x .." " .. user2Cards[i].y)
            end

            print ("---------User3 Cards--------")
            for i=1, table.maxn(user3Cards) do
                print ("my cards: " .. user3Cards[i].value .. " @" ..user3Cards[i].x .." " .. user3Cards[i].y)
            end

            print ("---------User4 Cards--------")
            for i=1, table.maxn(user4Cards) do
                print ("my cards: " .. user4Cards[i].value .. " @" ..user4Cards[i].x .." " .. user4Cards[i].y)
            end

            print ("-----------------") 
            print ("---------PlayArea Cards--------")
            for i=1, table.maxn(playAreaGroupCards) do
                print ("playarea group cards: " .. playAreaGroupCards[i].value .. " @" ..playAreaGroupCards[i].x .." " .. playAreaGroupCards[i].y)
            end
            print ("-----------------")
end
function printUserCards(user)
    print ("-----------------------")
    for i=1, table.maxn(user) do
        print ("card " .. i.." : " ..user[i].value)
    end
    print ("-----------------------")
    print ("")
end
function hasCollided( obj1, obj2 )
    if ( obj1 == nil ) then  -- Make sure the first object exists
        return false
    end
    if ( obj2 == nil ) then  -- Make sure the other object exists
        return false
    end
 
    local left = obj1.contentBounds.xMin <= obj2.contentBounds.xMin and obj1.contentBounds.xMax >= obj2.contentBounds.xMin
    local right = obj1.contentBounds.xMin >= obj2.contentBounds.xMin and obj1.contentBounds.xMin <= obj2.contentBounds.xMax
    local up = obj1.contentBounds.yMin <= obj2.contentBounds.yMin and obj1.contentBounds.yMax >= obj2.contentBounds.yMin
    local down = obj1.contentBounds.yMin >= obj2.contentBounds.yMin and obj1.contentBounds.yMin <= obj2.contentBounds.yMax
 
    return (left or right) and (up or down)
end
-------------------------------Scene Create/Show/Destroy-----------------------------------------
function scene:create( event )
	sceneGroup = self.view

    createAllObjects(sceneGroup)

    myUserArea = sceneGroup.myUserArea
    user2Area = sceneGroup.user2Area
    user3Area = sceneGroup.user3Area
    user4Area = sceneGroup.user4Area
    cards = sceneGroup.cards
    backCards = sceneGroup.backCards
    playAreaGroup = sceneGroup.playAreaGroup
    cardHeight = sceneGroup.cardHeight
    cardWidth = sceneGroup.cardWidth

    shuffleCards(cards)


    sceneGroup.cards[52].x = maxX - 30
    sceneGroup.cards[52].y = zeroY + sceneGroup.cardHeight/2 + 30
    sceneGroup.cards[52].width= sceneGroup.cardWidth 
    sceneGroup.cards[52].height = sceneGroup.cardHeight 
    sceneGroup.cards[52].isVisible = true
    sceneGroup:insert(sceneGroup.cards[52])
    sceneGroup:insert(backCards[52])
    AssignCutterSuit()

    local playArea = display.newRect( 0, 0, maxX/2,  maxY/2)
        playArea:setFillColor( .7, .4)
        playArea.alpha = 0
        playArea.x = centerX
        playArea.y = centerY

    playAreaGroup.playArea = playArea
	
    sceneGroup:insert(playArea)
end
function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		--
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		--physics.start()

    dealCards(6)
    printAllTheCards()
    GamePlay()
	end
end
function scene:destroy( event )
	local sceneGroup = self.view

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.

	if playBtn then
		playBtn:removeSelf()	-- widgets must be manually removed
		playBtn = nil
	end
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene

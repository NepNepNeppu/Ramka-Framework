local Game = require(game.StarterPlayer.StarterPlayerScripts.Client.Components)
local SharedPackages = game:GetService('ReplicatedFirst').SharedPackages
local ClientPackages = game.StarterPlayer.StarterPlayerScripts.Client.Scheduler.Packages
local Schedule = Game.Scheduler.Get()

local Tasks = require(SharedPackages.Tasks)
ifThen = Tasks.ifThen
doTask = Tasks.doTask

local Input = require(SharedPackages.input.Input)
local gamepadThumbstick = require(SharedPackages.interface.gamepadThumbstick)
local Device = require(SharedPackages.input.Device)

local gamepadSelected = Input.new()
gamepadSelected:Connect("Ended",{Enum.KeyCode.ButtonA,Enum.KeyCode.ButtonB})
local thumbstick = gamepadThumbstick.new(.4,.9,10)
thumbstick:Init()
thumbstick:Continue()

local keys = {}

local function systemUpdateInternal(self)
    if Device.currentDevice == "Gamepad" then
        local item = self:GetNormalizedContent()[self.currentIndex]
        self.hovered:Fire({item})
    else
        self.hovered:Fire({})
    end
end

--[[NOTES:
use :Sync when .enabled is changed to true to prepare gamepad
]]

local Selection = {}
Selection.__index = Selection

    function Selection.new(key)
        local self = setmetatable({
            yaxis = "absolute", -- absolute, opposite, nextint
            xaxis = "absolute", -- absolute, opposite, nextint

            row = 0,
            column = 1,

            enabled = false,
            useExactMouseDetection = false,
            orderByName = true,
            lockWhenSelected = true,

            content = {},
            contentData = {},

            currentIndex = 1,

            currentActiveSelection = nil,

            hovered = Instance.new("BindableEvent"),
            selected = Instance.new("BindableEvent"),

            systemsInternal = {
                hoverSelection = {},
                selectedSelection = {},
                savedConnections = {},
            }
        },Selection)

        if keys[key] then
            warn(key .. " can not be overriden and has been renamed")
            table.insert(keys,self)
        else
            if key ~= nil and key ~= "" then
                keys[key] = self
            else
                table.insert(keys,self)
            end
        end
        
        local function gamepadSelectInternal()
            local item = self:GetNormalizedContent()[self.currentIndex]
            self.hovered:Fire({item})
        end

        table.insert(self.systemsInternal.savedConnections,Device.Changed:Connect(function()
            systemUpdateInternal(self)
        end))

        table.insert(self.systemsInternal.savedConnections,gamepadSelected.Ended:Connect(function(input)
            if self.enabled == false then return end
            local item = self:GetNormalizedContent()[self.currentIndex]
            if input == Enum.KeyCode.ButtonB then
                self.selected:Fire({})
                self.currentActiveSelection = nil
            elseif input == Enum.KeyCode.ButtonA then
                self.currentActiveSelection = item
                self.selected:Fire({item})
            end
        end))

        table.insert(self.systemsInternal.savedConnections,thumbstick.directionTick.Event:Connect(function(x,y,input)
            if self.lockWhenSelected and self.currentActiveSelection ~= nil then return end 
            if input.Name == "Thumbstick1" and self.enabled then
                self:tickDirection(x, y)
                gamepadSelectInternal()
            end
        end))

        table.insert(self.systemsInternal.savedConnections,thumbstick.isHeld.Event:Connect(function(x,y,input)
            if self.lockWhenSelected and self.currentActiveSelection ~= nil then return end 
            if input.Name == "Thumbstick1" and self.enabled then
                self:tickDirection(x, y)
                gamepadSelectInternal()
            end
        end))

        return self
    end

    function Selection:updateInternal(maxRow) -- syncs row and column according to how many items are fit into a single row
        self.row = maxRow
        self.column = (self:GetN() - (self:GetN() % maxRow)) / maxRow
    end

    function Selection:Sync() -- updates system
        self.currentIndex = math.clamp(self.currentIndex,1,math.max(self:GetN(),1))
        self:updateInternal(self.row or 1)
        systemUpdateInternal(self)
    end

    function Selection.Get(key)
        return keys[key]
    end

    function Selection:GetNormalizedContent()
        local newContent = {}
        if self.orderByName then
            local n = 1
            for i,_ in self.content do
                newContent[n] = i
                n += 1
            end
            table.sort(newContent,function(a,b)
                return a.Name < b.Name
            end)
            return newContent
        else
            for i,v in self.content do
                if newContent[v.LayoutOrder] then
                    warn(v.Name .. " has the same layout order as " .. newContent[v.LayoutOrder].Name)
                end
                newContent[v.LayoutOrder] = v
            end
        end
        return newContent
    end

    function Selection:GetConverseButtons(buttons)
        local tbl = {}
        for _,v in self:GetNormalizedContent() do
            if not table.find(buttons,v) then
                table.insert(tbl,v)
            end
        end
        return tbl
    end

    function Selection:GetIndex(reference: GuiObject | number)
        if type(reference) == "number" then
            return self:GetNormalizedContent()[reference]
        else
            return table.find(self:GetNormalizedContent(),reference)
        end
    end

    function Selection:Add(object: GuiObject)
        if self.contentData[object] or object == nil then return end

        self.contentData[object] = {
            connections = {},
            object = object,
        }

        self.content[object] = false

        if self.useExactMouseDetection then

        else
            table.insert(self.contentData[object].connections,object.MouseEnter:Connect(function()
                if self.lockWhenSelected and self.currentActiveSelection ~= nil then return end 
                if self.enabled then
                    table.insert(self.systemsInternal.hoverSelection,object)
                    self.currentIndex = self:GetIndex(object)
                    self.hovered:Fire(self.systemsInternal.hoverSelection)
                end
            end))
            table.insert(self.contentData[object].connections,object.MouseLeave:Connect(function()
                if self.lockWhenSelected and self.currentActiveSelection ~= nil then return end 
                if self.enabled then
                    local index = table.find(self.systemsInternal.hoverSelection,object)
                    if index then
                        table.remove(self.systemsInternal.hoverSelection,index)
                    end
                    self.hovered:Fire(self.systemsInternal.hoverSelection)
                end
            end))
            local activated = Input.Create(object,"Ended")
            table.insert(self.contentData[object].connections,activated)
            table.insert(self.contentData[object].connections,activated.Ended:Connect(function()
                if self.lockWhenSelected and self.currentActiveSelection ~= nil and Device.currentDevice ~= "Mouse" then return end 
                if self.enabled then
                    self.currentIndex = self:GetIndex(object)
                    self.currentActiveSelection = object
                    self.selected:Fire({object})
                end
            end))
        end

        self:Sync()
    end

    function Selection:Remove(object: GuiObject)
        if self.contentData[object] then
            for i,v in self.contentData[object].connections do
                v:Disconnect()
            end

            self.contentData[object] = nil
        end

        if table.find(self.content,object) then
            table.remove(self.content,table.find(self.content,object))
        end

        self:Sync()
    end

    function Selection:GetN()
        local maxN = 0
        for i,v in self.content do
            maxN += 1
        end
        return maxN
    end

    -- Returns vector2 object
    function Selection:ScrollToItemInList(scrollingFrame,index,startingOffset: number?)
        local usingListLayout = if scrollingFrame:FindFirstChildOfClass("UIListLayout") then true else false
        local padding = scrollingFrame:FindFirstChildOfClass("UIListLayout") or scrollingFrame:FindFirstChildOfClass("UIGridLayout")
        padding = if usingListLayout then UDim.new(padding.Padding.Scale,padding.Padding.Offset) else UDim.new(padding.CellPadding.Y.Scale,padding.CellPadding.Y.Offset)

        if not usingListLayout then
            local row = 1
            for i = 1,index,self.row do
                row += 1
            end
            index = row
       end

        local onScreenVisible = scrollingFrame.AbsoluteSize.Y/2
        local generalSize = self:GetIndex(1).AbsoluteSize.Y/scrollingFrame.AbsoluteSize.Y
        local inset = padding.Scale + (padding.Offset/scrollingFrame.AbsoluteSize.Y)
        local contentPadding = generalSize*(index-1)
        local insetPadding = inset*(index-1) + ((startingOffset or 0)/scrollingFrame.AbsoluteSize.Y)
        return Vector2.new(0,((contentPadding + insetPadding) * scrollingFrame.AbsoluteSize.Y) - onScreenVisible)
    end

    function Selection:tickDirection(x, y)
        local function getRowAtIndex(index)
            return math.floor(math.ceil(index/self.row))
        end

        local function loopDirectionTillEnd(start,x, y) -- Im lazy with math
            local row = getRowAtIndex(start)
            while true do
                if x ~= 0 then
                    local goal = start + x
                    if goal > (row * self.row) or goal < 1 + (row * self.row) - self.row then
                        break
                    end
                    start += x
                end

                if y ~= 0 then
                    local goal = start + (y * self.row)
                    if goal > self:GetN() or goal < 1 then
                        break
                    end
                    start += (y * self.row)
                end
            end
            return start
        end

        if y ~= 0 then            
            if self.yaxis == "opposite" then -- ivrn side on overflow
                local nextNum = self.currentIndex - (y * self.row)
                if nextNum > self:GetN() then
                    self.currentIndex = loopDirectionTillEnd(self.currentIndex,0,-1)
                elseif nextNum < 1 then
                    self.currentIndex = loopDirectionTillEnd(self.currentIndex,0,1)
                else
                    self.currentIndex = nextNum
                end
            else -- absolute and nextint (basically just row locking since this ignores the xaxis)
                local nextNum = self.currentIndex - (y * self.row)
                if nextNum <= self:GetN() and nextNum > 0 then
                    self.currentIndex = nextNum
                end
            end
        end

        if x ~= 0 then            
            if self.xaxis == "opposite" then -- includes row locking and ivrn side on overflow
                local nextNum = self.currentIndex + x
                if getRowAtIndex(nextNum) > getRowAtIndex(self.currentIndex) then
                    self.currentIndex = loopDirectionTillEnd(self.currentIndex,-1,0)
                elseif getRowAtIndex(nextNum) < getRowAtIndex(self.currentIndex) then
                    self.currentIndex = loopDirectionTillEnd(self.currentIndex,1,0)
                else
                    self.currentIndex += x
                end    
            elseif self.axis == "nextint" then -- ignores row locking
                self.currentIndex += x
            else -- absolute + row locking
                local nextNum = self.currentIndex + x
                if getRowAtIndex(nextNum) == getRowAtIndex(self.currentIndex) then
                    self.currentIndex += x
                end
            end
        end

        self.currentIndex = math.clamp(self.currentIndex,1,math.max(self:GetN(),1))
    end

return Selection
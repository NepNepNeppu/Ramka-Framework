local characterTransparency = {}
local activeSelf = {}
local activeWorld = {}

local characterTransparencyConnections = {}

    local function recursiveTillChild(v,parent)
        local currentParent,tries = v,0
        while currentParent.Parent ~= parent do
            currentParent = currentParent.Parent
            tries += 1
            if tries > 10 then
                break
            end
        end
        return currentParent
    end

    local function SetCharacterLocalTransparency(character,transparency)
        local function modifyCharacter(v)
            v = recursiveTillChild(v,character)

            if v.Name == "Head" and v:FindFirstChildOfClass("Decal") then
                v:FindFirstChildOfClass("Decal").Transparency = transparency
            end

            if v:IsA("MeshPart") then 
                v.Transparency = transparency
            elseif v:IsA("Accessory") and v:FindFirstChild("Handle") then
                v:FindFirstChild("Handle").Transparency = transparency
            end

            if v.Name == "UserTag" and v:IsA("BillboardGui") then
                v.Size = transparency >= 1 and UDim2.new(0,0,0,0) or UDim2.new(10,0,2,0)
            end
        end

        if characterTransparencyConnections[character.Name] then
            characterTransparencyConnections[character.Name]:Disconnect()
        end

        for i,v in character:GetChildren() do
            modifyCharacter(v)
        end

        characterTransparencyConnections[character.Name] = character.DescendantAdded:Connect(function(v)
            modifyCharacter(v)
        end)
    end

    function characterTransparency.setWorldLocalTransparency(transparency)
        for i,v in activeWorld do
            v:Disconnect()
        end

        local function watchPlayer(player)
            if player == game.Players.LocalPlayer then
                for i,v in activeSelf do
                    v:Disconnect()
                end
            end

            if player.Character then
                SetCharacterLocalTransparency(player.Character,transparency)
            end

            table.insert(activeWorld,player.CharacterAdded:Connect(function(character)
                SetCharacterLocalTransparency(character,transparency)
            end))
        end

        for i,v in game.Players:GetPlayers() do
            watchPlayer(v)
        end

        table.insert(activeWorld, game.Players.PlayerAdded:Connect(function(player)
            watchPlayer(player)
        end))
    end

    function characterTransparency.setCharacterLocalTransparency(character,transparency)
        for i,v in activeSelf do
            v:Disconnect()
        end

        SetCharacterLocalTransparency(character,transparency)

        table.insert(activeSelf, game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
            SetCharacterLocalTransparency(character,transparency)
        end))
    end

return characterTransparency
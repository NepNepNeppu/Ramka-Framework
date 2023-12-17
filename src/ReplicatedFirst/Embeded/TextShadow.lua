function assertValue(index, key, expect, got)
    return ("bad argument %s to %s (%s expected, got %s)"):format(index, key, expect, got)
end

local function assertClassName(index, key, object, classname)
    if object.ClassName ~= classname or object.ClassName == nil then    
        error(assertValue(index, key, classname, object.ClassName), 2)
    end
end

type shadowLookup = {
    innerTransparency: number,
    outerTransparency: number,
    minThickness: number,
    maxThickness: number,
    Color: Color3,
    LineJoinMode: Enum.LineJoinMode,
}

local validDescendantClasses = {
    "UIAspectRatioConstraint",
    "UIGradient",
    "UIPadding",
    "UIScale",
    "UISizeConstraint",
    "UITextSizeConstraint",
    "UIFlexItem"
}

local propertyTable = {
    "LineHeight", "MaxVisibleGraphemes", "RichText", "Text", "TextColor3", "TextDirection",
    "TextFits", "TextScaled", "TextSize", "TextTruncate", "TextWrapped", "TextXAlignment", 
    "TextYAlignment", "TextTransparency"
}

local defaultSettings = {
    innerTransparency = .8,
    outerTransparency = 1,
    minThickness = 3,
    maxThickness = 13,
    Color = Color3.fromHSV(0,0,0), 
    LineJoinMode = Enum.LineJoinMode.Round,
}

local function syncTextProperties(reference, key)
    for _,property in propertyTable do
        if typeof((reference :: any)[property]) == typeof((key :: any)[property]) then
            (key :: any)[property] = (reference :: any)[property]
        end
    end
end

local function createValidClone(reference)
    local validClone = reference:Clone()
    validClone.BackgroundTransparency = 1
    validClone.Parent = nil

    for i,v in validClone:GetChildren() do
        if not table.find(validDescendantClasses, v.ClassName) then
            v:Destroy()
        end
    end

    return validClone
end

local function applyStrokeSettings(index, total, stroke, setting)
    if not stroke then return end
    stroke.Thickness = setting.minThickness + (setting.maxThickness - setting.minThickness) * (index/total)
    stroke.Color = setting.Color
    stroke.LineJoinMode = setting.LineJoinMode
    stroke.Transparency = setting.innerTransparency + (setting.outerTransparency - setting.innerTransparency) * (index/total)
end

local TextShadow = {}
TextShadow.__index = TextShadow

    --[[
        Automatically creates shadow
    ]]
    function TextShadow.Default(Label: TextLabel)
        assertClassName(1, "TextShadow.Default", Label, "TextLabel")

        local self = setmetatable({
            textLabel = Label,

            iterationCount = nil,
            shadowSettings = table.clone(defaultSettings),

            shadowLabels = nil
        }, TextShadow)

        Label.Destroying:Once(function()
            self:Destroy()
        end)

        self:SetIterations(6)

        return self
    end

    --[[
        Need to call :SetIterations to create shadow, use :Edit to edit shadow properties
    ]]
    function TextShadow.Custom(Label: TextLabel)
        assertClassName(1, "TextShadow.Custom", Label, "TextLabel")

        local self = setmetatable({
            textLabel = Label,

            iterationCount = nil,
            shadowSettings = table.clone(defaultSettings),

            shadowLabels = nil
        }, TextShadow)

        Label.Destroying:Once(function()
            self:Destroy()
        end)

        return self
    end

    --Change the count of shadow segments
    function TextShadow:SetIterations(iterations: number)
        for i,v in (self.shadowLabels or {}) do
            self.shadowLabels[i]:Destroy()
            self.shadowLabels[i] = nil
        end

        self.shadowLabels = {}

        local keyReference = createValidClone(self.textLabel)

        for i = 1,iterations,1 do
            local referenceObject = keyReference:Clone()
            referenceObject.Parent = self.textLabel
            referenceObject.Name = i.."_shadow"

            local uiStroke = Instance.new("UIStroke")
            uiStroke.Parent = referenceObject
            applyStrokeSettings(i, iterations, uiStroke, self.shadowSettings)

            table.insert(self.shadowLabels, referenceObject)
        end

        keyReference:Destroy()
    end

    --[[
        Edit the properties of the shadow     
    ]]
    function TextShadow:Edit(prop: shadowLookup)
        self.shadowSettings = {
            innerTransparency = prop.innerTransparency or self.shadowSettings.innerTransparency,
            outerTransparency = prop.outerTransparency or self.shadowSettings.outerTransparency,
            minThickness = prop.minThickness or self.shadowSettings.minThickness,
            maxThickness = prop.maxThickness or self.shadowSettings.maxThickness,
            Color = prop.Color or self.shadowSettings.Color, 
            LineJoinMode = prop.LineJoinMode or self.shadowSettings.LineJoinMode,
        }

        for i,label in self.shadowLabels do
            applyStrokeSettings(i, #self.shadowLabels, label.UIStroke, self.shadowSettings)
        end
    end

    --[[
        Change textlabel and shadows with new property value

        Exempted Properties: FontFace, FontStyle, FontWeight
    ]]
    function TextShadow:SetProperty(propertyName: string, value: any)
        if not table.find(propertyTable, propertyName) then
            error(assertValue(1, "SetProperty", "<Text Property>", propertyName), 2)
        end

        if typeof(value) ~= typeof((self.textLabel :: any)[propertyName]) then
            error(assertValue(1, "SetProperty", propertyName, typeof(value)), 2)
        end

        if self.shadowLabels == nil then
            error("Unable to call SetProperty because there is no shadow", 2)
        end

        for _,label in self.shadowLabels do
            (label :: any)[propertyName] = (self.textLabel :: any)[propertyName]
        end
    end

    --Syncs shadows according to textlabel properties
    function TextShadow:MatchTextProperties()
        if self.shadowLabels == nil then
            error("Unable to call MatchTextProperties because there is no shadow", 2)
        end

        for i,label in self.shadowLabels do
            syncTextProperties(self.textLabel, label)
        end
    end

    function TextShadow:Destroy()
        print("destroyed")

        for i,v in (self.shadowLabels or {}) do
            if self.shadowLabels[i] and self.shadowLabels[i].Parent then                
                self.shadowLabels[i]:Destroy()
            end

            self.shadowLabels[i] = nil
        end

        self.shadowLabels = nil
        self.textLabel = nil
        self.iterationCount = nil
        self.shadowSettings = nil
    end

return TextShadow
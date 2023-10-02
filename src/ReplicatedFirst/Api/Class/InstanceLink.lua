local InstanceLink = {}
InstanceLink.__index = InstanceLink

local Links = {}

    function InstanceLink.new(instance)
        local self = setmetatable({
            coreLink = instance,
            Links = {},
        },InstanceLink)

        table.insert(Links,self)

        return self
    end

    function InstanceLink.GetLink(item)
        for _,link in pairs(Links) do
            if item == link.coreLink then
                return link
            end
        end
        -- warn(string.format("Link for core:[%s] does not exist.",tostring(item)))
    end

    function InstanceLink:HasLink(item : any)
        for _,linkedItem in pairs(self.Links) do
            if linkedItem == item then
                return true,InstanceLink.GetLink(item)
            end
        end
        return false,nil
    end

    function InstanceLink:AddLink(item : any)
        if self:HasLink(item) == false then
            table.insert(self.Links,item)
        end
        -- warn(string.format("Attempt to link link:[%s] to core:[%s] but it is already linked.",tostring(item),tostring(self.coreLink)))
    end

    function InstanceLink:RemoveLink(item : any)
        local isLinked,Item = self:HasLink(item)
        if isLinked then
            table.remove(self.Links,table.find(self.Links,Item))
        end
        -- warn(string.format("Attempt to remove link:[%s] from core:[%s] but it does not exist.",tostring(item),tostring(self.coreLink)))
    end

    function InstanceLink:ReplaceLink(item,replace)
        self:RemoveLink(item)
        self:AddLink(replace)
    end

    function InstanceLink:Destroy()
        Links[self] = nil
        self.Links = nil
        self.coreLink = nil
    end

return InstanceLink
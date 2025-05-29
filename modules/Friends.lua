local FriendModule = {}

local Friends = {}

function FriendModule:Add(name: string)
    if not Friends[name] then
        Friends[name] = name

        print(Friends,name)

        return true
    end

    return nil
end

function FriendModule:Remove(name: string)
    if Friends[name] then
        Friends[name] = nil

        print(Friends,name)

        return true
    end

    return nil
end

function FriendModule:IsFriend(name: string)
    return Friends[name]
end

function FriendModule:GetFriends()
    return Friends
end

return FriendModule
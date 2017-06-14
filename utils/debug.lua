local function alert(msg)
    if DEBUG then
        hs.alert.show(msg)
    end
end

return {
    alert = alert
}

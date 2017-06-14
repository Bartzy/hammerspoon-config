local machine = require('utils.statemachine')
local debug = require('utils.debug')

local function nextValue(current, list)
    for i, v in ipairs(list) do
        if v == current then
            nextIndex = (i % #list) + 1
            return list[nextIndex]
        end
    end
end

local fsm = machine.create({
  initial = 'start',
  events = {
    { name = 'altDown', from = 'start',to = 'alt' },
    { name = 'shiftDown', from = 'alt', to = 'altShift' },
    { name = 'altUp', from = 'altShift', to = 'shift' },
    { name = 'altUp', from = 'alt', to = 'start' },
    { name = 'shiftUp', from = 'shift', to = 'layoutChange' },
    { name = 'changedLayout', from = 'layoutChange', to = 'start'},
    { name = 'anyOtherKey', from = {'*'}, to = 'start' }
}})

local altKeyCode = hs.keycodes.map['alt']
local shiftKeyCode = hs.keycodes.map['shift']

local altIsDown = false
local shiftIsDown = false

local flagsEventWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
    local keyCode = e:getKeyCode()

    if keyCode == altKeyCode then
        if not altIsDown then
            fsm:altDown()
            altIsDown = true
        else
            fsm:altUp()
            altIsDown = false
        end
    elseif keyCode == shiftKeyCode then

        if not shiftIsDown then
            fsm:shiftDown()
            shiftIsDown = true
        else
            fsm:shiftUp()
            shiftIsDown = false

            if fsm:is('layoutChange') then
                local currentLayout = hs.keycodes.currentLayout()
                local nextLayout = nextValue(currentLayout, hs.keycodes.layouts())
                if nextLayout ~= currentLayout then
                    hs.keycodes.setLayout(nextLayout)
                    debug.alert("NEW LAYOUT: " .. nextLayout)
                end
                fsm:changedLayout()

                return true
            end
        end
    else
        fsm:anyOtherKey()
    end

    return false;
end)

local keyDownEventWatcher = hs.eventtap.new({hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp}, function(e)
    fsm:anyOtherKey()

    return false;
end)

local start = function()
    flagsEventWatcher:start()
    keyDownEventWatcher:start()
end

local stop = function()
    flagsEventWatcher:stop()
    keyDownEventWatcher:stop()
end

return {
    start = start,
    stop = stop
}

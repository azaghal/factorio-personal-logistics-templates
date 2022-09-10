-- Copyright (c) 2022 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local gui = {}


--- Initialise GUI elements for a given player.
--
-- @param player LuaPlayer Player for which to initialise the GUI.
--
function gui.initialise(player)
    if global.player_data[player.index].window then
        return
    end

    local window = player.gui.relative.add{
        type = "frame",
        name = "plt_window",
        anchor = {
            gui = defines.relative_gui_type.controller_gui,
            position = defines.relative_gui_position.bottom
        },
        style = "quick_bar_window_frame",
        visible = false,
    }

    local panel = window.add{
        type = "frame",
        name = "plt_panel",
        style = "shortcut_bar_inner_panel",
    }

    local export_button = panel.add{
        type = "sprite-button",
        name = "plt_export_button",
        style = "shortcut_bar_button_blue",
        visible = false,
        sprite = "plt-export-template-button",
        tooltip = {"gui.plt-export"}
    }

    local import_button = panel.add{
        type = "sprite-button",
        name = "plt_import_button",
        style = "shortcut_bar_button_blue",
        visible = false,
        sprite = "plt-import-template-button",
        tooltip = {"gui.plt-import"}
    }

    global.player_data[player.index].window = window
end


--- Destroys all GUI elements for passed-in player.
--
-- @param player LuaPlayer Player for which to destroy the GUI.
--
function gui.destroy_player_data(player)
    if not global.player_data[player.index].window then
        return
    end

    global.player_data[player.index].window.destroy()
end


--- Sets mode of operation for GUI, showing or hiding the relevant elements.
--
-- @param player LuaPlayer Player for which to set the GUI mode.
-- @param mode string Mode to set. One of: "hidden", "export", "import".
--
function gui.set_mode(player, mode)
    local window = global.player_data[player.index].window

    if mode == "hidden" then
        window.visible = false
    elseif mode == "export" then
        window.plt_panel.plt_import_button.visible = false
        window.plt_panel.plt_export_button.visible = true
        window.visible = true
    elseif mode == "import" then
        window.plt_panel.plt_import_button.visible = true
        window.plt_panel.plt_export_button.visible = false
        window.visible = true
    end
end


-- Maps GUI events to list of handlers to invoke.
gui.handlers = {}

--- Registers handler with click event on a specific GUI element.
--
-- Multiple handlers can be registered with GUI element. Handlers are invoked in the order they have been registered.
--
-- @param name string Name of GUI element for which to register click handler.
-- @param func callable Callable to invoke when GUI element is clicked on.
--
function gui.register_handler(name, func)
    gui.handlers[name] = gui.handlers[name] or {}
    table.insert(gui.handlers[name], func)
end


--- Invokes registered handlers for passed-in GUI element.
--
-- @param player LuaPlayer Player that clicked on the GUI element.
-- @param element LuaGuiElement GUI element that was clicked on.
--
function gui.on_click(player, element)
    if string.find(element.name, "^plt_") then
        for _, func in pairs(gui.handlers[element.name] or {}) do
            func(player)
        end
    end
end


return gui

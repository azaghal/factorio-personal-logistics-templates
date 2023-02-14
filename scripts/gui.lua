-- Copyright (c) 2022 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local gui = {}


--- Initialise GUI elements for a given player.
--
-- @param player LuaPlayer Player for which to initialise the GUI.
--
function gui.initialise(player)
    if global.player_data[player.index].windows then
        return
    end

    -- Although it would be possible to maintain a single window, and simply update the anchors, this would result in
    -- character/spidetron window getting nudged upwards every time the export/import buttons window gets reanchored to
    -- them, which would be somewhat annoying visually. Maintain "duplicate" export/import button windows instead for
    -- smoother GUI experience.
    global.player_data[player.index].windows = {}

    local window_anchors = {
        character = defines.relative_gui_type.controller_gui,
        spidertron = defines.relative_gui_type.spider_vehicle_gui,
    }

    for window_name, gui_type in pairs(window_anchors) do

        local window = player.gui.relative.add{
            type = "frame",
            name = "plt_window_" .. window_name,
            anchor = {
                gui = gui_type,
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

        local append_button = panel.add{
            type = "sprite-button",
            name = "plt_append_button",
            style = "shortcut_bar_button_blue",
            visible = false,
            sprite = "plt-append-template-button",
            tooltip = {"gui.plt-append"}
        }

        local auto_trash_button = panel.add{
            type = "sprite-button",
            name = "plt_auto_trash_button",
            style = "shortcut_bar_button_blue",
            visible = false,
            sprite = "plt-auto-trash-template-button",
            tooltip = {"gui.plt-auto-trash"}
        }

        global.player_data[player.index].windows[window_name] = window
    end
end


--- Destroys all GUI elements for passed-in player.
--
-- @param player LuaPlayer Player for which to destroy the GUI.
--
function gui.destroy_player_data(player)
    if not global.player_data[player.index].windows then
        return
    end

    for _, window in pairs(global.player_data[player.index].windows) do
        window.destroy()
    end

    global.player_data[player.index].windows = nil
end


--- Sets mode of operation for GUI, showing or hiding the relevant elements.
--
-- @param player LuaPlayer Player for which to set the GUI mode.
-- @param mode string Mode to set. One of: "hidden", "export", "import".
--
function gui.set_mode(player, mode)
    for _, window in pairs(global.player_data[player.index].windows) do
        if mode == "hidden" then
            window.visible = false
        elseif mode == "export" then
            window.plt_panel.plt_import_button.visible = false
            window.plt_panel.plt_append_button.visible = false
            window.plt_panel.plt_auto_trash_button.visible = false
            window.plt_panel.plt_export_button.visible = true
            window.visible = true
        elseif mode == "import" then
            window.plt_panel.plt_import_button.visible = true
            window.plt_panel.plt_append_button.visible = true
            window.plt_panel.plt_auto_trash_button.visible = true
            window.plt_panel.plt_export_button.visible = false
            window.visible = true
        end
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

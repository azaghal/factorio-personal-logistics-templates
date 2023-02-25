-- Copyright (c) 2023 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local gui = require("scripts.gui")
local utils = require("scripts.utils")
local template = require("scripts.template")
local requests = require("scripts.requests")


local main = {}


--- Initialises global mod data.
--
function main.initialise_data()
    global.player_data = global.player_data or {}

    for index, player in pairs(game.players) do
        main.initialise_player_data(player)
    end
end


--- Initialiases global mod data for a specific player.
--
-- @param player LuaPlayer Player for which to initialise the data.
--
function main.initialise_player_data(player)
    global.player_data[player.index] = global.player_data[player.index] or {}

    gui.initialise(player)
end


--- Updates global mod data.
--
-- @param old_version string Old version of mod.
-- @param new_version string New version of mod.
--
function main.update_data(old_version, new_version)

    -- Ensure the GUI definition is up-to-date for all players.
    if new_version ~= old_version then
        for index, player in pairs(game.players) do
            gui.destroy_player_data(player)
            gui.initialise(player)
        end
    end

end


--- Destroys all mod data for a specific player.
--
-- @param player LuaPlayer Player for which to destroy the data.
--
function main.destroy_player_data(player)
    gui.destroy_player_data(player)

    global.player_data[player.index] = nil
end


--- Updates visibility of import/export buttons for a given player based on held cursor stack.
--
-- @param player LuaPlayer Player for which to update button visibility.
--
function main.update_button_visibility(player)

    -- Retrieve list of blueprint entities.
    local entities = player.get_blueprint_entities() or {}

    if not player.character or not player.force.character_logistic_requests then
        gui.set_mode(player, "hidden")
    elseif table_size(entities) == 0 and player.is_cursor_blueprint() and player.cursor_stack.valid_for_read then
        gui.set_mode(player, "export")
    elseif template.is_valid_template(entities) then
        gui.set_mode(player, "import")
    elseif utils.is_blank_deconstruction_planner(player.cursor_stack) then
        gui.set_mode(player, "modify")
    else
        gui.set_mode(player, "hidden")
    end

end


--- Exports personal logistics template for requesting player's opened entity into a held (empty) blueprint.
--
-- @param player LuaPlayer Player that has requested the export.
--
function main.export(player)

    -- Make sure the player is holding an empty blueprint before proceeding.
    if not (player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == "blueprint") then
        player.print({"error.plt-blueprint-not-empty"})
        return
    end

    -- Determine what entity is targeted by the player.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.export_into_blueprint(entity, player.cursor_stack)

    main.update_button_visibility(player)

end


--- Imports personal logistics template from a held blueprint.
--
-- @param player LuaPlayer Player that has requested the import.
--
function main.import(player)

    local blueprint_entities = player.get_blueprint_entities()

    if not template.is_valid_template(blueprint_entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.clear(entity)
    requests.append(entity, blueprint_entities)

end


--- Appends logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the setting of requests.
--
function main.append(player)

    local blueprint_entities = player.get_blueprint_entities()

    if not template.is_valid_template(blueprint_entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.append(entity, blueprint_entities)

end


--- Add and increment personal logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the increment.
--
function main.increment(player)
    local blueprint_entities = player.get_blueprint_entities()

    if not template.is_valid_template(blueprint_entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.increment(entity, blueprint_entities)

end


--- Decrement personal logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the decrement.
--
function main.decrement(player)
    local blueprint_entities = player.get_blueprint_entities()

    if not template.is_valid_template(blueprint_entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.decrement(entity, blueprint_entities)

end


--- Set logistics requests using the held blueprint.
--
-- @param player LuaPlayer Player that has requested the setting of requests.
--
function main.set(player)
    local blueprint_entities = player.get_blueprint_entities()

    if not template.is_valid_template(blueprint_entities) then
        player.print({"error.plt-invalid-template"})
        return
    end

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.set(entity, blueprint_entities)

end


--- Sets-up auto-trashing of all currently unrequested items (setting the maximum amount to zero).
--
-- @param player LuaPlayer Player that has requested the auto-trashing.
--
function main.auto_trash(player)

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.auto_trash(entity)

end


--- Clears all auto-trash personal logistics requests.
--
-- @param player LuaPlayer Player that has requested clearing of all auto-trash requests.
--
function main.clear_auto_trash(player)

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.clear_auto_trash(entity)

end


--- Clears all personal logistic requests.
--
-- @param player LuaPlayer Player that has requested clearing of all requests.
--
function main.clear_requests(player)

    -- Determine what entity is targeted.
    local entity = utils.get_opened_gui_entity(player)
    if not entity then
        return
    end

    requests.clear(entity)

end


--- Registers GUI handlers for the module.
--
function main.register_gui_handlers()
    gui.register_handler("plt_export_button", main.export)
    gui.register_handler("plt_import_button", main.import)
    gui.register_handler("plt_append_button", main.append)
    gui.register_handler("plt_increment_button", main.increment)
    gui.register_handler("plt_decrement_button", main.decrement)
    gui.register_handler("plt_set_button", main.set)
    gui.register_handler("plt_auto_trash_button", main.auto_trash)
    gui.register_handler("plt_clear_auto_trash_button", main.clear_auto_trash)
    gui.register_handler("plt_clear_requests_button", main.clear_requests)
end


return main

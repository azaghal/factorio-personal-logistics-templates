-- Copyright (c) 2023 Branko Majic
-- Provided under MIT license. See LICENSE for details.


local handlers = require("scripts.handlers")


-- Handler registration
-- ====================

script.on_init(handlers.on_init)
script.on_configuration_changed(handlers.on_configuration_changed)
script.on_event(defines.events.on_player_cursor_stack_changed, handlers.on_player_cursor_stack_changed)
script.on_event(defines.events.on_player_joined_game, handlers.on_player_joined_game)
script.on_event(defines.events.on_player_removed, handlers.on_player_removed)
script.on_event(defines.events.on_gui_click, handlers.on_gui_click)

handlers.register_gui_handlers()

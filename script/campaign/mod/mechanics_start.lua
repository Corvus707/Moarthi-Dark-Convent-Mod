local PANEL = "corvus_morathi_panel"
local BUTTON = "button_corvus_morathi"
local ESC_KEY = "corvus_morathi_panel_esc"

local function close_panel()
    local panel = find_uicomponent(core:get_ui_root(), PANEL)
    if panel then panel:Destroy() end
    cm:release_escape_key_with_callback(ESC_KEY)
end

local function open_panel()
    if find_uicomponent(core:get_ui_root(), PANEL) then return end
    local panel = UIComponent(core:get_ui_root():CreateComponent(PANEL, "ui/campaign ui/corvus_morathi_panel"))
    panel:SetDockingPoint(4)
    panel:SetDockOffset(0, 0)
    cm:steal_escape_key_with_callback(ESC_KEY, close_panel)
end

core:add_listener("corvus_morathi_button", "ComponentLClickUp",
    function(context) return context.string == BUTTON end,
    function() if find_uicomponent(core:get_ui_root(), PANEL) then close_panel() else open_panel() end end,
    true)

core:add_listener("corvus_morathi_close", "ComponentLClickUp",
    function(context) return context.string == "button_close" and uicomponent_descended_from(UIComponent(context.component), PANEL) end,
    close_panel, true)

-- close if another panel (diplomacy, tech, etc.) opens
core:add_listener("corvus_morathi_other_panel", "PanelOpenedCampaign",
    function(context) return context.string ~= PANEL end,
    close_panel, true)

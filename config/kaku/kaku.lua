local wezterm = require 'wezterm'

local function resolve_bundled_config()
  local resource_dir = wezterm.executable_dir:gsub('MacOS/?$', 'Resources')
  local bundled = resource_dir .. '/kaku.lua'
  local f = io.open(bundled, 'r')
  if f then
    f:close()
    return bundled
  end

  local dev_bundled = wezterm.executable_dir .. '/../../assets/macos/Kaku.app/Contents/Resources/kaku.lua'
  f = io.open(dev_bundled, 'r')
  if f then
    f:close()
    return dev_bundled
  end

  local app_bundled = '/Applications/Kaku.app/Contents/Resources/kaku.lua'
  f = io.open(app_bundled, 'r')
  if f then
    f:close()
    return app_bundled
  end

  local home = os.getenv('HOME') or ''
  local home_bundled = home .. '/Applications/Kaku.app/Contents/Resources/kaku.lua'
  f = io.open(home_bundled, 'r')
  if f then
    f:close()
    return home_bundled
  end

  return nil
end

local config = {}
local bundled = resolve_bundled_config()

if bundled then
  local ok, loaded = pcall(dofile, bundled)
  if ok and type(loaded) == 'table' then
    config = loaded
  else
    wezterm.log_error('Kaku: failed to load bundled defaults from ' .. bundled)
  end
else
  wezterm.log_error('Kaku: bundled defaults not found')
end

-- User overrides (WezTerm-compatible API): https://wezfurlong.org/wezterm/config/lua/

config.color_scheme = 'Kaku Dark'
config.font_size = 15
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.line_height = 1
config.tab_bar_at_bottom = false
config.tab_title_show_basename_only = true
config.enable_scroll_bar = true
config.window_background_opacity = 0.9
return config

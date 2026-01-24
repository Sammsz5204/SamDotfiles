local home = os.getenv("HOME")

local folders = {
    day = home .. "/Wallpapers/day",
    afternoon = home .. "/Wallpapers/afternoon",
    night = home .. "/Wallpapers/night"
}

local function get_period()
    local h = tonumber(os.date("%H"))

    if h >= 6 and h < 16 then
        return "day"
    elseif h >= 16 and h < 18 then
        return "afternoon"
    else
        return "night"
    end
end

local function pick_random_image(folder)
    local cmd = string.format("ls '%s'", folder)
    local handle = io.popen(cmd)
    local files = {}

    for file in handle:lines() do
        if file:match("%.jpg$") or file:match("%.png$") then
            table.insert(files, file)
        end
    end
    handle:close()

    if #files == 0 then return nil end

    math.randomseed(os.time())
    local file = files[math.random(#files)]

    return folder .. "/" .. file
end

local function set_wallpaper(path)
    if not path then return end

    local cmd = string.format(
        "gsettings set org.cinnamon.desktop.background picture-uri 'file://%s'",
        path
    )
    os.execute(cmd)
end

local last_period = nil

while true do
    local period = get_period()

    if period ~= last_period then
        local image = pick_random_image(folders[period])
        set_wallpaper(image)
        last_period = period
    end

    -- check every 2 minutes
    os.execute("sleep 120")
end

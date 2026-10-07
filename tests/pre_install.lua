-- Run from the repository root: lua tests/pre_install.lua
PLUGIN = {}
dofile("hooks/pre_install.lua")

local requested = false
local assets = {}
package.preload.http = function()
    return {
        get = function()
            requested = true
            return { status_code = 200, body = "release" }
        end,
    }
end
package.preload.json = function()
    return {
        decode = function()
            return { assets = assets }
        end,
    }
end

for _, os in ipairs({ "linux", "darwin", "windows" }) do
    for _, arch in ipairs({ "arm", "386", "riscv64", "unknown" }) do
        RUNTIME = { osType = os, archType = arch }
        requested = false
        local ok, err = pcall(PLUGIN.PreInstall, PLUGIN, { version = "0.12.5" })
        assert(not ok, os .. "/" .. arch .. " must be rejected")
        assert(err:find("Unsupported platform: " .. os .. "/" .. arch, 1, true), err)
        assert(not requested, "unsupported platforms must fail before fetching a release")
    end
end

for _, case in ipairs({
    { "linux", "amd64", "nvim-linux-x86_64.tar.gz" },
    { "linux", "arm64", "nvim-linux-arm64.tar.gz" },
    { "darwin", "amd64", "nvim-macos-x86_64.tar.gz" },
    { "darwin", "arm64", "nvim-macos-arm64.tar.gz" },
    { "windows", "amd64", "nvim-win64.zip" },
    { "windows", "arm64", "nvim-win-arm64.zip" },
}) do
    RUNTIME = { osType = case[1], archType = case[2] }
    assets = { { name = case[3], browser_download_url = "https://example.com/" .. case[3], digest = "sha256:abc" } }
    local result = PLUGIN:PreInstall({ version = "0.12.5" })
    assert(result.url == assets[1].browser_download_url)
    assert(result.sha256 == "abc")
end
for _, case in ipairs({
    { "linux", "amd64", "nvim-linux64.tar.gz" },
    { "darwin", "arm64", "nvim-macos.tar.gz" },
}) do
    RUNTIME = { osType = case[1], archType = case[2] }
    assets = { { name = case[3], browser_download_url = "https://example.com/" .. case[3], digest = "sha256:abc" } }
    assert(PLUGIN:PreInstall({ version = "0.9.5" }).url == assets[1].browser_download_url)
end

print("pre_install: 12 unsupported platforms rejected; 6 supported assets selected")

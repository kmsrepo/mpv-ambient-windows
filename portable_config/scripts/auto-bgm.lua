-- ==============================================================================
-- auto-bgm.lua - Automatic Background Music for Silent Videos in mpv
-- Project: https://github.com/kmsrepo/mpv-ambient-windows
-- ==============================================================================
-- When a video has NO audio track (e.g. silent presentation or slide demo),
-- this script automatically detects it, loads a background music track from
-- the 'bgm/' folder, and loops it continuously at a pleasant background volume.
-- If the video already has audio/narration, BGM is automatically suppressed.
-- ==============================================================================

local utils = require 'mp.utils'

local function on_file_loaded()
    -- 1. Inspect all tracks in the currently loaded media
    local tracks = mp.get_property_native("track-list") or {}
    local has_audio = false
    
    for _, track in ipairs(tracks) do
        if track["type"] == "audio" and not track["external"] then
            has_audio = true
            break
        end
    end

    -- 2. If NO internal audio track exists, look for BGM
    if not has_audio then
        mp.msg.info("[Auto-BGM] Silent video detected. Searching for BGM track...")

        local candidate_paths = {
            mp.command_native({"expand-path", "~~/../bgm/default_bgm.mp3"}),
            mp.command_native({"expand-path", "~~/../bgm/upbeat_corporate_tech.mp3"}),
            mp.command_native({"expand-path", "~~/../bgm/bgm.mp3"}),
            mp.command_native({"expand-path", "~~/bgm/default_bgm.mp3"}),
            "bgm/default_bgm.mp3",
            "bgm/upbeat_corporate_tech.mp3",
            "bgm/bgm.mp3"
        }

        local bgm_file = nil
        for _, path in ipairs(candidate_paths) do
            local info = utils.file_info(path)
            if info and info.is_file then
                bgm_file = path
                break
            end
        end

        if bgm_file then
            -- Inject external audio track
            mp.commandv("audio-add", bgm_file, "select")
            -- Infinite audio loop filter (ensures BGM repeats for long videos)
            mp.set_property("af", "lavfi=[aloop=loop=-1:size=2147483647]")
            -- Gentle background volume level (60%)
            mp.set_property("volume", "60")
            mp.msg.info("[Auto-BGM] Injected background music: " .. bgm_file)
        else
            mp.msg.warn("[Auto-BGM] Silent video, but no audio file found in 'bgm/' directory.")
        end
    else
        mp.msg.info("[Auto-BGM] Original audio track detected. BGM suppressed.")
    end
end

mp.register_event("file-loaded", on_file_loaded)

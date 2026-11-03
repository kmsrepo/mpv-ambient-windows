-- ==============================================================================
-- auto-bgm.lua - Automatic Background Music for Silent Videos in mpv
-- Project: https://github.com/kmsrepo/mpv-ambient-windows
-- ==============================================================================
-- 1. Automatically detects when a video has NO audio track (silent video).
-- 2. Injects and loops background music from 'bgm/' at a gentle 60% volume.
-- 3. Synchronizes EOF: When the visual video ends, it immediately stops the BGM
--    and advances to the next video (preventing the video from freezing on the
--    last frame while remaining BGM audio plays).
-- 4. Suppresses BGM automatically if the video already has its own sound track.
-- ==============================================================================

local utils = require 'mp.utils'

local video_dur = nil
local timer = nil
local fired = false

local function cleanup_timer()
    if timer then
        timer:kill()
        timer = nil
    end
    fired = false
    video_dur = nil
end

local function on_file_loaded()
    cleanup_timer()

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
        -- Record visual video duration before external audio is injected
        video_dur = mp.get_property_number("duration")
        mp.msg.info(string.format("[Auto-BGM] Silent video detected (duration: %.2fs). Searching for BGM track...", video_dur or 0))

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

            -- Synchronize EOF: Watch playback position and force advance when video ends
            -- (Prevents video from freezing on the final frame while longer BGM continues playing)
            if video_dur and video_dur > 0 then
                timer = mp.add_periodic_timer(0.1, function()
                    local pos = mp.get_property_number("time-pos")
                    if pos then
                        if pos < (video_dur - 1.0) then
                            fired = false
                        elseif not fired and pos >= (video_dur - 0.25) then
                            fired = true
                            cleanup_timer()
                            mp.msg.info(string.format("[Auto-BGM] Video finished at %.2fs. Advancing to next!", pos))
                            mp.commandv("playlist-next", "force")
                        end
                    end
                end)
            end
        else
            mp.msg.warn("[Auto-BGM] Silent video, but no audio file found in 'bgm/' directory.")
        end
    else
        mp.msg.info("[Auto-BGM] Original audio track detected. BGM suppressed.")
    end
end

local function on_end_file()
    cleanup_timer()
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("end-file", on_end_file)

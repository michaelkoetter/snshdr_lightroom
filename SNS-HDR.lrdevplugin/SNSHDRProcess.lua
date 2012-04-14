------------------------------------------------------------------------------------------
-- SNS-HDR Lightroom Plugin
-- http://github.com/michaelkoetter/snshdr_lightroom
--
-- Copyright (c) 2012 Michael Kötter
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. The name of the author may not be used to endorse or promote products
--    derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
-- IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
-- IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
-- NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
-- DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
-- THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
-- THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
------------------------------------------------------------------------------------------

local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrProgressScope = import 'LrProgressScope'
local LrExportSettings = import 'LrExportSettings'

local SNSHDRProcess = {}

function SNSHDRProcess.createPostProcessCommand( renditionDir )
    local postProcessCommand = LrPathUtils.child( renditionDir, "snshdr_callback.bat" )
    local callbackFile = LrPathUtils.child( renditionDir, ".snshdr_callback" )

    local f = assert(io.open( postProcessCommand, "w" ))

    f:write("ECHO %1 > " .. callbackFile)
    f:close()

    return postProcessCommand, callbackFile
end

function SNSHDRProcess.getProcessedImage( functionContext, callbackFile )
    local progress = LrProgressScope({
        title = LOC "$$$/SNSHDR/Export/WaitingForProcessedImage=Waiting for HDR image...",
        functionContext = functionContext
    })

    -- wait for the callback file to appear
    repeat
        LrTasks.sleep( 1 )
        if progress:isCanceled() then
            break
        end
    until LrFileUtils.exists( callbackFile )

    if LrFileUtils.exists( callbackFile ) then
        -- read filename from callback file
        local f = assert(io.open( callbackFile, "r" ))
        local processedImage = f:read("*line")

        -- file name is enclosed in parentheses & contains line break
        return string.sub(processedImage, 2, -3)
    end

end

function SNSHDRProcess.getOutputFile( renditionFile, numRenditions, format )
    local prefix = LrPathUtils.removeExtension( renditionFile )
    local extension

    if format == 'jpeg' then
        extension = LrExportSettings.extensionForFormat( 'JPEG' )
    else
        extension = LrExportSettings.extensionForFormat( 'TIFF' )
    end

    return prefix .. '_SNSHDR_' .. numRenditions .. '.' .. extension
end


function SNSHDRProcess.processExport( exportContext )
    local exportSession = exportContext.exportSession
    local exportSettings = assert( exportContext.propertyTable )
    local nPhotos = exportSession:countRenditions()

    local progress = exportContext:configureProgress({
        title = LOC("$$$/SNSHDR/Export/Progress=Exporting ^1 photos", nPhotos)
    })

    local callbackFile
    local postProcessCommand

    -- collect rendered files...
    local renditionDir
    local renditionFile
    local sourceDir

    local files = ""

    for i, rendition in exportContext:renditions() do
        renditionDir = LrPathUtils.parent( rendition.destinationPath )
        renditionFile = rendition.destinationPath
        sourceDir = LrPathUtils.parent( rendition.photo:getRawMetadata('path') )

        if not rendition.wasSkipped then
            files = files .. ' "' .. rendition.destinationPath .. '"'
            rendition:waitForRender()
        else
            -- use source (original) images if rendition was skipped
            files = files .. ' "' .. rendition.photo:getRawMetadata( 'path' ) .. '"'
        end
    end

    if progress:isCanceled() then
        return
    end

    -- Build the commandline ...

    local cmd = '"' .. exportSettings.application .. '"'

    if WIN_ENV == true then
        -- open the command in a visible window
        cmd = 'START "SNS-HDR" ' .. cmd
    end

    -- currently, only the "Lite" version accepts these commandline options
    if exportSettings.enable_lite_options then
        if not exportSettings.alignment then
            cmd = cmd .. ' -da'
        end

        if not exportSettings.deghosting then
            cmd = cmd .. ' -dd'
        end

        if exportSettings.panorama_mode then
            cmd = cmd .. ' -pm'
        end

        cmd = cmd .. ' -' .. exportSettings.size
        cmd = cmd .. ' -' .. exportSettings.preset
    end

    -- all version support the following options

    if exportSettings.srgb then
        cmd = cmd .. ' -srgb'
    end

    cmd = cmd .. ' -' .. exportSettings.output_format

    -- specify output file
    cmd = cmd .. ' -o "' .. SNSHDRProcess.getOutputFile( renditionFile, nPhotos, exportSettings.output_format ) .. '"'

    -- create & append callback script
    postProcessCommand, callbackFile = SNSHDRProcess.createPostProcessCommand( renditionDir );
    cmd = cmd .. ' -ee "' .. postProcessCommand .. '"'

    -- append rendered files
    cmd = cmd .. files

    -- LrDialogs.message( "Command", cmd )

    -- execute the actual command
    if LrTasks.execute( cmd ) ~= 0 then
        LrDialogs.message( LOC "$$$/SNSHDR/Error=Error",
               LOC "$$$/SNSHDR/Export/ErrorExecutingCommand=Error executing SNS-HDR command!" )
    end

    progress:done()

    if callbackFile ~= nil then
        -- wait for the callback file / processed image to appear
        local processedImage = LrFunctionContext.callWithContext(
            "getProcessedImage",
            SNSHDRProcess.getProcessedImage,
            callbackFile )

        if processedImage ~= nil then
            -- move the processed image to the source image directory
            local destination = LrPathUtils.child( sourceDir, LrPathUtils.leafName( processedImage ) )
            destination = LrFileUtils.chooseUniqueFileName( destination )

            LrFileUtils.move( processedImage, destination )

            -- import it?
            if exportSettings.reimport then
                exportSession.catalog:withWriteAccessDo( LOC "$$$/SNSHDR/Export/Import=Import tonemapped file",
                    function()
                        exportSession.catalog:addPhoto( destination )
                    end )
            end
        end
    end
end

return SNSHDRProcess
------------------------------------------------------------------------------------------
-- Copyright (c) 2012 Michael Kötter - http://github.com/michaelkoetter/snshdr_lightroom
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

local SNSHDRDialogs = require 'SNSHDRDialogs'
local SNSHDRProcess = require 'SNSHDRProcess'

local exportServiceProvider = {}

exportServiceProvider.exportPresetFields = {
	{ key = 'alignment', default = true },			-- "-da" switch
	{ key = 'deghosting', default = true },			-- "-dd" switch
	{ key = 'panorama_mode', default = false },		-- "-pm" switch
	{ key = 'srgb', default = false },				-- "-srgb" switch
	{ key = 'size', default = "x1" },				-- "-x1", "-x2", "-x3", "-x4" switches
	{ key = 'preset', default = "default" },		-- preset switches
	{ key = 'output_format', default = "tiff16" },	-- "-jpeg", "-tiff8", "-tiff16" switches
	{ key = 'application', default = "SNS-HDR.exe" },
	{ key = 'reimport', default = true },
	{ key = 'enable_lite_options', default = true }
}

exportServiceProvider.hideSections = { 'exportLocation', 'fileNaming', 'outputSharpening', 'watermarking', 'video', 'imageSettings', 'metadata' }

exportServiceProvider.allowFileFormats = { 'JPEG', 'TIFF', 'ORIGINAL' }
exportServiceProvider.allowColorSpaces = { 'sRGB', 'AdobeRGB', 'ProPhotoRGB' }

exportServiceProvider.hidePrintResolution = true
exportServiceProvider.canExportVideo = false

function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )

	return {
        SNSHDRDialogs.configuration( f, propertyTable ),
        SNSHDRDialogs.exportSettings( f, propertyTable ),
	}

end


function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
    SNSHDRProcess.processExport( exportContext )
end

function exportServiceProvider.startDialog( propertyTable )
    SNSHDRDialogs.applicationChanged( propertyTable )
end

function exportServiceProvider.updateExportSettings( exportSettings )
    SNSHDRDialogs.updateExportSettings( exportSettings )
end

return exportServiceProvider

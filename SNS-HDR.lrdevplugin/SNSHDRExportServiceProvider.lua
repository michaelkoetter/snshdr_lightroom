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

local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local LrTasks = import 'LrTasks'

local bind = LrView.bind
local share = LrView.share


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
	{ key = 'select_at_export_time', default = false }
}

exportServiceProvider.hideSections = { 'exportLocation', 'fileNaming', 'outputSharpening', 'watermarking', 'video' }

exportServiceProvider.allowFileFormats = { 'JPEG', 'TIFF', 'ORIGINAL' }
exportServiceProvider.allowColorSpaces = { 'sRGB', 'AdobeRGB', 'ProPhotoRGB' }

exportServiceProvider.hidePrintResolution = true
exportServiceProvider.canExportVideo = false

function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )

	return {

		{
			title = LOC "$$$/SNSHDR/ExportDialog/Configuration=SNS-HDR Configuration",

			f:row {
				spacing = f:control_spacing(),

				f:static_text {
					title = LOC "$$$/SNSHDR/ExportDialog/Configuration/Application=SNS-HDR Lite application",
					alignment = 'right',
					width = share 'labelWidth'
				},

				f:edit_field {
					value = bind 'application',
					enabled = false,
					fill_horizontal = 1
				},

				f:push_button {
					title = LOC "$$$/SNSHDR/ExportDialog/Configuration/SelectApplication=Select...",
					action = function()
						local application = LrDialogs.runOpenPanel( {
								canChooseFiles = true,
								canChooseDirectories = false,
								canCreateDirectories = false,
								allowsMultipleSelection = false
							} )
						propertyTable.application = application[1]
					end
				}
			},

			f:row {
				spacing = f:control_spacing(),
			},
		},

		{
			title = LOC "$$$/SNSHDR/ExportDialog/Settings=SNS-HDR Settings",
			--[[
			-- this feature will be in a
			f:row {
				spacing = f:control_spacing(),
				f:checkbox {
					title = LOC "$$$/SNSHDR/ExportDialog/Settings/SelectAtExportTime=Select at export time (useful for presets)",
					value = bind 'select_at_export_time'
				}
			},
			]]

			f:row {
				spacing = f:control_spacing(),
				f:static_text {
					title = LOC "$$$/SNSHDR/ExportDialog/Settings/Options=Options",
					width = share 'labelWidth'
				},

				f:column {
					spacing = f:control_spacing(),

					f:checkbox {
						enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
						title = LOC "$$$/SNSHDR/ExportDialog/Settings/Alignment=Align images",
						value = bind 'alignment'
					},
					f:checkbox {
						enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
						title = LOC "$$$/SNSHDR/ExportDialog/Settings/Deghosting=Enable deghosting",
						value = bind 'deghosting'
					},
					f:checkbox {
						enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
						title = LOC "$$$/SNSHDR/ExportDialog/Settings/Panorama=Panorama mode",
						value = bind 'panorama_mode'
					}
				}
			},

			f:row {
				spacing = f:control_spacing(),

				f:static_text {
					title = LOC "$$$/SNSHDR/ExportDialog/Settings/SizeReduction=Reduce size",
					width = share 'labelWidth'
				},

				f:radio_button {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					title = "1x",
					checked_value = "x1",
					value = bind 'size'
				},
				f:radio_button {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					title = "2x",
					checked_value = "x2",
					value = bind 'size'
				},
				f:radio_button {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					title = "3x",
					checked_value = "x3",
					value = bind 'size'
				},
				f:radio_button {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					title = "4x",
					checked_value = "x4",
					value = bind 'size'
				}
			},

			f:row {
				spacing = f:control_spacing(),
				f:static_text {
					title = LOC "$$$/SNSHDR/ExportDialog/Settings/Preset=Tonemapping preset",
					width = share 'labelWidth'
				},

				f:popup_menu {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					value = bind 'preset',
					width = 200,
					items = {
						{ title = 'Default', value = 'default' },
						{ title = 'Dramatic', value = 'dramatic' },
						{ title = 'Interior', value = 'interior' },
						{ title = 'LDR', value = 'ldr' },
						{ title = 'Natural', value = 'natural' },
						{ title = 'Neutral', value = 'neutral' },
						{ title = 'Night', value = 'night' },
						{ title = 'Soft', value = 'soft' },
					}
				},
			},

			f:row {
				spacing = f:control_spacing(),
				f:static_text {
					title = LOC "$$$/SNSHDR/ExportDialog/Settings/OutputFormat=Output format",
					width = share 'labelWidth'
				},

				f:popup_menu {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					value = bind 'output_format',
					width = 100,
					items = {
						{ title = 'JPEG', value = 'jpeg' },
						{ title = 'TIFF 8-bit', value = 'tiff8' },
						{ title = 'TIFF 16-bit', value = 'tiff16' },
					}
				},

				f:checkbox {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					title = LOC "$$$/SNSHDR/ExportDialog/Settings/sRGB=Use sRGB colorspace",
					value = bind 'srgb'
				}
			},

			f:row {
				spacing = f:control_spacing(),
				f:spacer {
					width = share 'labelWidth'
				},

				f:checkbox {
					enabled = LrBinding.negativeOfKey( "select_at_export_time" ),
					title = LOC "$$$/SNSHDR/ExportDialog/Configuration/Reimport=Automatically import tonemapped file",
					value = bind 'reimport'
				}
			},
		}
	}

end


function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	local exportSession = exportContext.exportSession
	local exportSettings = assert( exportContext.propertyTable )
	local nPhotos = exportSession:countRenditions()

	exportContext:configureProgress { title = LOC("$$$/SNSHDR/Export/Progress=Exporting ^1 photos", nPhotos) }

	-- Build the commandline ...

	local cmd = '"' .. exportSettings.application .. '"'

	if not exportSettings.alignment then
		cmd = cmd .. ' -da'
	end

	if not exportSettings.deghosting then
		cmd = cmd .. ' -dd'
	end

	if exportSettings.panorama_mode then
		cmd = cmd .. ' -pm'
	end

	if exportSettings.srgb then
		cmd = cmd .. ' -srgb'
	end

	cmd = cmd .. ' -' .. exportSettings.size
	cmd = cmd .. ' -' .. exportSettings.preset
	cmd = cmd .. ' -' .. exportSettings.output_format

	-- Append rendered files to commandline...

	local renditionDir
	local sourceDir
	for i, rendition in exportContext:renditions() do
		cmd = cmd .. ' "' .. rendition.destinationPath .. '"'
		renditionDir = LrPathUtils.parent( rendition.destinationPath )
		sourceDir = LrPathUtils.parent( rendition.photo:getRawMetadata('path') )

		rendition:waitForRender()
	end

	if WIN_ENV == true then
		-- open the command in a visible window
		cmd = 'START "SNS-HDR Lite" /LOW /WAIT ' .. cmd
	end

	-- execute the actual command
	if LrTasks.execute( cmd ) ~= 0 then
		LrDialogs.message( "Error executing command", other )
	else
		-- everything went well, search the output file
		local fileSearchPattern = "HDR(" .. nPhotos .. ")"
		for filePath in LrFileUtils.files( renditionDir ) do

			if string.find( filePath, fileSearchPattern, 1, true ) ~= nil then
				-- move the output file
				local destination = LrPathUtils.child( sourceDir, LrPathUtils.leafName( filePath ) )
				destination = LrFileUtils.chooseUniqueFileName( destination )

				LrFileUtils.move( filePath, destination )

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
end

return exportServiceProvider

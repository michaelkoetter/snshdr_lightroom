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

local LrBinding = import 'LrBinding'
local LrView = import 'LrView'
local LrDialogs = import 'LrDialogs'

local bind = LrView.bind
local share = LrView.share

local SNSHDRDialogs = {}

function SNSHDRDialogs.configuration( f, propertyTable )
    return
    {
        title = LOC "$$$/SNSHDR/ExportDialog/Configuration=SNS-HDR Configuration",

        f:row {
            spacing = f:control_spacing(),

            f:static_text {
                title = LOC "$$$/SNSHDR/ExportDialog/Configuration/Application=SNS-HDR application",
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

        f:column {
            place = "overlapping",

            f:view {
                visible = LrBinding.negativeOfKey 'enable_lite_options',
                f:row {
                    f:static_text {
                        title = LOC "$$$/SNSHDR/ExportDialog/Configuration/LiteOptionsDisabled=It looks like you are using SNS-HDR Pro/Home, some settings will be disabled.",
                    }
                },
            },

            f:view {
                visible = bind 'enable_lite_options',
                f:row {
                    f:static_text {
                        title = LOC "$$$/SNSHDR/ExportDialog/Configuration/LiteOptionsEnabled=SNS-HDR Lite settings will be enabled."
                    }
                },
            },
        }

    }
end


function SNSHDRDialogs.applicationChanged( properties )
    if string.find(properties.application, "Pro.exe") ~= nil then
        properties.enable_lite_options = false
    elseif string.find(properties.application, "Home.exe") ~= nil then
        properties.enable_lite_options = false
    else
        properties.enable_lite_options = true
    end
end

function SNSHDRDialogs.exportSettings( f, propertyTable )

    propertyTable:addObserver( 'application', SNSHDRDialogs.applicationChanged )

    return
    {
        title = LOC "$$$/SNSHDR/ExportDialog/Settings=SNS-HDR Settings",

        f:row {
            spacing = f:control_spacing(),
            f:static_text {
                title = LOC "$$$/SNSHDR/ExportDialog/Settings/Options=Options",
                width = share 'labelWidth'
            },

            f:column {
                spacing = f:control_spacing(),

                f:checkbox {
                    enabled = bind 'enable_lite_options',
                    title = LOC "$$$/SNSHDR/ExportDialog/Settings/Alignment=Align images",
                    value = bind 'alignment'
                },
                f:checkbox {
                    enabled = bind 'enable_lite_options',
                    title = LOC "$$$/SNSHDR/ExportDialog/Settings/Deghosting=Enable deghosting",
                    value = bind 'deghosting'
                },
                f:checkbox {
                    enabled = bind 'enable_lite_options',
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
                enabled = bind 'enable_lite_options',
                title = "1x",
                checked_value = "x1",
                value = bind 'size'
            },
            f:radio_button {
                enabled = bind 'enable_lite_options',
                title = "2x",
                checked_value = "x2",
                value = bind 'size'
            },
            f:radio_button {
                enabled = bind 'enable_lite_options',
                title = "3x",
                checked_value = "x3",
                value = bind 'size'
            },
            f:radio_button {
                enabled = bind 'enable_lite_options',
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
                enabled = bind 'enable_lite_options',
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
                value = bind 'output_format',
                width = 100,
                items = {
                    { title = 'JPEG', value = 'jpeg' },
                    { title = 'TIFF 8-bit', value = 'tiff8' },
                    { title = 'TIFF 16-bit', value = 'tiff16' },
                }
            },

            f:checkbox {
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
                title = LOC "$$$/SNSHDR/ExportDialog/Configuration/Reimport=Automatically import tonemapped file",
                value = bind 'reimport'
            }
        },
    }
end

return SNSHDRDialogs
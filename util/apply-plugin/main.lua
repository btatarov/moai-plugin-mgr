require ( 'io' )
require ( 'os' )

-- =============================================================
-- Params
-- =============================================================
AVAILABLE_PLUGINS   = {}
PLUGIN              = nil

----------------------------------------------------------------
PLUGIN = arg [ 4 ]
assert ( PLUGIN, 'You must specify a plugin name.\n' ..
                 'Use: ./bin/apply-plugin.sh <plugin-name>\n' )

-- =============================================================
-- Helper functions
-- =============================================================
local askUserForDecision
local installPlugin
local isPluginInstalled
local processConfigFile
local processDependances
local processPluginFiles
local uninstallPlugin

----------------------------------------------------------------
askUserForDecision = function ( question, exit_on_confirm )

    local answer
    repeat
        io.write ( string.format ( '%s (y/n) ', question ) )
        io.flush ()
        answer = string.lower ( io.read () )
    until util.isMember ( { 'yes', 'no', 'y', 'n' }, answer )

    if util.isMember ( { 'no', 'n' }, answer ) or exit_on_confirm then
        os.exit ()
    end
end

----------------------------------------------------------------
installPlugin = function ( plugin_name )

    local plugin = AVAILABLE_PLUGINS [ plugin_name ]
    assert ( plugin, string.format ( 'Plugin "%s" not found.', plugin_name ) )

    print ( 'Installing plugin: ' .. plugin_name )

    -- in case of cyclic dependances...
    local depends = plugin.depends
    plugin.depends = nil

    processDependances ( depends )
    processPluginFiles ( plugin_name )
end

----------------------------------------------------------------
isPluginInstalled = function ( plugin_name )

    local plugin = AVAILABLE_PLUGINS [ plugin_name ]
    assert ( plugin, string.format ( 'Plugin "%s" not found.', plugin_name ) )

    -- save for later
    local depends = plugin.depends
    plugin.depends = nil

    local installed = false
    local partial = false
    local first_step = true

    for dir, rules in pairs ( plugin ) do

        for i, rule in ipairs ( rules ) do

            if rule [ 'dir' ] then

                local real_dir_path = string.format ( '%s%s/%s/',
                                        MOAI_SDK_HOME, dir, rule [ 'dir' ] )


                if MOAIFileSystem.checkPathExists ( real_dir_path ) then
                    installed = true
                elseif installed or first_step then
                    partial = true
                end

                first_step = false
            end

            if rule [ 'file' ] then

                local real_file_path = string.format ( '%s%s/%s',
                                        MOAI_SDK_HOME, dir, rule [ 'file' ] )

                if MOAIFileSystem.checkFileExists ( real_file_path ) then
                    installed = true
                elseif installed or first_step then
                    partial = true
                end

                first_step = false
            end
        end
    end

    if partial then

        askUserForDecision ( string.format (
                             'Warning! Plugin "%s" is only partially installed. ' ..
                             'Would you like to try and clean it first?', plugin_name ) )
        uninstallPlugin ( plugin_name, true )
        installed = false
    end

    plugin.depends = depends

    return installed
end

----------------------------------------------------------------
processConfigFile = function ( filename )

	filename = MOAIFileSystem.getAbsoluteFilePath ( filename )
    assert ( MOAIFileSystem.checkFileExists ( filename ), 'Config file not found.' )

	local configFile = {}
	util.dofileWithEnvironment ( filename, configFile )

    for _, plugin in ipairs ( configFile.PLUGINS ) do

        plugin_filename = MOAIFileSystem.getAbsoluteFilePath (
            string.format ( '../../plugins/%s/plugin.lua', plugin ) )

        assert ( MOAIFileSystem.checkFileExists ( plugin_filename ),
                            'Config file not found for plugin: ' .. plugin )

        local pluginFile = {}
        util.dofileWithEnvironment ( plugin_filename, pluginFile )

        AVAILABLE_PLUGINS [ plugin ] = pluginFile.PLUGIN
    end
end

----------------------------------------------------------------
processDependances = function ( dependances )

    if not dependances then return end

    print ( 'Processing plugin dependances...' )
    for i, plugin_name in ipairs ( dependances ) do

        if not isPluginInstalled ( plugin_name ) then
            installPlugin ( plugin_name )
        end
    end
end

----------------------------------------------------------------
processPluginFiles = function ( plugin_name )

    local plugin = AVAILABLE_PLUGINS [ plugin_name ]
    assert ( plugin, string.format ( 'Plugin "%s" not found.', plugin_name ) )

    -- save for later
    local depends = plugin.depends
    plugin.depends = nil

    if isPluginInstalled ( plugin_name ) then

        askUserForDecision ( 'Plugin is already installed. ' ..
                        'Would you like to uninstall it first?' )
        uninstallPlugin ( plugin_name, true )
    end

    io.write ( 'Putting files in place... ' )

    for dir, rules in pairs ( plugin ) do

        for i, rule in ipairs ( rules ) do

            if rule [ 'dir' ] then

                local real_dir_path = string.format ( '%s%s/%s/',
                                        MOAI_SDK_HOME, dir, rule [ 'dir' ] )

                local rule_dir_path = string.format ( '../../plugins/%s/%s/%s/',
                                                plugin_name, dir, rule [ 'dir' ] )
                rule_dir_path = util.getAbsoluteDirPath ( rule_dir_path )

                MOAIFileSystem.affirmPath ( real_dir_path )
                MOAIFileSystem.copy ( rule_dir_path, real_dir_path )
            end

            -- Intentionally not "elseif" to use the same table for
            -- different things, i.e. { file = '..', dir = '...' }
            -- This may be useful for copying single config files.
            if rule [ 'file' ] then

                local real_file_path = string.format ( '%s%s/%s',
                                        MOAI_SDK_HOME, dir, rule [ 'file' ] )

                local rule_file_path = string.format ( '../../plugins/%s/%s/%s',
                                                plugin_name, dir, rule [ 'file' ] )
                rule_file_path = MOAIFileSystem.getAbsoluteFilePath ( rule_file_path )

                 MOAIFileSystem.affirmPath ( util.getFolderFromPath ( real_file_path ) )
                MOAIFileSystem.copy ( rule_file_path, real_file_path )
            end
        end
    end

    plugin.depends = depends

    io.write ( 'done\n' )
end

----------------------------------------------------------------
uninstallPlugin = function ( plugin_name, forced )

    local plugin = AVAILABLE_PLUGINS [ plugin_name ]
    assert ( plugin, string.format ( 'Plugin "%s" not found.', plugin_name ) )

    -- save for later
    local depends = plugin.depends
    plugin.depends = nil

    if not forced then
        print ( 'Warning! Uninstalling a plugin is a destructive operation. You may loose your changes.' )
        askUserForDecision ( 'Uninstall plugin: ' .. plugin_name )
    end

    io.write ( 'Removing plugin files... ' )

    for dir, rules in pairs ( plugin ) do

        for i, rule in ipairs ( rules ) do

            if rule [ 'dir' ] then

                local real_dir_path = string.format ( '%s%s/%s/',
                                        MOAI_SDK_HOME, dir, rule [ 'dir' ] )

                MOAIFileSystem.deleteDirectory ( real_dir_path )
            end

            if rule [ 'file' ] then

                local real_file_path = string.format ( '%s%s/%s',
                                        MOAI_SDK_HOME, dir, rule [ 'file' ] )

                MOAIFileSystem.deleteFile ( real_file_path )
            end
        end
    end

    plugin.depends = depends

    io.write ( 'done\n' )
end

-- =============================================================
-- Main
-- =============================================================
processConfigFile ( 'config.lua' )
installPlugin ( PLUGIN )

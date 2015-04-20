# HackUtilsView = require './hack-utils-view'

_     = require 'underscore-plus'
Fs    = require 'fs'
Path  = require 'path'
CSON  = require 'cson'
VM    = require 'vm'
Util  = require 'util'
Watch = require('chokidar').watch

{CompositeDisposable} = require 'atom'
{TextEditor}          = require 'atom'
{$, $$, View}         = require 'atom-space-pen-views'
{execSync, spawnSync} = require 'child_process'

LOG = console.log.bind console

module.exports = HackUtils =
    # hackUtilsView: null
    # modalPanel: null
    subscriptions: null

    Eval:
        files: []

        watch: (filename) ->
            return if _.some @files, (e) -> e.file == filename
            filename = Fs.realpathSync filename
            watcher = Watch filename
            watcher.on 'change', @reload
            @files.push
                file: filename,
                watcher: watcher

        # Called by chokidar.watch on file change
        #
        # * `filename` path to file
        # * `stats` fs.stats on filename
        #
        # Returns the required filename
        reload: (filename, stats) ->
            # filename = Path.resolve filename
            delete window.require(filename)
            delete require.cache[filename]
            window.require(filename)

        unrequire: ->
            delete window.require.cache[filename]

        coffee: (fn, run) ->
            console.log 'Loading ' + fn
            cmd = "coffee"
            args = [ "-p", fn ]
            ret = spawnSync(cmd, args)
            # console.log ret
            try
                code = ret.stdout.toString()
                result = eval.call(window, code) if run?
                console.log fn + ' reloaded'
                return code
            catch e
                console.error e
                return false

    # Load files and watch/autoreload them
    #
    # * `files` list of files to watch in absolute path
    initLib: (files) ->
        for f in files
            try
                window.require f
                Eval.watch f
            catch e
                console.error e

    # Reload the file
    #
    # * `filename` path to file
    #
    # Returns the required filename
    reload: (args...) ->
        filename = Path.resolve args...
        console.log "Reloading ", filename
        delete window.require(filename)
        delete require.cache[filename]
        window.require(filename)

    reloadPackage: (name) ->
        pk       = atom.packages
        pack     = pk.getActivePackage name
        path     = Fs.realpathSync pack.path
        filename = pack.mainModulePath
        return unless pack?
        console.log path

        pk.deactivatePackage(name)
        pk.unloadPackage(name)

        modules = window.require.cache
        _.each modules, (m, l, c) =>
            console.log path, m.filename.indexOf(path)
            @reload m.filename if m.filename.indexOf(path) != -1
        , @

        pack = pk.enablePackage(path)
        pack.name = name
        window.tempDisposable = pk.onDidActivatePackage (pack) ->
            console.log "Hack: package reloaded '#{pack.name}'"
            console.log pack
            window.tempDisposable.dispose()
        pk.activatePackage(name)

    activate: (state) ->
        @subscriptions = new CompositeDisposable
        window.hack = @
        console.log 'Hack: on'

    deactivate: ->
        # @modalPanel.destroy()
        @subscriptions.dispose()
        # @hackUtilsView.destroy()

    serialize: ->
        # hackUtilsViewState: @hackUtilsView.serialize()

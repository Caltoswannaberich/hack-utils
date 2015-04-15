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

    Config:
        set: 'ok'

    Eval:
        files: []

        watch: (filename) ->
            filename = Fs.realpathSync filename
            LOG 'Hack: watching ' + filename
            watcher = Watch filename
            watcher.on 'change', @reload
            @files.push
                file: filename,
                watcher: watcher

        reload: (filename, stats) ->
            # filename = Path.resolve filename
            delete require.cache[filename]
            window.require(filename)

        removeFromCache: ->
            delete require.cache[filename]

        requireNoCache: (context, filename) ->
            require.cache.remove(filename)
            require(filename)

        coffee: (fn) ->
            console.log 'Loading ' + fn
            cmd = "coffee"
            args = [ "-p", fn ]
            ret = spawnSync(cmd, args)
            # console.log ret
            try
                code = ret.stdout.toString()
                result = eval.call(window, code)
                console.log fn + ' reloaded'
                return result
            catch e
                console.error e
                return false


    require: (name) ->
        funcs = [
            (n) -> window.require n
            (n) -> window.require atom.packages.getActivePackage(n).mainModulePath
            (n) -> window.require Path.resolve(process.env.ATOM_HOME, n)
        ]
        for f in funcs
            try
                return window.require name
            catch e
                continue
        throw new Error('module not found')

    reload: (filename) ->
        delete window.module.children[filename]
        delete window.require.cache[filename]
        window.require filename

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
        # @subscriptions.dispose()
        # @hackUtilsView.destroy()

    serialize: ->
        # hackUtilsViewState: @hackUtilsView.serialize()

    toggle: ->
        console.log 'HackUtils was toggled!'
        # if @modalPanel.isVisible()
        #     @modalPanel.hide()
        # else
        #     @modalPanel.show()

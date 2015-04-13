HackUtilsView = require './hack-utils-view'
{CompositeDisposable} = require 'atom'

console.log  module.paths
module.require '/home/romgrk/github/hack-utils/lib/hack-utils.coffee'
module.exports = HackUtils =
    Config:
        set: 'ok'

    hackUtilsView: null
    modalPanel: null
    subscriptions: null

    activate: (state) ->
        @hackUtilsView = new HackUtilsView(state.hackUtilsViewState)
        # @modalPanel = atom.workspace.addModalPanel(item: @hackUtilsView.getElement(), visible: false)

        # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        # Register command that toggles this view
        @subscriptions.add atom.commands.add 'atom-workspace', 'hack-utils:toggle': => @toggle()

    deactivate: ->
        @modalPanel.destroy()
        @subscriptions.dispose()
        @hackUtilsView.destroy()

    serialize: ->
        hackUtilsViewState: @hackUtilsView.serialize()

    toggle: ->
        console.log 'HackUtils was toggled!'
        if @modalPanel.isVisible()
            @modalPanel.hide()
        else
            @modalPanel.show()

_.extend Template.fxpair,

##
## Computed fields and field formatters
#######################################

    color: ->
        change = Changes.findOne(@_id)
        if change
            if (Date.now()-change.time) >= 60000
                ''
            else
                change.color
        else
            ''

    symbol: ->
        @symbol.slice 0,6

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']

##
## Template event handlers
#######################################

Template.fxpair.events {

    'click #remove-fxpair': (evt) ->
        Meteor.call 'removeInstrument', @symbol,
            (error, result) ->
                newAlert 'alert-error', "#{result}" if result isnt 'ok'
}

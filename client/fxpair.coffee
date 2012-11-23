_.extend Template.fxpair,

##
## Computed fields and field formatters
#######################################

    symbol: ->
        @symbol.slice 0,6

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

##
## Template event handlers
#######################################

Template.fxpair.events {

    'click #remove-fxpair': (evt) ->
        Meteor.call 'removeInstrument', @symbol,
            (error, result) ->
                newAlert 'alert-error', "#{result}" if result isnt 'ok'
}

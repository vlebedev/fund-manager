_.extend Template.monetary_asset,

##
## Computed fields and field formatters
#######################################

    amount: ->
        accounting.formatNumber @amount, 2

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

##
## Template event handlers
#######################################

Template.monetary_asset.events {

    'click #remove-monetary-account': (evt) ->
        Meteor.call 'removeAccount', @,
            (error, result) ->
                newAlert 'alert-error', "#{result}", '#monetary-error-alert' if result isnt 'ok'
}
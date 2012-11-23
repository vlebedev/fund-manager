_.extend Template.stock_asset,

##
## Computed fields and field formatters
#######################################

    value: ->
        accounting.formatNumber getAssetValueInUSD('', @symbol, @amount), 2

    amount: ->
        accounting.formatNumber @amount

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

##
## Template event handlers
#######################################

Template.stock_asset.events {

    'click #remove-stock-account': (evt) ->
        Meteor.call 'removeAccount', @,
            (error, result) ->
                newAlert 'alert-error', "#{result}", '#stock-error-alert' if result isnt 'ok'
}

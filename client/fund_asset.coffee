_.extend Template.fund_asset,

##
## Computed fields and field formatters
#######################################

    value: ->
        accounting.formatNumber getAssetValueInUSD('', @symbol, @amount), 2

    amount: ->
        accounting.formatNumber @amount

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']

##
## Template event handlers
#######################################

Template.fund_asset.events {

    'click #remove-fund-account': (evt) ->
        Meteor.call 'removeAccount', @,
            (error, result) ->
                newAlert 'alert-error', "#{result}", '#fund-error-alert' if result isnt 'ok'
}

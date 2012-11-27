_.extend Template.stock_asset,

##
## Computed fields and field formatters
#######################################

    value: ->
        getAssetValueInUSD('', @symbol, @amount).format(2)

    amount: ->
        @amount.format()

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']


##
## Template event handlers
#######################################

Template.stock_asset.events {

    'click #remove-stock-account': (evt) ->
        Meteor.call 'removeAccount', @,
            (error, result) ->
                newAlert 'alert-error', "#{result}", '#stock-error-alert' if result isnt 'ok'
}

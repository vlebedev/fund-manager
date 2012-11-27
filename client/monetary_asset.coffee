_.extend Template.monetary_asset,

##
## Computed fields and field formatters
#######################################

    amount: ->
        @amount.format(2)

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']


##
## Template event handlers
#######################################

Template.monetary_asset.events {

    'click #remove-monetary-account': (evt) ->
        Meteor.call 'removeAccount', @,
            (error, result) ->
                newAlert 'alert-error', "#{result}", '#monetary-error-alert' if result isnt 'ok'
}
##
## 'client_chooser' was put into separate template
## as a workaround for Meteor 'select state is not persisted' bug
#################################################################

_.extend Template.client_chooser,

##
## Lists
#######################################

    t_clients: ->
        Clients.find {}, { sort : { symbol: 1 } }

##
## Rendering finished handler, contains workaround for Meteor 'select state is not persisted' bug
#################################################################################################

    rendered: ->

        if !Session.get 'trans_client_id'
            Session.set 'trans_client_id', Clients.findOne({ symbol: $('.client-select :selected').val() })?._id
        else
            $('.client-select').val(Session.get('pooty_poot'))

##
## Template event handlers
#######################################

Template.client_chooser.events {

    'change .client-select': (evt) ->
        Session.set 'trans_client_id', Clients.findOne({ symbol: evt.target.value })._id
        Session.set 'pooty_poot', $('.client-select :selected').html()
}

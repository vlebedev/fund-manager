Changes = new Meteor.Collection 'price_changes'

Session.set 'client_id', null
Session.set 'transactions_selected', null
Session.set 'stocks_selected', null
Session.set 'fx_selected', null
Session.set 'funds_selected', null
Session.set 'add_new_client_selected', null
Session.set 'add_new_fund_selected', null
Session.set 'trans_client_id', null
Session.set 'error_message', null
Session.set 'unlisted_dialog', null
Session.set 'editing_stock_id', null

okCancelEvents = (selector, callbacks) ->
    ok = callbacks.ok || ->
    cancel = callbacks.cancel || ->
    events = {}
    # removed <<+', focusout '+selector>> 
    events['keyup '+selector+', keydown '+selector] = (evt) ->

        if evt.type is 'keydown' and evt.which is 27
            # escape = cancel
            cancel.call @, evt
        else if evt.type is 'keyup' and evt.which is 13 or evt.type is 'focusout'
            # blur/return/enter = ok/submit if non-empty
            value = String(evt.target.value or '');
            if value
                ok.call @, value, evt
            else
                cancel.call @, evt
    events

okCancelEventsFull = (selector, callbacks) ->
    ok = callbacks.ok || ->
    cancel = callbacks.cancel || ->
    events = {}

    events['keyup '+selector+', keydown '+selector+', focusout '+selector] = (evt) ->

        if evt.type is 'keydown' and evt.which is 27
            # escape = cancel
            cancel.call @, evt
        else if evt.type is 'keyup' and evt.which is 13 or evt.type is 'focusout'
            # blur/return/enter = ok/submit if non-empty
            value = String(evt.target.value or '');
            if value
                ok.call @, value, evt
            else
                cancel.call @, evt
    events

activateInput = (input) ->
    input.focus()
    input.select()

newAlert = (type, message, id) ->

    if !id
        id = "#alert-area"

    $("#{id}").append($("<div class='alert " + type + " fade in' data-alert><a href='#' class='close' data-dismiss='alert'>×</a>" + message + "</div>"))

    $(".alert").delay(5000).fadeOut "slow", 
        -> $(@).remove()

FmRouter = Backbone.Router.extend {

    routes: {
        'transactions': 'transactions'
        'stocks': 'stocks'
        'fx': 'fx'
        'funds': 'funds'
        ':client_id': 'clients' 
        },

    transactions: ->
        Session.set 'client_id', null
        Session.set 'transactions_selected', 'active'
        Session.set 'stocks_selected', null
        Session.set 'fx_selected', null
        Session.set 'funds_selected', null
        Session.set 'trans_client_id', null
        Session.set 'add_new_client_selected', null
        Session.set 'add_new_fund_selected', null

    stocks: ->
        Session.set 'client_id', null
        Session.set 'transactions_selected', null
        Session.set 'stocks_selected', 'active'
        Session.set 'fx_selected', null
        Session.set 'funds_selected', null
        Session.set 'trans_client_id', null
        Session.set 'add_new_client_selected', null
        Session.set 'add_new_fund_selected', null

    fx: ->
        Session.set 'client_id', null
        Session.set 'transactions_selected', null
        Session.set 'stocks_selected', null
        Session.set 'fx_selected', 'active'
        Session.set 'funds_selected', null
        Session.set 'trans_client_id', null
        Session.set 'add_new_client_selected', null
        Session.set 'add_new_fund_selected', null

    funds: ->
        Session.set 'client_id', null
        Session.set 'transactions_selected', null
        Session.set 'stocks_selected', null
        Session.set 'fx_selected', null
        Session.set 'funds_selected', 'active'
        Session.set 'trans_client_id', null
        Session.set 'add_new_client_selected', null
        Session.set 'add_new_fund_selected', null

    clients: (client_id) ->
        Session.set 'client_id', client_id
        Session.set 'transactions_selected', null
        Session.set 'stocks_selected', null
        Session.set 'fx_selected', null
        Session.set 'funds_selected', null
        Session.set 'trans_client_id', null
        Session.set 'add_new_client_selected', null
        Session.set 'add_new_fund_selected', null

    setMain: (client_id) ->
        @navigate client_id, true
}

Router = new FmRouter

Meteor.autosubscribe ->
    Meteor.subscribe 'instruments'
    Meteor.subscribe 'price_changes'
    Meteor.subscribe 'clients'
    Meteor.subscribe 'assets'
    Meteor.subscribe 'transactions'
    username = Meteor.users.findOne(Meteor.userId())?.username

    if username in ['admin', 'dev']
        client_id = Clients.findOne({}, { sort: { symbol: 1 } })?._id
    else if username
        username = username.toUpperCase()
        client_id = Clients.findOne({ type: 'c', symbol: username })?._id

    Router.setMain client_id if client_id

Meteor.startup ->
    Backbone.history.start pushState: true
    Accounts.config { forbidClientAccountCreation: yes }
    Accounts.ui.config { passwordSignupFields: 'USERNAME_ONLY' }



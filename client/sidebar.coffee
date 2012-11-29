_.extend Template.sidebar, 

##
## Computed fields and field formatters
#######################################

    clients: -> 
        Clients.find {}, sort: { symbol: 1 }

    transactions_selected: ->
        Session.get 'transactions_selected'

    stocks_selected: ->
        Session.get 'stocks_selected'

    fx_selected: ->
        Session.get 'fx_selected'

    funds_selected: ->
        Session.get 'funds_selected'

    selected_client: ->
        if Session.equals('client_id', @_id) and !(Session.get('add_new_client_selected') or Session.get('add_new_client_selected'))
            'active' 
        else 
            ''
    add_new_client_selected: ->
        Session.get 'add_new_client_selected'

    add_new_fund_selected: ->
        Session.get 'add_new_fund_selected'

    isDeveloper: ->
        Meteor.users.findOne(Meteor.user())?.username is 'dev'

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']

##
## Template event handlers
#######################################

Template.sidebar.events {

    'mousedown .client': (evt) ->
        Router.setMain @_id

    'mousedown .transactions': (evt) ->
        Router.setMain 'transactions'

    'mousedown .stocks': (evt) ->
        Router.setMain 'stocks'

    'mousedown .fx': (evt) ->
        Router.setMain 'fx'

    'mousedown .funds': (evt) ->
        Router.setMain 'funds'

    'mousedown .add-new-client': (evt) ->
        Router.setMain 'add_new_client'

    'mousedown .add-new-fund': (evt) ->
        Router.setMain 'add_new_fund'

    'click #add-client-btn': (evt) ->
        evt.preventDefault()
        symbol = $('#new_client_symbol').val().trim().toUpperCase()
        name = $('#new_client_name').val().trim()
        email = $('#new_client_email').val().trim()
        password = $('#new_client_password').val().trim()

        if !symbol
            newAlert 'alert-error', "Please enter client's code. Example: <strong>C009</strong>"
            return

        if !name
            newAlert 'alert-error', "Please enter client's name. Example: <strong>Barents Group LLC</strong>"
            return

        if !email
            newAlert 'alert-error', "Please enter client's e-mail."
            return

        if !password
            newAlert 'alert-error', "Please enter client's password."
            return

        Meteor.call 'addClient', symbol, name, 'c', email, password,
            (error, result) ->

                if result isnt 'ok'
                    newAlert 'alert-error', result
                else
                    $('#new_client_symbol').val('')
                    $('#new_client_name').val('')
                    $('#new_client_email').val('')
                    $('#new_client_password').val('')

    'click #add-fund-btn': (evt) ->
        evt.preventDefault()
        symbol = $('#new_fund_symbol').val().trim().toUpperCase()
        name = $('#new_fund_name').val().trim()
        
        if !symbol
            newAlert 'alert-error', "Please enter fund's code. Example: <strong>F009</strong>"
            return

        if !name
            newAlert 'alert-error', "Please enter fund's name. Example: <strong>Eurasia Foundation</strong>"
            return

        Meteor.call 'addClient', symbol, name, 'f',
            (error, result) ->

                if result isnt 'ok'
                    newAlert 'alert-error', result
                else
                    $('#new_fund_symbol').val('')
                    $('#new_fund_name').val('')

    'click #flush-database': (evt) ->
        Meteor.call 'flushDatabase'

    'click .client, click .transactions, click .stocks, click .fx, click .funds, click .add-new-client, click .add-new-fund': (evt) ->
        evt.preventDefault()
}
_.extend Template.main,

##
## Session variables
#######################################

    any_client_selected: ->
        Session.get 'client_id'

    transactions_selected: ->
        Session.get 'transactions_selected'

    stocks_selected: ->
        Session.get 'stocks_selected'

    fx_selected: ->
        Session.get 'fx_selected'

    funds_selected: ->
        Session.get 'funds_selected'

    error_message: ->
        Session.get 'error_message'

    unlisted_dialog: ->
        Session.get 'unlisted_dialog'

##
## Computed fields and field formatters
#######################################

    client_symbol: ->
        client_id = Session.get 'client_id'

        if client_id
            client = Clients.findOne(client_id)
            client?.symbol

    client_name: ->
        client_id = Session.get 'client_id'

        if client_id
            client = Clients.findOne(client_id)
            client?.name

    client_type: ->
        client_id = Session.get 'client_id'

        if client_id
            client = Clients.findOne(client_id)

            switch client?.type
                when 'c' then 'client'
                when 'f' then 'fund'

    isDeveloper: ->
        Meteor.users.findOne(Meteor.user())?.username is 'dev'

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']

##
## Lists
#######################################

    stocks: ->
        Instruments.find { type: 's' }, { sort: { symbol: 1 } }

    fx: ->
        Instruments.find { type: 'x' }, { sort: { symbol: 1 } }

    funds: ->
        Instruments.find { type: 'f' }, { sort: { symbol: 1 } }

    transactions: ->
        Transactions.find {}, { sort: { date: -1 } }

    t_assets: ->
        client_id = Session.get 'trans_client_id'
        if client_id
            Assets.find { client_id }, { sort : { symbol: 1 } }

##
## Template event handlers
#######################################

Template.main.events {

    'click .assets-tab, click .transactions-tab, click .admin-tab': (evt) ->
        evt.preventDefault()
        $(evt.target).tab 'show'

    'click #add-unlisted-dialog': (evt) ->
        evt.preventDefault()
        Session.set 'unlisted_dialog', !Session.get('unlisted_dialog')

    'click #add-unlisted-btn': ->
        symbol = $('#new_unlisted_symbol').val().trim().toUpperCase()
        name = $('#new_unlisted_name').val().trim()
        currency = $('#new_unlisted_currency').val().trim().toUpperCase()
        lastTrade = $('#new_unlisted_last').val()

        if symbol && name && lastTrade
            Meteor.call 'addUnlistedStock', symbol, name, currency, lastTrade,
                (error, result) ->
                    if result isnt 'ok'
                        newAlert 'alert-error', "#{result}"
                    else
                        Session.set 'unlisted_dialog', null

    'click #add-stock-btn': ->
        symbol = $('#stock-symbol').val().trim().toUpperCase()

        Meteor.call 'addInstrument', symbol, 's', 
            (error, result) ->

                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}"
                else
                    $('#stock-symbol').val('')

    'click #add-fxpair-btn': ->
        symbol = $('#fxpair-symbol').val().trim().toUpperCase()

        Meteor.call 'addInstrument', symbol, 'x', 
            (error, result) ->

                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}"
                else
                    $('#fxpair-symbol').val('')

    'click #add-transaction-btn': (evt) ->
        amount = $('#transaction-amount').val()
        return if Number(amount) is 0

        client = $('.client-select :selected').val()
        symbol = $('.account-select :selected').val()
        comment = $('#transaction-comment').val()
        client_id = Clients.findOne({ symbol: client })?._id
        account_id = Assets.findOne({ client_id, symbol })?._id

        if account_id and amount
            Meteor.call 'executeTransaction', account_id, Number(amount), comment,
                (error, result) ->
                    newAlert 'alert-error', "#{result}" if result isnt 'ok'
            $('#transaction-comment').val('')
            $('#transaction-amount').val('')

    'click #rollback-transaction': ->
        Meteor.call 'rollbackTransaction'

    'click #delete-client-btn': ->
        client_id = Session.get 'client_id'

        if client_id
            Meteor.call 'removeClient', Clients.findOne(client_id)?.symbol,
                (error, result) ->

                    if result is 'ok'
                        Session.set 'client_id', null

                    newAlert 'alert-error', result unless result is 'ok'
}

Template.main.events okCancelEvents '#stock-name', {

    ok: (symbol, evt) ->
        Meteor.call 'addInstrument', symbol, 's', 
            (error, result) ->
                newAlert 'alert-error', "#{result}" if result isnt 'ok'
        evt.target.value = ""
}

Template.main.events okCancelEvents '#fxpair-name', {

    ok: (symbol, evt) ->
        Meteor.call 'addInstrument', symbol, 'x',
            (error, result) ->
                newAlert 'alert-error', "#{result}" if result isnt 'ok'
        evt.target.value = ""
}

Template.main.events okCancelEvents '#transaction-amount', {
    ok: (amount, evt) ->
        return if Number(amount) is 0

        client = $('.client-select :selected').val()
        symbol = $('.account-select :selected').val()
        comment = $('#transaction-comment').val()
        client_id = Clients.findOne({ symbol: client })?._id
        account_id = Assets.findOne({ client_id, symbol })?._id

        if account_id and amount
            Meteor.call 'executeTransaction', account_id, Number(amount), comment,
                (error, result) ->
                    newAlert 'alert-error', "#{result}" if result isnt 'ok'
            evt.target.value = ""
}

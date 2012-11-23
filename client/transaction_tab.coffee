_.extend Template.transactions_tab,

##
## Lists
#######################################

    # All client's accounts
    assets: ->
        client_id = Session.get 'client_id'

        if client_id
            Accounts.find { client_id }, { sort : { symbol: 1 } }

    transactions: ->
        client_id = Session.get 'client_id'
        
        if client_id
            Transactions.find({ client_id }, { sort: { date: -1 } })

Template.transactions_tab.events {

    'click #add_trans_on_trans_btn': (evt) ->
        amount = $('#transaction-amount').val()
        return if Number(amount) is 0

        client_id = Session.get 'client_id'
        symbol = $('.account-select :selected').val()
        comment = $('#transaction-comment').val()
        account_id = Accounts.findOne({ client_id, symbol })?._id

        if account_id and amount
            Meteor.call 'executeTransaction', account_id, Number(amount), comment,
                (error, result) ->
                    newAlert 'alert-error', "#{result}" if result isnt 'ok'
            $('#transaction-comment').val('')
            $('#transaction-amount').val('')

}

Template.transactions_tab.events okCancelEvents '#transaction-amount', {
    ok: (amount, evt) ->
        return if Number(amount) is 0

        client_id = Session.get 'client_id'
        symbol = $('.account-select :selected').val()
        comment = $('#transaction-comment').val()
        account_id = Accounts.findOne({ client_id, symbol })?._id

        if account_id and amount
            Meteor.call 'executeTransaction', account_id, Number(amount), comment,
                (error, result) ->
                    newAlert 'alert-error', "#{result}" if result isnt 'ok'
            evt.target.value = ""

}
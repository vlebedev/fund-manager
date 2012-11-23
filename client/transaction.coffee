_.extend Template.transaction,

    date: ->
        Date.create(@date).format("{yyyy}.{MM}.{dd} {HH}:{mm}:{ss}")

    client_symbol: ->
        Clients.findOne(@client_id).symbol

    account_symbol: ->
        Accounts.findOne(@account_id).symbol

    amount: ->
        accounting.formatNumber @amount, 2

    balance: ->
        accounting.formatNumber @balance, 2

    isOnTab: ->
        Session.get 'client_id'

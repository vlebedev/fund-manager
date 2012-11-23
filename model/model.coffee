## Accounts -- {
##    client_id: String
##    symbol: String
##    type: Boolean             # 's' - stock, 'm' - monetary, 'f' - fund
##    amount: Number
##    date_opened: Date
## }

Accounts = new Meteor.Collection 'accounts'

## Clients -- {
##     symbol: String
##     name: String
##     type: String                     # 'c' - client, 'f' - fund
##     date_registered: Date
## }

Clients = new Meteor.Collection 'clients'

## Instruments -- {
##     symbol: String
##     name: String
##     type: String                     # 's' - stock, 'm' - monetary, 'f' - fund, 'x' - fx
##     currency: String
##     lastTrade: Number
##     prevClose: Number
##     exchange: String
##
##     #stocks only
##     isUnlisted: Boolean              # true if instrument is unlisted stock
##
##     # funds only
##     shares: Number                   # number of shares issued
##     client_list: [client_id, ...]    # list of fund's clients
## }

Instruments = new Meteor.Collection 'instruments'

## Transactions -- {
##     date: Date
##     client_id: String
##     account_id: String
##     amount: Number
##     balance: Number
##     comment: String
## }

Transactions = new Meteor.Collection 'Transactions'

getFxRate = (symbol1, symbol2) ->
    fx = Instruments.findOne({ symbol: "#{symbol1}#{symbol2}=X" })

    if fx
        fx.lastTrade
    else
        1   # this is bloody kludge!

getAssetValueInUSD = (clientSymbol, symbol, amount) ->
    instrument = Instruments.findOne { symbol }

    return 0 unless instrument

    switch instrument.type
        when 's'

            return instrument.lastTrade * amount if instrument.currency is 'USD'

            conversionRate = getFxRate instrument.currency, 'USD'
            instrument.lastTrade * amount * conversionRate
        when 'm'

            return amount if instrument.symbol is 'USD'

            conversionRate = getFxRate instrument.symbol, 'USD'
            amount * conversionRate
        when 'f'

            return 0 if symbol is clientSymbol    # don't count fund's own shares

            instrument.lastTrade * amount

getClientTotalAssetsValue = (symbol) ->
    client = Clients.findOne { symbol }
    accounts = Accounts.find({ client_id: client._id }).fetch()
    total = 0

    for account in accounts
        total += getAssetValueInUSD client.symbol, account.symbol, account.amount

    total

getClientTotalNonMonetaryAssetsValue = (symbol) ->
    client = Clients.findOne { symbol }
    accounts = Accounts.find({ client_id: client._id }).fetch()
    total = 0

    for account in accounts
        if account.type isnt 'm'
            total += getAssetValueInUSD client.symbol, account.symbol, account.amount

    total

getQuotes = (symbols) ->

    if Meteor.isServer
        resp = Meteor.http.get "http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22#{symbols}%22)&format=json&env=store://datatables.org/alltableswithkeys"
        # console.log resp.content
        # console.log resp.statusCode

        if (resp.statusCode is 200) and (Number(resp.data?.query?.count) isnt 0)
            resp.data.query.results.quote
        else
            console.log resp.statusCode
            console.log resp.content
            null

Meteor.methods {

    'updateMarkets': ->

        if Meteor.isServer
            instruments = Instruments.find({}).fetch()
            symbols = _.pluck(_.filter(instruments, ((i) -> i.type isnt 'f' and i.type isnt 'm' and !i.isUnlisted)), 'symbol').join ', '

        quotes = getQuotes symbols

        if quotes

            for q in quotes

                if q.StockExchange is 'Micex'
                    type = 's'
                    currency = 'RUB'
                else if q.StockExchange isnt null
                    type = 's'
                    currency = 'USD'
                else
                    type = 'x'
                    currency = ''

                Instruments.update { symbol: q.symbol },        # have to shrink num of fields in $set
                    $set:   {
                        name:   q.Name,
                        type: type,
                        exchange: q.StockExchange,
                        currency: currency,
                        lastTrade: Number(q.LastTradePriceOnly),
                        prevClose: Number(q.PreviousClose)
                    }

            fund_instruments = Instruments.find({ type: 'f' }).fetch()
            
            for fund in fund_instruments
                assetsValue = getClientTotalAssetsValue fund.symbol
                shares = fund.shares
                if fund.shares is 0 
                    shares = 1
                Instruments.update fund._id, { $set: { lastTrade: assetsValue/shares } }

            undefined

    'addUnlistedStock': (symbol, name, currency, lastTrade) ->
        symbol = symbol.trim().toUpperCase()
        currency = currency.trim().toUpperCase()
        name = name.trim()

        return "Symbol <strong>#{symbol}</strong> already exists." if Instruments.find({ symbol }).count()

        Instruments.insert {
            symbol
            name
            type: 's'
            isUnlisted: yes
            exchange: ''
            currency
            lastTrade: Number(lastTrade)
            prevClose: 0
        }

        'ok'

    'updateUnlistedStockPrice': (symbol, lastTrade) ->
        symbol = symbol.trim().toUpperCase()
        instrument = Instruments.findOne({ symbol })

        return "Symbol <strong>#{symbol}</strong> does not exist." if !instrument
        
        prevClose = instrument.lastTrade
        Instruments.update { symbol }, {
            $set: { 
                lastTrade
                prevClose
            }
        }

        'ok'

    'addInstrument': (symbol, type) ->

        if Meteor.isServer
            symbol = symbol.trim().toUpperCase()
            len = symbol.length
            c1 = c2 = ''

            return "Wrong format for FX or currency symbol: <strong>#{symbol}</strong>." if (type is 'x') and !((len is 6) or (len is 3))

            if type is 'x' and len is 6
                c1 = symbol.slice(0,3)
                c2 = symbol.slice(3,6)
                symbol = symbol + "=X"

            return "Symbol <strong>#{symbol}</strong> already exists." if Instruments.find({ symbol }).count()

            if type is 'x' and len is 3
                Instruments.insert {
                    symbol: symbol
                    name:   symbol
                    type: 'm'
                    exchange: ''
                    currency: ''
                    lastTrade: 0
                    prevClose: 0
                }
                fx = symbol + 'USD=X'
                if Instruments.find({ symbol: fx }).count()
                    return 'ok'
                else
                    symbol = fx

            q = getQuotes symbol

            return "Symbol <strong>#{symbol}</strong> is not found in Yahoo! Finance database." if !q or q.ErrorIndicationreturnedforsymbolchangedinvalid

            if q.StockExchange is 'Micex'
                actualType = 's'
                currency = 'RUB'
            else if q.StockExchange isnt null
                actualType = 's'
                currency = 'USD'
            else
                actualType = 'x'
                currency = ''

            return "You cannot to add a stock <strong>#{symbol}</strong> to FX table." if actualType isnt type and type is 'x'

            return "You cannot to add an FX pair <strong>#{symbol}</strong> to Stocks table." if actualType isnt type and type is 's'

            Instruments.insert {
                    symbol: symbol
                    name:   q.Name
                    type: type
                    exchange: q.StockExchange
                    currency: currency
                    lastTrade: Number(q.LastTradePriceOnly)
                    prevClose: Number(q.PreviousClose)
            }
            if c1 and (c2 is 'USD')
                Instruments.insert {
                    symbol: c1
                    name:   c1
                    type: 'm'
                    exchange: ''
                    currency: ''
                    lastTrade: 0
                    prevClose: 0
                }
            'ok'

    'addClient': (symbol, name, type) ->
        symbol = symbol.trim().toUpperCase()

        Clients.insert {
            symbol
            name
            type
            date_registered: new Date()
        } unless alreadyExists = Clients.find({ symbol }).count()

        return "Client <strong>#{symbol}</strong> is already registered." if alreadyExists

        if type is 'f'
            Instruments.insert {
                symbol
                name
                type
                currency: ''
                lastTrade: ''
                prevClose: ''
                shares: 0
                client_list: []
            }

        'ok'

    'removeClient': (symbol) ->
        symbol = symbol.trim().toUpperCase()
        client = Clients.findOne({ symbol })

        return "Client <strong>#{symbol}</strong> is not registered." unless client

        return "Cannot delete client or fund <strong>#{symbol}</strong>, because it has active accounts." if Accounts.find({ client_id: client._id }).count()

        if client.type is 'f'
            return "Cannot delete fund <strong>#{symbol}</strong>, because it has active shares." if Instruments.findOne({ symbol }).shares
            return "Cannot delete fund <strong>#{symbol}</strong>, there is at least one client with account opened in #{symbol} shares." if Accounts.find({ symbol }).count()
            Instruments.remove { symbol }

        Clients.remove { symbol }

        'ok'

    'removeInstrument': (symbol) ->
        symbol = symbol.trim().toUpperCase()

        return "No such instrument <strong>#{symbol}</strong>." if !Instruments.find({ symbol }).count()

        return "Cannot delete instrument <strong>USD</strong>, because it is protected." if symbol is 'USD'

        switch Instruments.findOne({ symbol }).type 
            when 'x'
                c1 = symbol.slice(0,3)
                c2 = symbol.slice(3,6)
                if Accounts.find({ symbol : c1 }).count() and c2 is 'USD'
                    return "Cannot delete <strong>#{symbol}</strong> because there is at least one client's account opened in <strong>#{c1}</strong>."
                else
                    Instruments.remove { symbol: c1 }
            when 'm', 's'
                if Accounts.find({ symbol }).count()
                    return "Cannot delete <strong>#{symbol}</strong> because there is at least one client's account opened in <strong>#{symbol}</strong>."
            when 'f'
                return 'Cannot delete <strong>funds</strong> here.'

        Instruments.remove { symbol }
        'ok'

    'addAccount': (client_id, symbol) ->
        symbol = symbol.trim().toUpperCase()
        instrument = Instruments.findOne({ symbol })

        return "Cannot recursively add fund's <strong>#{symbol}</strong> account to the same fund." if Clients.findOne(client_id).symbol is symbol

        if instrument
            
            if Accounts.find({ client_id, symbol : instrument.symbol }).count()
                return "Cannot add <strong>#{symbol}</strong> account because it already exists."
            else
                Accounts.insert { client_id, symbol, type: instrument.type, amount: 0, date_registered: new Date() }

        else
            return "Cannot add <strong>#{symbol}</strong> account because there is no <strong>#{symbol}</strong> instrument registered in the system."

        'ok'

    'removeAccount': (account) ->
        transactionsCount = Transactions.find({ account_id: account._id }).count()
        return "Cannot remove <strong>#{account.symbol}</strong> account which is not empty." if account.amount isnt 0
        return "Cannot remove <strong>#{account.symbol}</strong> because it has <strong>#{transactionsCount}</strong> linked transaction(s)." if transactionsCount
        Accounts.remove account._id
        'ok'

    'executeTransaction': (account_id, amount, comment) ->
        account = Accounts.findOne account_id

        return "Account doesn't exist." unless account

        newBalance = account.amount + amount

        return "Amount of fund's shares cannot be negative." if account.type is 'f' and newBalance < 0

        Accounts.update account_id, $inc: { amount }

        if account.type is 'f'
            fundAssetsValue = getClientTotalAssetsValue account.symbol
            divider = fundNewTotalShares = Instruments.findOne({ symbol: account.symbol }).shares + amount
            
            if fundNewTotalShares is 0
                divider = 1

            console.log divider

            if newBalance > 0
                Instruments.update { symbol: account.symbol }, {
                    $set: { 
                        shares: fundNewTotalShares
                        lastTrade: fundAssetsValue/divider
                    }
                    $addToSet: { 
                        client_list: account.client_id 
                    }
                }
            else
                Instruments.update { symbol: account.symbol }, {
                    $set: { 
                        shares: fundNewTotalShares
                        lastTrade: fundAssetsValue/divider
                    }
                    $pull: { 
                        client_list: account.client_id 
                    }
                }

        Transactions.insert {
            date: new Date()
            client_id: account.client_id
            account_id
            amount
            balance: newBalance
            comment: comment.trim()
        }
        'ok'

    'rollbackTransaction': ->
        lastTransaction = Transactions.findOne {}, { sort: { date: -1 } }
        amount = lastTransaction.amount
        account_id = lastTransaction.account_id

        if lastTransaction
            account = Accounts.findOne account_id

            if account.type is 'f'
                fundAssetsValue = getClientTotalAssetsValue account.symbol
                fundNewTotalShares = Instruments.findOne({ symbol: account.symbol }).shares - amount

                if account.amount - amount > 0
                    Instruments.update { symbol: account.symbol }, {
                        $set: { 
                            shares: fundNewTotalShares
                            lastTrade: fundAssetsValue/(fundNewTotalShares is 0 ? 1 : fundTotalShares)
                        }
                        $addToSet: { client_list: account.client_id }
                    }
                else
                    Instruments.update { symbol: account.symbol }, {
                        $set: { 
                            shares: fundNewTotalShares 
                            lastTrade: fundAssetsValue/(fundNewTotalShares is 0 ? 1 : fundTotalShares) 
                        }
                        $pull: { 
                            client_list: account.client_id
                        }
                    }

            Accounts.update account_id, { $inc: { amount: -amount } }
            Transactions.remove lastTransaction._id

        'ok'
}
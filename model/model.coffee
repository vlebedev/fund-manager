## Assets -- {
##    client_id: String
##    symbol: String
##    type: Boolean             # 's' - stock, 'm' - monetary, 'f' - fund
##    amount: Number
##    date_opened: Date
## }

Assets = new Meteor.Collection 'assets'

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

Transactions = new Meteor.Collection 'transactions'

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
    
    if client
        assets = Assets.find({ client_id: client._id })?.fetch()
        total = 0

        if assets
            for asset in assets
                total += getAssetValueInUSD client.symbol, asset.symbol, asset.amount
            return total

    0

getClientTotalNonMonetaryAssetsValue = (symbol) ->
    client = Clients.findOne { symbol }
    assets = Assets.find({ client_id: client._id }).fetch()
    total = 0

    for asset in assets
        if account.type isnt 'm'
            total += getAssetValueInUSD client.symbol, asset.symbol, asset.amount

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
                        name:   q.Name
                        type: type
                        exchange: q.StockExchange
                        currency: currency
                        lastTrade: Number(q.LastTradePriceOnly)
                        prevClose: Number(q.PreviousClose)
                        timestamp: Date.utc.create().getTime()
                    }

            fund_instruments = Instruments.find({ type: 'f' }).fetch()
            
            for fund in fund_instruments
                assetsValue = getClientTotalAssetsValue fund.symbol
                shares = fund.shares
                if fund.shares is 0 
                    shares = 1
                Instruments.update fund._id, { $set: { lastTrade: assetsValue/shares, timestamp: Date.utc.create().getTime() } }

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
            timestamp: Date.utc.create().getTime()
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
                timestamp: Date.utc.create().getTime()
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
                    timestamp: Date.utc.create().getTime()
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
                    timestamp: Date.utc.create().getTime()
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
                    timestamp: Date.utc.create().getTime()
                }
            'ok'

    'addClient': (symbol, name, type, email, password) ->
        symbol = symbol.trim().toUpperCase()

        return "Client or fund <strong>#{symbol}</strong> is already registered." if Clients.find({ symbol }).count()

        if type is 'c'
            userId = Accounts.createUser {
                username: symbol.toLowerCase()
                email
                password
                profile: { name }
            }
            Clients.insert {
                symbol
                name
                type
                users: [userId]
                date_registered: new Date()
            } 
        else if type is 'f'
            Clients.insert {
                symbol
                name
                type
                users: []
                date_registered: new Date()
            } 
            Instruments.insert {
                symbol
                name
                type
                currency: ''
                lastTrade: ''
                prevClose: ''
                shares: 0
                client_list: []
                timestamp: Date.utc.create().getTime()
            }
        else 
            return "Unknown client type: '#{type}'."

        'ok'

    'removeClient': (symbol) ->
        symbol = symbol.trim().toUpperCase()
        client = Clients.findOne({ symbol })

        return "Client <strong>#{symbol}</strong> is not registered." unless client

        return "Cannot delete client or fund <strong>#{symbol}</strong>, because it has active accounts." if Assets.find({ client_id: client._id }).count()

        if client.type is 'f'
            return "Cannot delete fund <strong>#{symbol}</strong>, because it has active shares." if Instruments.findOne({ symbol }).shares
            return "Cannot delete fund <strong>#{symbol}</strong>, there is at least one client with account opened in #{symbol} shares." if Assets.find({ symbol }).count()
            Instruments.remove { symbol }

        if client.type is 'c'
            Meteor.users.remove { username: symbol.toLowerCase() }

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
                if Assets.find({ symbol : c1 }).count() and c2 is 'USD'
                    return "Cannot delete <strong>#{symbol}</strong> because there is at least one client's account opened in <strong>#{c1}</strong>."
                else
                    Instruments.remove { symbol: c1 }
            when 'm', 's'
                if Assets.find({ symbol }).count()
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
            
            if Assets.find({ client_id, symbol : instrument.symbol }).count()
                return "Cannot add <strong>#{symbol}</strong> account because it already exists."
            else
                Assets.insert { client_id, symbol, type: instrument.type, amount: 0, date_registered: new Date() }

        else
            return "Cannot add <strong>#{symbol}</strong> account because there is no <strong>#{symbol}</strong> instrument registered in the system."

        'ok'

    'removeAccount': (account) ->
        transactionsCount = Transactions.find({ account_id: account._id }).count()
        return "Cannot remove <strong>#{account.symbol}</strong> account which is not empty." if account.amount isnt 0
        return "Cannot remove <strong>#{account.symbol}</strong> because it has <strong>#{transactionsCount}</strong> linked transaction(s)." if transactionsCount
        Assets.remove account._id
        'ok'

    'executeTransaction': (account_id, amount, comment) ->
        account = Assets.findOne account_id

        return "Account doesn't exist." unless account

        newBalance = account.amount + amount

        return "Amount of fund's shares cannot be negative." if account.type is 'f' and newBalance < 0

        Assets.update account_id, $inc: { amount }

        if account.type is 'f'
            fundAssetsValue = getClientTotalAssetsValue account.symbol
            divider = fundNewTotalShares = Instruments.findOne({ symbol: account.symbol }).shares + amount
            userId = Meteor.users.findOne({ username: Clients.findOne(account.client_id)?.symbol.toLowerCase() })?._id

            if fundNewTotalShares is 0
                divider = 1

            if newBalance > 0
                Instruments.update { symbol: account.symbol }, {
                    $set: { 
                        shares: fundNewTotalShares
                        lastTrade: fundAssetsValue/divider
                        timestamp: Date.utc.create().getTime()
                    }
                    $addToSet: { 
                        client_list: account.client_id 
                    }
                }
                Clients.update { symbol: account.symbol }, {
                    $addToSet: { 
                        users: userId 
                    }
                }
            else
                Instruments.update { symbol: account.symbol }, {
                    $set: { 
                        shares: fundNewTotalShares
                        lastTrade: fundAssetsValue/divider
                        timestamp: Date.utc.create().getTime()
                    }
                    $pull: { 
                        client_list: account.client_id 
                    }
                }
                Clients.update { symbol: account.symbol }, {
                    $pull: { 
                        users: userId 
                    }
                }

        date = new Date()

        Transactions.insert {
            date
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
            account = Assets.findOne account_id

            if account.type is 'f'
                fundAssetsValue = getClientTotalAssetsValue account.symbol
                fundNewTotalShares = Instruments.findOne({ symbol: account.symbol }).shares - amount

                if account.amount - amount > 0
                    Instruments.update { symbol: account.symbol }, {
                        $set: { 
                            shares: fundNewTotalShares
                            lastTrade: fundAssetsValue/(fundNewTotalShares is 0 ? 1 : fundTotalShares)
                            timestamp: Date.utc.create().getTime()
                        }
                        $addToSet: { client_list: account.client_id }
                    }
                else
                    Instruments.update { symbol: account.symbol }, {
                        $set: { 
                            shares: fundNewTotalShares 
                            lastTrade: fundAssetsValue/(fundNewTotalShares is 0 ? 1 : fundTotalShares)
                            timestamp: Date.utc.create().getTime()
                        }
                        $pull: { 
                            client_list: account.client_id
                        }
                    }

            Assets.update account_id, { $inc: { amount: -amount } }
            Transactions.remove lastTransaction._id

        'ok'

    'flushDatabase': ->
        Assets.remove({})
        Clients.remove({})
        Instruments.remove({})
        Transactions.remove({})
        Meteor.users.remove({})
        Accounts.createUser {
            username: "dev"
            email: "dev@mail.xox"
            password: "1234"
            profile: { name: "John Doe" }
        } 
        Accounts.createUser {
            username: "admin"
            email: "admin@mail.xox"
            password: "1234"
            profile: { name: "John Doe II" }
        } 
        Instruments.insert { symbol: 'USD', name: '', type: 'm', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
        Instruments.insert { symbol: 'RUB', name: '', type: 'm', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
        Instruments.insert { symbol: 'USDRUB=X', name: '', type: 'x', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
        Instruments.insert { symbol: 'RUBUSD=X', name: '', type: 'x', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
        Instruments.insert { symbol: 'LKOH.ME', name: '', type: 's', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
        Instruments.insert { symbol: 'SNGS.ME', name: '', type: 's', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
        Instruments.insert { symbol: 'VIP', name: '', type: 's', lastTrade: 0.0, prevClose: 0.0, exchange: '', timestamp: Date.utc.create().getTime() }
}

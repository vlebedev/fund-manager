Meteor.startup ->
    # Accounts.remove {}
    # Clients.remove {}
    # Instruments.remove {}
    # Transactions.remove {}

    unless Clients.find({}).count()
        c1 = Clients.insert
            symbol: 'C001'
            name: 'Mikhail Ivanovich'
            type: 'c'
            date_registered: new Date()
        c2 = Clients.insert
            symbol: 'C002'
            name: 'Petr Ibragimovich'
            type: 'c'
            date_registered: new Date()
        f1 = Clients.insert
            symbol: 'F001'
            name: 'Friends closed fund'
            type: 'f'
            date_registered: new Date()

        Instruments.insert { symbol: 'USD', name: '', type: 'm', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        Instruments.insert { symbol: 'RUB', name: '', type: 'm', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        Instruments.insert { symbol: 'USDRUB=X', name: '', type: 'x', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        Instruments.insert { symbol: 'RUBUSD=X', name: '', type: 'x', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        Instruments.insert { symbol: 'LKOH.ME', name: '', type: 's', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        Instruments.insert { symbol: 'SNGS.ME', name: '', type: 's', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        Instruments.insert { symbol: 'VIP', name: '', type: 's', lastTrade: 0.0, prevClose: 0.0, exchange: '' }
        
        Instruments.insert { 
            symbol: 'F001'
            name: 'Friends closed fund'
            type: 'f'
            lastTrade: 0.0
            prevClose: 0.0
            exchange: ''             
            shares: 0
            client_list: []
        }

        Accounts.insert { client_id: c1, symbol: 'USD', type: 'm', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: c2, symbol: 'USD', type: 'm', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: f1, symbol: 'USD', type: 'm', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: c1, symbol: 'RUB', type: 'm', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: c2, symbol: 'RUB', type: 'm', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: f1, symbol: 'RUB', type: 'm', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: c1, symbol: 'LKOH.ME', type: 's', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: c1, symbol: 'F001', type: 'f', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: c2, symbol: 'VIP', type: 's', amount: 0, date_registered: new Date() }
        Accounts.insert { client_id: f1, symbol: 'SNGS.ME', type: 's', amount: 0, date_registered: new Date() }

    sleep = (ms) -> 
        fiber = Fiber.current;
        setTimeout (-> fiber.run()), ms
        Fiber.yield()

    updater = ->
        loop
            Meteor.call 'updateMarkets'
            sleep 60000
        undefined

    Fiber(updater).run()


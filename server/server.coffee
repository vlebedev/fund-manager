Meteor.publish 'instruments', ->
    Instruments.find()

Meteor.publish 'clients', ->

    if Meteor.users.findOne(@userId)?.username in ['admin', 'dev']
        Clients.find()
    else
        count = Clients.find({ users: { $all: [ @userId ] } }).count()
        TL.verbose "#{count} clients matched", "PUBLISH_ASSETS"
        Clients.find { users: { $all: [ @userId ] } }

Meteor.publish 'assets', ->

    if Meteor.users.findOne(@userId)?.username in ['admin', 'dev']
        Assets.find()
    else
        clientIds = _.pluck Clients.find({ users: { $all: [ @userId ] } }).fetch(), '_id'
        if clientIds
            count = Assets.find({ client_id: { $in: clientIds } }).count()
            TL.verbose "#{clientIds}, #{_.isArray(clientIds)}, #{count} assets", "PUBLISH_ASSETS"
            Assets.find { client_id: { $in: clientIds } }
        else
            null

Meteor.publish 'transactions', ->
    if Meteor.users.findOne(@userId)?.username in ['admin', 'dev']
        Transactions.find()
    else
        clientIds = _.pluck Clients.find({ users: { $all: [ @userId ] } }).fetch(), '_id'
        if clientIds
            Transactions.find { client_id: { $in: clientIds } }

Meteor.publish 'price_changes', ->
    self = @
    uids = []

    handle = Instruments.find({}).observe {

        added: (doc, idx) ->

        changed: (newDoc, idx, oldDoc) ->

            color = ''

            if newDoc.lastTrade > oldDoc.lastTrade
                color = 'success'
            else if newDoc.lastTrade < oldDoc.lastTrade
                color = 'error'

            # TL.verbose "price_change #{newDoc.symbol} #{oldDoc.lastTrade} #{newDoc.lastTrade} #{color}", "PUBLISH_PRICE_CHANGES"
            uids.push newDoc._id unless newDoc._id in uids
            self.set 'price_changes', newDoc._id, { color }
            self.flush()

        moved: (doc, oldIdx, newIdx) ->

        removed: (doc, oldIdx) ->

    }

    self.complete()
    self.flush()

    self.onStop ->
        handle.stop()

        for uid in uids
            self.unset 'price_changes', uid, ['color']

        self.flush()


Meteor.startup ->

    #Assets.remove()
    #Clients.remove()
    #Instruments.remove()
    #Transactions.remove()
    #Meteor.users.remove()

    Accounts.createUser {
        username: "dev"
        email: "dev@mail.com"
        password: "1234"
        profile: { name: "John Doe" }
    } unless Meteor.users.findOne { username: "dev" }

    Accounts.createUser {
        username: "admin"
        email: "admin@mail.com"
        password: "1234"
        profile: { name: "John Doe II" }
    } unless Meteor.users.findOne { username: "admin" }

    c001_id = Meteor.users.findOne({ username: "c001" })?._id

    c001_id = Accounts.createUser {
        username: "c001"
        email: "c001@mail.com"
        password: "1234"
        profile: { name: "Client 001" }
    } unless c001_id

    unless Clients.find({}).count()
        c1 = Clients.insert
            symbol: 'C001'
            name: 'Mikhail Ivanovich'
            type: 'c'
            users: [c001_id]
            date_registered: new Date()
        c2 = Clients.insert
            symbol: 'C002'
            name: 'Petr Ibragimovich'
            type: 'c'
            users: []
            date_registered: new Date()
        f1 = Clients.insert
            symbol: 'F001'
            name: 'Friends closed fund'
            type: 'f'
            users: [c001_id]
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
            client_list: [c1]
        }

        Assets.insert { client_id: c1, symbol: 'USD', type: 'm', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: c2, symbol: 'USD', type: 'm', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: f1, symbol: 'USD', type: 'm', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: c1, symbol: 'RUB', type: 'm', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: c2, symbol: 'RUB', type: 'm', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: f1, symbol: 'RUB', type: 'm', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: c1, symbol: 'LKOH.ME', type: 's', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: c1, symbol: 'F001', type: 'f', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: c2, symbol: 'VIP', type: 's', amount: 0, date_registered: new Date() }
        Assets.insert { client_id: f1, symbol: 'SNGS.ME', type: 's', amount: 0, date_registered: new Date() }

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


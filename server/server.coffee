Meteor.publish 'instruments', ->

    return null unless @userId

    Instruments.find()

Meteor.publish 'clients', ->

    return null unless @userId

    if Meteor.users.findOne(@userId)?.username in ['admin', 'dev']
        Clients.find()
    else
        count = Clients.find({ users: { $all: [ @userId ] } }).count()
        Clients.find { users: { $all: [ @userId ] } }

Meteor.publish 'assets', ->

    return null unless @userId

    if Meteor.users.findOne(@userId)?.username in ['admin', 'dev']
        Assets.find()
    else
        clientIds = _.pluck Clients.find({ users: { $all: [ @userId ] } }).fetch(), '_id'
        if clientIds
            count = Assets.find({ client_id: { $in: clientIds } }).count()
            Assets.find { client_id: { $in: clientIds } }
        else
            null

Meteor.publish 'transactions', ->

    return null unless @userId

    if Meteor.users.findOne(@userId)?.username in ['admin', 'dev']
        Transactions.find()
    else
        clientIds = _.pluck Clients.find({ users: { $all: [ @userId ] } }).fetch(), '_id'
        if clientIds
            Transactions.find { client_id: { $in: clientIds } }

Meteor.publish 'price_changes', ->
    self = @
    uids = []

    return null unless @userId

    handle = Instruments.find({}).observe {

        added: (doc, idx) ->

        changed: (newDoc, idx, oldDoc) ->

            color = ''

            if newDoc.lastTrade > oldDoc.lastTrade
                color = 'success'
            else if newDoc.lastTrade < oldDoc.lastTrade
                color = 'error'

            uids.push newDoc._id unless newDoc._id in uids
            time = Date.now()
            self.set 'price_changes', newDoc._id, { color, time }
            self.flush()

        moved: (doc, oldIdx, newIdx) ->

        removed: (doc, oldIdx) ->

    }

    self.complete()
    self.flush()

    self.onStop ->
        handle.stop()

        for uid in uids
            self.unset 'price_changes', uid, ['color', 'time']

        self.flush()


Meteor.startup ->

    rootUrl = process.env.ROOT_URL 
    console.log "Using mongodb instance at #{process.env.MONGO_URL}"

    if rootUrl isnt 'http://localhost:3000'
        # running on Heroku
        console.log 'Starting up on Heroku'
    else 
        # running on localhost
        console.log 'Starting up locally'

    Accounts.createUser {
        username: "dev"
        email: "dev@mail.xox"
        password: "1234"
        profile: { name: "John Doe" }
    } unless Meteor.users.findOne { username: "dev" }

    Accounts.createUser {
        username: "admin"
        email: "admin@mail.xox"
        password: "1234"
        profile: { name: "John Doe II" }
    } unless Meteor.users.findOne { username: "admin" }

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


_.extend Template.assets_tab,

##
## Computed fields and field formatters
#######################################

    total_assets: ->
        client_id = Session.get 'client_id'
        client = Clients.findOne client_id
        # TL.verbose "client_id: #{client?._id} #{client?.symbol}", "ASSETS_TAB"
        accounting.formatNumber getClientTotalAssetsValue(client.symbol), 2 if client

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']

##
## Lists
#######################################

    # All client's Assets
    assets: ->
        client_id = Session.get 'client_id'

        if client_id
            Assets.find { client_id }, { sort : { symbol: 1 } }

    # Only monetary Assets
    monetary_assets: ->
        client_id = Session.get 'client_id'

        if client_id
            Assets.find { client_id, type: 'm' }, { sort : { symbol: 1 } }

    # Only stock Assets
    stock_assets: ->
        client_id = Session.get 'client_id'

        if client_id
            Assets.find { client_id, type: 's' }, { sort : { symbol: 1 } }

    # Only fund Assets
    fund_assets: ->
        client_id = Session.get 'client_id'

        if client_id
            Assets.find { client_id, type: 'f' }, { sort : { symbol: 1 } }

Template.assets_tab.events {

    'click #add-fund-account-btn': ->
        client_id = Session.get 'client_id'
        symbol = $('#fund-account-symbol').val().trim().toUpperCase()

        return unless symbol

        Meteor.call 'addAccount', client_id, symbol,
            (error, result) ->
                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}", '#fund-error-alert'
                else
                    $('#fund-account-symbol').val('')

    'click #add-stock-account-btn': ->
        client_id = Session.get 'client_id'
        symbol = $('#stock-account-symbol').val().trim().toUpperCase()

        return unless symbol

        Meteor.call 'addAccount', client_id, symbol,
            (error, result) ->
                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}", '#stock-error-alert'
                else
                    $('#stock-account-symbol').val('')

    'click #add-monetary-account-btn': ->
        client_id = Session.get 'client_id'
        symbol = $('#monetary-account-symbol').val().trim().toUpperCase()

        return unless symbol

        Meteor.call 'addAccount', client_id, symbol,
            (error, result) ->
                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}", '#monetary-error-alert'
                else
                    $('#monetary-account-symbol').val('')
}

Template.assets_tab.events okCancelEvents '#fund-account-symbol', {

    ok: (symbol, evt) ->
        client_id = Session.get 'client_id'

        Meteor.call 'addAccount', client_id, symbol,
            (error, result) ->
                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}", '#fund-error-alert'
                else
                    evt.target.value = ""
}

Template.assets_tab.events okCancelEvents '#stock-account-symbol', {

    ok: (symbol, evt) ->
        client_id = Session.get 'client_id'

        Meteor.call 'addAccount', client_id, symbol,
            (error, result) ->

                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}", '#stock-error-alert'
                else
                    evt.target.value = ""
}

Template.assets_tab.events okCancelEvents '#monetary-account-symbol', {

    ok: (symbol, evt) ->
        client_id = Session.get 'client_id'

        Meteor.call 'addAccount', client_id, symbol,
            (error, result) ->

                if result isnt 'ok'
                    newAlert 'alert-error', "#{result}", '#monetary-error-alert'
                else
                    evt.target.value = ""
}


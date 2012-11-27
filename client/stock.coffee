_.extend Template.stock,

##
## Computed fields and field formatters
#######################################


    color: ->
        Changes.findOne(@_id)?.color

    lastTrade: ->
        @lastTrade.format(4)

    prevClose: ->
        @prevClose.format(4)

    stock_class: ->
        if @isUnlisted then 'unlisted' else ''

    editing: ->
        stock_id = Session.get 'editing_stock_id'
        if @_id is stock_id then 'yes' else null

    enable_tooltips: ->
        _.defer (-> $('[rel=tooltip]').tooltip()), ''

    isAdmin: ->
        Meteor.users.findOne(Meteor.user())?.username in ['admin', 'dev']


##
## Template event handlers
#######################################

Template.stock.events {

    'dblclick .unlisted': (evt, tmpl) ->                # start editing unlisted stock last trade price
        Session.set 'editing_stock_id', @_id
        Meteor.flush()                                  # force DOM redraw, so we can focus the edit field
        activateInput tmpl.find('.last-trade-input')

    'click #remove-stock': (evt) ->
        Meteor.call 'removeInstrument', @symbol,
            (error, result) ->
                newAlert 'alert-error', "#{result}" if result isnt 'ok'
}

Template.stock.events okCancelEventsFull '.last-trade-input', {

    ok: (lastTrade, evt) ->

        if !isNaN(parseFloat(lastTrade)) && isFinite(lastTrade)
            Meteor.call 'updateUnlistedStockPrice', @symbol, lastTrade,
                (error, result) ->
                    if result isnt 'ok'
                        newAlert 'alert-error', "#{result}"
                    else
                        evt.target.value = ""
                        Session.set 'editing_stock_id', null
        else
            newAlert 'alert-error', "Please enter valid stock price. Example: <strong>123.56</strong>"
}

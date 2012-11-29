_.extend Template.fund,

##
## Computed fields and field formatters
#######################################

    color: ->
        change = Changes.findOne(@_id)
        if change
            if (Date.now()-change.time) >= 60000
                ''
            else
                change.color
        else
            ''

    shares: ->
        @shares.format(2)

    assets: ->
        (@shares*@lastTrade).format(2)

    lastTrade: ->
        @lastTrade.format(2)

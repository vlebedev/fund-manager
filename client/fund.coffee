_.extend Template.fund,

##
## Computed fields and field formatters
#######################################

    color: ->
        Changes.findOne(@_id)?.color

    shares: ->
        @shares.format(2)

    assets: ->
        (@shares*@lastTrade).format(2)

    lastTrade: ->
        @lastTrade.format(2)

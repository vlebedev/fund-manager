_.extend Template.fund,

##
## Computed fields and field formatters
#######################################

    color: ->
        Changes.findOne(@_id)?.color

    shares: ->
        accounting.formatNumber @shares, 2

    assets: ->
        accounting.formatNumber @shares*@lastTrade, 2

    lastTrade: ->
        accounting.formatNumber @lastTrade, 2

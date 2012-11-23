_.extend Template.fund,

##
## Computed fields and field formatters
#######################################

    shares: ->
        accounting.formatNumber @shares, 2

    assets: ->
        accounting.formatNumber getClientTotalAssetsValue(@symbol), 2

    lastTrade: ->
        accounting.formatNumber @lastTrade, 2

Template.navbar.events {
    
    'click .logout': ->
        user = Meteor.users.findOne Meteor.user()
        TL.info "User logged out: #{user.username}"
        Meteor.logout()
}
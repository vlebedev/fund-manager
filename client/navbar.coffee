Template.navbar.events {
    
    'click .logout': ->
        user = Meteor.users.findOne Meteor.user()
        Meteor.logout()
}
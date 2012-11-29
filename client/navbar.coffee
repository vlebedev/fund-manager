Template.navbar.events {
    
    'click .logout': ->
        user = Meteor.users.findOne Meteor.user()
        Meteor.logout()

    'click #change-password-btn': ->
        oldPassword = $('#old-password').val().trim()
        newPassword = $('#new-password').val().trim()
        newPasswordAgain = $('#new-password-again').val().trim()
        console.log "#{oldPassword}, #{newPassword}"

        if newPassword isnt newPasswordAgain
            newAlert 'alert-error', "New password don't match, try again", '#change-password-alert-area'
            return

        Accounts.changePassword oldPassword, newPassword, 
            (error) ->
                if arguments.length
                    newAlert 'alert-error', "Old password is wrong, try again", '#change-password-alert-area'
                else
                    $('#changePasswordModal').modal('hide')
}

class ContactMailer < ApplicationMailer
    default from: 'no-reply@wiperstoyou.com'

    def contact_request
        form = params[:form]
        @name = form.name
        email = form.email
        @message = form.message
        mail(
            from: email,
            to: 'jeff@wiperstoyou.com',
            subject: 'Contact Request'
        )
    end
end

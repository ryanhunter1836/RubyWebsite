class StaticPagesController < ApplicationController

  def home
    #Take the user straight to their account if logged in
    # if logged_in?
    #   redirect_to user_path(:id => current_user.id)
    # else
    #   render 'home'
    # end
  end
  
  #Contact form submission
  def create
    message = ContactForm.new(contact_params)
    if message.valid?
      #Send email
      ContactMailer.with(form: message).contact_request.deliver_now
      redirect_to '/message-confirmation'
    else
      #Rerender the page
    end
      
  end

  def message_confirmation
  end
  
  def contact
    @contact_form = ContactForm.new
  end

  def overview
  end

  def faq
  end

  def about
  end

  def javascript
    render 'shared/javascript_warning'
  end

  private
    def contact_params
      params.require(:contact_form).permit(:name, :email, :message)
    end
end

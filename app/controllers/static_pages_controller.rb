class StaticPagesController < ApplicationController

  def home
    #Take the user straight to their account if logged in
    if logged_in?
      redirect_to user_path(:id => current_user.id)
    else
      render 'home'
    end
  end
  
  def help
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
end

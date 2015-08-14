class SessionsController < ApplicationController
  def new
    redirect_to "/auth/#{ENV['AUTH_MECHANISIM']}"
  end

  def create
    unless org_name.empty?
      # Check that this user is a member of the Github organization.
      client = Octokit::Client.new access_token: auth_hash['credentials']['token']
      unless client.org_member?(org_name, client.user.login)
        flash[:error] = "Authentication error: you are not a member of the #{org_name}."
        redirect_to root_url
      end
    end

    user = User.find_or_create_from_omniauth(auth_hash)
    if user.valid?
      session[:user_id] = user.id
      redirect_to root_url, notice: "Signed in!"
    else
      flash[:error] = "You need a #{ENV.fetch('ORIENTATION_DOMAIN')} account to sign in."
      redirect_to root_url
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, notice: "Signed out!"
  end

  protected

  def auth_hash
    # calling to_h because Strong Parameters don't allow direct access
    # to request parameters, even when passed to a class outside the
    # controller scope.
    request.env['omniauth.auth'].to_h
  end

  def org_name
    ENV['GITHUB_ORG_NAME']
  end
end

class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: [:pay]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def pay
    
    data = JSON.parse(request.body.read.to_s)
    begin
      if data['payment_method_id']
        # Create the PaymentIntent
        intent = Stripe::PaymentIntent.create(
          payment_method: data['payment_method_id'],
          amount: 1099,
          currency: 'usd',
          confirmation_method: 'manual',
          confirm: true,
        )
      elsif data['payment_intent_id']
        intent = Stripe::PaymentIntent.confirm(data['payment_intent_id'])
      end
    rescue Stripe::CardError => e
      # Display error on client
      return [200, { error: e.message }.to_json]
    end

    return generate_response(intent)
  end

  def generate_response(intent)
    # Note that if your API version is before 2019-02-11, 'requires_action'
    # appears as 'requires_source_action'.
    if intent.status == 'requires_action' &&
        intent.next_action.type == 'use_stripe_sdk'
      # Tell the client to handle the action
      [
        200,
        {
          requires_action: true,
          payment_intent_client_secret: intent.client_secret
        }.to_json
      ]
    elsif intent.status == 'succeeded'
      # The payment didn’t need any additional actions and is completed!
      # Handle post-payment fulfillment
      [200, { success: true }.to_json]
    else
      # Invalid status
      return [500, { error: 'Invalid PaymentIntent status' }.to_json]
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:email)
    end
end

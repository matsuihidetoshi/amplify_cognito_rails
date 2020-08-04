class VerificationService < ApplicationService
  attr_accessor :provider

  def initialize(provider)
    @provider = provider
  end

  def verify(token)
    @provider.verify(token)
  end
end
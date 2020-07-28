require "net/http"
require "json"

class AuthenticationService < ApplicationService
  def authenticate
    cognitotest_region = ENV['COGNITOTEST_REGION']
    cognitotest_userpool_id = ENV['COGNITOTEST_USERPOOL_ID']
    cognitotest_app_client_id = ENV['COGNITOTEST_APP_CLIENT_ID']

    uri = URI.parse(
        "https://cognito-idp." +
        cognitotest_region +
        ".amazonaws.com/" +
        cognitotest_userpool_id +
        "/.well-known/jwks.json"
      )

    response = JSON.load(Net::HTTP.get(uri))
    keys = response["keys"]

    return keys
  end
end
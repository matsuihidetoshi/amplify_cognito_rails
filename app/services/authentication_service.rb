class AuthenticationService < ApplicationService
  require "net/http"
  require "json"
  require "jwt"

  def authenticate(token)
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

    decoded_token = JWT.decode token, nil, false
    token_kid = decoded_token[1]["kid"]

    matched_key = keys.find { |key| key["kid"] == token_kid}

    public_key = JSON::JWK.new(matched_key).to_key

    return matched_key
  end
end
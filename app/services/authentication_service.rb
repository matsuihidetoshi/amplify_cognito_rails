class AuthenticationService < ApplicationService
  require "net/http"
  require "json"
  require "jwt"
  require "json/jwt"

  def authenticate(token)
    # Cognito User Poolアクセス先を環境変数から取得
    cognitotest_region = ENV['COGNITOTEST_REGION']
    cognitotest_userpool_id = ENV['COGNITOTEST_USERPOOL_ID']
    cognitotest_app_client_id = ENV['COGNITOTEST_APP_CLIENT_ID']

    # Cognito User Poolアクセス先URL作成
    uri = URI.parse(
      "https://cognito-idp." +
      cognitotest_region +
      ".amazonaws.com/" +
      cognitotest_userpool_id +
      "/.well-known/jwks.json"
    )

    # Cognitoからのレスポンスから、キーのセットを取得
    response = JSON.load(Net::HTTP.get(uri))
    keys = response["keys"]

    # パラメータ（ここでは引数）として受け取ったトークンをデコードして、kidを取得
    begin
      decoded_token = JWT.decode token, nil, false
    rescue
      # トークンの形式がおかしくてエラーだったらfalse
      return false
    end
    token_kid = decoded_token[1]["kid"]

    # kidがパラメータで受け取ったトークンと一致するキーを取得
    matched_key = keys.find { |key| key["kid"] == token_kid}

    # 一致するキーがちゃんとある
    if matched_key
      # 一致したキーから公開鍵を作成
      public_key = JSON::JWK.new(matched_key).to_key

      begin
        # 公開鍵でトークンをデコードできたらtrue
        JSON::JWT.decode(token, public_key)
        return true
      rescue
        # できなくてエラーだったらfalse
        return false
      end
    else
      # 一致するキーがなければfalse
      return false
    end
  end
end
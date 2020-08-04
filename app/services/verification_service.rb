class VerificationService < ApplicationService
  require "net/http"
  require "json"
  require "jwt"
  require "json/jwt"

  attr_accessor :verified, :result

  def initialize(token)
    # 検証ステータスはデフォルトでfalse
    @verified = false
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
    token_kid = nil
    begin
      decoded_token = JWT.decode token, nil, false
      claims = decoded_token[0]
      token_kid = decoded_token[1]["kid"]
    rescue
      # トークンの形式がおかしくてエラーだったらfalse
      @result =  "invalid token"
    end

    # kidがパラメータで受け取ったトークンと一致するキーを取得
    matched_key = keys.find { |key| key["kid"] == token_kid}

    # 一致するキーがちゃんとある
    if matched_key
      # 一致したキーから公開鍵を作成
      public_key = JSON::JWK.new(matched_key).to_key

      begin
        # 公開鍵でトークンをデコードできたらtrue
        JSON::JWT.decode(token, public_key)

        # トークンの期限切れ検証
        if (claims["exp"] < Time.now.to_i)
          @result = "token expired"
        # トークンのクライアントid検証
        elsif (claims["aud"] != cognitotest_app_client_id)
          @result = "wrong audience"
        else
          @verified = true
          @result = claims
        end
      rescue
        # できなくてエラーだったらfalse
        @result = "failed to decode token"
      end
    else
      # 一致するキーがなければfalse
      @result = "no kid matched"
    end
  end
end
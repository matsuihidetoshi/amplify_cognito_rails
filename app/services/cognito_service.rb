class CognitoService < ApplicationService
  require "net/http"
  require "json"
  require "jwt"
  require "json/jwt"

  attr_accessor :region, :userpool_id, :app_client_id, :uri, :result
  
  def initialize(region, userpool_id, app_client_id)
    @region = region
    @userpool_id = userpool_id
    @app_client_id = app_client_id

    # Cognito User Poolアクセス先URL作成
    @uri = URI.parse(
      "https://cognito-idp." +
      @region +
      ".amazonaws.com/" +
      @userpool_id +
      "/.well-known/jwks.json"
    )

    @result = {verified: false, detail: nil}
  end
  
  def verify(token)
    # Cognitoからのレスポンスから、キーのセットを取得
    response = JSON.load(Net::HTTP.get(@uri))
    keys = response["keys"]

    # パラメータ（ここでは引数）として受け取ったトークンをデコードして、kidを取得
    begin
      decoded_token = JWT.decode token, nil, false
      claims = decoded_token[0]
      token_kid = decoded_token[1]["kid"]
    rescue
      # トークンの形式がおかしくてエラー
      @result[:detail] = "invalid token"
    end

    # kidがパラメータで受け取ったトークンと一致するキーを取得
    matched_key = keys.find { |key| key["kid"] == token_kid}

    # 一致するキーがちゃんとある
    if matched_key
      begin
        # 一致したキーから公開鍵を作成
        public_key = JSON::JWK.new(matched_key).to_key
        
        # 公開鍵でトークンをデコードできたらtrue
        JSON::JWT.decode(token, public_key)

        # トークンの期限切れ検証
        if (claims["exp"] < Time.now.to_i)
          @result[:detail] = "token expired"
        # トークンのクライアントid検証
        elsif (claims["aud"] != @app_client_id)
          @result[:detail] = "wrong audience"
        else
          @result = {verified: true, detail: claims}
        end
      rescue => e
        # できなくてエラー
        @result[:detail] = e
      end
    else
      # 一致するキーがなくてエラー
      @result[:detail] = "no kid matched"
    end

    return @result
  end
end
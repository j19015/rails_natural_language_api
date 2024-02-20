require 'json'
require 'net/https'

class Task < ApplicationRecord
  after_save :assign_tags

  private

  def assign_tags
    # APIのURL作成
    api_url = "https://language.googleapis.com/v1/documents:analyzeEntities?key=#{ENV['GOOGLE_CLOUD_API_KEY']}"

    # APIリクエスト用のJSONパラメータ
    params = {
      document: {
        type: 'PLAIN_TEXT',
        content: self.description
      },
      encodingType: 'UTF8'
    }.to_json

    # Google Cloud Natural Language APIにリクエスト
    uri = URI.parse(api_url)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    response = https.request(request, params)
    response_body = JSON.parse(response.body)

    # APIレスポンス出力
    if (error = response_body['error']).present?
      raise error['message']
    else
      update_columns(tags: response_body['entities'].map { |entity| entity['name'] }.join(', '))
    end
  end
end

require "graphql/client"
require "graphql/client/http"
require "faraday"

module GitHubChangelogGenerator
  module GitHubGraphqlApi
    ENDPOINT = "https://api.github.com/graphql"

    HTTP = GraphQL::Client::HTTP.new(ENDPOINT) do
      def headers(_context)
        { "Authorization" => "Bearer #{ENV['CHANGELOG_GITHUB_TOKEN']}" }
      end
    end

    # Maintained by a task in Rakefile
    STORED_SCHEMA_PATH = File.expand_path("../graphql/schema.json", __FILE__)
    Schema = GraphQL::Client.load_schema(STORED_SCHEMA_PATH)

    Client = GraphQL::Client.new(schema: Schema, execute: HTTP)

    RepositoryWithIssuesQuery = GitHubGraphqlApi::Client.parse <<-'GRAPHQL'
      query {
        repository(owner:"octocat", name:"Hello-World") {
          issues(last:20, states:CLOSED) {
            edges {
              node {
                title
                url
                labels(first:5) {
                  edges {
                    node {
                      name
                    }
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  class GraphqlFetcher
    def initialize(options = {})
      @options = options || {}
    end

    def call
      _result = GitHubGraphqlApi::Client.query(GitHubGraphqlApi::RepositoryWithIssuesQuery)

      # The raw data is Hash of JSON values
      # _result["data"]["luke"]["homePlanet"]

      # The wrapped result allows to you access data with Ruby methods
      # _result.data.luke.homePlanet
    end
  end
end

require "spec_helper"
require "rack/test"
require "chartboost"

describe "chartboost" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  describe "/notify" do
    it "responds ok" do
      get '/notify'
      assert last_response.ok?
    end

    describe "saving" do
      before do
        @repo = Minitest::Mock.new
        app.set(:repository, @repo)
      end

      it "doesn't save the params" do
        get '/notify?plop=plip'
        assert @repo.verify
      end

      it "saves the params ('ifa' as id)" do
        @repo.expect :save, nil, ["42", {"ifa" => "42", "plop" => "plip"}]
        get '/notify?plop=plip&ifa=42'
        assert @repo.verify
      end

      it "saves the params ('uuid' as id)" do
        @repo.expect :save, nil, ["42", {"uuid" => "42", "plop" => "plip"}]
        get '/notify?plop=plip&uuid=42'
        assert @repo.verify
      end
    end
  end

  describe "/fetch" do
    it "responds not found with no id" do
      get '/fetch'
      assert last_response.not_found?
    end

    describe "fetching" do
      before do
        @repo = Minitest::Mock.new
        app.set(:repository, @repo)
      end

      it "responds not found with an unknown id" do
        @repo.expect :fetch, nil, ["42"]
        get '/fetch?id=42'
        assert last_response.not_found?
        assert @repo.verify
      end

      it "responds the JSON with a matching id" do
        json = '{"workgin":true}'
        @repo.expect :fetch, json, ["42"]
        get '/fetch?id=42'
        assert last_response.ok?
        last_response.body.must_equal json
        assert @repo.verify
      end
    end
  end

  describe "GET /all" do
    before do
      @repo = Minitest::Mock.new
      app.set(:repository, @repo)
    end

    it "responds ok and an empty array" do
      @repo.expect :all, []
      get '/all'
      assert last_response.ok?
      assert last_response.body = '[]'
    end

    it "responds all logs" do
      @repo.expect :all, ['{"workgin":true}', '{"workgin":false}']
      get '/all'
      assert last_response.ok?
      assert last_response.body = '[{"workgin":true},{"workgin":false}]'
    end
  end

  describe "DELETE /all" do
    before do
      @repo = Minitest::Mock.new
      app.set(:repository, @repo)
    end

    it "reset the repository" do
      @repo.expect :reset, []
      delete '/all'
      assert last_response.ok?
    end
  end
end
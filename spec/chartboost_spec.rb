require "spec_helper"
require "rack/test"
require "chartboost"

describe "chartboost" do
  include Rack::Test::Methods

  let(:redis_url) { ENV["REDISTOGO_URL"] || "redis://localhost:6379" }
  let(:redis) { Redis.new(url: redis_url, driver: :hiredis) }
  let(:repo) { Repository.new(redis) }

  before { repo.reset }
  after { repo.reset }

  def app
    app = Sinatra::Application
    app.set(:repository, repo)
  end

  describe "/notify" do
    it "responds ok" do
      get '/notify'
      assert last_response.ok?
    end

    describe "saving" do
      it "saves the params (no id)" do
        get '/notify?plop=plip'
        assert !repo.all.empty?
      end

      it "saves the params ('ifa' as id)" do
        get '/notify?plop=plip&ifa=42'
        assert !repo.fetch("ifa" => 42).empty?
      end

      it "saves the params ('uuid' as id)" do
        get '/notify?plop=plip&uuid=42'
        assert !repo.fetch("uuid" => 42).empty?
      end
    end
  end

  describe "/fetch" do

    it "responds not found with no id" do
      get '/fetch'
      last_response.body.must_equal "[]"
    end

    describe "fetching" do

      describe "ifa" do
        it "responds not found with an unknown ifa" do
          get '/fetch?ifa=42'
          assert last_response.ok?
          last_response.body.must_equal "[]"
        end

        it "responds the JSON with a matching ifa" do
          get '/notify?plop=plip&ifa=42'
          get '/fetch?ifa=42'
          assert last_response.ok?
          last_response.body.must_equal '[{"plop":"plip","ifa":"42"}]'
        end
      end

      describe "uuid" do
        it "responds not found with an unknown uuid" do
          get '/fetch?uuid=42'
          assert last_response.ok?
          last_response.body.must_equal "[]"
        end

        it "responds the JSON with a matching ifa" do
          get '/notify?plop=plip&uuid=42'
          get '/fetch?uuid=42'
          assert last_response.ok?
          last_response.body.must_equal '[{"plop":"plip","uuid":"42"}]'
        end
      end
    end
  end

  describe "GET /all" do

    it "responds ok and an empty array" do
      get '/all'
      assert last_response.ok?
      assert last_response.body = '[]'
    end

    it "responds all logs" do
      get '/notify?plop=plip&uuid=42'
      get '/notify?plop=plip&ifa=42'
      get '/all'
      assert last_response.ok?
      assert last_response.body = '[{"plop":"plip","uuid":"42"},{"plop":"plip","ifa":"42"}]'
    end
  end

  describe "DELETE /all" do

    it "reset the repository" do
      get '/notify?plop=plip&uuid=42'
      delete '/all'
      assert repo.all.empty?
    end
  end
end
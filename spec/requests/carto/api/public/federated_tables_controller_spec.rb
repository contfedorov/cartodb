require 'spec_helper_min'
require 'support/helpers'

describe Carto::Api::Public::FederatedTablesController do
  include_context 'users helper'
  include HelperMethods

  before(:each) do
    host! "#{@user1.username}.localhost.lan"
  end

  describe '#list_federated_servers' do
    it 'returns 200 with the federated server list' do
      params_register = { api_key: @user1.api_key }
      payload_register = {
        federated_server_name: 'amazon',
        mode: 'read-only',
        dbname: 'testdb',
        host: 'myhostname.us-east-2.rds.amazonaws.com',
        port: '5432',
        username: 'read_only_user',
        password: 'secret'
      }
      post_json api_v4_federated_servers_register_server_url(params_register), payload_register do |response|
        expect(response.status).to eq(201)

        params_list = { api_key: @user1.api_key, page: 1, per_page: 10 }
        get_json api_v4_federated_servers_list_servers_url(params_list) do |response|
          expect(response.status).to eq(200)

          expect(response.body[:total]).to eq(1)

          expect(response.body[:result][0][:federated_server_name]).to eq('amazon')
          expect(response.body[:result][0][:dbname]).to eq('testdb')
          expect(response.body[:result][0][:host]).to eq('myhostname.us-east-2.rds.amazonaws.com')
        end
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_servers_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { api_key: api_key.token, page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_servers_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#register_federated_server' do
    before(:each) do
      @payload = {
        federated_server_name: 'amazon',
        mode: 'read-only',
        dbname: 'testdb',
        host: 'myhostname.us-east-2.rds.amazonaws.com',
        port: '5432',
        username: 'read_only_user',
        password: 'secret'
      }
    end

    it 'returns 201 with the federated server was created' do
      params = { api_key: @user1.api_key }

      post_json api_v4_federated_servers_register_server_url(params), @payload do |response|
        expect(response.status).to eq(201)
        expect(response.headers['Content-Location']).to eq('/api/v4/federated_servers/amazon')
      end
    end

    it 'returns 401 when non authenticated user' do
      post_json api_v4_federated_servers_register_server_url, @payload do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { api_key: api_key.token }

      post_json api_v4_federated_servers_register_server_url(params), @payload do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 422 when payload is missing' do
      params = { api_key: @user1.api_key }
      payload = {}

      post_json api_v4_federated_servers_register_server_url(params), payload do |response|
        expect(response.status).to eq(422)
      end
    end
  end

  describe '#show_federated_server' do
    it 'returns 200 with the federated server' do
      params_register = { api_key: @user1.api_key }
      payload_register = {
        federated_server_name: 'azure',
        mode: 'read-only',
        dbname: 'db',
        host: 'us-east-1.azure.com',
        port: '5432',
        username: 'read_only_user',
        password: 'secret'
      }
      post_json api_v4_federated_servers_register_server_url(params_register), payload_register do |response|
        expect(response.status).to eq(201)

        params = { federated_server_name: 'azure', api_key: @user1.api_key }
        get_json api_v4_federated_servers_get_server_url(params) do |response|
          expect(response.status).to eq(200)

          expect(response.body[:federated_server_name]).to eq('azure')
          expect(response.body[:dbname]).to eq('db')
          expect(response.body[:host]).to eq('us-east-1.azure.com')
        end
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon' }
      get_json api_v4_federated_servers_get_server_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', api_key: api_key.token }

      get_json api_v4_federated_servers_get_server_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 404 when there is not a faderated server with the provided name' do
      params = { federated_server_name: 'wadus', api_key: @user1.api_key }

      get_json api_v4_federated_servers_get_server_url(params) do |response|
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#update_federated_server' do
    before(:each) do
      @payload = {
        mode: 'read-only',
        dbname: 'testdb',
        host: 'myhostname.us-east-2.rds.amazonaws.com',
        port: '5432',
        username: 'read_only_user',
        password: 'secret'
      }
    end

    xit 'returns 201 with the federated server was created' do
      params = { federated_server_name: 'azure', api_key: @user1.api_key }

      put_json api_v4_federated_servers_update_server_url(params), @payload do |response|
        expect(response.status).to eq(201)
        expect(response.headers['Content-Location']).to eq('/api/v4/federated_servers/amazon')
      end
    end

    it 'returns 204 with the federated server was updated' do
      params = { federated_server_name: 'azure', api_key: @user1.api_key }

      put_json api_v4_federated_servers_update_server_url(params), @payload do |response|
        expect(response.status).to eq(204)
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'azure' }
      put_json api_v4_federated_servers_update_server_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'azure', api_key: api_key.token }

      put_json api_v4_federated_servers_update_server_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 422 when payload is missing' do
      params = { federated_server_name: 'azure', api_key: @user1.api_key }
      payload = {}

      put_json api_v4_federated_servers_update_server_url(params), payload do |response|
        expect(response.status).to eq(422)
      end
    end
  end

  describe '#unregister_federated_server' do
    it 'returns 204 with the federated server was destroyed' do
      params = { federated_server_name: 'azure', api_key: @user1.api_key }

      delete_json api_v4_federated_servers_unregister_server_url(params), @payload do |response|
        expect(response.status).to eq(204)
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'azure' }
      delete_json api_v4_federated_servers_unregister_server_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'azure', api_key: api_key.token }

      delete_json api_v4_federated_servers_unregister_server_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 404 when there is not a faderated server with the provided name' do
      params = { federated_server_name: 'wadus', api_key: @user1.api_key }

      delete_json api_v4_federated_servers_unregister_server_url(params) do |response|
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#list_remote_schemas' do
    xit 'returns 200 with the remote schemas list' do
      params = { federated_server_name: 'amazon', api_key: @user1.api_key, page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_schemas_url(params) do |response|
        expect(response.status).to eq(200)

        expect(response.body[:total]).to eq(2)

        expect(response.body[:result][0][:remote_schema_name]).to eq('default')
        expect(response.body[:result][1][:remote_schema_name]).to eq('locations')
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon', page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_schemas_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', api_key: api_key.token, page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_schemas_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#list_remote_tables' do
    it 'returns 200 with the remote tables list' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'default', api_key: @user1.api_key, page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_tables_url(params) do |response|
        expect(response.status).to eq(200)

        expect(response.body[:total]).to eq(2)

        expect(response.body[:result][0][:remote_table_name]).to eq('my_table')
        expect(response.body[:result][0][:remote_schema_name]).to eq('default')
        expect(response.body[:result][0][:registered]).to eq('true')
        expect(response.body[:result][0][:qualified_name]).to eq('default.my_table')
        expect(response.body[:result][0][:id_column_name]).to eq('id')
        expect(response.body[:result][0][:geom_column_name]).to eq('the_geom')
        expect(response.body[:result][0][:webmercator_column_name]).to eq('the_geom_webmercator')

        expect(response.body[:result][1][:remote_table_name]).to eq('shops')
        expect(response.body[:result][1][:remote_schema_name]).to eq('public')
        expect(response.body[:result][1][:registered]).to eq('false')
        expect(response.body[:result][1][:qualified_name]).to eq('public.shops')
        expect(response.body[:result][1][:id_column_name]).to eq('shop_id')
        expect(response.body[:result][1][:geom_column_name]).to eq('the_geom')
        expect(response.body[:result][1][:webmercator_column_name]).to eq('the_geom_webmercator')
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'default', page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_tables_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', remote_schema_name: 'default', api_key: api_key.token, page: 1, per_page: 10 }

      get_json api_v4_federated_servers_list_tables_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end
  end

  describe '#register_remote_table' do
    before(:each) do
      @payload = {
        remote_table_name: 'my_table',
        local_table_name_override: 'my_table',
        id_column_name: 'id',
        geom_column_name: 'the_geom',
        webmercator_column_name: 'the_geom_webmercator'
      }
    end

    it 'returns 201 with the federated server was created' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', api_key: @user1.api_key }

      post_json api_v4_federated_servers_register_table_url(params), @payload do |response|
        expect(response.status).to eq(201)
        expect(response.headers['Content-Location']).to eq('/api/v4/federated_servers/amazon/remote_schemas/public/remote_tables/my_table')
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public' }

      post_json api_v4_federated_servers_register_table_url(params), @payload do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', api_key: api_key.token }

      post_json api_v4_federated_servers_register_table_url(params), @payload do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 422 when payload is missing' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', api_key: @user1.api_key }
      payload = {}

      post_json api_v4_federated_servers_register_table_url(params), payload do |response|
        expect(response.status).to eq(422)
      end
    end
  end

  describe '#show_remote_table' do
    before(:each) do
      @payload = {
        local_table_name_override: 'my_table',
        id_column_name: 'id',
        geom_column_name: 'the_geom',
        webmercator_column_name: 'the_geom_webmercator'
      }
    end

    it 'returns 200 with the remote table' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: @user1.api_key }

      get_json api_v4_federated_servers_get_table_url(params) do |response|
        expect(response.status).to eq(200)

        expect(response.body[:federated_server_name]).to eq('amazon')
        expect(response.body[:remote_schema_name]).to eq('public')
        expect(response.body[:remote_table_name]).to eq('my_table')
        expect(response.body[:local_table_name_override]).to eq('my_table')
        expect(response.body[:qualified_name]).to eq('public.my_table')
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table' }
      get_json api_v4_federated_servers_get_table_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: api_key.token }

      get_json api_v4_federated_servers_get_table_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 404 when there is not a remote table with the provided name' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'wadus', api_key: @user1.api_key }

      get_json api_v4_federated_servers_get_table_url(params) do |response|
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#update_remote_table' do
    before(:each) do
      @payload = {
        local_table_name_override: 'my_table',
        id_column_name: 'another_id',
        geom_column_name: 'another_the_geom',
        webmercator_column_name: 'another_the_geom_webmercator'
      }
    end

    xit 'returns 201 with the remote table was created' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: @user1.api_key }

      put_json api_v4_federated_servers_update_server_url(params), @payload do |response|
        expect(response.status).to eq(201)
        expect(response.headers['Content-Location']).to eq('/api/v4/federated_servers/amazon/remote_schemas/public/remote_tables/my_table')
      end
    end

    it 'returns 204 with the remote table was updated' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: @user1.api_key }

      put_json api_v4_federated_servers_update_server_url(params), @payload do |response|
        expect(response.status).to eq(204)
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', }
      put_json api_v4_federated_servers_update_server_url(params), @payload do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: api_key.token }

      put_json api_v4_federated_servers_update_server_url(params), @payload do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 422 when payload is missing' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: @user1.api_key }
      payload = {}

      put_json api_v4_federated_servers_update_server_url(params), payload do |response|
        expect(response.status).to eq(422)
      end
    end
  end

  describe '#unregister_remote_table' do
    it 'returns 204' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: @user1.api_key }

      delete_json api_v4_federated_servers_unregister_table_url(params), @payload do |response|
        expect(response.status).to eq(204)
      end
    end

    it 'returns 401 when non authenticated user' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table' }
      delete_json api_v4_federated_servers_unregister_table_url(params) do |response|
        expect(response.status).to eq(401)
      end
    end

    it 'returns 403 when using a regular API key' do
      api_key = FactoryGirl.create(:api_key_apis, user_id: @user1.id)
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'my_table', api_key: api_key.token }

      delete_json api_v4_federated_servers_unregister_table_url(params) do |response|
        expect(response.status).to eq(403)
      end
    end

    xit 'returns 404 when there is not a remote table with the provided name' do
      params = { federated_server_name: 'amazon', remote_schema_name: 'public', remote_table_name: 'wadus', api_key: @user1.api_key }

      delete_json api_v4_federated_servers_unregister_table_url(params) do |response|
        expect(response.status).to eq(404)
      end
    end
  end
end

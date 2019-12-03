require 'spec_helper_min'
require 'support/helpers'

describe Carto::FederatedTablesService do
    include_context 'users helper'
    include HelperMethods

    before(:all) do
        puts "Starting remote server"
        @dir = Cartodb.get_config(:federated_server, 'dir')
        port = Cartodb.get_config(:federated_server, 'port')
        user = Cartodb.get_config(:federated_server, 'test_user')
        pg_bindir = Cartodb.get_config(:federated_server, 'pg_bindir_path')
        unless pg_bindir.present?
          pg_bindir = `pg_config --bindir`.delete!("\n")
        end
        @pg_ctl     = "#{pg_bindir}/pg_ctl"
        @psql       = "#{pg_bindir}/psql"

        raise "Federated server directory is not configured!" unless @dir.present?
        raise "Federated server port is not configured!" unless port.present?
        raise "Federated server user is not configured!" unless user.present?
        raise "Binary 'pg_ctl' could not be found" unless system("which #{@pg_ctl}")
        raise "Binary 'psql' could not be found" unless system("which #{@psql}")

        puts "Starting the remote server"
        raise("Could not start the federated DB") unless system("#{@pg_ctl} start --silent -D #{@dir} >/dev/null")

        @remote_host     = "127.0.0.1"
        @remote_port     = "#{port}"
        @remote_database = "#{user}"
        @remote_username = "#{user}"
        @remote_password = "#{user}"
    end

    after(:all) do
        puts "Stopping the remote server"
        system("#{@pg_ctl} stop --silent -D #{@dir} >/dev/null") || raise("Could not stop the federated DB")
    end

    describe 'Federated Servers' do
        describe 'List Federated Servers' do
            it 'should return a empty collection of federated server' do
                service = Carto::FederatedTablesService.new(user: @user1)
                pagination = { page: 1, per_page: 10, order: 'federated_server_name', direction: 'asc' }
                federated_server_list = service.list_servers(pagination)
                expect(federated_server_list).to be_empty
            end

            it 'should return a collection with one federated server' do
                service = Carto::FederatedTablesService.new(user: @user1)
                attributes = {
                    federated_server_name: "fs_001_from_#{@user1.username}_to_remote",
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                service.register_server(attributes)
                pagination = { page: 1, per_page: 10, order: 'federated_server_name', direction: 'asc' }
                federated_server_list = service.list_servers(pagination)
                expect(federated_server_list.length()).to eq(1)
                expect(federated_server_list[0]).to have_key(:federated_server_name)
                expect(federated_server_list[0][:federated_server_name]).to eq(attributes[:federated_server_name])
                expect(federated_server_list[0]).to have_key(:mode)
                expect(federated_server_list[0][:mode]).to eq(attributes[:mode])
                expect(federated_server_list[0]).to have_key(:dbname)
                expect(federated_server_list[0][:dbname]).to eq(attributes[:dbname])
                expect(federated_server_list[0]).to have_key(:host)
                expect(federated_server_list[0][:host]).to eq(attributes[:host])
                expect(federated_server_list[0]).to have_key(:port)
                expect(federated_server_list[0][:port]).to eq(attributes[:port])
            end
        end

        describe 'Federated Server' do
            it 'should register a federated server' do
                service = Carto::FederatedTablesService.new(user: @user1)
                attributes = {
                    federated_server_name: "fs_002_from_#{@user1.username}_to_remote",
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.register_server(attributes)
                expect(federated_server).to have_key(:federated_server_name)
                expect(federated_server[:federated_server_name]).to eq(attributes[:federated_server_name])
                expect(federated_server).to have_key(:mode)
                expect(federated_server[:mode]).to eq(attributes[:mode])
                expect(federated_server).to have_key(:dbname)
                expect(federated_server[:dbname]).to eq(attributes[:dbname])
                expect(federated_server).to have_key(:host)
                expect(federated_server[:host]).to eq(attributes[:host])
                expect(federated_server).to have_key(:port)
                expect(federated_server[:port]).to eq(attributes[:port])
            end

            it 'should grant access of a federated server to a role' do
                service = Carto::FederatedTablesService.new(user: @user1)
                federated_server_name = "fs_003_from_#{@user1.username}_to_remote"
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.register_server(attributes)
                expect {
                    service.grant_access_to_federated_server(
                        federated_server_name: federated_server_name,
                        db_role: @user1.database_username
                    )
                }.not_to raise_error
            end

            it 'should get a federated server by name' do
                service = Carto::FederatedTablesService.new(user: @user1)
                federated_server_name = "fs_004_from_#{@user1.username}_to_remote"
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                service.register_server(attributes)
                federated_server = service.get_server(federated_server_name: federated_server_name)
                expect(federated_server).to have_key(:federated_server_name)
                expect(federated_server[:federated_server_name]).to eq(federated_server_name)
                expect(federated_server).to have_key(:mode)
                expect(federated_server[:mode]).to eq(attributes[:mode])
                expect(federated_server).to have_key(:dbname)
                expect(federated_server[:dbname]).to eq(attributes[:dbname])
                expect(federated_server).to have_key(:host)
                expect(federated_server[:host]).to eq(attributes[:host])
                expect(federated_server).to have_key(:port)
                expect(federated_server[:port]).to eq(attributes[:port])
            end

            it 'should update a federated server by name' do
                service = Carto::FederatedTablesService.new(user: @user1)
                federated_server_name = "fs_005_from_#{@user1.username}_to_remote"
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @user1.database_name,
                    host: @user1.database_host,
                    port: '5432',
                    username: @user1.database_username,
                    password: @user1.database_password
                }
                federated_server = service.register_server(attributes)
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.update_server(attributes)
                expect(federated_server).to have_key(:federated_server_name)
                expect(federated_server[:federated_server_name]).to eq(federated_server_name)
                expect(federated_server).to have_key(:mode)
                expect(federated_server[:mode]).to eq(attributes[:mode])
                expect(federated_server).to have_key(:dbname)
                expect(federated_server[:dbname]).to eq(attributes[:dbname])
                expect(federated_server).to have_key(:host)
                expect(federated_server[:host]).to eq(attributes[:host])
                expect(federated_server).to have_key(:port)
                expect(federated_server[:port]).to eq(attributes[:port])
            end

            it 'should unregister a federated server by name' do
                service = Carto::FederatedTablesService.new(user: @user1)
                federated_server_name = "fs_006_from_#{@user1.username}_to_remote"
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.register_server(attributes)
                expect {
                    service.unregister_server(federated_server_name: federated_server_name)
                }.not_to raise_error
            end

            it 'should revoke access to a federated server' do
                service = Carto::FederatedTablesService.new(user: @user1)
                federated_server_name = "fs_007_from_#{@user1.username}_to_remote"
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.register_server(attributes)
                expect {
                    service.revoke_access_to_federated_server(
                        federated_server_name: federated_server_name,
                        db_role: @user1.database_username
                    )
                }.not_to raise_error
            end
        end

        describe 'Remote Schemas' do
            it 'should list remote schemas of a federated server' do
                service = Carto::FederatedTablesService.new(user: @user1)
                federated_server_name = "fs_008_from_#{@user1.username}_to_remote"
                attributes = {
                    federated_server_name: federated_server_name,
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.register_server(attributes)
                service.grant_access_to_federated_server(
                    federated_server_name: federated_server_name,
                    db_role: @user1.database_username
                )
                pagination = { page: 1, per_page: 10, order: 'remote_schema_name', direction: 'asc' }
                remote_schemas = service.list_remote_schemas(federated_server_name, pagination)
                expect(remote_schemas).to include(:remote_schema_name=>"public")
            end

            it 'should raise "Not enough permissions" error when listing remote schemas of a federated server' do
                service = Carto::FederatedTablesService.new(user: @user1)
                attributes = {
                    federated_server_name: "fs_009_from_#{@user1.username}_to_remote",
                    mode: 'read-only',
                    dbname: @remote_database,
                    host: @remote_host,
                    port: @remote_port,
                    username: @remote_username,
                    password: @remote_username
                }
                federated_server = service.register_server(attributes)
                pagination = { page: 1, per_page: 10, order: 'remote_schema_name', direction: 'asc' }
                expect {
                    service.list_remote_schemas(federated_server[:federated_server_name], pagination)
                }.to raise_error(Sequel::DatabaseError, /Not enough permissions to access the server/)
            end
        end
    end
end

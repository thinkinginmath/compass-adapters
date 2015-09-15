# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::identity_registration' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'

    it 'registers service tenant' do
      expect(chef_run).to create_tenant_openstack_identity_register(
        'Register Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        tenant_description: 'Service Tenant'
      )
    end

    it 'registers cinder volume service' do
      expect(chef_run).to create_service_openstack_identity_register(
        'Register Cinder Volume Service'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        service_name: 'cinder',
        service_type: 'volume',
        service_description: 'Cinder Volume Service',
        endpoint_region: 'RegionOne',
        endpoint_adminurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
        endpoint_internalurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
        endpoint_publicurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s'
      )
    end

    context 'registers volume endpoint' do
      it 'with default values' do
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder Volume Endpoint'
        ).with(
          auth_uri: 'http://127.0.0.1:35357/v2.0',
          bootstrap_token: 'bootstrap-token',
          service_name: 'cinder',
          service_type: 'volume',
          service_description: 'Cinder Volume Service',
          endpoint_region: 'RegionOne',
          endpoint_adminurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
          endpoint_internalurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s',
          endpoint_publicurl: 'http://127.0.0.1:8776/v1/%(tenant_id)s'
        )
      end

      it 'with custom region override' do
        node.set['openstack']['block-storage']['region'] = 'volumeRegion'
        expect(chef_run).to create_endpoint_openstack_identity_register(
          'Register Cinder Volume Endpoint'
        ).with(endpoint_region: 'volumeRegion')
      end
    end

    it 'registers service user' do
      expect(chef_run).to create_user_openstack_identity_register(
        'Register Cinder Service User'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'cinder',
        user_pass: 'cinder-pass',
        user_enabled: true
      )
    end

    it 'grants admin role to service user for service tenant' do
      expect(chef_run).to grant_role_openstack_identity_register(
        'Grant service Role to Cinder Service User for Cinder Service Tenant'
      ).with(
        auth_uri: 'http://127.0.0.1:35357/v2.0',
        bootstrap_token: 'bootstrap-token',
        tenant_name: 'service',
        user_name: 'cinder',
        role_name: 'admin'
      )
    end
  end
end

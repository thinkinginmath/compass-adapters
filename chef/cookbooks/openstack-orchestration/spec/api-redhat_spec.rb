# encoding: UTF-8
require_relative 'spec_helper'

describe 'openstack-orchestration::api' do
  before { orchestration_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-orchestration::api'
    end

    expect_runs_openstack_orchestration_common_recipe
    expect_installs_python_keystoneclient

    it 'does not run logging recipe' do
      expect(@chef_run).not_to include_recipe 'openstack-common::logging'
    end

    it 'installs heat client packages' do
      expect(@chef_run).to upgrade_package 'python-heatclient'
    end

    expect_creates_api_paste 'service[heat-api]'

    it 'starts heat api on boot' do
      expect(@chef_run).to enable_service('openstack-heat-api')
    end
  end
end

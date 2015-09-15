# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::agent-central' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the agent-central package' do
      expect(chef_run).to install_package 'openstack-ceilometer-agent-central'
    end

    it 'starts the agent-central service' do
      expect(chef_run).to start_service 'openstack-ceilometer-agent-central'
    end
  end
end

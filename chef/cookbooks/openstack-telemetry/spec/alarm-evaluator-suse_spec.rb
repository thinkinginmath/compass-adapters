# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-telemetry::alarm-evaluator' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'telemetry-stubs'

    it 'installs the alarm-evaluator package' do
      expect(chef_run).to install_package 'openstack-ceilometer-alarm-evaluator'
    end

    it 'starts the alarm-evaluator service' do
      expect(chef_run).to start_service 'openstack-ceilometer-alarm-evaluator'
    end
  end
end

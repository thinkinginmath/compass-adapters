# encoding: UTF-8

require_relative 'spec_helper'

describe 'openstack-ops-database::mysql-client' do
  describe 'suse' do
    let(:runner) { ChefSpec::Runner.new(SUSE_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    it 'installs mysql packages' do
      expect(chef_run).to install_package('python-mysql')
    end
  end
end

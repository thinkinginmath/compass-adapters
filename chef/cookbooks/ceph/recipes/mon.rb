# This recipe creates a monitor cluster
#
# You should never change the mon default path or
# the keyring path.
# Don't change the cluster name either
# Default path for mon data: /var/lib/ceph/mon/$cluster-$id/
#   which will be /var/lib/ceph/mon/ceph-`hostname`/
#   This path is used by upstart. If changed, upstart won't
#   start the monitor
# The keyring files are created using the following pattern:
#  /etc/ceph/$cluster.client.$name.keyring
#  e.g. /etc/ceph/ceph.client.admin.keyring
#  The bootstrap-osd and bootstrap-mds keyring are a bit
#  different and are created in
#  /var/lib/ceph/bootstrap-{osd,mds}/ceph.keyring

node.default['ceph']['is_mon'] = true

include_recipe 'ceph::conf'
include_recipe 'ceph::_common'
include_recipe 'ceph::mon_install'


service_type = node['ceph']['mon']['init_style']

directory '/var/run/ceph' do
  owner 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

directory "/var/lib/ceph/mon/ceph-#{node['hostname']}" do
  owner 'root'
  group 'root'
  mode 00755
  recursive true
  action :create
end

# TODO: cluster name
cluster = 'ceph'

if mon_master.name != node.name
  admin_keyring = mon_master['ceph']['admin-secret']
  if admin_keyring.nil?
    Chef::Application.fatal!("wait for mon master node update.")
  end
  if mon_secret.nil?
    Chef::Application.fatal!("wait for mon master node update.")
  end
  admin_user = "admin"
  template "/etc/ceph/ceph.client.#{admin_user}.keyring" do
    source 'ceph.client.keyring.erb'
    mode 00600
    variables(
        name: admin_user,
        key: admin_keyring
    )
  end
end

unless File.exist?("/var/lib/ceph/mon/ceph-#{node['hostname']}/done")
  keyring = "#{Chef::Config[:file_cache_path]}/#{cluster}-#{node['hostname']}.mon.keyring"

  execute 'format mon-secret as keyring' do
    command lazy { "ceph-authtool '#{keyring}' --create-keyring --name=mon. --add-key='#{mon_secret}' --cap mon 'allow *'" }
    creates "#{Chef::Config[:file_cache_path]}/#{cluster}-#{node['hostname']}.mon.keyring"
    only_if { mon_secret }
    notifies :create, 'ruby_block[save mon_secret]', :immediately
  end

  execute 'generate mon-secret as keyring' do
    command "ceph-authtool '#{keyring}' --create-keyring --name=mon. --gen-key --cap mon 'allow *'"
    creates "#{Chef::Config[:file_cache_path]}/#{cluster}-#{node['hostname']}.mon.keyring"
    not_if { mon_secret }
    notifies :create, 'ruby_block[save mon_secret]', :immediately
  end

  ruby_block 'save mon_secret' do
    block do
      fetch = Mixlib::ShellOut.new("ceph-authtool '#{keyring}' --print-key --name=mon.")
      fetch.run_command
      key = fetch.stdout
      node.set['ceph']['monitor-secret'] = key
      node.save
    end
    action :nothing
  end

  execute 'ceph-mon mkfs' do
    command "ceph-mon  --mkfs -i #{node['hostname']} --keyring '#{keyring}'"
  end

  ruby_block 'finalise' do
    block do
      ['done', service_type].each do |ack|
        ::File.open("/var/lib/ceph/mon/ceph-#{node['hostname']}/#{ack}", 'w').close
      end
    end
  end
end

if service_type == 'upstart'
  service 'ceph-mon' do
    provider Chef::Provider::Service::Upstart
    action :enable
  end
  service 'ceph-mon-all' do
    provider Chef::Provider::Service::Upstart
    supports :status => true
    action [:enable, :start]
  end
end

service 'ceph_mon' do
  case service_type
  when 'upstart'
    service_name 'ceph-mon-all-starter'
    provider Chef::Provider::Service::Upstart
  else
    service_name 'ceph'
  end
  supports :restart => true, :status => true
  subscribes :restart, resources('template[/etc/ceph/ceph.conf]')
  action [:enable, :start]
end

mon_addresses.each do |addr|
  execute "peer #{addr}" do
    command "ceph --admin-daemon '/var/run/ceph/ceph-mon.#{node['hostname']}.asok' add_bootstrap_peer_hint #{addr}"
    ignore_failure true
  end
end

# The key is going to be automatically created, We store it when it is created
# If we're storing keys in encrypted data bags, then they've already been generated above
#if use_cephx? && !node['ceph']['encrypted_data_bags']
unless node['ceph']['encrypted_data_bags']
  ruby_block 'get osd-bootstrap keyring' do
    block do
      run_out = ''
      while run_out.empty?
        run_out = Mixlib::ShellOut.new('ceph auth get-key client.bootstrap-osd').run_command.stdout.strip
        sleep 2
      end
      node.set['ceph']['bootstrap_osd_key'] = run_out
      node.save
    end
    not_if { node['ceph']['bootstrap_osd_key'] }
  end
end

ruby_block 'save admin_secret' do
  block do
    fetch = Mixlib::ShellOut.new("ceph-authtool /etc/ceph/ceph.client.admin.keyring --print-key --name=client.admin")
    fetch.run_command
    key = fetch.stdout
    node.set['ceph']['admin-secret'] = key
    node.save
  end
end


default_pools = node['ceph']['default_pools']
#set default pg num
if node['ceph']['config']['global']['osd pool default pg num']

  default_pools.each do |default_pool|
    run_out = Mixlib::ShellOut.new("ceph osd pool get #{default_pool} pg_num| awk -F \": \" '{print $2}'").run_command.stdout.strip
    if run_out.to_i < node['ceph']['config']['global']['osd pool default pgp num'].to_i
      execute 'set default pg num' do
        command "ceph osd pool delete #{default_pool} #{default_pool} --yes-i-really-really-mean-it;ceph osd pool create #{default_pool} #{node['ceph']['config']['global']['osd pool default pg num']}"
        ignore_failure true
        not_if {pg_creating?}
      end
    end
  end
end

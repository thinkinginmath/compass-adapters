# encoding: utf-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::cinder-common' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::Runner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      node.set['openstack']['mq']['host'] = '127.0.0.1'
      node.set['openstack']['mq']['block-storage']['rabbit']['notification_topic'] = 'rabbit_topic'

      runner.converge(described_recipe)
    end

    include_context 'block-storage-stubs'

    it 'upgrades the cinder-common package' do
      expect(chef_run).to upgrade_package 'cinder-common'
    end

    describe '/etc/cinder' do
      let(:dir) { chef_run.directory('/etc/cinder') }

      it 'has proper owner' do
        expect(dir.owner).to eq('cinder')
        expect(dir.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', dir.mode)).to eq '750'
      end
    end

    describe 'cinder.conf' do
      let(:file) { chef_run.template('/etc/cinder/cinder.conf') }

      it 'has proper owner' do
        expect(file.owner).to eq('cinder')
        expect(file.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', file.mode)).to eq '644'
      end

      context 'template contents' do
        let(:test_pass) { 'test_pass' }
        before do
          Chef::Recipe.any_instance.stub(:endpoint)
            .with('image-api')
            .and_return(double(host: 'glance_host_value', port: 'glance_port_value'))
          Chef::Recipe.any_instance.stub(:endpoint)
            .with('block-storage-api-bind')
            .and_return(double(host: 'cinder_host_value', port: 'cinder_port_value'))
          Chef::Recipe.any_instance.stub(:get_password)
            .with('user', anything)
            .and_return(test_pass)
        end

        context 'commonly  named attributes' do
          %w(debug verbose lock_path notification_driver
             storage_availability_zone quota_volumes quota_gigabytes quota_driver
             volume_name_template snapshot_name_template
             control_exchange rpc_thread_pool_size rpc_conn_pool_size
             rpc_response_timeout max_gigabytes).each do |attr_key|
            it "has a #{attr_key} attribute" do
              node.set['openstack']['block-storage'][attr_key] = "#{attr_key}_value"

              expect(chef_run).to render_file(file.name).with_content(/^#{attr_key}=#{attr_key}_value$/)
            end
          end
        end

        context 'rdb driver' do
          # FIXME(galstrom21): this block needs to check all of the default
          #   rdb_* configuration options
          it 'has default rbd_* options set' do
            node.set['openstack']['block-storage']['volume'] = {
              'driver' => 'cinder.volume.drivers.rbd.RBDDriver'
            }
            expect(chef_run).to render_file(file.name).with_content(/^rbd_/)
            expect(chef_run).not_to render_file(file.name).with_content(/^netapp_/)
          end
        end

        context 'netapp driver' do
          # FIXME(galstrom21): this block needs to check all of the default
          #   netapp_* configuration options
          it 'has default netapp_* options set' do
            node.set['openstack']['block-storage']['volume'] = {
              'driver' => 'cinder.volume.drivers.netapp.NetAppISCSIDriver'
            }
            expect(chef_run).to render_file(file.name).with_content(/^netapp_/)
            expect(chef_run).not_to render_file(file.name).with_content(/^rbd_/)
          end
        end

        context 'syslog use' do
          it 'sets the log_config value when syslog is in use' do
            node.set['openstack']['block-storage']['syslog']['use'] = true

            expect(chef_run).to render_file(file.name)
              .with_content(%r{^log_config = /etc/openstack/logging.conf$})
          end

          it 'sets the log_file value when syslog is not in use' do
            node.set['openstack']['block-storage']['syslog']['use'] = false

            expect(chef_run).to render_file(file.name)
              .with_content(%r{^log_file = /var/log/cinder/cinder.log$})
          end
        end

        it 'has a sql_connection attribute' do
          Chef::Recipe.any_instance.stub(:db_uri)
            .with('block-storage', anything, '').and_return('sql_connection_value')

          expect(chef_run).to render_file(file.name)
            .with_content(/^sql_connection=sql_connection_value$/)
        end

        it 'has a volume_driver attribute' do
          node.set['openstack']['block-storage']['volume']['driver'] = 'volume_driver_value'
          expect(chef_run).to render_file(file.name).with_content(/^volume_driver=volume_driver_value$/)
        end

        it 'has a state_path attribute' do
          node.set['openstack']['block-storage']['volume']['state_path'] = 'state_path_value'
          expect(chef_run).to render_file(file.name).with_content(/^state_path=state_path_value$/)
        end

        context 'glance endpoint' do
          %w(host port).each do |glance_attr|
            it "has a glace #{glance_attr} attribute" do
              expect(chef_run).to render_file(file.name).with_content(/^glance_#{glance_attr}=glance_#{glance_attr}_value$/)
            end
          end
        end

        it 'has a api_rate_limit attribute' do
          node.set['openstack']['block-storage']['api']['ratelimit'] = 'api_rate_limit_value'
          expect(chef_run).to render_file(file.name).with_content(/^api_rate_limit=api_rate_limit_value$/)
        end

        context 'cinder endpoint' do
          it 'has osapi_volume_listen set' do
            expect(chef_run).to render_file(file.name).with_content(/^osapi_volume_listen=cinder_host_value$/)
          end

          it 'has osapi_volume_listen_port set' do
            expect(chef_run).to render_file(file.name).with_content(/^osapi_volume_listen_port=cinder_port_value$/)
          end
        end

        it 'has a rpc_backend attribute' do
          node.set['openstack']['block_storage']['rpc_backend'] = 'rpc_backend_value'
          expect(chef_run).to render_file(file.name).with_content(/^rpc_backend=rpc_backend_value$/)
        end

        context 'rabbitmq as mq service' do
          before do
            node.set['openstack']['mq']['block-storage']['service_type'] = 'rabbitmq'
          end

          context 'ha attributes' do
            before do
              node.set['openstack']['mq']['block-storage']['rabbit']['ha'] = true
            end

            it 'has a rabbit_hosts attribute' do
              Chef::Recipe.any_instance.stub(:rabbit_servers)
                .and_return('rabbit_servers_value')

              expect(chef_run).to render_file(file.name).with_content(/^rabbit_hosts=rabbit_servers_value$/)
            end

            %w(host port).each do |attr|
              it "does not have rabbit_#{attr} attribute" do
                expect(chef_run).not_to render_file(file.name).with_content(/^rabbit_#{attr}=/)
              end
            end
          end

          context 'non ha attributes' do
            before do
              node.set['openstack']['mq']['block-storage']['rabbit']['ha'] = false
            end

            %w(host port).each do |attr|
              it "has rabbit_#{attr} attribute" do
                node.set['openstack']['mq']['block-storage']['rabbit'][attr] = "rabbit_#{attr}_value"
                expect(chef_run).to render_file(file.name).with_content(/^rabbit_#{attr}=rabbit_#{attr}_value$/)
              end
            end

            it 'does not have a rabbit_hosts attribute' do
              expect(chef_run).not_to render_file(file.name).with_content(/^rabbit_hosts=/)
            end
          end

          %w(use_ssl userid).each do |attr|
            it "has rabbit_#{attr}" do
              node.set['openstack']['mq']['block-storage']['rabbit'][attr] = "rabbit_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^rabbit_#{attr}=rabbit_#{attr}_value$/)
            end
          end

          it 'has rabbit_password' do
            expect(chef_run).to render_file(file.name).with_content(/^rabbit_password=#{test_pass}$/)
          end

          it 'has rabbit_virtual_host' do
            node.set['openstack']['mq']['block-storage']['rabbit']['vhost'] = 'vhost_value'
            expect(chef_run).to render_file(file.name).with_content(/^rabbit_virtual_host=vhost_value$/)
          end
        end

        context 'qpid as mq service' do
          before do
            node.set['openstack']['mq']['block-storage']['service_type'] = 'qpid'
          end

          %w(port username sasl_mechanisms reconnect reconnect_timeout reconnect_limit
             reconnect_interval_min reconnect_interval_max reconnect_interval heartbeat protocol
             tcp_nodelay).each do |attr|
            it "has qpid_#{attr} attribute" do
              node.set['openstack']['mq']['block-storage']['qpid'][attr] = "qpid_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^qpid_#{attr}=qpid_#{attr}_value$/)
            end
          end

          it 'has qpid_hostname' do
            node.set['openstack']['mq']['block-storage']['qpid']['host'] = 'qpid_host_value'
            expect(chef_run).to render_file(file.name).with_content(/^qpid_hostname=qpid_host_value$/)
          end

          it 'has qpid_password' do
            expect(chef_run).to render_file(file.name).with_content(/^qpid_password=#{test_pass}$/)
          end

          it 'has qpid notification_topics' do
            node.set['openstack']['mq']['block-storage']['qpid']['notification_topic'] = 'qpid_notification_topic_value'
            expect(chef_run).to render_file(file.name).with_content(/^notification_topics=qpid_notification_topic_value$/)
          end
        end

        context 'lvm settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.lvm.LVMISCSIDriver'
          end

          %w(group clear clear_size).each do |attr|
            it "has lvm volume_#{attr} attribute" do
              node.set['openstack']['block-storage']['volume']["volume_#{attr}"] = "volume_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^volume_#{attr}=volume_#{attr}_value$/)
            end
          end
        end

        context 'commonly named volume attributes' do
          %w(iscsi_ip_address iscsi_port iscsi_helper volumes_dir).each do |attr|
            it "has volume related #{attr} attribute" do
              node.set['openstack']['block-storage']['volume'][attr] = "common_volume_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=common_volume_#{attr}_value$/)
            end
          end
        end

        context 'rbd attributes' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.rbd.RBDDriver'
          end

          %w(rbd_pool rbd_user rbd_secret_uuid).each do |attr|
            it "has a #{attr} attribute" do
              node.set['openstack']['block-storage'][attr] = "#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=#{attr}_value$/)
            end
          end
        end

        it 'has volume_driver attribute' do
          node.set['openstack']['block-storage']['volume']['driver'] = 'volume_driver_value'
          expect(chef_run).to render_file(file.name).with_content(/^volume_driver=volume_driver_value$/)
        end

        context 'netapp ISCSI settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.NetAppISCSIDriver'
          end

          %w(login password).each do |attr|
            it "has a netapp_#{attr} attribute" do
              node.set['openstack']['block-storage']['netapp']["dfm_#{attr}"] = "dfm_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^netapp_#{attr}=dfm_#{attr}_value$/)
            end
          end

          %w(hostname port).each do |attr|
            it "has a netapp_server_#{attr} attribute" do
              node.set['openstack']['block-storage']['netapp']["dfm_#{attr}"] = "dfm_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^netapp_server_#{attr}=dfm_#{attr}_value$/)
            end
          end

          it 'has a netapp_storage_service attribute' do
            node.set['openstack']['block-storage']['netapp']['storage_service'] = 'netapp_storage_service_value'
            expect(chef_run).to render_file(file.name).with_content(/^netapp_storage_service=netapp_storage_service_value$/)
          end
        end

        context 'netapp direct7 mode nfs settings' do
          let(:hostnames) { %w(hostname1 hostname2 hostname3) }
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver'
            node.set['openstack']['block-storage']['netapp']['netapp_server_hostname'] = hostnames
          end

          %w(mount_point_base shares_config).each do |attr_key|
            it "has a nfs_#{attr_key} attribute" do
              node.set['openstack']['block-storage']['nfs'][attr_key] = "netapp_nfs_#{attr_key}_value"
              expect(chef_run).to render_file(file.name).with_content(/^nfs_#{attr_key}=netapp_nfs_#{attr_key}_value$/)
            end
          end

          it 'has netapp server_hostname attributes' do
            hostnames.each do |hostname|
              expect(chef_run).to render_file(file.name).with_content(/^netapp_server_hostname=#{hostname}$/)
            end
          end

          it 'has a netapp_server_port attribute' do
            node.set['openstack']['block-storage']['netapp']['netapp_server_port'] = 'netapp_server_port_value'
            expect(chef_run).to render_file(file.name).with_content(/^netapp_server_port=netapp_server_port_value$/)
          end

          %w(login password).each do |attr|
            it "has a netapp_#{attr} attribute" do
              node.set['openstack']['block-storage']['netapp']["netapp_server_#{attr}"] = "netapp_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^netapp_#{attr}=netapp_#{attr}_value$/)
            end
          end

          %w(disk_util sparsed_volumes).each do |attr|
            it "has a nfs_#{attr} attribute" do
              node.set['openstack']['block-storage']['nfs']["nfs_#{attr}"] = "netapp_nfs_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^nfs_#{attr}=netapp_nfs_#{attr}_value$/)
            end
          end
        end

        context 'ibmnas settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.ibmnas.IBMNAS_NFSDriver'
          end

          %w(mount_point_base shares_config).each do |attr|
            it "has a ibmnas_#{attr} attribute" do
              node.set['openstack']['block-storage']['ibmnas'][attr] = "ibmnas_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^nfs_#{attr}=ibmnas_#{attr}_value$/)
            end
          end

          it 'has a nfs_sparsed_volumes attribute' do
            node.set['openstack']['block-storage']['ibmnas']['nfs_sparsed_volumes'] = 'ibmnas_nfs_sparsed_volumes_value'
            expect(chef_run).to render_file(file.name).with_content(/^nfs_sparsed_volumes=ibmnas_nfs_sparsed_volumes_value$/)
          end

          %w(nas_ip nas_login nas_ssh_port).each do |attr|
            it "has a ibmnas #{attr} attribute" do
              node.set['openstack']['block-storage']['ibmnas'][attr] = "ibmnas_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=ibmnas_#{attr}_value$/)
            end
          end

          it 'has a nas_password attribute' do
            expect(chef_run).to render_file(file.name).with_content(/^nas_password=#{test_pass}$/)
          end
        end

        context 'storwize settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.ibm.storwize_svc.StorwizeSVCDriver'
          end

          it 'has a default attribute' do
            %w(san_ip=127.0.0.1
               san_login=admin
               san_private_key=/v7000_rsa
               storwize_svc_volpool_name=volpool
               storwize_svc_vol_rsize=2
               storwize_svc_vol_warning=0
               storwize_svc_vol_autoexpand=true
               storwize_svc_vol_grainsize=256
               storwize_svc_vol_compression=false
               storwize_svc_vol_easytier=true
               storwize_svc_vol_iogrp=0
               storwize_svc_flashcopy_timeout=120
               storwize_svc_connection_protocol=iSCSI
               storwize_svc_iscsi_chap_enabled=true
               storwize_svc_multihostmap_enabled=true).each do |attr|
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}$/)
            end
          end

          it 'has a overridden attribute' do
            %w(san_ip
               san_login
               san_private_key
               storwize_svc_volpool_name
               storwize_svc_vol_rsize
               storwize_svc_vol_warning
               storwize_svc_vol_autoexpand
               storwize_svc_vol_grainsize
               storwize_svc_vol_compression
               storwize_svc_vol_easytier
               storwize_svc_vol_iogrp
               storwize_svc_flashcopy_timeout
               storwize_svc_connection_protocol
               storwize_svc_multihostmap_enabled).each do |attr|
              node.set['openstack']['block-storage']['storwize'][attr] = "storwize_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=storwize_#{attr}_value$/)
            end
          end

          context 'storwize with iSCSI connection protocol' do
            before do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'iSCSI'
            end

            it 'has a iscsi chap enabled attribute' do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_iscsi_chap_enabled'] = 'storwize_svc_iscsi_chap_enabled_value'
              expect(chef_run).to render_file(file.name).with_content(/^storwize_svc_iscsi_chap_enabled=storwize_svc_iscsi_chap_enabled_value$/)
            end

            it 'does not have a multipath enabled attribute' do
              expect(chef_run).not_to render_file(file.name).with_content(/^storwize_svc_multipath_enabled=/)
            end
          end

          context 'storwize without iSCSI connection protocol' do
            before do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_connection_protocol'] = 'non-iSCSI'
            end

            it 'does not have a iscsi chap enabled attribute' do
              expect(chef_run).not_to render_file(file.name).with_content(/^storwize_svc_iscsi_enabled=/)
            end

            it 'has a multipath enabled attribute' do
              node.set['openstack']['block-storage']['storwize']['storwize_svc_multipath_enabled'] = 'storwize_svc_multipath_enabled_value'
              expect(chef_run).to render_file(file.name).with_content(/^storwize_svc_multipath_enabled=storwize_svc_multipath_enabled_value$/)
            end
          end
        end

        context 'solidfire settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.solidfire.SolidFire'
          end

          it 'has solidfire sf_emulate set' do
            node.set['openstack']['block-storage']['solidfire']['sf_emulate'] = 'test'
            expect(chef_run).to render_file(file.name).with_content(/^sf_emulate_512=test$/)
          end

          %w(san_login san_ip).each do |attr|
            it "has solidfire #{attr} set" do
              node.set['openstack']['block-storage']['solidfire'][attr] = "solidfire_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=solidfire_#{attr}_value$/)
            end
          end

          it 'does not have iscsi_ip_prefix not specified' do
            node.set['openstack']['block-storage']['solidfire']['iscsi_ip_prefix'] = nil
            expect(chef_run).to_not render_file(file.name).with_content(/^iscsi_ip_prefix=/)
          end

          it 'does have iscsi_ip_prefix when specified' do
            chef_run.node.set['openstack']['block-storage']['solidfire']['iscsi_ip_prefix'] = '203.0.113.*'
            expect(chef_run).to render_file(file.name).with_content(/^iscsi_ip_prefix=203.0.113.*$/)
          end
        end

        context 'emc settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.emc.emc_smis_iscsi.EMCSMISISCSIDriver'
          end

          %w(iscsi_target_prefix cinder_emc_config_file).each do |attr|
            it "has emc #{attr} set" do
              node.set['openstack']['block-storage']['emc'][attr] = "emc_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr}=emc_#{attr}_value$/)
            end
          end
        end

        context 'vmware vmdk settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver'
            %w(vmware_host_ip vmware_host_username
               vmware_api_retry_count vmware_task_poll_interval vmware_volume_folder
               vmware_image_transfer_timeout_secs vmware_max_objects_retrieval).each do |attr|
              node.set['openstack']['block-storage']['vmware'][attr] = "vmware_#{attr}_value"
            end
          end

          it 'has vmware attributes set' do
            node['openstack']['block-storage']['vmware'].each do |attr, val|
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = #{val}$/)
            end
          end

          it 'has password set which is from databag' do
            expect(chef_run).to render_file(file.name).with_content(/^vmware_host_password = vmware_secret_name$/)
          end

          it 'has no wsdl_location line without the attribute' do
            node.set['openstack']['block-storage']['vmware']['vmware_wsdl_location'] = nil
            expect(chef_run).not_to render_file(file.name).with_content(/^vmware_wsdl_location = /)
          end

          it 'has wsdl_location line with attribute present' do
            node.set['openstack']['block-storage']['vmware']['vmware_wsdl_location'] = 'http://127.0.0.1/wsdl'
            expect(chef_run).to render_file(file.name).with_content(%r(^vmware_wsdl_location = http://127.0.0.1/wsdl$))
          end
        end

        context 'gpfs settings' do
          before do
            node.set['openstack']['block-storage']['volume']['driver'] = 'cinder.volume.drivers.gpfs.GPFSDriver'
          end

          %w(gpfs_mount_point_base gpfs_images_share_mode gpfs_max_clone_depth
             gpfs_sparse_volumes gpfs_storage_pool).each do |attr|
            it "has gpfs #{attr} set" do
              node.set['openstack']['block-storage']['gpfs'][attr] = "gpfs_#{attr}_value"
              expect(chef_run).to render_file(file.name).with_content(/^#{attr} = gpfs_#{attr}_value$/)
            end
          end

          it 'has no gpfs_images_dir line without the attribute' do
            node.set['openstack']['block-storage']['gpfs']['gpfs_images_dir'] = nil
            expect(chef_run).not_to render_file(file.name).with_content(/^gpfs_images_dir = /)
          end

          it 'has gpfs_images_dir line with attribute present' do
            node.set['openstack']['block-storage']['gpfs']['gpfs_images_dir'] = 'gpfs_images_dir_value'
            expect(chef_run).to render_file(file.name).with_content(/^gpfs_images_dir = gpfs_images_dir_value$/)
          end

          it 'templates misc_cinder array correctly' do
            node.set['openstack']['block-storage']['misc_cinder'] = ['# Comments', 'MISC=OPTION']
            expect(chef_run).to render_file(file.name).with_content(
              /^# Comments$/)
            expect(chef_run).to render_file(file.name).with_content(
              /^MISC=OPTION$/)
          end
        end
      end
    end

    describe '/var/lock/cinder' do
      let(:dir) { chef_run.directory('/var/lock/cinder') }

      it 'has proper owner' do
        expect(dir.owner).to eq('cinder')
        expect(dir.group).to eq('cinder')
      end

      it 'has proper modes' do
        expect(sprintf('%o', dir.mode)).to eq '700'
      end
    end
  end
end

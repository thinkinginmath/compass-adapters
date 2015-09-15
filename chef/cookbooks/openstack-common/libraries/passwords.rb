# encoding: UTF-8

#
# Cookbook Name:: openstack-common
# library:: passwords
#
# Copyright 2012-2013, AT&T Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module ::Openstack # rubocop:disable Documentation
  # Library routine that returns an encrypted data bag value
  # for a supplied string. The key used in decrypting the
  # encrypted value should be located at
  # node['openstack']['secret']['key_path'].
  #
  # Note that if node['openstack']['developer_mode'] is true,
  # then the value of the index parameter is just returned as-is. This
  # means that in developer mode, if a cookbook does this:
  #
  # class Chef
  #   class Recipe
  #     include ::Openstack
  #    end
  # end
  #
  # nova_password = secret 'passwords', 'nova'
  #
  # That means nova_password will == 'nova'.
  #
  # You also can provide a default password value in developer mode,
  # like following:
  #
  # node.set['openstack']['secret']['nova'] = 'nova_password'
  # nova_password = secret 'passwords', 'nova'
  #
  # The nova_password will == 'nova_password'
  def secret(bag_name, index, password = nil)
    return (node['openstack']['secret'][index] || password || index) if node['openstack']['developer_mode']
    key_path = node['openstack']['secret']['key_path']
    ::Chef::Log.info "Loading encrypted databag #{bag_name}.#{index} using key at #{key_path}"
    secret = ::Chef::EncryptedDataBagItem.load_secret key_path
    ::Chef::EncryptedDataBagItem.load(bag_name, index, secret)[index]
  end

  # Ease-of-use/standarization routine that returns a secret from the
  # attribute-specified openstack secrets databag.
  def get_secret(key)
    secret node['openstack']['secret']['secrets_data_bag'], key
  end

  # Ease-of-use/standarization routine that returns a service/database/user
  # password for a named OpenStack service/database/user. Accepts 'user',
  # 'service' or 'db' as the type.
  def get_password(type, key, password = nil)
    if ['db', 'user', 'service'].include?(type)
      secret node['openstack']['secret']["#{type}_passwords_data_bag"], key, password
    else
      ::Chef::Log.error("Unsupported type for get_password: #{type}")
    end
  end
end

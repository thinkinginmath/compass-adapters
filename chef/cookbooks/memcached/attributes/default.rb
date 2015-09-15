#
# Cookbook Name:: memcached
# Attributes:: default
#
# Copyright 2009-2013, Opscode, Inc.
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

default['memcached']['memory'] = (node['memory']['total'].to_i/1024/3) < 8192 ? node['memory']['total'].to_i/1024/3 : 8192
default['memcached']['port'] = 11211
default['memcached']['udp_port'] = 11211
default['memcached']['listen'] = '0.0.0.0'
default['memcached']['bind_interface'] = nil
default['memcached']['maxconn'] = 4096
default['memcached']['max_object_size'] = '1m'
default['memcached']['logfilename'] = 'memcached.log'

case node['platform_family']
when 'suse', 'fedora', 'rhel'
  default['memcached']['user'] = 'memcached'
  default['memcached']['group'] = 'memcached'
when 'ubuntu'
  default['memcached']['user'] = 'memcache'
  default['memcached']['group'] = 'memcache'
when 'debian'
  default['memcached']['user'] = 'nobody'
  default['memcached']['group'] = 'nogroup'
else
  default['memcached']['user'] = 'nobody'
  default['memcached']['user'] = 'nogroup'
end

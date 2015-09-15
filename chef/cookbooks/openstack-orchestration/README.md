Description
===========

This cookbook installs the OpenStack Heat service **Heat** as part of an OpenStack reference deployment Chef for OpenStack.

http://heat.openstack.org/

Requirements
============

Chef 11 or higher required (for Chef environment use).

Cookbooks
---------

The following cookbooks are dependencies:

* openstack-common
* openstack-identity

Usage
=====

api
------
- Configure and start heat-api service

api-cfn
------
- Configure and start heat-api-cfn service

api-cloudwatch
------
- Configure and start heat-api-cloudwatch service

client
----
- Install the heat client packages

common
------
- Installs the heat packages and setup configuration for Heat.

engine
------
- Setup the heat database and start heat-engine service

identity_registration
---------------------
- Registers the Heat API endpoint, heat service and user

Attributes
==========

Attributes for the Heat service are in the ['openstack']['orchestration'] namespace.

* `openstack['orchestration']['verbose']` - Enables/disables verbose output for heat services.
* `openstack['orchestration']['debug']` - Enables/disables debug output for heat services.
* `openstack['orchestration']['identity_service_chef_role']` - The name of the Chef role that installs the Keystone Service API
* `openstack['orchestration']['rabbit_server_chef_role']` - The name of the Chef role that knows about the message queue server
* `openstack['orchestration']['user']` - User heat runs as
* `openstack['orchestration']['group']` - Group heat runs as
* `openstack['orchestration']['db']['username']` - Username for heat database access
* `openstack['orchestration']['api']['adminURL']` - Used when registering heat endpoint with keystone
* `openstack['orchestration']['api']['internalURL']` - Used when registering heat endpoint with keystone
* `openstack['orchestration']['api']['publicURL']` - Used when registering heat endpoint with keystone
* `openstack['orchestration']['service_tenant_name']` - Tenant name used by heat when interacting with keystone - used in the API and registry paste.ini files
* `openstack['orchestration']['service_user']` - User name used by heat when interacting with keystone - used in the API and registry paste.ini files
* `openstack['orchestration']['service_role']` - User role used by heat when interacting with keystone - used in the API and registry paste.ini files
* `openstack['orchestration']['api']['auth']['cache_dir']` - Defaults to `/var/cache/heat`. Directory where `auth_token` middleware writes certificates for heat
* `openstack['orchestration']['syslog']['use']` - Should heat log to syslog?
* `openstack['orchestration']['syslog']['facility']` - Which facility heat should use when logging in python style (for example, `LOG_LOCAL1`)
* `openstack['orchestration']['syslog']['config_facility']` - Which facility heat should use when logging in rsyslog style (for example, local1)
* `openstack['orchestration']['rpc_thread_pool_size']` - size of RPC thread pool
* `openstack['orchestration']['rpc_conn_pool_size']` - size of RPC connection pool
* `openstack['orchestration']['rpc_response_timeout']` - seconds to wait for a response from call or multicall
* `openstack['orchestration']['platform']` - hash of platform specific package/service names and options
* `openstack['orchestration']['api']['auth']['version']` - Select v2.0 or v3.0. Default v2.0. The auth API version used to interact with identity service.

Notification definitions
------------------------
* `openstack['orchestration']['notification_driver']` - driver
* `openstack['orchestration']['default_notification_level']` - level
* `openstack['orchestration']['default_publisher_id']` - publisher id
* `openstack['orchestration']['list_notifier_drivers']` - list of drivers
* `openstack['orchestration']['notification_topics']` - notifications topics

MQ attributes
-------------
* `openstack["orchestration"]["mq"]["service_type"]` - Select qpid or rabbitmq. default rabbitmq
TODO: move rabbit parameters under openstack["orchestration"]["mq"]
* `openstack["orchestration"]["rabbit"]["username"]` - Username for nova rabbit access
* `openstack["orchestration"]["rabbit"]["vhost"]` - The rabbit vhost to use
* `openstack["orchestration"]["rabbit"]["port"]` - The rabbit port to use
* `openstack["orchestration"]["rabbit"]["host"]` - The rabbit host to use (must set when `openstack["orchestration"]["rabbit"]["ha"]` false).
* `openstack["orchestration"]["rabbit"]["ha"]` - Whether or not to use rabbit ha

* `openstack["orchestration"]["mq"]["qpid"]["host"]` - The qpid host to use
* `openstack["orchestration"]["mq"]["qpid"]["port"]` - The qpid port to use
* `openstack["orchestration"]["mq"]["qpid"]["qpid_hosts"]` - Qpid hosts. TODO. use only when ha is specified.
* `openstack["orchestration"]["mq"]["qpid"]["username"]` - Username for qpid connection
* `openstack["orchestration"]["mq"]["qpid"]["password"]` - Password for qpid connection
* `openstack["orchestration"]["mq"]["qpid"]["sasl_mechanisms"]` - Space separated list of SASL mechanisms to use for auth
* `openstack["orchestration"]["mq"]["qpid"]["reconnect_timeout"]` - The number of seconds to wait before deciding that a reconnect attempt has failed.
* `openstack["orchestration"]["mq"]["qpid"]["reconnect_limit"]` - The limit for the number of times to reconnect before considering the connection to be failed.
* `openstack["orchestration"]["mq"]["qpid"]["reconnect_interval_min"]` - Minimum number of seconds between connection attempts.
* `openstack["orchestration"]["mq"]["qpid"]["reconnect_interval_max"]` - Maximum number of seconds between connection attempts.
* `openstack["orchestration"]["mq"]["qpid"]["reconnect_interval"]` - Equivalent to setting qpid_reconnect_interval_min and qpid_reconnect_interval_max to the same value.
* `openstack["orchestration"]["mq"]["qpid"]["heartbeat"]` - Seconds between heartbeat messages sent to ensure that the connection is still alive.
* `openstack["orchestration"]["mq"]["qpid"]["protocol"]` - Protocol to use. Default tcp.
* `openstack["orchestration"]["mq"]["qpid"]["tcp_nodelay"]` - Disable the Nagle algorithm. default disabled.

The following attributes are defined in attributes/default.rb of the common cookbook, but are documented here due to their relevance:

* `openstack['endpoints']['orchestration-api-bind']['host']` - The IP address to bind the service to
* `openstack['endpoints']['orchestration-api-bind']['port']` - The port to bind the service to
* `openstack['endpoints']['orchestration-api-bind']['bind_interface']` - The interface name to bind the service to

* `openstack['endpoints']['orchestration-api-cfn-bind']['host']` - The IP address to bind the service to
* `openstack['endpoints']['orchestration-api-cfn-bind']['port']` - The port to bind the service to
* `openstack['endpoints']['orchestration-api-cfn-bind']['bind_interface']` - The interface name to bind the-cfn service to

* `openstack['endpoints']['orchestration-api-cloudwatch-bind']['host']` - The IP address to bind the service to
* `openstack['endpoints']['orchestration-api-cloudwatch-bind']['port']` - The port to bind the service to
* `openstack['endpoints']['orchestration-api-cloudwatch-bind']['bind_interface']` - The interface name to bind the-cloudwatch service to

If the value of the 'bind_interface' attribute is non-nil, then the service will be bound to the first IP address on that interface. If the value of the 'bind_interface' attribute is nil, then the service will be bound to the IP address specifie>

Testing
=====

Please refer to the [TESTING.md](TESTING.md) for instructions for testing the cookbook.

License and Author
==================

|                      |                                                    |
|:---------------------|:---------------------------------------------------|
| **Author**           |  Zhao Fang Han (<hanzhf@cn.ibm.com>)               |
| **Author**           |  Chen Zhiwei (<zhiwchen@cn.ibm.com>)               |
|                      |                                                    |
| **Copyright**        |  Copyright (c) 2013-2014, IBM Corp.                |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

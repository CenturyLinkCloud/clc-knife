[![Build Status](https://travis-ci.org/CenturyLinkCloud/clc-knife.svg?branch=master)](https://travis-ci.org/CenturyLinkCloud/clc-knife)
[![Gem Version](https://badge.fury.io/rb/knife-clc.svg)](https://badge.fury.io/rb/knife-clc)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)

# Knife CLC

This is the Chef Knife plugin for CenturyLink Cloud. It gives Knife the ability to manage servers and query for additional resources like data centers, templates and groups.

## Requirements

## Installation

There are three ways to install the Chef Knife plugin on your CenturyLink Cloud platform.

### If you're using [ChefDK](https://downloads.chef.io/chef-dk/):

* Install the Gem:

```
bash
$ chef gem install knife-clc
```

### If you're using Bundler:

1. Add this line to your application's Gemfile:

```
ruby
gem 'knife-clc'
```

2. Then, execute:

```
bash
$ bundle
```

### If you're installing it yourself:

* Run:

```
$ gem install knife-clc
```

## Configuration

In order to use the CLC API, which runs the Chef Knife plugin, a user must supply an API username & password. This can be done in several ways.

### knife.rb
Credentials can be specified in the [knife.rb](https://docs.chef.io/config_rb_knife.html) file:

```
ruby
knife[:clc_username] = "CLC API Username"
knife[:clc_password] = "CLC API Password"
```

**Note:** If your `knife.rb` file will be checked into a source control management system, or will be otherwise accessible by others, you may want to use one of the other configuration methods to avoid exposing your credentials.

### ENV & knife.rb
It is also possible to specify credentials as environment (ENV) variables. Here's an example:

```
ruby
knife[:clc_username] = ENV['CLC_USERNAME']
knife[:clc_password] = ENV['CLC_PASSWORD']
```

**Note:** Since most CLC tools use the same set of ENV variables, the plugin would read the `CLC_USERNAME` and `CLC_PASSWORD` variables automatically if no other options were specified in `knife.rb`.

### CLI Arguments
If you prefer to specify credentials on a per-command basis, you can do it with CLI arguments:

```
bash
$ knife clc datacenter list \
--username 'api_username' \
--password 'api_password'
```

## Advanced Configuration
In order to speed up your workflow, you can specify some defaults for every command option in `knife.rb`.

**Note:** Since `knife.rb` is basically a Ruby file, we use `snake_case` notation. Also, we prefix CLC options with `clc_`. For example, `--source-server` turns into `clc_source_server`.

```
ruby
knife[:clc_name] = 'QAEnv'
knife[:clc_description] = 'Automatic UI testing node'
knife[:clc_group] = '675b79g94b84122ea1c920111967a33c'
knife[:clc_source_server] = 'DEBIAN-7-64-TEMPLATE'
knife[:clc_cpu] = 2
knife[:clc_memory] = 2
```
Options like `--disk`, `--custom-field`, `--package` can be specified several times. In the configuration file they will look like an Array with a plural config option name. For example:

```
ruby
knife[:clc_custom_fields] = [
  'KEY=VALUE',
  'ANOTHER=VALUE'
]

knife[:clc_disks] = [
  '/dev/sdb,10,raw'
]
```

## Supported Commands
This plugin provides the following Knife subcommands.

Specific command options can be found by invoking the subcommand with a `--help` flag.

* [knife clc datacenter list (options)](#knife-clc-datacenter-list)
* [knife clc group create (options)](#knife-clc-group-create)
* [knife clc group list (options)](#knife-clc-group-list)
* [knife clc ip create (options)](#knife-clc-ip-create)
* [knife clc ip delete IP (options)](#knife-clc-ip-delete)
* [knife clc operation show ID (options)](#knife-clc-operation-show)
* [knife clc server create (options)](#knife-clc-server-create)
* [knife clc server delete ID (options)](#knife-clc-server-delete)
* [knife clc server list (options)](#knife-clc-server-list)
* [knife clc server power_off ID (options)](#knife-clc-server-power_off)
* [knife clc server power_on ID (options)](#knife-clc-server-power_on)
* [knife clc server reboot ID (options)](#knife-clc-server-reboot)
* [knife clc server show ID (options)](#knife-clc-server-show)
* [knife clc template list (options)](#knife-clc-template-list)

**Note:** Some commands provide access to long-running cloud operations. These commands are **asynchronous** by default (they don't wait for the operation to complete before continuing their work and they don't return an output immediately). All of them support the `--wait` option, which makes the command pause until the operation either completes or fails.

Several types of resources are scoped by the datacenter they reside in. Commands querying for these resources support the `--datacenter ID` option, which returns resources for a specific data center. Some of the commands support the `--all` option, which returns all resources from all data centers (this command is much slower).

Also, resources like IP addresses are scoped by the server they belong to. The related commands require the `--server ID` option.

### `knife clc datacenter list`
Outputs a list of all available CLC data centers.

```
bash
$ knife clc datacenter list
```

### `knife clc group create`
Creates a child group for a specified parent. Unlike other modification operations, this command is synchronous and does not support the `--wait` flag.

```
bash
$ knife clc group create --name 'Custom Group' \
--description 'Manual Test Group' \
--parent bcda7f994b844521111920325qrta33c
```

### `knife clc group list`
**Scoped by datacenter**. Outputs a list of datacenter groups. By default, it reflects a logical group structure as a tree. Supports the `--view` option with the values `table` and `tree`.

```
$ knife clc group list --datacenter ca1 --view table
```

### `knife clc ip create`
**Asynchronous**. **Scoped by server**. Assigns a public IP to a specified server. Applies the passes protocol and source restrictions. While the CLC API supports TCP, UDP and ICMP permissions only, this command provides several useful aliases to the most frequently used protocols: `ssh`, `sftp`, `ftp`, `http`, `https`, `ftp`, and `ftps`. These same options can be provided during server creation.

```
bash
$ knife clc ip create --server ca1altdqasrv01 \
--allow tcp:66-67 \
--allow udp:68 \
--allow icmp \
--allow ssh \
--allow http \
--allow ftp \
--source 10.0.0.0/32 \
--source 172.0.0.0/32 \
--wait
```

### `knife clc ip delete`
**Asynchronous**. **Scoped by server**. Deletes a previously assigned public IP of a server.

```
bash
$ knife clc ip delete 65.39.184.23 --server ca1altdqasrv01 --wait
```

### `knife clc operation show`
**Asynchronous**. Outputs the current operation status. User can use the `--wait` flag to wait for operation completion. Operation IDs are usually printed by other asynchronous commands when they are executed without the `--wait` option.

```
bash
$ knife clc operation show ca1-43089 --wait
```

### `knife clc server create`
**Asynchronous**. Launches a server using specified parameters. It is recommended to allow SSH/RDP access to the server if the user plans to use it from an external network later.

```
bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--allow icmp \
--allow ssh \
--wait
```

#### Bootstrap flag
This command supports the `--bootstrap` flag, which allows the launched machine to connect to your Chef Server installation. Only the **Linux** platform is supported.

The Async bootstrap variant does not require public IP access to the machine. Chef Server credentials and other parameters will be sent to the server. They will be used by the Chef Client installation script during launch.

**Note:** Bootstrapping errors will cancel a launch operation.

```
bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--bootstrap \
--run-list recipe[chef-client] \
--tags one,two,three
```

The Sync bootstrap variant is very similar to the bootstrap used in other Knife plugins. It requires an SSH connection to the server.

**Note:** The plugin will refuse to launch a server unless a public IP with SSH access is requested.

Example for custom SSH port:

```
bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--allow tcp:55 \
--bootstrap \
--ssh-port 55 \
--run-list recipe[chef-client] \
--tags one,two,three \
--no-host-key-verify \
--wait
```

It is also possible to bootstrap a machine without using a public IP address. A machine with open SSH access that belongs to the same network can be used as an SSH gateway via the `--ssh-gateway` option. Users can also  run the Knife plugin inside of the network with the `--bootstrap-private` flag to bypass public IP checks.

```
bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--bootstrap \
--bootstrap-private \
--run-list recipe[chef-client] \
--tags one,two,three \
--no-host-key-verify \
--wait
```

### `knife clc server delete`
**Asynchronous**. Deletes an existing server by its ID. Note that all Chef Server objects (if there are any) are left intact after the deletion.

```
bash
$ knife clc server delete ca1altdqasrv01 --wait
```

### `knife clc server list`
**Scoped by datacenter**. Outputs a list of all servers in a specified datacenter. This also supports `--all` option (which returns a list of servers in all datacenters).

Can be used with the  `--chef-nodes` option to add a `Chef Node` column. The node names of servers managed by Chef Server will appear in the `Chef Node` column.

**Note:** Chef API credentials are required for this operation to work.

```
bash
$ knife clc server list --datacenter ca1 --chef-nodes
```

### `knife clc server power_off`
**Asynchronous**. Turns the server power off.

**Note:** All SSH/RDP sessions will be forcibly closed when this command runs.

```
bash
$ knife clc server power_off ca1altdqasrv01 --wait
```

### `knife clc server power_on`
**Asynchronous**. Turns the server power on. The server will be available for connections after this operation is complete.

```
bash
$ knife clc server power_off ca1altdqasrv01 --wait
```

### `knife clc server reboot`
**Asynchronous**. Performs an OS-level reboot on the server.

**Note:** All applications that are running will finish the current task and then close.

```
bash
$ knife clc server reboot ca1altdqasrv01 --wait
```

### `knife clc server show`
Outputs details for a specified server ID. This command supports the `--uuid` flag, which interprets the primary argument as a UUID (instead of a server ID). By default, the output does not show server credentials or opened ports. Users may request more information with the `--creds` and `--ports` options.

**Note:** Requesting additional information will slow this command down.

```
bash
$ knife clc server show 406282c5116443029576a2b9ac56f5cc \
--uuid \
--creds

$ knife clc server show ca1altdqasrv01 --ports
```

### `knife clc template list`
**Scoped by datacenter**. Outputs available server templates in a specified datacenter. Supports the `--all` option, which returns a list of templates from all datacenters.

```
bash
$ knife clc template list --datacenter ca1
```

## Contributing

1. Fork it [https://github.com/CenturyLinkCloud/clc-knife/fork](https://github.com/CenturyLinkCloud/clc-knife/fork)
2. Create your feature branch `git checkout -b my-new-feature`
3. Commit your changes `git commit -am 'Add some feature'`
4. Push to the branch `git push origin my-new-feature`
5. Create a new Pull Request
6. Specs and Code Style checks should pass before Code Review.

## FAQs



## License
The project is licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0.html).

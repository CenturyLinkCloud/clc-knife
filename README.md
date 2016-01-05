[![Build Status](https://travis-ci.com/CenturyLinkCloud/clc-knife.svg?branch=master&token=LhLVx9NS1UaceLVeEbZK)](https://travis-ci.com/CenturyLinkCloud/clc-knife)

# Knife CLC

This is the Chef Knife plugin for CenturyLink Cloud. It gives Knife the ability to manage servers and query for additional resources like datacenters, templates and groups.

## Installation

If you're using [ChefDK](https://downloads.chef.io/chef-dk/), simply install the Gem:

```bash
$ chef gem install knife-clc
```

If you're using Bundler, add this line to your application's Gemfile:

```ruby
gem 'knife-clc'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```
$ gem install knife-clc
```

## Configuration
In order to use CLC API, user must supply API username & password. This can be done in several ways:

### knife.rb
Credentials can be specified in [knife.rb](https://docs.chef.io/config_rb_knife.html) file:

```ruby
knife[:clc_username] = "CLC API Username"
knife[:clc_password] = "CLC API Password"
```

Note: If your `knife.rb` file will be checked into a source control management system, or will be otherwise accessible by others, you may want to use one of the other configuration methods to avoid exposing your credentials.

### ENV & knife.rb
It is also possible to specify credentials as environment variables. Here's an example:

```ruby
knife[:clc_username] = ENV['CLC_USERNAME']
knife[:clc_password] = ENV['CLC_PASSWORD']
```

Note that since most CLC tools use the same set of ENV variables, plugin would read `CLC_USERNAME` and `CLC_PASSWORD` variables automatically if no other options were specified in `knife.rb`.

### CLI Arguments
If you prefer to specify credentials on per-command basis, you can do it with CLI arguments:

```bash
$ knife clc datacenter list \
--username 'api_username' \ 
--password 'api_password'
```

## Advanced Configuration
In order to speed up your workflow, you can specify some defaults for every command option in `knife.rb`. Since `knife.rb` is basically a Ruby file, we use `snake_case` notation there. Also, we prefix CLC options with `clc_`. It means that `--source-server` turns into `clc_source_server`:

```ruby
knife[:clc_name] = 'QAEnv'
knife[:clc_description] = 'Automatic UI testing node'
knife[:clc_group] = '675b79g94b84122ea1c920111967a33c'
knife[:clc_source_server] = 'DEBIAN-7-64-TEMPLATE'
knife[:clc_cpu] = 2
knife[:clc_memory] = 2
```
Options like `--disk`, `--custom-field`, `--package` can be specified several times. In configuration file they will look like an Array with plural config option name:

```ruby
knife[:clc_custom_fields] = [
  'KEY=VALUE', 
  'ANOTHER=VALUE'
]

knife[:clc_disks] = [
  '/dev/sdb,10,raw'
]
```

## Supported Commands
This plugin provides the following Knife subcommands. Specific command options can be found by invoking the subcommand with a `--help` flag:

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

Note that some commands provide an access to long-running cloud operations. These commands are **asynchronous** by default (they don't wait for completion and return some output immediately). All of them support `--wait` option which makes command to wait until operation is completed or failed.

Several types of resources are **scoped by datacenter** they reside in. Commands querying for these resources support `--datacenter ID` option. Some of them support `--all` option to return all resources from all datacenters (which is much slower).

Also, resources like ip addresses are **scoped by server** they belong to. Related commands require `--server ID` option.

### `knife clc datacenter list`
Outputs list of all available CLC datacenters.

```bash
$ knife clc datacenter list
```

### `knife clc group create`
Creates a child group for specified parent. Unlike other modification operations, that command is synchronous and does not support `--wait` flag.

```bash
$ knife clc group create --name 'Custom Group' \
--description 'Manual Test Group' \
--parent bcda7f994b844521111920325qrta33c
```

### `knife clc group list`
**Scoped by datacenter**. Outputs list of datacenter groups. By default, reflects logical group structure as a tree. Supports `--view` option with values `table` and `tree`.

```
$ knife clc group list --datacenter ca1 --view table
```

### `knife clc ip create`
**Asynchronous**. **Scoped by server**. Assigns a public IP to specified server. Applies passes protocol and source restrictions. While CLC API supports TCP, UDP and ICMP permissions only, this command provides several useful aliases to most ofthen used protocols: `ssh`, `sftp`, `ftp`, `http`, `https`, `ftp`, `ftps`. Same options can be provided during server creation.

```bash
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
**Asynchronous**. **Scoped by server**. Deletes previously assigned public IP of the server.

```bash
$ knife clc ip delete 65.39.184.23 --server ca1altdqasrv01 --wait
```

### `knife clc operation show`
**Asynchronous**. Outputs current operation status. User can use `--wait` flag to wait for operation completion. Operation IDs are usually printed by other asynchronous commands when they are executed without `--wait` option.

```bash
$ knife clc operation show ca1-43089 --wait
```

### `knife clc server create`
**Asynchronous**. Launches a server using specified parameters. It is recommended to allow SSH/RDP access to the server if user plans to use it from external network later.

```bash
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

Command supports `--bootstrap` flag which allows to connect launched machine to your Chef Server installation. Only **Linux** platform is supported.

Async bootstrap variant does not require public IP access to the machine. Chef Server credentials and other parameters will be sent to the server for execution during server launch. Note, that bootstrapping errors cancel launch operation.

```bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--bootstrap
```

Sync bootstrap is very similar to bootstrap from other Knife plugins. It requires SSH connection to the server. Note, that plugin will refuse to launch a server unless public IP with SSH access is requested. Example for custom SSH port:

```bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--allow tcp:55 \
--ssh-port 55 \
--wait
```

There might be several cases when bootstrap is intended to be run from the private network. If there's a machine with opened SSH access and it belongs to the same network, it can be used as a SSH gateway via `--ssh-gateway` option. Another way is to run Knife plugin inside of the network with `--bootstrap-private` flag to skip public IP checks.

```bash
$ knife clc server create --name 'QASrv' \
--group 675b79g94b84122ea1c920111967a33c \
--source-server DEBIAN-7-64-TEMPLATE \
--cpu 1 \
--memory 1 \
--type standard \
--bootstrap
--bootstrap-private
--wait
```

### `knife clc server delete`
**Asynchronous**. Deletes an existing server by its ID. Note that Chef Server objects (if there are any) are left intact.

```bash
$ knife clc server delete ca1altdqasrv01 --wait
```

### `knife clc server list`
**Scoped by datacenter**. Outputs a list of all servers in specified datacenter. Can be used with `--chef-nodes` option to add `Chef Node` column. Servers managed by Chef Server will have their node names there. Note that Chef API credentials are required for this to work. Supports `--all` option.

```bash
$ knife clc server list --datacenter ca1 --chef-nodes
```

### `knife clc server power_off`
**Asynchronous**. Turns server power off. Note that all SSH/RDP sessions will be forcibly closed.

```bash
$ knife clc server power_off ca1altdqasrv01 --wait
```

### `knife clc server power_on`
**Asynchronous**. Turns server power on. The server will be available for connections after operation is completed.

```bash
$ knife clc server power_off ca1altdqasrv01 --wait
```

### `knife clc server reboot`
**Asynchronous**. Performs OS-level reboot on the server. All applications will be requested to finish current tasks and close.

```bash
$ knife clc server reboot ca1altdqasrv01 --wait
```

### `knife clc server show`
Outputs details for specified server ID. Supports `--uuid` flag to interpret primary argument as UUID. By default, does not show server credentials and opened ports. User may request more information with `--creds` and `--ports` options. Requesting additional information slows command down.

```bash
$ knife clc server show 406282c5116443029576a2b9ac56f5cc \
--uuid \ 
--creds

$ knife clc server show ca1altdqasrv01 --ports
```

### `knife clc template list`
**Scoped by datacenter**. Outputs available server templates. Supports `--all` option.

```bash
$ knife clc template list --datacenter ca1
```

## Contributing

1. Fork it [https://github.com/CenturyLinkCloud/clc-knife/fork](https://github.com/CenturyLinkCloud/clc-knife/fork)
2. Create your feature branch `git checkout -b my-new-feature`
3. Commit your changes `git commit -am 'Add some feature'`
4. Push to the branch `git push origin my-new-feature`
5. Create a new Pull Request
6. Specs and Code Style checks should pass before Code Review.

## License
The project is licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0.html).
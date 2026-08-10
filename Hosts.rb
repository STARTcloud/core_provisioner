# coding: utf-8
# Load the CoreProvisioner Version Module
require File.expand_path("#{File.dirname(__FILE__)}/version.rb")
require 'open3'
require 'yaml'
require 'fileutils'


if File.file?("#{File.dirname(__FILE__)}/../version.rb")
  # Load the Current Provisioner Version Module
  require File.expand_path("#{File.dirname(__FILE__)}/../version.rb")
end

# This class takes the Hosts.yaml and set's the neccessary variables to run provider specific sequences to boot a VM.
class Hosts
  def Hosts.configure(config, settings)
    secrets = Hosts.load_secrets

    ENV['ATLAS_TOKEN'] = secrets['ATLAS_TOKEN'] if secrets && secrets.key?('ATLAS_TOKEN')

    # Main loop to configure VM
    settings['hosts'].each_with_index do |host, index|

      ENV['VAGRANT_NO_PARALLEL'] = 'yes'
      if host['settings'].has_key?('parallel') && host['settings']['parallel']
        ENV['VAGRANT_NO_PARALLEL'] = 'no'
      end

      ENV['VAGRANT_SERVER_URL'] = host['settings']['box_url'] if host['settings'].has_key?('box_url')

      provider = host['settings']['provider_type']
      machine_domain = host['settings']['machine_domain'] || host['settings']['domain']

      config.vm.provider provider

      config.vm.define "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}" do |server|
        server.vm.box = host['settings']['box']
        config.vm.box_url = host['settings']['box_url'].to_s.empty? ? "https://vagrantcloud.com/#{host['settings']['box']}" : "#{host['settings']['box_url']}/#{host['settings']['box']}"
        server.vm.box_version = host['settings']['box_version']
        config.vm.box_architecture = host['settings']['box_arch']
        server.vm.boot_timeout = host['settings']['setup_wait']
        server.ssh.username = host['settings']['vagrant_user']
        config.vm.ignore_box_vagrantfile = host['settings'].key?('vagrant_ignore_box_vagrantfile') ? host['settings']['vagrant_ignore_box_vagrantfile'] : true
        #server.ssh.password = host['settings']['vagrant_user_pass']
        default_ssh_key = File.join(File.dirname(__FILE__), 'ssh_keys', 'id_rsa')
        vagrant_ssh_key = host['settings']['vagrant_user_private_key_path']
        server.ssh.private_key_path = File.exist?(vagrant_ssh_key) ? [vagrant_ssh_key, default_ssh_key] : default_ssh_key
        server.ssh.insert_key = false # host['settings']['vagrant_ssh_insert_key'], Note we are no longer automatically forcing the key in via Vagrants SSH insertion function
        server.ssh.forward_agent = host['settings']['vagrant_ssh_forward_agent']
        server.ssh.keep_alive = host['settings'].key?('vagrant_ssh_keep_alive') ? host['settings']['vagrant_ssh_keep_alive'] : true
        config.vm.communicator = host['settings'].key?('vagrant_communicator') ? host['settings']['vagrant_communicator'].to_sym : :ssh
        config.winrm.username = host['settings']['vagrant_user']
        config.winrm.password = host['settings']['vagrant_user_pass']
        config.winrm.port = host['settings'].key?('vagrant_winrm_port') ? host['settings']['vagrant_winrm_port'] :  5986
        config.winrm.transport = host['settings'].key?('vagrant_winrm_transport') ? host['settings']['vagrant_winrm_transport'].to_sym : :ssl
        config.winssh.shell = host['settings'].key?('vagrant_winssh_shell') ? host['settings']['vagrant_winssh_shell'] : "powershell"
        config.vm.guest = Hosts.get_vagrant_guest_type(host['settings']['os_type'] || 'linux')
        config.winrm.timeout = host['settings']['setup_wait']
        config.winrm.retry_delay = host['settings'].key?('vagrant_winrm_retry_delay') ? host['settings']['vagrant_winrm_retry_delay'] :  30
        config.winrm.retry_limit = host['settings'].key?('vagrant_winrm_retry_limit') ? host['settings']['vagrant_winrm_retry_limit'] :  1000
        config.winrm.ssl_peer_verification = host['settings'].key?('vagrant_winrm_ssl_peer_verification') ? host['settings']['vagrant_winrm_ssl_peer_verification'] :  false

        if Vagrant::Util::Platform.windows?  || Vagrant::Util::Platform.cygwin? || Vagrant::Util::Platform.wsl?
          path_VBoxManage = "VBoxManage.exe"
        elsif Vagrant::Util::Platform.darwin? || Vagrant::Util::Platform.linux?  || Vagrant::Util::Platform.bsd? || Vagrant::Util::Platform.solaris?
          path_VBoxManage = "VBoxManage"
        end

        ## Networking
        ## For every Network block in Hosts.yml, and if its not empty
        if host.has_key?('networks') and !host['networks'].empty?
          ## This tells Virtualbox to set the Nat network so that we can avoid IP conflicts and more easily identify networks
          ## This Nic cannot be removed which is why its not in the loop below
          #config.vm.provider "virtualbox" do |network_provider|
          #  # https://github.com/Moonshine-IDE/Super.Human.Installer/issues/116
          #  network_provider.customize ['modifyvm', :id, '--natnet1', '10.244.244.0/24']
          #end

          ## Loop over each block, with an index so that we can use the ordering to specify interface number
          host['networks'].each_with_index do |network, netindex|
              ## Get the bridge device the user specifies, if none selected, we need to try our best to get the best one (for every OS: Mac, Windows, and Linux)
              bridge = network['bridge'] if defined?(network['bridge'])
              if bridge.nil? && (provider == 'virtualbox' || provider == 'utm')
                bridge = get_bridge_interface(path_VBoxManage)
                # For UTM on Mac, use only the part before the first colon
                if provider == 'utm' && Vagrant::Util::Platform.darwin? && bridge && bridge.include?(':')
                  bridge = bridge.split(':').first
                end
              end

              ## We then take those variables, and hopefully have the best connection to use and then pass it to vagrant so it can create the network adapters.
              if network['type'] == 'host'
                server.vm.network "private_network",
                  bridge: network['bridge'],
                  ip: network['address'],
                  gateway: network['gateway'],
                  netmask: network['netmask'],
                  type: 'dhcp',
                  dhcp: network['dhcp4'],
                  dhcp4: network['dhcp4'],
                  dhcp6: network['dhcp6'],
                  auto_config: network['autoconf'],
                  mac: provider == 'virtualbox' ? network['mac'].tr(':', '') : network['mac'],
                  nic_type: network['nic_type'],
                  nictype: network['type'],
                  nic_number: netindex,
                  managed: network['is_control'],
                  vlan: network['vlan'],
                  dns: network['dns'],
                  provisional: network['provisional'],
                  route: network['route'],
                  etherstub: network['etherstub']
                  #name: 'core_provisioner_network'
              end
              if network['type'] == 'external'
                server.vm.network "public_network",
                  bridge: bridge,
                  ip: network['address'],
                  gateway: network['gateway'],
                  netmask: network['netmask'],
                  dhcp: network['dhcp4'],
                  dhcp4: network['dhcp4'],
                  dhcp6: network['dhcp6'],
                  auto_config: network['autoconf'],
                  mac: provider == 'virtualbox' ? network['mac'].tr(':', '') : network['mac'],
                  nic_type: network['nic_type'],
                  nictype: network['type'],
                  nic_number: netindex,
                  managed: network['is_control'],
                  vlan: network['vlan'],
                  dns: network['dns'],
                  provisional: network['provisional'],
                  route: network['route'],
                  etherstub: network['etherstub']
              end
          end
        end

        ##### Begin Virtualbox Configurations #####
        # Save MAC addresses after VM is created and update Hosts.yml if needed
        config.trigger.after :up do |trigger|
          trigger.info = "Checking and updating network interface MAC addresses in Hosts.yml..."
          trigger.ruby do |env, machine|
            # Only run this for VirtualBox provider
            if host['settings']['provider_type'] == 'virtualbox'
              vm_name = "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}"

              # Get VM info from VirtualBox
              vm_info = `#{path_VBoxManage} showvminfo "#{vm_name}" --machinereadable`

              # Extract MAC addresses for each adapter
              mac_addresses = {}
              vm_info.scan(/macaddress(\d+)="(.+?)"/).each do |adapter_num, mac|
                mac_addresses[adapter_num.to_i] = mac.upcase
              end

              # Check if we need to update Hosts.yml
              hosts_yml_path = File.join(Dir.pwd, 'Hosts.yml')
              if File.exist?(hosts_yml_path)
                # Read the file line by line
                lines = File.readlines(hosts_yml_path)

                # Track if we're in the right host section
                in_current_host = false
                in_networks = false
                current_network_index = -1
                needs_update = false

                # Process each line
                lines.each_with_index do |line, i|
                  # Check if we're entering a host section
                  if line.strip == '-' && lines[i+1] && lines[i+1].strip.start_with?('settings:')
                    in_current_host = false
                    in_networks = false
                    current_network_index = -1
                  end

                  # Check if we're in the settings section of the current host
                  if !in_current_host && line.strip.start_with?('hostname:') && line.include?(host['settings']['hostname'])
                    in_current_host = true
                  end

                  # Check if we're entering the networks section of the current host
                  if in_current_host && line.strip == 'networks:'
                    in_networks = true
                    current_network_index = -1
                  end

                  # Check if we're starting a new network entry
                  if in_networks && line.strip == '-'
                    current_network_index += 1
                  end

                  # Check if this line contains a MAC address set to 'auto'
                  if in_networks && current_network_index >= 0 && line.strip.start_with?('mac:') && (line.include?('auto') || line.strip == 'mac:')
                    adapter_num = current_network_index + 2  # +2 because adapter 1 is NAT
                    if mac_addresses.has_key?(adapter_num)
                      formatted_mac = mac_addresses[adapter_num].scan(/../).join(':')
                      indent = line[/\A\s*/]
                      lines[i] = "#{indent}mac: #{formatted_mac}\n"
                      needs_update = true
                      puts "Updated MAC address for network #{current_network_index} to #{formatted_mac}"
                    end
                  end
                end

                # Write updated Hosts.yml if changes were made
                if needs_update
                  File.open(hosts_yml_path, 'w') do |file|
                    file.write(lines.join)
                  end
                  puts "Updated Hosts.yml with actual MAC addresses while preserving comments"
                end
              end
            end
          end
        end
        ##### Disk Configurations #####
        ## https://sleeplessbeastie.eu/2021/05/10/how-to-define-multiple-disks-inside-vagrant-using-virtualbox-provider/
        disks_directory = File.join("./", "disks")

        ## Create Disks
        config.trigger.before :up do |trigger|
          if host.has_key?('disks') && host['disks'].is_a?(Hash) && host['disks'].has_key?('additional_disks') && !host['disks']['additional_disks'].nil? && provider == 'virtualbox'
            trigger.name = "Creating disks"
            trigger.ruby do
              unless File.directory?(disks_directory)
                FileUtils.mkdir_p(disks_directory)
              end

              host['disks']['additional_disks'].each_with_index do |disks, diskindex|
                local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
                unless File.exist?(local_disk_filename)
                  system("#{path_VBoxManage} closemedium disk #{local_disk_filename}", out: File::NULL, err: File::NULL)
                  disk_size_gb = disks['size'].match(/(\d+(\.\d+)?)/)[0].to_f
                  disk_size_mb = (disk_size_gb * 1024).to_i
                  puts "Creating \"#{disks['volume_name']}\" disk with size \"#{disk_size_mb}\" MB (#{disk_size_gb} GB)"
                  system("#{path_VBoxManage} createmedium --filename #{local_disk_filename} --size #{disk_size_mb} --format VDI")
                end
              end
            end
          end
        end

        if host.has_key?('disks') && host['disks'].is_a?(Hash) && host['disks'].has_key?('additional_disks') && !host['disks']['additional_disks'].nil? && provider == 'virtualbox'
          machine_name = "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}"
          machine_id_file = File.join('.vagrant', 'machines', machine_name, 'virtualbox', 'id')

          machine_registered = false
          if File.exist?(machine_id_file)
            registered_vm_id = File.read(machine_id_file).strip
            machine_registered = system("#{path_VBoxManage} showvminfo \"#{registered_vm_id}\" --machinereadable", out: File::NULL, err: File::NULL)
          end

          unless machine_registered
            box_controller = Hosts.box_virtio_controller(host['settings']['box'], host['settings']['box_version'])
            attach_controller = box_controller || 'VirtIO Controller'
            config.vm.provider "virtualbox" do |storage_provider|
              if box_controller.nil?
                storage_provider.customize ["storagectl", :id, "--name", "VirtIO Controller", "--add", "virtio-scsi", '--hostiocache', 'off']
              end
              host['disks']['additional_disks'].each_with_index do |disks, diskindex|
                local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
                storage_provider.customize ['storageattach', :id, '--storagectl', attach_controller, '--port', disks['port'] || diskindex + 1, '--device', 0, '--type', 'hdd', '--medium', local_disk_filename]
              end
            end
          end

          config.trigger.before :up do |trigger|
            trigger.info = "Reconciling additional-disk controller and attachments"
            trigger.ruby do
              if File.exist?(machine_id_file)
                vm_id = File.read(machine_id_file).strip
                vm_info = `#{path_VBoxManage} showvminfo "#{vm_id}" --machinereadable`
                vm_state = vm_info[/VMState="(.+?)"/, 1]
                if ['poweroff', 'aborted'].include?(vm_state)
                  controller_names = vm_info.scan(/storagecontrollername(\d+)="(.+?)"/).to_h
                  controller_types = vm_info.scan(/storagecontrollertype(\d+)="(.+?)"/).to_h
                  virtio_index = controller_types.find { |_, type| type == 'VirtioSCSI' }&.first
                  controller = virtio_index ? controller_names[virtio_index] : nil
                  if controller.nil?
                    system(path_VBoxManage, 'storagectl', vm_id, '--name', 'VirtIO Controller', '--add', 'virtio-scsi', '--hostiocache', 'off')
                    controller = 'VirtIO Controller'
                  end
                  host['disks']['additional_disks'].each_with_index do |disks, diskindex|
                    local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
                    next unless File.exist?(local_disk_filename)
                    port = (disks['port'] || diskindex + 1).to_s
                    attachment = vm_info[/"#{Regexp.escape(controller)}-#{port}-0"="(.+?)"/, 1]
                    next unless attachment.nil? || attachment == 'none'
                    system(path_VBoxManage, 'storageattach', vm_id, '--storagectl', controller, '--port', port, '--device', '0', '--type', 'hdd', '--medium', local_disk_filename)
                  end
                end
              end
            end
          end
        end

        # Cleanup Disks after "destroy" action
        config.trigger.after :destroy do |trigger|
          if host.has_key?('disks') && host['disks'].is_a?(Hash) && host['disks'].has_key?('additional_disks') && !host['disks']['additional_disks'].nil? && provider == 'virtualbox'
            trigger.name = "Cleanup operation"
            trigger.ruby do
              # the following loop is now obsolete as these files will be removed automatically as machine dependency
              host['disks']['additional_disks'].each_with_index do |disks, diskindex|
                local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
                if File.exist?(local_disk_filename)
                  puts "Deleting \"#{disks['volume_name']}\" disk"
                  system("#{path_VBoxManage} closemedium disk #{local_disk_filename} --delete")
                end
              end
              if File.exist?(disks_directory)
                FileUtils.rmdir(disks_directory)
              end
            end
          end
        end

        server.vm.provider :virtualbox do |vb|
          if host['settings']['memory'].to_s =~ /gb|g|/
            vm_memory = 1024 * host['settings']['memory'].to_s.tr('^0-9', '').to_i
          elsif host['settings']['memory'] =~ /mb|m|/
            vm_memory = host['settings']['memory'].tr('^0-9', '')
          end
          vb.name = "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}"
          vb.gui = host['settings']['show_console']
          vb.customize ['modifyvm', :id, '--ostype', host['settings']['os_type'] || 'Debian_64']
          vb.customize ["modifyvm", :id, "--vrdeport", host['settings']['consoleport']]
          vb.customize ["modifyvm", :id, "--vrdeaddress", host['settings']['consolehost']]
          vb.customize ["modifyvm", :id, "--cpus", host['settings']['vcpus']]
          vb.customize ["modifyvm", :id, "--memory", vm_memory ]
          vb.customize ["modifyvm", :id, "--firmware", 'efi'] if host['settings']['firmware_type'] == 'UEFI'
          vb.customize ['modifyvm', :id, "--vrde", 'on']
          vb.customize ['modifyvm', :id, "--natdnsproxy1", 'off']
          vb.customize ['modifyvm', :id, "--natdnshostresolver1", 'off']
          vb.customize ['modifyvm', :id, "--accelerate3d", 'off']
          vb.customize ['modifyvm', :id, "--vram", '256']
          vb.customize ['modifyvm', :id, '--macaddress1', '00FF00FF00FF']

          if host.has_key?('roles') and !host['roles'].empty?
            host['roles'].each do |rolefwds|
              if rolefwds.has_key?('port_forwards') and !rolefwds.empty?
                rolefwds['port_forwards'].each_with_index do |param, index|
                  config.vm.network "forwarded_port", guest: param['guest'], host: param['host'], host_ip: param['ip']
                end
              end
            end
          end

          if host.has_key?('vbox') and !host['vbox'].empty?
            if host['vbox'].has_key?('directives') and !host['vbox']['directives'].empty?
              host['vbox']['directives'].each do |param|
                vb.customize ['modifyvm', :id, "--#{param['directive']}", param['value']]
              end
            end
          end
        end
        ##### End Virtualbox Configurations #####

        ##### Begin UTM type Configurations #####
        if provider == 'utm'
          if host['settings']['memory'].to_s =~ /gb|g|/
            vm_memory = 1024 * host['settings']['memory'].to_s.tr('^0-9', '').to_i
          elsif host['settings']['memory'] =~ /mb|m|/
            vm_memory = host['settings']['memory'].tr('^0-9', '')
          end

          # Determine directory share mode based on folder configurations
          directory_share_mode = "none"
          if host.has_key?('folders')
            host['folders'].each do |folder|
              if folder['type'] == 'utm' && !folder['disabled']
                directory_share_mode = "webDAV"
                break
              elsif folder['type'] == 'virtualbox' && !folder['disabled']
                directory_share_mode = "virtFS"
                break
              end
            end
          end

          server.vm.provider :utm do |utm|
            utm.name = "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}"
            utm.cpus = host['settings']['vcpus']
            utm.memory = vm_memory
            utm.notes = host['utm'] && host['utm']['notes'] ? host['utm']['notes'] : "Vagrant: For testing plugin development"
            utm.wait_time = host['settings']['setup_wait']
            utm.directory_share_mode = directory_share_mode

            # Additional UTM-specific settings from utm configuration block
            if host.has_key?('utm') && host['utm'] && !host['utm'].empty?
              utm.check_guest_additions = host['utm']['check_guest_additions'] if host['utm'].has_key?('check_guest_additions')
              utm.functional_9pfs = host['utm']['functional_9pfs'] if host['utm'].has_key?('functional_9pfs')

              # Support for custom UTM AppleScript customizations
              if host['utm'].has_key?('customizations') && host['utm']['customizations'] && !host['utm']['customizations'].empty?
                host['utm']['customizations'].each do |customization|
                  event = customization['event'] || 'pre-boot'
                  command = customization['command']
                  utm.customize(event, command) if command
                end
              end
            end
          end

          if host.has_key?('roles') and !host['roles'].empty?
            host['roles'].each do |rolefwds|
              if rolefwds.has_key?('port_forwards') and !rolefwds.empty?
                rolefwds['port_forwards'].each_with_index do |param, index|
                  config.vm.network "forwarded_port", guest: param['guest'], host: param['host'], host_ip: param['ip']
                end
              end
            end
          end
        end
        ##### End UTM Configurations #####

        ##### Begin ZONE type Configurations #####
        if provider == 'zone'
          server.vm.provider :zone do |vm|
            vm.hostname                             = "#{host['settings']['hostname']}.#{machine_domain}"
            vm.name                                 = "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}"
            vm.partition_id                         = host['settings']['server_id']

            vm.vagrant_cloud_creator                = host['settings']['cloud_creator']
            vm.boxshortname                         = host['settings']['boxshortname']

            vm.cloud_init_password                  = host['settings']['vagrant_user_pass']
            vm.vagrant_user_private_key_path        = host['settings']['vagrant_user_private_key_path']
            vm.vagrant_user                         = host['settings']['vagrant_user']
            vm.vagrant_user_pass                    = host['settings']['vagrant_user_pass']
            vm.os_type                              = Hosts.get_zone_os_type(host['settings']['os_type'] || 'generic')
            vm.firmware_type                        = host['settings']['firmware_type']
            vm.setup_wait                           = host['settings']['setup_wait']
            vm.consoleport                          = host['settings']['consoleport']
            vm.consolehost                          = host['settings']['consolehost']
            vm.memory                               = host['settings']['memory']
            vm.cpus                                 = host['settings']['vcpus']
            vm.dns                                  = host['networks']
            vm.boot                                 = host['disks']['boot']
            vm.additional_disks                     = host['disks']['additional_disks']
            vm.cdroms                               = host['disks']['cdroms']
            vm.autoboot                             = host['zones']['autostart']
            vm.brand                                = host['zones']['brand']
            vm.zunlockbootkey                       = host['zones']['zunlockbootkey']
            vm.zunlockboot                          = host['zones']['zunlockboot']
            vm.cpu_configuration                    = host['zones']['cpu_configuration']
            vm.complex_cpu_conf                     = host['zones']['complex_cpu_conf']
            vm.console_onboot                       = host['zones']['console_onboot']
            vm.console                              = host['zones']['console']
            vm.override                             = host['zones']['override']
            vm.acpi                                 = host['zones']['acpi']
            vm.shared_disk_enabled                  = host['zones']['shared_lofs_disk_enabled']
            vm.shared_dir                           = host['zones']['shared_lofs_dir']
            vm.custom_ci_web_root                   = host['zones']['custom_ci_web_root']
            vm.ci_port                              = host['zones']['ci_port']
            vm.ci_listen                            = host['zones']['ci_listen']
            vm.custom_ci                            = host['zones']['custom_ci']
            vm.allowed_address                      = host['zones']['allowed_address']
            vm.diskif                               = host['zones']['diskif']
            vm.netif                                = host['zones']['netif']
            vm.hostbridge                           = host['zones']['hostbridge']
            vm.clean_shutdown_time                  = host['zones']['clean_shutdown_time']
            vm.vmtype                               = host['zones']['vmtype']
            vm.booted_string                        = host['zones']['booted_string']
            vm.lcheck                               = host['zones']['lcheck_string']
            vm.alcheck                              = host['zones']['alcheck_string']
            vm.debug_boot                           = host['zones']['debug_boot']
            vm.debug                                = host['zones']['debug']
            vm.snapshot_script                      = host['zones']['snapshot_script']
            vm.cloud_init_enabled                   = host['zones']['cloud_init_enabled']
            vm.cloud_init_dnsdomain                 = host['zones']['cloud_init_dnsdomain']
            vm.cloud_init_conf                      = host['zones']['cloud_init_conf']
            vm.safe_restart                         = host['zones']['safe_restart']
            vm.safe_shutdown                        = host['zones']['safe_shutdown']
            vm.setup_method                         = host['zones']['setup_method']
            vm.on_demand_vnics                      = host['zones']['on_demand_vnics']
            vm.qga_slot                             = host['zones']['qga_slot']           if host['zones'].key?('qga_slot')           && !host['zones']['qga_slot'].nil?
            vm.qga_network_script                   = host['zones']['qga_network_script'] if host['zones'].key?('qga_network_script') && !host['zones']['qga_network_script'].nil?
          end
        end
        ## End Vagrant-Zones Configurations

        ##### Begin DigitalOcean Configurations #####
        if provider == 'digital_ocean'
          do_config = host['digitalocean'] || {}

          ## Ensure a Block Storage volume exists per additional disk so the droplet
          ## separates OS and application data like the other providers; volumes are
          ## found by name, so they survive droplet destroy/rebuild cycles
          do_volume_ids = []
          if %w[up rebuild].include?(ARGV[0]) && host['disks'].is_a?(Hash) && !host['disks']['additional_disks'].nil?
            do_token = secrets['DO_TOKEN'] || do_config['token']
            host['disks']['additional_disks'].each do |disks|
              ## DO volume names must be strictly lowercase alphanumeric
              volume_name = "vol#{host['settings']['server_id']}#{disks['volume_name']}".downcase.gsub(/[^a-z0-9]/, '')
              size_gb = disks['size'].to_s.match(/(\d+(\.\d+)?)/)[0].to_f.ceil
              do_volume_ids << Hosts.ensure_do_volume(do_token, do_config['region'], volume_name, size_gb)
            end
          end

          server.vm.provider :digital_ocean do |do_provider, override|
            ## The box's digital_ocean provider artifact from box_url is metadata-only (same as the aws one);
            ## the droplet itself boots from the DigitalOcean-side image referenced below
            override.nfs.functional = false
            override.vm.allowed_synced_folder_types = :rsync

            do_provider.token = secrets['DO_TOKEN'] || do_config['token']
            do_provider.image = do_config['image']
            do_provider.region = do_config['region']
            do_provider.size = do_config['size']
            do_provider.ssh_key_name = do_config['ssh_key_name'] if do_config.key?('ssh_key_name') && !do_config['ssh_key_name'].nil?
            do_provider.setup = do_config['setup'] if do_config.key?('setup') && !do_config['setup'].nil?
            do_provider.private_networking = do_config['private_networking'] if do_config.key?('private_networking') && !do_config['private_networking'].nil?
            do_provider.vpc_uuid = do_config['vpc_uuid'] if do_config.key?('vpc_uuid') && !do_config['vpc_uuid'].nil?
            do_provider.ipv6 = do_config['ipv6'] if do_config.key?('ipv6') && !do_config['ipv6'].nil?
            do_provider.backups_enabled = do_config['backups_enabled'] if do_config.key?('backups_enabled') && !do_config['backups_enabled'].nil?
            do_provider.monitoring = do_config['monitoring'] if do_config.key?('monitoring') && !do_config['monitoring'].nil?
            do_provider.droplet_agent = do_config['droplet_agent'] if do_config.key?('droplet_agent') && !do_config['droplet_agent'].nil?
            do_provider.tags = do_config['tags'] if do_config.key?('tags') && !do_config['tags'].nil?
            do_provider.user_data = do_config['user_data'] if do_config.key?('user_data') && !do_config['user_data'].nil?
            do_provider.volumes = do_volume_ids unless do_volume_ids.empty?
          end

          ## Delete the Block Storage volumes with the droplet, matching the
          ## VirtualBox behavior of removing additional disks on destroy
          config.trigger.after :destroy do |trigger|
            trigger.info = "Deleting DigitalOcean volumes"
            trigger.ruby do
              if host['disks'].is_a?(Hash) && !host['disks']['additional_disks'].nil?
                do_token = secrets['DO_TOKEN'] || do_config['token']
                host['disks']['additional_disks'].each do |disks|
                  next if disks['persist']
                  volume_name = "vol#{host['settings']['server_id']}#{disks['volume_name']}".downcase.gsub(/[^a-z0-9]/, '')
                  Hosts.delete_do_volume(do_token, do_config['region'], volume_name)
                end
              end
            end
          end
        end
        ##### End DigitalOcean Configurations #####

        if host['vars'] && host['vars'].key?('git_vault_password')
          Hosts.write_results_file(host['vars']['git_vault_password'], 'provisioners/ansible/git_vault_password', false)
        end

        # Register shared folders
        if host.has_key?('folders')
          host['folders'].each do |folder|
            mount_opts = folder['type'] == folder['type'] ? ['actimeo=1'] : []
            server.vm.synced_folder "#{folder['map']}", "#{folder ['to']}",
            type: folder['type'],
            map: "#{folder['map']}",
            to: "#{folder['to']}",
            owner: folder['owner'] ||= host['settings']['vagrant_user'],
            group: folder['group'] ||= host['settings']['vagrant_user'],
            mount_options: mount_opts,
            automount: true,
            scp__args: folder['args'],
            rsync__args: folder['args'] ||= ["--verbose", "--archive", "-z", "--copy-links"],
            rsync__chown: folder['chown'] ||= 'false',
            create: folder['create'] ||= 'false',
            rsync__rsync_ownership: folder['rsync_ownership'] ||= 'true',
            disabled: folder['disabled'] ||= false
          end
        end

        # Begin Provisioning Sequences
        if host.has_key?('provisioning') and !host['provisioning'].nil?
          # Run the shell provisioners defined in hosts.yml
          if host['provisioning'].has_key?('shell') && host['provisioning']['shell']['enabled']
            host['provisioning']['shell']['scripts'].each do |file|
                server.vm.provision 'shell', path: file
            end
          end

          # Run the Ansible Provisioners -- You can pass Host.yaml variables to Ansible via the Extra_vars variable as noted below.
          ## If Ansible is not available on the host and is installed in the template you are spinning up, use 'ansible-local'
          if host['provisioning'].has_key?('ansible') && host['provisioning']['ansible']['enabled']
            host['provisioning']['ansible']['playbooks'].each do |playbooks|
              if playbooks.has_key?('local')
                playbooks['local'].each do |localplaybook|
                  run_value = case localplaybook['run']
                    when 'always'
                      :always
                    when 'not_first'
                      File.exist?(File.join(Dir.pwd, 'results.yml')) ? :always : :never
                    else
                      :once
                    end

                  server.vm.provision :ansible_local, run: run_value do |ansible|
                    ansible.playbook = localplaybook['playbook']
                    ansible.compatibility_mode = localplaybook['compatibility_mode'].to_s
                    ansible.install_mode = "pip" if localplaybook['install_mode'] == "pip"
                    ansible.verbose = localplaybook['verbose']
                    ansible.config_file = "/vagrant/ansible/ansible.cfg"
                    ansible.galaxy_roles_path = "/vagrant"

                    ansible.extra_vars = {
                      settings: host['settings'],
                      networks: host['networks'],
                      disks: host['disks'],
                      secrets: secrets,
                      role_vars: host['vars'],
                      provision_roles: host['roles'],
                      provision_pre_tasks: host['pre_tasks'],
                      provision_post_tasks: host['post_tasks'],
                      playbook_collections: localplaybook['collections'],
                      core_provisioner_version: CoreProvisioner::VERSION,
                      provisioner_name: Provisioner::NAME,
                      provisioner_version: Provisioner::VERSION,
                      ansible_winrm_server_cert_validation: "ignore",
                      ansible_callbacks_enabled:localplaybook['callbacks'],
                      ansible_ssh_pipelining:localplaybook['ssh_pipelining'],
                      ansible_python_interpreter:localplaybook['ansible_python_interpreter']}
                    if localplaybook['remote_collections']
                      ansible.galaxy_role_file = "/vagrant/ansible/requirements.yml"
                      ansible.galaxy_roles_path = "/vagrant/ansible/ansible_collections"
                    end
                  end
                end
              end

              ## If Ansible is available on the host or is not installed in the template you are spinning up, use 'ansible'
              if playbooks.has_key?('remote')
                playbooks['remote'].each do |remoteplaybook|
                  run_value = case remoteplaybook['run']
                    when 'always'
                      :always
                    when 'once'
                      File.exist?(File.join(Dir.pwd, 'results.yml')) ? :never : :once
                    when 'not_first'
                      File.exist?(File.join(Dir.pwd, 'results.yml')) ? :always : :never
                    else
                      :once
                    end
                  server.vm.provision :ansible, run: run_value do |ansible|
                    ansible.playbook = remoteplaybook['playbook']
                    ansible.compatibility_mode = remoteplaybook['compatibility_mode'].to_s
                    ansible.verbose = remoteplaybook['verbose']
                    ansible.extra_vars = {
                      settings: host['settings'],
                      networks: host['networks'],
                      disks: host['disks'],
                      secrets: secrets,
                      role_vars: host['vars'],
                      provision_roles: host['roles'],
                      playbook_collections: remoteplaybook['collections'],
                      core_provisioner_version: CoreProvisioner::VERSION,
                      provisioner_name: Provisioner::NAME,
                      provisioner_version: Provisioner::VERSION,
                      ansible_winrm_server_cert_validation: "ignore",
                      ansible_callbacks_enabled:remoteplaybook['callbacks'],
                      ansible_ssh_pipelining:remoteplaybook['ssh_pipelining'],
                      ansible_python_interpreter:remoteplaybook['ansible_python_interpreter']
                    }
                    if remoteplaybook['remote_collections']
                      ansible.galaxy_role_file = "requirements.yml"
                      ansible.galaxy_roles_path = "./ansible/ansible_collections"
                    end
                  end
                end
              end
            end
          end

          # Run the Docker-Compose provisioners defined in hosts.yml
          if host['provisioning'].has_key?('docker') && host['provisioning']['docker']['enabled']
            server.vm.provision 'docker'
            if host['provisioning']['docker'].has_key?('docker-compose')
              host['provisioning']['docker']['docker_compose'].each do |file|
                server.vm.provision :docker_compose, yml: file, run: "always"
              end
            end
          end
        end
      end

      # Hook to run after destroy to clean up artifacts.
      if provider == 'virtualbox'
        config.trigger.after :destroy do |trigger|
          trigger.info = "Deleting cached files"
          files_to_delete = [
            '.vagrant/done.txt',
            '.vagrant/provisioned-adapters.yml',
            'results.yml'
          ]
          trigger.ruby do
            pristine_key = File.join(File.dirname(__FILE__), 'ssh_keys', 'id_rsa')
            rotated_key = host['settings']['vagrant_user_private_key_path']
            unless rotated_key.to_s.empty? || (File.exist?(rotated_key) && File.identical?(rotated_key, pristine_key))
              files_to_delete += [rotated_key, "#{rotated_key}.pub"]
            end
            Hosts.delete_files(trigger, files_to_delete)
          end
        end
      end

      ## Syncback
      if host.has_key?('folders') && Vagrant.has_plugin?("vagrant-scp-sync") && Vagrant::Util::Which.which('rsync')
        prefix = "==> #{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}:"
        host['folders'].each do |folder|
          next unless folder['syncback']
          config.trigger.after :rsync, type: :command do |trigger|
            trigger.info = "Using SCP to sync from Guest to Host"
            trigger.ruby do |env, machine|
              guest_path = folder['to']
              host_path = folder['map'].split(/(?<=\/)[^\/]*$/).last
              transfer_cmd = "vagrant scp :#{guest_path} #{host_path}"
              puts "#{ prefix } #{ transfer_cmd }"
              system(transfer_cmd)
            end
          end
        end
      end

      ## Save variables to .vagrant directory
      if host.has_key?('networks') && host['settings']['provider_type'] == 'virtualbox' &&  host['settings']['post_provision']
        host['networks'].each_with_index do |network, netindex|
          config.trigger.after [:up] do |trigger|
            trigger.info = "Post-Provisioning Vagrant Operations"
            trigger.ruby do |env, machine|
              prefix = "==> #{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}:"
              puts "#{ prefix } This server has been provisioned with core_provisioner v#{CoreProvisioner::VERSION}"
              puts "#{ prefix } https://github.com/STARTcloud/core_provisioner/releases/tag/v#{CoreProvisioner::VERSION}"
              puts "#{ prefix } This server has been provisioned with #{Provisioner::NAME} v#{Provisioner::VERSION}"
              puts "#{ prefix } https://github.com/STARTcloud/#{Provisioner::NAME}/releases/tag/v#{Provisioner::VERSION}"

              puts "#{ prefix } Transferring Debugging files back to Host"
              transfer_cmd = "vagrant scp :/vagrant/support-bundle/provisioned-adapters.yml .vagrant/provisioned-adapters.yml"
              transfer_cmd = "vagrant ssh -c 'cat /vagrant/support-bundle/provisioned-adapters.yml' > .vagrant/provisioned-adapters.yml" if not Vagrant.has_plugin?("vagrant-scp-sync")
              system(transfer_cmd)

              ansible_log = "vagrant scp :/home/#{host['settings']['vagrant_user']}/ansible.log #{host['settings']['server_id']}--#{host['settings']['hostname']}.#{machine_domain}-ansible.log"
              system(ansible_log) if Vagrant.has_plugin?("vagrant-scp-sync")

              has_support_bundle_role = host.has_key?('roles') && host['roles'].any? { |r| r.is_a?(Hash) && r['name'] == 'startcloud.startcloud_roles.support_bundle' }
              support_bundle = "vagrant scp :/vagrant/support-bundle.zip support-bundle.zip"
              system(support_bundle) if Vagrant.has_plugin?("vagrant-scp-sync") && has_support_bundle_role

              if File.exist?('.vagrant/provisioned-adapters.yml')
                adapters_content = File.read('.vagrant/provisioned-adapters.yml')
                begin
                  adapters = YAML.load(adapters_content)
                rescue Psych::SyntaxError => e
                  puts "YAML Syntax Error: #{e.message}"
                  adapters = nil
                end

                if adapters && adapters.is_a?(Hash) && adapters.key?('adapters')
                  public_adapter = adapters['adapters'].find { |adapter| adapter['name'] == 'public_adapter' }
                  nat_adapter = adapters['adapters'].find { |adapter| adapter['name'] == 'nat_adapter' }

                  ip_address = public_adapter&.fetch('ip') || nat_adapter&.fetch('ip')

                  open_url = "https://#{ip_address.split('/').first}:443/welcome.html"

                  adapters['adapters'].each do |adapter_hash|
                    adapter_hash.transform_keys!(&:to_s)
                  end

                  output_data = {
                    'open_url' => open_url,
                    'adapters' => adapters['adapters']
                  }
                  puts "#{ prefix } Network Information Can be found here: "
                  puts "#{ prefix }     #{File.join(Dir.pwd, 'results.yml')}"
                  Hosts.write_results_file(output_data, 'results.yml', true)
                  puts "#{ prefix } You can access the Welcome Page Here: "
                  puts "#{ prefix }     #{ open_url }"
                  system("echo '" + open_url + "' > .vagrant/done.txt")

                  ## The rotated key must never be fetched INTO the identity
                  ## file the fetch connection authenticates with — that races
                  ## itself into a password prompt. The fetch lands in a temp
                  ## file, and only replaces the identity (removing its stale
                  ## .pub) once the content looks like a private key. Shell
                  ## redirection is avoided on purpose: under PowerShell it
                  ## re-encodes the key to UTF-16, which net-ssh rejects.
                  if host['settings']['vagrant_ssh_insert_key']
                    key_dest = host['settings']['vagrant_user_private_key_path']
                    pristine_key = File.join(File.dirname(__FILE__), 'ssh_keys', 'id_rsa')
                    if File.exist?(key_dest) && File.identical?(key_dest, pristine_key)
                      puts "#{ prefix } vagrant_user_private_key_path points at the driver's pristine key; skipping rotated-key transfer"
                    else
                      puts "#{ prefix } Transferring New SSH key"
                      key_src = "/home/#{host['settings']['vagrant_user']}/.ssh/id_ssh_rsa"
                      key_tmp = "#{key_dest}.new"
                      if Vagrant.has_plugin?("vagrant-scp-sync")
                        system("vagrant scp :#{key_src} #{key_tmp}")
                      else
                        key_data = `vagrant ssh -c "cat #{key_src}"`
                        File.binwrite(key_tmp, key_data) unless key_data.to_s.strip.empty?
                      end
                      if File.file?(key_tmp) && File.read(key_tmp, 64).to_s.include?('PRIVATE KEY')
                        FileUtils.mv(key_tmp, key_dest)
                        FileUtils.rm_f("#{key_dest}.pub")
                      else
                        FileUtils.rm_f(key_tmp)
                        puts "#{ prefix } Rotated key not published by the guest; keeping the existing identity"
                      end
                    end
                  end
                end
              else
                puts "Error: .vagrant/provisioned-adapters.yml file does not exist."
              end
            end
          end
        end
      end

      if host['zones'] && host['zones'].has_key?('post_provision_boot') && host['zones']['post_provision_boot'] && host['settings']['provider_type'] == 'zones'
        config.trigger.after [:up, :provision] do |trigger|
          trigger.info = "post_provision_boot is true, Waiting for instance to stop"
          trigger.ruby do |env, machine|
            sleep 30
            loop do
              system("vagrant status #{machine.name}")
              break if %x(vagrant status #{machine.name}) =~ /stopped/
              sleep 10
            end
            post_reboot_cmd = "pfexec zoneadm -z #{machine.name} boot"
            system(post_reboot_cmd)
          end
        end
      end
    end
  end

  def self.get_bridge_interface(path_VBoxManage)
    # Gather a list of Bridged Interfaces that Virtualbox is aware of, We only want to get the ones that are a status of Up.
    vm_interfaces = %x[#{path_VBoxManage} list bridgedifs].split("\n")
    interfaces = vm_interfaces.select { |line| line.start_with?('Name') || line.start_with?('Status') }
    pairs = interfaces.each_slice(2).select { |_, status_line| status_line.include? "Up" }.map { |name_line, _| name_line.sub("Name:", '').strip }

    # This gathers the default Route so as to further narrow the list of interfaces to use, since these would likely have public access
    defroute = if Vagrant::Util::Platform.windows?
      powershell_command = [
        "Get-NetRoute -DestinationPrefix '0.0.0.0/0'",
        "Sort-Object -Property { $_.InterfaceMetric + $_.RouteMetric }",
        "Get-NetAdapter -InterfaceIndex { $_.ifIndex }",
        "foreach { $_.InterfaceDescription }"
      ].join(" | ")

      stdout, stderr, status = Open3.capture3("powershell", "-Command", powershell_command)
      stdout.strip
    else
      stdout, stderr, status = Open3.capture3("netstat -rn -f inet")
      stdout.split("\n").find { |line| line.include? "UG" }&.split("\s")
    end

    # We then compare the interfaces that are up, and then compare that with the output of the defroute
    bridge = nil
    pairs.each do |active_interface|
      if Vagrant::Util::Platform.windows?
        bridge = active_interface if !defroute.nil? && active_interface.start_with?(defroute.to_s)
      elsif Vagrant::Util::Platform.linux?
        bridge = active_interface if !defroute[7].nil? && active_interface.start_with?(defroute[7])
      elsif Vagrant::Util::Platform.darwin?
        bridge = active_interface if !defroute[3].nil? && active_interface.start_with?(defroute[3])
      end
    end

    bridge
  end

  # Helper method to determine Vagrant guest type from VirtualBox OS type
  def self.get_vagrant_guest_type(os_type)
    return :linux if os_type.nil?

    # Check if it's a Windows OS type
    os_type.downcase.include?('windows') ? :windows : :linux
  end

  # Helper method to translate VirtualBox OS type to zone OS type
  def self.get_zone_os_type(os_type)
    return 'generic' if os_type.nil?

    os_type_lower = os_type.downcase

    if os_type_lower.include?('windows')
      'windows'
    elsif os_type_lower.include?('openbsd')
      'openbsd'
    else
      'generic'  # Default for Linux and other types
    end
  end

  def self.box_virtio_controller(box, box_version)
    return nil if box.to_s.empty? || box_version.to_s.empty?

    vagrant_home = (ENV['VAGRANT_HOME'] || File.join(Dir.home, '.vagrant.d')).tr('\\', '/')
    pattern = File.join(vagrant_home, 'boxes', box.gsub('/', '-VAGRANTSLASH-'), box_version.to_s, '{.,*}', 'virtualbox', 'box.ovf')
    ovf = Dir.glob(pattern).first
    return nil if ovf.nil?

    tag = File.read(ovf).scan(/<StorageController\b[^>]*>/).find { |controller| controller.include?('type="VirtioSCSI"') }
    tag && tag[/\bname="([^"]+)"/, 1]
  end

  ## Finds a DigitalOcean Block Storage volume by name in the region, creating it
  ## when absent, and returns its id. Left unformatted so the disks role formats
  ## and mounts it exactly like the additional disks of the other providers.
  def self.ensure_do_volume(token, region, name, size_gb)
    require 'net/http'
    require 'uri'
    require 'json'

    raise 'DigitalOcean additional disks need DO_TOKEN in .secrets.yml (or digitalocean.token in Hosts.yml)' if token.to_s.empty?

    headers = { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }

    uri = URI("https://api.digitalocean.com/v2/volumes?name=#{name}&region=#{region}")
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.get(uri.request_uri, headers) }
    volumes = JSON.parse(response.body)['volumes'] || []
    return volumes.first['id'] unless volumes.empty?

    uri = URI('https://api.digitalocean.com/v2/volumes')
    body = { name: name, region: region, size_gigabytes: size_gb }.to_json
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.post(uri.request_uri, body, headers) }
    volume = JSON.parse(response.body)['volume']
    raise "DigitalOcean volume creation failed for #{name}: #{response.body}" if volume.nil?

    puts "==> Created DigitalOcean volume #{name} (#{size_gb}GB) in #{region}"
    volume['id']
  end

  ## Deletes a DigitalOcean Block Storage volume by name in the region. Retries
  ## briefly because the droplet deletion that detaches the volume is asynchronous.
  def self.delete_do_volume(token, region, name)
    require 'net/http'
    require 'uri'

    return if token.to_s.empty?

    uri = URI("https://api.digitalocean.com/v2/volumes?name=#{name}&region=#{region}")
    5.times do
      request = Net::HTTP::Delete.new(uri.request_uri, { 'Authorization' => "Bearer #{token}" })
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
      if response.code == '204'
        puts "==> Deleted DigitalOcean volume #{name} in #{region}"
        return
      end
      sleep 5
    end
    puts "==> WARNING: could not delete DigitalOcean volume #{name} in #{region} — remove it in the control panel"
  end

  def self.load_secrets
    secrets_dir = File.dirname(__FILE__)
    secrets_path = File.join(secrets_dir, '../secrets.yml')
    hidden_secrets_path = File.join(secrets_dir, '../.secrets.yml')

    secrets = {}

    # Load secrets.yml if it exists
    if File.file?(secrets_path)
      secrets.merge!(YAML.load(File.read(secrets_path)) || {})
    end

    # Load .secrets.yml if it exists, overwriting any duplicate keys
    if File.file?(hidden_secrets_path)
      secrets.merge!(YAML.load(File.read(hidden_secrets_path)) || {})
    end

    secrets
  end

  def self.rsync_version_low?
    return false unless Vagrant::Util::Platform.darwin?
    `rsync --version`.include?('2.6.9') || `rsync --version` < '2.6.9'
  end


  def self.delete_files(trigger, files_to_delete)
    files_to_delete.each do |file|
      if File.exist?(file)
        FileUtils.rm_f(file)
        trigger.info = "Deleted file: #{file}"
      else
        trigger.info = "File not found: #{file}"
      end
    end
  end

  def self.write_results_file(data, file_path, yaml)
    File.delete(file_path) if File.exist?(file_path)
    File.open(file_path, 'w') do |file|
      file.flock(File::LOCK_EX) # Exclusive lock
      file.write(data) if not yaml
      file.write(data.to_yaml) if yaml
      file.flock(File::LOCK_UN) # Unlock the file
    end
  end

end

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
    # Load your Secrets file
    secrets = load_secrets
    # Main loop to configure VM
    settings['hosts'].each_with_index do |host, index|
      configure_plugins(host)
      provider = host['provider-type']
      config.vm.define "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{host['settings']['domain']}" do |server|
        server.vm.box = host['settings']['box']
        config.vm.box_url = "#{host['settings']['box_url']}/#{host['settings']['box']}"
        server.vm.box_version = host['settings']['box_version']
        server.vm.boot_timeout = host['settings']['setup_wait']
        server.ssh.username = host['settings']['vagrant_user']
        #server.ssh.password =  host['settings']['vagrant_user_pass']
        default_ssh_key = "./core/ssh_keys/id_rsa"
        vagrant_ssh_key = host['settings']['vagrant_user_private_key_path']
        server.ssh.private_key_path = File.exist?(vagrant_ssh_key) ? [vagrant_ssh_key, default_ssh_key] : default_ssh_key
        server.ssh.insert_key = false # host['settings']['vagrant_insert_key'], Note we are no longer automatically forcing the key in via Vagrants SSH insertion function
        server.ssh.forward_agent = host['settings']['ssh_forward_agent']
        config.vm.communicator = :ssh
        config.winrm.username = host['settings']['vagrant_user']
        config.winrm.password = host['settings']['vagrant_user_pass']
        config.winrm.timeout = host['settings']['setup_wait']
        config.winrm.retry_delay = 30
        config.winrm.retry_limit = 1000

        path_VBoxManage = Vagrant::Util::Platform.windows? ? "VBoxManage" : "VBoxManage.exe"

        ## Networking
        ## For every Network block in Hosts.yml, and if its not empty
        if host.has_key?('networks') and !host['networks'].empty?
          ## This tells Virtualbox to set the Nat network so that we can avoid IP conflicts and more easily identify networks
          ## This Nic cannot be removed which is why its not in the loop below
          config.vm.provider "virtualbox" do |network_provider|
            # https://github.com/Moonshine-IDE/Super.Human.Installer/issues/116
            network_provider.customize ['modifyvm', :id, '--natnet1', '10.244.244.0/24']
          end

          ## Loop over each block, with an index so that we can use the ordering to specify interface number
          host['networks'].each_with_index do |network, netindex|
              # For Virtualbox, we need to modify the MAC address if the user has specified one
              network['vmac'] = network['mac'].tr(':', '') if host['provider-type'] == 'virtualbox'
              
              ## Get the bridge device the user specifies, if none selected, we need to try our best to get the best one (for every OS: Mac, Windows, and Linux)
              bridge = network['bridge'] if defined?(network_bridge)
              
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
          
              ## We then compare the interfaces that are up, and then compare that with the output of the defroute
              pairs.each do |active_interface|
                if Vagrant::Util::Platform.windows?
                  bridge = active_interface if !defroute.nil? && active_interface.start_with?(defroute.to_s) && !defined?(network_bridge)
                elsif Vagrant::Util::Platform.linux?
                  bridge = active_interface if !defroute[7].nil? && active_interface.start_with?(defroute[7]) && !defined?(network_bridge)
                elsif Vagrant::Util::Platform.darwin?
                  bridge = active_interface if !defroute[3].nil? && active_interface.start_with?(defroute[3]) && !defined?(network_bridge)
                end
              end

              ## We then take those variables, and hopefully have the best connection to use and then pass it to vagrant so it can create the network adapters.
              if network['type'] == 'host'
                server.vm.network "private_network",
                  ip: network['address'],
                  dhcp: network['dhcp4'],
                  dhcp6: network['dhcp6'],
                  auto_config: network['autoconf'],
                  netmask: network['netmask'],
                  vmac: network['mac'],
                  mac: network['vmac'],
                  gateway: network['gateway'],
                  nictype: network['type'],
                  nic_number: netindex,
                  managed: network['is_control'],
                  vlan: network['vlan'],
                  type: 'dhcp'#,
                  #name: 'core_provisioner_network'
              end
              if network['type'] == 'external'
                server.vm.network "public_network",
                  ip: network['address'],
                  dhcp: network['dhcp4'],
                  dhcp6: network['dhcp6'],
                  bridge: bridge,
                  auto_config: network['autoconf'],
                  netmask: network['netmask'],
                  vmac: network['mac'],
                  mac: network['vmac'],
                  gateway: network['gateway'],
                  nictype: network['type'],
                  nic_number: netindex,
                  managed: network['is_control'],
                  vlan: network['vlan']
              end
          end
        end

        ##### Disk Configurations #####
        ## https://sleeplessbeastie.eu/2021/05/10/how-to-define-multiple-disks-inside-vagrant-using-virtualbox-provider/
        disks_directory = File.join("./", "disks")
        
        ## Create Disks
        config.trigger.before :up do |trigger|
          if host.has_key?('disks') and !host['disks'].empty?
            trigger.name = "Create disks"
            trigger.ruby do
              unless File.directory?(disks_directory)
                FileUtils.mkdir_p(disks_directory)
              end
              
              host['disks']['additional_disks'].each_with_index do |disks, diskindex|
                local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
                unless File.exist?(local_disk_filename)
                  puts "Creating \"#{disks['volume_name']}\" disk with size \"#{disks['size'].delete('^0-9').to_i * 1024}\""
                  system("VBoxManage createmedium --filename #{local_disk_filename} --size #{disks['size'].delete('^0-9').to_i * 1024} --format VDI")
                end
              end
            end  
          end
        end

        # create storage controller on first run
        if host.has_key?('disks') and !host['disks'].empty?
          unless File.directory?(disks_directory)
            config.vm.provider "virtualbox" do |storage_provider|
              storage_provider.customize ["storagectl", :id, "--name", "Virtual I/O Device SCSI controller", "--add", "virtio-scsi", '--hostiocache', 'off']
            end
          end
        end

        # attach storage devices
        if host.has_key?('disks') and !host['disks'].empty?
          config.vm.provider "virtualbox" do |storage_provider|
            host['disks']['additional_disks'].each_with_index do |disks, diskindex|
              local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
              unless File.exist?(local_disk_filename)
                storage_provider.customize ['storageattach', :id, '--storagectl', "Virtual I/O Device SCSI controller", '--port', disks['port'], '--device', 0, '--type', 'hdd', '--medium', local_disk_filename]
              end
            end
          end
        end

        # cleanup after "destroy" action
        config.trigger.after :destroy do |trigger|
          if host.has_key?('disks') and !host['disks'].empty?
            trigger.name = "Cleanup operation"
            trigger.ruby do
              # the following loop is now obsolete as these files will be removed automatically as machine dependency
              host['disks']['additional_disks'].each_with_index do |disks, diskindex|
                local_disk_filename = File.join(disks_directory, "#{disks['volume_name']}.vdi")
                if File.exist?(local_disk_filename)
                  puts "Deleting \"#{disks['volume_name']}\" disk"
                  system("vboxmanage closemedium disk #{local_disk_filename} --delete")
                end
              end
              if File.exist?(disks_directory)
                FileUtils.rmdir(disks_directory)
              end
            end
          end
        end

        # Hook to run after destroy to clean up artifacts.
        config.trigger.after :destroy do |trigger|
          trigger.info = "Deleting specific files after VM is destroyed"
          trigger.run = {
            inline: <<-SCRIPT
              rm -f ./.vagrant/done.txt
              rm -f ./.vagrant/provisioned-adapters.yml
              rm -f ./results.yml
            SCRIPT
          }
        end

        ##### Begin Virtualbox Configurations #####
        server.vm.provider :virtualbox do |vb|
          if host['settings']['memory'] =~ /gb|g|/
            host['settings']['memory']= 1024 * host['settings']['memory'].tr('^0-9', '').to_i
          elsif host['settings']['memory'] =~ /mb|m|/
            host['settings']['memory']= host['settings']['memory'].tr('^0-9', '')
          end
          vb.name = "#{host['settings']['server_id']}--#{host['settings']['hostname']}.#{host['settings']['domain']}"
          vb.gui = host['settings']['show_console']
          vb.customize ['modifyvm', :id, '--ostype', host['settings']['os_type']]
          vb.customize ["modifyvm", :id, "--vrdeport", host['settings']['consoleport']]
          vb.customize ["modifyvm", :id, "--vrdeaddress", host['settings']['consolehost']]
          vb.customize ["modifyvm", :id, "--cpus", host['settings']['vcpus']]
          vb.customize ["modifyvm", :id, "--memory", host['settings']['memory']]
          vb.customize ["modifyvm", :id, "--firmware", 'efi'] if host['settings']['firmware_type'] == 'UEFI'
          vb.customize ['modifyvm', :id, "--vrde", 'on']
          vb.customize ['modifyvm', :id, "--natdnsproxy1", 'off']
          vb.customize ['modifyvm', :id, "--natdnshostresolver1", 'off']
          vb.customize ['modifyvm', :id, "--accelerate3d", 'off']
          vb.customize ['modifyvm', :id, "--vram", '256']
          
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

        # Register shared folders
        if host.has_key?('folders')
					host['folders'].each do |folder|
						mount_opts = folder['type'] == folder['type'] ? ['actimeo=1'] : []
						server.vm.synced_folder folder['map'], folder ['to'],
						type: folder['type'],
						owner: folder['owner'] ||= host['settings']['vagrant_user'],
						group: folder['group'] ||= host['settings']['vagrant_user'],
						mount_options: mount_opts,
						automount: true,
            rsync__args: folder['args'] ||= ["--verbose", "--archive", "-z", "--copy-links"],
						rsync__chown: folder['chown'] ||= 'false',
            create: folder['create'] ||= 'false',
						rsync__rsync_ownership: folder['rsync_ownership'] ||= 'true',
						disabled: folder['disabled']||= false
					end
				end
        
        # Begin Provisioning Sequences
        if host.has_key?('provisioning') and !host['provisioning'].nil?
          # Add Branch Files to Vagrant Share on VM Change to Git folders to pull
          if host['provisioning'].has_key?('role') && host['provisioning']['role']['enabled']
            scriptsPath = File.dirname(__FILE__) + '/scripts'
            server.vm.provision 'shell' do |s|
              s.path = scriptsPath + '/add-role.sh'
              s.args = [host['provisioning']['role']['name'], host['provisioning']['role']['git_url'] ]
            end
          end
  
          # Run the shell provisioners defined in hosts.yml
          if host['provisioning'].has_key?('shell') && host['provisioning']['shell']['enabled']
            host['provisioning']['shell']['scripts'].each do |file|
                server.vm.provision 'shell', path: file
            end
          end
  
          # Run the Ansible Provisioners -- You can pass Host.yaml variables to Ansible via the Extra_vars variable as noted below.
          ## If Ansible is not available on the host and is installed in the template you are spinning up, use 'ansible-local'
          if host['provisioning'].has_key?('ansible') && host['provisioning']['ansible']['enabled']
            host['provisioning']['ansible']['scripts'].each do |scripts|
              if scripts.has_key?('local')
                scripts['local'].each do |localscript|
                  run_value = localscript['always_run']? :always : :once
                  server.vm.provision :ansible_local, run: run_value do |ansible|
                    ansible.playbook = localscript['script']
                    ansible.compatibility_mode = localscript['compatibility_mode'].to_s
                    ansible.install_mode = "pip" if localscript['install_mode'] == "pip"
                    ansible.verbose = localscript['verbose']
                    ansible.config_file = "/vagrant/ansible/ansible.cfg"
                    ansible.extra_vars = {
                      settings: host['settings'],
                      networks: host['networks'],
                      secrets: secrets,
                      role_vars: host['vars'],
                      provision_roles: host['roles'],
                      core_provisioner_version: CoreProvisioner::VERSION,
                      provisioner_name: Provisioner::NAME,
                      provisioner_version: Provisioner::VERSION,
                      ansible_winrm_server_cert_validation: "ignore",
                      ansible_ssh_pipelining:localscript['ssh_pipelining'],
                      ansible_python_interpreter:localscript['ansible_python_interpreter']}
                    if localscript['remote_collections']
                      ansible.galaxy_role_file = "/vagrant/ansible/requirements.yml"
                      ansible.galaxy_roles_path = "/vagrant/ansible/ansible_collections"
                    end
                  end
                end
              end
  
              ## If Ansible is available on the host or is not installed in the template you are spinning up, use 'ansible'
              if scripts.has_key?('remote')
                scripts['remote'].each do |remotescript|
                  server.vm.provision :ansible do |ansible|
                    ansible.playbook = remotescript['script']
                    ansible.compatibility_mode = remotescript['compatibility_mode'].to_s
                    ansible.verbose = remotescript['verbose']
                    ansible.extra_vars = {
                      settings: host['settings'],
                      networks: host['networks'],
                      secrets: secrets,
                      role_vars: host['vars'],
                      provision_roles: host['roles'],
                      core_provisioner_version: CoreProvisioner::VERSION,
                      provisioner_name: Provisioner::NAME,
                      provisioner_version: Provisioner::VERSION,
                      ansible_winrm_server_cert_validation: "ignore",
                      ansible_ssh_pipelining:remotescript['ssh_pipelining'],
                      ansible_python_interpreter:remotescript['ansible_python_interpreter']
                    }
                    if remotescript['remote_collections']
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
            host['provisioning']['docker']['docker_compose'].each do |file|
                server.vm.provision 'docker'
                server.vm.provision :docker_compose, yml: file, run: "always"
            end
          end
        end
      end

    # Syncback to User Directory
      config.trigger.after :rsync do |trigger|
        ssh_private_key = host['settings']['vagrant_user_private_key_path']
        ssh_username = host['settings']['vagrant_user']
        ssh_options = "-e 'ssh -i #{ssh_private_key} -o StrictHostKeyChecking=no'"
        file_path = File.join(Dir.pwd, 'results.yml')
        adapters = File.exist?(file_path) ? YAML.load_file(file_path) : nil
        puts adapters
        if host.has_key?('folders') && host['settings']['provider-type'] == 'virtualbox' && !adapters.nil?
          host['folders'].each do |folder|
            if folder['syncback']
              puts "rsync from on the VM"
              if adapters['adapters'].is_a?(Array)
                public_adapter = adapters['adapters'].find { |adapter| adapter['name'] == 'public_adapter' }
                nat_adapter = adapters['adapters'].find { |adapter| adapter['name'] == 'nat_adapter' }
                public_ip_address = public_adapter[:ip] if public_adapter
                nat_ip_address = nat_adapter[:ip] if nat_adapter
                ip_address = public_ip_address || nat_ip_address
                puts "rsync from on the VM: #{ip_address}: #{folder['to']} to #{folder['map']}"
                if ip_address
                  trigger.name = "rsync from on the VM: #{ip_address}: #{folder['to']} to #{folder['map']}"
                  puts "rsync from on the VM: #{ip_address}: #{folder['to']} to #{folder['map']}"
                  source_path = folder['to']
                  destination_path = folder['map']
                  rsync_options = [
                    "--rsync-path='sudo rsync'",
                    "--verbose"
                  ]
                  rsync_options.concat(folder['args']) if folder.key?('args')
                  rsync_options << "--chown=#{folder['owner']}" if folder.key?('owner')
                  rsync_options << "--chgrp=#{folder['group']}" if folder.key?('group')
                  rsync_command = "rsync #{rsync_options.join(' ')} #{ssh_options} #{ssh_username}@#{ip_address}:#{source_path} #{destination_path}"
                  trigger.run = { inline: rsync_command }
                end
              end
            end
          end
        end
      end
      
      ## Save variables to .vagrant directory
      if host.has_key?('networks') && host['settings']['provider-type'] == 'virtualbox'
        host['networks'].each_with_index do |network, netindex|
          ## Post-Provisioning Vagrant Operations
          config.trigger.after [:up] do |trigger|
            trigger.ruby do |env, machine|
              puts "This server has been provisioned with core_provisioner v#{CoreProvisioner::VERSION}"
              puts "https://github.com/STARTcloud/core_provisioner/releases/tag/v#{CoreProvisioner::VERSION}"
              puts "This server has been provisioned with #{Provisioner::NAME} v#{Provisioner::VERSION}"
              puts "https://github.com/STARTcloud/#{Provisioner::NAME}/releases/tag/v#{Provisioner::VERSION}"
      
              system("vagrant ssh -c 'cat /vagrant/support-bundle/adapters.yml' > .vagrant/provisioned-adapters.yml")
      
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
      
                  ## Set the URL that SHI will Open
                  open_url = "https://#{ip_address.split('/').first}:443/welcome.html"
      
                  ## This section replaces the default SSH key with one that the provisioner scripts generated
                  ## Note if you enable insert key, but don't have  provisioner script that regenerates the key, this may fail
                  if host['settings']['vagrant_insert_key']
                    system("vagrant ssh -c 'cat /home/startcloud/.ssh/id_ssh_rsa' > #{host['settings']['vagrant_user_private_key_path']}")
                    system(%x(vagrant ssh -c "sed -i '/vagrantup/d' /home/startcloud/.ssh/id_ssh_rsa"))
                  end
      
                  filtered_adapters = adapters['adapters'].select { |adapter| adapter['name'] != 'public_adapter' }
                  filtered_adapters.each do |adapter_hash|
                    adapter_hash.transform_keys(&:to_s)
                  end
      
                  output_data = {
                    open_url: open_url,
                    adapters: filtered_adapters
                  }.to_yaml
                  puts "Network Information Can be found here: #{File.join(Dir.pwd, 'results.yml')}"
                  Hosts.write_results_file(output_data, 'results.yml')
      
                  puts open_url
                  system("echo '" + open_url + "' > .vagrant/done.txt")
                end
              else
                puts "Error: .vagrant/provisioned-adapters.yml file does not exist."
              end
            end
          end
        end
      end
    end
  end

  def self.load_secrets
    secrets_path = "#{File.dirname(__FILE__)}/../.secrets.yml"
    YAML.load(File.read(secrets_path)) if File.exists?(secrets_path)
  end

  def self.configure_plugins(host)
    plugins = Array(host['plugins'])
    return if plugins.empty?
  
    plugins.each do |plugin|
      next if Vagrant.has_plugin?(plugin)
  
      system("vagrant plugin install #{plugin}")
      exit system('vagrant', *ARGV)
    end
  end

  def self.delete_files(settings)
    return unless settings['delete_old']

    files_to_delete = [
      'hcl_domino_standalone_provisioner/.vagrant/done.txt',
      'hcl_domino_standalone_provisioner/.vagrant/provisioned-adapters.yml',
      'hcl_domino_standalone_provisioner/results.yml'
    ]

    files_to_delete.each do |file|
      if File.exist?(file)
        File.delete(file)
        puts "Deleted file: #{file}"
      else
        puts "File not found: #{file}"
      end
    end
  end

  def self.write_results_file(data, file_path)
    # Delete the file if it exists
    File.delete(file_path) if File.exist?(file_path)

    # Write the new content
    File.open(file_path, 'w') do |file|
      file.write(data.to_yaml.gsub(/:(\w+):/, '\1:'))
    end
  end
end
